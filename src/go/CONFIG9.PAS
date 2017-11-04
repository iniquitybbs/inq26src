{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config9;

interface

procedure cfgFaListThem;
procedure cfgFileAreaEditor;

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, bbsInit,
     Logs, FileArea;

var faF : file of tFileAreaRec;

procedure cfgInsertFileArea;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   if numFileArea >= maxFileArea then
   begin
      oCWriteLn('|U0You may only have a maximum of '+St(maxFileArea)+' file areas.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Insert before which file area? |U5[|U61|U5-|U6'+St(numFileArea+1)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numFileArea+1) or (I < 1) then Exit;

   oCWrite('|U1Number of areas to insert |U5[|U61|U5-|U6'+St(maxMsgArea-numMsgArea)+'|U5]: |U3');
   X := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (X > maxMsgArea-numMsgArea) or (X < 1) then X := 1;

   Dec(I);

   Reset(faF);
   for b := 1 to x do
   begin
      for Z := FileSize(faF)-1 downto I do
      begin
         Seek(faF,Z);
         Read(faF,fArea^);
         Write(faF,fArea^);
      end;
      faReset;
      Seek(faF,I);
      Write(faF,fArea^);
   end;
   numFileArea := FileSize(faF);
   Close(faF);
{  faUpdateScanFile;}
end;

procedure cfgDeleteFileArea;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   if numFileArea <= 1 then
   begin
      oCWriteLn('|U0You must have at least one file area!');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Delete which file area? |U5[|U61|U5-|U6'+St(numFileArea)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numFileArea) or (I < 1) then Exit;

   Dec(I,1);

   Reset(faF);
   if (I >= 0) and (I <= FileSize(faF)-2) then
   for Z := I to FileSize(faF)-2 do
   begin
      Seek(faF,Z+1);
      Read(faF,fArea^);
      Seek(faF,Z);
      Write(faF,fArea^);
   end;
   Seek(faF,FileSize(faF)-1);
   Truncate(faF);
   Dec(numFileArea,1);
   Close(faF);
   if (fExists(Cfg^.pathData+fArea^.Filename+extFileDir)) then
   begin
      oDnLn(1);
      oCWrite('|U1Delete this file area''s data files? ');
      if iYesNo(False) then fDeleteFile(Cfg^.pathData+fArea^.Filename+extFileDir);
   end;
end;

procedure cfgMoveFileArea;
var K,X,Y,I,B : Word; J : Integer;
    mTemp : ^tFileAreaRec;
begin
   oDnLn(2);
   if numFileArea <= 1 then
   begin
      oCWriteLn('|U0There is only one file area, no need to move it.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Move which file area? |U5[|U61|U5-|U6'+St(numFileArea)+'|U5]: |U3');
   X := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (X > numFileArea) or (X < 1) then Exit;

   oCWrite('|U1Move before which file area? |U5[|U61|U5-|U6'+St(numFileArea+1)+'|U5]: |U3');
   Y := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (Y > numFileArea+1) or (Y < 1) then Exit;

   Dec(I,1);

   New(mTemp);
   Reset(faF);

   K := Y;
   if (Y > X) then Dec(Y);
   Dec(X);
   Dec(Y);
   Seek(faF,X);
   Read(faF,mTemp^);
   I := X;
   if (X > Y) then J := -1 else J := 1;
   while (I <> Y) do
   begin
      if (I+J < FileSize(faF)) then
      begin
         Seek(faF,I+J);
         Read(faF,fArea^);
         Seek(faF,I);
         Write(faF,fArea^);
      end;
      Inc(I,J);
   end;
   Seek(faF,Y);
   Write(faF,mTemp^);
   Inc(X);
   Inc(Y);
   {y:=k;}
   Close(faF);
   Dispose(mTemp);
{
   if ((I >= 0) and (I <= FileSize(faF))) and (numFileArea < maxMsgArea) then
   begin
      for Z := FileSize(faF)-1 downto I do
      begin
         Seek(faF,Z);
         Read(faF,mArea^);
         Write(faF,mArea^);
      end;
      maReset;
      Seek(faF,I);
      Write(faF,mArea^);
      Inc(numFileArea,1);
   end;}
end;

procedure cfgEditFileArea;
var optSort : array[1..8] of String;
    optSortDir : array[1..2] of String;
    An, Anum : Word; Fil : String; Z : Byte;
begin
   optSort[1] := 'None (unsorted)';
   optSort[2] := 'Filename';
   optSort[3] := 'Extension';
   optSort[4] := 'Size';
   optSort[5] := 'Date';
   optSort[6] := 'Upload date';
   optSort[7] := 'Uploader';
   optSort[8] := 'Downloads';

   optSortDir[1] := 'Ascending';
   optSortDir[2] := 'Descending';

   Anum := User^.curFileArea;
   oDnLn(2);
   if numFileArea = 0 then
   begin
      oCWriteLn('|U0Can''t continue.  No file areas exist.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Begin edit with which file area? |U5[|U61|U5-|U6'+St(numFileArea)+'|U5]: |U3');
   An := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (An > numFileArea) or (An < 1) then Exit;
   User^.curFileArea := An;
   faLoad;

   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' File Area Editor');
      cfgItem('--Current area',3,St(An),'');
      cfgItem('A Description',40,fArea^.Name,
              'This file area''s description (shown in file area lists, etc).');
      cfgItem('B Filename',8,fArea^.Filename,
              'This is the file prefix that''s used to store the area''s data.');
      cfgItem('C File path',40,fArea^.Path,
              'Directory in which the files in this area are stored.');
      cfgItem('D Area sponsor',36,fArea^.Sponsor,
              'Creator or manager of this file area (Usually the SysOp).');
      cfgItem('E Access ACS',20,fArea^.acs,
              'ACS required to access this file area.');
      cfgItem('F Upload ACS',20,fArea^.acsUL,
              'ACS required to upload files to this area.');
      cfgItem('G Download ACS',20,fArea^.acsDL,
              'ACS required to download files from this area.');
      cfgItem('H Password',20,fArea^.Password,
              'Password required to access this area.');
      cfgItem('I Sort method',20,cfgOption(optSort,fArea^.SortType),
              'How to sort this file area.');
      if fArea^.SortAcen then Z := 1 else Z := 2;
      cfgItem('J Sort direction',20,cfgOption(optSortDir,Z),
              'Direction to sort files.');
      cfgItem('K # of files',5,st(fArea^.Files),
              'Number of files currently in area (do not change unless necessary)');
      cfgItem('[ Previous area',0,'','');
      cfgItem('] Next area',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(fArea^.Name,inNormal,chNormal,'',False);
                 fArea^.Name := cfgRead;
                 cfgSetItem(fArea^.Name);
              end;
        'B' : begin
                 Fil := fArea^.Filename;
                 cfgReadInfo(fArea^.Filename,inUpper,chFileNoExt,'',True);
                 fArea^.Filename := cfgRead;
                 cfgSetItem(fArea^.Filename);
                 fRenameFile(Cfg^.pathData+Fil+extFileDir,fArea^.Filename+extFileDir);
              end;
        'C' : begin
                 cfgReadInfo(fArea^.Path,inUpper,chDirectory,'',True);
                 fArea^.Path := cfgRead;
                 if fArea^.Path[Length(fArea^.Path)] <> '\' then
                    fArea^.Path := fArea^.Path+'\';
                 cfgSetItem(fArea^.Path);
                 cfgAskCreate(fArea^.Path);
              end;
        'D' : begin
                 cfgReadInfo(fArea^.Sponsor,inNormal,chNormal,'',False);
                 fArea^.Sponsor := cfgRead;
                 cfgSetItem(fArea^.Sponsor);
              end;
        'E' : begin
                 cfgReadInfo(fArea^.acs,inLower,chNormal,'',False);
                 fArea^.acs := cfgRead;
                 cfgSetItem(fArea^.acs);
              end;
        'F' : begin
                 cfgReadInfo(fArea^.acsUL,inLower,chNormal,'',False);
                 fArea^.acsUL := cfgRead;
                 cfgSetItem(fArea^.acsUL);
              end;
        'G' : begin
                 cfgReadInfo(fArea^.acsDL,inLower,chNormal,'',False);
                 fArea^.acsDL := cfgRead;
                 cfgSetItem(fArea^.acsDL);
              end;
        'H' : begin
                 cfgReadInfo(fArea^.Password,inUpper,chNormal,'',False);
                 fArea^.Password := cfgRead;
                 cfgSetItem(fArea^.Password);
              end;
        'I' : begin
                 cfgReadOption(optSort,8,fArea^.SortType);
                 cfgSetItem(cfgOption(optSort,fArea^.SortType));
              end;
        'J' : begin
                 cfgReadOption(optSortDir,2,Z);
                 cfgSetItem(cfgOption(optSortDir,Z));
                 if Z = 1 then fArea^.SortAcen := True else fArea^.SortAcen := False;
              end;
        'K' : begin
                 cfgReadInfo(St(fArea^.Files),inUpper,chNumeric,'',True);
                 fArea^.Files := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(fArea^.Files));
              end;
        '[' : begin
                 User^.curFileArea := An;
                 faSave;
                 if An = 1 then An := numFileArea else Dec(An,1);
                 User^.curFileArea := An;
                 faLoad;
                 cfgDraw := True;
                 cfgOver := True;
              end;
        ']' : begin
                 User^.curFileArea := An;
                 faSave;
                 if An = numFileArea then An := 1 else Inc(An,1);
                 User^.curFileArea := An;
                 faLoad;
                 cfgDraw := True;
                 cfgOver := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
   User^.curFileArea := An;
   faSave;
   User^.curFileArea := Anum;
   if UserOn then faLoad;
end;

procedure cfgFaListThem;
begin
   oClrScr;
   PausePos := 1;
   PauseAbort := False;
   oSetCol(colText);
   oWriteLn(' Num  Description                Filename  ACS    ulACS  dlACS  Sponsor');
{                   4                         26         9      6      6      6       16}
   oSetCol(colBorder);
   oWriteLn(sRepeat('Ä',79));
   oUpPause(2);

   numFileArea := 0;

   Assign(faF,Cfg^.pathData+fileFileArea);
   {$I-}
   Reset(faF);
   {$I+}
   if ioResult <> 0 then
   begin
      faReset;
      Rewrite(faF);
      Write(faF,fArea^);
      Close(faF);
      Reset(faF);
   end;
   while (not PauseAbort) and (not Eof(faF)) do
   begin
      Read(faF,fArea^);
      Inc(numFileArea,1);
      oSetCol(colInfo);
      oCWriteLn(' '+Resize(St(numFileArea),4)+
                ' '+Resize(fArea^.Name,26)+
                ' '+Resize(fArea^.Filename,9)+
                ' '+Resize(fArea^.acs,6)+
                ' '+Resize(fArea^.acsUL,6)+
                ' '+Resize(fArea^.acsDL,6)+
                ' '+strSquish(fArea^.Sponsor,16));
      oUpPause(1);
   end;
   numFileArea := FileSize(faF);
   Close(faF);
   if numFileArea = 0 then oWriteLn('No file areas currently exist.');
   oSetCol(colBorder);
   oWriteLn(sRepeat('Ä',79));
   oUpPause(1);
   PausePos := 0;
end;

procedure cfgFileAreaEditor;
var cmdFaEdit : array[1..5] of String;
    oldArea : Word;
begin
   if numBatch > 0 then
   begin
      oDnLn(1);
      oStrCtr('|U5-- |U4Warning|U5:  |U1Download batch will be cleared|U2.  |U1Continue|U2? ');
      if not iYesNo(True) then Exit;
   end;
   numBatch := 0;
   cmdFaEdit[1] := 'I nsert';
   cmdFaEdit[2] := 'D elete';
   cmdFaEdit[3] := 'E dit';
   cmdFaEdit[4] := 'M ove';
   cmdFaEdit[5] := 'Esc Quit';
   cfgDone := False;
   oldArea := User^.curFileArea;
   logWrite('*File area edit.');
   repeat
      cfgDraw := True;
      cfgOver := False;

      cfgFaListThem;

      cfgPrompt(cmdFaEdit,5);
      repeat
         cfgKey := UpCase(iReadkey);
      until (HangUp) or (cfgKey in ['M','I','D','E',#27]);
      if cfgKey = #27 then oWrite('Quit') else oWriteChar(cfgKey);
      oDnLn(1);
      case cfgKey of
        'I' : cfgInsertFileArea;
        'D' : cfgDeleteFileArea;
        'E' : cfgEditFileArea;
        'M' : cfgMoveFileArea;
        #27 : cfgDone := True;
      end;
   until (HangUp) or (cfgDone);
{  msgUpdateAllScanFiles;}
   User^.curFileArea := oldArea;
   faLoad;
end;

end.