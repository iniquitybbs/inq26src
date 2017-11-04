{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit ChatMode;

interface

procedure chatBeep;
procedure chatNormal;
procedure chatPage(Matrix : Boolean);
procedure chatSplitScreen;

implementation

uses Crt,
     Global, Comm, Output, Input, Strings, ShowFile, Emulate, Transfer, Logs,
     Misc, DateTime, Tetris, StatBar, Email;

procedure chatNormal;
const
   maxLineLen = 80;
var
   WordLine  : String[maxLineLen];
   Index1    : Byte;
   Index2    : Byte;
   InputChar : Char;
   Ok, Down  : Boolean;
   Done      : Boolean;
   dt1,dt2,dt3
             : tDateTimeRec;
   S, P      : String;
begin
   ChatModeOn := True;
   emuScreenToANSi;
   logWrite('*Chat mode initiated.');
   if Cfg^.LogLineChat then
   begin
      logChatWrite('');
      logChatWrite('-- Line chat with user: '+User^.Username+' ('+User^.RealName+')');
      logChatWrite('   at '+dtTimeStr12+', '+dtDateString);
      logChatWrite(sRepeat('Ä',79));
   end;
   dtGetDateTime(dt1);
   WordLine  := '';
   Index1    := 0;
   Index2    := 0;
   InputChar := ' ';
   oStringLn(strChatInitiate);
   oSetCol(colInfo);
   Done      := False;
   repeat
      InputChar := iReadKey;
      if extKey <> #0 then
      case extKey of
         AltC : if LocKey then Done := True;
         LfArrow  : oMoveLeft(1);
         RtArrow  : oMoveRight(1);
         DnArrow  : oMoveDown(1);
         UpArrow  : oMoveUp(1);
      end else
      if (InputChar = #8) and (Length(WordLine) > 0) then
      begin
         oBackspace(' ');
         Delete(WordLine,Length(WordLine),1)
      end else
      if InputChar = #13 then
      begin
         if Cfg^.LogLineChat then logChatWrite(WordLine);
         Ok := True;
         Down := True;
         if (Length(WordLine) >= 2) and (WordLine[1] = '/') then
         begin
            S := CleanUp(UpStr(Copy(WordLine,2,255)));
            if Pos(' ',S) > 0 then
            begin
               P := Copy(S,Pos(' ',S)+1,255);
               Delete(S,Pos(' ',S),255);
            end else P := '';
            if (S = 'TYPE') and (P <> '') then begin oDnLn(1); sfShowTextFile(P,ftNormal) end else
            if (S = 'SEND') and (P <> '') then xferSend(P,[protActive]) else
            if (S = 'RECEIVE') and (P <> '') then xferReceive(P,[protActive]) else
{           if (S = 'BATCH') and (P <> '') then xferAddToBatch(P) else}
            if (S = 'ACS') and (P <> '') then
            begin
               oMoveLeft(maxLineLen);
               if acsOk(P) then oStrLn('|U2-- |U1Access |U3ok|U2.') else
                                oStrLn('|U2-- |U1Access |U3denied|U2.');
               Down := False;
            end;
            if S = 'SENDBATCH' then xferSend('',[protActive,protBatch]) else
            if S = 'PAGE' then begin chatBeep; oWriteRem(#7#7); end else
            if S = 'RECEIVEBATCH' then xferReceive('',[protActive,protBatch]) else
            if S = 'TETRIS' then itPlayTetris else
            if S = 'TIME' then
            begin
               oMoveLeft(maxLineLen);
               dtGetDateTime(dt2);
               dtTimeDiff(dt3,dt1,dt2);
               oStrLn('|U2-- |U1Current time|U2: |U3'+dtTimeStr12+'|U2, |U1date|U2: |U3'+dtDateString);
               oStrLn('   |U1Chatting for|U2: |U3'+dtTimeRecStr(dt3));
               Down := False;
            end else
            if S = 'CLS' then begin Down := False; oClrScr; end else
            if S = 'BYE' then HangUp := True else
            if S = 'Q' then Done := True else
            if S = '?' then sfShowTextFile(txChatHelp,ftNormal);
         end;
         if Down then oDnLn(1);
         if Ok then WordLine := '';
      end else if not (InputChar in [#0..#31,#255]) then
      begin
        if LocKey then oSetCol(colInfoHi) else oSetCol(colInfo);
        oWriteChar(InputChar);
        WordLine := (WordLine+InputChar);
        if (Length(WordLine) >= (maxLineLen-1)) then
        begin
           Index1 := (maxLineLen-1);
           while ((WordLine[Index1] <> ' ') and (WordLine[Index1] <> '-')
                 and (Index1 <> 0)) do Dec(Index1);
           if (Index1 = 0) then Index1 := (maxLineLen - 1);
           if Cfg^.LogLineChat then logChatWrite(Copy(WordLine,1,Index1));
           Delete(WordLine,1,Index1);
           for Index2 := 1 to Length(WordLine) do oBackspace(' ');
           oDnLn(1);
           oWrite(WordLine);
        end;
      end;
   until (HangUp) or (Done);
   if (Cfg^.LogLineChat) and (WordLine <> '') then logChatWrite(WordLine);
   ChatModeOn := False;
   dtGetDateTime(dt2);
   dtTimeDiff(dt3,dt1,dt2);
   if Cfg^.RestoreChatTime then timeFree := timeFree+dtDateToReal(dt3);
   logWrite('*Chat mode terminated.');
   if Hangup then Exit;
   oStringLn(strChatTerminate);
   emuANSitoScreen;
end;

procedure chatSplitScreen;
type
   tWindow = record
      x1,y1,x2,y2,x,y : Byte;
      Col : tColorRec;
      Word : String;
   end;
var
   InputChar   : Char;
   A           : Byte;
   Key         : Byte;
   Des         : Boolean;
   Win         : array[1..2] of tWindow;
   oldPos      : Pointer;
   dt1,dt2,dt3 : tDateTimeRec;
 procedure CheckWindows;
 begin
    if (Key <> A) then
    begin
       A := Key;
       oGotoXY(Win[A].x1+Win[A].x-1,Win[A].y1+Win[A].y-1);
       oSetColRec(Win[A].Col);
    end;
 end;
 procedure ClearWin(Z : Byte);
 var N : Byte; S : String;
 begin
    S := '';
    for N := Win[Z].x1 to Win[Z].x2 do S := S + ' ';
    for N := Win[Z].y1 to Win[Z].y2 do
    begin
       oGotoXY(Win[Z].x1,N);
       oWrite(S);
    end;
    oGotoXY(Win[Z].x1,Win[Z].y1);
    Win[Z].x := 1; Win[Z].y := 1;
    if Des then Win[Z].Word := '';
    A := Z;
 end;
 procedure LogWord(A : Byte; X : String);
 var S : String;
 begin
    case A of 1: S := Cfg^.SysOpAlias; 2: S := User^.UserName; end;
    if S = '' then S := '??';
    if Cfg^.LogSplitChat then logChatWrite(mInitials(S)+'> '+X);
 end;

 procedure DoEnter(reDraw : Boolean);
 var S : String;
 begin
    CheckWindows;
    Inc(Win[A].y,1);
    Win[A].x := 1;
   {if Win[A].x > Win[A].x2-Win[A].x1 then DoEnter;}
    if Win[A].y > Win[A].y2-Win[A].y1+1 then
    begin
       S := Win[A].Word;
       ClearWin(A);
       if (reDraw) and (CleanUp(S) <> '') then
       begin
          oCWrite(S);
          Win[A].y := 2;
          Win[A].x := 1;
       end;
    end;
    if des then Win[A].Word := '';
    oGotoXY(Win[A].x1+Win[A].x-1,Win[A].y1+Win[A].y-1);
 end;
 procedure WriteIt(S : String);
 begin
    CheckWindows;
    oCWrite(S);
    Inc(Win[A].x,Length(S));
 end;
 procedure DoBackspace;
 begin
    if Length(Win[A].Word) < 1 then Exit;
    CheckWindows;
    oBackspace(' ');
    if des then Delete(Win[A].Word,Length(Win[A].Word),1);
    Dec(Win[A].x,1);
 end;
 procedure CheckWrap;
 var Mx, Z, V : Byte;
 begin
    Win[A].Word := (Win[A].Word+InputChar);
    Mx := Win[A].x2-Win[A].x1;
    if (Length(Win[A].Word) >= (Mx-1)) then
    begin
       Des := False;
       Z := (Mx-1);
       while (not (Win[A].Word[Z] in [' ','-'])) and (Z <> 0) do Dec(Z,1);
       if Z = 0 then Z := Mx-1;
       LogWord(A,Copy(Win[A].Word,1,Z));
       Delete(Win[A].Word,1,Z);
       for V := 1 to Length(Win[A].Word) do DoBackspace;
       DoEnter(False);
       WriteIt(Win[A].Word);
       Des := True;
    end;
 end;
begin
   if sfGetTextFile(txChatMode,ftChatMode) = '' then
   begin
      logWrite('xSplit-screen chat attempted, but template did not exist.');
      chatNormal;
      Exit;
   end;

   if Cfg^.LogSplitChat then
   begin
      logChatWrite('');
      logChatWrite('-- SplitScreen chat with user: '+User^.Username+' ('+User^.RealName+')');
      logChatWrite('   at '+dtTimeStr12+', '+dtDateString);
      logChatWrite(sRepeat('Ä',79));
   end;
   dtGetDateTime(dt1);

   GetMem(oldPos,SizeOf(sfPos));
   Move(sfPos,oldPos^,SizeOf(sfPos));

   ChatModeOn := True;
   emuScreenToANSi;
   InputChar  := #0;

   sfShowTextFile(txChatMode,ftChatMode);

   A          := 1;
   Win[1].x1  := sfPos[1].X;
   Win[1].y1  := sfPos[1].Y;
   Win[1].x2  := sfPos[2].X;
   Win[1].y2  := sfPos[2].Y;
   Win[1].Col := sfPos[1].C;
   Win[1].x   := 1;
   Win[1].y   := 1;

   Win[2].x1  := sfPos[3].X;
   Win[2].y1  := sfPos[3].Y;
   Win[2].x2  := sfPos[4].X;
   Win[2].y2  := sfPos[4].Y;
   Win[2].Col := sfPos[3].C;
   Win[2].x   := 1;
   Win[2].y   := 1;

   ClearWin(2);
   ClearWin(1);
   oSetColRec(Win[A].Col);
   repeat
      InputChar := iReadKey;
      if LocKey then Key := 1 else Key := 2;
      if extKey = #0 then
      case InputChar of
          #32..#254 : begin
             CheckWindows;
             WriteIt(InputChar);
             CheckWrap;
          end;
          #8  : DoBackspace;
          #13 : begin
             LogWord(Key,Win[Key].Word);
             DoEnter(True);
          end;
          else cCheckUser;
      end;
   until (HangUp) or ((locKey) and (extKey = altX));
   if Win[1].Word <> '' then LogWord(1,Win[1].Word) else
   if Win[2].Word <> '' then LogWord(2,Win[2].Word);
   ChatModeOn := False;
   dtGetDateTime(dt2);
   dtTimeDiff(dt3,dt1,dt2);
   if Cfg^.RestoreChatTime then timeFree := timeFree+dtDateToReal(dt3);
   Move(oldPos^,sfPos,SizeOf(sfPos));
   FreeMem(oldPos,SizeOf(sfPos));
   logWrite('*Split-screen chat terminated.');
   if Hangup then Exit;
   emuANSitoScreen;
end;

procedure chatBeep;
var Z : Word;
begin
   for Z := 32 downto 1 do
   begin
      Sound(Z*100);
      Delay(5);
      Sound(Z*60);
      Delay(4);
   end;
   for Z := 1 to 15 do
   begin
      Sound(Z*40);
      Delay(3);
      Sound(Z*80);
      Delay(4);
      Sound(Z*70);
      Delay(2);
   end;
   for Z := 15 downto 1 do
   begin
      Sound(Z*20);
      Delay(3);
      Sound(Z*40);
      Delay(1);
      Sound(Z*50);
      Delay(2);
   end;
   Delay(80);
   Sound(2000);
   for z := 2000 downto 1500 do if z mod 10 = 0 then
   begin
      Delay(1);
      Sound(z);
   end;
   Delay(80);
   for z := 2000 downto 1500 do if z mod 20 = 0 then
   begin
      Delay(1);
      Sound(z);
   end;
   Delay(80);
   NoSound;
end;

procedure chatPage(Matrix : Boolean);
var Why, pw : String; Z : Byte; noise, chat, done : Boolean; ch : Char;
 procedure cpMail;
 begin
    if (not Matrix) and (Cfg^.pageAskEmail) and (acsOk(Cfg^.acsPostEmail)) then
    begin
       oStr(strCode(mStr(strPageLeaveEmail),1,Cfg^.SysOpAlias));
       if iYesNo(False) then emailEnterEmail('1','',True);
    end;
 end;
begin
   oDnLn(1);
   if (not Matrix) and (Cfg^.maxPageTimes <> 0) and (numPaged >= Cfg^.maxPageTimes) then
   begin
      oStrLn(strCode(mStr(strPageNoMore),1,St(Cfg^.maxPageTimes)));
      Exit;
   end;

   if not mSysOpAvail then
   begin
      if (not matrix) and (acsOk(Cfg^.chatOverAcs)) then
      begin
         oString(strPageAskOverride);
         if not iYesNo(False) then
         begin
            cpMail;
            Exit;
         end;
         if Cfg^.NoChatPw <> '' then
         begin
            oString(strPageAskPassword);
            pw := iReadString('',inUpper,chNormal,rsPassword+rsNoEdit,20);
            if pw <> Cfg^.NoChatPw then
            begin
               oStringLn(strPageBadPw);
               logWrite('User entered wrong chat override password ['+pw+']');
               Exit;
            end;
            logWrite('User entered correct chat override password');
         end;
      end else
      begin
         oStringLn(strPageSysOpNotAvail);
         cpMail;
         Exit;
      end;
   end;

   oString(strPageAskWhy);
   Why := iReadString('',inNormal,chNormal,'',70);
   if Why = '' then Exit;
   chatReason := Why;

   if Matrix then logWrite('-Paged sysop from matrix; reason: "'+Why+'"') else
                  logWrite('-User paged sysop; reason: "'+Why+'"');
   if not Matrix then Inc(numPaged);

   noise := Cfg^.chatPageNoise;
   done := False;
   chat := False;
   z := 0;
   sbInfo('|H'+User^.Username+'|L: |MPaging sysop |L... [|Hspace|L] |MChat  |L[|Henter|L] |MNoise  |L[|Hesc|L] |MAbort',True);
   oStringLn(strPageBegin);
   while (z < Cfg^.maxPageBeeps) and (not done) do
   begin
      Inc(z);
      oString(strPagePaging);
      oWriteRem(#7);
      if noise then chatBeep else Delay(1200);
      if iKeypressed then
      begin
         ch := iReadKey;
         if LocKey then
         case ch of
           #13 : noise := not noise;
           #27 : done := True;
           #32 : begin done := True; chat := True; end;
         end else done := True;
      end;
   end;
   sbInfo('',False);
   oDnLn(1);
   if chat then chatNormal else
   begin
      oStringLn(strPageNoAnswer);
      cpMail;
      if Matrix then oPromptKey;
   end;
end;

end.