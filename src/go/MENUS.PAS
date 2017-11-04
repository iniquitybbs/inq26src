{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Menus;

interface

uses Global, Strings, Output, Misc, Input, MenuCmd, Comm, ShowFile, Logs;

function  menuAccess(I : Integer; var CmdNotHid : Boolean) : Boolean;
procedure menuChange(var Done : Boolean; var NewMenuCmd : String; c2 : Char; mStr : String);
procedure menuCmdHelp;
procedure menuExec;
procedure menuExecute(sCmd : String; var NewMenuCmd : String);
procedure menuGeneric;
procedure menuGetCmd(var S : String);
procedure menuHandle(var Cmd : String);
procedure menuInstall;
function  menuLoad(S : String; Glob : Boolean) : Boolean;
procedure menuRead;
procedure menuSave(S : String);
procedure menuShow;

implementation

procedure menuExec;
var Cmd, S : String; I : Integer;
    Aa, Abort, Next, Done : Boolean;
begin
   Cmd := '';
   if ExecFirst then
   begin
      ExecFirst := False;
      Cmd := NewMenuCmd;
      NewMenuCmd := '';
   end else menuHandle(Cmd);

   if (Copy(Cmd,1,2) = '\\') and (acsOk(Cfg^.acsSysOp)) then
   begin
      menuCommand(Done,Copy(Cmd,3,Length(Cmd)-2),NewMenuCmd);
      if (NewMenuCmd <> '') then Cmd := NewMenuCmd else Cmd := '';
   end;

   if (Cmd <> '') then
   begin
      NewMenuCmd := '';
      repeat
         menuExecute(Cmd,NewMenuCmd)
      until (NewMenuCmd = '');
   end;
end;

procedure menuChange(var Done : Boolean; var NewMenuCmd : String; c2 : Char; mStr : String);
var S, s1 : String;
begin
  case c2 of
     '^' : begin
              s1 := mStr;
              if (Pos(';',s1) <> 0) then s1 := Copy(s1,1,Pos(';',s1)-1);
              if (mStr <> '') then
              begin
                 S := mStr;
                 if (Pos(';',S) <> 0) then S := Copy(S,Pos(';',S)+1,Length(S));
                 if (Copy(S,1,1) = 'C') then MenuPtr := 0;
                 if (Pos(';',S) = 0) or (Length(S) = 1) then S := '' else
                    S := Copy(S,Pos(';',S)+1,Length(S));
              end;
              if (s1 <> '') then
              begin
                 LastMenu := CurMenu;
                 CurMenu := s1;
                 Done := True;
                 if (S <> '') then NewMenuCmd := UpStr(S);
                 NewMnuToLoad := True;
              end;
           end;
     '/' : begin
              s1 := mStr;
              if (Pos(';',s1) <> 0) then s1 := Copy(s1,1,Pos(';',s1)-1);
              if ((mStr <> '') and (MenuPtr <> 8)) then
              begin
                 S := mStr;
                 if (Pos(';',S) <> 0) then S := Copy(S,Pos(';',S)+1,Length(S));
                 if (Copy(S,1,1) = 'C') then MenuPtr := 0;
                 if (Pos(';',S) = 0) or (Length(S) = 1) then S := '' else
                    S := Copy(S,Pos(';',S)+1,Length(S));
                 Inc(MenuPtr);
                 MenuStack[MenuPtr] := CurMenu;
              end;
              if (s1 <> '') then
              begin
                 LastMenu := CurMenu;
                 CurMenu := s1;
                 Done := True;
                 if (S <> '') then NewMenuCmd := UpStr(S);
                 NewMnuToLoad:=True;
              end;
           end;
     '\' : begin
              S := mStr;
              if (MenuPtr <> 0) then
              begin
                 LastMenu := CurMenu;
                 CurMenu := MenuStack[MenuPtr];
                 Dec(MenuPtr);
              end;
              if (Copy(S,1,1) = 'C') then MenuPtr := 0;
              Done := True;
              if (Pos(';',S) = 0) then S := '' else
                 NewMenuCmd := UpStr(Copy(S,Pos(';',S)+1,Length(S)));
                 NewMnuToLoad := True;
           end;
  end;
end;

function menuLoad(S : String; Glob : Boolean) : Boolean;
var F : file;
begin
   menuLoad := False;
   Assign(F,Cfg^.pathMenu+S+'.MNU');
   {$I-}
   Reset(F,1);
   {$I+}
   if ioResult <> 0 then Exit;
   numCmds := 0;
   FillChar(Menu^,SizeOf(Menu^),0);
   FillChar(Cmd^,SizeOf(Cmd^),0);
   BlockRead(F,Menu^,SizeOf(Menu^));
   while (numCmds < maxMenuCmd) and (not Eof(F)) do
   begin
      Inc(numCmds);
      BlockRead(F,Cmd^[numCmds],SizeOf(Cmd^[1]));
   end;
   Close(F);
   if (Glob) and (Menu^.GlobalUse) then
   begin
      Assign(F,Cfg^.pathMenu+'GLOBAL.MNU');
      {$I-}
      Reset(F,1);
      {$I+}
      if ioResult = 0 then
      begin
         Seek(F,SizeOf(Menu^));
         while (numCmds <  maxMenuCmd) and (not Eof(F)) do
         begin
            Inc(numCmds);
            BlockRead(F,Cmd^[numCmds],SizeOf(Cmd^[1]));
         end;
         Close(F);
      end;
   end;
(*    lcmdlistentry:=''; j:=0;
    for i:=1 to noc do begin
      if (Cmd^[i].ckeys<>lcmdlistentry) then begin
        b:=(aacs(Cmd^[i].acs));
        if (b) then inc(j);
{
        if (b) and (j<>1) then cmdlist:=cmdlist+',';
        if (b) then cmdlist:=cmdlist+Cmd^[i].ckeys;
}
        if (b) then begin
          if ((Cmd^[i].ckeys<>'FIRSTCMD') and (Cmd^[i].ckeys<>'GTITLE')) then begin
            if (j<>1) then cmdlist:=cmdlist+',';
            cmdlist:=cmdlist+Cmd^[i].ckeys;
          end else dec(j);
        end;
        lcmdlistentry:=Cmd^[i].ckeys;
      end;
      if (Cmd^[i].cmdkeys='M#') then mqarea:=TRUE;
      if (Cmd^[i].cmdkeys='F#') then fqarea:=TRUE;
    end;
  end;*)
   menuLoad := True;
end;

procedure menuSave(S : String);
var I : Word; F : file;
begin
   Assign(F,Cfg^.pathMenu+S+'.MNU');
   {$I-}
   Rewrite(F,1);
   {$I+}
   if ioResult <> 0 then Exit;
   BlockWrite(F,Menu^,SizeOf(Menu^));
   for I := 1 to numCmds do BlockWrite(F,Cmd^[I],SizeOf(Cmd^[I]));
   Close(F);
end;

procedure menuRead;
var S, lCmdListEntry : String;
    I, J : Integer;
    B : Boolean;
begin
  CmdList := '';
  if not menuLoad(CurMenu,True) then
  begin
     oWriteLn('Error loading "'+CurMenu+'"');
     oWriteLn('Attempting to load fallback menu ...');
     logWrite('xMenu file "'+CurMenu+'" not found.  Used fallback ...');
     CurMenu := Menu^.Fallback;
     if not menuLoad(CurMenu,True) then
     begin
        oWriteLn('Error loading fallback menu.  Please inform SysOp');
        oWriteLn('');
        logWrite('xFallback menu file is missing as well.  Hanging up');
        oWriteLn('Fatal error; terminating carrier');
        Hangup := True;
     end;
  end;

{ mqarea:=FALSE; fqarea:=FALSE;}
  lCmdListEntry := '';
  J := 0;
  for I := 1 to numCmds do
  begin
     if (Cmd^[I].Keys <> lCmdListEntry) then
     begin
        B := (acsOk(Cmd^[I].ACS));
        if (B) then Inc(J,1);
        if (B) then
        begin
           if ((Cmd^[I].Keys <> cmdFirst) {and (Cmd^[I].Keys <> 'GTITLE'))}) then
           begin
              if (J <> 1) then CmdList := CmdList+',';
              CmdList := CmdList+Cmd^[I].Keys;
           end else Dec(J,1);
        end;
        lCmdListEntry := Cmd^[I].Keys;
     end;
    {if (Cmd^[I].cmdkeys='M#') then mqarea:=TRUE;
     if (Cmd^[i].cmdkeys='F#') then fqarea:=TRUE;}
  end;
