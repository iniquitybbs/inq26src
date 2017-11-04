{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Misc;

interface

uses Dos, Crt, Global, Strings;

var
  initNum : Word;

function  acFlag(A : tUserACflag) : Boolean;
function  acsOK(S : String) : Boolean;
procedure cFwrite(x, y : Byte; S : String);
function  emuANSi : Boolean;
function  emuAvatar : Boolean;
function  emuRIP : Boolean;
function  mAliasFormat : tInFlag;
function  mArchSig(Sig : String) : String;
function  mAreaCode : String;
function  mBaudString(Bd : LongInt) : String;
procedure mClearScr(Full : Boolean);
function  mClip(Num, Min, Max : LongInt) : LongInt;
function  mCrypt(S : String) : String;
procedure mCursor(On : boolean);
function  mEmulation(var U : tUserRec) : String;
procedure mFillWord(var x; Count : Integer; w : Word);
function  mGetBit(v, bitNum : Byte) : Boolean;
Function  mGetDriveType(Drive : byte) : byte;
function  mGetParam(S : String) : String;
function  mInitials(iS : String) : String;
function  mParamStr(p : Byte; S : String) : Boolean;
function  mParam(S : String) : Boolean;
function  mRatio(P, C : LongInt) : String;
procedure mScroll(x1, y1, x2, y2 : Byte; Linesdown : Integer);
function  mSecLeft : Real;
procedure mSetColor(N, R, G, B : Byte);
function  mSexString(C : Char) : String;
function  mStr(sn : Word) : String;
function  mStrParam(ps : String; n : Byte) : String;
function  mStrParCnt(ps : String) : Byte;
procedure mStrSet(sn : Word; new : String);
function  mSysOpAvail : Boolean;
function  mTimeLeft(Typ : Char) : LongInt;
function  mTimeSec(T : LongInt) : String;
procedure mTimeSlice;
function  mUserAcs(s : String; var u : tUserRec) : Boolean;
procedure mWriteInit(stat : String);
function  mXferTimeSec(Size : LongInt) : LongInt;
procedure fWrite(x, y : Word; MsgText : String; ColorAttr : Byte);
{$IFDEF iniRegistered}
function  mRegString : String;
{$ENDIF}

implementation

uses FastIO, DateTime;

const maxInit = 39;

function acFlag(A : tUserACflag) : Boolean;
begin
   acFlag := A in User^.acFlag;
end;

function emuANSi : Boolean;
begin
   emuANSi := acFlag(acANSI) or acFlag(acAVATAR) or acFlag(acRIP);
end;

function emuAvatar : Boolean;
begin
   emuAvatar := acFlag(acAvatar);
end;

function emuRIP : Boolean;
begin
   emuRIP := acFlag(acRIP);
end;

procedure mClearScr(Full : Boolean);
begin
   if Full then Window(1,1,maxX,maxY) else Window(1,scrTop,maxX,scrBot);
{  TextAttr := $07;}
{  if not ScreenOff then ClrScr;}
   ioClrScr;
end;

procedure mCursor(On : boolean);
begin
   if not On then
   Asm
     MOV   ax,$0100
     MOV   cx,$2607
     INT   $10
   end else
   Asm
     MOV   ax,$0100
     MOV   cx,$0506
     INT   $10
   end;
end;

procedure fWrite(x, y : Word; MsgText : String; ColorAttr : Byte);
assembler;
       asm
        dec   x
        dec   y

        mov   ax,y
        mov   cl,5
        shl   ax,cl
        mov   di,ax
        mov   cl,2
        shl   ax,cl
        add   di,ax
        shl   x,1
        add   di,x

        mov   ax,0b800h     { 0b000h for mono }
        mov   es,ax
        xor   ch,ch
        push  ds
        lds   si,MsgText
        lodsb
        mov   cl,al
        mov   ah,ColorAttr
        jcxz  @@End
@@L1:
        lodsb
        stosw
        loop  @@L1
@@End:
        pop   ds
end;

procedure cFwrite(x, y : Byte; S : String);
var C1, C2 : Char; p, C : Byte; N, CP : Integer; CS : String;
begin
   CP := 0; C1 := ' '; C2 := ' '; CS := '';
   p := x;
   c := $07;

   for N := 1 to Length(S) do
   begin
      case S[N] of
        '|' : CP := 1;
        else if CP = 0 then begin fWrite(p,y,S[N],c); Inc(p); end else
             if CP = 1 then
             begin
                C1 := S[N];
                Inc(CP);
             end else
             if CP = 2 then
             begin
                C2 := S[N];
                CS := C1+C2;
                if CS = '00' then c := $00 else
                if CS = '01' then c := $01 else
                if CS = '02' then c := $02 else
                if CS = '03' then c := $03 else
                if CS = '04' then c := $04 else
                if CS = '05' then c := $05 else
                if CS = '06' then c := $06 else
                if CS = '07' then c := $07 else
                if CS = '08' then c := $08 else
                if CS = '09' then c := $09 else
                if CS = '10' then c := $0A else
                if CS = '11' then c := $0B else
                if CS = '12' then c := $0C else
                if CS = '13' then c := $0D else
                if CS = '14' then c := $0E else
                if CS = '15' then c := $0F else
                begin fWrite(p,y,'|'+CS,c); Inc(p,3); end;
                CP := 0;
             end;
      end;
   end;
end;

function mBaudString(Bd : LongInt) : String;
begin
   if Bd = 0 then mBaudString := 'Local' else
      mBaudString := St(Bd);
end;

function mUserAcs(s : String; var u : tUserRec) : Boolean;
var s1, s2 : String; p1, p2, I, J : Integer; C, c1, c2 : Char;
    B : Boolean;

 procedure acsCheckParam;
 begin
    s1 := C;
    p1 := I;
    if ((I <> 1) and (S[I-1] = '!')) then
    begin
       s1 := '!'+s1;
       Dec(p1,1);
    end;
    if (C in ['=','*','C','F','G','R','V','X']) then
    begin
       s1 := s1+S[I+1];
       Inc(I);
    end else
    begin
       J := I+1;
       repeat
          if (S[J] in ['0'..'9']) then
          begin
             s1 := s1+S[J];
             Inc(J,1);
          end;
       until ((J > Length(S)) or (not (S[J] in ['0'..'9'])));
       I := J-1;
    end;
    p2 := I;
 end;

 function acsCheckCode(S : String) : Boolean;
 var vs : String; Year, Month, Day, DayOfWeek, Hour, Minute, Second,
     Sec100 : Word; vsi : Integer; BoolState, Res : Boolean;
 begin
    BoolState := S[1] <> '!';
    if (not BoolState) then S := Copy(S,2,Length(S)-1);
    vs := Copy(S,2,Length(S)-1); vsi := StrToInt(vs);
    case S[1] of
      '=' : Res := LocalIO;
      '*' : Res := OkFlag;
      'A' : Res := dtAge(u.Birthdate) >= Vsi;
      'B' : Res := (LocalIO) or (u.BaudRate >= Vsi);
      'C' : Res := (mandMsg) or (mConf^.Key = UpCase(Vs[1]));
      'D' : Res := u.DSL >= Vsi;
      'F' : Res := UpCase(vs[1]) in u.Flag;
      'G' : Res := u.Sex = UpCase(Vs[1]);
      'H' : begin
               GetTime(Hour,Minute,Second,Sec100);
               Res := (Hour = Vsi);
            end;
      'K' : Res := Copy(u.phoneNum,2,3) = Vs;
      'P' : Res := u.Posts >= Vsi;
{     'R' :res:=(tacch(upcase(vs[1])) in u.ac);}
      'S' : Res := u.SL >= Vsi;
      'T' : Res := mTimeLeft('M') >= Vsi;
      'U' : Res := u.Number = Vsi;
      'V' : Res := u.Level <> 'A';
      'W' : begin
               GetDate(Year,Month,Day,DayOfWeek);
               Res := (DayOfWeek = Ord(vs[1])-48);
            end;
      'X' : Res := (fConfAll) or (fConf^.Key = UpCase(Vs[1]));
      'Y' : Res := Trunc(dtTimer) div 60 >= Vsi;
      'Z' : Res := Trunc(u.Posts / u.TotalCalls * 100) >= u.PostCall;
    end;
    if (not BoolState) then Res := not Res;
    acsCheckCode := Res;
  end;

begin
   S := UpStr(S);
   if S = '' then
   begin
      mUserAcs := True;
      Exit;
   end;
{  if S = '*' then S := S+' ';}
   I := 0;
   while (I < Length(S)) do
   begin
      Inc(I);
      C := S[I];
      if (C in ['*','=']) or ((C in ['A'..'Z']) and (I <> Length(S))) then
      begin
         acsCheckParam;
         B := acsCheckCode(s1);
         Delete(S,p1,Length(s1));
         if (B) then s2 := '^' else s2 := '%';
         Insert(s2,S,p1);
         Dec(I,Length(s1)-1);
      end;
   end;
   S := '('+S+')';
   while (Pos('&',S) <> 0) do Delete(S,Pos('&',S),1);
   while (Pos('^^',S) <> 0) do Delete(S,Pos('^^',S),1);
   while (Pos('(',S) <> 0) do
   begin
      I := 1;
      while ((S[I] <> ')') and (I <= Length(S))) do
      begin
         if (S[I] = '(') then p1 := I;
         Inc(I,1);
      end;
      p2 := I;
      s1 := Copy(S,p1+1,(p2-p1)-1);
      while (Pos('|',s1) <> 0) do
      begin
         I := Pos('|',s1);
         c1 := s1[I-1];
         c2 := s1[I+1];
         s2 := '%';
         if ((c1 in ['%','^']) and (c2 in ['%','^'])) then
         begin
            if ((c1 = '^') or (c2 = '^')) then s2 := '^';
            Delete(s1,I-1,3);
            Insert(s2,s1,I-1);
         end else
         Delete(s1,I,1);
      end;
      while (Pos('%%',s1) <> 0) do Delete(s1,Pos('%%',s1),1);  {leave only "%"}
      while (Pos('^^',s1) <> 0) do Delete(s1,Pos('^^',s1),1);  {leave only "^"}
      while (Pos('%^',s1) <> 0) do Delete(s1,Pos('%^',s1)+1,1);{leave only "%"}
      while (Pos('^%',s1) <> 0) do Delete(s1,Pos('^%',s1),1);  {leave only "%"}
      Delete(S,p1,(p2-p1)+1);
      Insert(s1,S,p1);
   end;
   mUserAcs := (not (Pos('%',S) <> 0));
end;

function acsOk(s : String) : Boolean;
begin
   acsOk := mUserAcs(s,User^);
end;

function mClip(Num, Min, Max : LongInt) : LongInt;
begin
   if Num < Min then Num := Min;
   if Num > Max then Num := Max;
   mClip := Num;
end;

function mSexString(C : Char) : String;
begin
   case UpCase(C) of
     'M' : mSexString := 'Male';
     'F' : mSexString := 'Female';
     else mSexString := 'Unknown';
   end;
end;

function mInitials(iS : String) : String;
var S : String; Z : Byte;
begin
   S := iS[1];
   Z := Pos(' ',iS);
   if Z = 0 then Z := Pos('-',iS);
   if (Z <> 0) and (not (iS[Z+1] in [' ','-'])) then
      S := S+iS[Z+1] else if Length(iS) > 1 then S := S+iS[2];
   mInitials := S;
end;

function mGetBit(v, bitNum : Byte) : Boolean;
begin
   mGetBit := (v and (1 shl bitNum)) <> 0;
end;

procedure mSetColor(N, R, G, B : Byte);
begin
   Port[$3C8] := N;
   Port[$3C9] := R;
   Port[$3C9] := G;
   Port[$3C9] := B;
end;

Function mGetDriveType(Drive : byte) : byte; assembler;
{ 0=current (default) drive,1=A,2=B,3=C... }
Asm
  cmp Drive,0
  jne @@1
  mov ah,19h
  int 21h
  mov Drive,al
  inc Drive
@@1:
  mov ax,1500h
  xor bx,bx
  int 2Fh
  or  bx,0      { works with CD-ROM v2.00+ }
  jz  @@2
  mov ax,150Bh
  xor ch,ch
  mov cl,Drive
  int 2Fh
  cmp bx,0ADADh
  jne @@2
  or  ax,0
  jz  @@2
  mov bl,drvCDROM
  jmp @@7
@@2:
  mov ax,4A11h
  mov bx,1
  mov dl,Drive
  dec dl
  int 2Fh
  xor cl,cl     { mov cl,False }
  or  ax,0      { is DoubleSpace loaded? }
  jnz @@3
  cmp dl,bl     { if a host drive equal to compressed, then get out... }
  je  @@3
  test bl,10000000b { bit 7=1: DL=compressed,BL=host
                           =0: DL=host,BL=compressed }
  jz  @@3       { so avoid host drives, assume host=fixed :) }
  inc dl
  cmp Drive,dl
  jne @@3
  mov bl,drvDblSpace
  jmp @@7
