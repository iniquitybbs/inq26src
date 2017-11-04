{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,N-,E+}
unit Output;

interface

uses Global;

procedure oBack(N : Byte);
procedure oBackspace(C : Char);
procedure oBeep;
procedure oClrEol;
procedure oClrScr;
procedure oCWrite(S : String);
procedure oCWriteLn(S : String);
procedure oDnLn(Ln : Byte);
procedure oGotoXY(X,Y : Integer);
procedure oMoveUp(C : Byte);
procedure oMoveDown(C : Byte);
procedure oMoveRight(C : Byte);
procedure oMoveLeft(C : Byte);
procedure oPause;
procedure oPosX(X : Integer);
procedure oPosY(Y : Integer);
procedure oPromptKey;
procedure oRestoreCursor;
procedure oSaveCursor;
procedure oSetBack(C : Byte);
procedure oSetBlink(B : Boolean);
procedure oSetCol(C : Byte);
procedure oSetColor(F,B : Byte);
procedure oSetColRec(T : tColorRec);
procedure oSetFore(C : Byte);
function  oStr(S : String) : Boolean;
procedure oStrCtr(S : String);
procedure oStrCtrLn(S : String);
procedure oString(Z : Word);
procedure oStringLn(Z : Word);
procedure oStrLn(S : String);
procedure oUpPause(R : Word);
function  oWhereX : Byte;
function  oWhereY : Byte;
procedure oWrite(S : String);
procedure oWriteAnsi(S : String);
procedure oWriteChar(C : Char);
procedure oWriteLn(S : String);
procedure oWritePw(S : String);
procedure oWriteRem(S : String);

implementation

uses
   Misc, FastIO, Emulate, StrProc, WinDos, Input, ShowFile, IPLx, MciCodes, eComm;

const
   ansiFore : array[0..15] of String[2] = ('30','34','32','36','31','35','33','37',
                                           '30','34','32','36','31','35','33','37');
   ansiBack : array[0..7] of String[2]  = ('40','44','42','46','41','45','43','47');

function oAnsiCode(F,T : tColorRec) : String;
var S : String; cF, cB, cBl : Boolean;
begin
   cF  := F.Fore  <> T.Fore;
   cB  := F.Back  <> T.Back;
   cBl := F.Blink <> T.Blink;
   oAnsiCode := '';
   if not (cF or cB or cBl) then Exit;
   S := #27+'[';
   if (cBl and T.Blink) or ((cF) and (F.Fore >= 8) and (T.Fore <= 7)) then
   begin
      S := S+'0;';
      cBl := T.Blink;
      cB := T.Back <> 0;
      cF := T.Fore <> 7;
   end;

   if cF then
   begin
      if (F.Fore <= 7) and (T.Fore >= 8) then
         S := S+'1;'+ansiFore[T.Fore]+';' else
         S := S+ansiFore[T.Fore]+';';
   end;

   if cB then S := S+ansiBack[T.Back]+';';
   if cBl then S := S+'5;';

   S[Ord(S[0])] := 'm';

   oAnsiCode := S;
end;