end;

function menuAccess(I : Integer; var CmdNotHid : Boolean) : Boolean;
begin
   menuAccess := False;
   CmdNotHid := not Cmd^[I].Hidden;
   if not acsOk(Cmd^[I].ACS) then Exit;
   menuAccess := True;
end;

procedure menuGeneric;
var GLin : array[1..maxMenuCmd] of String;
    S, s1 : String;
    gColors : array[1..3] of tColorRec;
    onLin, I, J, colSiz, numCols, numGLin, maxRight : Integer;
    B, CmdNotHid : Boolean;

 function genCommand(Keys, Desc : String; Acc : Boolean) : String;
 begin
    if Acc then genCommand := '|U2[|U3'+Keys+'|U2] |U1'+Desc else
                genCommand := '|U2[|U1'+Keys+'|U2] '+Desc;
{   S := Desc;

    J := Pos(UpStr(Keys),UpStr(Desc));
    if (J <> 0) and (Length(NoColor(Desc)) = Length(Desc)) then
    begin
       Insert(strColCode(gColors[1].Fore,gColors[1].Back,gColors[1].Blink),Desc,J+Length(Keys)+1);
       Insert(strColCode(gColors[2].Fore,gColors[2].Back,gColors[2].Blink),Desc,J+Length(Keys));
       if Acc then Insert(strColCode(gColors[3].Fore,gColors[3].Back,gColors[3].Blink),Desc,J);
       if (J <> 1) then Insert(strColCode(gColors[2].Fore,gColors[2].Back,gColors[2].Blink),Desc,J-1);
    end;
    genColor := strColCode(gColors[3].Fore,gColors[3].Back,gColors[3].Blink)+Desc;}
 end;
{
 procedure genExtended;
 var I,J : Integer;
     B : Boolean;
 begin
    numGLin := 0;
    maxRight := 0;
    GLin[1] := '';
    for I := 1 to numCmds do
    begin
       B := menuAccess(I,CmdNotHid);
       if (B) and (not Cmd^[I].Hidden) then
          if (Cmd^[I].Desc <> '') then
          begin
             Inc(numGLin);
             GLin[numGLin] := genCommand(Cmd^[I].Keys,Cmd^[I].Desc,B);
             J := Length(NoColor((GLin[numGlin])));
             if (J > maxRight) then maxRight := J;
          end;
    end;
 end;
}
 procedure genNormal;
 var s1 : String; I, J : Integer; B : Boolean;
 begin
    s1 := '';
    onLin := 0;
    numGLin := 1;
    maxRight := 0;
    GLin[1] := '';
    for I := 1 to numCmds do
    begin
       B := menuAccess(I,CmdNotHid);
       if (B) and (not (Cmd^[I].Hidden)) then
       begin
          if (Cmd^[I].Desc <> '') then
          begin
             Inc(onLin);
             s1 := genCommand(Cmd^[I].Keys,Cmd^[I].Desc,B);
             if (onLin <> numCols) then s1 := Resize(s1,colSiz);
             GLin[numGLin] := GLin[numGLin]+s1;
          end;
          if (onLin = numCols) then
          begin
             J := Length(NoColor(GLin[numGLin]));
             if (J > maxRight) then maxRight := J;
             Inc(numGLin);
             GLin[numGLin] := '';
             onLin := 0;
          end;
       end;
    end;
    if (onLin = 0) then Dec(numGLin);
 end;

 function genCentered(C : Integer; S : String) : String;
 const SpaceStr = '                                               ';
 begin
    C := (C div 2)-(Length(NoColor((S))) div 2);
    if (C < 1) then C := 0;
    genCentered := Copy(SpaceStr,1,C)+S;
 end;

 procedure genInitTitles;
 var I : Integer; B : Boolean;
 begin
    B := False;
    if Menu^.ClearBefore then oClrScr;
    oSetCol(1);
    oDnLn(1);
    if Menu^.MenuName <> '' then
    begin
       if not Menu^.CenterTtl then oStrLn(Menu^.MenuName) else
                                   oStrLn(genCentered(maxRight,Menu^.MenuName));
       oDnLn(1);
    end;
 end;

