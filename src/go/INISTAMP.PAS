program iniStamp;

uses Dos, Crt, Misc, Global, Files, Strings;

const
   iniEXE = 'INIQUITY.EXE';
   maxBuf = 8;
   maxRbuf = 20000;

var EXE : String; F : file;
    Buf : String[maxBuf];
    rBuf : array[1..maxRbuf] of Char;
    Found : Boolean;
    Pos : LongInt;
    Reg : String;
    X : Word;
    Read : Integer;
    Total, TotalRead : LongInt;

begin
   TextMode(co80);
   LocalIO := True;
   ModemOff := True;

   WriteLn(' '+bbsTitle+' Version '+bbsVersion+' Registration Stamp Utility');
   WriteLn(' (c)Copyright 1995, Mike Fricker - Release: '+bbsRelease);
   WriteLn;
   EXE := iniEXE;
   if not fExists(iniEXE) then
   begin
      WriteLn('-- '+iniEXE+' not found in current directory.');
      WriteLn;
      WriteLn('Enter full path and filename to '+iniEXE);
      Write(': ');
      ReadLn(EXE);
      WriteLn;
      if not fExists(EXE) then
      begin
         WriteLn('-- '+iniEXE+' not found in specified path.  Exiting.');
         Halt(255);
      end;
   end else WriteLn('-- '+iniEXE+' found in current directory.');
   Assign(F,EXE);
   Reset(F,1);
   FillChar(Buf[1],maxBuf,0);
   Buf[0] := Chr(8);
   Found := False;
   Write('-- Scanning '+iniEXE);
   Total := FileSize(F);
   TotalRead := 0;
   while (not Found) and (TotalRead < Total) and (not Eof(F)) do
   begin
      {$I-}
      BlockRead(F,rBuf,maxRbuf,Read);
      {$I+}
      Inc(TotalRead,Read);
      for X := 1 to Read do if not Found then
      begin
         Move(Buf[2],Buf[1],maxBuf-1);
         Buf[maxBuf] := rBuf[X];
         if Buf = Copy(regStamp,1,maxBuf) then
         begin
            Found := True;
            Pos := TotalRead-Read+X;
            FillChar(Reg,SizeOf(Reg),0);
            Seek(F,Pos);
            BlockRead(F,Reg[1],22);
            Reg[0] := Chr(22);
         end else Pos := 0;
      end;
   end;
   Close(F);
   WriteLn;
   if not Found then
   begin
      WriteLn;
      WriteLn('-- Registration locator not detected in file.');
      WriteLn('   Cannot continue registration process.');
      Halt(255);
   end;
   WriteLn('-- Locator found at position '+Stc(Pos)+' in '+EXE+'.');
   WriteLn;
   if Reg[1] <> ' ' then WriteLn('-- Currently registered to: '+mCrypt(Reg)) else
                         WriteLn('-- Currently unregistered.');
   WriteLn;
   Write('-- Enter registration: ');
   FillChar(Reg,SizeOf(Reg),0);
   ReadLn(Reg);
   if (Length(Reg) <= 22) and (Reg <> '') then
   begin
      Reg[0] := Chr(22);
      Reg := mCrypt(Reg);
      Reset(F,1);
      Seek(F,Pos);
      BlockWrite(F,Reg[1],22);
      Close(F);
      WriteLn('-- Registration complete.');
   end else WriteLn('-- Registration aborted.');
end.