@@3:
  mov ax,4409h
  mov bl,Drive
  int 21h
  jc  @@5
  or  al,False
  jz  @@4
  mov bl,drvRemote
  jmp @@7
@@4:
  mov ax,4408h
  mov bl,Drive
  int 21h
  jc  @@5
  or  al,False
  jz  @@6
  mov bl,drvFixed
  jmp @@7
@@5:
  xor bl,bl     { mov bl,dtError cuz dtError=0 }
  jmp @@7
@@6:
  mov bl,drvRemovable
@@7:
  mov al,bl
End; { GetDriveType }

procedure mScroll(x1, y1, x2, y2 : Byte; Linesdown : Integer);
var tmpbyte, intbyte, clearattrib: byte;
begin
  if linesdown <> 0 then begin
    clearattrib := $07;
    x1 := x1 - 1;
    y1 := y1 - 1;
    x2 := x2 - 1;
    y2 := y2 - 1;
    if linesdown > 0 then intbyte := $07 else intbyte := $06;
    tmpbyte := abs(linesdown);
    asm
      mov ah, intbyte
      mov al, tmpbyte
      mov bh, clearattrib
      mov ch, y1
      mov cl, x1
      mov dh, y2
      mov dl, x2
      int 10h
      end;
    end;
  end;

function mTimeLeft(Typ : Char) : LongInt;
begin
   case UpCase(Typ) of
     'S' : mTimeLeft := Trunc(mSecLeft);
     'M' : mTimeLeft := Trunc(mSecLeft/60);
     'H' : mTimeLeft := Trunc(mSecLeft/60/60);
   end;
