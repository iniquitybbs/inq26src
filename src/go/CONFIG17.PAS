{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config17;

interface

procedure cfgInfoformEditor;

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, bbsInit,
     Logs, Infoform;

var faI : file of tInfoformRec;
    inf  : tInfoformRec;

procedure cfgInsert;
var I,X,Z,B : Byte; S : String[8];
begin
   oDnLn(1);
   oCWrite('|U1Insert before which infoform|U2? |U5[|U61|U5-|U6'+St(numInfo+1)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numInfo+1) or (I < 1) then Exit;

   FillChar(inf,SizeOf(inf),0);
   with inf do
   begin
      Desc := 'New '+bbsTitle+' infoform';
      Filename := 'NEWFORM';
      Mand := False;
      Nuv := False;
   end;

   Dec(I);

   if numInfo = 0 then
   begin
      Rewrite(faI);
      Write(faI,inf);
      numInfo := 1;
   end else
   begin
      Reset(faI);
      fDeleteFile(Cfg^.pathData+fileInfoPre+z3(numInfo+1));
      if (I >= 0) and (I <= FileSize(faI)) then
      begin
         for Z := FileSize(faI)-1 downto I do
         begin
            fRenameFile(Cfg^.pathData+fileInfoPre+z3(Z+1),Cfg^.pathData+fileInfoPre+z3(Z+2));
            Seek(faI,Z);
            Read(faI,inf);
            Write(faI,inf);
         end;
         Seek(faI,I);
         FillChar(inf,SizeOf(inf),0);
         with inf do
         begin
            Desc := 'New '+bbsTitle+' infoform';
            Filename := 'NEWFORM';
            Mand := False;
            Nuv := False;
         end;
         Write(faI,inf);
         Inc(numInfo);
      end;
   end;
   Close(faI);
   ifReset(I+1);
end;

procedure cfgEdit;
var I,X,Z,B : Byte; S : String[8];
begin
   oDnLn(1);
   oCWrite('|U1Begin edit with which infoform|U2? |U5[|U61|U5-|U6'+St(numInfo)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numInfo) or (I < 1) then Exit;
   Reset(faI);
   Seek(faI,I-1);
   Read(faI,inf);

   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' Infoform Editor');
      cfgItem('--Current infoform',3,St(I),'');
      cfgItem('A Description',40,inf.Desc,
              'Brief description of this infoform');
      cfgItem('B Filename',13,inf.Filename,
              'Infoform template filename; must be in text directory');
      cfgItem('C Mandatory',3,b2St(inf.Mand),
              'Is this infoform mandatory? (force users to fill out infoform?)');
      cfgItem('D NUV infoform',3,b2St(inf.Nuv),
              'Allow users to display this infoform when voting on new users via NUV?');
      cfgItem('E Access',20,inf.Acs,
              'Restrict this infoform to users of a specific access requirement');
      cfgItem('[ Previous infoform',0,'','');
      cfgItem('] Next infoform',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(inf.Desc,inNormal,chNormal,'',False);
                 inf.Desc := cfgRead;
                 cfgSetItem(inf.Desc);
              end;
        'B' : begin
                 cfgReadInfo(inf.Filename,inUpper,chFilename,'',True);
                 inf.Filename := cfgRead;
                 cfgSetItem(inf.Filename);
              end;
        'C' : begin
                 cfgReadBoolean(inf.Mand);
                 cfgSetItem(b2St(inf.Mand));
              end;
        'D' : begin
                 cfgReadBoolean(inf.Nuv);
                 cfgSetItem(b2St(inf.Nuv));
              end;
        'E' : begin
                 cfgReadInfo(inf.Acs,inLower,chNormal,'',False);
                 inf.Acs := cfgRead;
                 cfgSetItem(inf.Acs);
              end;
        '[' : begin
                 Seek(faI,I-1);
                 Write(faI,inf);
                 if I = 1 then I := numInfo else Dec(I);
                 Seek(faI,I-1);
                 Read(faI,inf);
                 cfgDraw := True;
                 cfgOver := True;
              end;
        ']' : begin
                 Seek(faI,I-1);
                 Write(faI,inf);
                 if I = numInfo then I := 1 else Inc(I);
                 Seek(faI,I-1);
                 Read(faI,inf);
                 cfgDraw := True;
                 cfgOver := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
   Seek(faI,I-1);
   Write(faI,inf);
   Close(faI);
end;

procedure cfgDelete;
var I,X,Z,B : Byte;
begin
   oDnLn(1);
   if numInfo < 1 then
   begin
      oCWriteLn('|U0No infoforms exist.');
      oDnLn(1);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Remove which infoform|U2? |U5[|U61|U5-|U6'+St(numInfo)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numInfo) or (I < 1) then Exit;

   fDeleteFile(Cfg^.pathData+fileInfoPre+z3(I));
   Dec(I);

   Reset(faI);
   if (I >= 0) and (I <= FileSize(faI)-2) then
   for Z := I to FileSize(faI)-2 do
   begin
      fRenameFile(Cfg^.pathData+fileInfoPre+z3(Z+2),Cfg^.pathData+fileInfoPre+z3(Z+1));
      Seek(faI,Z+1);
      Read(faI,inf);
      Seek(faI,Z);
      Write(faI,inf);
   end;
   Seek(faI,FileSize(faI)-1);
   Truncate(faI);
   Dec(numInfo);
   Close(faI);
end;

procedure cfgList;
begin
   oClrScr;
   PausePos := 1;
   PauseAbort := False;
   oSetCol(colText);
   oCWriteLn(' '+Resize('Num',4)+
             ' '+Resize('Filename',14)+
             ' '+Resize('Description',30)+
             ' '+Resize('Mand',4)+
             ' '+Resize('NUV',4)+
             ' '+strSquish('Acs',15));
   oSetCol(colBorder);
   oWriteLn(sRepeat('Ä',79));
   oUpPause(2);

   numInfo := 0;

   Assign(faI,Cfg^.pathData+fileInfoform);
   {$I-}
   Reset(faI);
   {$I+}
   oSetCol(colInfo);
   if ioResult = 0 then
   begin
      while (not PauseAbort) and (not Eof(faI)) do
      begin
         Read(faI,inf);
         Inc(numInfo);
         oSetCol(colInfo);
         oCWriteLn(' '+Resize(St(numInfo),4)+
                   ' '+Resize(inf.Filename,14)+
                   ' '+Resize(inf.Desc,30)+
                   ' '+Resize(b2st(inf.Mand),4)+
                   ' '+Resize(b2st(inf.Nuv),4)+
                   ' '+strSquish(inf.Acs,15));
         oUpPause(1);
      end;
      Close(faI);
   end;
   if numInfo = 0 then oWriteLn('No infoforms are currently installed.');
   oSetCol(colBorder);
   oWriteLn(sRepeat('Ä',79));
   oUpPause(1);
   PausePos := 0;
end;

procedure cfgInfoformEditor;
var cmdInfEdit : array[1..4] of String;
begin
   cmdInfEdit[1] := 'I nsert';
   cmdInfEdit[2] := 'D elete';
   cmdInfEdit[3] := 'E dit';
   cmdInfEdit[4] := 'Esc Quit';
   cfgDone := False;
   logWrite('*Infoform edit');
   repeat
      cfgDraw := True;
      cfgOver := False;

      cfgList;

      cfgPrompt(cmdInfEdit,4);
      repeat
         cfgKey := UpCase(iReadkey);
      until (HangUp) or (cfgKey in ['I','D','E',#27]);
      if cfgKey = #27 then oWrite('Quit') else oWriteChar(cfgKey);
      oDnLn(1);
      case cfgKey of
        'I' : cfgInsert;
        'D' : cfgDelete;
        'E' : if numInfo > 0 then cfgEdit;
        #27 : cfgDone := True;
      end;
   until (HangUp) or (cfgDone);
end;

end.