begin
   numCols := Menu^.GenColumns;
   case numCols of
      2 : colSiz := 39;
      3 : colSiz := 25;
      4 : colSiz := 19;
      5 : colSiz := 16;
      6 : colSiz := 12;
      7 : colSiz := 11;
   end;
   genNormal;
   genInitTitles;
   for I := 1 to numGLin do if (GLin[I] <> '') then oStrLn(GLin[I]);
end;

procedure menuShow;
begin
   case Menu^.mType of
      1 : if not sfShowTextFile(Menu^.HelpFile,ftNormal) then menuGeneric;
      2 : menuGeneric;
   end;
   doHelp := False;
end;

procedure menuCheckExpert;
begin
   if Menu^.Expert = 2 then DoHelp := False else
   if Menu^.Expert = 3 then DoHelp := True else
   if not doHelp then doHelp := not (acExpert in User^.acFlag);
end;

procedure menuInstall;
var S : String;
    nAcc : Boolean;
begin
   menuRead;
   nAcc := False;
   with Menu^ do
   begin
      if ((not acsOk(ACS)) or (Password <> '')) then
      begin
         nAcc := True;
         if (Password <> '') then
         begin
            oDnLn(1);
            oString(strMenuPassword);
            S := iReadString('',inUpper,chNormal,rsPassword,20);
            if (S = Password) then nAcc := False;
         end;
         if (nAcc) then
         begin
            oDnLn(1);
            oStringLn(strMenuAccessDenied);
            logWrite('-Access to menu "'+CurMenu+'" denied.');
            CurMenu := Fallback;
            menuRead;
         end;
      end;
      doHelp := False;
      menuCheckExpert;
{     if (not nAcc) then
         if (fHelpLevel <> 0) then
            HelpLevel := fHelpLevel else
         if not (acExpert in User^.acFlag) then HelpLevel := 2 else
                                                HelpLevel := 1;}
   end;
