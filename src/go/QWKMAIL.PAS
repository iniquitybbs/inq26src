{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit QwkMail;

interface

procedure qwkDownload;
procedure qwkUpload;

implementation

uses Dos,
     Global, Files, Logs, Output, Input, Misc, Strings, DateTime, MsgArea,
     ShowFile, Archive, Transfer, Users, Stats, History;

type
   tQwkIndexRec = record
      ptrMsg  : LongInt;
      numConf : Byte;
   end;

   tQwkMsgRec = record
      Status      : Char;
      msgNum      : array[1.. 7] of Char;
      Date        : array[1.. 8] of Char;
      Time        : array[1.. 5] of Char;
      toName      : array[1..25] of Char;
      fromName    : array[1..25] of Char;
      Subject     : array[1..25] of Char;
      Password    : array[1..12] of Char;
      msgRef      : array[1.. 8] of Char;
      numBlocks   : array[1.. 6] of Char;
      Flag        : Char;
      numConf     : Word;
      lMnr        : Word;
      Tag         : Char;
   end;

function qwkBasicReal2Long(InValue: LongInt): LongInt;

  Var
  Temp: LongInt;
  Negative: Boolean;
  Expon: Integer;

  Begin
    If InValue And $00800000 <> 0 Then
      Negative := True
    Else
      Negative := False;
    Expon := InValue shr 24;
    Expon := Expon and $ff;
    Temp := InValue and $007FFFFF;
    Temp := Temp or $00800000;
    Expon := Expon - 152;
    If Expon < 0 Then Temp := Temp shr Abs(Expon)
      Else Temp := Temp shl Expon;
    If Negative Then
      qwkBasicReal2Long := -Temp
    Else
      qwkBasicReal2Long := Temp;
    If Expon = 0 Then
      qwkBasicReal2Long := 0;
  End;


function qwkLong2BasicReal(InValue: LongInt): LongInt;
  Var
  Negative: Boolean;
  Expon: LongInt;

  Begin
  If InValue = 0 Then
    qwkLong2BasicReal := 0
  Else
    Begin
    If InValue < 0 Then
      Begin
      Negative := True;
      InValue := Abs(InValue);
      End
    Else
      Negative := False;
    Expon := 152;
    If InValue < $007FFFFF Then
      While ((InValue and $00800000) = 0) Do
        Begin
        InValue := InValue shl 1;
        Dec(Expon);
        End
    Else
      While ((InValue And $FF000000) <> 0) Do
        Begin
        InValue := InValue shr 1;
        Inc(Expon);
        End;
    InValue := InValue And $007FFFFF;
    If Negative Then
      InValue := InValue Or $00800000;
    qwkLong2BasicReal := InValue + (Expon shl 24);
    End;
  End;

procedure qwkDownload;
var fileCtr  : Text; tp, S : String; All, Ans : Boolean;
    fileArea : file of tMsgAreaRec; oldA, cMsg, hiMsg, ttlM, numB : Word; recNum : LongInt;
    fileNdx  : file of tQwkIndexRec; Ndx : tQwkIndexRec; Ms : Byte;
    fileMsg  : file; ctrNdx : array[1..maxMsgArea] of record N : Byte; D : String[16]; end;
    Head : tMsgHeaderRec; Txt : ^tMessage;
    Qwk : tQwkMsgRec;  ownMsg : Boolean;
    qwkHead : String;

 procedure qdError(eS : String; Pos : Boolean);
 begin
    if Pos then sfGotoPos(maxPos);
    oStringLn(strQwkDLerror);
    logWrite('-QWK download error: '+S);
 end;

 procedure qdWriteMsg;
 var curP, curL, N : Word; S : Integer; msgBuf : array[1..128] of Char;
  procedure qdWriteChar(Ch : Char);
  begin
     Inc(curP);
     if curP > 128 then
     begin
        Inc(numB);
        curP := 1;
        BlockWrite(fileMsg,msgBuf,1);
        Inc(recNum);
        FillChar(msgBuf,SizeOf(msgBuf),#32);
     end;
     msgBuf[curP] := Ch;
  end;
 begin
     curP := 0;
     numB := 1;
     FillChar(msgBuf,SizeOf(msgBuf),#32);
     S := 0;
     if Cfg^.qwkStripSigs then S := Head.sigPos-1;
     if S < 1 then S := Head.Size;
     for curL := 1 to S do
     begin
        for N := 1 to Length(Txt^[curL]) do
           if Txt^[curL,N] <> #227 then qdWriteChar(Txt^[curL,N]) else
                                        qdWriteChar(#210);
        if curL <> Head.Size then qdWriteChar(#227);
     end;
     if curP > 1 then
     begin
        Inc(numB);
        BlockWrite(fileMsg,msgBuf,1);
        Inc(recNum);
     end;
 end;
 procedure qdSimMsg;
 var curP, curL, N : Word; S : Integer; msgBuf : array[1..128] of Char;
  procedure qdWriteChar(Ch : Char);
  begin
     Inc(curP);
     if curP > 128 then
     begin
        Inc(numB);
        curP := 1;
     end;
  end;
 begin
     curP := 0;
     numB := 1;
     S := 0;
     if Cfg^.qwkStripSigs then S := Head.sigPos-1;
     if S < 1 then S := Head.Size;
     for curL := 1 to S do
     begin
        for N := 1 to Length(Txt^[curL]) do qdWriteChar(':');
        if curL <> Head.Size then qdWriteChar(#227);
     end;
     if curP > 1 then Inc(numB);
 end;

 procedure qdUpdatePtrs;
 var D : String; Dt : Dos.DateTime; L : LongInt; ca, ma, fs, ls : Word;
 begin
    GetTime(Dt.Hour,Dt.Min,Dt.Sec,ca);
    GetDate(Dt.Year,Dt.Month,Dt.Day,ca);
    PackTime(Dt,L);
    mandMsg := All;
    for ca := 1 to numMsgArea do
    begin
       User^.curMsgArea := ca;
       maLoad;
       if maHasAccess then
       begin
          maLoadScan(Scan^,User^.Number);
          Scan^.ptrMsg := L;
          maSaveScan(Scan^,User^.Number);
       end;
    end;
    mandMsg := False;
 end;

begin
   qwkHead := 'Produced by Qmail...'+
              'Copyright (c) 1987 by Sparkware.  All Rights Reserved';
   oldA := User^.curMsgArea;
   if numMsgArea < 1 then Exit;
   tp := fTempPath('Q');
   fClearDir(tp);
   logWrite('Downloaded offline mail [QWK] packet');
   Assign(fileArea,Cfg^.pathData+fileMsgArea);
   {$I-}
   Reset(fileArea);
   {$I+}
   if ioResult <> 0 then Exit;
   Assign(fileCtr,tp+'CONTROL.DAT');
   {$I-}
   Rewrite(fileCtr);
   {$I+}
   if ioResult <> 0 then
   begin
      qdError('Couldn''t create QWK control file "'+tp+'CONTROL.DAT"',False);
      Close(fileArea);
      Exit;
   end;
   oString(strQwkDLaskCurConf);
   All := not iYesNo(True);
   oString(strQwkDLownMsgs);
   ownMsg := iYesNo(False);
   oDnLn(1);
   Ans := sfShowTextFile(txQwkDL,ftQwkDL);
   if Ans then sfLight(1) else oStr('|U2-- |U1Creating control file|U2.');
   WriteLn(fileCtr,Cfg^.bbsName);
   WriteLn(fileCtr,Cfg^.bbsLocation);
   S := strReplace(Cfg^.bbsPhone,'(','');
   S := strReplace(S,')','-');
   WriteLn(fileCtr,S);
   WriteLn(fileCtr,Cfg^.SysOpName+', SysOp');
   WriteLn(fileCtr,'0241,'+Cfg^.qwkFilename);
   S := strReplace(dtDateString,'/','-');
   Insert('19',S,7);
   S := S+','+dtTimeStr24;
   WriteLn(fileCtr,S);
   WriteLn(fileCtr,UpStr(User^.Username));
   WriteLn(fileCtr,'');
   WriteLn(fileCtr,'0');
   WriteLn(fileCtr,'0');

   FillChar(ctrNdx,SizeOf(ctrNdx),0);

   ttlM := 0;

   mandMsg := All;
   User^.curMsgArea := 0;
   while not Eof(fileArea) do
   begin
      Read(fileArea,mArea^);
      Inc(User^.curMsgArea);
      if maHasAccess then
      begin
         Inc(ttlM);
         ctrNdx[ttlM].N := User^.curMsgArea;
         ctrNdx[ttlM].D := mArea^.qwkName;
      end;
   end;
   if ttlM = 0 then ttlM := 1;
   mandMsg := False;
   Close(fileArea);

   WriteLn(fileCtr,ttlM-1);

   for numB := 1 to ttlM do
   begin
      WriteLn(fileCtr,ctrNdx[numB].N);
      WriteLn(fileCtr,ctrNdx[numB].D);
   end;

   WriteLn(fileCtr,Cfg^.qwkWelcome);
   WriteLn(fileCtr,Cfg^.qwkNews);
   WriteLn(fileCtr,Cfg^.qwkGoodbye);
   Close(fileCtr);
   if Ans then
   begin
      sfOkLight(1);
      sfLight(2);
   end else
   begin
      oDnLn(1);
      oStr('|U2-- |U1Creating door identification file|U2.');
   end;
   Assign(fileCtr,tp+'DOOR.ID');
   {$I-}
   Rewrite(fileCtr);
   {$I+}
   if ioResult <> 0 then
   begin
      qdError('Couldn''t create QWK door ID file "'+tp+'DOOR.ID"',True);
      Close(fileArea);
      Exit;
   end;
   WriteLn(fileCtr,'DOOR = iNiQwk');
   WriteLn(fileCtr,'VERSION = '+Copy(bbsVersion,1,1)+'.00');
   WriteLn(fileCtr,'SYSTEM = '+bbsTitle+' v'+bbsVersion);
   WriteLn(fileCtr,'CONTROLNAME = INIQWK');
   WriteLn(fileCtr,'CONTROLTYPE = ADD');
   WriteLn(fileCtr,'CONTROLTYPE = DROP');
   Close(fileCtr);
   if Ans then
   begin
      sfOkLight(2);
      sfLight(3);
   end else
   begin
      oDnLn(1);
      oStr('|U2-- |U1Exporting QWK, please wait|U2.');
   end;
   Ms := 0;
   Reset(fileArea);
   User^.curMsgArea := 0;
   recNum := 1;
   Assign(fileMsg,tp+'MESSAGES.DAT');
   {$I-}
   Rewrite(fileMsg,128);
   {$I+}
   if ioResult <> 0 then
   begin
      User^.curMsgArea := oldA;
      maLoad;
      qdError('Couldn''t create main message file: '+tp+'MESSAGES.DAT',True);
      Exit;
   end;
   Fillchar(qwk,SizeOf(qwk),#32);
   Move(qwkHead[1],qwk,Length(qwkHead));
   Blockwrite(fileMsg,qwk,1);
   Inc(recNum);

   mandMsg := All;
   ttlM := 0;
   New(Txt);
   while not Eof(fileArea) do
   begin
      Read(fileArea,mArea^);
      Inc(User^.curMsgArea);
      if maHasAccess then
      begin
         maLoadScan(Scan^,User^.Number);
         hiMsg := maNewScanMsgNum;
         if sfGotoPos(6) then oStr(strEnlarge(mArea^.Name,Ms));
         Ms := Length(NoColor(mArea^.Name));
         if sfGotoPos(10) then oStrCtr(Resize(b2st(mArea^.areaType = mareaEchoMail),3));
         if sfGotoPos(7) then oStrCtr(Resize(St(mArea^.Msgs),5));
         if (hiMsg = 0) and (sfGotoPos(8)) then
            oStrCtr(Resize('0',5));
      end;
      if (hiMsg > 0) and (maHasAccess) then
      begin
         if sfGotoPos(8) then oStrCtr(Resize(St(mArea^.Msgs-hiMsg+1),5));
         if sfGotoPos(9) then oStrCtr(St((FileSize(fileMsg)*128) div 1024)+'k');
         S := St(User^.curMsgArea);
         while Length(S) < 3 do Insert('0',S,1);
         FillChar(Ndx,SizeOf(Ndx),0);
         Assign(fileNdx,tp+S+'.NDX');
         {$I-}
         Rewrite(fileNdx);
         {$I+}
         if ioResult <> 0 then
         begin
            Close(fileArea);
            User^.curMsgArea := oldA;
            maLoad;
            qdError('Couldn''t create QWK index file: '+tp+S+'.NDX',True);
            mandMsg := False;
            Exit;
         end;
         for cMsg := hiMsg to mArea^.Msgs do
            if (maLoadMessage(Txt^,Head,cMsg)) and (maOkToRead(Head))
               and ((not ownMsg) or (Head.FromInfo.RealName <> User^.RealName)) then
         begin
            Ndx.ptrMsg := qwkLong2BasicReal(recNum);
            Ndx.numConf := User^.curMsgArea;
            Inc(ttlM);
            if sfGotoPos(11) then oStrCtr(St(ttlM));
            Write(fileNdx,Ndx);

            FillChar(Qwk,SizeOf(Qwk),#32);
            if msgPrivate in Head.Status then Qwk.Status := '*' else
                                              Qwk.Status := '-';
            S := St(cMsg);
            Move(S[1],qwk.msgNum,Length(S));
            S := strReplace(dtDatePackedString(Head.Date),'/','-');
            Move(S[1],qwk.Date,Length(S));
            S := dtTimePackedStr24(Head.Date);
            if S[1] <> '0' then Insert('0',S,1);
            Move(S[1],qwk.Time,Length(S));
            S := UpStr(Head.ToInfo.Name);
            Move(S[1],qwk.toName,Length(S));
            S := UpStr(Head.FromInfo.Name);
            Move(S[1],qwk.fromName,Length(S));
            S := Head.Subject;
            Move(S[1],qwk.Subject,Length(S));
            { Pw }
            S := '0';
            Move(S[1],qwk.msgRef,1);
            qdSimMsg;
            S := St(numB);
            Move(S[1],qwk.numBlocks,Length(S));
            qwk.Flag := 'a';
            qwk.numConf := User^.curMsgArea;
            qwk.lMnr := Head.Size;
            BlockWrite(fileMsg,qwk,1);
            Inc(recNum);
            qdWriteMsg;
         end;
         Close(fileNdx);
      end;
   end;
   Dispose(Txt);
   mandMsg := False;
   if sfGotoPos(9) then oStrCtr(St((FileSize(fileMsg)*128) div 1024)+'k');
   if Ans then
   begin
      sfOkLight(3);
      sfLight(4);
   end else
   begin
      oDnLn(1);
      oStr('|U2-- |U1Including text/infomation files|U2.');
   end;
   Close(fileMsg);
   Close(fileArea);
   fCopyFile(Cfg^.pathText+Cfg^.qwkWelcome,tp+Cfg^.qwkWelcome);
   fCopyFile(Cfg^.pathText+Cfg^.qwkNews,tp+Cfg^.qwkNews);
   fCopyFile(Cfg^.pathText+Cfg^.qwkGoodbye,tp+Cfg^.qwkGoodbye);
   if Ans then
   begin
      sfOkLight(4);
      sfLight(5);
   end else
   begin
      oDnLn(1);
      oStr('|U2-- |U1Compressing QWK mail packet|U2.');
   end;
   if ttlM > 0 then
   begin
      if (not archZip(tp+Cfg^.qwkFilename+'.QWK',tp+'*.*',1)) or
         (not fExists(tp+Cfg^.qwkFilename+'.QWK')) then
      begin
         User^.curMsgArea := oldA;
         maLoad;
         qdError('Couldn''t archive QWK packet',True);
         Exit;
      end;
   end;
   if Ans then sfOkLight(5) else oDnLn(1);
   sfGotoPos(maxPos);
   Ans := False;
   if ttlM = 0 then oStringLn(strQwkDLnoNewMsgs) else
   begin
      oStr(strCode(mStr(strQwkDLaskDownload),1,Stc(fFileSize(tp+Cfg^.qwkFilename+'.QWK'))));
      if iYesNo(True) then
      begin
         if (not HangUp) and (LocalIO) then
         begin
            fMoveFile(tp+Cfg^.qwkFilename+'.QWK',Cfg^.qwkLocalPath+Cfg^.qwkFilename+'.QWK');
            Ans := True;
         end else
         if xferSend(tp+Cfg^.qwkFilename+'.QWK',[protActive]) then Ans := True else
            qdError('QWK download error',False);
      end;
   end;
   if Ans then
   begin
      oString(strQwkDLaskUpdatePtrs);
      if iYesNo(True) then
      begin
         oString(strQwkDLupdatingPtrs);
         qdUpdatePtrs;
         oDnLn(1);
      end;
   end;
   fClearDir(tp);
   User^.curMsgArea := oldA;
   maLoad;
end;

procedure qwkUpload;
var tp, tw, S : String; All, Ans : Boolean;
    ttlM, oldA, newA, numB, curB, ms, ss, fs, ts, curP : Word; fileMsg  : file; Head : tMsgHeaderRec; Txt : ^tMessage;
    Qwk : tQwkMsgRec; U : tUserRec; Buf : array[1..128] of Char;
    qwkT : LongInt;

 procedure quError(eS : String; Pos : Boolean);
 begin
    if Pos then sfGotoPos(maxPos);
    oStringLn(strQwkULerror);
    logWrite('-REP upload error: '+S);
 end;

 function quDateTime : LongInt;
 var Y,M,D,Dw, H,Mn,S,So : Word; Dt : Dos.DateTime; L : LongInt;
 begin
    Dt.Year := 1900+strToInt(Copy(qwk.Date,7,2));
    Dt.Month := strToInt(Copy(qwk.Date,1,2));
    Dt.Day := strToInt(Copy(qwk.Date,4,2));
    Dt.Hour := strToInt(Copy(qwk.Time,1,2));
    Dt.Min := strToInt(Copy(qwk.Time,4,2));
    Dt.Sec := 0;

    PackTime(Dt,L);

    quDateTime := L;
 end;

begin
   oldA := User^.curMsgArea;
   if numMsgArea < 1 then Exit;
   tp := fTempPath('Q');
   fClearDir(tp);
   logWrite('Uploaded offline mail [REP] packet');
   S := '';
   if acsOk(Cfg^.acsSysOp) then
   begin
      oCWrite('|U5-- |U4Enter REP filename to process|U2 [|U3Enter|U2/|U1Upload|U2]|U5: |U6');
      S := iReadString('',inUpper,chDirectory,'',65);
   end;
   if S <> '' then
   begin
      if not fCopyFile(S,tp+Cfg^.qwkFilename+'.REP') then Exit;
   end else
      if not xferReceive(tp+Cfg^.qwkFilename+'.REP',[protActive]) then Exit;

   fCreateDir(tp,False);

   oDnLn(1);
   Ans := sfShowTextFile(txQwkUL,ftQwkUL);
   if Ans then sfLight(1) else oStr('|U2-- |U1Unarchiving REP packet|U2.');
   tw := fTempPath('A');
   fClearDir(tw);
   if not archUnzip(tp+Cfg^.qwkFilename+'.REP','*.*',tw) then
   begin
      quError('Couldn''t unarchive REP packet',True);
      Exit;
   end;

   if Ans then
   begin
      sfOkLight(1);
      sfLight(2);
   end else
   begin
      oDnLn(1);
      oStrCtr('|U2-- |U1Importing replies, please wait|U2.');
   end;

   fFindFile(tw+'*.MSG');
   if not fileFound then
   begin
      quError('No message data file found in REP packet',True);
      Exit;
   end;
   Assign(fileMsg,tw+Search.Name);
   {$I-}
   Reset(fileMsg,128);
   {$I+}
   if ioResult <> 0 then
   begin
      quError('Couldn''t open reply data file',True);
      Exit;
   end;
   getFtime(fileMsg,qwkT);
   if qwkT = User^.lastQwkDate then
   begin
      sfGotoPos(maxPos);
      oStringLn(strQwkULalready);
      logWrite('REP upload aborted; already uploaded');
      Close(fileMsg);
      Exit;
   end;

   if SizeOf(fileMsg) < 2 then
   begin
      Close(fileMsg);
      quError('REP packet contains no replies',True);
      Exit;
   end;

   maLoad;

   BlockRead(fileMsg,Qwk,1);  { read the header }
   New(Txt);

   ms := 0;
   fs := 0;
   ts := 0;
   ss := 0;
   ttlM := 0;

   while not Eof(fileMsg) do
   begin
      BlockRead(fileMsg,Qwk,1);
      FillChar(Head,SizeOf(Head),0);
      with Head do
      begin
         with FromInfo do
         begin
            UserNum := User^.Number;
            Alias := User^.UserName;
            RealName := User^.RealName;
            Name := User^.UserName;
            UserNote := User^.UserNote;
         end;
         U.Username := CleanUp(qwk.toName);
         if (userSearch(U,True)) and (userLoad(U)) then with ToInfo do
         begin
            UserNum := U.Number;
            Alias := U.UserName;
            RealName := U.RealName;
            Name := U.UserName;
            UserNote := U.UserNote;
         end else with ToInfo do
         begin
            UserNum := 0;
            Alias := strMixed(CleanUp(qwk.toName));
            RealName := 'Unknown';
            Name := Alias;
            UserNote := 'Unknown';
         end;
         Date := dtDateTimePacked; {quDateTime;}
         if Qwk.Status in ['*','+'] then Status := Status+[msgPrivate];
         if CleanUp(Qwk.msgNum) = '' then newA := 0 else newA := strToInt(Qwk.msgNum);
         if newA = 0 then newA := Qwk.numConf;
         Pos := 0;
         Replies := 0;
         Subject := CleanUp(qwk.Subject);
         NetFlag := [];
         SigPos := 0;
         incFile := 0;
         Size := 1;
         numB := strToInt(qwk.numBlocks);
         FillChar(Txt^,SizeOf(Txt^),0);
         for curB := 2 to numB do
         begin
            BlockRead(fileMsg,Buf,1);
            for curP := 1 to 128 do if Buf[curP] = #227 then Inc(Size) else
               if Buf[curP] <> #0 then Txt^[Size] := Txt^[Size]+Buf[curP];
         end;
         for curP := 1 to Size do Txt^[curP] := strSquish(CleanUp(Txt^[curP]),79);
         while (Size > 1) and (Txt^[Size] = '') do Dec(Size);
         Inc(Size);
         Txt^[Size] := '';
         for curP := Size downto 1 do
             if (SigPos = 0) and (System.Pos('--',Copy(Txt^[curP],1,4)) > 0) then  sigPos := curP;
      end;
      if (ttlM = 0) or (newA <> User^.curMsgArea) then
      begin
         User^.curMsgArea := newA;
         maLoad;
         if sfGotoPos(4) then oStr(strEnlarge(mArea^.Name,Ms));
         Ms := Length(NoColor(mArea^.Name));
      end;

      if not (maPrivate in mArea^.Flag) then Head.Status := Head.Status-[msgPrivate];

      Inc(ttlM);
      if sfGotoPos(5) then oStrCtr(St(ttlM));
      if sfGotoPos(6) then oStrCtr(strEnlarge(Head.FromInfo.Name,fs));
      fs := Length(NoColor(Head.FromInfo.Name));
      if sfGotoPos(7) then oStrCtr(strEnlarge(Head.ToInfo.Name,ts));
      ts := Length(NoColor(Head.ToInfo.Name));
      if sfGotoPos(8) then oStrCtr(strEnlarge(Head.Subject,ss));
      ss := Length(NoColor(Head.Subject));

      if (acsOk(mArea^.postAcs)) and (maHasAccess) and (maAddMessage(Txt^,Head,True)) then
      begin
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
      end;
   end;

   if Ans then
   begin
      sfOkLight(2);
      sfLight(3);
   end else
   begin
      oDnLn(1);
      oStrCtrLn('|U2-- |U1Replies imported ('+St(ttlM)+')|U2.');
   end;

   Dispose(Txt);

   Close(fileMsg);

   User^.LastQwkDate := qwkT;
   statSave;
   hisSave;
   userSave(User^);

   fClearDir(tp);
   User^.curMsgArea := oldA;
   maLoad;
   if Ans then
   begin
      sfOkLight(3);
      sfGotoPos(maxPos);
   end;
end;

end.