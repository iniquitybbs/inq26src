{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config10;

interface

procedure cfgArchiverEditor;

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Files, Misc, bbsInit, Archive,
     Logs;

procedure cfgArchiverEditor;
var curArch, Z : Byte; Arch : tArchiverRec; B : Boolean; X : Byte;
    optView : array[1..2] of String;
begin
   curArch := 1;
   optView[1] := 'None';
   optView[2] := 'ZIP';
   logWrite('*Archive edit.');
   archLoadArch(Arch,curArch);
   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' Archiver Editor');
      cfgCol := 25;
      cfgItem('--Current archiver #',2,St(curArch),'');
      cfgItem('A Active archiver',3,b2st(Arch.Active),
              'Is this archiver currently active or disabled?');
      cfgItem('B File extension',3,Arch.Extension,
              '3 character file extension that signifies use of this archiver');
      cfgItem('C Archive signature',20,Arch.fileSig,
              'First bytes of archive file (for ID).  Use ^xxx for weird chars (xxx = Ascii)');
      cfgItem('D Compress command',40,Arch.cmdZip,
              'Archive command to compress/add file(s) to an archive');
      cfgItem('E Decompress command',40,Arch.cmdUnzip,
              'Archive command to decompress an archive to a specific directory');
      cfgItem('F Test command',40,Arch.cmdTest,
              'Archive command to perform an integrity check on the archive file');
      cfgItem('G Comment command',40,Arch.cmdComment,
              'Archive command to add file comments to the archive, if possible');
      cfgItem('H Delete command',40,Arch.cmdDelete,
              'Archive command to delete file(s) from the archive');
      cfgItem('I List character',1,Arch.listChar,
              'Character used to specify a batch list of files for an operation');
      cfgItem('J Internal viewer',5,cfgOption(optView,Arch.Viewer),
              'Internal archiver viewer');
      cfgItem('K Success errorlevel',3,St(Arch.okErrLevel),
              'Errorlevel that indicates that archive command was successful');
      cfgItem('L Check errorlevel',3,B2St(Arch.CheckEL),
              'Check the errorlevel for success code, or ignore it?');
      cfgItem('[ Previous archiver',0,'','');
      cfgItem('] Next archiver',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadBoolean(Arch.Active);
                 cfgSetItem(B2St(Arch.Active));
              end;
        'B' : begin
                 cfgReadInfo(Arch.Extension,inUpper,chFilename,'',False);
                 Arch.Extension := cfgRead;
                 cfgSetItem(Arch.Extension);
              end;
        'C' : begin
                 cfgReadInfo(Arch.fileSig,inNormal,chNormal,'',False);
                 if cfgRead = '' then Arch.fileSig := '' else
                 if mArchSig(cfgRead) <> '' then Arch.fileSig := cfgRead;
                 cfgSetItem(Arch.fileSig);
              end;
        'D' : begin
                 cfgReadInfo(Arch.cmdZip,inNormal,chNormal,'',False);
                 Arch.cmdZip := cfgRead;
                 cfgSetItem(Arch.cmdZip);
              end;
        'E' : begin
                 cfgReadInfo(Arch.cmdUnzip,inNormal,chNormal,'',False);
                 Arch.cmdUnzip := cfgRead;
                 cfgSetItem(Arch.cmdUnzip);
              end;
        'F' : begin
                 cfgReadInfo(Arch.cmdTest,inNormal,chNormal,'',False);
                 Arch.cmdTest := cfgRead;
                 cfgSetItem(Arch.cmdTest);
              end;
        'G' : begin
                 cfgReadInfo(Arch.cmdComment,inNormal,chNormal,'',False);
                 Arch.cmdComment := cfgRead;
                 cfgSetItem(Arch.cmdComment);
              end;
        'H' : begin
                 cfgReadInfo(Arch.cmdDelete,inNormal,chNormal,'',False);
                 Arch.cmdDelete := cfgRead;
                 cfgSetItem(Arch.cmdDelete);
              end;
        'I' : begin
                 cfgReadInfo(Arch.listChar,inNormal,chNormal,'',False);
                 Arch.listChar := cfgRead[1];
                 cfgSetItem(Arch.listChar);
              end;
        'J' : begin
                 cfgReadOption(optView,2,Arch.Viewer);
                 cfgSetItem(cfgOption(optView,Arch.Viewer));
              end;
        'K' : begin
                 cfgReadInfo(St(Arch.okErrLevel),inUpper,chNumeric,'',False);
                 Arch.okErrLevel := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(Arch.okErrLevel));
              end;
              { Viewer }
        'L' : begin
                 cfgReadBoolean(Arch.CheckEL);
                 cfgSetItem(B2St(Arch.CheckEL));
              end;
        '[' : begin
                 archSaveArch(Arch,curArch);
                 Dec(curArch,1);
                 if curArch < 1 then curArch := maxArchiver;
                 archLoadArch(Arch,curArch);
                 cfgDraw := True;
                 cfgOver := True;
              end;
        ']' : begin
                 archSaveArch(Arch,curArch);
                 Inc(curArch,1);
                 if curArch > maxArchiver then curArch := 1;
                 archLoadArch(Arch,curArch);
                 cfgDraw := True;
                 cfgOver := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   archSaveArch(Arch,curArch);
   cfgDone := False;
end;

end.