end;

function mSysOpAvail : Boolean;
var sl : Byte absolute $0000:$0417;
begin
   mSysOpAvail := ((sl and 16) = 0) and
                  (dtInTime(Cfg^.chatStart,Cfg^.chatEnd));
end;

procedure mTimeSlice; Assembler;
Asm
  cmp  oprType, 0
  je   @Fin
  cmp  oprType, 1
  je   @Win_OS2
  cmp  oprType, 2
  je   @Win_OS2
@DV_TV:
  mov  Ax, 1000h
  int  15h
  jmp  @Fin
@Win_OS2:
  mov  Ax, 1680h
  int  2Fh
@Fin:
End;

function mParam(S : String) : Boolean;
var Z : Byte;
begin
   S := UpStr(S);
   mParam := False;
   for Z := 1 to ParamCount do if Pos(S,UpStr(ParamStr(Z))) > 0 then mParam := True;
end;

function mParamStr(p : Byte; S : String) : Boolean;
begin
   S := UpStr(S);
   mParamStr := Pos(S,UpStr(ParamStr(p))) > 0;
end;

function mGetParam(S : String) : String;
var Z, X : Byte; P : String;
begin
   S := UpStr(S);
   mGetParam := '';
   X := 0;
   for Z := 1 to ParamCount do if Pos(S,UpStr(ParamStr(Z))) > 0 then X := Z;
   if X = 0 then Exit;
   P := ParamStr(X);
   Z := Pos(':',P);
   if (Z > 0) and (Length(P) > Z) then mGetParam := Copy(P,Z+1,255) else
   if ParamCount > X then mGetParam := ParamStr(X+1) else
      mGetParam := '';
