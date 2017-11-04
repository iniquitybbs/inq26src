{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Email;

interface

function  emailEnterEmail(whoTo, theSubject : String; AskUL : Boolean) : Boolean;
function  emailLoad : Boolean;
procedure emailReadEmail(All : Boolean; Ask : Boolean);
procedure emailReset;
procedure emailSave;

implementation

uses Files, Global, MsgArea, ShowFile, Output, Strings, Misc, Input, Logs,
     FsEditor, DateTime, Config8;

function emailEnterEmail(whoTo, theSubject : String; AskUL : Boolean) : Boolean;
var Area : Word;
begin
   if not acsOk(Cfg^.acsPostEmail) then
   begin
      oStringLn(strEmailNoAccess);
      logWrite('-Email post access denied.');
      Exit;
   end;
   Area := User^.curMsgArea;
   User^.curMsgArea := mareaEmail;
   emailLoad;

   emailEnterEmail := maPostMessage(whoTo,theSubject,0,AskUL);

   User^.curMsgArea := Area;
   maLoad;
end;

procedure emailAskKillAll;
var F : file of tMsgHeaderRec; Head : ^tMsgHeaderRec; N : Word; Ok, Asked : Boolean;
begin
   Assign(F,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   {$I-}
   Reset(F);
   {$I+}
   Ok := True;
   Asked := False;
   if ioResult = 0 then
   begin
      New(Head);
      N := 0;
      while (Ok) and (not Eof(F)) do
      begin
         Read(F,Head^);
         Inc(N,1);
         if ((Head^.ToInfo.RealName = User^.RealName) or
             (Head^.ToInfo.Alias = User^.UserName)) and
             (not (msgDeleted in Head^.Status)) then
         begin
            if not Asked then
            begin
               oDnLn(1);
               oString(strEmailAskKillAll);
               Ok := iYesNo(False);
               Asked := True;
            end;
            if Ok then
            begin
               Head^.Status := Head^.Status+[msgDeleted];
               Seek(F,N-1);
               Write(F,Head^);
            end;
         end;
      end;
      Dispose(Head);
      Close(F);
      User^.EmailWaiting := 0;
   end;
end;

procedure emailReadEmail(All : Boolean; Ask : Boolean);
var Area : Word; Ans : Boolean; F : file of tMsgHeaderRec; N : Word;
    Head : pMsgHeaderRec; Mail : array[1..maxEmail] of Word; S : String;
    Ch : Char; mf : file;
    Temp, HiMsg : Word;
    readDone, readShow, readGoto : Boolean;
begin
   Area := User^.curMsgArea;
   User^.curMsgArea := mareaEmail;
   emailLoad;

   User^.EmailWaiting := 0;
   N := 0;

   New(Head);

   Assign(F,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult = 0 then
   begin
      while not Eof(F) do
      begin
         Read(F,Head^);
         Inc(N);
         if (not All) and (useTag) and (readTag <> 0) and (readTag = Head^.msgTag) then
         begin
            Inc(User^.EmailWaiting);
            Mail[User^.EmailWaiting] := N;
         end else
         if ((All) or (Head^.ToInfo.RealName = User^.RealName) or
            (Head^.ToInfo.Alias = User^.UserName)) and
            (User^.EmailWaiting < maxEmail) and
            ((All) or (not (msgDeleted in Head^.Status))) then
         begin
            Inc(User^.EmailWaiting);
            Mail[User^.EmailWaiting] := N;
         end;
      end;
      Close(F);
   end;
   if User^.EmailWaiting = 0 then
   begin
      if not Ask then oStringLn(strEmailNoMail);
      Dispose(Head);
      User^.curMsgArea := Area;
      maLoad;
      Exit;
   end;
   if Ask then
   begin
      oString(strEmailAskRead);
      if not iYesNo(True) then
      begin
         Dispose(Head);
         User^.curMsgArea := Area;
         maLoad;
         Exit;
      end;
   end;
   if All then logWrite('*Read all email.') else logWrite('Read email.');
   Ans := (sfGetTextFile(txListMailtop,ftTopLine) <> '') and
          (sfGetTextFile(txListMailmid,ftListMail) <> '') and
          (sfGetTextFile(txListMailbot,ftNormal) <> '');
   PausePos := 1;
   PauseAbort := False;
   if Ans then
   begin
      sfShowTextFile(txListMailtop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txListMailMid);
   end else
   begin
      oClrScr;
      oDnLn(1);
      oCWriteLn('|U4 Num  Message Title          Sender          Reciever        Date      Time');
                   {_4   _22                    _15             _15              _9       _8}
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(3);
      oSetCol(colText);
   end;
   N := 0;
   for N := 1 to User^.EmailWaiting do
   begin
      maLoadHeader(Head^,Mail[N]);
      if Ans then
      begin
         sfStr[1] := Head^.Subject;
         sfStr[2] := Head^.FromInfo.Name;
         sfStr[3] := Head^.ToInfo.Name;
         sfStr[4] := dtTimePackedString(Head^.Date);
         sfStr[5] := dtDatePackedString(Head^.Date);
         sfStr[6] := St(N);
         sfShowRepeat(ftListMail);
         if oWhereX <> 1 then oDnLn(1);
         oUpPause(1);
      end else
      begin
         oWriteLn(' '+Resize(St(N),4)+
                  ' '+Resize(Head^.Subject,22)+
                  ' '+Resize(Head^.FromInfo.Name,15)+
                  ' '+Resize(Head^.ToInfo.Name,15)+
                  ' '+Resize(dtDatePackedString(Head^.Date),9)+
                  ' '+strSquish(dtTimePackedString(Head^.Date),8));
         oUpPause(1);
      end;
      if PauseAbort then Break;
   end;
   sfKillRepeat;
   if Ans then
   begin
      sfShowTextFile(txListMailbot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
   end;
   if oWhereX <> 1 then oDnLn(1);
   PausePos := 0;
   oStr(strCode(mStr(strEmailSelectToRead),1,St(User^.EmailWaiting)));
   S := iReadString('1',inUpper,chNumeric,'',4);
   curMsg := StrToInt(S);
   if (S = '') or (curMsg > User^.EmailWaiting) or (curMsg < 1) then
   begin
      Dispose(Head);
      User^.curMsgArea := Area;
      maLoad;
      Exit;
   end;

   numMsg := User^.EmailWaiting;
   readDone := False;
   readShow := True;
   if curMsg > numMsg then curMsg := numMsg;
   if curMsg < 1 then curMsg := 1;
   Assign(mf,Cfg^.pathMsgs+mArea^.Filename+extMsgData);
   {$I-}
   Reset(mf,1);
   {$I+}
   if ioResult <> 0 then
   begin
      Dispose(Head);
      User^.curMsgArea := Area;
      maLoad;
   end;
   if maLoadHeader(Head^,Mail[curMsg]) then
   repeat
      if readShow then maShowMessage(mf,Head^,Mail[curMsg]);
      readShow := False;
      oStr(strCode(strCode(mStr(strEmailReadPrompt),1,St(curMsg)),2,St(numMsg)));
      S := '';
      readGoto := False;
      repeat
         Ch := UpCase(iReadKey);
         if Ch in ['0'..'9'] then
         begin
            S := S+Ch;
            readGoto := Length(S) >= Length(St(numMsg));
            oWriteChar(Ch);
         end else
         if (Ch = #8) and (Length(S) > 0) then
         begin
            oBackSpace(' ');
            Delete(S,Length(S),1);
         end else
         if (Ch = #13) and (Length(S) > 0) then readGoto := True;
      until (HangUp) or (readGoto) or
            ((extKey = #0) and (Ch in [#27,#13,'Q','-','?','A','R','D','E','X','U']));
      if (S = '') then oWriteLn(Ch);
      if not readGoto then
      case Ch of
         #27,'Q' : readDone := True;
         #13     : begin
              if Length(S) > 0 then readGoto := True else
              if (curMsg < numMsg) and (maLoadHeader(Head^,Mail[curMsg+1])) then
              begin
                 Inc(curMsg);
                 readShow := True;
              end else if not All then readDone := True else ReadShow := True;
         end;
         '-'     : begin
              if (curMsg > 1) and (maLoadHeader(Head^,Mail[curMsg-1])) then
              begin
                 Dec(curMsg);
                 readShow := True;
              end;
         end;
         '?'     : begin
              if sfShowTextFile(txEmailHelp,ftNormal) then
              begin
                 oPromptKey;
                 readShow := True;
              end;
         end;
         'A'     : readShow := True;
         'R'     : if maPostMessage('','',Mail[curMsg],True) then
                   begin
              logWrite('Replied to email "'+Head^.Subject+'" from '+Head^.FromInfo.Name+'.');
              Inc(Head^.Replies,1);
              oDnLn(1);
              if (Cfg^.AskKillMsg) and (not (msgDeleted in Head^.Status)) then
              begin
                 oString(strEmailKillOriginal);
                 if iYesNo(True) then
                 begin
                    Head^.Status := Head^.Status+[msgDeleted];
                    logWrite('Original email message destroyed.');
                 end;
                 oDnLn(1);
              end;
              maSaveHeader(Head^,Mail[curMsg]);
         end;
         'D'     : begin
              if msgDeleted in Head^.Status then
              begin
                 Head^.Status := Head^.Status-[msgDeleted];
                 oStringLn(strMsgUndeleted);
                 logWrite('Email message "'+Head^.Subject+'" from '+Head^.FromInfo.Name+' undeleted.');
              end else
              begin
                 Head^.Status := Head^.Status+[msgDeleted];
                 oStringLn(strMsgDeleted);
                 logWrite('Email message "'+Head^.Subject+'" from '+Head^.FromInfo.Name+' deleted.');
              end;
              maSaveHeader(Head^,Mail[curMsg]);
              readShow := True;
         end;
         'E'     : if All then begin
              maEditMessage(Head^,Mail[curMsg]);
              readShow := True;
         end;
         'U'     : if acsOk(Cfg^.acsSysOp) then cfgUserEditor(Head^.FromInfo.UserNum);
         'X'     : begin maDownloadMessage(Mail[curMsg]); readShow := True; end;
      end else
      begin
         oDnLn(1);
         Temp := curMsg;
         curMsg := StrToInt(S);
         if not ((curMsg >= 1) and (curMsg <= numMsg)) then curMsg := Temp;
         maLoadHeader(Head^,Mail[curMsg]);
         readShow := True;
      end;
      if (not All) and (msgDeleted in Head^.Status) then
      begin
         if (curMsg < numMsg) and (maLoadHeader(Head^,Mail[curMsg+1])) then
         begin
            Inc(curMsg,1);
            readShow := True;
         end else
         begin
            readShow := False;
            readDone := True;
         end;
      end;
   until (HangUp) or (readDone);
   Dispose(Head);
   Close(mf);
   if (Cfg^.AskKillAllMsg) and (not All) then emailAskKillAll;
   oDnLn(1);

   User^.curMsgArea := Area;
   maLoad;
end;

function emailLoad : Boolean;
var F : file of tMsgAreaRec;
begin
   emailLoad := False;
   Assign(F,Cfg^.pathData+fileEmailArea);
   {$I-}
   Reset(F);
   if ioResult = 0 then
   begin
      Read(F,mArea^);
      Close(F);
      emailLoad := ioResult = 0;
   end else
   begin
      emailLoad := True;
      emailReset;
      emailSave;
   end;
   {$I+}
end;

procedure emailReset;
begin
   with mArea^ do
   begin
      Name := 'Private Mail';
      Filename := 'EMAIL';
      MsgPath := '';
      Sponsor := Cfg^.SysOpName;
      Acs := '';
      PostAcs := '';
      MaxMsgs := 64000;
      Msgs := 0;
      Password := '';
      Flag := [];
      AreaType := mareaEmail;
      Origin := 1;
      Address := 1;
   end;
end;

procedure emailSave;
var F : file of tMsgAreaRec;
begin
   Assign(F,Cfg^.pathData+fileEmailArea);
   {$I-}
   Rewrite(F);
   if ioResult <> 0 then Exit;
   Write(F,mArea^);
   {$I+}
   Close(F);
end;

end.