end;

procedure menuDoLightBarMenu(var S : String);
var Mnu : array[1..24] of Byte; Hs : Byte; C, Cur, N : Word; Ch : Char; Help : Boolean;
procedure DrawItem(It : Byte; Hi : Boolean);
 begin
    if Hi then sfGotoPos(It) else sfGotoPos2(It);
    oStr(Cmd^[Mnu[It]].Desc);
    if (Hi) and (Help) then
    begin
       if Hs > 0 then
       begin
          sfGotoPos(maxPos-1);
          oWrite(sRepeat(' ',Hs));
       end;
       sfGotoPos(maxPos-1);
       oStr(Cmd^[Mnu[It]].Help);
       Hs := Length(NoColor(Cmd^[Mnu[It]].Help));
    end;
 end;
 procedure MoveItUp;
 begin
    DrawItem(Cur,False);
    Dec(Cur);
    if Cur < 1 then Cur := C;
    DrawItem(Cur,True);
 end;
 procedure MoveItDown;
 begin
    DrawItem(Cur,False);
    Inc(Cur);
    if Cur > C then Cur := 1;
    DrawItem(Cur,True);
 end;
 procedure HomeIt;
 begin
    if Cur = 1 then Exit;
    DrawItem(Cur,False);
    Cur := 1;
    DrawItem(Cur,True);
 end;
 procedure EndIt;
 begin
    if Cur = C then Exit;
    DrawItem(Cur,False);
    Cur := C;
    DrawItem(Cur,True);
 end;
