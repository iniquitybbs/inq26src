{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Input;

interface

uses Global;

function  iEditString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte; pgLen : Byte) : String;
function  iGetString(f, c, p, l, d, e : String) : String;
function  iKeyPressed : Boolean;
procedure iMenuSystem(var Menu; var Cur : Byte; Num : Byte);
function  iReadDate(def : String) : String;
function  iReadKey : Char;
function  iReadPhone(def : String) : String;
function  iReadPostalCode : String;
function  iReadString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte) : String;
function  iReadTime(def : String) : String;
function  iReadZipCode : String;
function  iXprompt(var Cmds; numC, def : Byte) : Byte;
function  iYesNo(Def : Boolean) : Boolean;
function  iYesNoBar(Def : Boolean) : Boolean;

implementation

uses Crt,
     Fossil, Strings, Comm, Output, Misc, Chatmode, Files, StatBar, FastIO,
     Emulate, HardAnsi, Levels, Logs, Users, DateTime;

function iReadKey : Char;
var C : Char; Hit : Byte; N : Byte; newKey, wasOff, warn : Boolean; rs : LongInt;
 function rkUpdateMacro : Boolean;
 begin
   rkUpdateMacro := True;
   if macroPos <> 0 then
   begin
      extKey := #0;
      C := Cfg^.Macro[macroNum,macroPos];
      Inc(macroPos);
      if macroPos > Length(Cfg^.Macro[macroNum]) then macroPos := 0;
   end else rkUpdateMacro := False;
 end;
