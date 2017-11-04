{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Files;

interface

uses Global;

procedure fAddToText(Fn, Add : String; Tru : Word);
procedure fClearDir(Path : String);
function  fCopyFile(fFrom, fTo : String) : Boolean;
procedure fCreateDir(Target : String; Stay : Boolean);
function  fDeleteFile(FN : String) : Boolean;
function  fDirExists(Dir: String) : Boolean;
function  fExists(FN : String) : Boolean;
function  fExistsWild(FN : String) : Boolean;
function  fFileSize(Fn : String) : LongInt;
procedure fFindFile(Fn : String);
procedure fFindNext;
function  fFreeSpace : LongInt;
procedure fJumpToDOS(Show : Byte);
procedure fKillDir(Path : String);
procedure fLibraryInstall;
function  fLoadCfg : Boolean;
function  fMoveFile(f, t : String) : Boolean;
procedure fNoLibrary;
function  fRenameFile(F1,F2 : String) : Boolean;
procedure fResetCfg;
procedure fResetModem(N : Byte);
procedure fSaveCfg;
procedure fSaveModem(Node : Byte);
function  fShellDos(Cl : String; Swap, Log, Bat : Boolean) : Byte;
function  fTempPath(Typ : Char) : String;

implementation

uses Dos, Crt,
     Misc, Strings, Screen, Swap, BBSinit, Output, Emulate, FastIO, Logs;

function fExists(FN : String) : Boolean;
var F : File;
begin
   {$I-}
   Assign(F, FN);
   Reset(F);
   Close(F);
   {$I+}
   fExists := (IOResult = 0) and (FN <> '');
end;

function fExistsWild(FN : String) : Boolean;
var SR : SearchRec;
begin
   FindFirst(FN,0,SR);
   fExistsWild := dosError = 0;
end;

function fLoadCfg : Boolean;
var F : file of tCfgRec;
begin
   fLoadCfg := False;
   if not fExists(fileConfig) then Exit;
   Assign(F,fileConfig);
   Reset(F);
   Read(F,Cfg^);
   Close(F);
   fLoadCfg := True;
end;

function fDeleteFile(FN : String) : Boolean;
var F : file;
begin
   Assign(F,FN);
   {$I-}
   Erase(F);
   {$I+}
   fDeleteFile := ioResult = 0;
end;

function fLoadModem(Node : Byte) : Boolean;
var F : file of tModemRec; P : String; Ps : Byte;
begin
   fLoadModem := False;
   P := fileModem;
   Ps := Pos('%',P);
   if Ps < 1 then Exit;
   Delete(P,Ps,1);
   Insert(St(Node),P,Ps);
   if not fExists(Cfg^.pathData+P) then fResetModem(Node);
   Assign(F,Cfg^.pathData+P);
   Reset(F);
   Read(F,Modem^);
   Close(F);
   fLoadModem := True;
end;

procedure fSaveModem(Node : Byte);
var F : file of tModemRec; P : String; Ps : Byte;
begin
   P := fileModem;
   Ps := Pos('%',P);
   if Ps < 1 then Exit;
   Delete(P,Ps,1);
   Insert(St(Node),P,Ps);
   Assign(F,Cfg^.pathData+P);
   Rewrite(F);
   Write(F,Modem^);
   Close(F);
end;

procedure fSaveCfg;
var F : file of tCfgRec;
begin
   Assign(F,StartDir+fileConfig);
   Rewrite(F);
   Write(F,Cfg^);
   Close(F);
end;

procedure fResetCfg;
begin
   resetCfg;
   fSaveCfg;
end;

procedure fResetModem(N : Byte);
begin
   resetModem;
   fSaveModem(N);
end;

procedure fCreateDir(Target : String; Stay : Boolean);
var
  i,
  count   : Integer;
  dir,
  home,
  tempdir,
  Start : String;
  Slash : Array[1..20] of Integer;

begin
  Dir := Target;
  if Stay then GetDir(0,Start);
  if Dir[Length(Dir)] <> '\' then Dir := Dir + '\';
  if Dir[2] = ':' then ChDir(Copy(Dir, 1, 2)) else
  begin
    GetDir(0, Home);
    if Dir[1] <> '\' then
      Dir := Home + '\' + Dir
    else
      Dir := Home + Dir;
  end;

  Count := 0;
  { search directory For slashed and Record them }
  For i := 1 to Length(Dir) do
  begin
    if Dir[i] = '\' then
    begin
      Inc(Count);
      Slash[Count] := i;
    end;
  end;
  { For each step of the way, change to the directory }
  { if get error, assume it doesn't exist - make it }
  { then change to it }
  For i := 2 to Count do
  begin
    TempDir := Copy(Dir, 1, Slash[i] - 1);
    {$I-}
    ChDir(TempDir);
    if IOResult <> 0 then
    begin
      MkDir(TempDir);
      ChDir(TempDir);
    end;
  end;
  if Stay then ChDir(Start);
end;

function fDirExists(Dir: String) : Boolean;
var
   fHandle: file;
   wAttr: WORD;
begin
     while Dir[Length(Dir)] = '\' do Dec( Dir[0] );
     Dir := Dir + '\.';
     Assign( fHandle, Dir );
     GetFAttr( fHandle, wAttr );
     fDirExists := ( (wAttr and Directory) = Directory );
end;

function fRenameFile(F1,F2 : String) : Boolean;
var F : file;
begin
   fRenameFile := False;
   if not fExists(F1) then Exit;
   Assign(F,F1);
   {$I-}
   Rename(F,F2);
   {$I+}
   fRenameFile := IOResult = 0;
end;

function fShellDos(Cl : String; Swap, Log, Bat : Boolean) : Byte;
var S, Z, Tp : String; I : Integer; So : Boolean; F : Text;
    Attr : tColorRec; X, Y : Byte; W1,W2 : Word;
begin
   if Bat then
   begin
      Tp := fTempPath('F');
      Assign(F,Tp+fileTempBat);
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult <> 0 then Exit;
      WriteLn(F,batHead1);
      WriteLn(F,batHead2);
      if Pos(#1,Cl) > 0 then
      begin
         WriteLn(F,Copy(Cl,Pos(#1,Cl)+1,255));
         Cl[0] := Chr(Pos(#1,Cl)-1);
      end;
      WriteLn(F,Cl);
      Close(F);
   end;

   if (Cl <> '') then
   begin
      if Log then logWrite('-Executing "'+Cl+'"...');
      Cl := '/C '+Cl;
   end;

   So := ScreenOff;
   if so then ioScreenOn;

   X := ioWhereX;  Y := ioWhereY;
   scrStoreScreen(1);
   Attr := Col;
   W1 := windMin;
   W2 := windMax;

   fCreateDir(Cfg^.pathSwap,True);
   I := 0;
   repeat
      S := fileSwap;
      Delete(S,Pos('%',S),3);
      Z := St(I);
      while Length(Z) < 3 do Insert('0',Z,1);
      S := S+Z;
      Inc(I);
   until not fExists(Cfg^.pathSwap+S);

   mClearScr(True);
   ioTextAttr($4F);
   if Pos('/C',cl) > 0 then ioWrite(Resize(' '+Copy(cl,4,255),78)+' ');
   ioTextAttr($07);
   ioWriteLn('');
   if (Swap) and (Cfg^.SwapInShell) then
   begin
      UseEMSIfAvailable := Cfg^.SwapToEMS;
      SwapOk := InitExecSwap(HeapPtr,Cfg^.pathSwap+S);
   end;
   ioGotoXY(1,3);
   if Bat then Cl := '/C '+Tp+fileTempBat;
   SwapVectors;
   if (Swap) and (SwapOk) and (Cfg^.SwapInShell) then
   begin
      if not EMSAllocated then WriteLn('Swapping to Disk ...');
      if ExecWithSwap(GetEnv('COMSPEC'),Cl) <> 0 then
      begin
         ioGotoXY(1,3);
         WriteLn('Error Swapping.  Shelling Normally ...');
         Exec(GetEnv('COMSPEC'),Cl);
      end else ShutDownExecSwap;
   end else Exec(GetEnv('COMSPEC'),Cl);
   execLevel := dosExitCode;
   SwapVectors;

   if (Log) and (Pos('/C',Cl) = 0) then logWrite('-Returned from execution (errorlevel '+St(Lo(execLevel))+')');
   fShellDos := Lo(execLevel);

   mClearScr(True);
   scrRestoreScreen(1);
   ioTextColor(Attr.Fore,Attr.Back,Attr.Blink);
   windMin := W1;
   windMax := W2;
   ioGotoXY(X,Y);

   if so then
   begin
      ScreenOff := True;
      ioPageActive(0);
      ioPageVisual(1);
   end;
end;

procedure fJumpToDOS(Show : Byte);
begin
   logWrite('*Shelled to DOS');
   if Show > 1 then emuScreenToANSi;
   if Show >= 1 then oString(strJumpToDOS);
   fCreateDir(StartDir,False);
   fShellDos('',True,False,False);
   if Show >= 1 then oStringLn(strBackFromDOS);
   if Show > 1 then emuANSitoScreen;
   fCreateDir(StartDir,False);
   logWrite('*Returned from DOS shell');
end;

procedure fFindFile(Fn : String);
begin
   FindFirst(Fn,0,Search);
   FileFound := (dosError = 0);
end;

procedure fFindNext;
begin
   FindNext(Search);
   FileFound := (dosError = 0);
end;

function fFreeSpace : LongInt;
begin
   fFreeSpace := DiskFree(0);
end;

function fTempPath(Typ : Char) : String;
var S, T : String;
begin
   case Typ of
      'A' : T := 'ARCH\';
      'D' : T := 'DESC\';
      'F' : T := 'FILE\';
      'I' : T := 'ATCH\';
      'M' : T := 'MSGS\';
      'T' : T := 'TEXT\';
      'Q' : T := 'QWK\';
      'X' : T := 'XFER\';
     else T := '';
   end;
   S := St(Node)+'\';
   while Length(S) < 4 do Insert('0',S,1);
   S := Cfg^.pathTemp+'NODE.'+S+T;
   fCreateDir(S,True);
   fTempPath := S;
end;

function fCopyFile(fFrom, fTo : String) : Boolean;
Type Buf = Array[0..65527] of Byte;
Var
  FileFrom, FileTo : File;
  Buffer : ^Buf;
  BytesToRead, BytesRead : Word;
  MoreToCopy, IoStatus : Boolean;

begin
   fCopyFile := False;
   Assign(FileFrom,fFrom);
   Assign(FileTo,fTo);
   {$I-}
   Reset(FileFrom, 1);
   {$I+}
   if ioResult <> 0 then Exit;
   {$I-}
   ReWrite(FileTo, 1);
   {$I+}
   if ioResult <> 0 then
   begin
      Close(fileFrom);
      Exit;
   end;
   If MaxAvail < 65528 then BytesToRead := MaxAvail else BytesToRead := 65528;
   GetMem(Buffer, BytesToRead);    {Grab heap memory For buffer}
   IoStatus := (IoResult = 0);
   MoreToCopy := True;
   While IoStatus and MoreToCopy do
   begin
      {$I-}
      blockread(FileFrom, Buffer^, BytesToRead, BytesRead);
      blockWrite(FileTo, Buffer^, BytesRead);
      {$I+}
      MoreToCopy := (BytesRead = BytesToRead);
      IoStatus := (IoResult=0);
   end;
   Close(FileTO);
   Close(FileFrom);
   FreeMem(Buffer, BytesToRead); {Release Heap memory}
   if IoStatus then fCopyFile := True;
end;

function fMoveFile(f, t : String) : Boolean;
var Fi : file;
begin
   fMoveFile := False;
   Assign(fi,f);
   {$I-}
   Rename(fi,t);
   {$I+}
   if ioResult = 0 then
   begin
      fMoveFile := True;
      Exit;
   end;
   fMoveFile := (fCopyfile(f,t)) and (fDeleteFile(f));
end;

procedure fKillDir(Path : String);
Var FileInfo : searchRec;
    f        : File;
    path2    : String;
    s        : String;


begin
      if Path[Length(Path)] = '\' then Delete(Path,Length(Path),1);
      FindFirst ( path + '\*.*', AnyFile, FileInfo );
      While DosError = 0 Do
      begin
         if (FileInfo.Name[1] <> '.') and (FileInfo.attr <> VolumeId) then
              if ( (FileInfo.Attr and Directory) = Directory ) then
                begin Path2 := Path + '\' + FileInfo.Name;
                      fKillDir ( path2 );
                end
            else
              if ((FileInfo.Attr and VolumeID) <> VolumeID) then begin
                Assign ( f, path + '\' + FileInfo.Name );
                {$I-}
                Erase ( f );
                {$I+}
              end;
            FindNext ( FileInfo );
      end;

      if (DosError = 18) and not ((Length(path) = 2)
                                   and ( path[2] = ':')) then
      {$I-}
      RmDir ( path );
      {$I+}
end;

procedure fClearDir(Path : String);
Var FileInfo : searchRec;
    f        : File;
    path2    : String;
    s        : String;


begin
      if Path[Length(Path)] = '\' then Delete(Path,Length(Path),1);
      FindFirst ( path + '\*.*', AnyFile, FileInfo );
      While DosError = 0 Do
      begin
         if (FileInfo.Name[1] <> '.') and (FileInfo.attr <> VolumeId) then
              if ( (FileInfo.Attr and Directory) = Directory ) then
                begin Path2 := Path + '\' + FileInfo.Name;
                      fKillDir ( path2 );
                end
            else
              if ((FileInfo.Attr and VolumeID) <> VolumeID) then begin
                Assign ( f, path + '\' + FileInfo.Name );
                {$I-}
                Erase ( f );
                {$I+}
              end;
            FindNext ( FileInfo );
      end;

      if (DosError = 18) and not ((Length(path) = 2)
                                   and ( path[2] = ':')) then
end;

function fFileSize(Fn : String) : LongInt;
var F : file;
begin
   Assign(F,Fn);
   {$I-}
   Reset(F,1);
   {$I+}
   if ioResult = 0 then
   begin
      fFileSize := FileSize(F);
      Close(F);
   end else fFileSize := 0;
end;

procedure fAddToText(Fn, Add : String; Tru : Word);
var F, T : Text; S : String; N, Z : Word;
begin
   if (pos('\',fn) = 0) then fn := Cfg^.pathText+fn;
   Assign(F,Fn);
   {$I-}
   Append(F);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult <> 0 then Exit;
   end;
   WriteLn(F,Add);
   Close(F);
   if Tru > 0 then
   begin
      {$I-}
      Reset(F);
      {$I+}
      N := 0;
      if ioResult <> 0 then Exit;
      while not Eof(F) do
      begin
         Inc(N);
         ReadLn(F);
      end;
      Close(F);
      if N > Tru then
      begin
         Assign(T,fTempPath('F')+'INIQTEMP.TXT');
         {$I-}
         Rewrite(T);
         {$I+}
         if ioResult <> 0 then Exit;
         Reset(F);
         Z := 0;
         while not Eof(F) do
         begin
            ReadLn(F,S);
            Inc(Z);
            if Z > N-Tru then WriteLn(T,S);
         end;
         Close(T);
         Close(F);
         Erase(F);
         Rename(T,Fn);
      end;
   end;
end;

procedure fLibraryInstall;
var ln, z : Word; tlr : tTextLibRec; fl : file of tTextLibRec;
begin
   if not Cfg^.useTextLibs then Exit;
   if tLibOpen then {$I-} Close(tLibFile); {$I+}
   tLibOpen := False;
   Cfg^.useTextLibs := False;
   ln := User^.textLib;
   Assign(fl,Cfg^.pathData+fileTextLib);
   {$I-}
   Reset(fl);
   {$I+}
   numLib := 0;
   if ioResult <> 0 then Exit;
   numLib := FileSize(fl);
   if numLib = 0 then
   begin
      Close(fl);
      Exit;
   end;
   if (ln < 1) or (ln > numLib) then ln := 1;
   Seek(fl,ln-1);
   Read(fl,tlr);
   Close(fl);

   Assign(tLibFile,Cfg^.pathLibs+tlr.Filename+extTextLib);
   {$I-}
   Reset(tLibFile,1);
   {$I+}
   if ioResult <> 0 then Exit;
   BlockRead(tLibFile,textLib^.numLib,1);
   BlockRead(tLibFile,textLib^.Desc,SizeOf(textLib^.Desc));
   BlockRead(tLibFile,textLib^.Author,SizeOf(textLib^.Author));
   for z := 1 to textLib^.numLib do
   begin
      BlockRead(tLibFile,textLib^.Index[z].fileName,13);
      BlockRead(tLibFile,textLib^.Index[z].filePos,4);
      BlockRead(tLibFile,textLib^.Index[z].fileSize,2);
   end;

   tLibOpen := True;
   Cfg^.useTextLibs := True;
   User^.textLib := ln;
end;

procedure fNoLibrary;
begin
   if tLibOpen then {$I-} Close(tLibFile); {$I+}
   tLibOpen := False;
end;

end.