begin
   s := '1';
   if not sfShowTextFile(Menu^.HelpFile,ftLightBar) then Exit;
   C := 0;
   Help := sfPos[maxPos-1].Ok;
   for N := 1 to numCmds do if (C < 24) and
{                              (Cmd^[N].Keys = '') and}
                               (acsOk(Cmd^[N].Acs)) and
                               (Cmd^[N].Hidden = False) then
   begin
      Inc(C);
      Mnu[C] := N;
   end;
   Hs := 0;
   if C = 0 then Exit;
   for N := 1 to C do DrawItem(N,False);
   Cur := 1;
   DrawItem(Cur,True);
   repeat
      Ch := iReadKey;
      if extKey <> #0 then
      case extKey of
         upArrow, lfArrow : MoveItUp;
         dnArrow, rtArrow : MoveItDown;
         HomeKey, PgUp : HomeIt;
         EndKey,  PgDn : EndIt;
      end else
      case Ch of
         '8','4' : MoveItUp;
         '6','2',' ' : MoveItDown;
         '7','9' : HomeIt;
         '1','3' : EndIt;
      end;
   until (HangUp) or (Ch = Enter);
   S := St(Mnu[Cur]);
   sfGotoPos(maxPos);
end;

function menuHotKey : Boolean;
begin
   case Menu^.HotKey of
     2 : menuHotKey := True;
     3 : menuHotKey := False;
     else menuHotKey := acHotKey in User^.acFlag;
   end;
end;

procedure menuGetCmd(var S : String);
var s1, ss, oss, shas0, shas1 : String;
    i, NewArea : Integer;
    c, cc : Char;
    oldco : Byte;
    achange, bb, gotCmd, has0, has1, has2 : Boolean;