begin
   ioUpdatePos;
   emuAnsiInit;
   cCheckUser;
   iReadKey := #1;
   if not rkUpdateMacro then
   repeat
      newKey := False;
      extKey := #0;
      rs := Trunc(dtTimer);
      Hit := 0;
      warn := False;
      repeat
         if KeyPressed then Hit := 1 else
         if (not LocalIO) and (ModemIO) and (RemoteIn) and
            (CharWaiting(Modem^.ComPort)) then Hit := 2 else
         begin
            if (Cfg^.inactTime) and ((not chatModeOn) or (Cfg^.inactInChat)) and
                                    ((not LocalIO) or (Cfg^.inactLocal)) then
            begin
               if dtSecDiff(rs,Trunc(dtTimer)) >= Cfg^.inactSeconds then
               begin
                  oStringLn(strTimeInactive);
                  logWrite('Inactivity timeout; hanging up.');
                  HangUp := True;
                  HungUp := False;
               end else
               if (not Warn) and (dtSecDiff(rs,Trunc(dtTimer)) >= Cfg^.inactWarning) then
               begin
                  oWrite(#7);
                  Delay(800);
                  oWrite(#7);
                  Delay(800);
                  oWrite(#7);
                  warn := True;
               end;
            end;
            cCheckUser;
         end;
      until (Hit > 0) or (Hangup);

      case Hit of
        1 : begin
               C := ReadKey;
               LocKey := True;
               wasOff := ScreenOff;
               if wasOff then
               begin
                  ioScreenOn;
                  ioUpdatePos;
                  newKey := True;
               end;
               if (C = #0) and (Keypressed) then
               begin
                  C := ReadKey;
                  newKey := True;
                  extKey := C;
                  case C of
                 F1..F10 : if macroPos = 0 then
                           begin
                              macroNum := Ord(C)-58;
                              if Cfg^.Macro[macroNum] <> '' then
                              begin
                                 macroPos := 1;
                                 rkUpdateMacro;
                                 newKey := False;
                              end;
                           end;
                    altH : begin
                              sbInfo('Terminating carrier',False);
                              HangUp := True;
                           end;
                    altE : begin
                              if acAvatar in User^.acFlag then User^.acFlag := User^.acFlag-[acAvatar] else
                                                               User^.acFlag := User^.acFlag+[acAvatar];
                           end;
                    altJ : if ChatModeOn then fJumpToDOS(1) else fJumpToDOS(2);
                    altC : if not ChatModeOn then chatNormal else newKey := False;
                    altX : if not ChatModeOn then chatSplitScreen else newKey := False;
                    altS : sbStatBar(not Cfg^.StatBarOn);
                    altB : begin
                             Inc(Cfg^.StatBar,1);
                             if Cfg^.StatBar > maxStatBar then Cfg^.StatBar := 1;
                             sbClear;
                             sbUpdate;
                           end;
                    altR : if RemoteOut then
                           begin
                              sbInfo('Remote output |Hdisabled',False);
                              RemoteOut := False;
                           end else
                           begin
                              sbInfo('Remote output |Henabled',False);
                              RemoteOut := True;
                           end;
                    altN : if RemoteIn then
                           begin
                              sbInfo('Remote input |Hdisabled',False);
                              RemoteIn := False;
                           end else
                           begin
                              sbInfo('Remote input |Henabled',False);
                              RemoteIn := True;
                           end;
                    altT : sbToggleMode;
                    altF : begin
                              sbInfo('Creating fake line noise ...',False);
                              for N := 1 to 5+Random(200) do oWrite(Chr(Random(255)));
                           end;
               #119,altI : begin
                              ScreenOff := True;
                              ioPageActive(1);
                              ansiHelp;
                              ioPageActive(0);
                              ioPageVisual(1);
                           end;
                    altM : begin
                              if not TempSysOp then
                              begin
                                 sbInfo('|L-- |MTemporary SysOp access granted|L.',False);
                                 logWrite('*Temporary SysOp access enabled');
                                 realSL := User^.SL;
                                 realDSL := User^.DSL;
                                 User^.SL := 255;
                                 User^.DSL := 255;
                                 TempSysOp := True;
                              end else
                              begin
                                 sbInfo('|L-- |MNormal access levels restored|L.',False);
                                 logWrite('*Temporary SysOp access disabled');
                                 User^.SL := realSL;
                                 User^.DSL := realDSL;
                                 TempSysOp := False;
                                 userSave(User^);
                              end;
                           end;
                    altU : begin
                              logWrite('*Upgraded user''s access online');
                              levelUpgrade(User^);
                              sbInfo('User access level upgrade complete |L-- |MUser''s level is now |L"|H'+
                                           User^.Level+'|L"',False);
                              if LoggedIn then userSave(User^);
                           end;
                    altZ : begin
                              sbInfo('Paging user...  Press any key to abort',True);
                              repeat
                                 oWrite(#7#7);
                                 Delay(600);
                              until (HangUp) or (iKeypressed);
                              sbInfo('',False);
                           end;
            #131,altPlus : timeFree := timeFree+60;
           #130,altMinus : timeFree := timeFree-60;
                     else newKey := False;
                  end;
               end else if not wasOff then newKey := False;
            end;
        2 : begin
               C := ComReadChar(Modem^.ComPort);
               LocKey := False;
               if C = #127 then extKey := #83 else
               if (C = #27) then
               begin
                  Delay(20);
                  if CharWaiting(Modem^.ComPort) then
                  begin
                     C := ComReadChar(Modem^.ComPort);
                     if (C = '[') and (CharWaiting(Modem^.ComPort)) then
                     begin
                        C := UpCase(ComReadChar(Modem^.ComPort));
                        case C of
                           extUpArrow     : extKey := #72;
                           extDownArrow   : extKey := #80;
                           extLeftArrow   : extKey := #75;
                           extRightArrow  : extKey := #77;
                           extHome        : extKey := #71;
                           extEnd         : extKey := #79;
                           extCtrlHome    : extKey := #119;
                           extCtrlPageUp  : extKey := #132;
                        end;
                     end;
                  end;
               end;
            end;
      end;
   until (HangUp) or (not newKey);
   iReadKey := C;
end;

function iKeyPressed : Boolean;
begin
   if KeyPressed then iKeyPressed := True else iKeyPressed := False;
   if (not LocalIO) and (RemoteIn) and (CharWaiting(Modem^.ComPort)) then
      iKeyPressed := True;
{  cCheckUser;}
end;
(*
function iReadString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte) : String;
var
   Ch      : Char;
   Done    : Boolean;
   Ins     : Boolean;
   S       : String;
   Ps      : Byte;
   Sze     : Byte;
   Int     : Integer;

   Password : Boolean;
   NoCR     : Boolean;
   NoIns    : Boolean;
   NoEdit   : Boolean;
   Min      : Boolean;
   Space    : Boolean;
   Req      : Boolean;
   NoClean  : Boolean;
   Abort    : Boolean;
   Backgr   : Boolean;

 procedure UpdateString(Add : Boolean);
 begin
    oWrite(Copy(S,Ps,255));
    if Add then
    begin
       oWrite(' ');
       oMoveLeft(Sze-Ps+1);
    end else oMoveLeft(Sze-Ps);
 end;

 procedure GetOptions;
 begin
    Password := Pos(rsPassword,Opt) > 0;
    NoCR     := Pos(rsNoCR,Opt)     > 0;
    NoIns    := Pos(rsNoIns,Opt)    > 0;
    NoEdit   := Pos(rsNoEdit,Opt)   > 0;
    Min      := Pos(rsMin,Opt)      > 0;
    Space    := Pos(rsSpace,Opt)    > 0;
    Req      := Pos(rsReq,Opt)      > 0;
    NoClean  := Pos(rsNoClean,Opt)  > 0;
    Abort    := Pos(rsAbort,Opt)    > 0;
    Backgr   := Pos(rsBackGr,Opt)   > 0;
 end;

 procedure ProcessChar(var C : Char);
 begin
    case iFl of
    inCapital : begin
                   if (Ps > 1) and (not (UpCase(S[Ps-1]) in ['A'..'Z','0'..'9','''','"']))
                      then C := UpCase(C); { else C := LowCase(C);}
                   if Ps = 1 then C := UpCase(C);
                end;
      inUpper : C := UpCase(C);
      inLower : C := LowCase(C);
      inMixed : begin
                   if (Ps > 1) and (not (UpCase(S[Ps-1]) in ['A'..'Z','0'..'9','''','"']))
                      then C := UpCase(C) else C := LowCase(C);
                   if Ps = 1 then C := UpCase(C);
                end;
      inWeird : if UpCase(C) in ['A','E','I','O','U'] then C := LowCase(C) else
                   C := UpCase(C);
     inWarped : if UpCase(C) in ['A','E','I','O','U'] then C := UpCase(C) else
                   C := LowCase(C);
       inCool : if UpCase(C) = 'I' then C := LowCase(C) else C := UpCase(C);
    end;
 end;

 procedure AddChar(C : Char);
 begin
    if (Ps >= Len) or (Sze >= Len) or ((Ps = 1) and (C = ' ') and
       (not Space)) then Exit;

    ProcessChar(C);

    if not (C in iCh) then Exit;

    if Password then oWritePw(C) else oWriteChar(C);
    if Ps = Sze then
    begin
       S := S + C;
       Inc(Sze,1);
       Inc(Ps,1);
    end else if Ins then
    begin
       Insert(C,S,Ps);
       Inc(Sze,1);
       Inc(Ps,1);
       UpdateString(False);
    end else
    begin
       S[Ps] := C;
       Inc(Ps,1);
    end;
 end;

 procedure Backspace;
 begin
    if Ps <= 1 then Exit;
    oBackSpace(' ');
    Dec(Ps,1);
    Dec(Sze,1);
    Delete(S,Ps,1);
    if Ps < Sze then UpdateString(True);
 end;

 procedure DelChar;
 begin
    if (Sze < 2) or (Ps >= Sze) then Exit;
    Delete(S,Ps,1);
    {sRepeat(EchoCh,Sze-Ps-1)+' ')}
    if Password then oWritePw(Copy(S,Ps,255)+' ') else
                       oWrite(Copy(S,Ps,255)+' ');
    oMoveLeft(Sze-Ps);
    Dec(Sze,1);
 end;

 procedure NextWord;
 var N, Z : Byte;
 begin
    if Ps = Sze then Exit;
    Z := 0;
    for N := Ps+1 to Sze do if (Z = 0) and (S[N] in [' ','-']) then Z := N;
    if Z = 0 then Z := Sze;
    if Ps = Z then Exit;
    oMoveRight(-Ps+Z);
    Ps := Z;
 end;

 procedure LastWord;
 var N, Z : Byte;
 begin
    if (Ps = 1) or (Sze < 2) then Exit;
    Z := 0;
    for N := Ps-1 downto 1 do if (Z = 0) and (S[N] in [' ','-']) then Z := N;
    if Z = 0 then Z := 1;
    if Ps = Z then Exit;
    if Z > Ps then oMoveRight(Z-Ps) else oMoveLeft(Ps-Z);
    Ps := Z;
 end;

 procedure ClearEol;
 var Z : Byte;
 begin
    if (Ps = Sze) then Exit;
    for Z := Ps to Sze do oWrite(' ');
    oMoveLeft(Sze-Ps+1);
    Delete(S,Ps,255);
    Sze := Ps;
 end;

 procedure ClearItAll;
 var Z : Byte;
 begin
    if (Sze = 1) then Exit;
    oMoveLeft((Ps-1));
    for Z := 1 to Sze do oWriteChar(' ');
    oMoveLeft(Sze);
    Delete(S,1,255);
    Sze := 1;
    Ps := 1;
 end;

 procedure DoTab;
 var Z : Byte;
 begin
    for Z := 1 to 4 do AddChar(' ');
 end;

 procedure DrawBackground;
 begin
    oSetCol(colEdit);
    oWrite(sRepeat(' ',Len));
    oWrite(sRepeat(#8,Len));
 end;

 procedure InitVars;
 begin
    Ch      := #1;
    Done    := False;
    Ins     := True;
    S       := '';
    Ps      := 1;
    Sze     := 1;
    Int     := 1;

    Password := False;
    NoCR     := False;
    NoIns    := False;
    NoEdit   := False;
    Min      := False;
    Space    := False;
    Req      := False;
    NoClean  := False;
    Abort    := False;
    Backgr   := False;
 end;

begin
   InitVars;
   GetOptions;
   if Backgr then DrawBackground;
   Inc(Len,1);
   if not emuANSi then NoEdit := True;
   Ins := not NoIns;
   if Def <> '' then for Int := 1 to Length(Def) do AddChar(Def[Int]);
   repeat
      Ch := iReadKey;
      if (extKey <> #0) then
      begin
         case extKey of
{Left}     #75  : if (not NoEdit) and (Ps > 1) then begin Dec(Ps,1); oMoveLeft(1); end;
{Right}    #77  : if (not NoEdit) and (Ps < Sze) then begin Inc(Ps,1); oMoveRight(1); end;
{Home}     #71  : if (not NoEdit) and (Ps > 1) then begin oMoveLeft(Ps-1); Ps := 1; end;
{End}      #79  : if (not NoEdit) and (Ps < Sze) then begin oMoveRight(Sze-Ps); Ps := Sze; end;
{Insert}   #82  : if (not NoIns) and (not NoEdit) then Ins := not Ins;
{Delete}   #83  : if not NoEdit then DelChar;
{Ctrl <-}  #115 : if not NoEdit then LastWord;
{Ctrl ->}  #116 : if not NoEdit then NextWord;
{Ctrl End} #117 : if not NoEdit then ClearEol;
         end;
      end else
      case Ch of
{Enter}    #13 : if ((not Min) or (Ps > 1)) and
                    ((not Req) or (Ps = Len)) then Done := True;
{Bkspace}  #8  : Backspace;
{Tab}      #9  : DoTab;
{Ctrl Y}   #25 : if not NoEdit then ClearItAll;
{ESC / ^Z} #26..#27 : if Abort then begin S := ''; Done := True; end;
{Anything} #32..#254 : AddChar(Ch);
      end;
   until (HangUp) or (Done);
   if (HangUp) and (S = '') then S := Def;
   if Backgr then oSetCol(colInfo);
   if not NoCR then oDnLn(1);
   if not NoClean then S := CleanUp(S);
   iReadString := S;
end;
*)
function iReadDate(def : String) : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   if def = '' then S := '  /  /  ' else S := def;
   Done := False;
   oWrite(S);
   if def = '' then
   begin
      P := 1;
      oMoveLeft(8);
   end else P := 9;
   repeat
      C := iReadKey;
      case C of
        '0'..'9' :
           case P of
             1,4,7,8 : begin
                          oWriteChar(C);
                          S[P] := C;
                          Inc(P);
                       end;
             2,5     : begin
                          oWrite(C+'/');
                          S[P] := C;
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 9 then Done := True;
        #8  :
          case P of
            4,7     : begin
                         oMoveLeft(1);
                         oBackspace(' ');
                         S[P] := ' ';
                         Dec(P,2);
                      end;
           2,5,8,9  : begin
                         oBackSpace(' ');
                         S[P] := ' ';
                         Dec(P);
                      end;
          end;
      end;
   until (HangUp) or (Done);
   iReadDate := S;
   oDnLn(1);
end;

function iReadPhone(def : String) : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   S := def;
   if S = '' then S := '(   )   -    ';
   Done := False;
   oWrite(S);
   if Def = '' then
   begin
      P := 2;
      oMoveLeft(12);
   end else P := 14;
   repeat
      C := iReadKey;
      case C of
        '0'..'9' :
           case P of
             2,3,6,7,10,11,12,13
                     : begin
                          oWriteChar(C);
                          S[P] := C;
                          Inc(P);
                       end;
             4       : begin
                          oWrite(C+')');
                          S[P] := C;
                          Inc(P,2);
                       end;
             8       : begin
                          oWrite(C+'-');
                          S[P] := C;
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 14 then Done := True;
        #8  :
          case P of
            6,10     : begin
                          oMoveLeft(1);
                          oBackSpace(' ');
                          S[P] := ' ';
                          Dec(P,2);
                       end;
            3,4,6,7,8,10,11,12,13,14
                     : begin
                          oBackSpace(' ');
                          S[P] := ' ';
                          Dec(P);
                       end;
          end;
      end;
   until (HangUp) or (Done);
   iReadPhone := S;
   oDnLn(1);
end;

function iReadTime(def : String) : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   S := def;
   if S = '' then S := '  :  ';
   Done := False;
   oWrite(S);
   if Def = '' then
   begin
      P := 1;
      oMoveLeft(5);
   end else P := 6;
   repeat
      C := iReadKey;
      case C of
        '0'..'9' :
           case P of
             1,4,5
                     : if ((P = 1) and (C in ['0'..'2'])) or
                          ((P = 4) and (C in ['0'..'5'])) or
                          (P = 5) then
                       begin
                          oWriteChar(C);
                          S[P] := C;
                          Inc(P);
                       end;
             2       : begin
                          oWrite(C+':');
                          S[P] := C;
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 6 then Done := True;
        #8  :
          case P of
            4        : begin
                          oMoveLeft(1);
                          oBackSpace(' ');
                          S[P] := ' ';
                          Dec(P,2);
                       end;
            2,5,6    : begin
                          oBackSpace(' ');
                          S[P] := ' ';
                          Dec(P);
                       end;
          end;
      end;
   until (HangUp) or (Done);
   iReadTime := S;
   oDnLn(1);
end;

function iReadZipCode : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   S := '     -    ';
   Done := False;
   oWrite(S);
   P := 1;
   oMoveLeft(10);
   repeat
      C := iReadKey;
      case C of
        '0'..'9' :
           case P of
             1,2,3,4,7,8,9,10
                     : begin
                          oWriteChar(C);
                          S[P] := C;
                          Inc(P);
                       end;
             5       : begin
                          oWrite(C+'-');
                          S[P] := C;
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 11 then Done := True;
        #8  :
          case P of
            2,3,4,5,8,9,10,11
                     : begin
                          oBackSpace(' ');
                          S[P] := ' ';
                          Dec(P);
                       end;
            7        : begin
                          oMoveLeft(1);
                          oBackSpace(' ');
                          S[P] := ' ';
                          Dec(P,2);
                       end;
          end;
      end;
   until (HangUp) or (Done);
   iReadZipCode := S;
   oDnLn(1);
end;

function iReadPostalCode : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   S := '   -   ';
   Done := False;
   oWrite(S);
   P := 1;
   oMoveLeft(7);
   repeat
      C := UpCase(iReadKey);
      case C of
        '0'..'9','A'..'Z' :
           case P of
             1,2,5,6,7
                     : if ((C in ['A'..'Z']) and (P in [1,6])) or
                          ((C in ['0'..'9']) and (P in [2,5,7])) then
                       begin
                          oWriteChar(C);
                          S[P] := C;
                          Inc(P);
                       end;
             3       : if C in ['A'..'Z'] then
                       begin
                          oWrite(C+'-');
                          S[P] := C;
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 8 then Done := True;
        #8  :
          case P of
            2,3,6,7,8
                     : begin
                          oBackSpace(' ');
                          S[P] := ' ';
                          Dec(P);
                       end;
            5        : begin
                          oMoveLeft(1);
                          oBackSpace(' ');
                          S[P] := ' ';
                          Dec(P,2);
                       end;
          end;
      end;
   until (HangUp) or (Done);
   iReadPostalCode := S;
   oDnLn(1);
end;

function iYesNoBar(Def : Boolean) : Boolean;
var C : Char; Yes : Boolean; X : Byte;
 procedure WriteNo;
 begin
    oPosX(x);
    oStr(Cfg^.pmtNoBar);
    Yes := False;
 end;
 procedure WriteYes;
 begin
    oPosX(x);
    oStr(Cfg^.pmtYesBar);
    Yes := True;
 end;
begin
   mCursor(False);
   X := oWhereX;
   if Def then oStr(Cfg^.pmtYesBar) else oStr(Cfg^.pmtNoBar);
   Yes := Def;
   repeat
      C := UpCase(iReadKey);
      if (Yes)     and ((extKey in [#77,#75]) or (C in ['4','6',' ','N'])) then WriteNo else
      if (not Yes) and ((extKey in [#77,#75]) or (C in ['4','6',' ','Y'])) then WriteYes;
   until (HangUp) or (C in [#13,'Y','N']);
   oSetCol(colInfo);
   if C = 'Y' then Yes := True else if C = 'N' then Yes := False;
   oDnLn(1);
   mCursor(True);
   if HangUp then iYesNoBar := Def else iYesNoBar := Yes;
end;

function iYesNo(Def : Boolean) : Boolean;
var C : Char;
begin
   if acYesNoBar in User^.acFlag then
   begin
      iYesNo := iYesNoBar(Def);
      Exit;
   end;
   if Def then oStr(Cfg^.pmtYes) else oStr(Cfg^.pmtNo);
   repeat
      C := UpCase(iReadKey);
   until (HangUp) or ((extKey = #0) and (C in ['Y','N',#13]));
   if HangUp then iYesNo := Def else
   case C of
     'Y' : begin iYesNo := True;  oStrLn(Cfg^.pmtYesWord); end;
     'N' : begin iYesNo := False; oStrLn(Cfg^.pmtNoWord); end;
     #13 : if Def then
           begin iYesNo := True;  oStrLn(Cfg^.pmtYesWord); end else
           begin iYesNo := False; oStrLn(Cfg^.pmtNoWord); end;
   end;
end;

procedure iMenuSystem(var Menu; var Cur : Byte; Num : Byte);
type MnuArray = array[1..40] of tMenuItemRec;
var Item : ^MnuArray; X : Byte; Ch : Char;
 procedure DrawItem(It : Byte; Hi : Boolean);
 begin
    oGotoXY(Item^[It].X,Item^[It].Y);
    if Hi then oSetColRec(Item^[It].HiCol) else oSetColRec(Item^[It].LoCol);
    oWrite(Item^[It].Txt);
 end;
begin
   Item := @Menu;
   for X := 1 to Num do DrawItem(X,False);
   DrawItem(Cur,True);
   repeat
      Ch := iReadKey;
      case extKey of
         #72,#75 : begin DrawItem(Cur,False); Dec(Cur,1);
                       if Cur < 1 then Cur := Num; DrawItem(Cur,True); end;
         #80,#77 : begin DrawItem(Cur,False); Inc(Cur,1);
                       if Cur > Num then Cur := 1; DrawItem(Cur,True); end;
      end;
   until (HangUp) or (Ch = #27);
end;

function iGetString(f, c, p, l, d, e : String) : String;
var Inp : tInFlag; Cha : tInChar; Len, plen : Byte;
begin
   iGetString := inputString;
   if (f = '') or (c = '') or (p = '') or (l = '') then Exit;
   case UpCase(F[1]) of
      'N' : Inp := inNormal;
      'C' : Inp := inCapital;
      'U' : Inp := inUpper;
      'L' : Inp := inLower;
      'M' : Inp := inMixed;
      'V' : Inp := inWeird;
      'W' : Inp := inWarped;
      'I' : Inp := inCool;
       else Inp := inNormal;
   end;
   case UpCase(C[1]) of
      'A' : Cha := chAlpha;
      'I' : Cha := chAnyNum;
      'F' : Cha := chFilename;
      'D' : Cha := chDirectory;
      'E' : Cha := chFileNoExt;
      'N' : Cha := chNumeric;
       else Cha := chNormal;
   end;
   Len := strToInt(l);
   if (l = '*') or (Len = 0) then Len := 255;
   if d = '*' then d := inputString;
   plen := strToInt(e);
   if (e = '*') or (plen = 0) then iGetString := iReadString(d,Inp,Cha,p,Len) else
                                   iGetString := iEditString(d,Inp,Cha,p,Len,plen);
end;

function iXprompt(var Cmds; numC, def : Byte) : Byte;
type tStrArray = array[1..20] of String;
var Cmd : ^tStrArray; Y, Z : Byte; Pos : array[1..20] of Byte; C : Char;
 procedure Bar(I : Byte);
 begin
    oPosX(Pos[I]);
    oSetCol(colItemSel);
    oStrCtr(' '+Cmd^[I]+' ');
 end;
 procedure NoBar(I : Byte);
 begin
    oPosX(Pos[I]);
    oSetCol(colItem);
    oStrCtr(' '+Cmd^[I]+' ');
 end;
begin
   Cmd := @Cmds;
   mCursor(False);
   iXprompt := def;
   oSetCol(colItem);
   for Z := 1 to numC do
   begin
      Pos[Z] := oWhereX;
      oStrCtr(' '+Cmd^[Z]+' ');
   end;
   Z := def;
   Bar(z);
   repeat
      C := UpCase(iReadKey);
      if ((extKey = rtArrow) or (C in ['6',' '])) then
      begin
         NoBar(Z);
         Inc(Z);
         if Z > numC then Z := 1;
         Bar(Z);
      end else
      if ((extKey = lfArrow) or (C = '4')) then
      begin
         NoBar(Z);
         Dec(Z);
         if Z < 1 then Z := numC;
         Bar(Z);
      end;
   until (HangUp) or (C = #13);
   oSetCol(colInfo);
   oDnLn(1);
   mCursor(True);
   if HangUp then iXprompt := Def else iXprompt := Z;
end;

function iEditString(Def   : String;
                     iFl   : tInFlag;
                     iCh   : tInChar;
                     Opt   : String;
                     Len   : Byte;
                     pgLen : Byte) : String;

var
   Ch           : Char;
   Done         : Boolean;
   S            : String;
   pStr         : Integer;
   pSrt         : Integer;
   pCur         : Integer;
   xSrt         : Integer;

   optAbort     : Boolean;
   optNoIns     : Boolean;
   optPassword  : Boolean;
   optNoCR      : Boolean;
   optNoEdit    : Boolean;
   optMin       : Boolean;
   optSpace     : Boolean;
   optReq       : Boolean;
   optNoClean   : Boolean;
   optBackgr    : Boolean;

   Ins          : Boolean;

 procedure esInitOptions;
 begin
    optAbort     := Pos(rsAbort,Opt)    > 0;
    optNoIns     := Pos(rsNoIns,Opt)    > 0;
    optPassword  := Pos(rsPassword,Opt) > 0;
    optNoCR      := Pos(rsNoCR,Opt)     > 0;
    optNoEdit    := Pos(rsNoEdit,Opt)   > 0;
    optMin       := Pos(rsMin,Opt)      > 0;
    optSpace     := Pos(rsSpace,Opt)    > 0;
    optReq       := Pos(rsReq,Opt)      > 0;
    optNoClean   := Pos(rsNoClean,Opt)  > 0;
    optBackgr    := Pos(rsBackGr,Opt)   > 0;
 end;

 procedure esAbort;
 begin
    if not optAbort then Exit;
    S := Def;
    Done := True;
 end;

 function xCur : Integer;
 begin
    xCur := oWhereX-xSrt+1;
 end;

 procedure esPos;
 begin
    pCur := pStr-pSrt+1;
 end;

 procedure esProcessChar(var C : Char);
 begin
    case iFl of
    inCapital : begin
                   if (pStr > 1) and (not (UpCase(S[pStr-1]) in ['A'..'Z','0'..'9','''','"']))
                      then C := UpCase(C); { else C := LowCase(C);}
                   if pStr = 1 then C := UpCase(C);
                end;
      inUpper : C := UpCase(C);
      inLower : C := LowCase(C);
      inMixed : begin
                   if (pStr > 1) and (not (UpCase(S[pStr-1]) in ['A'..'Z','0'..'9','''','"']))
                      then C := UpCase(C) else C := LowCase(C);
                   if pStr = 1 then C := UpCase(C);
                end;
      inWeird : if UpCase(C) in ['A','E','I','O','U'] then C := LowCase(C) else
                   C := UpCase(C);
     inWarped : if UpCase(C) in ['A','E','I','O','U'] then C := UpCase(C) else
                   C := LowCase(C);
       inCool : if UpCase(C) = 'I' then C := LowCase(C) else C := UpCase(C);
    end;
{   case iFl of
      inUpper : C := UpCase(C);
      inLower : C := LowCase(C);
      inMixed : begin
                   if (pStr > 1) and (not (UpCase(S[pStr-1]) in ['A'..'Z','0'..'9','''','"']))
                      then C := UpCase(C) else C := LowCase(C);
                   if pStr = 1 then C := UpCase(C);
                end;
      inWeird : if UpCase(C) in ['A','E','I','O','U'] then C := LowCase(C) else
                   C := UpCase(C);
       inCool : if UpCase(C) = 'I' then C := LowCase(C) else C := UpCase(C);
    end;}
 end;

 procedure esWrite(S : String);
 begin
    if optPassword then oWritePw(S) else oWrite(S);
 end;

 procedure esRedraw;
 begin
    esPos;
    oPosX(xSrt);
    esWrite(strResizeNc(Copy(S,pSrt,pgLen),pgLen));
    oPosX(xSrt+pCur-1);
 end;

 procedure esRedrawToEol;
 begin
    esPos;
    esWrite(strResizeNc(Copy(S,pStr,pgLen-pCur+1),pgLen-pCur+1));
    oPosX(xSrt+pCur-1);
 end;

 procedure esScrollRight;
 begin
    esPos;
    if pgLen > 5 then Inc(pSrt,5) else Inc(pSrt,1);
    if pSrt > Length(S) then pSrt := Length(S);
    if pSrt > Len then pSrt := Len;
    esPos;
    esRedraw;
 end;

 procedure esScrollLeft;
 begin
    esPos;
    if pgLen > 5 then Dec(pSrt,5) else Dec(pSrt,1);
    if pSrt < 1 then pSrt := 1;
    esPos;
    esRedraw;
 end;

 procedure esAddChar(Ch : Char);
 begin
    if (Length(S) >= Len) or ((pStr = 1) and (Ch = ' ') and (not optSpace)) then Exit;

    esProcessChar(Ch);

    if not (Ch in iCh) then Exit;

    esPos;
    if pCur > pgLen then esScrollRight;

    if pStr > Length(S) then
    begin
       Inc(pStr);
       esWrite(Ch);
       S := S+Ch;
       esPos;
    end else
    if Ins then
    begin
       Insert(Ch,S,pStr);
       esRedrawToEol;
       Inc(pStr);
       Inc(pCur);
       esWrite(Ch);
    end else
    begin
       S[pStr] := Ch;
       Inc(pStr);
       Inc(pCur);
       esWrite(Ch);
    end;

 end;

 procedure esBackSpace;
 begin
    if Length(S) = 0 then Exit;
    if (pCur > 1) and (pStr = Length(S)+1) then
    begin
       Delete(S,Length(S),1);
       oBackspace(' ');
       Dec(pStr);
    end else
    if (Length(S) > 0) and (pCur = 1) and
       (pStr = Length(S)+1) and (pSrt > 1) then
    begin
       Delete(S,Length(S),1);
       pStr := Length(S)+1;
       esScrollLeft;
    end else if pStr > 1 then
    begin
       Delete(S,pStr-1,1);
       Dec(pStr);
       if pCur = 1 then esScrollLeft else
       begin
          Dec(pCur);
          oWrite(#8);
          esRedrawToEol;
       end;
    end;
 end;

 procedure esDeleteChar;
 begin
    if (pStr = 0) or (pStr > Length(S)) or (Length(S) = 0) then Exit;
    Delete(S,pStr,1);
    esRedrawToEol;
 end;

 procedure esCursorRight;
 begin
    if pStr = Length(S)+1 then Exit;
    esPos;
    if pCur = pgLen then esScrollRight;

    Inc(pStr);
    oMoveRight(1);
    esPos;
 end;

 procedure esCursorLeft;
 begin
    if pStr = 1 then Exit;
    esPos;
    if pCur = 1 then esScrollLeft;

    Dec(pStr);
    oMoveLeft(1);
    esPos;
 end;

 procedure esCursorHome;
 begin
    if pStr = 1 then Exit;
    pStr := 1;
    pSrt := 1;
    pCur := 1;
    esPos;
    esRedraw;
 end;

 procedure esCursorEnd;
 begin
    if pStr > Length(S) then Exit;
    esPos;
    pStr := Length(S)+1;
    pSrt := Length(S)-pgLen+2;
    if pSrt < 1 then pSrt := 1;
    pCur := pgLen-1;
    esRedraw;
 end;

 procedure esTab;
 var N : Byte;
 begin
    for N := 1 to 4 do esAddChar(' ');
 end;

 procedure esClearEol;
 begin
    if (Length(S) = 0) or (pStr = Length(S)+1) then Exit;
    S[0] := Chr(pStr-1);
    esRedrawToEol;
 end;

 procedure esClearItAll;
 begin
    if Length(S) = 0 then Exit;
    S := '';
    pStr := 1;
    pSrt := 1;
    pCur := 1;
    esRedraw;
 end;

 procedure esBackground;
 begin
    oSetCol(colEdit);
    oWrite(sRepeat(' ',Len));
    oPosX(xSrt);
 end;

begin
   esInitOptions;
   Ins := (not optNoEdit) and (not optNoIns);
   Done := False;
   S := Def;
   xSrt := oWhereX;
   if pgLen = 0 then
   begin
      pgLen := Len+1;
      if pgLen+xSrt > 79 then pgLen := 79-xSrt+1;
   end;
   if optBackgr then esBackground;
   for pStr := 1 to Length(S) do
   begin
      esProcessChar(S[pStr]);
      if not (S[pStr] in iCh) then S[pStr] := ' ';
   end;
   if Length(S) > Len then Delete(S,Len+1,255);
   pStr := Length(S)+1;
   pSrt := Length(S)-pgLen+1;
   if pSrt < 1 then pSrt := 1;
   esPos;
   esWrite(Copy(S,pSrt,pgLen));

   repeat
      esPos;
      Ch := iReadKey;
      if extKey <> #0 then
      begin
         case extKey of
            RtArrow : if not optNoEdit then esCursorRight;
            LfArrow : if not optNoEdit then esCursorLeft;
            homeKey : if not optNoEdit then esCursorHome;
            endKey  : if not optNoEdit then esCursorEnd;
          DeleteKey : if not optNoEdit then esDeleteChar;
          InsertKey : if (not optNoEdit) and (not optNoIns) then Ins := not Ins;
               #117 : if not optNoEdit then esClearEol;
         end;
      end else
      case Ch of
        CtrlZ,
        Escape    : esAbort;
        #9        : esTab;
        BkSpace   : esBackSpace;
        Enter     : if ((not optMin) or (pStr > 1)) and
                       ((not optReq) or (Length(S) = Len)) then Done := True;
        ^Y        : if not optNoEdit then esClearItAll;
        #32..#254 : esAddChar(Ch);
      end;
   until (HangUp) or (Done);
   if not optNoCR then oDnLn(1);
   if not optNoClean then S := CleanUp(S);
   iEditString := S;
end;

function iReadString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte) : String;
begin
   iReadString := iEditString(Def,iFl,iCh,Opt,Len,0);
end;

end.