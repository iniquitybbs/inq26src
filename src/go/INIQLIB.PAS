{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D+,L-,N-,E+}
{$M 40000,0,100000}

(*                                                                          *)
(*   Iniquity Textfile Library Manager                                      *)
(*   (c)Copyright 1994, Mike Fricker                                        *)
(*                                                                          *)

program iniqLib;

uses
   Dos,
   Crt,
   Global, FastIO, Files, Misc, Strings;

var
   fl : file;
   fnl, fs : String;
   err : Boolean;
   tLib : tTextLib;

function iReadLn(L : Byte) : String;
var S,DefStr : String; Done, Req, Min, Def : Boolean; C : Char; P : Byte; X : Integer;
  procedure ToPos(N : Integer);
  begin
     ioGotoXY(ioWhereX+N-P,ioWhereY);
     P := N;
  end;
  procedure AddCh(Cr : Char);
  begin
     if (P <= L) then
     begin
        S := S + Cr; Inc(P);
        ioWriteChar(Cr);
     end;
  end;
begin
   S := '';
   Min := True; Req := False;
   Def := False;
   DefStr := S;
   P := 1; Done := False;
   repeat
      C := ReadKey;
      if (C = #0) and (Keypressed) then ReadKey;
      case C of
        #32..#254 : AddCh(C);
        #8 : if Length(S) > 0 then
             begin
                Delete(S,Length(S),1); Dec(P);
                ioWrite(#8#32#8);
             end;
        #13 : if ((Req) and (Length(S) = P-1)) or
                 ((Min) and (Length(S) >= 1)) or
                 ((not Req) and (not Min)) then
                 begin
                    if (Def) and (Length(S) = 0) then
                       for X := 1 to Length(DefStr) do AddCh(DefStr[X]);
                    Done := True;
                 end;
     end;
   until Done;
   iReadLn := CleanUp(S);
   ioWriteLn('');
end;

procedure libCreateTfl;
type tBuf = array[1..20000] of Byte;
var sr : SearchRec; z, size : Word; f : file;
    Buf : ^tBuf; alr : Boolean;
begin
   tLib.numLib := 0;
   alr := False;
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   ioWriteLn('Library filename: '+fnl);
   ioWriteLn('        filespec: '+fs+'*.*');
   ioWriteLn('');
   if (tLib.Desc <> '') and (not (mParam('-r') or mParam('/r'))) then
   begin
      ioWriteLn('Previous library existed; header information loaded (-r command not specified)');
      ioWriteLn('');
      ioWriteLn('Library description: '+tLib.Desc);
      ioWriteLn('     Library author: '+tLib.Author);
   end else
   begin
      ioWrite('Enter library description: ');
      tLib.Desc := iReadLn(36);
      ioWrite('     Enter library author: ');
      tLib.Author := iReadLn(36);
   end;
   ioWriteLn('');
   ioWrite('Generating library header ...');
   FindFirst(fs+'*.*',0,sr);
   while (tLib.numLib < maxTextLib) and (dosError = 0) do
   begin
      Inc(tLib.numLib);
      tLib.Index[tLib.numLib].fileName := sr.Name;
      tLib.Index[tLib.numLib].fileSize := sr.Size;
      tLib.Index[tLib.numLib].filePos := 0;
      FindNext(sr);
   end;
   if tLib.numLib = 0 then Exit;
   BlockWrite(fl,tLib.numLib,1);
   BlockWrite(fl,tLib.Desc,SizeOf(tLib.Desc));
   BlockWrite(fl,tLib.Author,SizeOf(tLib.Author));
   for z := 1 to tLib.numLib do
   begin
      BlockWrite(fl,tLib.Index[z].fileName,13);
      BlockWrite(fl,tLib.Index[z].filePos,4);
      BlockWrite(fl,tLib.Index[z].fileSize,2);
   end;
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   ioWrite('Adding textfiles to library ...');
   New(Buf);
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   for z := 1 to tLib.numLib do
   begin
      ioWrite('Adding: '+fs+tLib.Index[z].fileName);
      ioClrEol;
      ioGotoXY(1,ioWhereY);
      tLib.Index[z].filePos := FilePos(fl);
      Assign(f,fs+tLib.Index[z].fileName);
      {$I-}
      Reset(f,1);
      BlockRead(f,Buf^,20000,Size);
      BlockWrite(fl,Buf^,Size);
      {$I+}
      Close(f);
   end;
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   ioWrite('Creating textfile library index ...');
   Seek(fl,0);
   BlockWrite(fl,tLib.numLib,1);
   BlockWrite(fl,tLib.Desc,SizeOf(tLib.Desc));
   BlockWrite(fl,tLib.Author,SizeOf(tLib.Author));
   for z := 1 to tLib.numLib do
   begin
      BlockWrite(fl,tLib.Index[z].fileName,13);
      BlockWrite(fl,tLib.Index[z].filePos,4);
      BlockWrite(fl,tLib.Index[z].fileSize,2);
   end;
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   ioWriteLn('Library "'+fnl+'" successfully created ['+St(tLib.numLib)+' files]');
   Dispose(Buf);
end;

procedure libExtractTfl;
type tBuf = array[1..20000] of Byte;
var sr : SearchRec; z, size : Word; f : file;
    Buf : ^tBuf; alr : Boolean;
begin
   FillChar(tLib,SizeOf(tLib),0);
   tLib.numLib := 0;
   alr := False;
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   ioWriteLn('Library filename: '+fnl);
   ioWriteLn(' Extraction path: '+fs);
   ioWriteLn('');
   ioWrite('Reading library header ...');
   BlockRead(fl,tLib.numLib,1);
   BlockRead(fl,tLib.Desc,SizeOf(tLib.Desc));
   BlockRead(fl,tLib.Author,SizeOf(tLib.Author));
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   if tLib.numLib = 0 then Exit;
   ioWriteLn('Library description: '+tLib.Desc);
   ioWriteLn('     Library author: '+tLib.Author);
   ioWriteLn('');
   ioWrite('Loading library index ...');
   for z := 1 to tLib.numLib do
   begin
      BlockRead(fl,tLib.Index[z].fileName,13);
      BlockRead(fl,tLib.Index[z].filePos,4);
      BlockRead(fl,tLib.Index[z].fileSize,2);
   end;
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   ioWrite('Extracting textfiles from library ...');
   New(Buf);
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   for z := 1 to tLib.numLib do
   begin
      ioWrite('Extracting: '+fs+tLib.Index[z].fileName);
      ioClrEol;
      ioGotoXY(1,ioWhereY);
      Seek(fl,tLib.Index[z].filePos);
      Assign(f,fs+tLib.Index[z].fileName);
      {$I-}
      Rewrite(f,1);
      BlockRead(fl,Buf^,tLib.Index[z].fileSize,Size);
      BlockWrite(f,Buf^,Size);
      {$I+}
      Close(f);
   end;
   ioGotoXY(1,ioWhereY);
   ioClrEol;
   ioWriteLn(St(tLib.numLib)+' files extracted successfully from library "'+fnl+'"');
   Dispose(Buf);
end;

procedure libError;
begin
   Halt(255);
end;

begin
   TextMode(co80);
   ioInitFastIO;
   ioClrScr;
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($0F);
   ioWriteLn('iniqLib v'+bbsVersion+'  (c)Copyright 1995, Mike Fricker');
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($07);
   ioWriteLn('Textfile library creation & extraction utility');
   ioTextAttr($08);
   ioWrite(sRepeat('Ä',80));
   ioTextAttr($07);
   err := False;
   if ParamCount = 0 then
   begin
      ioWriteLn('No command line parameters specified');
      err := True;
   end else
   if ParamCount = 1 then
   begin
      ioWriteLn('Filespec or directory name required');
      err := True;
   end else
   begin
      fnl := UpStr(ParamStr(1));
      fs := UpStr(ParamStr(2));
      if Pos('.',fnl) = 0 then fnl := fnl+extTextLib;
      fnl := fExpand(upStr(fnl));
      FillChar(tLib,SizeOf(tLib),0);
      Assign(fl,fnl);
      {$I-}
      Reset(fl,1);
      {$I+}
      if ioResult = 0 then
      begin
         BlockRead(fl,tLib.numLib,1);
         BlockRead(fl,tLib.Desc,SizeOf(tLib.Desc));
         BlockRead(fl,tLib.Author,SizeOf(tLib.Author));
         Close(fl);
      end;
      if mParam('-x') or mParam('/x') then
      begin
         fCreateDir(fs,True);
         if fDirExists(fs) then fs := strBkSlash(True,fs) else
         begin
            ioWriteLn('Invalid directory name.');
            libError;
         end;
         Assign(fl,fnl);
         {$I-}
         Reset(fl,1);
         {$I+}
         if ioResult <> 0 then
         begin
            ioWriteLn('Specified library file does not exist.');
            libError;
         end;
         libExtractTfl;
         Close(fl);
      end else
      begin
         if fDirExists(fs) then fs := strBkSlash(True,fs) else
         begin
            ioWriteLn('Specified path is not a directory.');
            libError;
         end;
         fFindFile(fs+'*.*');
         if not fileFound then
         begin
            ioWriteLn('No file(s) found in specified directory.');
            libError;
         end;
         Assign(fl,fnl);
         {$I-}
         Rewrite(fl,1);
         {$I+}
         if ioResult <> 0 then
         begin
            ioWriteLn('Invalid library filename.');
            libError;
         end;
         libCreateTfl;
         Close(fl);
      end;
   end;

   if err then
   begin
      ioWriteLn('');
      ioWriteLn('Usage:  '+ParamStr(0)+' <libfile> <dirname> [-x|r]');
      ioWriteLn('');
      ioWriteLn('<libfile> is the TFL file you want to process');
      ioWriteLn('<dirname> is the directory in which textfiles will be found or created in');
      ioWriteLn('');
      ioWriteLn('When creating a library, iniqLib will attempt to load the description and');
      ioWriteLn('author from the specified TFL file (if it exists)');
      ioWriteLn('');
      ioWriteLn('Also, you may specify one of the following commands:');
      ioWriteLn('');
      ioWriteLn(' -x   Extraction command; iniqLib will export the textfiles in the TFL file');
      ioWriteLn('      to the specified directory');
      ioWriteLn(' -r   Rewrite header command; allows you to enter new description and author');
      ioWriteLn('      information.  iniqLib will not import original header information when');
      ioWriteLn('      this command is specified [only used in TFL creation]');
      libError;
   end;
end.

