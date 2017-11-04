{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config15;

interface

procedure cfgBbsListEditor;

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, bbsInit,
     Logs, bbsList;

var eF : file of tBbsListRec;
    BBS : tBbsListRec;
    numBBS : Word;

procedure cfgInsertBBS;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   oCWrite('|U1Insert before which BBS? |U5[|U61|U5-|U6'+St(numBBS+1)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if I < 1 then Exit;
   Dec(I);

   Reset(eF);
   if (I >= 0) and (I <= FileSize(eF)) then
   begin
      for Z := FileSize(eF)-1 downto I do
      begin
         Seek(eF,Z);
         Read(eF,BBS);
         Write(eF,BBS);
      end;
      FillChar(BBS,SizeOf(BBS),0);
      with BBS do
      begin
         Name := 'New BBS entry';
         SysOp := 'Someone';
         Phone := '(000)000-0000';
         Baud := 0;
         Software := bbsTitle;
         Storage := '??? mb';
         Info := 'None';
         WhoAdded := User^.Username;
      end;
      Seek(eF,I);
      Write(eF,BBS);
      Inc(numBBS);
   end;
   Close(eF);
end;

procedure cfgMoveBBS;
var K,X,Y,I,B : Word; J : Integer;
    mTemp : tBbsListRec;
begin
   oDnLn(2);
   if numBBS <= 1 then
   begin
      oCWriteLn('|U0There is only one BBS, no need to move it.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Move which BBS? |U5[|U61|U5-|U6'+St(numBBS)+'|U5]: |U3');
   X := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (X > numBBS) or (X < 1) then Exit;

   oCWrite('|U1Move before which BBS? |U5[|U61|U5-|U6'+St(numBBS+1)+'|U5]: |U3');
   Y := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (Y > numBBS+1) or (Y < 1) then Exit;

   Dec(I,1);

   Reset(eF);

   K := Y;
   if (Y > X) then Dec(Y);
   Dec(X);
   Dec(Y);
   Seek(eF,X);
   Read(eF,mTemp);
   I := X;
   if (X > Y) then J := -1 else J := 1;
   while (I <> Y) do
   begin
      if (I+J < FileSize(eF)) then
      begin
         Seek(eF,I+J);
         Read(eF,BBS);
         Seek(eF,I);
         Write(eF,BBS);
      end;
      Inc(I,J);
   end;
   Seek(eF,Y);
   Write(eF,mTemp);
   Inc(X);
   Inc(Y);
   {y:=k;}
   Close(eF);
{
   if ((I >= 0) and (I <= FileSize(eF))) and (numBBS < maxBBS) then
   begin
      for Z := FileSize(eF)-1 downto I do
      begin
         Seek(eF,Z);
         Read(eF,BBS);
         Write(eF,BBS);
      end;
      maReset;
      Seek(eF,I);
      Write(eF,BBS);
      Inc(numBBS,1);
   end;}
end;

procedure cfgDeleteBBS;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   if numBBS <= 1 then
   begin
      oCWriteLn('|U0You must have at least one BBS!');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Delete which BBS? |U5[|U61|U5-|U6'+St(numBBS)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numBBS) or (I < 1) then Exit;

   Dec(I,1);

   Reset(eF);
   if (I >= 0) and (I <= FileSize(eF)-2) then
   for Z := I to FileSize(eF)-2 do
   begin
      Seek(eF,Z+1);
      Read(eF,BBS);
      Seek(eF,Z);
      Write(eF,BBS);
   end;
   Seek(eF,FileSize(eF)-1);
   Truncate(eF);
   Dec(numBBS,1);
   Close(eF);
end;

procedure cfgEditBBS;
var Bn : Word;
begin
   oDnLn(2);
   if numBBS = 0 then Exit;
   oCWrite('|U1Begin edit with which BBS? |U5[|U61|U5-|U6'+St(numBBS)+'|U5]: |U3');
   Bn := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (Bn > numBBS) or (Bn < 1) then Exit;
   bbsLoadBBS(BBS,Bn);
   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' BBS List Editor');
      cfgCol := 20;
      cfgItem('--Current',12,St(Bn)+' of '+St(numBBS),'');
      cfgItem('A Name',40,BBS.Name,
              'The name of this bulletin board system');
      cfgItem('B SysOp',36,BBS.SysOp,
              'The SysOp''s name or handle');
      cfgItem('C Phone Number',13,BBS.Phone,
              'The BBS''s phone number (w/area code)');
      cfgItem('D Baudrate',6,St(BBS.Baud),
              'The maximum baudrate of this BBS');
      cfgItem('E Software',12,BBS.Software,
              'Name of the bulletin board software this system is running');
      cfgItem('F Storage',20,BBS.Storage,
              'Maximum file area storage (usually in megabytes)');
      cfgItem('G Other Info',58,BBS.Info,
              'Any other information about this board (ie affiliations)');
      cfgItem('H Who added',36,BBS.WhoAdded,
              'The name of the user that added this BBS to the list');
      cfgItem('[ Previous BBS',0,'','');
      cfgItem('] Next BBS',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(BBS.Name,inNormal,chNormal,'',False);
                 BBS.Name := cfgRead;
                 cfgSetItem(BBS.Name);
              end;
        'B' : begin
                 cfgReadInfo(BBS.SysOp,inNormal,chNormal,'',False);
                 BBS.SysOp := cfgRead;
                 cfgSetItem(BBS.SysOp);
              end;
        'C' : begin
                 cfgReadPhone;
                 BBS.Phone := cfgRead;
                 cfgSetItem(BBS.Phone);
              end;
        'D' : begin
                 cfgReadInfo(St(BBS.Baud),inUpper,chNumeric,'',True);
                 BBS.Baud := mClip(StrToInt(cfgRead),300,64000);
                 cfgSetItem(St(BBS.Baud));
              end;
        'E' : begin
                 cfgReadInfo(BBS.Software,inNormal,chNormal,'',False);
                 BBS.Software := cfgRead;
                 cfgSetItem(BBS.Software);
              end;
        'F' : begin
                 cfgReadInfo(BBS.Storage,inNormal,chNormal,'',False);
                 BBS.Storage := cfgRead;
                 cfgSetItem(BBS.Storage);
              end;
        'G' : begin
                 cfgEditInfo(BBS.Info,75,inNormal,chNormal,'',False);
                 BBS.Info := cfgRead;
                 cfgSetItem(BBS.Info);
              end;
        'H' : begin
                 cfgReadInfo(BBS.WhoAdded,inNormal,chNormal,'',False);
                 BBS.WhoAdded := cfgRead;
                 cfgSetItem(BBS.WhoAdded);
              end;
        '[' : begin
                 bbsSaveBBS(BBS,Bn);
                 if Bn = 1 then Bn := numBBS else Dec(Bn);
                 bbsLoadBBS(BBS,Bn);
                 cfgDraw := True;
                 cfgOver := True;
              end;
        ']' : begin
                 bbsSaveBBS(BBS,Bn);
                 if Bn = numBBS then Bn := 1 else Inc(Bn);
                 bbsLoadBBS(BBS,Bn);
                 cfgDraw := True;
                 cfgOver := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
   bbsSaveBBS(BBS,Bn);
end;

procedure cfgBbsListEditor;
var cmdbbsEdit : array[1..5] of String;
begin
   cmdbbsEdit[1] := 'I nsert';
   cmdbbsEdit[2] := 'D elete';
   cmdbbsEdit[3] := 'E dit';
   cmdbbsEdit[4] := 'M ove';
   cmdbbsEdit[5] := 'Esc Quit';

   cfgDone := False;
   logWrite('*BBS list edit.');
   repeat
      oClrScr;
      cfgDraw := True;
      cfgOver := False;
      PausePos := 1;
      PauseAbort := False;

      oSetCol(colText);
      oWriteLn(' Num  BBS Name                    SysOp                  Baud    Software');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(2);

      numBBS := 0;

      Assign(eF,Cfg^.pathData+fileBbsList);
      {$I-}
      Reset(eF);
      {$I+}
      if ioResult <> 0 then Exit;
      while (not PauseAbort) and (not Eof(eF)) do
      begin
         Read(eF,BBS);
         Inc(numBBS);
         oSetCol(colInfo);
         oCWriteLn(' '+Resize(St(numBBS),4)+
                   ' '+Resize(BBS.Name,27)+
                   ' '+Resize(BBS.SysOp,22)+
                   ' '+Resize(St(BBS.Baud),7)+
                   ' '+strSquish(BBS.Software,12));
         oUpPause(1);
      end;
      Close(eF);
      if numBBS = 0 then oWriteLn('No BBSs currently exist.');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
      PausePos := 0;
      cfgPrompt(cmdbbsEdit,5);
      repeat
         cfgKey := UpCase(iReadkey);
      until (HangUp) or (cfgKey in ['I','D','E','M',#27]);
      if cfgKey = #27 then oWrite('Quit') else oWriteChar(cfgKey);
      case cfgKey of
        'I' : cfgInsertBBS;
        'D' : cfgDeleteBBS;
        'E' : cfgEditBBS;
        'M' : cfgMoveBBS;
        #27 : cfgDone := True;
      end;
   until (HangUp) or (cfgDone);
end;

end.