{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit StatBar;

interface

procedure sbClear;
procedure sbInfo(S : String; Stick : Boolean);
procedure sbReset;
procedure sbStatBar(On : Boolean);
procedure sbToggleMode;
procedure sbUpdate;

implementation

uses Crt,
     Global, Misc, Strings, FastIO, DateTime;

procedure sbClear;
var Yp : Byte;
begin
   if Cfg^.StatType = sbTop then Yp := 1 else Yp := 25;
   if (not UserOn) or (not Cfg^.StatBarOn) then Exit;
   fWrite(1,Yp,sRepeat(' ',maxX),Cfg^.StatTxt);
end;

procedure sbWrite(X : Byte; S : String; L : Integer);
var Col, P, F : Integer; Z : String; Ps, Yp : Byte;
begin
   Z := S;
   if Cfg^.StatType = sbTop then Yp := 1 else Yp := 25;
   while Pos('|',Z) <> 0 do Delete(Z,Pos('|',Z),2);
   F := L-Length(Z);
   if F > 0 then for P := 1 to F do S := S + ' ' else
   if F < 0 then for P := 1 to Abs(F) do Delete(S,Length(S),1);
   s := ' '+s;
   Col := Cfg^.StatTxt;
   Ps := 1;
   while S <> '' do if S[1] = '|' then
   begin
      case S[2] of
         'L' : Col := Cfg^.StatLo;
         'M' : Col := Cfg^.StatTxt;
         'H' : Col := Cfg^.StatHi;
      end;
      Delete(S,1,2);
   end else
   begin
      P := Pos('|',S);
      if P = 0 then P := Length(S) else Dec(P,1);
      fWrite(X+Ps-1,Yp,Copy(S,1,P),Col);
      Inc(Ps,P);
      Delete(S,1,P);
   end;
end;

procedure sbUpdate;
var S : String;
begin
   if (statCnt > 0) and (statCnt < 64000) then
   begin
      Inc(statCnt);
      if statCnt = 1000 then
      begin
         statCnt := 0;
         sbClear;
      end;
   end;
   if (not UserOn) or (not Cfg^.StatBarOn) then Exit;
   if statCnt <> 0 then sbWrite(1,'|M'+statInfo,80) else
   case Cfg^.StatBar of
     1 : begin
        if Cfg^.RealNameSystem then
           sbWrite(1, 'User |L[|H'+User^.RealName+'|L]',30) else
        begin
           sbWrite(1, 'User |L[|H'+User^.UserName+'|L]',30);
           sbWrite(32,'Real |L[|H'+User^.RealName+'|L]',30);
        end;
        sbWrite(64,'Time |L[|H'+St(mTimeLeft('M'))+'|L]',14);
     end;
     2 : begin
        sbWrite(1, 'Birth |L[|H'+User^.BirthDate+'|L] |MAge |L[|H'+St(dtAge(User^.BirthDate))+'|L]',26);
        sbWrite(28,'Phone |L[|H'+User^.PhoneNum+'|L]',22);
        if Cfg^.ShowPwLocal then S := User^.Password else S := strEcho(User^.Password);
        sbWrite(52,'Password |L[|H'+S+'|L]',27);
     end;
     3 : begin
        sbWrite(1, 'Sex |L[|H'+mSexString(User^.Sex)+'|L]',14);
        sbWrite(16,'Location |L[|H'+User^.Location+'|L]',30);
        sbWrite(50,'Address |L[|H'+User^.Address+'|L]',30);
     end;
     4 : begin
        sbWrite(1, 'Baud |L[|H'+mBaudString(User^.BaudRate)+'|L]',12);
        sbWrite(14,'Emulation |L[|H'+mEmulation(User^)+'|L]',19);
        sbWrite(40,'SL |L[|H'+st(User^.SL)+'|L]',9);
        sbWrite(50,'DSL |L[|H'+st(User^.DSL)+'|L]',10);
     end;
     5 : begin
        sbWrite(1, 'Chat Reason |L[|H'+chatReason+'|L]',63);
        sbWrite(65,'Attempts |L[|H'+St(numPaged)+'|L]',15);
     end;
     6 : begin
        sbWrite(1, 'MemAvail |L[|H'+St(memAvail)+'|L]',18);
        sbWrite(20,'MaxAvail |L[|H'+St(maxAvail)+'|L]',18);
        sbWrite(40,'Filemode |L[|H'+St(fileMode)+'|L]  '+
                 '|MTlo |L[|H'+b2St(tLibOpen)+'|L]',18);
{       sbWrite(60,'Tl |L[|H'+St(User^.textLib)+'|L]  '+
                 '|MNl |L[|H'+St(textLib^.numLib)+'|L]',20);}
     end;
   end;
end;

procedure sbReset;
begin
   scrTop := 1;
   scrBot := 25;
   Window(1,1,maxX,maxY);
   TextAttr := $0F;
   ClrScr;
   statInfo := '';
   statCnt := 0;
end;

procedure sbDraw;
var X,Y : Byte;
begin
   if not UserOn then Exit;
   X := ioWhereX; Y := ioWhereY;
   Window(1,1,maxX,maxY);
   case Cfg^.StatType of
     sbBot : begin
                scrTop := 1;
                scrBot := 24;
                if Y = 25 then
                begin
                   mScroll(1,1,80,25,-1);
                   Dec(Y,1);
                end;
             end;
     sbTop : begin
                scrTop := 2;
                scrBot := 25;
                if Y = 1 then mScroll(1,1,80,25,1);
                Dec(Y,1);
             end;
   end;
   Window(1,scrTop,80,scrBot);
   ioGotoXY(X,Y);
   sbClear;
   sbUpdate;
end;

procedure sbErase;
var X,Y,Yp : Byte;
begin
   if not UserOn then Exit;
   if Cfg^.StatType = sbTop then Yp := 1 else Yp := 25;
   X := ioWhereX; Y := ioWhereY;
   Window(1,1,maxX,maxY);
   scrTop := 1;
   scrBot := 25;
   if Cfg^.StatType = sbTop then Inc(Y,1);
   fWrite(1,Yp,sRepeat(' ',maxX),$0F);
   ioGotoXY(X,Y);
end;

procedure sbStatBar(On : Boolean);
begin
   if not UserOn then Exit;
   if Cfg^.StatBarOn = On then Exit;
   Cfg^.StatBarOn := On;
   if On then sbDraw else sbErase;
end;

procedure sbToggleMode;
var X,Y : Byte;
begin
   if not UserOn then Exit;
   if (not ScreenOff) and (Cfg^.StatBarOn) then sbErase;
   if Cfg^.StatType = sbBot then Cfg^.StatType := sbTop else Cfg^.StatType := sbBot;
   if (not Cfg^.StatBarOn) or (ScreenOff) then Exit;
   X := ioWhereX; Y := ioWhereY;
   Window(1,1,maxX,maxY);
   case Cfg^.StatType of
     sbBot : begin
                scrTop := 1;
                scrBot := 24;
                mScroll(1,1,80,25,-1);
                Dec(Y,1);
             end;
     sbTop : begin
                scrTop := 2;
                scrBot := 25;
                mScroll(1,1,80,25,1);
             end;
   end;
   Window(1,scrTop,80,scrBot);
   ioGotoXY(X,Y);
   sbClear;
   sbUpdate;
end;

procedure sbInfo(S : String; Stick : Boolean);
begin
   sbClear;
   if S = '' then
   begin
      statInfo := '';
      statCnt := 0;
      Exit;
   end;
   if Stick then statCnt := 64000 else statCnt := 1;
   statInfo := S;
   sbClear;
   sbUpdate;
end;

end.