end;

function mStrParam(ps : String; n : Byte) : String;
var z, x : Byte;
begin
   z := 1;
   mStrParam := '';
   ps := cleanUp(ps);
   while (Length(ps) > 0) and (z < n) do
   begin
      x := Pos(' ',ps);
      if x > 0 then
      begin
         Delete(ps,1,x);
         ps := cleanUp(ps);
      end else ps := '';
      Inc(z);
   end;
   if ps = '' then Exit;

   x := Pos(' ',ps);
   if x > 0 then Delete(ps,x,255);
   mStrParam := ps;
end;

function mStrParCnt(ps : String) : Byte;
var z, x : Byte;
begin
   z := 0;
   mStrParCnt := 0;
   ps := cleanUp(ps);
   if ps = '' then Exit;

   while (Length(ps) > 0) do
   begin
      x := Pos(' ',ps);
      if x > 0 then
      begin
         Delete(ps,1,x);
         ps := cleanUp(ps);
      end else ps := '';
      Inc(z);
   end;

   mStrParCnt := z;
end;

procedure mFillWord(var x; Count : Integer; w : Word);
begin
  Inline(
  $c4/$be/x/
  $8b/$86/w/
  $8b/$8e/count/
  $fc/
  $f2/$ab);
end;

procedure mWriteInit(stat : String);
const iY = 25;
var Z : Byte;
begin
   if initNum = 0 then
   begin
      cFwrite(1,iY,'|08[');
      cFwrite(80,iY,'|08]');
{     fWrite(40-maxInit,iY,sRepeat('ú',maxInit*2+1),$08);}
   end else
   begin
      fWrite(initNum*2,iY,'ù',$04);
      fWrite(initNum*2+1,iY,'ù',$04);

      if initNum < maxInit then fWrite(initNum*2+2,iY,#16,$0C) else
                                fWrite(initNum*2+1,iY,#16,$0C);
      cFwrite(76,1,'|12'+St(Round(initNum/maxInit*100))+'|04%');
      fWrite(9,2,strResizeNc(stat,35),$07);
   end;
   Inc(initNum);
end;
(*
procedure mWriteInit(stat : String);
const iY = 2;
var Z : Byte;
begin
   if initNum = 0 then
   begin
      cFwrite(40-maxInit,iY,'|08[');
      cFwrite(40+maxInit+1,iY,'|08]');
{     fWrite(40-maxInit,iY,sRepeat('ú',maxInit*2+1),$08);}
   end else
   begin
      if initNum > 1 then
      begin
         fWrite(40-(initNum-1)+1,iY,'ù',$01);
         fWrite(40+(initNum-1),iY,'ù',$01);
      end else fWrite(40,iY,'ù',$01);
      fWrite(40-initNum+1,iY,#17,$09);
      fWrite(40+initNum,iY,#16,$09);
      cFwrite(76,1,'|09'+St(Round(initNum/maxInit*100))+'|01%');
   end;
   Inc(initNum);
end;
*)
function mSecLeft : Real;
var Date1, Date2 : tDateTimeRec;
    BeenOn : Real;
    Sec : Real;
begin
   if (LoggedIn) and (userOn) then
   begin
      dtGetDateTime(Date1);
      dtTimeDiff(Date2,TimeOn,Date1);
      BeenOn := dtDatetoReal(Date2);
      Sec := ((User^.timeToday*60.0+timeExtra+timeFree)-(BeenOn+timeEvent));
   end else Sec := 3600.0;
   mSecLeft := Sec;
end;

function mCrypt(S : String) : String;
var i : Byte;
begin
   for i := 1 to Length(S) do S[i] := Char(Ord(S[i]) xor i);
   mCrypt := S;
end;

{$IFDEF iniRegistered}
function mRegString : String;
begin
   if regStamp[9] <> ' ' then mRegString := mCrypt(Copy(regStamp,9,22)) else
                              mRegString := 'None';
end;
{$ENDIF}

function mEmulation(var U : tUserRec) : String;
begin
   if acRIP    in U.acFlag then mEmulation := 'Rip' else
   if acAvatar in U.acFlag then mEmulation := 'Avatar' else
   if acAnsi   in U.acFlag then mEmulation := 'Ansi' else
                                mEmulation := 'None';
end;

function mAreaCode : String;
begin
   mAreaCode := Copy(User^.PhoneNum,2,3);
end;

function mRatio(P, C : LongInt) : String;
var S : String;
begin
   if C = 0 then C := 1;
   mRatio := strReal(P / C * 100,3,1)+'%';
end;

function mXferTimeSec(Size : LongInt) : LongInt;
var L : LongInt;
begin
   if (LocalIO) or (User^.BaudRate = 0) then
   begin
      mXferTimeSec := 0;
      Exit;
   end;
   mXferTimeSec := Size div (User^.BaudRate div 8);
end;

function mTimeSec(T : LongInt) : String;
var H, M, S : LongInt; Z : String;
begin
   S := T mod 60;
   M := T div 60;
   H := T div (60*60);
   Z := '';
   if H > 1 then Z := Z+St(H)+' hrs ' else
   if H > 0 then Z := Z+St(H)+' hr ';
   if M > 0 then Z := Z+St(M)+' min ';        { 2 hrs 30 min 13s }
   if S > 0 then Z := Z+St(S)+'s';
   Z := CleanUp(Z);
   if Z = '' then Z := 'no time';
   mTimeSec := Z;
end;

function mArchSig(Sig : String) : String;
var N, X : Byte;
begin
   mArchSig := '';
   if Sig = '' then Exit;
   for N := 1 to Length(Sig) do if Sig[N] = '^' then
   begin
      if N+3 > Length(Sig) then Exit;
      if not (Sig[N+1] in ['0'..'2']) then Exit;
      if not (Sig[N+2] in ['0'..'9']) then Exit;
      if not (Sig[N+3] in ['0'..'9']) then Exit;
      if strToInt(Copy(Sig,N+1,3)) > 255 then Exit;
   end;

   while Pos('^',Sig) > 0 do
   begin
      X := Pos('^',Sig);
      N := strToInt(Copy(Sig,X+1,3));
      Delete(Sig,X,4);
      Insert(Chr(N),Sig,X);
   end;

   mArchSig := Sig;
end;

function mAliasFormat : tInFlag;
var F : tInFlag;
begin
   case Cfg^.AliasFormat of
      2 : F := inCapital;
      3 : F := inUpper;
      4 : F := inLower;
      5 : F := inMixed;
      6 : F := inWeird;
      7 : F := inWarped;
      8 : F := inCool;
     else F := inNormal;
   end;
   mAliasFormat := F;
end;

function mStr(sn : Word) : String;
var x : Word;
begin
   if (sn = 0) or (sn > numString) then
   begin
      mStr := '';
      Exit;
   end;
   x := 1;
   while (x <= maxString) and (strIdx[x] <> sn) do Inc(x);
   if x > maxString then
   begin
      Move(strIdx[1],strIdx[2],maxString*2-2);
      Move(strBuf^[1],strBuf^[2],maxString*256-256);
      strIdx[1] := sn;
      Seek(strFile,sn-1);
      BlockRead(strFile,strBuf^[1],1);
      x := 1;
   end;
   mStr := strBuf^[x];
end;

procedure mStrSet(sn : Word; new : String);
var x : Word;
begin
   if (sn = 0) or (sn > numString) then Exit;
   for x := 1 to maxString do if strIdx[x] = sn then strBuf^[x] := new;
   Seek(strFile,sn-1);
   BlockWrite(strFile,new,1);
end;

end.