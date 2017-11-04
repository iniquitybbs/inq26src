{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,N-,E+}
unit BBSlist;

interface

uses Global;

procedure bbsListAddtoList;
procedure bbsListClear(Ask : Boolean);
procedure bbsListDeleteOne(X : Word; Ask : Boolean);
procedure bbsListShowOne(X : Word);
function  bbsListShowAll : Word;
function  bbsLoadBBS(var B : tBBSlistRec; N : Word) : Boolean;
procedure bbsSaveBBS(var B : tBBSlistRec; N : Word);

implementation

uses
   Output, Input, StrProc, ShowFile, Files, Misc, Logs;

procedure bbsListAdd(var B : tBBSlistRec);
var F : file of tBBSlistRec; N : Word; T : tBBSlistRec; Done : Boolean;
begin
   Assign(F,Cfg^.pathData+fileBBSlist);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Rewrite(F) else Seek(F,FileSize(F));
   Write(F,B);
   Close(F);
end;

function bbsSearchBBS(var B : tBBSlistRec) : Boolean;
var F : file of tBBSlistRec; T : tBBSlistRec; Done : Boolean; S : String;
    Un, N : Integer;
begin
   bbsSearchBBS := False;
   Assign(F,Cfg^.pathData+fileBBSlist);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Done := False;
   while (not Eof(F)) and (not Done) do
   begin
      Read(F,T);
      Done := (B.Phone = T.Phone) or (UpStr(B.Name) = UpStr(T.Name));
   end;
   Close(F);
   bbsSearchBBS := Done;
end;

procedure bbsSaveBBS(var B : tBBSlistRec; N : Word);
var F : file of tBBSlistRec;
begin
   Assign(F,Cfg^.pathData+fileBBSlist);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Seek(F,N-1);
   Write(F,B);
   Close(F);
end;

function bbsLoadBBS(var B : tBBSlistRec; N : Word) : Boolean;
var F : file of tBBSlistRec;
begin
   bbsLoadBBS := False;
   Assign(F,Cfg^.pathData+fileBBSlist);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Seek(F,N-1);
   {$I-}
   Read(F,B);
   {$I+}
   bbsLoadBBS := ioResult = 0;
   Close(F);
end;

procedure bbsListAddtoList;
var bbs : tBBSlistRec; Ans : Boolean;
begin
   bbs.WhoAdded := User^.UserName;
   Ans := sfShowTextFile(txAddBBS,ftAddBBS);
   if not Ans then oDnLn(1);
   if not sfGotoPos(1) then oString(strBBSaskName);
   bbs.Name := iReadString('',inNormal,chNormal,'',40);
   if bbs.Name = '' then Exit;
   if not sfGotoPos(2) then oString(strBBSaskPhone);
   bbs.Phone := iReadPhone('');
   if bbsSearchBBS(bbs) then
   begin
      if not sfGotoPos(8) then oDnLn(1);
      logWrite('Tried to add entry to BBS list ('+bbs.Name+'); already existed');
      oStringLn(strBBSexists);
      oDnLn(1);
      Exit;
   end;
   if not sfGotoPos(3) then oString(strBBSaskSysOp);
   bbs.SysOp := iReadString('',inNormal,chNormal,rsMin,36);
   if not sfGotoPos(4) then oString(strBBSaskBaud);
   bbs.Baud := StrtoInt(iReadString('',inNormal,chNumeric,rsMin,6));
   if not sfGotoPos(5) then oString(strBBSaskSoftware);
   bbs.Software := iReadString('',inNormal,chNormal,rsMin,12);
   if not sfGotoPos(6) then oString(strBBSaskStorage);
   bbs.Storage := iReadString('',inNormal,chNormal,rsMin,20);
   if not sfGotoPos(7) then oString(strBBSaskInfo);
   bbs.Info := iReadString('',inNormal,chNormal,'',75);
   if bbs.Info = '' then bbs.Info := 'None';
   if not sfGotoPos(8) then oDnLn(1);
   oString(strBBSaskSaveBBS);
   if iYesNo(True) then
   begin
      if sfGotoPos(8) then oClrEol;
      oString(strBBSsavingEntry);
      bbsListAdd(bbs);
      logWrite('Entry added to BBS list');
   end else logWrite('User aborted add to BBS list');
   oDnLn(1);
end;

