{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config12;

interface

procedure cfgConferenceEditor(M : Boolean);

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, bbsInit,
     Conf, Logs;

var
  cF : file of tConfRec;
  Con : ^tConfRec;
  numC : ^Word;
  cS, lS : String;
  Msg : Boolean;

procedure cfgInsertConf;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   if numC^ >= maxConf then
   begin
      oCWriteLn('|U0You may only have a maximum of '+St(maxConf)+' '+ls+' conferences.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Insert before which '+ls+' conference? |U5[|U61|U5-|U6'+St(numC^+1)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numC^+1) or (I < 1) then Exit;

   Dec(I,1);

   Reset(cF);
   if ((I >= 0) and (I <= FileSize(cF))) and (numC^ < maxConf) then
   begin
      for Z := FileSize(cF)-1 downto I do
      begin
         Seek(cF,Z);
         Read(cF,Con^);
         Write(cF,Con^);
      end;
      confDefault(Msg);
      Seek(cF,I);
      Write(cF,Con^);
      Inc(numC^);
   end;
   Close(cF);
end;

procedure cfgMoveConf;
var K,X,Y,I,B : Word; J : Integer;
    mTemp : ^tConfRec;
begin
   oDnLn(2);
   if numC^ <= 1 then
   begin
      oCWriteLn('|U0There is only one '+ls+' conference, no need to move it.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Move which '+ls+' conference? |U5[|U61|U5-|U6'+St(numC^)+'|U5]: |U3');
   X := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (X > numC^) or (X < 1) then Exit;

   oCWrite('|U1Move before which '+ls+' conference? |U5[|U61|U5-|U6'+St(numC^+1)+'|U5]: |U3');
   Y := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (Y > numC^+1) or (Y < 1) then Exit;

   Dec(I,1);

   New(mTemp);
   Reset(cF);

   K := Y;
   if (Y > X) then Dec(Y);
   Dec(X);
   Dec(Y);
   Seek(cF,X);
   Read(cF,mTemp^);
   I := X;
   if (X > Y) then J := -1 else J := 1;
   while (I <> Y) do
   begin
      if (I+J < FileSize(cF)) then
      begin
         Seek(cF,I+J);
         Read(cF,Con^);
         Seek(cF,I);
         Write(cF,Con^);
      end;
      Inc(I,J);
   end;
   Seek(cF,Y);
   Write(cF,mTemp^);
   Inc(X);
   Inc(Y);
   {y:=k;}
   Close(cF);
   Dispose(mTemp);
{
   if ((I >= 0) and (I <= FileSize(cF))) and (numC^ < maxMsgArea) then
   begin
      for Z := FileSize(cF)-1 downto I do
      begin
         Seek(cF,Z);
         Read(cF,Con^);
         Write(cF,Con^);
      end;
      maReset;
      Seek(cF,I);
      Write(cF,Con^);
      Inc(numC^,1);
   end;}
end;

procedure cfgDeleteConf;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   if numC^ <= 1 then
   begin
      oCWriteLn('|U0You must have at least one '+ls+' conference.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Delete which '+ls+' conference? |U5[|U61|U5-|U6'+St(numC^)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numC^) or (I < 1) then Exit;

   Dec(I,1);

   Reset(cF);
   if (I >= 0) and (I <= FileSize(cF)-2) then
   for Z := I to FileSize(cF)-2 do
   begin
      Seek(cF,Z+1);
      Read(cF,Con^);
      Seek(cF,Z);
      Write(cF,Con^);
   end;
   Seek(cF,FileSize(cF)-1);
   Truncate(cF);
   Dec(numC^,1);
   Close(cF);
end;

procedure cfgEditConf;
var An, T : Byte; B : Boolean; Fil : String;
begin
   oDnLn(2);
   if numC^ = 0 then
   begin
      oCWriteLn('|U0Can''t continue.  No conferences exist.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Begin edit with which '+ls+' conference? |U5[|U61|U5-|U6'+St(numC^)+'|U5]: |U3');
   An := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (An > numC^) or (An < 1) then Exit;
   if Msg then User^.confMsg := An else User^.confFile := An;
   confLoad(Msg);

   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' '+cS+' Conference Editor');
      cfgItem('--Current Conference',3,St(An),'');
      cfgItem('A Key',1,Con^.Key,
              'Key used to select and identify this '+ls+' conference');
      cfgItem('B Description',30,Con^.Desc,
              'This '+ls+' conference''s description');
      cfgItem('C ACS',20,Con^.ACS,
              'Access condition required to enter this '+ls+' conference');
      cfgItem('[ Previous Conference',0,'','');
      cfgItem('] Next Conference',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Con^.Key,inUpper,chNormal,'',False);
                 Con^.Key := cfgRead[1];
                 cfgSetItem(Con^.Key);
              end;
        'B' : begin
                 cfgReadInfo(Con^.Desc,inNormal,chNormal,'',False);
                 Con^.Desc := cfgRead;
                 cfgSetItem(Con^.Desc);
              end;
        'C' : begin
                 cfgReadInfo(Con^.ACS,inLower,chNormal,'',False);
                 Con^.ACS := cfgRead;
                 cfgSetItem(Con^.ACS);
              end;
        '[' : begin
                 if Msg then User^.confMsg := An else
                             User^.confFile := An;
                 confSave(Msg);
                 if An = 1 then An := numC^ else Dec(An);
                 if Msg then User^.confMsg := An else
                             User^.confFile := An;
                 confLoad(Msg);
                 cfgDraw := True;
                 cfgOver := True;
              end;
        ']' : begin
                 if Msg then User^.confMsg := An else
                             User^.confFile := An;
                 confSave(Msg);
                 if An = numC^ then An := 1 else Inc(An);
                 if Msg then User^.confMsg := An else
                             User^.confFile := An;
                 confLoad(Msg);
                 cfgDraw := True;
                 cfgOver := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
   if Msg then User^.confMsg := An else
               User^.confFile := An;
   confSave(Msg);
