{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit MsgArea;

interface

uses Global;

function  maAddMessage(var M : tMessage; var Head : tMsgHeaderRec; Save : Boolean) : Boolean;
function  maChangeArea(Area : Word) : Boolean;
function  maDownloadMessage(N : Word) : Boolean;
procedure maEditMessage(var Head : tMsgHeaderRec; mn : Word);
procedure maEditTextfile(Fn : String);
procedure maFindAreaWithAccess;
function  maHasAccess : Boolean;
function  maImportMessage(var M : tMessage) : Word;
procedure maListAreas(Change : Boolean);
function  maLoad : Boolean;
function  maLoadHeader(var Head : tMsgHeaderRec; M : Word) : Boolean;
function  maLoadMessage(var Mr : tMessage; var Head : tMsgHeaderRec; M : Word) : Boolean;
procedure maLoadScan(var S : tScanRec; U : Word);
function  maLoadTextFile(fn : String; var Txt : tMessage) : Word;
procedure maNewScan(AllAreas : Boolean; Num : Word);
procedure maNewScanAsk(Par : String);
function  maNewScanMsgNum : Word;
procedure maNextArea;
function  maOKtoRead(var Head : tMsgHeaderRec) : Boolean;
procedure maPackAreaAsk(Par : String);
procedure maPackAreas(AllAreas : Boolean; Num : Word);
function  maPostMessage(whoTo, theSubject : String; rN : Word; AskUL : Boolean) : Boolean;
procedure maPrevArea;
function  maReadMessages(Start : Word; Mand : Boolean; Show : Boolean) : Boolean;
function  maReadStr(var F : file) : String;
procedure maReset;
procedure maSave;
function  maSaveHeader(var Head : tMsgHeaderRec; M : Word) : Boolean;
procedure maSaveScan(var S : tScanRec; U : Word);
procedure maScanForMandatory(N : Word);
procedure maSetPointerDate;
procedure maShowMessage(var mf : file; var Head : tMsgHeaderRec; realMsg : Word);
procedure maUpdateAllScanFiles;
procedure maUpdateScanFile;
function  maUploadMessage(var H : tMsgHeaderRec) : Boolean;

implementation

uses Dos, Crt,
     Files, Output, Input, Misc, Strings, FsEditor, ShowFile, History, Stats,
     Logs, Users, StatBar, DateTime, Transfer, Emulate, Email, Attach,
     Config8, Comm;

function maHasAccess : Boolean;
begin
   maHasAccess := acsOk(mArea^.Acs);
end;

function maIsSponsor : Boolean;
begin
   maIsSponsor := (maHasAccess) and ((UpStr(User^.UserName) = UpStr(mArea^.Sponsor)) or
                                     (UpStr(User^.RealName) = UpStr(mArea^.Sponsor)));
end;

function maHasPostAccess : Boolean;
begin
   maHasPostAccess := acsOk(mArea^.PostAcs);
end;

function maChangeArea(Area : Word) : Boolean;
var OldArea : Word; Ok : Boolean; Pw : String;
begin
   maChangeArea := False;
   if (Area < 1) or (Area > numMsgArea) then Exit;
   OldArea := User^.curMsgArea;
   User^.curMsgArea := Area;
   Ok := (maLoad) and (maHasAccess);
   if (Ok) and (mArea^.Password <> '') then
   begin
      oString(strMsgAskPassword);
      Pw := iReadString('',inUpper,chNormal,rsPassword,20);
      Ok := Pw = UpStr(mArea^.Password);
   end;
   if not Ok then
   begin
      User^.curMsgArea := OldArea;
      maLoad;
      Exit;
   end;
   logWrite('Changed to message area: '+mArea^.Name);
   maChangeArea := True;
end;

procedure maPrevArea;
var A, oa : Word; Found : Boolean;
begin
   oa := User^.curMsgArea;
   Found := False;
   while (not Found) and (User^.curMsgArea > 1) do
   begin
      Dec(User^.curMsgArea);
      Found := maChangeArea(User^.curMsgArea);
   end;
   if not Found then
   begin
      User^.curMsgArea := oa;
      maLoad;
      oStringLn(strMsgLowestArea);
   end else oStrLn(strCode(mStr(strMsgChangedAreas),1,mArea^.Name));
end;

procedure maNextArea;
var A, oa : Word; Found : Boolean;
begin
   oa := User^.curMsgArea;
   Found := False;
   while (not Found) and (User^.curMsgArea < numMsgArea) do
   begin
      Inc(User^.curMsgArea);
      Found := maChangeArea(User^.curMsgArea);
   end;
   if not Found then
   begin
      User^.curMsgArea := oa;
      maLoad;
      oStringLn(strMsgHighestArea);
   end else oStrLn(strCode(mStr(strMsgChangedAreas),1,mArea^.Name));
end;

function maReadStr(var F : file) : String;
var C : Char; Len : Byte; S : String;
begin
   S := '';
   BlockRead(F,C,1);
   Len := Ord(C);
   S[0] := Chr(Len);
   BlockRead(F,S[1],Len);
   maReadStr := S;
end;

procedure maWriteStr(var F : file; S : String);
var C : Char; Len : Byte;
begin
   Len := Length(S);
   BlockWrite(F,Len,1);
   BlockWrite(F,S[1],Len);
end;

function maSaveHeader(var Head : tMsgHeaderRec; M : Word) : Boolean;
var HF : file of tMsgHeaderRec;
begin
   maSaveHeader := False;
   Assign(HF,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   {$I-}
   Reset(HF);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(HF);
      {$I+}
      if ioResult <> 0 then Exit;
   end else Seek(HF,M-1);
   Write(HF,Head);
   Close(HF);
   maSaveHeader := True;
end;

function maLoadHeader(var Head : tMsgHeaderRec; M : Word) : Boolean;
var HF : file of tMsgHeaderRec;
begin
   maLoadHeader := False;
   Assign(HF,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   {$I-}
   Reset(HF);
   {$I+}
   if ioResult <> 0 then Exit;
   if M > FileSize(HF) then
   begin
      Close(HF);
      Exit;
   end;
   Seek(HF,M-1);
   Read(HF,Head);
   Close(HF);
   maLoadHeader := True;
end;

function maAddMessage(var M : tMessage; var Head : tMsgHeaderRec; Save : Boolean) : Boolean;
var F : file; HF : file of tMsgHeaderRec; S : String; C : Char;
    N : Word; TmpHdr : tMsgHeaderRec;
begin
   maAddMessage := False;
   Assign(F,Cfg^.pathMsgs+mArea^.Filename+extMsgData);
   {$I-}
   Reset(F,1);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F,1);
      {$I+}
      if ioResult <> 0 then Exit;
   end else Seek(F,FileSize(F));
   Head.Pos := FileSize(F)+1;
   for N := 1 to Head.Size do maWriteStr(F,M[N]);
   Close(F);
   Assign(HF,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   {$I-}
   Reset(HF);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(HF);
      {$I+}
      if ioResult <> 0 then Exit;
   end else Seek(HF,FileSize(HF));
   Write(HF,Head);
   Close(HF);
   Inc(mArea^.Msgs);
   if Save then
   begin
      if mArea^.areaType = mareaEmail then emailSave else maSave;
   end;
   maAddMessage := True;
end;

function maReplaceMessage(var M : tMessage; var Head : tMsgHeaderRec; mn : Word) : Boolean;
var F : file; HF : file of tMsgHeaderRec; S : String; C : Char;
    N : Word; TmpHdr : tMsgHeaderRec;
begin
   maReplaceMessage := False;
   Assign(F,Cfg^.pathMsgs+mArea^.Filename+extMsgData);
   {$I-}
   Reset(F,1);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F,1);
      {$I+}
      if ioResult <> 0 then Exit;
   end else Seek(F,FileSize(F));
   Head.Pos := FileSize(F)+1;
   for N := 1 to Head.Size do maWriteStr(F,M[N]);
   Close(F);
   Assign(HF,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   {$I-}
   Reset(HF);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(HF);
      {$I+}
      if ioResult <> 0 then Exit;
   end else Seek(HF,mn-1);
   Write(HF,Head);
   Close(HF);
   maReplaceMessage := True;
end;

function maAddMsgFile(var fn : String; var Head : tMsgHeaderRec) : Boolean;
var F : file; M : Text; HF : file of tMsgHeaderRec; S : String; C : Char;
    N : Word; TmpHdr : tMsgHeaderRec;
begin

   Head.Size := 0;
   maAddMsgFile := False;
   Assign(M,Fn);
   {$I-}
   Reset(M);
   {$I+}
   if ioResult <> 0 then Exit;
   N := 0;

   Assign(F,Cfg^.pathMsgs+mArea^.Filename+extMsgData);
   {$I-}
   Reset(F,1);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F,1);
      {$I+}
      if ioResult <> 0 then
      begin
         Close(M);
         Exit;
      end;
   end else Seek(F,FileSize(F));
   Head.Pos := FileSize(F)+1;

   while (not Eof(M)) and (N < 64000) do
   begin
      Inc(N);
      FillChar(S,SizeOf(S),0);
      ReadLn(M,S);
      if Length(S) > 80 then S[0] := #80;
      maWriteStr(F,S);
   end;

   Head.Size := N;

   Close(M);
   Close(F);

   Assign(HF,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   {$I-}
   Reset(HF);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(HF);
      {$I+}
      if ioResult <> 0 then Exit;
   end else Seek(HF,FileSize(HF));
   Write(HF,Head);
   mArea^.Msgs := fileSize(hf);
   Close(HF);
   maAddMsgFile := True;
end;

function maLoadMessage(var Mr : tMessage; var Head : tMsgHeaderRec; M : Word) : Boolean;
var F : file; HF : file of tMsgHeaderRec; N, s : Word;
begin
   maLoadMessage := False;
   Assign(HF,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   Assign(F,Cfg^.pathMsgs+mArea^.Filename+extMsgData);
   {$I-}
   Reset(HF);
   {$I+}
   if ioResult <> 0 then Exit;
   if M > FileSize(HF) then
   begin
      Close(HF);
      Exit;
   end;
   Seek(HF,M-1);
   Read(HF,Head);
   Close(HF);
   {$I-}
   Reset(F,1);
   {$I+}
   if ioResult <> 0 then Exit;
   if Head.Pos > FileSize(F) then
   begin
      Close(F);
      Exit;
   end;
   Seek(F,Head.Pos-1);
   FillChar(Mr,SizeOf(Mr),0);
   s := Head.Size;
   if s > maxMsgLines then s := maxMsgLines;
   Head.Size := s;
   for N := 1 to s do Mr[N] := maReadStr(F);
   Close(F);
   maLoadMessage := True;
end;

function maPostMessage(whoTo, theSubject : String; rN : Word; AskUL : Boolean) : Boolean;
var Usr : tUserRec; Head : tMsgHeaderRec; Txt, rTxt : pMessage; Def : String;
    Reply, Ok, autoQuote, AttachIt : Boolean; rHead : pMsgHeaderRec;
begin
   maPostMessage := False;
   Reply := rN > 0;
   rTxt := nil; rHead := nil;
   if Reply then
   begin
      New(rTxt);
      New(rHead);
      if not maLoadMessage(rTxt^,rHead^,rN) then
      begin
         Dispose(rTxt);
         Dispose(rHead);
         Exit;
      end;
   end;
   FillChar(Head,SizeOf(Head),0);
   if (not maHasAccess) or (not maHasPostAccess) then
   begin
      oStringLn(strMsgNoPostAcs);
      oDnLn(1);
      if Reply then
      begin
         Dispose(rTxt);
         Dispose(rHead);
      end;
      Exit;
   end;
   Head.Status := [];
   Head.NetFlag := [];

   if mArea^.areaType = mareaEmail then
   begin
      Head.Status := Head.Status+[msgPrivate];
      Head.msgTag := emailTag;
      AttachIt := acsOk(Cfg^.acsAttachEmail);
   end else
   if mArea^.areaType = mareaEchoMail then
   begin
      Head.Status := Head.Status+[msgEchoMail];
      Head.msgTag := 0;
      AttachIt := False; { EchoMail = no files :) }
   end else
   begin
      Head.msgTag := 0;
      AttachIt := acsOk(Cfg^.acsAttachPublic);
   end;

   if Reply then
   begin
      Def := rHead^.Subject;
      if UpStr(Copy(Def,1,3)) <> 'RE:' then Insert('Re: ',Def,1);
      Head.ToInfo := rHead^.FromInfo;
      if maPrivate in mArea^.Flag then
      begin
         oString(strMsgAskPrivate);
         if iYesNo(msgPrivate in rHead^.Status) then Head.Status := Head.Status+[msgPrivate];
      end;
   end else
   begin
      if mArea^.areaType = mareaEmail then Def := '' else Def := 'All';
      oString(strMsgAskWhoTo);
      if whoTo = '' then
      Usr.UserName := iReadString(Def,inNormal,chNormal,'',36) else
      begin
         Usr.UserName := whoTo;
         oCWriteLn(Usr.UserName);
      end;
      Def := '';
      if Usr.UserName = '' then Exit;
      if userSearch(Usr,False) then with Head.ToInfo do
      begin
         userLoad(Usr);
         UserNum := Usr.Number;
         Alias := Usr.UserName;
         RealName := Usr.RealName;
         Name := Usr.UserName;
         UserNote := Usr.UserNote;
         FillChar(Address,SizeOf(Address),0);
         if mArea^.areaType = mareaEchoMail then
                Address := Cfg^.Address[mArea^.Address];
         if (maPrivate in mArea^.Flag) and ((mArea^.areaType = mareaEmail) or
             ((Cfg^.AskPrivateMsg) and (not Reply)) or
                (Cfg^.AskPrivateReply) and (Reply)) then
         begin
            oString(strMsgAskPrivate);
            if iYesNo(False) then Head.Status := Head.Status+[msgPrivate];
         end;
      end else if mArea^.areaType = mareaEmail then
      begin
         oStringLn(strEmailUserUnknown);
         Exit;
      end else with Head.ToInfo do
      begin
         UserNum := 0;
         Alias := 'None';
         RealName := 'None';
         Name := Usr.UserName;
         UserNote := 'None';
         FillChar(Address,SizeOf(Address),0);
      end;
   end;
   oString(strMsgAskTitle);
   if theSubject = '' then
   Head.Subject := iReadString(Def,inNormal,chNormal,'',40) else
   begin
      Head.Subject := theSubject;
      oCWriteLn(Head.Subject);
   end;
   if Head.Subject = '' then Exit;
   with Head.FromInfo do
   begin
      UserNum := User^.Number;
      Alias := User^.UserName;
      RealName := User^.RealName;
      if maRealName in mArea^.Flag then Name := User^.RealName else
                                        Name := User^.UserName;
      UserNote := User^.UserNote;
   end;
   if (acsOk(Cfg^.acsAnonymous)) and (not (msgPrivate in Head.Status)) and (maAnonymous in mArea^.Flag) then
   begin
      oString(strMsgAskAnonymous);
      if iYesNo(False) then
      begin
         Head.Status := Head.Status+[msgAnonymous];
         Head.FromInfo.Name := mStr(strAnonymous);
      end;
   end;
   Head.Replies := 0;
   Head.Date := dtDateTimePacked;
   Head.incFile := 0;

   if msgPrivate in Head.Status then Head.netFlag := Head.netFlag+[nPrivate];
   Head.netFlag := Head.netFlag+[nHold];
   New(Txt);

   autoQuote := (Reply) and (acQuote in User^.acFlag);
   Ok := False;
   if (((Reply) and (Cfg^.AskUploadReply)) or (not Reply)) and
      (((mArea^.areaType = mareaEmail) and (Cfg^.AskUploadEmail)) or (mArea^.areaType <> mareaEmail)) and
        (acsOk(Cfg^.acsUploadMessage)) and (AskUL) then
   begin
      oString(strMsgAskUploadMsg);
      if iYesNo(False) then
         Ok := maUploadMessage(Head);
{        if Head.Size > 0 then Ok := maAddMessage(Txt^,Head,True);}
   end else if (Reply) and (Cfg^.AskAutoQuote) then
   begin
      oString(strMsgAskQuote);
      autoQuote := iYesNo(acQuote in User^.acFlag);
   end;
   if not Ok then if fsEdit(Txt^,Head,True,rTxt,rHead,autoQuote,attachIt) then Ok := maAddMessage(Txt^,Head,False);
   maPostMessage := Ok;
   if Ok then
   begin
      if User^.curMsgArea = 0 then
      begin
         logWrite('Email sent');
         oStrLn(strCode(mStr(strEmailSent),1,Head.ToInfo.Name));
      end else
      begin
         logWrite('Message posted in area "'+mArea^.Name+'"');
         oStrLn(strCode(mStr(strMsgPublicPosted),1,mArea^.Name));
      end;
      logWrite('  Title: "'+Head.Subject+'",  From: '+Head.FromInfo.Name+',  To: '+Head.ToInfo.Name);
      if msgPrivate in Head.Status then
      begin
         Inc(Stat^.Email);
         Inc(His^.Email);
         Inc(User^.Email);
      end else
      begin
         Inc(Stat^.Posts);
         Inc(His^.Posts);
         Inc(User^.Posts);
      end;
      if mArea^.AreaType = mareaEchomail then errorLevel := Cfg^.echomailLev;
      statSave;
      hisSave;
      userSave(User^);
      if mArea^.areaType = mareaEmail then emailSave else maSave;
   end;
   Dispose(Txt);
   if Reply then
   begin
      Dispose(rTxt);
      Dispose(rHead);
   end;
end;

{
Date: 4:06 pm  Mon Nov 28, 1994        Number : 50 of 51
From: Highflyer                        Base   : [Local] General Messages
To  : Sysop                            Refer #: None
Subj: log out                          Replies: 1
Stat: Normal                           Origin : Local
}

function maStatus(var Head : tMsgHeaderRec) : String;
var StatStr : String;
begin
   StatStr := '';
   if msgDeleted in Head.Status then StatStr := '[Deleted] ';
   if msgSent in Head.Status then StatStr := StatStr+'[Sent] ';
   if msgPrivate in Head.Status then StatStr := StatStr+'[Private] ';
   if msgForwarded in Head.Status then StatStr := StatStr+'[Forward] ';
   if Head.incFile > 0 then StatStr := StatStr+'[File] ';
   if msgAnonymous in Head.Status then StatStr := StatStr+'[Anonymous]';
   StatStr := CleanUp(StatStr);
   if StatStr = '' then StatStr := '[Normal]';
   maStatus := StatStr;
end;

procedure maShowMessage(var mf : file; var Head : tMsgHeaderRec; realMsg : Word);
var Ans : Boolean; RepStr, StatStr, uNote, S : String; Ln, X : Word;
begin
   Seek(mf,Head.Pos-1);
   oClrScr;
   if Head.Replies < 1 then RepStr := 'None' else RepStr := St(Head.Replies);
   StatStr := maStatus(Head);
   if msgAnonymous in Head.Status then uNote := 'Unknown' else
                                       uNote := Head.FromInfo.UserNote;

   sfStr[1]  := dtTimePackedString(Head.Date);
   sfStr[2]  := dtDatePackedString(Head.Date);
   sfStr[3]  := Head.FromInfo.Name;
   sfStr[4]  := Head.ToInfo.Name;
   sfStr[5]  := Head.Subject;
   sfStr[6]  := St(curMsg)+'/'+St(numMsg);
   sfStr[7]  := mArea^.Name;
   sfStr[8]  := St(Head.Replies);
   sfStr[9]  := StatStr;
   sfStr[10] := uNote;
   PausePos := 1;
   PauseAbort := False;
   if User^.curMsgArea <> 0 then Ans := sfShowTextFile(txMsgHeader,ftMsgHeader) else
                                 Ans := sfShowTextFile(txEmailHeader,ftMsgHeader);
   if Ans then
   begin
      sfGotoPos(11);
      oUpPause(ansiRows-1);
   end else
   begin
      oCWriteLn('|U4Time  |U5: |U6'+Resize(dtTimePackedString(Head.Date),7)+
              '   |U4Date |U5: |U6'+dtDatePackedString(Head.Date)+
     '        |U4Number   |U5: |U6'+St(curMsg)+'|U4 of |U6'+St(numMsg));
      oCWriteLn('|U4From  |U5: |U6'+Resize(Head.FromInfo.Name,32)+
            ' |U4Msg Area |U5: |U6'+strSquish(mArea^.Name,28));
      oCWriteLn('|U4To    |U5: |U6'+Resize(Head.ToInfo.Name,32)+
            ' |U4Replies  |U5: |U6'+RepStr);
      oCWriteLn('|U4Title |U5: |U6'+Resize(Head.Subject,32)+
            ' |U4Status   |U5: |U6'+strSquish(StatStr,28));
      oUpPause(4);
      oDnLn(1);
      oUpPause(1);
   end;
   if (msgAnonymous in Head.Status) and ((maIsSponsor) or (acsOk(Cfg^.acsCoSysOp))) then
   begin
      oCWriteLn('|U5Anonymous message by: |U4'+Head.FromInfo.Alias+
                ' |U5['+Head.FromInfo.RealName+']');
      oUpPause(1);
   end;
   emuANSiInit;
   oSetCol(colTextHi);
   for Ln := 1 to Head.Size do if (not HangUp) and (not PauseAbort) then
   begin
      S := maReadStr(mf);
      X := Pos('>',S);
      if Pos(#27,S) = 0 then
      begin
         if (X > 0) and (X < 4) then
         begin
            Insert('|U1',S,1);
            S := S+'|U3';
         end else if (Copy(S,1,3) = '---') and
                     ((Ord(S[0]) = 3) or (S[4] = ' ')) then Insert('|U2',S,1);
         oStrCtrLn(S);
         oUpPause(1);
      end else oWriteANSi(S+#13#10);
   end;
   if Head.incFile > 0 then
   begin
      atAskDownload(Head);
      maSaveHeader(Head,realMsg);
   end;
   PausePos := 0;
end;

function maOKtoRead(var Head : tMsgHeaderRec) : Boolean;
begin
   maOKtoRead := ((not (msgPrivate in Head.Status)) and (not (msgDeleted in Head.Status))) or
                  (((msgPrivate in Head.Status) or (msgDeleted in Head.Status)) and
                  ((Head.ToInfo.Alias = User^.UserName) or
                   (Head.ToInfo.RealName = User^.RealName) or
                   (acsOk(Cfg^.acsCoSysOp)) or
                   (maIsSponsor) or
                   (Head.FromInfo.Alias = User^.UserName) or
                   (Head.FromInfo.RealName = User^.RealName)));
end;

function maOKtoDelete(var Head : tMsgHeaderRec) : Boolean;
begin
   maOKtoDelete := (acsOk(Cfg^.acsCoSysOp)) or
                   (maIsSponsor) or

                    ((msgPrivate in Head.Status) and
                    ((Head.ToInfo.Alias = User^.UserName) or
                    (Head.ToInfo.RealName = User^.RealName))) or

                    ((Head.FromInfo.Alias = User^.UserName) or
                    (Head.FromInfo.RealName = User^.RealName));
end;

function maOKtoEdit(var Head : tMsgHeaderRec) : Boolean;
begin
   maOKtoEdit   := (acsOk(Cfg^.acsCoSysOp)) or
                   (maIsSponsor) or

                    ((Head.FromInfo.Alias = User^.UserName) or
                    (Head.FromInfo.RealName = User^.RealName));
end;

function maCheckMessage(var Head : tMsgHeaderRec) : Boolean;
begin
   maCheckMessage := False;
   while (not maOktoRead(Head)) and (curMsg < numMsg) do
   begin
      Inc(curMsg);
      maLoadHeader(Head,curMsg);
   end;
   maCheckMessage := maOktoRead(Head);
end;

function maCheckMessageBack(var Head : tMsgHeaderRec) : Boolean;
begin
   maCheckMessageBack := False;
   while (not maOktoRead(Head)) and (curMsg > 1) do
   begin
      Dec(curMsg);
      maLoadHeader(Head,curMsg);
   end;
   maCheckMessageBack := maOktoRead(Head);
end;

procedure maUpdateScanFile;
var sf : file of tScanRec; sfs, N : LongInt; sfr : tScanRec;
begin
   Assign(sf,Cfg^.pathMsgs+mArea^.Filename+extMsgScan);
   {$I-}
   Reset(sf);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(sf);
      {$I+}
      if ioResult <> 0 then Exit;
   end;

   sfs := FileSize(sf);

   with sfr do
   begin
      scnMsg := True;
      ptrMsg := 0;
   end;

   if sfs > numUsers then
   begin
      Seek(sf,numUsers+1);
      Truncate(sf);
   end else
   begin
      Seek(sf,sfs);
      while FileSize(sf) < numUsers do Write(sf,sfr);
      sfs := FileSize(sf);
   end;

{  if numUsers > sfs then
   begin
      Seek(sf,sfs);
      for N := sfs to numUsers do Write(sf,sfr);
   end else}
   Close(sf);
end;

procedure maLoadScan(var S : tScanRec; U : Word);
var sf : file of tScanRec;
begin
   Assign(sf,Cfg^.pathMsgs+mArea^.Filename+extMsgScan);
   {$I-}
   Reset(sf);
   {$I+}
   if ioResult <> 0 then
   begin
      maUpdateScanFile;
      {$I-}
      Reset(sf);
      {$I+}
      if ioResult <> 0 then Exit;
   end;
   {$I-}
   Seek(sf,U-1);
   {$I+}
   if ioResult <> 0 then
   begin
      Close(sf);
      maUpdateScanFile;
      Reset(sf);
      Seek(sf,U-1);
   end;
   Read(sf,S);

   Close(sf);
end;

procedure maSaveScan(var S : tScanRec; U : Word);
var sf : file of tScanRec;
begin
   Assign(sf,Cfg^.pathMsgs+mArea^.Filename+extMsgScan);
   {$I-}
   Reset(sf);
   {$I+}
   if ioResult <> 0 then
   begin
      maUpdateScanFile;
      {$I-}
      Reset(sf);
      {$I+}
      if ioResult <> 0 then Exit;
   end;
   {$I-}
   Seek(sf,U-1);
   {$I+}
   if ioResult <> 0 then
   begin
      Close(sf);
      maUpdateScanFile;
      Reset(sf);
      Seek(sf,U-1);
   end;
   Write(sf,S);

   Close(sf);
end;

procedure maUpdateAllScanFiles;
var N, X : Word; F : file of tMsgAreaRec;
begin
   X := User^.curMsgArea;
   Assign(F,Cfg^.pathData+fileMsgArea);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   numMsgArea := FileSize(F);
   while not Eof(F) do
   begin
      User^.curMsgArea := FilePos(F)+1;
      Read(F,mArea^);
      maUpdateScanFile;
   end;
   Close(F);
   User^.curMsgArea := X;
   maLoad;
end;

function maReadMessages(Start : Word; Mand : Boolean; Show : Boolean) : Boolean;
var Ch : Char; S : String; Head : pMsgHeaderRec; mf : file;
    Temp, HiMsg : Word; readDone, readShow, readGoto : Boolean;

 procedure rmPostAMessage(Show : Boolean);
 begin
    if (Cfg^.AskPostInArea) and (maHasPostAccess) then
    begin
       oDnLn(1);
       oString(strMsgReadAskPost);
       if iYesNo(False) then maPostMessage('','',0,True);
    end else if (Cfg^.askPostInArea) and (Show) then
    begin
       oDnLn(1);
       oStringLn(strMsgNoPostAcs);
       oDnLn(1);
    end;
    readDone := True;
 end;

 procedure rmListMessages;
 var fm, lm, cm : Integer; Ans, Hil : Boolean;
  function lmHil : Boolean;
  begin
     lmHil := (UpStr(Head^.ToInfo.Alias) = UpStr(User^.Username)) or
              (UpStr(Head^.ToInfo.RealName) = UpStr(User^.RealName)) or
              (UpStr(Head^.FromInfo.Alias) = UpStr(User^.Username)) or
              (UpStr(Head^.FromInfo.RealName) = UpStr(User^.RealName));
  end;
 begin
    fm := curMsg;
    lm := fm+User^.PageLength-5;
    if lm > numMsg then lm := numMsg;
    if lm < fm then lm := fm;
    Ans := (sfGetTextFile(txListMsgTop,ftTopLine) <> '') and
           (sfGetTextFile(txListMsgMid,ftListMsg) <> '') and
           (sfGetTextFile(txListMsgBot,ftNormal) <> '');
    Hil := (not Ans) or (sfGetTextFile(txListMsgHil,ftListMsg) <> '');
    if Ans then
    begin
       sfShowTextFile(txListMsgTop,ftTopLine);
       sfGotoPos(1);
       sfLoadRepeat(txListMsgMid);
    end else
    begin
       oClrScr;
       oSetCol(colInfo);
       oCWriteLn('|U4 Num   Sender                 Receiver               Subject');
{                         5                     22                     22}
       oSetCol(colBorder);
       oWriteLn(sRepeat('Ä',79));
    end;
    cm := fm;
    for cm := fm to lm do if (maLoadHeader(Head^,cm)) and
                             (maOkToRead(Head^)) then
    begin
       if Ans then
       begin
          sfStr[1] := St(cm);
          sfStr[2] := Head^.FromInfo.Name;
          sfStr[3] := Head^.ToInfo.Name;
          sfStr[4] := dtTimePackedString(Head^.Date);
          sfStr[5] := dtDatePackedString(Head^.Date);
          sfStr[6] := Head^.Subject;
          if (Hil) and (lmHil) then
          begin
             sfKillRepeat;
             sfLoadRepeat(txListMsgHil);
             sfShowRepeat(ftListMsg);
             sfKillRepeat;
             sfLoadRepeat(txListMsgMid);
          end else sfShowRepeat(ftListMsg);
          if oWhereX <> 1 then oDnLn(1);
       end else
       begin
          if lmHil then oSetCol(colTextHi) else oSetCol(colText);
          oWriteLn(' '+Resize(St(cm),5)+
                   ' '+Resize(Head^.FromInfo.Name,22)+
                   ' '+Resize(Head^.ToInfo.Name,22)+
                   ' '+strSquish(Head^.Subject,25));
       end;
    end;
    sfKillRepeat;
    if Ans then sfShowTextFile(txListMsgBot,ftNormal) else
    begin
       oSetCol(colBorder);
       oWriteLn(sRepeat('Ä',79));
    end;
    curMsg := lm;
    maLoadHeader(Head^,curMsg);
    maCheckMessageBack(Head^);
 end;

begin
   maReadMessages := True;
   New(Head);
   numMsg := mArea^.Msgs;
   readDone := False;
   readShow := True;
   if numMsg < 1 then
   begin
      if Show then
      begin
         oDnLn(1);
         oStringLn(strMsgReadNoMsgs);
         oDnLn(1);
      end;
      Dispose(Head);
      Exit;
   end;
   curMsg := Start;
   maLoadScan(Scan^,User^.Number);
   HiMsg := maNewScanMsgNum;
   if HiMsg = 0 then HiMsg := mArea^.Msgs;
   if curMsg <= 0 then
   begin
      oStr(strCode(strCode(mStr(strMsgReadStartAt),1,St(numMsg)),2,St(HiMsg)));
      S := iReadString(St(HiMsg),inUpper,chNumeric,'',Length(St(numMsg)));
      if S = '' then S := '1';
      curMsg := StrToInt(S);
   end;
   if curMsg > numMsg then curMsg := numMsg;
   if curMsg < 1 then curMsg := 1;
   Assign(mf,Cfg^.pathMsgs+mArea^.Filename+extMsgData);
   {$I-}
   Reset(mf,1);
   {$I+}
   if ioResult <> 0 then
   begin
      Dispose(Head);
      Exit;
   end;
   if (not maLoadHeader(Head^,curMsg)) or (not maCheckMessage(Head^)) then
   begin
      Dispose(Head);
      Exit;
   end;
   repeat
      if readShow then maShowMessage(mf,Head^,curMsg);
      if Head^.Date > Scan^.ptrMsg then
      begin
         Scan^.ptrMsg := Head^.Date;
         maSaveScan(Scan^,User^.Number);
      end;
      readShow := False;
      oStr(strCode(strCode(mStr(strMsgReadPrompt),1,St(curMsg)),2,St(numMsg)));
      S := '';
      readGoto := False;
      repeat
         Ch := UpCase(iReadKey);
         if Ch in ['0'..'9'] then
         begin
            S := S+Ch;
            readGoto := Length(S) >= Length(St(mArea^.Msgs));
            oWriteChar(Ch);
         end else
         if (Ch = #8) and (Length(S) > 0) then
         begin
            oBackSpace(' ');
            Delete(S,Length(S),1);
         end else
         if (Ch = #13) and (Length(S) > 0) then readGoto := True;
      until (HangUp) or (readGoto) or
            ((extKey = #0) and (Ch in [#27,#13,'Q','-','P','?','A','R','D','E','H','L','I','X','U','Z','S']));
      if (S = '') then oWriteLn(Ch);
      if not readGoto then
      case Ch of
         #27,'Q' : if (Cfg^.AbortMandOk) or (not Mand) then
                   begin
                      readDone := True;
                      maReadMessages := False;
                   end else oStringLn(strMsgReadMandatory);
         #13     : begin
              if Length(S) > 0 then readGoto := True else
              if (curMsg < numMsg) and (maLoadHeader(Head^,curMsg+1)) then
              begin
                 Inc(curMsg);
                 if not maCheckMessage(Head^) then rmPostAMessage(False);
                 readShow := True;
              end else rmPostAMessage(False);
         end;
         'I'     : if (Cfg^.AbortMandOk) or (not Mand) then begin
              curMsg := numMsg;
              maLoadHeader(Head^,curMsg);
              Scan^.ptrMsg := Head^.Date;
              maSaveScan(Scan^,User^.Number);
              readDone := True;
         end else oStringLn(strMsgReadMandatory);
         'S'     : if (Cfg^.AbortMandOk) or (not Mand) then readDone := True
                      else oStringLn(strMsgReadMandatory);
         '-'     : begin
              if (curMsg > 1) and (maLoadHeader(Head^,curMsg-1)) then
              begin
                 Temp := curMsg;
                 Dec(curMsg);
                 if not maCheckMessageBack(Head^) then
                 begin
                    curMsg := Temp;
                    maLoadHeader(Head^,curMsg);
                 end;
                 readShow := True;
              end;
         end;
         'P'     : begin
              readShow := True;
              maPostMessage('','',0,True);
              numMsg := mArea^.Msgs;
         end;
         '?'     : begin
              if sfShowTextFile(txReadHelp,ftNormal) then
              begin
                 oPromptKey;
                 readShow := True;
              end;
         end;
         'A'     : readShow := True;
         'R'     : if maPostMessage('','',curMsg,True) then
                   begin
              Inc(Head^.Replies);
              maSaveHeader(Head^,curMsg);
              oDnLn(1);
{             readShow := True;}
              numMsg := mArea^.Msgs;
         end;
         'D'     : if maOktoDelete(Head^) then
                   begin
              if msgDeleted in Head^.Status then
              begin
                 Head^.Status := Head^.Status-[msgDeleted];
                 oStringLn(strMsgUndeleted);
                 logWrite('-Message "'+Head^.Subject+'" in area "'+mArea^.Name+'" undeleted');
              end else
              begin
                 Head^.Status := Head^.Status+[msgDeleted];
                 oStringLn(strMsgDeleted);
                 logWrite('-Message "'+Head^.Subject+'" in area "'+mArea^.Name+'" deleted');
              end;
              maSaveHeader(Head^,curMsg);
              readShow := True;
         end;
         'E'     : if maOktoEdit(Head^) then
                   begin
              maEditMessage(Head^,curMsg);
              logWrite('-Message "'+Head^.Subject+'" in area "'+mArea^.Name+'" edited');
              readShow := True;
         end;
         'H'     : begin
              oStringLn(strMsgSetPointer);
              Scan^.ptrMsg := Head^.Date;
              readShow := True;
         end;
         'L'     : rmListMessages;
         'U'     : if acsOk(Cfg^.acsSysOp) then cfgUserEditor(Head^.FromInfo.UserNum);
         'X'     : begin maDownloadMessage(curMsg); readShow := True; end;
         'Z'     : if acsOk(Cfg^.acsCoSysOp) then
                   begin
                      Head^.Date := dtDateTimePacked;
                      maSaveHeader(Head^,curMsg);
                      readShow := True;
                   end;
      end else
      begin
         oDnLn(1);
         Temp := curMsg;
         curMsg := StrToInt(S);
         if (curMsg >= 1) and (curMsg <= mArea^.Msgs) then
         begin
            maLoadHeader(Head^,curMsg);
            if not maCheckMessageBack(Head^) then curMsg := Temp;
         end else curMsg := Temp;
         maLoadHeader(Head^,curMsg);
         readShow := True;
      end;
   until (HangUp) or (readDone);
   maSaveScan(Scan^,User^.Number);
   maSave;
   Dispose(Head);
   Close(mf);
   oDnLn(1);
end;

function maNewScanMsgNum : Word;
var HF : file; Head : pMsgHeaderRec; N : Word; Found : Boolean;
begin
   maNewScanMsgNum := 0;
   New(Head);
   Assign(HF,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   {$I-}
   Reset(HF,SizeOf(Head^));
   {$I+}
   if ioResult <> 0 then
   begin
      Dispose(Head);
      Exit;
   end;
   Found := False;
   N := 0;
   while (not Found) and (not Eof(HF)) do
   begin
      BlockRead(HF,Head^,1);
      Inc(N,1);
      Found := (Head^.Date > Scan^.ptrMsg) and (maOktoRead(Head^));
   end;
   if Found then maNewScanMsgNum := N else maNewScanMsgNum := 0;
   Close(HF);
   Dispose(Head);
end;

procedure maListAreas(Change : Boolean);
var Ans, Hil : Boolean; F : file of tMsgAreaRec; A : tMsgAreaRec; N, cN : Word;
    S : String; Ref : array[1..maxMsgArea] of Word;
begin
   if not Change then logWrite('Listed message areas');
   Assign(F,Cfg^.pathData+fileMsgArea);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Ans := (sfGetTextFile(txMareaLtop,ftTopLine) <> '') and
          (sfGetTextFile(txMareaLmid,ftListMarea) <> '') and
          (sfGetTextFile(txMareaLbot,ftNormal) <> '');
   Hil := (not Ans) or (sfGetTextFile(txMareaLhil,ftListMarea) <> '');
   PausePos := 1;
   PauseAbort := False;
   if Ans then
   begin
      sfShowTextFile(txMareaLtop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txMareaLmid);
   end else
   begin
      oClrScr;
      oDnLn(1);
      oSetCol(colInfo);
      oCWriteLn(' Num    Area Title                     Msgs    Sponsor');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(2);
   end;
   N := 0;
   cN := 0;
   FillChar(Ref,SizeOf(Ref),0);
   while not Eof(F) do
   begin
      Read(F,A);
      Inc(N);
      if not Cfg^.compMsgAreas then
      begin
         Inc(cN);
         Ref[cN] := N;
      end;
      if (acsOk(A.Acs)) or (maUnhidden in A.Flag) then
      begin
         if Cfg^.compMsgAreas then
         begin
            Inc(cN);
            Ref[cN] := N;
         end;
         if PauseAbort then begin end else
         if Ans then
         begin
            sfStr[1] := A.Name;
            sfStr[2] := St(cN);
            sfStr[3] := St(A.Msgs);
            sfStr[4] := A.Sponsor;
            if (Hil) and (N = User^.curMsgArea) then
            begin
               sfKillRepeat;
               sfLoadRepeat(txMareaLHil);
               sfShowRepeat(ftListMarea);
               sfKillRepeat;
               sfLoadRepeat(txMareaLMid);
            end else sfShowRepeat(ftListMarea);
            if oWhereX <> 1 then oDnLn(1);
            oUpPause(1);
         end else
         begin
            if N = User^.curMsgArea then oSetCol(colTextHi) else oSetCol(colText);
            oWriteLn(' '+Resize(St(cN),6)+
                     ' '+Resize(A.Name,30)+
                     ' '+Resize(St(A.Msgs),7)+
                     ' '+strSquish(A.Sponsor,36));
            oUpPause(1);
         end;
      end;
   end;
   sfKillRepeat;
   Close(F);
   if Ans then
   begin
      sfShowTextFile(txMareaLbot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
   end;
   PausePos := 0;
   if Change then
   begin
      oString(strMsgAskChangeArea);
      S := iReadString('',inUpper,chNumeric,'',4);
      N := strToInt(S);
      if (S <> '') and (N > 0) and (N <= cN) and (maChangeArea(Ref[N])) then
      begin
         maUpdateScanFile;
         oStrLn(strCode(mStr(strMsgChangedAreas),1,mArea^.Name));
      end;
   end;
end;

procedure maNewScan(AllAreas : Boolean; Num : Word);
var N, Z, A : Word; Ok : Boolean;
begin
   if numMsgArea < 1 then Exit;
   A := User^.curMsgArea;
   Ok := True;
   if AllAreas then
   begin
      logWrite('Global message newscan');
      oStringLn(strMsgNewScanInit);
      for N := 1 to numMsgArea do if Ok then
      begin
         User^.curMsgArea := N;
         maLoad;
         if maHasAccess then
         begin
            oStr(strCode(strCode(mStr(strMsgNewScanStart),1,mArea^.Name),2,St(mArea^.Msgs)));
            maLoadScan(Scan^,User^.Number);
            Z := maNewScanMsgNum;
            cCheckUser;
            oDnLn(1);
            if Z > 0 then Ok := (not HangUp) and (maReadMessages(Z,False,False));
            oStrLn(strCode(strCode(mStr(strMsgNewScanEnd),1,mArea^.Name),2,St(mArea^.Msgs)));
         end;
      end;
      oStringLn(strMsgNewScanDone);
   end else
   begin
      if Num = 0 then N := User^.curMsgArea else N := Num;
      if N > numMsgArea then N := numMsgArea else if N < 1 then N := 1;
      User^.curMsgArea := N;
      maLoad;
      if maHasAccess then
      begin
         logWrite('Newscanned message area "'+mArea^.Name+'"');
         oStr(strCode(strCode(mStr(strMsgNewScanStart),1,mArea^.Name),2,St(mArea^.Msgs)));
         maLoadScan(Scan^,User^.Number);
         Z := maNewScanMsgNum;
         oDnLn(1);
         if Z > 0 then maReadMessages(Z,False,False);
         oStrLn(strCode(strCode(mStr(strMsgNewScanEnd),1,mArea^.Name),2,St(mArea^.Msgs)));
      end;
   end;
   User^.curMsgArea := A;
   maLoad;
end;

procedure maNewScanAsk(Par : String);
var All : Boolean; Num : Word;
begin
   oDnLn(1);
   All := False;
   Num := 0;
   if Par <> '' then
   begin
      Par := UpStr(Par);
      All := (Par[1] = 'A');
      if not All then Num := StrToInt(Par);
   end;
   if (not All) and (Num = 0) then
   begin
      oString(strMsgNewScanAskAll);
      All := iYesNo(True);
      oDnLn(1);
   end;
   maNewScan(All,Num);
end;

procedure maPackMessageArea;
var fH, tH : file of tMsgHeaderRec; fD, tD : file;
    Head, TmpHead : pMsgHeaderRec;
    Z, X, P, numM : Word; Pack : Boolean;
begin
   Assign(fH,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   Assign(fD,Cfg^.pathMsgs+mArea^.Filename+extMsgData);
   Assign(tH,Cfg^.pathMsgs+'MSGHEAD.$$$');
   Assign(tD,Cfg^.pathMsgs+'MSGDATA.$$$');

   Pack := False;
   {$I-}
   Reset(fH);
   if ioResult <> 0 then Exit;
   Reset(fD,1);
   if ioResult <> 0 then
   begin
      Close(fH);
      Exit;
   end;
   {$I-}

   oStr(strCode(strCode(mStr(strMsgPackStart),1,mArea^.Name),2,St(mArea^.Msgs)));

   New(Head);
   New(TmpHead);

   if ((mArea^.maxMsgs <> 0) and (FileSize(fH) > mArea^.maxMsgs)) then
   begin
      numM := 0;
      Pack := True;
      while not Eof(fH) do
      begin
         Read(fH,Head^);
         if (not (msgDeleted in Head^.Status)) then Inc(numM);
      end;
      if (numM > mArea^.maxMsgs) then
      begin
         Dec(numM,mArea^.maxMsgs);
         Seek(fH,0);
         while (numM > 0) and (not Eof(fH)) do
         begin
            Read(fH,Head^);
            if (not (msgDeleted in Head^.Status)) then
            begin
               Head^.Status := Head^.Status+[msgDeleted];
               Seek(fH,FilePos(fH)-1);
               Write(fH,Head^);
               Dec(numM);
            end;
         end;
      end;
      Seek(fH,0);
   end else
   begin
      while (not Pack) and (not Eof(fH)) do
      begin
         Read(fH,Head^);
         Pack := msgDeleted in Head^.Status;
      end;
      Seek(fH,0);
   end;

   if Pack then
   begin
      Rewrite(tH);
      Rewrite(tD,1);
      while not Eof(fH) do
      begin
         Read(fH,Head^);
         Seek(fD,Head^.Pos-1);
         if not (msgDeleted in Head^.Status) then
         begin
            Head^.Pos := FilePos(tD)+1;
            Write(tH,Head^);
            for x := 1 to Head^.Size do maWriteStr(tD,maReadStr(fD));
         end else
         begin
            Dec(mArea^.Msgs);
            if Head^.incFile > 0 then atKillAttach(Head^.incFile);
         end;
      end;
      mArea^.Msgs := FileSize(tH);
      Close(tH);
      Close(tD);
   end else mArea^.Msgs := FileSize(fH);

   Dispose(Head);
   Dispose(TmpHead);

   Close(fH);
   Close(fD);

   if Pack then
   begin
      Erase(fD);
      Erase(fH);
      fRenameFile(Cfg^.pathMsgs+'MSGDATA.$$$',Cfg^.pathMsgs+mArea^.Filename+extMsgData);
      fRenameFile(Cfg^.pathMsgs+'MSGHEAD.$$$',Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   end;

   if User^.curMsgArea = 0 then emailSave else maSave;
   oStrLn(strCode(strCode(mStr(strMsgPackEnd),1,mArea^.Name),2,St(mArea^.Msgs)));
end;

procedure maPackAreas(AllAreas : Boolean; Num : Word);
var N, Z, A : Word;
begin
   if numMsgArea < 1 then Exit;
   A := User^.curMsgArea;
   if AllAreas then logWrite('*Packing all message areas');
   if AllAreas then for N := 0 to numMsgArea do
   begin
      User^.curMsgArea := N;
      if N = 0 then emailLoad else maLoad;
      maPackMessageArea;
   end else
   begin
      if Num = 0 then N := User^.curMsgArea else N := Num;
      if N > numMsgArea then N := numMsgArea else if N < 1 then N := 1;
      User^.curMsgArea := N;
      maLoad;
      if maHasAccess then
      begin
         logWrite('*Packing message area "'+mArea^.Name+'"');
         maPackMessageArea;
      end;
   end;
   User^.curMsgArea := A;
   if UserOn then maLoad;
end;

procedure maPackAreaAsk(Par : String);
var All : Boolean; Num : Word;
begin
   oDnLn(1);
   All := False;
   Num := 0;
   if Par <> '' then
   begin
      Par := UpStr(Par);
      All := (Par[1] = 'A');
      if not All then Num := StrToInt(Par);
   end;
   if (not All) and (Num = 0) then
   begin
      oString(strMsgPackAskAll);
      All := iYesNo(True);
      oDnLn(1);
   end;
   maPackAreas(All,Num);
end;
(*
procedure maReplaceMessage(var Head : tMsgHeaderRec; var Txt : tMessage);
var fH : file of tMsgHeaderRec; fD, fT : file;
    TmpHead : pMsgHeaderRec; TmpTxt : pMessage;
    N, Z, X, P : Word;
begin
   if (curMsg < 1) or (curMsg > mArea^.Msgs) or (mArea^.Msgs < 1) then Exit;
   Assign(fH,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
   Assign(fD,Cfg^.pathMsgs+mArea^.Filename+extMsgData);
   Assign(fT,Cfg^.pathMsgs+'MSGDATA.$$$');

   {$I-}
   Reset(fH);
   if ioResult <> 0 then Exit;
   Reset(fD,1);
   if ioResult <> 0 then
   begin
      Close(fH);
      Exit;
   end;
   {$I+}

   Rewrite(fT,1);
   N := 0;

   New(TmpHead);
   New(TmpTxt);

   if curMsg > 1 then
   for N := 1 to curMsg-1 do
   begin
      Read(fH,TmpHead^);
      for X := 1 to TmpHead^.Size do TmpTxt^[X] := maReadStr(fD);
      for X := 1 to TmpHead^.Size do maWriteStr(fT,TmpTxt^[X]);
   end;

   Seek(fH,curMsg-1);
   Read(fH,TmpHead^);
   for X := 1 to TmpHead^.Size do TmpTxt^[X] := maReadStr(fD);

   Seek(fH,curMsg-1);
   Head.Pos := FilePos(fT)+1;
   Write(fH,Head);
   for X := 1 to Head.Size do maWriteStr(fT,Txt[X]);

   if curMsg < mArea^.Msgs then
   for N := curMsg+1 to mArea^.Msgs do
   begin
      Seek(fH,N-1);
      Read(fH,TmpHead^);
      Seek(fD,TmpHead^.Pos-1);
      TmpHead^.Pos := FilePos(fT)+1;
      Seek(fH,N-1);
      Write(fH,TmpHead^);
      for X := 1 to TmpHead^.Size do TmpTxt^[X] := maReadStr(fD);
      for X := 1 to TmpHead^.Size do maWriteStr(fT,TmpTxt^[X]);
   end;

   Dispose(TmpHead);
   Dispose(TmpTxt);

   Truncate(fH);

   Close(fH);
   Close(fD);
   Close(fT);

   Erase(fD);
   fRenameFile(Cfg^.pathMsgs+'MSGDATA.$$$',Cfg^.pathMsgs+mArea^.Filename+extMsgData);
end;
*)
procedure maEditMessage(var Head : tMsgHeaderRec; mn : Word);
var H2 : tMsgHeaderRec; Txt : ^tMessage;
begin
   if (User^.curMsgArea <> 0) and (not maOktoEdit(Head)) then Exit;
   New(Txt);
   if not maLoadMessage(Txt^,Head,curMsg) then
   begin
      Dispose(Txt);
      Exit;
   end;
   H2 := Head;
   if fsEdit(Txt^,Head,False,nil,nil,False,False) then maReplaceMessage(Txt^,Head,mn) else
      Head := H2;
   Dispose(Txt);
end;

function maLoadTextFile(fn : String; var Txt : tMessage) : Word;
var tF : Text; N : Word; S : String;
begin
   maLoadTextFile := 0;
   Assign(tF,Fn);
   {$I-}
   Reset(tF);
   {$I+}
   if ioResult <> 0 then Exit;
   N := 0;
   while (not Eof(tF)) and (N < maxMsgLines) do
   begin
      Inc(N,1);
      FillChar(S,SizeOf(S),0);
      ReadLn(tF,S);
      if Length(S) > 80 then Delete(S,81,255);
      Txt[N] := S;
   end;
   Close(tF);
   maLoadTextFile := N;
end;

function maExportMessage(fn : String; var Txt : tMessage; var Head : tMsgHeaderRec) : Boolean;
var tF : Text; N, E : Word;
begin
   maExportMessage := False;
   Assign(tF,Fn);
   {$I-}
   Rewrite(tF);
   {$I+}
   if ioResult <> 0 then Exit;
   WriteLn(tF,'From      : '+NoColor(Head.FromInfo.Name));
   WriteLn(tF,'To        : '+NoColor(Head.ToInfo.Name));
   WriteLn(tF,'Subject   : '+NoColor(Head.Subject));
   WriteLn(tF,'Area      : '+NoColor(mArea^.Name));
   WriteLn(tF,'Status    : '+NoColor(maStatus(Head)));
   WriteLn(tF);
   E := Head.sigPos;
   if E = 0 then E := Head.Size else Dec(E);
   for N := 1 to E do WriteLn(tF,Txt[N]);
   Close(tF);
   maExportMessage := True;
end;

procedure maScanForMandatory(N : Word);
var X, Y, Z, A : Word;
begin
   oString(strMsgScanMandatory);
   mandMsg := Cfg^.confIgnoreMsg;
   A := User^.curMsgArea;
   if N <> 0 then
   begin
      if N > numMsgArea then N := numMsgArea;
      logWrite('Scanning for mandatory messages in area number '+St(N));
      X := N;
      Y := N;
   end else
   begin
      logWrite('Scanning for mandatory messages');
      X := 1;
      Y := numMsgArea;
   end;
   for Z := X to Y do
   begin
      User^.curMsgArea := Z;
      if (maLoad) and (maMandatory in mArea^.Flag) and (maHasAccess) then
      begin
         maLoadScan(Scan^,User^.Number);
         N := maNewScanMsgNum;
         if N > 0 then maReadMessages(N,True,False);
      end;
   end;
   User^.curMsgArea := A;
   mandMsg := False;
   maLoad;
   oDnLn(1);
end;

procedure maReset;
begin
   FillChar(mArea^,SizeOf(tMsgAreaRec),0);
   with mArea^ do
   begin
      Name          := 'New '+bbsTitle+' Message Area';
      Filename      := 'NEWAREA';
      MsgPath       := '';
      Sponsor       := Cfg^.SysOpAlias;
      Acs           := 's25';
      PostAcs       := 's50';
      MaxMsgs       := 200;
      Msgs          := 0;
      Password      := '';
      AreaType      := mareaNormal;
      Origin        := 1;
      Address       := 1;
      qwkName       := 'NewArea';
      Flag          := [maPrivate,maAnonymous];
   end;
end;

function maLoad : Boolean;
var F : file of tMsgAreaRec;
begin
   maLoad := False;
   Assign(F,Cfg^.pathData+fileMsgArea);
   {$I-}
   Reset(F);
   if ioResult = 0 then numMsgArea := FileSize(F) else Exit;
   {$I+}
   if (User^.curMsgArea < 1) or (User^.curMsgArea > numMsgArea) then
   begin
      Close(F);
      Exit;
   end;
   {$I-}
   Seek(F,User^.curMsgArea-1);
   Read(F,mArea^);
   {$I+}
   maLoad:= ioResult = 0;
   Close(F);
end;

procedure maSave;
var F : file of tMsgAreaRec;
begin
   Assign(F,Cfg^.pathData+fileMsgArea);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult = 0 then numMsgArea := FileSize(F) else Exit;
   if (User^.curMsgArea < 1) or (User^.curMsgArea > numMsgArea) then
   begin
      Close(F);
      Exit;
   end;
   Seek(F,User^.curMsgArea-1);
   {$I-}
   Write(F,mArea^);
   numMsgArea := FileSize(F);
   {$I+}
   Close(F);
end;

procedure maSetPointerDate;
var D : String; Dt : Dos.DateTime; L : LongInt; ca, ma, fs, ls : Word;
begin
   oString(strMsgAskPointer);
   D := iReadDate('');
   if not dtValidDate(D) then Exit;
   Dt.Sec   := 0;
   Dt.Min   := 0;
   Dt.Hour  := 0;
   Dt.Month := strToInt(Copy(D,1,2));
   Dt.Day   := strToInt(Copy(D,4,2));
   Dt.Year  := strToInt(Copy(D,7,2))+1900;
   PackTime(Dt,L);
   ma := User^.curMsgArea;
   oString(strMsgAskAllPointers);
   if iYesNo(True) then
   begin
      fs := 1;
      ls := numMsgArea;
   end else
   begin
      fs := ma;
      ls := ma;
   end;
   for ca := fs to ls do
   begin
      User^.curMsgArea := ca;
      maLoad;
      maLoadScan(Scan^,User^.Number);
      Scan^.ptrMsg := L;
      maSaveScan(Scan^,User^.Number);
   end;
   User^.curMsgArea := ma;
   maLoad;
end;

function maUploadMessage(var H : tMsgHeaderRec) : Boolean;
var Fil : String; X : Word;
begin
   maUploadMessage := False;
   Fil := fTempPath('M')+'UPLOAD.MSG';
   fDeleteFile(Fil);
   if acsOk(Cfg^.acsSysOp) then
   begin
      oCWrite('|U5-- |U4Enter filename to import|U2 [|U3Enter|U2/|U1Upload|U2]|U5: |U6');
      Fil := iReadString('',inUpper,chDirectory,'',65);
      if Fil = '' then
      begin
         Fil := fTempPath('M')+'UPLOAD.MSG';
         if not xferReceive(Fil,[protActive]) then Exit;
      end;
   end else if not xferReceive(Fil,[protActive]) then Exit;
   maUploadMessage := maAddMsgFile(Fil,H);
   if not LocalIO then fDeleteFile(Fil);
end;

function maImportMessage(var M : tMessage) : Word;
var Fil : String; X : Word;
begin
   maImportMessage := 0;
   Fil := fTempPath('M')+'UPLOAD.MSG';
   fDeleteFile(Fil);
   if acsOk(Cfg^.acsSysOp) then
   begin
      oCWrite('|U5-- |U4Enter filename to import|U2 [|U3Enter|U2/|U1Upload|U2]|U5: |U6');
      Fil := iReadString('',inUpper,chDirectory,'',65);
      if Fil = '' then
      begin
         Fil := fTempPath('M')+'UPLOAD.MSG';
         if not xferReceive(Fil,[protActive]) then Exit;
      end;
   end else if not xferReceive(Fil,[protActive]) then Exit;
   maImportMessage := maLoadTextFile(Fil,M);
   if not LocalIO then fDeleteFile(Fil);
end;

function maDownloadMessage(N : Word) : Boolean;
var Fil : String; X : Word; Send : Boolean; Head : tMsgHeaderRec; Txt : ^tMessage;
begin
   maDownloadMessage := False;
   New(Txt);
   if not maLoadMessage(Txt^,Head,N) then Exit;
   Send := True;
   Fil := fTempPath('M')+'DOWNLOAD.MSG';
   fDeleteFile(Fil);
   if acsOk(Cfg^.acsSysOp) then
   begin
      oCWrite('|U5-- |U4Enter filename to export message to|U2 [|U3Enter|U2/|U1Download|U2]|U5: |U6');
      Fil := iReadString('',inUpper,chDirectory,'',65);
      if Fil = '' then Fil := fTempPath('M')+'DOWNLOAD.MSG' else Send := False;
   end;
   if maExportMessage(Fil,Txt^,Head) then
   begin
      if Send then maDownloadMessage := xferSend(Fil,[protActive]) else
                   maDownloadMessage := True;
      if not LocalIO then fDeleteFile(Fil);
   end;
   Dispose(Txt);
end;

procedure maEditTextfile(Fn : String);
var Head : ^tMsgHeaderRec; Txt : ^tMessage; X : Word; F : Text;
begin
   New(Txt);
   New(Head);
   FillChar(Txt^,SizeOf(Txt^),0);
   FillChar(Head^,SizeOf(Head^),0);
   X := maLoadTextfile(Fn,Txt^);
   with Head^ do
   begin
      with FromInfo do
      begin
         UserNum := User^.Number;
         Alias := User^.UserName;
         RealName := User^.RealName;
         Name := User^.UserName;
         UserNote := User^.UserNote;
      end;
      with ToInfo do
      begin
         UserNum := 0;
         Alias := 'n/a';
         RealName := 'n/a';
         Name := 'n/a';
         UserNote := 'None';
      end;
      Size := X;
      Replies := 0;
      Date := dtDateTimePacked;
      Subject := #10'Text Editor ('+UpStr(Fn)+')';
      sigPos := 0;
   end;
   if fsEdit(Txt^,Head^,False,nil,nil,False,False) then
   begin
      Assign(F,Fn);
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult = 0 then
      begin
         for X := 1 to Head^.Size do WriteLn(F,Txt^[X]);
         Close(F);
      end else oWriteLn('Error saving file.');
   end;
   Dispose(Head);
   Dispose(Txt);
end;

procedure maFindAreaWithAccess;
var old, N : Word; F : file of tMsgAreaRec; Found : Boolean;
begin
   maLoad;
   if maHasAccess then Exit;
   old := User^.curMsgArea;
   Assign(F,Cfg^.pathData+fileMsgArea);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   N := 0;
   Found := False;
   while (not Found) and (not Eof(F)) do
   begin
      Read(F,mArea^);
      Inc(N);
      Found := maHasAccess;
   end;
   Close(F);
   if Found then User^.curMsgArea := N else User^.curMsgArea := old;
   maLoad;
end;

procedure maSelectAreas;
begin
end;

end.