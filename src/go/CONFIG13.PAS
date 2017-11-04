{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config13;

interface

procedure cfgFileEditor(Cur : Word; Del : Boolean);

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, bbsInit,
     Logs, Transfer, FileArea, Config9, Users, Archive;

function cfgFileSearch(Fn : String; var D : tFileRec) : Word;
var F : file; Found, cF : Word;
begin
   cfgFileSearch := 0;
   Found := 0;
   cF := 0;
   Assign(F,Cfg^.pathData+fArea^.Filename+extFileDir);
   {$I-}
   Reset(F,SizeOf(tFileRec));
   {$I+}
   if ioResult = 0 then
   begin
      while (Found = 0) and (not Eof(F)) do
      begin
         BlockRead(F,D,1);
         Inc(cF);
         if faCloseEnough(Fn,D.Filename) then Found := cF;
      end;
      Close(F);
   end;
   cfgFileSearch := Found;
end;

procedure cfgFileEditor(Cur : Word; Del : Boolean);
var curFile, w, Z, oA, nA : Word; Fil : tFileRec; B, isThere : Boolean; Old, Us : String;
    dF : file of tFileRec; atmp : tFileAreaRec; F : file of tFileRec; eF : file of tFileDescLn;
    U : tUserRec; I : LongInt; pD : pFileDesc; tf : Text; sff : file; s : tfileDescLn;
begin
   oA := User^.curFileArea;
   faLoad;
   if fArea^.Files < 1 then Exit;
   if (Del) and (numBatch > 0) then
   begin
      oClrScr;
      oDnLn(1);
      oStrCtr('|U5-- |U4Warning|U5:  |U1Download batch will be cleared|U2.  |U1Continue|U2? ');
      if not iYesNo(True) then Exit;
   end;
   numBatch := 0;
   if Cur = 0 then curFile := 1 else curFile := Cur;
   if not faLoadFile(curFile,Fil) then Exit;
   isThere := fExists(fArea^.Path+Fil.Filename);
   logWrite('*File edit');
   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' File Editor: '+fArea^.Name);
      cfgCol := 25;
      if not isThere then Old := ' |U2(|U1does |U3not|U1 exist|U2)' else Old := '';
      cfgItem('/ Current file #',30,St(curFile)+' of '+St(fArea^.Files)+Old,'');
      cfgCol := 50;
      cfgSrt := 40;
      cfgItem('[ Prev',0,'','');
      cfgSrt := 60;
      cfgCol := 70;
      Dec(cfgLn);
      cfgItem('] Next',0,'','');
      cfgSrt := 1;
      cfgCol := 25;
      Dec(cfgLn);
      if cfgDraw then Dec(cfgBot,2);
      cfgItem('A Filename',12,Fil.Filename,
              'Filename (max 12 chars), will be physically renamed if possible');
      cfgItem('B Size',9,St(Fil.Size),
              'Size of this file in byte (should not normally be altered)');
      cfgItem('C Date',10,Fil.Date,
              'File''s date [mm/dd/yy]');
      cfgItem('D Downloads',5,St(Fil.Downloads),
              'Number of times this file has been downloaded');
      cfgItem('E File points',5,St(Fil.filePts),
              'This file''s value in file points');
      cfgItem('F Uploader',36,Fil.Uploader,
              'Name of user that uploaded this file');
      cfgItem('G Upload date',10,Fil.ulDate,
              'Date that this file was uploaded [mm/dd/yy]');
      cfgItem('H Validated',3,B2St(Fil.Valid),
              '');

      cfgItem('I Edit description',12,St(Fil.DescLns)+' line(s)','');
      Dec(cfgLn);
      cfgSrt := 40;
      cfgCol := 65;
      cfgItem('J View archive',0,'','');

      if cfgDraw then Dec(cfgBot);

      cfgSrt := 1;
      cfgCol := 25;
      if Del then
      begin
         cfgItem('= Move file',0,'','');
         Dec(cfgLn);
         cfgSrt := 40;
         cfgCol := 65;
         cfgItem('* Delete file',0,'','');
         if cfgDraw then Dec(cfgBot);
      end;

      cfgSrt := 1;
      cfgCol := 25;
      cfgItem('+ Apply description',0,'','Creating description file and applying to archive ...');
      Dec(cfgLn);
      cfgSrt := 40;
      cfgCol := 65;
      cfgItem('- Extract description',0,'','Extracting description from archive file ...');

      if cfgDraw then Dec(cfgBot);

      if cfgDraw then
      begin
         Inc(cfgLn);
         oGotoXY(1,cfgLn);
         oSetCol(colInfo);
         faLoadDesc(fil,pd);
         for z := 1 to 6 do
         begin
            oClrEol;
            if fil.DescLns >= z then oStrCtrLn(pD^[z]) else oDnLn(1);
         end;
         faKillDesc(fil,pD);
         Inc(cfgBot,7);
      end;
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        '/' : begin
                 cfgInfo('|U4File to edit (name/number)|U5: |U6');
                 Us := iReadString('',inUpper,chNormal,rsNoCR,13);
                 if Us <> '' then
                 begin
                    faSaveFile(curFile,Fil);
                    Inc(cfgStat,Length(Us));
                    if (strToInt(us) >= 1) and (strToInt(us) <= fArea^.Files) then
                    begin
                       z := strToInt(us);
                       if faLoadFile(z,Fil) then curFile := z;
                    end else
                    begin
                       z := cfgFileSearch(us,Fil);
                       if z > 0 then curFile := z else faLoadFile(curFile,Fil);
                    end;
                    isThere := fExists(fArea^.Path+Fil.Filename);
                    cfgDraw := True;
                    cfgOver := True;
                 end;
                 cfgInfo('');
              end;
        'A' : begin
                 Old := Fil.Filename;
                 cfgReadInfo(Fil.Filename,inUpper,chFilename,'',False);
                 Fil.Filename := cfgRead;
                 if Old <> Fil.Filename then
                    fRenameFile(fArea^.path+Old,fArea^.Path+Fil.Filename);
                 cfgSetItem(Fil.Filename);
              end;
        'B' : begin
                 cfgReadInfo(St(Fil.Size),inUpper,chNumeric,'',True);
                 Fil.Size := mClip(StrToInt(cfgRead),0,100000000);
                 cfgSetItem(St(Fil.Size));
              end;
        'C' : begin
                 cfgReadDate;
                 Fil.Date := cfgRead;
                 cfgSetItem(Fil.Date);
              end;
        'D' : begin
                 cfgReadInfo(St(Fil.Downloads),inUpper,chNumeric,'',True);
                 Fil.Downloads := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Fil.Downloads));
              end;
        'E' : begin
                 cfgReadInfo(St(Fil.filePts),inUpper,chNumeric,'',True);
                 Fil.filePts := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Fil.filePts));
              end;
        'F' : begin
                 cfgReadInfo(Fil.Uploader,inNormal,chNormal,'',False);
                 Fil.Uploader := cfgRead;
                 cfgSetItem(Fil.Uploader);
              end;
        'G' : begin
                 cfgReadDate;
                 Fil.ulDate := cfgRead;
                 cfgSetItem(Fil.ulDate);
              end;
        'H' : begin
                 if Fil.Valid then
                 begin
                    U.UserName := Fil.Uploader;
                    if (userSearch(U,True)) and (userLoad(U)) then
                    begin
                       cfgInfo('|U3'+U.UserName+'|U1 uploaded this|U2; |U1Remove credit for upload from user|U2? ');
                       Inc(cfgStat,10);
                       if cfgYesNo(True) then
                       begin
                          if U.Uploads > 0 then Dec(U.Uploads);
                          I := U.UploadKb-(Fil.Size div 1024);
                          if I < 0 then I := 0;
                          U.UploadKb := I;
                          I := U.filePts-(Fil.filePts*Cfg^.filePtsPer div 100);
                          if I < 0 then I := 0;
                          if (Cfg^.useFilePoints) and (Cfg^.filePtsPer > 0) then
                             U.filePts := I;
                          userSave(U);
                       end;
                    end;
                    Fil.Valid := False;
                 end else
                 begin
                    U.UserName := Fil.Uploader;
                    if (userSearch(U,True)) and (userLoad(U)) then
                    begin
                       cfgInfo('|U1Credit |U3'+U.UserName+'|U1 for uploading this file|U2? ');
                       Inc(cfgStat,10);
                       if cfgYesNo(True) then
                       begin
                          Inc(U.Uploads);
                          Inc(U.UploadKb,Fil.Size div 1024);
                          if (Cfg^.useFilePoints) and (Cfg^.filePtsPer > 0) then
                             Inc(U.filePts,Fil.filePts*Cfg^.filePtsPer div 100);
                          userSave(U);
                       end;
                    end;
                    Fil.Valid := True;
                 end;
                 cfgInfo('');
                 cfgSetItem(B2St(Fil.Valid));
              end;
        'I' : begin
                 faEditFileDesc(Fil);
                 faSaveFile(curFile,Fil);
                 cfgDraw := True;
                 cfgOver := False;
              end;
        'J' : begin
                 if archView(fArea^.Path+fil.Filename) then
                 begin
                    oPromptKey;
                    cfgDraw := True;
                    cfgOver := False;
                 end;
              end;
        '=' : if Del then begin
                 cfgFaListThem;
                 oStrCtr('|U2-- |U1Move |U3'+Fil.Filename+'|U1 to which file area|U2? |U3');
                 nA := strToInt(iReadString('',inUpper,chNumeric,'',3));
                 if (nA > 0) and (nA <= numFileArea) and (nA <> oA) then
                 begin
                    atmp := fArea^;
                    User^.curFileArea := nA;
                    faLoad;
                    Assign(F,Cfg^.pathData+fArea^.Filename+extFileDir);
                    {$I-}
                    Reset(F);
                    {$I+}
                    if ioResult <> 0 then
                    begin
                       {$I-}
                       Rewrite(F);
                       {$I+}
                    end else Seek(F,FileSize(F));
                    Write(F,Fil);
                    fArea^.Files := FileSize(F);
                    Close(F);
                    faSave;

                    atmp := fArea^;
                    User^.curFileArea := oA;
                    faLoad;

                    if fExists(fArea^.Path+Fil.Filename) then
                    begin
                       oStrCtr('|U2-- |U1Move actual file|U2? ');
                       if cfgYesNo(True) then fMoveFile(fArea^.Path+Fil.Filename,atmp.Path+Fil.Filename);
                    end;

                    Assign(dF,Cfg^.pathData+fArea^.Filename+extFileDir);
                    {$I-}
                    Reset(dF);
                    {$I+}
                    if ioResult <> 0 then oBeep;
                    if (curFile >= 1) and (curFile < FileSize(dF)) then
                    for Z := curFile to FileSize(dF)-1 do
                    begin
                       Seek(dF,Z);
                       Read(dF,Fil);
                       Seek(dF,Z-1);
                       Write(dF,Fil);
                    end;
                    Seek(dF,FileSize(dF)-1);
                    Truncate(dF);
                    fArea^.Files := FileSize(dF);
                    Close(dF);
                    faSave;
                    if fArea^.Files = 0 then cfgDone := True;
                    if curFile > fArea^.Files then curFile := fArea^.Files;
                    if not cfgDone then faLoadFile(curFile,Fil);
                    isThere := fExists(fArea^.Path+Fil.Filename);
                 end;
                 faLoad;
                 cfgDraw := True;
                 cfgOver := False;
              end;
        '*' : if Del then begin
                 cfgInfo('Delete this file from area? ');
                 Inc(cfgStat,12);
                 if cfgYesNo(True) then
                 begin
                    Assign(dF,Cfg^.pathData+fArea^.Filename+extFileDir);
                    {$I-}
                    Reset(dF);
                    {$I+}
                    if ioResult = 0 then
                    begin
                       if fExists(fArea^.Path+Fil.Filename) then
                       begin
                          cfgInfo('');
                          cfgInfo('Destroy physical file? ');
                          Inc(cfgStat,12);
                          if cfgYesNo(True) then fDeleteFile(fArea^.Path+Fil.Filename);
                       end;
                       if (curFile >= 1) and (curFile < FileSize(dF)) then
                       for Z := curFile to FileSize(dF)-1 do
                       begin
                          Seek(dF,Z);
                          Read(dF,Fil);
                          Seek(dF,Z-1);
                          Write(dF,Fil);
                       end;
                       Seek(dF,FileSize(dF)-1);
                       Truncate(dF);
                       fArea^.Files := FileSize(dF);
                       Close(dF);
                       faSave;
                       if fArea^.Files = 0 then cfgDone := True;
                       if curFile > fArea^.Files then curFile := fArea^.Files;
                       if not cfgDone then faLoadFile(curFile,Fil);
                       isThere := fExists(fArea^.Path+Fil.Filename);
                       cfgDraw := True;
                       cfgOver := True;
                    end;
                 end;
                 cfgInfo('');
              end;
        '+' : if fil.descLns > 0 then
              begin
                 faLoadDesc(fil,pD);
                 Old := fTempPath('F');
                 Assign(tf,Old+Cfg^.fileDesc1);
                 {$I-}
                 Rewrite(tf);
                 {$I+}
                 if ioResult = 0 then
                 begin
                    for z := 1 to fil.descLns-1 do WriteLn(tf,pD^[z]);
                    Write(tf,pD^[fil.descLns]);
                    Close(tf);
                    if archZip(fArea^.Path+fil.Filename,Old+Cfg^.fileDesc1,0) then
                    begin
                       Assign(sff,fArea^.Path+fil.Filename);
                       {$I-}
                       Reset(sff,1);
                       {$I+}
                       if ioResult = 0 then
                       begin
                          fil.Size := FileSize(sff);
                          Close(sff);
                          cfgDraw := True;
                          cfgOver := True;
                       end;
                    end;
                 end;
                 faKillDesc(fil,pD);
              end;
        '-' : begin
                 old := fTempPath('A');
                 fClearDir(old);
                 z := 0;
                 if archUnzip(fArea^.Path+fil.Filename,Cfg^.fileDesc1+' '+Cfg^.fileDesc2,old) then
                 begin
                    if fExists(old+Cfg^.fileDesc1) then
                       z := faLoadDescFile(old+Cfg^.fileDesc1,pD) else
                    if fExists(old+Cfg^.fileDesc2) then
                       z := faLoadDescFile(old+Cfg^.fileDesc2,pD);
                    if z > fil.DescLns then
                    begin
                       Fil.DescLns := z;
                       Assign(eF,Cfg^.pathData+fileFileDesc);
                       {$I-}
                       Reset(eF);
                       {$I+}
                       if ioResult <> 0 then {$I-} Rewrite(eF) {$I+} else
                       Seek(eF,FileSize(eF));
                       Fil.DescPtr := FilePos(eF);
                       for w := 1 to Fil.DescLns do
                       begin
                          s := pD^[w];
                          Write(eF,s);
                       end;
                       Close(eF);
                       end else
                       if (z > 0) and (z <= Fil.DescLns) then
                       begin
                          Fil.DescLns := z;
                          Assign(eF,Cfg^.pathData+fileFileDesc);
                          {$I-}
                          Reset(eF);
                          {$I+}
                          if ioResult = 0 then
                          begin
                             Seek(eF,Fil.DescPtr);
                             for w := 1 to Fil.DescLns do
                             begin
                                s := pD^[w];
                                Write(eF,s);
                             end;
                          Close(eF);
                       end;
                    end;
                    cfgOver := True;
                    cfgDraw := True;
                 end;
              end;
        '[' : begin
                 faSaveFile(curFile,Fil);
                 Dec(curFile);
                 if curFile < 1 then curFile := fArea^.Files;
                 faLoadFile(curFile,Fil);
                 isThere := fExists(fArea^.Path+Fil.Filename);
                 cfgDraw := True;
                 cfgOver := True;
              end;
        ']' : begin
                 faSaveFile(curFile,Fil);
                 Inc(curFile);
                 if curFile > fArea^.Files then curFile := 1;
                 faLoadFile(curFile,Fil);
                 isThere := fExists(fArea^.Path+Fil.Filename);
                 cfgDraw := True;
                 cfgOver := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   if (fArea^.Files > 0) and (curFile > 0) then faSaveFile(curfile,Fil);
   cfgDone := False;
end;

end.