end;

procedure cfgConferenceEditor(M : Boolean);
var cmdConfEdit : array[1..5] of String;
    oldArea : Word;
begin
   cfgDone := False;
   Msg := M;
   cmdConfEdit[1] := 'I nsert';
   cmdConfEdit[2] := 'D elete';
   cmdConfEdit[3] := 'E dit';
   cmdConfEdit[4] := 'M ove';
   cmdConfEdit[5] := 'Esc Quit';
   if Msg then
   begin
      cS := 'Message';
      lS := 'message';
      Con := @mConf^;
      oldArea := User^.confMsg;
      numC := @numMsgConf;
   end else
   begin
      cS := 'File';
      lS := 'file';
      Con := @fConf^;
      oldArea := User^.confFile;
      numC := @numFileConf;
   end;
   logWrite('*'+cS+' conference edit.');
   repeat
      oClrScr;
      cfgDraw := True;
      cfgOver := False;

      oSetCol(colText);
      PausePos := 1;
      PauseAbort := False;

      oWriteLn(' Num  Description                          ACS                  Key');
{                   4                         26         9      6      6    4       16}
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(2);

      if Msg then Assign(cF,Cfg^.pathData+fileConfMsg) else
                  Assign(cF,Cfg^.pathData+fileConfFile);
      {$I-}
      Reset(cF);
      {$I+}
      if ioResult <> 0 then
      begin
         confReset(Msg);
         Reset(cF);
      end;

      numC^ := 0;
      while (not PauseAbort) and (not Eof(cF)) do
      begin
         Read(cF,Con^);
         Inc(numC^);
         oSetCol(colInfo);
         oCWriteLn(' '+Resize(St(numC^),4)+
                   ' '+Resize(Con^.Desc,36)+
                   ' '+Resize(Con^.ACS,20)+
                   ' '+Con^.Key);
         oUpPause(1);
      end;
      Close(cF);
      if numC^ = 0 then oWriteLn('No '+ls+' conferences currently exist.');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
      PausePos := 0;
      cfgPrompt(cmdConfEdit,5);
      repeat
         cfgKey := UpCase(iReadkey);
      until (HangUp) or (cfgKey in ['I','D','E','M',#27]);
      if cfgKey = #27 then oWrite('Quit') else oWriteChar(cfgKey);
      case cfgKey of
        'I' : cfgInsertConf;
        'D' : cfgDeleteConf;
        'E' : cfgEditConf;
        'M' : cfgMoveConf;
        #27 : cfgDone := True;
      end;
   until (HangUp) or (cfgDone);
   if Msg then User^.confMsg := oldArea else User^.confFile := oldArea;
   if User^.confMsg > numMsgConf then User^.confMsg := 1;
   if User^.confFile > numFileConf then User^.confFile := 1;
   if UserOn then confLoad(Msg);
end;

end.