{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config16;

interface

procedure cfgTextLibEditor;

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, bbsInit,
     Logs;

var faT : file of tTextLibRec;
    tl : tTextLibRec;

procedure cfgInsertTextLib;
var I,X,Z,B : Byte; S : String[8];
begin
   oDnLn(1);
   oCWrite('|U1Insert before which library|U2? |U5[|U61|U5-|U6'+St(numLib+1)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numLib+1) or (I < 1) then Exit;

   oCWrite('|U1Enter library filename (no extension)|U2: |U3');
   S := iReadString('',inUpper,chFileNoExt,'',8);
   if (S = '') or (not fExists(Cfg^.pathLibs+S+extTextLib)) then Exit;

   Dec(I);

   if numLib = 0 then
   begin
      Rewrite(faT);
      FillChar(tl,sizeOf(tl),0);
      tl.Filename := S;
      Write(faT,tl);
      numInfo := 1;
   end else
   begin
      Reset(faT);
      if (I >= 0) and (I <= FileSize(faT)) then
      begin
         for Z := FileSize(faT)-1 downto I do
         begin
            Seek(faT,Z);
            Read(faT,tl);
            Write(faT,tl);
         end;
         FillChar(tl,sizeOf(tl),0);
         tl.Filename := S;
         Seek(faT,I);
         Write(faT,tl);
         Inc(numLib);
      end;
   end;
   Close(faT);
end;

procedure cfgEditTextLib;
var I,X,Z,B : Byte; S : String[8];
begin
   oDnLn(1);
   oCWrite('|U1Edit which text library|U2? |U5[|U61|U5-|U6'+St(numLib)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numLib) or (I < 1) then Exit;
   Reset(faT);
   Seek(faT,I-1);
   Read(faT,tl);

   oCWrite('|U1Enter new library filename (no extension)|U2: |U3');
   S := iReadString(tl.Filename,inUpper,chFileNoExt,'',8);
   if (S <> '') and (fExists(Cfg^.pathLibs+S+extTextLib)) then
   begin
      Seek(faT,I-1);
      tl.Filename := S;
      Write(faT,tl);
   end;
   Close(faT);
end;

procedure cfgDeleteTextLib;
var I,X,Z,B : Byte;
begin
   oDnLn(1);
   if numLib < 1 then
   begin
      oCWriteLn('|U0No text libraries are installed.');
      oDnLn(1);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Delete which text library|U2? |U5[|U61|U5-|U6'+St(numLib)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numLib) or (I < 1) then Exit;

   Dec(I);

   Reset(faT);
   if (I >= 0) and (I <= FileSize(faT)-2) then
   for Z := I to FileSize(faT)-2 do
   begin
      Seek(faT,Z+1);
      Read(faT,tl);
      Seek(faT,Z);
      Write(faT,tl);
   end;
   Seek(faT,FileSize(faT)-1);
   Truncate(faT);
   Dec(numLib);
   Close(faT);
   if (fExists(Cfg^.pathLibs+tl.Filename+extTextLib)) then
   begin
      oDnLn(1);
      oCWrite('|U1Erase actual library file|U2? ');
      if iYesNo(False) then fDeleteFile(Cfg^.pathLibs+tl.Filename+extTextLib);
   end;
end;

procedure cfgMoveTextLib;
var K,X,Y,I,B : Word; J : Integer; ttl : tTextLibRec;
begin
   oDnLn(1);
   if numLib = 1 then
   begin
      oCWriteLn('|U0There is only one text library, no need to move it.');
      oDnLn(1);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Move which text library|U2? |U5[|U61|U5-|U6'+St(numLib)+'|U5]: |U3');
   X := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (X > numLib) or (X < 1) then Exit;

   oCWrite('|U1Move before which library|U2? |U5[|U61|U5-|U6'+St(numLib+1)+'|U5]: |U3');
   Y := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (Y > numLib+1) or (Y < 1) then Exit;

   Dec(I);

   Reset(faT);

   K := Y;
   if (Y > X) then Dec(Y);
   Dec(X);
   Dec(Y);
   Seek(faT,X);
   Read(faT,ttl);
   I := X;
   if (X > Y) then J := -1 else J := 1;
   while (I <> Y) do
   begin
      if (I+J < FileSize(faT)) then
      begin
         Seek(faT,I+J);
         Read(faT,tl);
         Seek(faT,I);
         Write(faT,tl);
      end;
      Inc(I,J);
   end;
   Seek(faT,Y);
   Write(faT,ttl);
   Inc(X);
   Inc(Y);
   {y:=k;}
   Close(faT);
{
   if ((I >= 0) and (I <= FileSize(faT))) and (numLib < maxMsgArea) then
   begin
      for Z := FileSize(faT)-1 downto I do
      begin
         Seek(faT,Z);
         Read(faT,mArea^);
         Write(faT,mArea^);
      end;
      maReset;
      Seek(faT,I);
      Write(faT,mArea^);
      Inc(numLib,1);
   end;}
end;

procedure cfgListTextLibs;
var F : file; A, D : String; Ls : Byte;
begin
   oClrScr;
   PausePos := 1;
   PauseAbort := False;
   oSetCol(colText);
   oCWriteLn(' '+Resize('Num',4)+
             ' '+Resize('Filename',10)+
             ' '+Resize('Description',25)+
             ' '+Resize('Author',25)+
             ' '+strSquish('Files',5));
   oSetCol(colBorder);
   oWriteLn(sRepeat('Ä',79));
   oUpPause(2);

   numLib := 0;

   Assign(faT,Cfg^.pathData+fileTextLib);
   {$I-}
   Reset(faT);
   {$I+}
   oSetCol(colInfo);
   if ioResult = 0 then
   begin
      while (not PauseAbort) and (not Eof(faT)) do
      begin
         Read(faT,tl);
         Inc(numLib);
         Assign(f,Cfg^.pathLibs+tl.Filename+extTextLib);
         {$I-}
         Reset(f,1);
         {$I+}
         if ioResult <> 0 then
         begin
            Ls := 0;
            A  := '---';
            D  := 'Error loading file';
         end else
         begin
            BlockRead(f,Ls,1);
            BlockRead(f,D,SizeOf(textLib^.Desc));
            BlockRead(f,A,SizeOf(textLib^.Author));
            Close(f);
         end;
         oSetCol(colInfo);
         oCWriteLn(' '+Resize(St(numLib),4)+
                   ' '+Resize(tl.Filename,10)+
                   ' '+Resize(D,25)+
                   ' '+Resize(A,25)+
                   ' '+strSquish(St(Ls),3));
         oUpPause(1);
      end;
      Close(faT);
   end;
   if numLib = 0 then oWriteLn('No text libraries are currently installed.');
   oSetCol(colBorder);
   oWriteLn(sRepeat('Ä',79));
   oUpPause(1);
   PausePos := 0;
end;

procedure cfgTextLibEditor;
var cmdTlEdit : array[1..5] of String;
    oldLib : Word;
begin
   cmdTlEdit[1] := 'I nsert';
   cmdTlEdit[2] := 'D elete';
   cmdTlEdit[3] := 'E dit';
   cmdTlEdit[4] := 'M ove';
   cmdTlEdit[5] := 'Esc Quit';
   cfgDone := False;
   oldLib := User^.textLib;
   logWrite('*Textfile library edit');
   repeat
      cfgDraw := True;
      cfgOver := False;

      cfgListTextLibs;

      cfgPrompt(cmdTlEdit,5);
      repeat
         cfgKey := UpCase(iReadkey);
      until (HangUp) or (cfgKey in ['M','I','D','E',#27]);
      if cfgKey = #27 then oWrite('Quit') else oWriteChar(cfgKey);
      oDnLn(1);
      case cfgKey of
        'I' : cfgInsertTextLib;
        'D' : cfgDeleteTextLib;
        'E' : if numLib > 0 then cfgEditTextLib;
        'M' : if numLib > 0 then cfgMoveTextLib;
        #27 : cfgDone := True;
      end;
   until (HangUp) or (cfgDone);
   User^.textLib := oldLib;
{ ----------------- load it }
end;

end.