begin
   S := '';
   if Menu^.mType = 3 then
   begin
      menuDoLightBarMenu(S);
      if S = '' then S := '?';
      Exit;
   end;
{  if (buf <> '') then if (Copy(buf,1,1) = '`') then
   begin
      buf := Copy(buf,2,Length(buf)-1);
      i := Pos('`',buf);
      if (i <> 0) then
      begin
         S := UpStr(Copy(buf,1,i-1));
         buf := Copy(buf,i+1,Length(buf)-i);
         oDnLn(1);
         Exit;
      end;
   end;}
   shas0 := '?';
   shas1 := '';
   has0 := False;
   has1 := False;
   has2 := False;

  { find out what kind of 0:"x", 1:"/x", and 2:"//xxxxxxxx..." commands
    are in this menu. }

  for i := 1 to numCmds do if acsOk(Cmd^[i].ACS) then
      if Cmd^[i].Keys[0] = #1 then
      begin
         has0 := True;
         shas0 := shas0+Cmd^[i].Keys;
      end else if ((Cmd^[i].Keys[1] = '/') and (Cmd^[i].Keys[0] = #2)) then
      begin
         has1 := True; shas1 := shas1+Cmd^[i].Keys[2];
      end else has2 := True;

{  oldco := curco;}

  gotCmd := False;
  ss := '';
  if not menuHotKey then
  begin
     if not Menu^.InputUp then S := UpStr(iReadString('',inNormal,chNormal,'',60)) else
                               S := iReadString('',inUpper,chNormal,'',60);
  end else
  begin
     repeat
        C := iReadKey;
        if Menu^.InputUp then C := UpCase(C);
        if extKey <> #0 then C := #0;
        oss := ss;
        if (ss = '') then
        begin
           if (c = #13) then gotCmd := True;
           if (c = '/') and ((has1) or (has2) or (acsOk(Cfg^.acsSysOp))) then ss := '/';
        {  if (((fqarea) or (mqarea)) and (c in ['0'..'9'])) then
          ss:=c
        else}
           if (Pos(UpCase(c),shas0) <> 0) then
           begin
              gotCmd := True;
              ss := c;
           end;
        end else if (ss = '/') then
        begin
           if (c = ^H) then ss := '';
           if (c = '/') and ((has2) or (acsOk(Cfg^.acsSysOp))) then ss := ss + '/';
           if ((Pos(UpCase(c),shas1) <> 0) and (has1)) then
           begin
              gotCmd := True;
              ss := ss+c;
           end;
        end else if (Copy(ss,1,2) = '//') then
        begin
           if (c = #13) then gotCmd := True else
           if (c = ^H) then ss := Copy(ss,1,Length(ss)-1) else
           if (c = ^X) then
           begin
              for i := 1 to Length(ss)-2 do oBackspace(' ');
              ss := '//';
              oss := ss;
           end else if ((Length(ss) < 62) and (c >= #32) and (c <= #127)) then ss := ss+c;
        end;{ else if ((Length(ss) >= 1) and (ss[1] in ['0'..'9']) and (
                    (fqarea) or (mqarea))) then begin
              if (c=^H) then ss:=copy(ss,1,length(ss)-1);
              if (c=#13) then gotCmd:=TRUE;
              if (c in ['0'..'9']) then begin
                ss:=ss+c;
                if (length(ss)=3) then gotCmd:=TRUE;
              end;
            end;}

{       if ((Length(ss) = 1) and (Length(oss) = 2)) then setc(oldco);}
        if (oss <> ss) then
        begin
           if (Length(ss) > Length(oss)) then oWrite(Copy(ss,Length(ss),1));
           if (Length(ss) < Length(oss)) then oBackspace(' ');
        end;
{        if ((not (ss[1] in ['0'..'9'])) and ((Length(ss) = 2) and (Length(oss) = 1))) then cl(6);}
    until ((gotCmd) or (Hangup));

    if (Copy(ss,1,2) = '//') then ss := Copy(ss,3,Length(ss)-2);

    S := ss;
  end;

  oDnLn(1);

  if (Pos(';',S) <> 0) then if (Copy(S,1,2) <> '\\') then
  begin
     if menuHotKey then
     begin
        s1 := Copy(S,2,Length(S)-1);
        if (Copy(s1,1,1) = '/') then S := Copy(s1,1,2) else S := Copy(s1,1,1);
        s1 := Copy(s1,Length(S)+1,Length(s1)-Length(S));
     end else
     begin
        s1 := Copy(S,Pos(';',S)+1,Length(S)-Pos(';',S));
        S := Copy(S,1,Pos(';',S)-1);
     end;
     while (Pos(';',s1) <> 0) do s1[Pos(';',s1)] := ^M;
  end;
end;

procedure menuFindCmd(Cd : String; var I : Integer; Noc : Integer;
                      var CmdExists, CmdNotHid : Boolean);
var Done : Boolean;
begin
   Done := False;
   cd := UpStr(cd);
   repeat
      Inc(I,1);
      if (Cd = Cmd^[I].Keys) then
      begin
         CmdExists := True;
         if (menuAccess(I,CmdNotHid)) then Done := True;
      end;
  until ((I > Noc) or (Done));
  if (I > Noc) then I := 0;
end;

procedure menuExecute(sCmd : String; var NewMenuCmd : String);
var CmdACS, CmdNotHid, CmdExists, Done : Boolean;
    NocSave, I : Integer;
begin
   if (NewMenuCmd <> '') then
   begin
      sCmd := NewMenuCmd;
      NewMenuCmd := '';
   end;
   if (sCmd <> '') then
   begin
      CmdACS := False;
      CmdExists := False;
      CmdNotHid := False;
      Done := False;
      NocSave := numCmds;
      I := 0;
      repeat
         if UpStr(Menu^.Prompt) = mnuLightBar then
         begin
            I := strToInt(sCmd);
            cmdExists := True;
            cmdNotHid := True;
            cmdAcs    := True;
            Done := True;
         end else menuFindCmd(sCmd,I,NocSave,CmdExists,CmdNotHid);
         if (I <> 0) then
         begin
            CmdACS := True;
            menuCommand(Done,Cmd^[I].Command+Cmd^[I].Param,NewMenuCmd);
         end;
      until ((I = 0) or (Done));
      if (not Done) then
      if ((not CmdACS) and (sCmd <> '')) then
      begin
         oDnLn(1);
         if ((CmdNotHid) and (CmdExists)) then
         begin
            oStringLn(strCmdAccessDenied);
            logWrite('-Access to menu command in menu "'+CurMenu+'" denied');
         end else
         begin
            oStringLn(strInvalidCommand);
            logWrite('-Invalid menu command error in menu "'+CurMenu+'"');
         end;
      end;
   end;
end;

procedure menuHandle(var Cmd : String);
var NewArea : Integer; WantShow : Boolean;
begin
   cCheckUser;
   if HangUp then
   begin
      Cmd := '';
      Exit;
   end;

   menuCheckExpert;

   if ((Menu^.PauseBefore) and (doHelp) and (LastCmdGood)) then oPromptKey;
   LastCmdGood := False;
   if doHelp then menuShow;

   if (UpStr(Menu^.Prompt) <> mnuLightBar) and (Menu^.ShowPrompt) then
   begin
      oDnLn(1);
      oStr(Menu^.Prompt);
   end;

   menuGetCmd(Cmd);

   if (Cmd = '?') then
   begin
      Cmd := '';
      doHelp := True;
   end else menuCheckExpert;
{
  if (fqarea) or (mqarea) then
  begin
    NewArea:=value(cmd);
    if ((NewArea<>0) or (copy(cmd,1,1)='0')) then
    begin
      if (fqarea) then
      begin
        if (NewArea>=0) and (NewArea<=maxuboards) then
          changefileboard(ccuboards[0][NewArea]);
      end else
      if (mqarea) then
        if (NewArea>=0) and (NewArea<=maxboards) then
          changeboard(ccboards[0][NewArea]);
      cmd:='';
    end;
  end;}
end;

procedure menuCmdHelp;
var Ans : Boolean; z : Word;
begin
   PausePos := 1;
   PauseAbort := False;
   Ans := (sfGetTextFile(txHelpTop,ftTopLine) <> '') and
          (sfGetTextFile(txHelpMid,ftCmdHelp) <> '') and
          (sfGetTextFile(txHelpBot,ftNormal)  <> '');
   if Ans then
   begin
      sfShowTextFile(txHelpTop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txHelpMid);
   end else
   begin
      oClrScr;
      oDnLn(1);
      oSetCol(colInfo);
      oCWriteLn(' Key   Description');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',50));
      oUpPause(3);
      oSetCol(colText);
   end;
   z := 0;
   while (not HangUp) and (z < numCmds) and (not PauseAbort) do
   begin
      Inc(z);
      if (Cmd^[z].Hidden) or (not acsOk(Cmd^[z].Acs)) then begin { nothing .. } end else
      if Ans then
      begin
         sfStr[1] := Cmd^[z].Keys;
         sfStr[2] := Cmd^[z].Help;
         sfStr[3] := Cmd^[z].Desc;
         sfShowRepeat(ftCmdHelp);
         if oWhereX <> 1 then oDnLn(1);
         oUpPause(1);
      end else
      begin
         oCWriteLn(' '+Resize(Cmd^[z].Keys,5)+
                   ' '+strSquish(Cmd^[z].Help,72));
         oUpPause(1);
      end;
   end;
   sfKillRepeat;
   if Ans then
   begin
      sfShowTextFile(txHelpBot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',50));
      oUpPause(1);
   end;
   PausePos := 0;
end;

end.