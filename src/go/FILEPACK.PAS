{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
{$M 40000,0,30000}

(*                                                                          *)
(*   Iniquity File Packing Utility                                          *)
(*   (C)Copyright 1994, Mike Fricker                                        *)
(*                                                                          *)

program FilePack;

uses
   Dos, Crt,
   Global, Strings, Misc, FastIO;

var
   fF : file of tFileAreaRec;
   fC : file of tCfgRec;
   fD : file of tFileRec;

   D : tFileRec;

procedure fpError;
begin
   Dispose(Cfg);
   Dispose(fArea);
   Halt(255);
end;

procedure fpPackDescFile;
var F, nF : file of tFileDescLn; Des : tFileDescLn; Z : Word; nP : LongInt;
    aL : Byte;
begin
   Assign(F,cfg^.pathData+fileFileDesc);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      Close(fF);
      fpError;
   end;
   Assign(nF,cfg^.pathData+'FILEDESC.$$$');
   {$I-}
   Rewrite(nF);
   {$I+}
   if ioResult <> 0 then
   begin
      Close(fF);
      Close(F);
      fpError;
   end;
   ioWriteLn('');
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($0A);
   ioWrite('Packing and sorting file descriptions');
   ioTextAttr($08);
   ioWrite(' ... ');
   ioTextAttr($02);
   ioWrite('Please wait');
   ioTextAttr($08);
   ioWriteLn('.');
   ioWriteLn('');
   ioTextAttr($07);
   ioWrite('Old file size');
   ioTextAttr($08);
   ioWrite(': ');
   ioTextAttr($0F);
   ioWriteLn(stc(FileSize(F)*51));
   ioTextAttr($07);
   ioWrite('New file size');
   ioTextAttr($08);
   ioWrite(': ');
   ioTextAttr($0F);
   ioWriteLn('0');
   ioWriteLn('');
   ioTextAttr($02);
   ioWrite('Area');
   ioTextAttr($08);
   ioWriteLn(':');
   ioTextAttr($02);
   ioWrite('File');
   ioTextAttr($08);
   ioWriteLn(':');
   aL := 0;

   Seek(fF,0);
   while not Eof(fF) do
   begin
      Read(fF,fArea^);
      ioGotoXY(7,10);
      ioTextAttr($0A);
      ioWrite(strEnlarge(NoColor(fArea^.Name),aL));
      aL := Length(noColor(fArea^.Name));
      Assign(fD,cfg^.pathData+fArea^.Filename+extFileDir);
      {$I-}
      Reset(fD);
      {$I+}
      if ioResult = 0 then
      begin
         while not Eof(fD) do
         begin
            Read(fD,D);
            if D.descLns > 0 then
            begin
               ioGotoXY(7,11);
               ioTextAttr($0A);
               ioWrite(Resize(D.Filename,12));
               Seek(F,D.descPtr);
               nP := FilePos(nF);
               for Z := 1 to D.descLns do
               begin
                  Read(F,Des);
                  Write(nF,Des);
               end;
               ioGotoXY(16,8);
               ioTextAttr($0F);
               ioWrite(stc(FileSize(nF)*51));
               D.descPtr := nP;
               Seek(fD,FilePos(fD)-1);
               Write(fD,D);
            end;
         end;
         Close(fD);
      end;
   end;
   Close(F);
   Close(nF);
   Erase(F);
   Rename(nF,cfg^.pathData+filefileDesc);
   ioTextAttr($07);
   ioGotoXY(1,20);
end;

begin
   New(Cfg);
   New(fArea);
   TextMode(co80);
   ioInitFastIO;
   ioClrScr;
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($0F);
   ioWriteLn('FilePack v'+bbsVersion+'  (c)Copyright 1995, Mike Fricker');
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($07);
   ioWriteLn('File description packing utility for Iniquity bulletin board systems');
   ioTextAttr($08);
   ioWrite(sRepeat('Ä',80));
   ioTextAttr($07);
   Assign(fC,fileConfig);
   {$I-}
   Reset(fC);
   {$I+}
   if ioResult <> 0 then
   begin
      ioWriteLn(fileConfig+' not found in current directory.');
      ioWriteLn('Please change to your Iniquity directory before executing this program.');
      fpError;
   end;
   Read(fC,Cfg^);
   Close(fC);
   Assign(ff,Cfg^.pathData+fileFileArea);
   {$I-}
   Reset(fF);
   {$I+}
   if ioResult <> 0 then
   begin
      ioWriteLn(fileFileArea+' not found in your data directory ('+Cfg^.pathData+').');
      ioWriteLn('Please ensure that this file exists before using this program.');
      fpError;
   end;

   fpPackDescFile;

   Close(fF);
   Dispose(Cfg);
   Dispose(fArea);
end.