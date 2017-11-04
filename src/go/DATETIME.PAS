{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit DateTime;

interface

uses Global;

function  dtAge(Date : String) : Word;                            { Years old }
function  dtDateFullString(S : String) : String;         { Verbal date string }
function  dtDatePackedString(L : LongInt) : String;  { Date unpacked (string) }
function  dtDateString : String;                      { Current date (string) }
function  dtDateTimePacked : LongInt;              { Current date+time packed }
function  dtDaysBetween(d1, d2 : String) : LongInt; { # of days between dates }
function  dtTimePackedString(L : LongInt) : String;  { Time unpacked (string) }
function  dtTimePackedStr24(L : LongInt) : String;
function  dtTimeRecLen(var d : tDateTimeRec) : String;
function  dtTimeRecStr(dt : tDateTimeRec) : String;
function  dtTimeStr12 : String;                 { Current time 12 hr (string) }
function  dtTimeStr24 : String;                 { Current time 24 hr (string) }
function  dtValidDate(Dat : String) : Boolean;   { Is date in proper format ? }

function  dtDateFactor(MonthNum, DayNum, YearNum : Real) : Real;
function  dtDatetoJulian(DateLine : String) : Integer;
function  dtJuliantoDate(DateInt : Integer) : String;

function  dtDatetoReal(dt : tDateTimeRec) : Real;
procedure dtGetDateTime(var dt : tDateTimeRec);
procedure dtTimeDiff(var dt : tDateTimeRec; dt1, dt2 : tDateTimeRec);
function  dtInTime(t1, t2 : String) : Boolean;
function  dtSecDiff(before, after : LongInt) : LongInt;
function  dtRealDiff(before, after : Real) : Real;

function  dtDayCount(mo, yr : Integer) : Integer;    { # of days in mo months }
function  dtDayNum(Dt : String) : Integer;                  { # of Days ago ? }
function  dtDays(mo, yr : Integer) : Integer;            { # of days in month }
function  dtLeapYear(yr : Integer) : Boolean;          { Checks for leap year }
function  dtTimer : Real;                            { Seconds since midnight }

implementation

uses Dos,
     Strings;

Var
  Hour,Minute,Second,S100,
  Year,Month,Day,Dow     : Word;
  Syear,Smonth,Sday,Sdow : String;
  JulianDate             : Integer;

function dtTimer : Real;
var hour,
    minute,
    second,
    sec100  : Word;
begin
   GetTime(hour, minute, second, sec100);
   dtTimer := ((hour*60*60) + (minute*60) + (second) + (sec100 * 0.01))
end;

function dtDateString : String;
var S, D : String; Yr,Mn,Da,Dw : Word;
    Zr : String;
begin
   D := '';
   S := '';
   Zr := '0';
   GetDate(Yr,Mn,Da,Dw);
   D := St(Mn);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := D;
   D := St(Da);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := S + '/' + D;
   D := St(Yr);
   Delete(D,1,2);
   S := S + '/' + D;
   dtDateString := S;
end;

function dtLeapYear(yr : Integer) : Boolean;
begin
   dtLeapYear := (yr mod 4 = 0) and ((yr mod 100 <> 0) or (yr mod 400 = 0));
end;

function dtDayCount(mo, yr : Integer) : Integer;
var m, t : Integer;
begin
   t := 0;
   for m := 1 to (mo-1) do t := t+dtDays(m,yr);
   dtDayCount := t;
end;

function dtDays(mo, yr : Integer) : Integer;
var D : Integer;
begin
   d := strToInt(Copy('312831303130313130313031',1+(mo-1)*2,2));
   if ((mo=2) and (dtLeapYear(yr))) then Inc(d);
   dtDays := d;
end;

function dtDayNum(Dt : String) : Integer;
var d,m,y,t,c : Integer;
begin
   t := 0;
   m := strToInt(Copy(dt,1,2));
   d := strToInt(Copy(dt,4,2));
   y := strToInt(Copy(dt,7,2))+1900;
   for c := 1985 to y-1 do
     if (dtLeapYear(c)) then Inc(t,366) else Inc(t,365);
   t := t+dtDayCount(m,y)+(d-1);
   dtDayNum := t;
   if y < 1985 then dtDayNum :=0;
end;

function dtAge(Date : String) : Word;
var D : String; I : Integer;
begin
   I := strToInt(Copy(dtDateString,7,2))-strToInt(Copy(Date,7,2));
   if (dtDayNum(Copy(Date,1,6)+Copy(dtDateString,7,2)) > dtDayNum(dtDateString)) then Dec(I);
   dtAge := I;
end;

function dtValidDate(Dat : String) : Boolean;
var M, D : Byte;
begin
   M := StrToInt(Copy(Dat,1,2));
   D := StrToInt(Copy(Dat,4,2));
   dtValidDate := (M > 0) and (D > 0) and (M <= 12) and (D <= 31);
end;
{
function mMachineDate : String;
begin
  GetDate(Year,Month,Day,Dow);
  Str(Year,Syear);
  Str(Month,Smonth);
  if Month < 10 then Smonth := '0' + Smonth;
  Str(Day,Sday);
  if Day < 10 then Sday := '0' + Sday;
  mMachineDate := smonth + sday + syear;
end;
}
Function dtDateFactor(MonthNum, DayNum, YearNum : Real) : Real;
Var
 Factor : Real;
begin
 Factor :=   (365 * YearNum)
           + DayNum
           + (31 * (MonthNum-1));
 if MonthNum < 3
  then Factor :=  Factor
                + Int((YearNum-1) / 4)
                - Int(0.75 * (Int((YearNum-1) / 100) + 1))
  else Factor :=  Factor
                - Int(0.4 * MonthNum + 2.3)
                + Int(YearNum / 4)
                - Int(0.75 * (Int(YearNum / 100) + 1));
 dtDateFactor := Factor;
end;

function dtDatetoJulian(DateLine : String) : Integer;
Var
 Factor, MonthNum, DayNum, YearNum : Real;
 Ti : Integer;
begin
 Delete(DateLine,3,1);
 Delete(DateLine,5,1);
 Insert('19',DateLine,5);
 if Length(DateLine) = 7
  then DateLine := '0'+DateLine;
 MonthNum := 0.0;
 For Ti := 1 to 2 Do
  MonthNum := (10 * MonthNum)
    + (ord(DateLine[Ti])-ord('0'));
 DayNum := 0.0;
 For Ti := 3 to 4 Do
  DayNum := (10 * DayNum)
    + (ord(DateLine[Ti])-ord('0'));
 YearNum := 0.0;
 For Ti := 5 to 8 Do
  YearNum := (10 * YearNum)
    + (ord(DateLine[Ti])-ord('0'));
 Factor := dtDateFactor(MonthNum, DayNum, YearNum);
 dtDatetoJulian :=
  Trunc((Factor - 679351.0) - 32767.0);
end;

function dtJuliantoDate(DateInt : Integer) : String;
Var
 holdstr  : String[2];
 anystr  : String[11];
 StrMonth : String[3];
 strDay   : String[2];
 stryear  : String[4];
 test,
 error,
 Year,
 Dummy,
 I       : Integer;
 Save,Temp    : Real;
 JuliantoanyString : String;
begin
 holdstr := '';
 JuliantoanyString := '00000000000';
 Temp  := Int(DateInt) + 32767 + 679351.0;
 Save  := Temp;
 Dummy := Trunc(Temp/365.5);
 While Save >= dtDateFactor(1.0,1.0,Dummy+0.0)
  Do Dummy := Succ(Dummy);
 Dummy := Pred(Dummy);
 Year  := Dummy;
 (* Determine number of Days into current year *)
 Temp  := 1.0 + Save - dtDateFactor(1.0,1.0,Year+0.0);
 (* Put the Year into the output String *)
 For I := 8 downto 5 Do
  begin
   JuliantoanyString[I]
    := Char((Dummy mod 10)+ord('0'));
   Dummy := Dummy div 10;
  end;
 Dummy := 1 + Trunc(Temp/31.5);
 While Save >= dtDateFactor(Dummy+0.0,1.0,Year+0.0)
  Do Dummy := Succ(Dummy);
 Dummy := Pred(Dummy);
 Temp  := 1.0 + Save - dtDateFactor(Dummy+0.0,1.0,Year+0.0);
 For I := 2 Downto 1 Do
  begin
   JuliantoanyString[I]
    := Char((Dummy mod 10)+ord('0'));
   Dummy := Dummy div 10;
  end;
 Dummy := Trunc(Temp);
 For I := 4 Downto 3 Do
  begin
   JuliantoanyString[I]
    := Char((Dummy mod 10)+ord('0'));
   Dummy := Dummy div 10;
  end;
  holdstr := copy(juliantoanyString,1,2);
  val(holdstr,test,error);
{ Case test of
    1 : StrMonth := 'Jan';
    2 : StrMonth := 'Feb';
    3 : StrMonth := 'Mar';
    4 : StrMonth := 'Apr';
    5 : StrMonth := 'May';
    6 : StrMonth := 'Jun';
    7 : StrMonth := 'Jul';
    8 : StrMonth := 'Aug';
    9 : StrMonth := 'Sep';
   10 : StrMonth := 'Oct';
   11 : StrMonth := 'Nov';
   12 : StrMonth := 'Dec';
  end;}
  StrMonth := St(Test);
  if Length(StrMonth) < 2 then Insert('0',StrMonth,1);
  stryear := copy(juliantoanyString,7,2);
  strDay  := copy(juliantoanyString,3,2);
  anystr := StrMonth + '/' + StrDay + '/' +strYear;
  dtJuliantoDate := anystr;
end;

function dtInTime(t1, t2 : String) : Boolean;
var ti1, ti2, tnow : Word;
begin
   Delete(t1,3,1);
   Delete(t2,3,1);
   ti1 := strToInt(t1);
   ti2 := strToInt(t2);
   t1 := dtTimeStr24;
   Delete(t1,3,1);
   tnow := strToInt(t1);
   if ti1 = ti2 then dtInTime := tnow = ti1 else
   if ti1 < ti2 then dtInTime := (tnow >= ti1) and (tnow <= ti2) else
   if ti1 > ti2 then dtInTime := (tnow >= ti1) or (tnow <= ti2);
end;

function dtTimeStr24 : String;
var S, D, Zr : String; Hr,Mn,Sc,Ms : Word;
begin
   D := '';
   S := '';
   Zr := '0';
   GetTime(Hr,Mn,Sc,Ms);
   D := St(Hr);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := D;
   D := St(Mn);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := S + ':' + D;
   D := St(Sc);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := S + ':' + D;
   dtTimeStr24 := S;
end;

function dtTimeStr12 : String;
var S, D, Zr : String; Hr,Mn,Sc,Ms : Word; Pm : Boolean;
begin
   D := '';
   S := '';
   Zr := '0';
   GetTime(Hr,Mn,Sc,Ms);
   Pm := (Hr >= 12);
   if Hr > 12 then Dec(Hr,12);
   if Hr = 0 then Hr := 12;
   D := St(Hr);
   S := D;
   D := St(Mn);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := S + ':' + D;
   if Pm then S := S + 'pm' else S := S + 'am';
   dtTimeStr12 := S;
end;

function dtDateTimePacked : LongInt;
var Y,M,D,Dw, H,Mn,S,So : Word; Dt : Dos.DateTime; L : LongInt;
begin
   GetTime(H,Mn,S,So);
   GetDate(Y,M,D,Dw);
   Dt.Year := Y;
   Dt.Month := M;
   Dt.Day := D;
   Dt.Hour := H;
   Dt.Min := Mn;
   Dt.Sec := S;

   PackTime(Dt,L);

   dtDateTimePacked := L;
end;

function dtDatePackedString(L : LongInt) : String;
var S, D, Zr : String; Yr,Mn,Da : Word; Dt : Dos.DateTime;
begin
   UnpackTime(L,Dt);
   Zr := '0';
   Yr := Dt.Year;
   Mn := Dt.Month;
   Da := Dt.Day;
   D := St(Mn);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := D;
   D := St(Da);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := S + '/' + D;
   D := St(Yr);
   Delete(D,1,2);
   S := S + '/' + D;
   dtDatePackedString := S;
end;

function dtTimePackedString(L : LongInt) : String;
var S, D, Zr : String; Hr,Mn : Word; Dt : Dos.DateTime; Pm : Boolean;
begin
   UnpackTime(L,Dt);
   Hr := Dt.Hour;
   Zr := '0';
   Mn := Dt.Min;
   Pm := (Hr >= 12);
   if Hr > 12 then Dec(Hr,12);
   if Hr = 0 then Hr := 12;
   D := St(Hr);
   S := D;
   D := St(Mn);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := S + ':' + D;
   if Pm then S := S + 'pm' else S := S + 'am';
   dtTimePackedString := S;
end;

function dtTimePackedStr24(L : LongInt) : String;
var S, D, Zr : String; Hr,Mn : Word; Dt : Dos.DateTime;
begin
   UnpackTime(L,Dt);
   Hr := Dt.Hour;
   Zr := '0';
   Mn := Dt.Min;
   D := St(Hr);
   S := D;
   D := St(Mn);
   if Length(D) = 1 then Insert(Zr,D,1);
   S := S + ':' + D;
   dtTimePackedStr24 := S;
end;

function dtDaysBetween(d1, d2 : String) : LongInt;
var
  internal1,internal2:longint;
  JNUM:real;
  cd,month,day,year: integer;
  out:string[25];

    function Jul( mo, da, yr: integer): real;
    var
      i, j, k, j2, ju: real;
    begin
         i := yr;     j := mo;     k := da;
         j2 := int( (j - 14)/12 );
         ju := k - 32075 + int(1461 * ( i + 4800 + j2 ) / 4 );
         ju := ju + int( 367 * (j - 2 - j2 * 12) / 12);
         ju := ju - int(3 * int( (i + 4900 + j2) / 100) / 4);
         Jul := ju;
    end;

begin
  out:=copy(d1,1,2);
  if copy(out,1,1)='0' then delete(out,1,1);
  val(out,month,cd);
  out:=copy(d1,4,2);
  if copy(out,1,1)='0' then delete(out,1,1);
  val(out,day,cd);
  out:=copy(d1,7,2);
  if copy(out,1,1)='0' then delete(out,1,1);
  val(out,year,cd);
  jnum:=jul(month,day,year);
  str(jnum:10:0,out);
  val(out,internal1,cd);
  out:=copy(d2,1,2);
  if copy(out,1,1)='0' then delete(out,1,1);
  val(out,month,cd);
  out:=copy(d2,4,2);
  if copy(out,1,1)='0' then delete(out,1,1);
  val(out,day,cd);
  out:=copy(d2,7,2);
  if copy(out,1,1)='0' then delete(out,1,1);
  val(out,year,cd);
  jnum:=jul(month,day,year);
  str(jnum:10:0,out);
  val(out,internal2,cd);
  dtDaysBetween := internal1-internal2;
end;

function dtDateFullString(S : String) : String;
var D : String; Z : Byte;
begin
   D := '';
   Z := StrToInt(Copy(S,1,2));
   case Z of
     1 : D := 'January';
     2 : D := 'February';
     3 : D := 'March';
     4 : D := 'April';
     5 : D := 'May';
     6 : D := 'June';
     7 : D := 'July';
     8 : D := 'August';
     9 : D := 'September';
     10: D := 'October';
     11: D := 'November';
     12: D := 'December';
     else D := 'Unknown';
   end;
   Z := StrToInt(Copy(S,4,2));
   D := D+' '+St(Z)+', 19'+Copy(S,7,2);
   dtDateFullString := D;
end;
{
function mRealDate(D : String) : String;
begin
   mRealDate := Copy(D,1,2)+'/'+Copy(D,3,2)+'/'+Copy(D,7,2);
end;
}
procedure dtTimeDiff(var dt : tDateTimeRec; dt1, dt2 : tDateTimeRec);
begin
   with dt do
   begin
      day  := dt2.day-dt1.day;
      hour := dt2.hour-dt1.hour;
      min  := dt2.min-dt1.min;
      sec  := dt2.sec-dt1.sec;

      if (hour < 0) then begin Inc(hour,24); Dec(day); end;
      if (min  < 0) then begin Inc(min, 60); Dec(hour); end;
      if (sec  < 0) then begin Inc(sec, 60); Dec(min); end;
   end;
end;

function dtTimeRecStr(dt : tDateTimeRec) : String;
var S : String;
begin
   with dt do
   begin
      if day > 1 then S := St(day)+' days, ' else
      if day > 0 then S := St(day)+' day, ' else
                      S := '';
      if hour > 1 then S := S+St(hour)+' hours, ' else
      if hour > 0 then S := S+St(hour)+' hour, ';

      if min > 1 then S := S+St(min)+' minutes, ' else
      if min > 0 then S := S+St(min)+' minute, ';

      if sec > 1 then S := S+St(sec)+' seconds' else
      if sec > 0 then S := S+St(sec)+' second';
   end;
   if S = '' then S := 'no time' else
   if S[Length(S)-1] = ',' then Delete(S,Length(S)-1,2);
   dtTimeRecStr := S;
end;

function dtDatetoReal(dt : tDateTimeRec) : Real;
begin
   with dt do dtDatetoReal := day*86400.0+hour*3600.0+min*60.0+sec;
end;

procedure dtGetDateTime(var dt : tDateTimeRec);
var w1,w2,w3,w4:word;
begin
   GetTime(w1,w2,w3,w4);
   with dt do begin
      day  := dtdaynum(dtDateString);
      hour := w1;
      min  := w2;
      sec  := w3;
   end;
end;

function dtSecDiff(before, after : LongInt) : LongInt;
begin
   if after > before then dtSecDiff := after-before else
   if before > after then dtSecDiff := 86400-before+after else
                          dtSecDiff := 0;
end;

function dtRealDiff(before, after : Real) : Real;
begin
   if after > before then dtRealDiff := after-before else
   if before > after then dtRealDiff := 86400-before+after else
                          dtRealDiff := 0;
end;

function dtTimeRecLen(var d : tDateTimeRec) : String;
var h, m : LongInt; s : String;
begin
   h := d.day*24+d.hour;
   m := d.min;
   if h > 99 then h := 99;
   s := st(h);
   if Ord(s[0]) = 1 then s := '0'+s;
   s := s+':'+st(m);
   if m < 10 then Insert('0',s,4);
   dtTimeRecLen := s;
end;

end.