procedure oSetColRec(T : tColorRec);
begin
   if not emuAnsi then Exit;
   if (not LocalIO) and (RemoteOut) then
   begin
      if emuTextFX then
      begin
         ioTextColRec(T);
         putstring(#27'M'+char(colAttr));
      end else
      if emuAvatar then
      begin
         ioTextColRec(T);
         putstring(^V^A+char(colAttr));
      end else
      begin
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
procedure oWriteChar(C : Char);
begin
   ioWriteChar(C);
   if (not LocalIO) and (RemoteOut) then eputchar(C);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
end;

procedure oWrite(S : String);
begin
   ioWrite(S);
   if (not LocalIO) and (RemoteOut) then putstring(S);
end;

procedure oWriteLn(S : String);
begin
   ioWriteLn(S);
   if (not LocalIO) and (RemoteOut) then putstring(S+#13#10);
end;

procedure oClrScr;
begin
   if (not LocalIO) and (RemoteOut) then
   begin
      if emuTextFX then putstring(#27'J') else
      if emuAnsi then putstring(#27+'[2J') else
                      putstring(#12);
   end;
   emuAnsiInit;
   mClearScr(False);
end;

procedure oSetBlink(B : Boolean);
var C : tColorRec;
begin
   C := col;
   C.Blink := B;
   oSetColRec(C);
end;

procedure oGotoXY(X,Y : Integer);
begin
   if not emuAnsi then Exit;
   ioGotoXY(X,Y);
   if (not LocalIO) and (RemoteOut) then
   begin
      if emuTextFX then putstring(#27'H'+char(X)+char(Y)) else
      if emuAvatar then putstring(^V^H+char(Y)+char(X)) else
                        putstring(#27'['+St(Y)+';'+St(X)+'H');
   end;

end;

procedure oBeep;
begin
   oWrite(#7);
end;

procedure oCWrite(S : String);
var C1, C2 : Char; N, CP : Integer; CS : String;
begin
   CP := 0; C1 := ' '; C2 := ' '; CS := '';
   for N := 1 to Length(S) do
   begin
      case S[N] of
        '|' : if (UpCase(S[N+1]) in ['0'..'9','B','U']) and
                 (S[N+2] in ['0'..'9']) then CP := 1 else oWriteChar(S[N]);
        else if CP = 0 then oWriteChar(S[N]) else
             if CP = 1 then
             begin
                C1 := S[N];
                Inc(CP,1);
             end else
             if CP = 2 then
             begin
                C2 := S[N];
                CS := UpStr(C1+C2);
                if CS = '00' then oSetFore(0) else
                if CS = '01' then oSetFore(1) else
                if CS = '02' then oSetFore(2) else
                if CS = '03' then oSetFore(3) else
                if CS = '04' then oSetFore(4) else
                if CS = '05' then oSetFore(5) else
                if CS = '06' then oSetFore(6) else
                if CS = '07' then oSetFore(7) else
                if CS = '08' then oSetFore(8) else
                if CS = '09' then oSetFore(9) else
                if CS = '10' then oSetFore(10) else
                if CS = '11' then oSetFore(11) else
                if CS = '12' then oSetFore(12) else
                if CS = '13' then oSetFore(13) else
                if CS = '14' then oSetFore(14) else
                if CS = '15' then oSetFore(15) else
                if CS = 'U0' then oSetCol(colError) else
                if CS = 'U1' then oSetCol(colText) else
                if CS = 'U2' then oSetCol(colTextLo) else
                if CS = 'U3' then oSetCol(colTextHi) else
                if CS = 'U4' then oSetCol(colInfo) else
                if CS = 'U5' then oSetCol(colInfoLo) else
                if CS = 'U6' then oSetCol(colInfoHi) else
                if CS = 'U7' then oSetCol(colItem) else
                if CS = 'U8' then oSetCol(colItemSel) else
                if CS = 'U9' then oSetCol(colBorder) else
                if CS = '16' then oSetBack(0) else
                if CS = '17' then oSetBack(1) else
                if CS = '18' then oSetBack(2) else
                if CS = '19' then oSetBack(3) else
                if CS = '20' then oSetBack(4) else
                if CS = '21' then oSetBack(5) else
                if CS = '22' then oSetBack(6) else
                if CS = '23' then oSetBack(7) else
                if CS = 'B0' then oSetBack(0) else
                if CS = 'B1' then oSetBack(1) else
                if CS = 'B2' then oSetBack(2) else
                if CS = 'B3' then oSetBack(3) else
                if CS = 'B4' then oSetBack(4) else
                if CS = 'B5' then oSetBack(5) else
                if CS = 'B6' then oSetBack(6) else
                if CS = 'B7' then oSetBack(7) else
                oWrite('|'+CS);
                CP := 0;
             end;
      end;
   end;
end;

procedure oSetFore(C : Byte);
var cl : tColorRec;
begin
   cl := col;
   cl.Fore := C;
   oSetColRec(Cl);
end;

procedure oSetBack(C : Byte);
var cl : tColorRec;
begin
   cl := col;
   cl.Back := C;
   oSetColRec(Cl);
end;

procedure oSetColor(F,B : Byte);
var cl : tColorRec;
begin
   cl := col;
   cl.Fore := F;
   cl.Back := B;
   oSetColRec(Cl);
end;

procedure oSetCol(C : Byte);
begin
   oSetColRec(User^.Color[C]);
end;

procedure oCWriteLn(S : String);
begin
   oCWrite(S);
   oWriteChar(#13); oWriteChar(#10);
end;

procedure oDnLn(Ln : Byte);
var x : Byte;
begin
   for x := 1 to Ln do begin oWriteChar(#13); oWriteChar(#10); end;
end;

procedure oBackspace(C : Char);
begin
   oWrite(#8+C+#8);
end;

procedure oWriteAnsi(S : String);
var N : Byte;
begin
   for N := 1 to byte(s[0]) do emuAnsiWriteChar(S[N]);
   if (not LocalIO) and (RemoteOut) then putstring(S);
end;

procedure oPause;
var Ch : Char; C : tColorRec;
begin
   if not (acPause in User^.acFlag) then Exit;
   C := Col;
   oString(strPause);
   Ch := UpCase(iReadKey);
   PauseAbort := Ch in ['Q','S','N',#27];
   if Ch = 'C' then PausePos := 0;
   if Cfg^.RemovePause then oBack(oWhereX);
   oSetColRec(C);
end;

procedure oPromptKey;
begin
   oString(strHitAKey);
   iReadKey;
   if Cfg^.RemovePause then oBack(oWhereX);
end;

procedure oMoveUp(C : Byte);
begin
   ioGotoXY(ioWhereX,ioWhereY-C);
   if (not LocalIO) and (RemoteOut) then
   begin
      if emuTextFX then putstring(#27'A'+char(c)) else
      if emuAvatar then putstring(^V^H+char(ioWhereY)+char(ioWhereX)) else
                        putstring(#27+'['+St(C)+'A');
   end;
end;
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);

procedure oMoveDown(C : Byte);
begin
   ioGotoXY(ioWhereX,ioWhereY+C);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
   if (not LocalIO) and (RemoteOut) then
   begin
      if emuTextFX then putstring(#27'B'+char(c)) else
      if emuAvatar then putstring(^V^H+char(ioWhereY)+char(ioWhereX)) else
                        putstring(#27+'['+St(C)+'B');
   end;
end;

procedure oMoveRight(C : Byte);
begin
   if C+ioWhereX > 80 then C := 80-ioWhereX;
   ioGotoXY(ioWhereX+C,ioWhereY);
   if (not LocalIO) and (RemoteOut) then
   begin
      if emuTextFX then putstring(#27'C'+char(c)) else
      if emuAvatar then putstring(^V^H+char(ioWhereY)+char(ioWhereX)) else
                        putstring(#27+'['+St(C)+'C');
   end;
end;

procedure oMoveLeft(C : Byte);
begin
   if C > ioWhereX-1 then C := ioWhereX-1;
   ioGotoXY(ioWhereX-C,ioWhereY);
   if (not LocalIO) and (RemoteOut) then
   begin
      if emuTextFX then putstring(#27'D'+char(c)) else
      if emuAvatar then putstring(^V^H+char(ioWhereY)+char(ioWhereX)) else
                        putstring(#27+'['+St(C)+'D');
   end;
end;

function oStr(S : String) : Boolean;
var
   Cd, z, x : String; ct : Integer; mciPad : Boolean;
   mciLimit, nps, n, ex, ey : Byte; ec : tColorRec;
begin
   N := 0;
   oStr := False;
   if HangUp then Exit;
   oStr := True;
   if S = '' then Exit;
   mciPad := False;
   mciLimit := 255;
   z := s[1]+s[2];
   nps := 0;
   ex := 0;
   if z = '%%' then
   begin
      sfShowTextFile(Copy(S,3,255),ftNormal);
      oStr := False;
      Exit;
   end else
   if z = '%!' then
   begin
      x := Copy(s,3,255);
      while x[1] = ' ' do Dec(x[0]);
      ct := Pos(' ',x);
      if ct > 0 then
      begin
         s := Copy(x,ct+1,255);
         Delete(x,ct,255);
      end else s := '';
      iplExecute(x,s);
      oStr := False;
      Exit;
   end else
   if z = '%|' then
   begin
      Delete(s,1,2);
      ct := centerPos(s);
      if ct < 1 then ct := 1;
      if ct > 39 then ct := 39;
      oPosX(ct);
   end else
   if z = '%>' then
   begin
      Delete(s,1,2);
      ct := 80-Length(noColor(s));
      if ct < 1 then ct := 1;
      oPosX(ct);
   end;
   while N < Ord(s[0]) do
   begin
      Inc(N);
      if nps > 0 then
      begin
         Dec(nps);
         oWriteChar(s[N]);
      end else
      if S[N] = mciHeader then
      begin
         if mciProcessMCICode(Copy(S,N,3)) then
         begin
            Delete(S,N,3);
            if mciPad then mciString := Resize(mciString,mciLimit) else
                           mciString := strSquish(mciString,mciLimit);
            Insert(mciString,S,N);
            nps := Ord(mciString[0]);
            Dec(N);
         end else oWriteChar(S[N]);
      end else
      if S[N] = ctrHeader then
      begin
         if copy(s,n+1,2) = '**' then
         begin
            ex := oWhereX;
            ey := oWhereY;
            ec := col;
            Delete(S,N,3);
            Dec(n);
         end else
         if mciProcessControlCode(Copy(S,N,3)) then
         begin
            Delete(S,N,3);
            Dec(N);
         end else oWriteChar(S[N]);
      end else
      if S[N] in [posHeader,rowHeader,limHeader,padHeader] then
      begin
         if (S[N+1] in ['0'..'9']) and (S[N+2] in ['0'..'9']) then
         begin
            case S[n] of
              posHeader : oPosX(strToInt(S[N+1]+S[N+2]));
              rowHeader : oPosY(strToInt(S[N+1]+S[N+2]));
              limHeader : begin mciPad := False; mciLimit := StrToInt(S[N+1]+S[N+2]); end;
              padHeader : begin mciPad := True;  mciLimit := StrToInt(S[N+1]+S[N+2]); end;
            end;

            Delete(S,N,3);
            Dec(N);
         end else oWriteChar(S[N]);
      end else oWriteChar(S[N]);
   end;
   if ex <> 0 then
   begin
      oGotoXY(ex,ey);
      oSetColRec(ec);
   end;
end;

procedure oStrLn(S : String);
begin
   if oStr(S) then oDnLn(1);
end;

procedure oStrCtr(S : String);
var Cd : String; N, ex, ey : Byte; ec : tColorRec;
begin
   N := 0;
   ex := 0;
   while (S <> '') and (N < Length(S)) do
   begin
      Inc(N,1);
      if S[N] = ctrHeader then
      begin
         if copy(s,n+1,2) = '**' then
         begin
            ex := oWhereX;
            ey := oWhereY;
            ec := col;
            Delete(S,N,3);
            Dec(n);
         end else
         if mciProcessControlCode(Copy(S,N,3)) then
         begin
            Delete(S,N,3);
            Dec(n);
         end else oWriteChar(S[N]);
      end else oWriteChar(S[N]);
   end;
   if ex <> 0 then
   begin
      oGotoXY(ex,ey);
      oSetColRec(ec);
   end;
end;

procedure oStrCtrLn(S : String);
begin
   oStrCtr(S);
   if not HangUp then oDnLn(1);
end;
{
procedure oStrLn(S : String);
begin
   oStr(S);
   oDnLn(1);
end;
}
procedure oString(Z : Word);
begin
{  if NoColor(mStr(Z]) = mStr(Z] then oSetCol(colInfo);}
   oStr(mStr(Z));
end;

procedure oStringLn(Z : Word);
begin
{  if NoColor(mStr(Z]) = mStr(Z] then oSetCol(colInfo);}
   oStrLn(mStr(Z));
end;

function oWhereX : Byte;
begin
   oWhereX := ioWhereX;
end;

function oWhereY : Byte;
begin
   oWhereY := ioWhereY;
end;

procedure oBack(N : Byte);
var Z : Byte;
begin
   for Z := 1 to N do oBackspace(' ');
end;

procedure oClrEol;
begin
   ioClrEol;
   if (not LocalIO) and (RemoteOut) then
   begin
      if emuTextFX then putstring(#27'K') else
      if emuAvatar then putstring(^V^K) else
                        putstring(#27+'[K');
   end;
end;

procedure oSaveCursor;
begin
   savX := oWhereX;
   savY := oWhereY;
end;

procedure oRestoreCursor;
begin
   oGotoXY(savX,savY);
end;

procedure oWriteRem(S : String);
begin
   if (not LocalIO) and (RemoteOut) then putstring(S);
end;

procedure oWritePw(S : String);
begin
   if Cfg^.ShowPwLocal then ioWrite(S) else ioWrite(strEcho(S));
   if (not LocalIO) and (RemoteOut) then putstring(strEcho(S));
end;

procedure oUpPause(R : Word);
begin
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
   if PausePos = 0 then Exit;
   Inc(PausePos,R);
   if PausePos >= User^.PageLength then
   begin
      PausePos := 1;
      oPause;
   end;
end;

      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
procedure oPosX(X : Integer);
var P : Integer;
begin
   P := oWhereX;
   if X > P then oMoveRight(X-P) else
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
   if X < P then oMoveLeft(P-X);
end;

procedure oPosY(Y : Integer);
var P : Integer;
begin
   P := oWhereY;
   if Y > P then oMoveDown(Y-P) else
   if Y < P then oMoveUp(P-Y);
end;

end.
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
      begin
         putstring(oAnsiCode(col,T));
         ioTextColRec(T);
      end;
   end else ioTextColRec(T);
end;

procedure oWriteChar(C : Char);
