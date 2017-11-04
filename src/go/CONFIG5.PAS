{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config5;

interface

procedure cfgMsgAreaEditor;

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, bbsInit,
     MsgArea, Logs;

var maF : file of tMsgAreaRec;

procedure cfgInsertMsgArea;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   if numMsgArea >= maxMsgArea then
   begin
      oCWriteLn('|U0You may only have a maximum of '+St(maxMsgArea)+' message areas.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Insert before which message area? |U5[|U61|U5-|U6'+St(numMsgArea+1)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numMsgArea+1) or (I < 1) then Exit;

   oCWrite('|U1Number of areas to insert |U5[|U61|U5-|U6'+St(maxMsgArea-numMsgArea)+'|U5]: |U3');
   X := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (X > maxMsgArea-numMsgArea) or (X < 1) then X := 1;

   Dec(I);

   Reset(maF);
   for b := 1 to x do
   begin
      for Z := FileSize(maF)-1 downto I do
      begin
         Seek(maF,Z);
         Read(maF,mArea^);
         Write(maF,mArea^);
      end;
      maReset;
      Seek(maF,I);
      Write(maF,mArea^);
   end;
   numMsgArea := FileSize(maF);
   Close(maF);
   maUpdateScanFile;
end;

procedure cfgMoveMsgArea;
var K,X,Y,I,B : Word; J : Integer;
    mTemp : ^tMsgAreaRec;
begin
   oDnLn(2);
   if numMsgArea <= 1 then
   begin
      oCWriteLn('|U0There is only one message area, no need to move it.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Move which message area? |U5[|U61|U5-|U6'+St(numMsgArea)+'|U5]: |U3');
   X := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (X > numMsgArea) or (X < 1) then Exit;

   oCWrite('|U1Move before which message area? |U5[|U61|U5-|U6'+St(numMsgArea+1)+'|U5]: |U3');
   Y := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (Y > numMsgArea+1) or (Y < 1) then Exit;

   Dec(I,1);

   New(mTemp);
   Reset(maF);

   K := Y;
   if (Y > X) then Dec(Y);
   Dec(X);
   Dec(Y);
   Seek(maF,X);
   Read(maF,mTemp^);
   I := X;
   if (X > Y) then J := -1 else J := 1;
   while (I <> Y) do
   begin
      if (I+J < FileSize(maF)) then
      begin
         Seek(maF,I+J);
         Read(maF,mArea^);
         Seek(maF,I);
         Write(maF,mArea^);
      end;
      Inc(I,J);
   end;
   Seek(maF,Y);
   Write(maF,mTemp^);
   Inc(X);
   Inc(Y);
   {y:=k;}
   Close(maF);
   Dispose(mTemp);
{
   if ((I >= 0) and (I <= FileSize(maF))) and (numMsgArea < maxMsgArea) then
   begin
      for Z := FileSize(maF)-1 downto I do
      begin
         Seek(maF,Z);
         Read(maF,mArea^);
         Write(maF,mArea^);
      end;
      maReset;
      Seek(maF,I);
      Write(maF,mArea^);
      Inc(numMsgArea,1);
   end;}
   maUpdateScanFile;
end;

procedure cfgDeleteMsgArea;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   if numMsgArea <= 1 then
   begin
      oCWriteLn('|U0You must have at least one message area!');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Delete which message area? |U5[|U61|U5-|U6'+St(numMsgArea)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numMsgArea) or (I < 1) then Exit;

   Dec(I);

   Reset(maF);
   if (I >= 0) and (I <= FileSize(maF)-2) then
   for Z := I to FileSize(maF)-2 do
   begin
      Seek(maF,Z+1);
      Read(maF,mArea^);
      Seek(maF,Z);
      Write(maF,mArea^);
   end;
   Seek(maF,FileSize(maF)-1);
   Truncate(maF);
   Dec(numMsgArea,1);
   Close(maF);
   if (fExists(Cfg^.pathMsgs+mArea^.Filename+extMsgData)) or
      (fExists(Cfg^.pathMsgs+mArea^.Filename+extMsgHead)) or
      (fExists(Cfg^.pathMsgs+mArea^.Filename+extMsgScan)) then
   begin
      oCWrite('|U1Delete this message area''s data files? ');
      if iYesNo(False) then
      begin
         fDeleteFile(Cfg^.pathMsgs+mArea^.Filename+extMsgData);
         fDeleteFile(Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
         fDeleteFile(Cfg^.pathMsgs+mArea^.Filename+extMsgScan);
      end;
   end;
end;

procedure cfgEditMsgArea;
var optAreaType : array[1..2] of String;
    An, Anum, T : Byte; B : Boolean; Fil : String; optNet : array[1..maxAddress] of String;
begin
   optAreaType[1] := 'Local message area';
   optAreaType[2] := 'EchoMail area';
   Anum := User^.curMsgArea;
   oDnLn(2);
   for T := 1 to maxAddress do optNet[T] := '#'+St(T)+' ('+St(Cfg^.Address[T].Zone)+
        ':'+St(Cfg^.Address[T].Net)+'/'+St(Cfg^.Address[T].Node)+'.'+St(Cfg^.Address[T].Point)+')';
   if numMsgArea = 0 then
   begin
      oCWriteLn('|U0Can''t continue.  No message areas exist');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Begin edit with which message area? |U5[|U61|U5-|U6'+St(numMsgArea)+'|U5]: |U3');
   An := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (An > numMsgArea) or (An < 1) then Exit;
   User^.curMsgArea := An;
   maLoad;

   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' Message Area Editor');
      cfgCol := 20;
      cfgItem('--Current area',10,St(An)+' of '+St(numMsgArea),'');
      cfgItem('A Description',40,mArea^.Name,
              'This message area''s description (shown in message area lists, etc).');
      cfgItem('B Filename',8,mArea^.Filename,
              'This is the file that the actual messages for this area will be stored in.');
      cfgItem('C Msg area type',20,cfgOption(optAreaType,mArea^.areaType),
              'Type of message area.');
      if mArea^.areaType = mareaEchoMail then
      cfgItem('D Echomail path',40,mArea^.MsgPath,
              'Directory which incoming/outgoing echomail will be stored in, until processed.');
      if mArea^.areaType = mareaEchoMail then
      cfgItem('E Origin line #',58,Resize(St(mArea^.Origin)+' ('+Cfg^.Origin[mArea^.Origin],40)+'...)',
              'Which origin line (defined in system configuration) to append to messages.');
      if mArea^.areaType = mareaEchoMail then
      cfgItem('F Net address',20,cfgOption(optNet,mArea^.Address),
              'Network address this area uses.');
      cfgItem('G Area sponsor',36,mArea^.Sponsor,
              'Creator or manager of this message area (Usually the SysOp).');
      cfgItem('H Access ACS',20,mArea^.ACS,
              'ACS required to access or read messages in this area.');
      cfgItem('I Post ACS',20,mArea^.PostACS,
              'ACS required to post messages in this area.');
      cfgItem('J Max messages',4,St(mArea^.MaxMsgs),
              'Maximum messages this area can contain before being packed (0 = unlimited).');
      cfgItem('K Password',20,mArea^.Password,
              'Password required to access or read messages in this message Area.');
      cfgItem('L QWK name',16,mArea^.qwkName,
              'Shortened message area name (max 16 characters) for QWK indexing');
      cfgItem('M Messages',5,st(mArea^.Msgs),
              'Number of messages currently in area (do not change unless necessary)');
      cfgItem('1 Unhidden',3,B2St(maUnhidden in mArea^.Flag),
              'Display this area under any circumstances?');
      cfgItem('2 Real Names',3,B2St(maRealName in mArea^.Flag),
              'Force use of user''s REAL name when posting in this area?');
      cfgItem('3 Private',3,B2St(maPrivate in mArea^.Flag),
              'Allow private messages to be posted in this area?');
      cfgSrt := 40;
      cfgCol := 60;
      Dec(cfgLn,2);
      cfgItem('4 Mandatory',3,B2St(maMandatory in mArea^.Flag),
              'Force user to read all new messages in this area?');
      cfgItem('5 Anonymous',3,B2St(maAnonymous in mArea^.Flag),
              'Allow anonymous messages to be posted in this area?');
      cfgSrt := 1;
      cfgCol := 20;
      if cfgDraw then Dec(cfgbot,2);
      cfgItem('[ Previous Area',0,'','');
      cfgItem('] Next Area',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(mArea^.Name,inNormal,chNormal,'',False);
                 mArea^.Name := cfgRead;
                 cfgSetItem(mArea^.Name);
              end;
        'B' : begin
                 Fil := mArea^.Filename;
                 cfgReadInfo(mArea^.Filename,inUpper,chFileNoExt,'',True);
                 mArea^.Filename := cfgRead;
                 cfgSetItem(mArea^.Filename);
                 fRenameFile(Cfg^.pathMsgs+Fil+extMsgData,Cfg^.pathMsgs+mArea^.Filename+extMsgData);
                 fRenameFile(Cfg^.pathMsgs+Fil+extMsgHead,Cfg^.pathMsgs+mArea^.Filename+extMsgHead);
                 fRenameFile(Cfg^.pathMsgs+Fil+extMsgScan,Cfg^.pathMsgs+mArea^.Filename+extMsgScan);
                 if UpStr(mArea^.qwkName) = Fil then
                 begin
                    mArea^.qwkName := strMixed(mArea^.Filename);
                    cfgDraw := True;
                    cfgOver := True;
                 end;
              end;
        'C' : begin
                 T := mArea^.areaType;
                 cfgReadOption(optAreaType,2,mArea^.areaType);
                 cfgSetItem(cfgOption(optAreaType,mArea^.areaType));
                 cfgDraw := T <> mArea^.areaType;
              end;
        'D' : begin
                 cfgReadInfo(mArea^.MsgPath,inUpper,chDirectory,'',True);
                 mArea^.MsgPath := cfgRead;
                 if mArea^.MsgPath[Length(mArea^.MsgPath)] <> '\' then
                    mArea^.MsgPath := mArea^.MsgPath+'\';
                 cfgSetItem(mArea^.MsgPath);
                 cfgAskCreate(mArea^.MsgPath);
              end;
        'E' : begin
                 cfgSetItem('');
                 cfgReadInfo(St(mArea^.Origin),inUpper,chNumeric,'',True);
                 mArea^.Origin := mClip(StrToInt(cfgRead),1,maxOrigin);
                 cfgSetItem(Resize(St(mArea^.Origin)+' ('+Cfg^.Origin[mArea^.Origin],40)+'...)');
              end;
        'F' : begin
                 cfgReadOption(optNet,maxAddress,mArea^.Address);
                 cfgSetItem(cfgOption(optNet,mArea^.Address));
              end;
        'G' : begin
                 cfgReadInfo(mArea^.Sponsor,inNormal,chNormal,'',False);
                 mArea^.Sponsor := cfgRead;
                 cfgSetItem(mArea^.Sponsor);
              end;
        'H' : begin
                 cfgReadInfo(mArea^.ACS,inLower,chNormal,'',False);
                 mArea^.ACS := cfgRead;
                 cfgSetItem(mArea^.ACS);
              end;
        'I' : begin
                 cfgReadInfo(mArea^.PostACS,inLower,chNormal,'',False);
                 mArea^.PostACS := cfgRead;
                 cfgSetItem(mArea^.PostACS);
              end;
        'J' : begin
                 cfgReadInfo(St(mArea^.MaxMsgs),inUpper,chNumeric,'',True);
                 mArea^.MaxMsgs := mClip(StrToInt(cfgRead),0,9999);
                 cfgSetItem(St(mArea^.MaxMsgs));
              end;
        'K' : begin
                 cfgReadInfo(mArea^.Password,inUpper,chNormal,'',False);
                 mArea^.Password := cfgRead;
                 cfgSetItem(mArea^.Password);
              end;
        'L' : begin
                 cfgReadInfo(mArea^.qwkName,inNormal,chNormal,'',False);
                 mArea^.qwkName := cfgRead;
                 cfgSetItem(mArea^.qwkName);
              end;
        'M' : begin
                 cfgReadInfo(St(mArea^.Msgs),inUpper,chNumeric,'',True);
                 mArea^.Msgs := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(mArea^.Msgs));
              end;
        '1' : begin
                 B := maUnhidden in mArea^.Flag;
                 cfgReadBoolean(B);
                 if not B then mArea^.Flag := mArea^.Flag - [maUnhidden] else
                               mArea^.Flag := mArea^.Flag + [maUnhidden];
                 cfgSetItem(B2St(B));
              end;
        '2' : begin
                 B := maRealName in mArea^.Flag;
                 cfgReadBoolean(B);
                 if not B then mArea^.Flag := mArea^.Flag - [maRealName] else
                               mArea^.Flag := mArea^.Flag + [maRealName];
                 cfgSetItem(B2St(B));
              end;
        '3' : begin
                 B := maPrivate in mArea^.Flag;
                 cfgReadBoolean(B);
                 if not B then mArea^.Flag := mArea^.Flag - [maPrivate] else
                               mArea^.Flag := mArea^.Flag + [maPrivate];
                 cfgSetItem(B2St(B));
              end;
        '4' : begin
                 B := maMandatory in mArea^.Flag;
                 cfgReadBoolean(B);
                 if not B then mArea^.Flag := mArea^.Flag - [maMandatory] else
                               mArea^.Flag := mArea^.Flag + [maMandatory];
                 cfgSetItem(B2St(B));
              end;
        '5' : begin
                 B := maAnonymous in mArea^.Flag;
                 cfgReadBoolean(B);
                 if not B then mArea^.Flag := mArea^.Flag - [maAnonymous] else
                               mArea^.Flag := mArea^.Flag + [maAnonymous];
                 cfgSetItem(B2St(B));
              end;
        '[' : begin
                 T := mArea^.areaType;
                 User^.curMsgArea := An;
                 maSave;
                 if An = 1 then An := numMsgArea else Dec(An,1);
                 User^.curMsgArea := An;
                 maLoad;
                 cfgDraw := T <> mArea^.areaType;
                 cfgOver := not cfgDraw;
                 if cfgOver then cfgDraw := True;
              end;
        ']' : begin
                 T := mArea^.areaType;
                 User^.curMsgArea := An;
                 maSave;
                 if An = numMsgArea then An := 1 else Inc(An,1);
                 User^.curMsgArea := An;
                 maLoad;
                 cfgDraw := T <> mArea^.areaType;
                 cfgOver := not cfgDraw;
                 if cfgOver then cfgDraw := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
   User^.curMsgArea := An;
   maSave;
   User^.curMsgArea := Anum;
   if UserOn then maLoad;
end;


procedure cfgMsgAreaEditor;
var cmdMaEdit : array[1..5] of String;
    oldArea : Word;
begin
   cmdMaEdit[1] := 'I nsert';
   cmdMaEdit[2] := 'D elete';
   cmdMaEdit[3] := 'E dit';
   cmdMaEdit[4] := 'M ove';
   cmdMaEdit[5] := 'Esc Quit';
   cfgDone := False;
   logWrite('*Message area edit.');
   oldArea := User^.curMsgArea;
   repeat
      oClrScr;
      cfgDraw := True;
      cfgOver := False;
      PausePos := 1;
      PauseAbort := False;

      oSetCol(colText);

      oWriteLn(' Num  Description                Filename  ACS    pACS   Max  Sponsor');
{                   4                         26         9      6      6    4       16}
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(2);

      numMsgArea := 0;

      Assign(maF,Cfg^.pathData+fileMsgArea);
      {$I-}
      Reset(maF);
      {$I+}
      if ioResult <> 0 then
      begin
         maReset;
         Rewrite(maF);
         Write(maF,mArea^);
         Close(maF);
         Reset(maF);
      end;
      while (not PauseAbort) and (not Eof(maF)) do
      begin
         Read(maF,mArea^);
         Inc(numMsgArea,1);
         oSetCol(colInfo);
         oCWriteLn(' '+Resize(St(numMsgArea),4)+
                   ' '+Resize(mArea^.Name,26)+
                   ' '+Resize(mArea^.Filename,9)+
                   ' '+Resize(mArea^.ACS,6)+
                   ' '+Resize(mArea^.PostACS,6)+
                   ' '+Resize(St(mArea^.MaxMsgs),4)+
                   ' '+strSquish(mArea^.Sponsor,16));
         oUpPause(1);
      end;
      numMsgArea := FileSize(maF);
      Close(maF);
      if numMsgArea = 0 then oWriteLn('No message areas currently exist.');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
      PausePos := 0;
      cfgPrompt(cmdMaEdit,5);
      repeat
         cfgKey := UpCase(iReadkey);
      until (HangUp) or (cfgKey in ['I','D','E','M',#27]);
      if cfgKey = #27 then oWrite('Quit') else oWriteChar(cfgKey);
      case cfgKey of
        'I' : cfgInsertMsgArea;
        'D' : cfgDeleteMsgArea;
        'E' : cfgEditMsgArea;
        'M' : cfgMoveMsgArea;
        #27 : cfgDone := True;
      end;
   until (HangUp) or (cfgDone);
   maUpdateAllScanFiles;
   User^.curMsgArea := oldArea;
   maLoad;
end;

end.