function bbsListShowAll : Word;
var Ans : Boolean; B : file of tBBSlistRec; bbs : tBBSlistRec; N : Word;
begin
   bbsListShowAll := 0;
   logWrite('Displayed BBS list');
   Assign(B,Cfg^.pathData+fileBBSlist);
   {$I-}
   Reset(B);
   {$I+}
   if ioResult <> 0 then
   begin
      oDnLn(1);
      oStringLn(strBBSnoSystems);
      Exit;
   end;
   if FileSize(B) < 1 then
   begin
      oDnLn(1);
      Close(B);
      oStringLn(strBBSnoSystems);
      Exit;
   end;
   PausePos := 1;
   PauseAbort := False;
   Ans := (sfGetTextFile(txBbsLtop,ftTopLine) <> '') and
          (sfGetTextFile(txBbsLmid,ftBBSlist) <> '') and
          (sfGetTextFile(txBbsLbot,ftNormal)  <> '');
   if Ans then
   begin
      sfShowTextFile(txBbsLtop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txBbsLmid);
   end else
   begin
      oDnLn(1);
      oSetCol(colInfo);
      oWriteLn(' Num  BBS Name                  Phone Number     Software        Baudrate');
               { 2    7   11                    33               50              66 }
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(3);
      oSetCol(colText);
   end;
   N := 0;
   while (not HangUp) and (not Eof(B)) and (not PauseAbort) do
   begin
      Read(B,bbs);
      Inc(N);
      if Ans then
      begin
         sfStr[1] := bbs.Name;
         sfStr[2] := bbs.Phone;
         sfStr[3] := bbs.SysOp;
         sfStr[4] := St(bbs.Baud);
         sfStr[5] := bbs.Software;
         sfStr[6] := bbs.Storage;
         sfStr[7] := bbs.Info;
         sfStr[8] := St(N);
         sfShowRepeat(ftBBSlist);
         if oWhereX <> 1 then oDnLn(1);
         oUpPause(1);
      end else
      begin
         oWriteLn(' '+Resize(St(N),4)+
                  ' '+Resize(bbs.Name,25)+
                  ' '+Resize(bbs.Phone,16)+
                  ' '+Resize(bbs.Software,15)+
                  ' '+strSquish(St(bbs.Baud),10));
         oUpPause(1);
      end;
   end;
   sfKillRepeat;
   bbsListShowAll := N;
   Close(B);
   if Ans then
   begin
      sfShowTextFile(txBbsLbot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
   end;
   PausePos := 0;
end;

procedure bbsListShowOne(X : Word);
var N : Word; S : String; bbs : tBBSlistRec; Ans, Ok : Boolean;
begin
   logWrite('Displayed entry from BBS list');
   Ok := (X <> 0) and (bbsLoadBBS(bbs,X));
   if not Ok then
   begin
      N := bbsListShowAll;
      if N = 0 then Exit;
      oStr(strCode(mStr(strBBSshowOne),1,St(N)));
      S := iReadString('',inUpper,chNumeric,'',3);
      X := strToInt(S);
      if (S = '') or (X < 1) or (X > N) or (not bbsLoadBBS(bbs,X)) then Exit;
   end else N := 0;
   sfStr[1] := bbs.Name;
   sfStr[2] := bbs.Phone;
   sfStr[3] := bbs.SysOp;
   sfStr[4] := St(bbs.Baud);
   sfStr[5] := bbs.Software;
   sfStr[6] := bbs.Storage;
   sfStr[7] := bbs.Info;
   sfStr[8] := St(X);
   Ans := sfShowTextFile(txShowBBS,ftBBSlist);
   if not Ans then
   begin
      oDnLn(1);
      if X = 0 then S := St(X) else S := St(X)+'|U2 of |U3'+St(N);
      oCWriteLn('|U1List Number      |U2: |U3'+S);
      oCWriteLn('|U1System Name      |U2: |U3'+bbs.Name);
      oCWriteLn('|U1Phone Number     |U2: |U3'+bbs.Phone);
      oCWriteLn('|U1SysOp Name/Alias |U2: |U3'+bbs.SysOp);
      oCWriteLn('|U1Baudrate         |U2: |U3'+St(bbs.Baud));
      oCWriteLn('|U1Software         |U2: |U3'+bbs.Software);
      oCWriteLn('|U1Storage          |U2: |U3'+bbs.Storage);
      if bbs.Info <> 'None' then
      begin
         oCWriteLn('|U1Other Info |U2--');
         oCWriteLn('|U2: |U3'+bbs.Info);
      end;
   end;
   logWrite('BBS displayed: "'+bbs.Name+'".');
   oDnLn(1);
end;

procedure bbsListDelete(X : Word);
var F : file of tBBSlistRec; N : Word; B : tBBSlistRec;
begin
   Assign(F,Cfg^.pathData+fileBBSlist);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Seek(F,X-1);
   {$I-}
   Read(F,B);
   {$I+}
   N := X;
   if (not (acsOk(Cfg^.acsCoSysOp) or (User^.UserName = B.WhoAdded))) or
      (ioResult <> 0) then begin Close(F); Exit; end;
   if Eof(F) then Seek(F,X-1) else
   begin
      Seek(F,N);
      repeat
         Read(F,B);
         Seek(F,N-1);
         Write(F,B);
         Inc(N,1);
         Seek(F,N);
      until Eof(F);
      Seek(F,N-1);
   end;
   Truncate(F);
   Close(F);
end;

procedure bbsListDeleteOne(X : Word; Ask : Boolean);
var N : Word; S : String; bbs : tBBSlistRec; Ok : Boolean;
begin
   Ok := (X <> 0) and (bbsLoadBBS(bbs,X));
   if not Ok then
   begin
      N := bbsListShowAll;
      if N = 0 then Exit;
      oStr(strCode(mStr(strBBSdeleteOne),1,St(N)));
      S := iReadString('',inUpper,chNumeric,'',3);
      X := strToInt(S);
      if (S = '') or (X < 1) or (X > N) or (not bbsLoadBBS(bbs,X)) then Exit;
   end else N := 0;
   oDnLn(1);
   Ok := True;
   if Ask then
   begin
      oString(strBBSverifyKill);
      Ok := iYesNo(False);
   end;
   if Ok then
   begin
      bbsListDelete(X);
      logWrite('*Removed BBS number '+St(X)+' from BBS list');
   end;
end;

procedure bbsListClear(Ask : Boolean);
var Ok : Boolean;
begin
   Ok := True;
   if Ask then
   begin
      oString(strBBSclearAll);
      Ok := iYesNo(False);
   end;
   if Ok then
   begin
      fDeleteFile(Cfg^.pathData+fileBBSlist);
      logWrite('*Entire BBS list deleted');
   end;
end;

end.
