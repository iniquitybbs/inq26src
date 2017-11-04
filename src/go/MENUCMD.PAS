{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit MenuCmd;

interface

procedure menuCommand(var Done : Boolean; sCmd : String; var NewMenuCmd : String);

implementation

uses Crt, Dos,
     Global, Menus, Output, Input, Strings, Misc, Config1, Config2, Config3,
     Config4, Config5, Config6, Config7, Config8, Config9, Config10, Config11,
     Config12, Config13, Config14, Config15, Config16, Config17, ShowFile,
     MicroDOS, Files, MsgArea, BBSlist, Doors, AutoMsg, Email, Logon, Apply,
     Users, Callers, ChatMode, Logs, AutoSig, FileArea, FileSort, Conf, Levels,
     Comm, StatBar, QwkMail, mciCodes, Tetris, Infoform, Nuv, Iplx, Nodes;

procedure menuCommand(var Done : Boolean; sCmd : String; var NewMenuCmd : String);
var FilVar : Text; Cms, S, s1,s2 : String; I : Integer; c1, c2, C : Char;
    B, NoCmd : Boolean; semiNum : Byte; semiCmd : array[1..20] of String[60];

 procedure cmdSetupSemis;
 var S : String; P : Byte;
 begin
    FillChar(semiCmd,SizeOf(semiCmd),0);
    if Cms = '' then Exit;
    S := Cms;
    P := 0;
    while Pos(';',S) > 0 do
    begin
       Inc(P);
       semiCmd[P] := Copy(S,1,Pos(';',S)-1);
       Delete(S,1,Pos(';',S));
    end;
    Inc(P);
    semiCmd[P] := S;
    semiNum := P;
 end;

 procedure cmdPromptX;
 var Cmd : array[1..20] of String; Num, Def, X : Byte;
 begin
    inputString := '';
    if semiNum < 2 then Exit;
    FillChar(Cmd,SizeOf(Cmd),0);
    for X := 1 to 20 do Cmd[X] := semiCmd[X];
    Num := semiNum-1;
    Def := StrToInt(Cmd[Num+1]);
    if (Def = 0) or (Def > Num) then Exit;
{   sbInfo('Num = '+St(Num)+', Def = '+St(Def)+', Cmd[1] = '+Cmd[1],True);}
    X := iXprompt(Cmd,Num,Def);
    inputString := Cmd[X];
 end;

 procedure cmdChangeFlag;
 var On : Boolean; N : Byte;
 begin
    On := True;
    if Cms = '' then Exit;
    Cms := UpStr(Cms);
    for N := 1 to Length(Cms) do
    case Cms[N] of
      'A'..'Z' : if On then User^.Flag := User^.Flag+[Cms[N]] else
                            User^.Flag := User^.Flag-[Cms[N]];
      '+'      : On := True;
      '-'      : On := False;
    end;
 end;

begin
   NewMnuToLoad := False;
   NewMenuCmd := '';
   c1 := sCmd[1];
   c2 := sCmd[2];
   Cms := Copy(sCmd,3,Length(sCmd)-2);
   cmdSetupSemis;
   NoCmd := False;
   case c1 of
    '?' : case c2 of
            '=' : inputString := Cms;
            '+' : inputString := inputString+Cms;
            '/' : inputString := Cms+inputString;
            '%' : inputString := mciProcess(inputString,strToInt(Cms));
            'B' : cmdPromptX;
            'E' : OkFlag := fExists(Cms);
            'F' : begin
                     if UpCase(Cms[1]) in ['Y','T'] then okFlag := True else
                        okFlag := False;
                  end;
            'I' : inputString := iGetString(semiCmd[1],semiCmd[2],semiCmd[3],semiCmd[4],semiCmd[5],semiCmd[6]);
            'L' : inputString := St(mTimeLeft('M'));
            'N' : begin
                     if Cms <> '' then oStr(Cms);
                     OkFlag := iYesNo(False);
                  end;
            'S' : OkFlag := Cms = inputString;
            'T' : fAddToText(semiCmd[1],inputString,strToInt(semiCmd[2]));
            'U' : OkFlag := UpStr(Cms) = UpStr(inputString);
            'Y' : begin
                     if Cms <> '' then oStr(Cms);
                     OkFlag := iYesNo(True);
                  end;
            'X' : inputString := St(Lo(dosExitCode));
             else NoCmd := True;
    end;
    '-' : case c2 of
            '^',
            '/',
            '\' : menuChange(Done,NewMenuCmd,c2,Cms);
            '<' : RemoteIn := not RemoteIn;
            '>' : RemoteOut := not RemoteOut;
            '=' : levelChange(User^,UpCase(Cms[1]));
            '?' : menuCmdHelp;
            'C' : oClrScr;
            'D' : Delay(StrToInt(Cms)*1000);
            'E' : oStr(Cms);
            'F' : sfShowTextFile(Cms,ftNormal);
            'K' : begin oStr(Cms); iReadKey; end;
            'L' : oStrLn(Cms);
            'P' : oPromptKey;
            'R' : if Cms = '' then oDnLn(1) else oDnLn(StrToInt(Cms));
            'S' : cmdChangeFlag;
            'W' : logWrite(Cms);
{ --- >> }  'X' : begin
                     if Pos(' ',Cms) > 0 then Delete(Cms,1,Pos(' ',Cms)) else Cms := '';
                     iplExecute(semiCmd[1],Cms);
                  end;
            'Z' : while (not HangUp) and (not cOutBufferEmpty) do cCheckUser;
             else NoCmd := True;
          end;
    '|' : case c2 of
            'B' : oMoveDown(25);
            'C' : oGotoXY(1,1);
            'D' : oMoveDown(strToInt(semiCmd[1]));
            'E' : oMoveRight(80);
            'H' : oMoveLeft(80);
            'L' : oMoveLeft(strToInt(semiCmd[1]));
            'M' : oGotoXY(strToInt(semiCmd[1]),strToInt(semiCmd[2]));
            'R' : oMoveRight(strToInt(semiCmd[1]));
            'U' : oMoveUp(strToInt(semiCmd[1]));
            'T' : oMoveUp(25);
            'Z' : oClrEol;
             else NoCmd := True;
          end;
    '*' : case c2 of
            '#' : cfgMenuEditor;
            '%' : faLocalUpload;
            '@' : cfgConferenceEditor(True);
            '!' : cfgConferenceEditor(False);
            '>' : faDownloadAny(Cms);
            'A' : cfgMsgAreaEditor;
            'B' : cfgBbsListEditor;
            'C' : cfgSystemConfig;
            'D' : dosExecuteMicroDOS;
            'E' : cfgStringEditor;
            'F' : cfgFileAreaEditor;
            'H' : cfgStatEditor;
            'I' : cfgInfoformEditor;
            'L' : cfgLevelEditor;
            'M' : cfgCommunicationsSetup;
            'P' : maPackAreaAsk(Cms);
            'R' : emailReadEmail(True,False);
            'S' : fsSortFileAreas(Cms);
            'T' : cfgTextLibEditor;
            'U' : cfgUserEditor(User^.Number);
            'V' : cfgEventEditor;
            'X' : cfgProtocolEditor;
            'Y' : cfgFileEditor(0,True);
            'Z' : cfgArchiverEditor;
             else NoCmd := True;
          end;
    '>' : case c2 of
            'A' : applyToBBS;
            'C' : chatPage(True);
            'H' : begin HangUp := True; cHangUp; end;
            'L' : logonSystem;
             else NoCmd := True;
          end;
    'A' : case c2 of
            'R' : autoReply;
            'S' : autoShowAutoMessage;
            'W' : autoWriteAutoMessage;
             else NoCmd := True;
          end;
    'B' : case c2 of
            'A' : bbsListAddtoList;
            'C' : bbsListClear(UpCase(Cms[1]) = 'A');
            'D' : bbsListDeleteOne(StrToInt(semiCmd[1]),Pos('A',UpStr(Cms)) > 0);
            'L' : bbsListShowAll;
            'S' : bbsListShowOne(StrToInt(Cms));
             else NoCmd := True;
          end;
    'C' : case c2 of
            'P' : chatPage(False);
             else NoCmd := True;
          end;
    'D' : doorExecute(Cms,c2);
    'E' : case c2 of
            '+' : useTag := True;
            '-' : useTag := False;
            '/' : emailTag := strToInt(semiCmd[1]);
            '\' : readTag := strToInt(semiCmd[1]);
            'C' : emailReadEmail(False,True);
            'E' : emailEnterEmail(semiCmd[1],semiCmd[2],Pos('N',UpStr(semiCmd[3])) = 0);
            'R' : emailReadEmail(False,False);
             else NoCmd := True;
          end;
    'F' : case c2 of
            '+' : faBatchAdd(Cms);
            '[' : faPrevArea;
            ']' : faNextArea;
            'A' : faListAreas(False);
            'C' : begin
                     if not ((StrToInt(Cms) >= 1) and (StrToInt(Cms) <= numFileArea) and (faChangeArea(StrToInt(Cms)))) then
                         faListAreas(True);
                  end;
            'D' : faDownload(Cms);
            'F' : faSearchFile(True);
            'I' : faGetfileInfo(Cms);
            'J' : confSelect(False,Cms);
            'L' : if Cms = '' then faListfiles(False,nil,0) else faAskListFiles;
            'N' : faNewScanAsk(Cms);
            'S' : faSetNewScanDate;
            'T' : faSearchFile(False);
            'U' : faUpload;
            'V' : faViewFile(Cms);
            'Z' : confList(True);
             else NoCmd := True;
          end;
    'H' : case c2 of
            'C' : begin
                     oStr(Cms);
                     if iYesNo(True) then
                     begin
                        oClrScr;
                        sfShowTextFile(txLogoff,ftNormal);
                        HangUp := True;
                     end;
                  end;
            'I' : begin
                     if Cms <> '' then oStrLn(Cms);
                     HangUp := True;
                  end;
            'M' : begin
                     oStr(Cms);
                     sfShowTextFile(txLogoff,ftNormal);
                     HangUp := True;
                  end;
             else NoCmd := True;
          end;
    'I' : case c2 of
            'N' : ifInfoforms(False);
            'M' : ifInfoforms(True);
             else NoCmd := True;
          end;
    'L' : case c2 of
            'C' : callLastCallersShow(UpCase(Cms[1]) = 'A');
             else NoCmd := True;
          end;
    'M' : case c2 of
            '[' : maPrevArea;
            ']' : maNextArea;
            'A' : maListAreas(False);
            'C' : begin
                     if (StrToInt(Cms) >= 1) and (StrToInt(Cms) <= numMsgArea) and (maChangeArea(StrToInt(Cms))) then
                         maUpdateScanFile else maListAreas(True);
                  end;
            'J' : confSelect(True,Cms);
            'P' : maPostMessage(semiCmd[1],semiCmd[2],0,Pos('N',UpStr(semiCmd[3])) = 0);
            'R' : maReadMessages(0,Pos('M',UpStr(Cms)) > 0,True);
            'S' : maSetPointerDate;
            'N' : maNewScanAsk(Cms);
            'M' : if Cms <> '' then maScanForMandatory(StrToInt(Cms)) else
                                    maScanForMandatory(0);
            'Z' : confList(True);
             else NoCmd := True;
          end;
    'N' : case c2 of
            'V' : nuvVote(Pos('S',upStr(cms)) > 0);
             else NoCmd := True;
          end;
    'Q' : case c2 of
            'D' : qwkDownload;
            'U' : qwkUpload;
             else NoCmd := True;
          end;
    'S' : case c2 of
            'D' : asDeleteAutoSig;
            'E' : asEditAutoSig(User^,True);
            'S' : asShowAutoSig;
            'U' : asUploadAutoSig;
             else NoCmd := True;
          end;
    'T' : case c2 of
            'P' : itPlayTetris;
            'S' : itShowScores(cms);
             else NoCmd := True;
          end;
    'U' : case c2 of
            'C' : userConfiguration(False);
            'L' : userShowList;
            'P' : userPassword;
             else NoCmd := True;
          end;
    'X' : case c2 of
            'L' : nodeList;
            'S' : nodeUpdate(cms);
          end;
     else NoCmd := True;
   end;
   LastCmdGood := not NoCmd;
{  if (lastcommandovr) then lastcommandgood:=FALSE;}
   if (NoCmd) then {if (cso) then}
   begin
      oDnLn(1);
      oSetCol(colError);
      oStrLn(strCode(mStr(strInvalidMnuCmd),1,sCmd));
   end;
   if (NewMnuToLoad) then
   begin
      menuInstall;
      LastCmdGood := False;
      if (NewMenuCmd = '') then
      begin
         I := 1;
         while ((I <= numCmds) and (NewMenuCmd = '')) do
         begin
            if (Cmd^[I].Keys = cmdFirst) then
            if (acsOk(Cmd^[I].ACS)) then NewMenuCmd := cmdFirst;
            Inc(I);
         end;
      end;
   end;
end;

end.