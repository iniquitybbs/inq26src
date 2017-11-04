{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit FileArea;

interface

uses Global;

procedure faAskListFiles;
procedure faBatchAdd(Par : String);
function  faChangeArea(Area : Word) : Boolean;
function  faCloseEnough(f1,f2 : String) : Boolean;
procedure faDownload(Par : String);
procedure faDownloadAny(Par : String);
procedure faEditFileDesc(var Fil : tFileRec);
procedure faFindAreaWithAccess;
procedure faGetFileInfo(Par : String);
function  faIsSponsor : Boolean;
procedure faKillDesc(var F : tFileRec; var Desc : pFileDesc);
procedure faListAreas(Change : Boolean);
function  faListFiles(Scn : Boolean; Idx : pFileScanIdx; idxFiles : Word) : Boolean;
function  faLoad : Boolean;
procedure faLoadDesc(var aFile : tFileRec; var Desc : pFileDesc);
function  faLoadDescFile(Fn : String; var P : pFileDesc) : Word;
function  faLoadFile(N : Word; var D : tFileRec) : Boolean;
procedure faLocalUpload;
procedure faNewScanAsk(Par : String);
procedure faNextArea;
procedure faPrevArea;
procedure faReset;
procedure faSave;
function  faSaveFile(N : Word; var D : tFileRec) : Boolean;
procedure faSearchFile(fs : Boolean);
procedure faSetNewScanDate;
function  faTestFile(Fn : String) : Boolean;
procedure faUpload;
procedure faViewFile(Par : String);

var pDesc    : pFileDesc;
    nDescLns : Word;

implementation

uses Dos,
     Strings, Misc, Output, Input, Logs, ShowFile, DateTime, Files, Comm,
     Archive, Users, Transfer, Stats, History, Config13, fsEditor, Sauce;

var skipOk : Boolean;

procedure faReset;
begin
   with fArea^ do
   begin
      Name     := 'New '+bbsTitle+' file area';
      Filename := 'NEWAREA';
      Path     := StartDir;
      Sponsor  := Cfg^.SysOpAlias;
      acs      := 's25';
      acsUL    := 's50';
      acsDL    := 's50';
      Password := '';
      Files    := 0;
      SortType := sortFilename;
      SortAcen := True;
   end;
end;

function faCloseEnough(f1,f2 : String) : Boolean;
begin
   f1 := UpStr(f1);
   f2 := UpStr(f2);
   faCloseEnough := (f1 = f2) or
                    ((Pos('.',f1) = 0) and
                     (Pos('.',f2) > 0) and
                     (f1 = Copy(f2,1,Pos('.',f2)-1)));
end;

function faLoad : Boolean;
var F : file of tFileAreaRec;
begin
   faLoad := False;
   Assign(F,Cfg^.pathData+fileFileArea);
   {$I-}
   Reset(F);
   if ioResult = 0 then numFileArea := FileSize(F) else Exit;
   {$I+}
   if (User^.curFileArea < 1) or (User^.curFileArea > numFileArea) then
   begin
      Close(F);
      Exit;
   end;
   {$I-}
   Seek(F,User^.curFileArea-1);
   Read(F,fArea^);
   {$I+}
   faLoad := ioResult = 0;
   Close(F);
end;

procedure faSave;
var F : file of tFileAreaRec;
begin
   Assign(F,Cfg^.pathData+fileFileArea);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult = 0 then numFileArea := FileSize(F) else Exit;
   if (User^.curFileArea < 1) or (User^.curFileArea > numFileArea) then
   begin
      Close(F);
      Exit;
   end;
   Seek(F,User^.curFileArea-1);
   {$I-}
   Write(F,fArea^);
   numFileArea := FileSize(F);
   {$I+}
   Close(F);
end;

function faHasAccess : Boolean;
begin
   faHasAccess := acsOk(fArea^.Acs);
end;

function faIsSponsor : Boolean;
begin
   faIsSponsor := (faHasAccess) and ((UpStr(User^.UserName) = UpStr(fArea^.Sponsor)) or
                                     (UpStr(User^.RealName) = UpStr(fArea^.Sponsor)));
end;

function faHasULaccess : Boolean;
begin
   faHasULaccess := acsOk(fArea^.AcsUL);
end;

function faHasDLaccess : Boolean;
begin
   faHasDLaccess := acsOk(fArea^.AcsDL);
end;

function faChangeArea(Area : Word) : Boolean;
var OldArea : Word; Ok : Boolean; Pw : String;
begin
   faChangeArea := False;
   if (Area < 1) or (Area > numFileArea) then Exit;
   OldArea := User^.curFileArea;
   User^.curFileArea := Area;
   Ok := (faLoad) and (faHasAccess);
   if (Ok) and (fArea^.Password <> '') then
   begin
      oString(strFaAskPassword);
      Pw := iReadString('',inUpper,chNormal,rsPassword,20);
      Ok := Pw = UpStr(fArea^.Password);
   end;
   if not Ok then
   begin
      User^.curFileArea := OldArea;
      faLoad;
      Exit;
   end;
   logWrite('Changed to file area: '+fArea^.Name);
   faChangeArea := True;
end;

procedure faListAreas(Change : Boolean);
var Ans, Hil : Boolean; F : file of tFileAreaRec; A : tFileAreaRec; N, cN : Word;
    S : String; Ref : array[1..maxFileArea] of Word;
begin
   if not Change then logWrite('Listed file areas');
   Assign(F,Cfg^.pathData+fileFileArea);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Ans := (sfGetTextFile(txListFareaTop,ftTopLine) <> '') and
          (sfGetTextFile(txListFareaMid,ftListFarea) <> '') and
          (sfGetTextFile(txListFareaBot,ftNormal) <> '');
   Hil := (not Ans) or (sfGetTextFile(txListFareaHil,ftListFarea) <> '');
   PausePos := 1;
   PauseAbort := False;
   if Ans then
   begin
      sfShowTextFile(txListFareaTop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txListFareaMid);
   end else
   begin
      oClrScr;
      oDnLn(1);
      oSetCol(colInfo);
      oCWriteLn(' Num    Area Title                     Files   Sponsor');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(2);
   end;
   N := 0;
   cN := 0;
   FillChar(Ref,SizeOf(Ref),0);
   while not Eof(F) do
   begin
      Read(F,A);
      Inc(N);
      if not Cfg^.compFileAreas then
      begin
         Inc(cN);
         Ref[cN] := N;
      end;
      if acsOk(A.Acs) then
      begin
         if Cfg^.compFileAreas then
         begin
            Inc(cN);
            Ref[cN] := N;
         end;
         if PauseAbort then begin end else
         if Ans then
         begin
            sfStr[1] := A.Name;
            sfStr[2] := St(cN);
            sfStr[3] := Stc(A.Files);
            sfStr[4] := A.Sponsor;
            if (Hil) and (N = User^.curFileArea) then
            begin
               sfKillRepeat;
               sfLoadRepeat(txListFareaHil);
               sfShowRepeat(ftListFarea);
               sfKillRepeat;
               sfLoadRepeat(txListFareaMid);
            end else sfShowRepeat(ftListFarea);
            if oWhereX <> 1 then oDnLn(1);
            oUpPause(1);
         end else
         begin
            if N = User^.curFileArea then oSetCol(colTextHi) else oSetCol(colText);
            oWriteLn(' '+Resize(St(cN),6)+
                     ' '+Resize(A.Name,30)+
                     ' '+Resize(Stc(A.Files),7)+
                     ' '+strSquish(A.Sponsor,36));
            oUpPause(1);
         end;
      end;
   end;
   sfKillRepeat;
   Close(F);
   if Ans then
   begin
      sfShowTextFile(txListFareaBot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
   end;
   PausePos := 0;
   if Change then
   begin
      oString(strFaAskChangeArea);
      S := iReadString('',inUpper,chNumeric,'',4);
      N := strToInt(S);
      if (S <> '') and (N > 0) and (N <= cN) and (faChangeArea(Ref[N])) then
         oStrLn(strCode(mStr(strFaChangedAreas),1,fArea^.Name));
   end;
end;

procedure faPrevArea;
var A, oa : Word; Found : Boolean;
begin
   oa := User^.curFileArea;
   Found := False;
   while (not Found) and (User^.curFileArea > 1) do
   begin
      Dec(User^.curFileArea);
      Found := faChangeArea(User^.curFileArea);
   end;
   if not Found then
   begin
      User^.curFileArea := oa;
      faLoad;
      oStringLn(strFaLowestArea);
   end else oStrLn(strCode(mStr(strFaChangedAreas),1,fArea^.Name));
end;

procedure faNextArea;
var A, oa : Word; Found : Boolean;
begin
   oa := User^.curFileArea;
   Found := False;
   while (not Found) and (User^.curFileArea < numFileArea) do
   begin
      Inc(User^.curFileArea);
      Found := faChangeArea(User^.curFileArea);
   end;
   if not Found then
   begin
      User^.curFileArea := oa;
      faLoad;
      oStringLn(strFaHighestArea);
   end else oStrLn(strCode(mStr(strFaChangedAreas),1,fArea^.Name));
end;

function faAddFile(var aFile : tFileRec; var Desc) : Boolean;
var F : file of tFileRec; eF : file of tFileDescLn; pD : pFileDesc; N : Word;
begin
   pD := @Desc;
   faAddFile := False;
   Inc(fArea^.Files,1);

   if aFile.DescLns > 0 then
   begin
      if aFile.DescLns > maxDescLns then aFile.DescLns := maxDescLns;
      Assign(eF,Cfg^.pathData+fileFileDesc);
      {$I-}
      Reset(eF);
      {$I+}
      if ioResult <> 0 then
      begin
         {$I-}
         Rewrite(eF);
         {$I+}
         if ioResult <> 0 then Exit;
      end else Seek(eF,FileSize(eF));
      aFile.DescPtr := FilePos(eF);
      for N := 1 to aFile.DescLns do Write(eF,pD^[N]);
      Close(eF);
   end;

   Assign(F,Cfg^.pathData+fArea^.Filename+extFileDir);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult <> 0 then Exit;
   end else Seek(F,FileSize(F));
   Write(F,aFile);
   fArea^.Files := FileSize(F);
   Close(F);

   faSave;
   faAddFile := True;
end;

procedure faLoadDesc(var aFile : tFileRec; var Desc : pFileDesc);
var eF : file of tFileDescLn; N : Word;
begin
   if aFile.DescLns > 0 then
   begin
      Assign(eF,Cfg^.pathData+fileFileDesc);
      {$I-}
      Reset(eF);
      {$I+}
      if ioResult <> 0 then Exit;
      Seek(eF,aFile.descPtr);
      GetMem(Desc,aFile.DescLns*(maxDescLen+1));
      FillChar(Desc^,SizeOf(Desc^),0);
      for N := 1 to aFile.DescLns do Read(eF,Desc^[N]);
      Close(eF);
   end;
end;

procedure faReadDesc(var F : file; var aFile : tFileRec; var Desc : pFileDesc);
var N : Word;
begin
   if (FileSize(F) > 0) and (aFile.DescLns > 0) then
   begin
      Seek(F,aFile.descPtr);
      GetMem(Desc,aFile.DescLns*(maxDescLen+1));
      FillChar(Desc^,SizeOf(Desc^),0);
      for N := 1 to aFile.DescLns do BlockRead(F,Desc^[N],1);
   end;
end;

procedure faKillDesc(var F : tFileRec; var Desc : pFileDesc);
begin
   if F.DescLns > 0 then FreeMem(Desc,F.DescLns*(maxDescLen+1));
end;

function faFileExists(Fn : String) : Boolean;
var F : file; D : tFileRec; Found : Boolean;
begin
   faFileExists := False;
   Assign(F,Cfg^.pathData+fArea^.Filename+extFileDir);
   {$I-}
   Reset(F,SizeOf(tFileRec));
   {$I+}
   if ioResult <> 0 then Exit;
   Found := False;
   while (not Found) and (not Eof(F)) do
   begin
      BlockRead(F,D,1);
      Found := D.Filename = Fn;
   end;
   Close(F);
   faFileExists := Found;
end;

function faFileSearch(Fn : String; var D : tFileRec; var Area : Word) : Word;
var F : file; Found, A, cA, cF : Word;
begin
   faFileSearch := 0;
   Area := User^.curFileArea;
   A := User^.curFileArea;
   Found := 0;
   cF := 0;
   Assign(F,Cfg^.pathData+fArea^.Filename+extFileDir);
   {$I-}
   Reset(F,SizeOf(tFileRec));
   {$I+}
   if ioResult = 0 then
   begin
      while (Found = 0) and (not Eof(F)) do
      begin
         BlockRead(F,D,1);
         Inc(cF);
         if faCloseEnough(Fn,D.Filename) then Found := cF;
      end;
      Close(F);
   end;
   faFileSearch := Found;
   if Found <> 0 then Exit;
   cA := 0;
   repeat
      Inc(cA);
      User^.curFileArea := cA;
      if (cA <> A) and (faLoad) and (faHasAccess) and (fArea^.Password = '') then
      begin
         Assign(F,Cfg^.pathData+fArea^.Filename+extFileDir);
         {$I-}
         Reset(F,SizeOf(tFileRec));
         {$I+}
         cF := 0;
         if ioResult = 0 then
         begin
            while (Found = 0) and (not Eof(F)) do
            begin
               BlockRead(F,D,1);
               Inc(cF);
               if faCloseEnough(Fn,D.Filename) then Found := cF;
            end;
            Close(F);
         end;
      end;
   until (Found <> 0) or (cA >= numFileArea);

   faFileSearch := Found;
   Area := cA;

   User^.curFileArea := A;
   faLoad;
end;

function faLoadDescFile(Fn : String; var P : pFileDesc) : Word;
var Lns, nL, lfs : Word; dF : file; S : String[maxDescLen]; Z : String; lastLf : Boolean;
    C : Char; Po : Byte;
begin
   faLoadDescFile := 0;
   Lns := 0;
   Assign(dF,Fn);
   {$I-}
   Reset(dF,1);
   {$I+}
   if ioResult <> 0 then Exit;
   if Eof(dF) then Lns := 0 else Lns := 1;
   lastLf := False;
   C := #0;
   Po := 0;
   lfs := 0;
   while (C <> #26) and (Lns <= maxDescLns) and (ioResult = 0) and (not Eof(dF)) do
   begin
      BlockRead(dF,C,1);
      if (C = #13) or ((C = #10) and (not lastLf)) then
      begin
         Inc(Lns);
         Inc(lfs);
         Po := 0;
      end else if not (C in [#10,#13,#26]) then begin lfs := 0; Inc(Po); end;
      lastLf := C = #13;
   end;
   Close(dF);
   if Po > 0 then Inc(Lns) else Dec(Lns,lfs);
   if Lns = 0 then Exit;
   GetMem(P,Lns*(maxDescLen+1));
   FillChar(P^,Lns*(maxDescLen+1),0);
   nL := Lns;
   Reset(dF,1);
   Lns := 1;
   lastLf := False;
   C := #0;
   while (C <> #26) and (Lns <= nL) and (ioResult = 0) and (not Eof(dF)) do
   begin
      BlockRead(dF,C,1);
      if (not (C in [#10,#13,#26,#8])) and (Ord(P^[Lns,0]) < maxDescLen) then
          P^[Lns] := P^[Lns]+C else if (C = #13) or
             ((C = #10) and (not lastLf)) then Inc(Lns);
      lastLf := C = #13;
   end;
   Close(dF);
   faLoadDescFile := nL;
end;
(*
function faLoadDescFile(Fn : String; var P : pFileDesc) : Word;
var Lns : Word; dF : Text; S : String[maxDescLen]; Z : String;
begin
   faLoadDescFile := 0;
   Lns := 0;
   Assign(dF,Fn);
   {$I-}
   Reset(dF);
   {$I+}
   if ioResult <> 0 then Exit;
   while not Eof(dF) do
   begin
      ReadLn(dF);
      Inc(Lns);
   end;
   Close(dF);
   if Lns = 0 then Exit;
   GetMem(P,Lns*(maxDescLen+1));
   FillChar(P^,Lns*(maxDescLen+1),0);
   Reset(dF);
   Lns := 0;
   while not Eof(dF) do
   begin
      ReadLn(dF,S);
      Inc(Lns);
      Move(S,P^[Lns],Length(S)+1);
   end;
   Close(dF);
   faLoadDescFile := Lns;
end;
*)
procedure faLocalUpload;
var sr, sr2 : SearchRec; F : tFileRec; None, ca, fa, la, oa, X, xp, xa : Byte; dF : Text;
    fn, S, Tp : String; P : pFileDesc; pX : array[1..5] of String; Auto, error, no, sa : Boolean;
 procedure luOut(v : String);
 begin
    oMoveLeft(80);
    oClrEol;
    oStrCtr(v);
 end;
begin
   oa := User^.curFileArea;
   oDnLn(1);
   oStrCtr('|U2(|U1upload|U2) |U1Upload to which file area(s)|U2? ');
   pX[1] := 'Current';
   pX[2] := 'Conference';
   pX[3] := 'All';
   pX[4] := 'Abort';
   xa := iXprompt(pX,4,1);
   if xa = 4 then Exit;

   oStrCtr('|U2(|U1upload|U2) |U1File process method|U2: ');
   pX[1] := 'None';
   pX[2] := 'Import';
   pX[3] := 'Test';
   pX[4] := 'Recompress';
   xp := iXprompt(pX,4,3);

   if xa = 1 then begin fa := oa; la := oa; end else
   if xa in [2,3] then begin fa := 1; la := numFileArea; end;

   pX[1] := 'Add';
   pX[2] := 'Skip';
   pX[3] := 'Kill';
   pX[4] := 'Auto';
   pX[5] := 'Quit';

   Auto := False;

   Tp := fTempPath('A');
   fClearDir(Tp);
   X := 1;

   for ca := fa to la do if ((xa <> 2) or (acsOk(fArea^.acs))) and (not hangup) and (x <> 5) then
   begin
      User^.curFileArea := ca;
      faLoad;
      oDnLn(1);
      oStrCtrLn('|U2(|U1upload|U2) |U1Processing area|U2: |U3'+fArea^.Name+'|U2, |U3'+st(fArea^.files)+'|U1 file(s)');
      FindFirst(fArea^.Path+'*.*',0,Sr);
      while (X <> 5) and (not HangUp) and (dosError = 0) do
      begin
         if not faFileExists(Sr.Name) then
         begin
            oStrCtr('|U2- |U1Found|U2: |U3'+Resize(Sr.Name,12)+' ');
            fn := upStr(fArea^.path+sr.Name);
            if iKeypressed then Auto := False;
            if Auto then oStrLn('|U2[|U1auto mode|U2]') else
            begin
               oStr('|U2- |U1Command|U2: ');
               X := iXprompt(pX,5,1);
            end;
            if X = 3 then fDeleteFile(fArea^.Path+Sr.Name) else
            if X = 4 then Auto := True;
            if (Auto) or (X = 1) then with F do
            begin
               luOut('|U2- |U1Analyzing file|U2 ...');
               fClearDir(Tp);
               FillChar(F,SizeOf(F),0);
               DescLns := 0;
               error := False;

               no := ArchType(fn) = 0;
               if no then error := True;

               if (not error) and (xp in [3,4]) and (Cfg^.delFile <> '') and
                  (fExists(Cfg^.pathData+Cfg^.delFile)) then
               begin
                  luOut('|U2- |U1Removing useless file(s) from archive|U2 ...');
                  archDelete(fn,'@'+Cfg^.pathData+Cfg^.delFile);
               end;

               if (not error) and (xp in [3,4]) and (Cfg^.addFile <> '') and
                  (fExists(Cfg^.pathData+Cfg^.addFile)) then
               begin
                  luOut('|U2- |U1Adding file(s) to archive|U2 ...');
                  archZip(fn,'@'+Cfg^.pathData+Cfg^.addFile,0);
               end;

               if (not error) and (xp in [3,4]) then
               begin
                  luOut('|U2- |U1Decompressing file|U2 ...');
                  if not archUnzip(fn,'*.*',tp) then error := True;
               end;

               if (not error) and (xp in [3,4]) then
               begin
                  luOut('|U2- |U1Scanning for viruses|U2 ...');
                  if not archScan(tp+'*.*') then error := True;
               end;

               if (not error) and (xp = 4) then
               begin
                  luOut('|U2- |U1Recompressing archive|U2 ...');
                  s := fTempPath('F')+'COMPTEMP.$$$';
                  fDeleteFile(s);
                  fRenameFile(fn,s);
                  if archZip(fn,tp+'*.*',0) then fDeleteFile(s) else
                  begin
                     error := True;
                     fRenameFile(s,fn);
                  end;
               end;

               if (not error) and (xp in [2,3,4]) and (Cfg^.comFile <> '') and
                  (fExists(Cfg^.pathData+Cfg^.comFile)) then
               begin
                  luOut('|U2- |U1Applying bbs comment to archive|U2 ...');
                  archComment(fn,Cfg^.pathData+cfg^.comFile);
               end;

               if (not error) and (xp in [2,3,4]) then
               begin
                  luOut('|U2- |U1Checking for description |U2(|U1'+cfg^.fileDesc1+' or '+cfg^.fileDesc2+'|U2) ...');
                  fClearDir(tp);
                  if (Cfg^.ImportDescs) and
                     (archUnzip(fn,Cfg^.fileDesc1+' '+Cfg^.fileDesc2,Tp)) then
                  begin
                     if fExists(Tp+Cfg^.fileDesc1) then
                     begin
                        luOut('|U2- |U1Importing file description|U2: |U3'+Cfg^.fileDesc1);
                        DescLns := faLoadDescFile(Tp+Cfg^.fileDesc1,P);
                     end else if fExists(Tp+Cfg^.fileDesc2) then
                     begin
                        luOut('|U2- |U1Importing file description|U2: |U3'+Cfg^.fileDesc2);
                        DescLns := faLoadDescFile(Tp+Cfg^.fileDesc2,P);
                     end;
                  end;
               end;
               if (descLns = 0) and ((no) or (not error)) and (xp in [2,3,4]) then
               begin
                  luOut('|U2- |U1Checking for sauce comment|U2 ...');
                  fClearDir(tp);
                  if (Cfg^.ImportDescs) and (sauceDiz(fn,tp+cfg^.fileDesc1)) then
                  begin
                     luOut('|U2- |U1Importing sauce comment |U2...');
                     DescLns := faLoadDescFile(Tp+Cfg^.fileDesc1,P);
                  end;
               end;
               if no then error := False;
               luOut('|U2- |U1Loading file information|U2 ...');
               FindFirst(fn,0,sr2);
               if dosError <> 0 then error := True else
               begin
                  Filename := Sr2.Name;
                  Downloads := 0;
                  Size := Sr2.Size;
                  Uploader := User^.UserName;
                  Date := dtDatePackedString(Sr2.Time);
                  ulDate := dtDateString;
                  Valid := True;
                  filePts := Size div (Cfg^.kbPerFilePoint*1024);
               end;
               fClearDir(tp);

               if (not error) and (DescLns = 0) and (not Auto) then
               begin
                  Assign(dF,fTempPath('A')+'FILEDESC.TMP');
                  {$I-}
                  Rewrite(dF);
                  {$I+}
                  if ioResult = 0 then
                  begin
                     luOut('|U2- |U1Enter file description|U2.  |U1Hit |U3enter |U1on a blank line to end|U2.');
                     oDnLn(1);
                     repeat
                        Inc(DescLns);
                        oStrCtr('|U6'+ResizeRt(St(DescLns),3)+'|U5: |U4');
                        S := iReadString('',inNormal,chNormal,rsNoCR,maxDescLen);
                        if S <> '' then
                        begin
                           WriteLn(dF,S);
                           oDnLn(1);
                        end else
                        begin
                           oMoveLeft(70);
                           oClrEol;
                        end;
                     until (HangUp) or (DescLns >= maxDescLns) or (S = '');
                     Close(dF);
                     if HangUp then DescLns := 0;
                     DescLns := faLoadDescFile(fTempPath('A')+'FILEDESC.TMP',P);
                  end;
               end;
               if not error then
               begin
                  faAddFile(F,P^);
                  luOut('|U2- |U3'+Sr.Name+'|U2: |U1file added|U2.');
                  if F.DescLns > 0 then oStrCtr(' |U2[|U1'+St(F.DescLns)+'|U1 line description|U2]');
               end else luOut('|U2- |U3'+Sr.Name+'|U2: |U1error processing file|U2.');
               oDnLn(1);
               faKillDesc(F,P);
            end;
         end;
         FindNext(Sr);
{        if dosError <> 0 then oDnLn(1);}
      end;
      faSave;
   end;
   User^.curfileArea := oa;
   faLoad;
end;

function faLoadFile(N : Word; var D : tFileRec) : Boolean;
var fD : file of tFileRec;
begin
   faLoadFile := False;
   Assign(fD,Cfg^.pathData+fArea^.Filename+extFileDir);
   {$I-}
   Reset(fD);
   {$I+}
   if ioResult <> 0 then Exit;
   fArea^.Files := FileSize(fD);
   if N > FileSize(fD) then Exit;
   Seek(fD,N-1);
   Read(fD,D);
   Close(fD);
   faLoadFile := True;
end;

function faSaveFile(N : Word; var D : tFileRec) : Boolean;
var fD : file of tFileRec;
begin
   faSaveFile := False;
   Assign(fD,Cfg^.pathData+fArea^.Filename+extFileDir);
   {$I-}
   Reset(fD);
   {$I+}
   if ioResult <> 0 then Exit;
   fArea^.Files := FileSize(fD);
   if N > FileSize(fD) then Exit;
   Seek(fD,N-1);
   Write(fD,D);
   Close(fD);
   faSaveFile := True;
end;

procedure faFileInfo(var F : tFileRec);
var Ans : boolean;
begin
   faLoadDesc(F,pDesc);
   nDescLns := F.DescLns;
   with F do
   begin
      sfStr[1] := Filename;
      sfStr[2] := Stc(Downloads);
      sfStr[3] := Stc(Size);
      sfStr[4] := Uploader;
      sfStr[5] := Date;
      sfStr[6] := ulDate;
      sfStr[7] := St(mXferTimeSec(Size) div 60);
      sfStr[8] := St(filePts);
   end;
   Ans := sfShowTextFile(txFileInfo,ftFileInfo);
   if not Ans then with F do
   begin
      oStrCtrLn('|U5'+sRepeat('Ä',79));
      oStrCtrLn('|U4 Filename      |U5: |U6'+Filename);
      oStrCtrLn('|U4 Downloads     |U5: |U6'+Stc(Downloads));
      oStrCtrLn('|U4 Size          |U5: |U6'+Stc(Size));
      oStrCtrLn('|U4 Uploader      |U5: |U6'+Uploader);
      oStrCtrLn('|U4 Date          |U5: |U6'+Date);
      oStrCtrLn('|U4 Upload date   |U5: |U6'+ulDate);
      oStrCtrLn('|U4 Transfer time |U5: |U6'+St(mXferTimeSec(Size) div 60)+' |U4min');
      oStrCtrLn('|U5'+sRepeat('Ä',79));
   end;
   faKillDesc(F,pDesc);
end;

function faReqDownload(var D : tFileRec; TimAdd, dlAdd, dlkbAdd, fpAdd : LongInt) : Boolean;
begin
   faReqDownload := False;

   fConfAll := True;
   if not (faHasAccess and faHasDLAccess) then
   begin
      fConfAll := False;
      oStrLn(strCode(mStr(strFaDLaccessDenied),1,D.Filename));
      logWrite(D.Filename+':  Access to area denied');
      Exit;
   end;
   fConfAll := False;

   if not fExists(fArea^.path+D.Filename) then
   begin
      oStrLn(strCode(mStr(strFaFileNotThere),1,D.Filename));
      logWrite('-'+D.Filename+':  File did not actually exist');
      Exit;
   end;

   if (not acsOk(Cfg^.acsCoSysOp)) and (not D.Valid) then
   begin
      oStrLn(strCode(mStr(strFaFileNotValid),1,D.Filename));
      logWrite(D.Filename+':  File not validated for transfer');
      Exit;
   end;

   if mTimeLeft('S')-TimAdd < mXferTimeSec(D.Size) then
   begin
      oStrLn(strCode(mStr(strFaNoTimeForDL),1,D.Filename));
      logWrite(D.Filename+':  Insufficient time for transfer');
      Exit;
   end;

   if (Cfg^.useFilePoints) and (D.filePts > User^.filePts-fpAdd) then
   begin
      oStrLn(strCode(strCode(strCode(mStr(strFaNoFilePts),1,St(User^.filePts)),2,St(D.filePts)),3,D.Filename));
      logWrite(D.Filename+':  Not enough file points');
      Exit;
   end;

   if (Cfg^.useDLlimit) and (User^.todayDL+dlAdd >= User^.limitDL) then
   begin
      oStrLn(strCode(strCode(mStr(strFaOverDLlimit),1,St(User^.limitDL)),2,D.Filename));
      logWrite(D.Filename+':  Over daily download limit');
      Exit;
   end;

   if (Cfg^.useDLkbLimit) and (User^.todayDLkb+dlKbAdd >= User^.limitDLkb) then
   begin
      oStrLn(strCode(strCode(mStr(strFaOverDLkbLimit),1,St(User^.limitDLkb)),2,D.Filename));
      logWrite(D.Filename+':  Over daily download kilobyte limit');
      Exit;
   end;

   if (Cfg^.useUlDlratio) and (User^.Downloads+dlAdd >= User^.Uploads*User^.uldlRatio+User^.uldlRatio) then
   begin
      oStrLn(strCode(mStr(strFaULDLratioBad),1,D.Filename));
      logWrite(D.Filename+':  Upload/download ratio out of balance');
      Exit;
   end;

   if (Cfg^.useKbratio) and (User^.DownloadKb+dlKbAdd >= User^.UploadKb*User^.kbRatio+User^.kbRatio) then
   begin
      oStrLn(strCode(mStr(strFaKBratioBad),1,D.Filename));
      logWrite(D.Filename+':  Upload/download kilobyte ratio out of balance');
      Exit;
   end;

   faReqDownload := True;
end;

procedure faDownload(Par : String);
var Fn : String; D : tFileRec; Ch : Char; bDL : Boolean;
    dlSize : LongInt; dlTime, dlKb, dlFp, dlFiles, dlOk, N, oldA, A  : Word; fB : Text;
    dlIdx : array[1..maxBatch] of record
       Num : Word;
       Area : Word;
       Ok : Boolean;
    end;
begin
   oldA := User^.curFileArea;

   oDnLn(1);

   bDL := False;

   if (Par = '') and (numBatch > 0) then
   begin
      oStr(strCode(mStr(strFaBatchAskDL),1,St(numBatch)));
      bDL := iYesNo(True);
   end;


   if bDL then
   begin
      oDnLn(1);
      dlTime := 0;
      dlFiles := 0;
      dlSize := 0;
      dlKb := 0;
      dlFp := 0;
      Assign(fB,fTempPath('F')+fileTempDL);
      {$I-}
      Rewrite(fB);
      {$I+}
      if ioResult <> 0 then Exit;
      for N := 1 to numBatch do
      begin
         if User^.curFileArea <> batchDL[N].Area then
         begin
            User^.curFileArea := batchDL[N].Area;
            faLoad;
         end;
         if (faLoadFile(batchDL[N].Num,D)) and (faReqDownload(D,dlTime,dlFiles,dlKb,dlFp)) then
         begin
            Inc(dlSize,D.Size);
            Inc(dlFiles);
            Inc(dlKb,D.Size div 1024);
            Inc(dlFp,D.FilePts);
            Inc(dlTime,mXferTimeSec(D.Size));
            dlIdx[dlFiles].Num := batchDL[N].Num;
            dlIdx[dlFiles].Area := batchDL[N].Area;
            dlIdx[dlFiles].Ok := False;
            oStrLn(strCode(strCode(strCode(mStr(strFaBatchFileDL),1,D.Filename),
                                                                   2,Stc(D.Size)),
                                                                   3,mTimeSec(mXferTimeSec(D.Size))));
            WriteLn(fB,fArea^.Path+D.Filename);
         end;
      end;
      Close(fB);
      User^.curFileArea := oldA;
      faLoad;
      if dlFiles = 0 then Exit;
      oDnLn(1);
      oStrLn(strCode(strCode(strCode(mStr(strFaBatchDLtotal),1,St(dlFiles)),
                                                              2,Stc(dlSize)),
                                                              3,mTimeSec(mXferTimeSec(dlSize))));
      oDnLn(1);
      oString(strFaDownloadPrompt);
      repeat
         Ch := UpCase(iReadKey);
      until (HangUp) or ((extKey = #0) and (Ch in ['D','C','A',#27,#13]));
      if Ch in ['D','C',#13] then
      begin
         oWriteLn('Continue');
         if xferSend('',[protActive,protBatch]) then
         begin
            dlOk := 0;
            dlSize := 0;
            for N := 1 to dlFiles do
            begin
               if User^.curFileArea <> dlIdx[N].Area then
               begin
                  User^.curFileArea := dlIdx[N].Area;
                  faLoad;
               end;
               if faLoadFile(dlIdx[N].Num,D) then
               begin
                  if xferGood(D.Filename,True) then
                  begin
                     Inc(dlOk);
                     Inc(dlSize,D.Size);
                     Inc(User^.Downloads);
                     Inc(User^.DownloadKb,D.Size div 1024);
                     Inc(Stat^.Downloads);
                     Inc(Stat^.DownloadKb,D.Size div 1024);
                     Inc(His^.Downloads);
                     Inc(His^.DownloadKb,D.Size div 1024);
                     Inc(User^.todayDL);
                     Inc(User^.todayDLkb,D.Size div 1024);
                     Inc(D.Downloads);
                     faSaveFile(dlIdx[N].Num,D);
                  end;
               end;
            end;
            oDnLn(1);
            if dlOk = 0 then
            begin
               logWrite('Transfer failed');
               oStringLn(strFaXferFailed);
            end else
            begin
               logWrite('Transfer successful ['+St(dlOk)+' files, '+Stc(dlSize)+' bytes]');
               oStringLn(strFaXferSuccess);
               oStrLn(strCode(strCode(mStr(strFaXferFilesSent),1,St(dlOk)),2,Stc(dlSize)));
            end;
            userSave(User^);
            hisSave;
            statSave;
            oDnLn(1);
            numBatch := 0;
         end else logWrite('-Transfer failed');
      end else
      if Ch in ['A',#27] then
      begin
         oWriteLn('Abort');
         logWrite('Transfer aborted');
      end;
      Exit;
   end;

   oString(strFaAskFileDownload);
   Par := UpStr(Par);
   if Par = '' then
   begin
      Fn := iReadString('',inUpper,chFilename,'',12);
      if Fn = '' then Exit;
   end else
   begin
      Fn := Par;
      oWriteLn(Par);
   end;

   oString(strFaSearching);

   N := faFileSearch(Fn,D,A);

   oDnLn(1);

   if N = 0 then
   begin
      oStringLn(strFaFileNotFound);
      Exit;
   end;

   if A <> User^.curFileArea then
   begin
      User^.curFileArea := A;
      faLoad;
      oStrLn(strCode(strCode(mStr(strFaFoundInArea),2,fArea^.Name),1,D.Filename));
   end;

   logWrite('File download: '+D.Filename+' ('+fArea^.Name+')');

   faFileInfo(D);

   if not faReqDownload(D,0,0,0,0) then
   begin
      User^.curFileArea := oldA;
      faLoad;
      Exit;
   end;

   oString(strFaDownloadPrompt);
   repeat
     Ch := UpCase(iReadKey);
   until (HangUp) or ((extKey = #0) and (Ch in ['D','C','A',#27,#13]));
   if Ch in ['D','C',#13] then
   begin
      oWriteLn('Continue');
      if xferSend(fArea^.Path+D.Filename,[protActive]) then
      begin
         Inc(User^.Downloads);
         Inc(User^.DownloadKb,D.Size div 1024);
         Inc(Stat^.Downloads);
         Inc(Stat^.DownloadKb,D.Size div 1024);
         Inc(His^.Downloads);
         Inc(His^.DownloadKb,D.Size div 1024);
         Inc(User^.todayDL);
         Inc(User^.todayDLkb,D.Size div 1024);
         Inc(D.Downloads);
         userSave(User^);
         hisSave;
         statSave;
         faSaveFile(N,D);
         logWrite('Transfer successful');
      end else logWrite('-Transfer failed');
   end else
   if Ch in ['A',#27] then
   begin
      oWriteLn('Abort');
      logWrite('Transfer aborted');
   end;

   User^.curFileArea := oldA;
   faLoad;
end;

procedure faFindAreaWithAccess;
var old, N : Word; F : file of tFileAreaRec; Found : Boolean;
begin
   faLoad;
   if faHasAccess then Exit;
   old := User^.curFileArea;
   Assign(F,Cfg^.pathData+fileFileArea);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   N := 0;
   Found := False;
   while (not Found) and (not Eof(F)) do
   begin
      Read(F,fArea^);
      Inc(N);
      Found := faHasAccess;
   end;
   if Found then User^.curFileArea := N else User^.curFileArea := old;
   Close(F);
   faLoad;
end;

procedure faDownloadAny(Par : String);
begin
   if Par <> '' then fFindFile(Par) else FileFound := False;
   if not FileFound then
   begin
      oStrLn('|U2-- |U1Enter filename to download|U2.');
      oStr('|U2: |U3');
      Par := iReadString('',inUpper,chDirectory,'',76);
      if Par = '' then Exit;
      fFindFile(Par);
      if not fileFound then
      begin
         oStrLn('|U1File not found|U2.');
         Exit;
      end;
   end;
   xferSend(Par,[protActive]);
end;

function faInBatch(n, a : Word) : Boolean;
var Z : Word; There : Boolean;
begin
   There := False;
   for Z := 1 to numBatch do
      if (n = batchDL[Z].Num) and (a = batchDL[Z].Area) then There := True;
   faInBatch := There;
end;

function faAddToBatch(N, A : Word) : Byte;
begin
   faAddToBatch := 1;
   if numBatch >= maxBatch then Exit;
   if faInBatch(n,a) then
   begin
      faAddToBatch := 2;
      Exit;
   end;
   Inc(numBatch);
   with batchDL[numBatch] do
   begin
      Num := N;
      Area := A;
   end;
   faAddToBatch := 0;
end;

procedure faBatchAdd(Par : String);
var Fn : String; D : tFileRec; A, N : Word;
begin
   oDnLn(1);
   if numBatch >= maxBatch then
   begin
      oStringLn(strFaBatchFull);
      Exit;
   end;
   oString(strFaBatchAskAdd);
   Par := UpStr(Par);
   if Par = '' then
   begin
      Fn := iReadString('',inUpper,chFilename,'',12);
      if Fn = '' then Exit;
   end else
   begin
      Fn := Par;
      oWriteLn(Par);
   end;

   oString(strFaSearching);

   N := faFileSearch(Fn,D,A);

   oDnLn(1);

   if N = 0 then
   begin
      oStringLn(strFaFileNotFound);
      Exit;
   end;

   faFileInfo(D);

   case faAddToBatch(N,A) of
     0 : begin
            logWrite('File added to batch: '+D.Filename);
            oStrLn(strCode(mStr(strFaBatchAdded),1,D.Filename));
         end;
     1 : oStringLn(strFaBatchFull);
     2 : oStringLn(strFaBatchAlready);
   end;
end;

procedure faViewFile(Par : String);
var Fn : String; D : tFileRec; oA, A, N : Word;
begin
   oDnLn(1);
   oA := User^.curFileArea;
   oString(strFaViewAskFile);
   Par := UpStr(Par);
   if Par = '' then
   begin
      Fn := iReadString('',inUpper,chFilename,'',12);
      if Fn = '' then Exit;
   end else
   begin
      Fn := Par;
      oWriteLn(Par);
   end;

   oString(strFaSearching);

   N := faFileSearch(Fn,D,A);

   oDnLn(1);

   if N = 0 then
   begin
      oStringLn(strFaFileNotFound);
      Exit;
   end;

   User^.curFileArea := A;
   faLoad;
   archView(fArea^.Path+D.Filename);
   User^.curFileArea := oA;
   faLoad;
end;

procedure faGetFileInfo(Par : String);
var Fn : String; D : tFileRec; oA, A, N : Word;
begin
   oDnLn(1);
   oA := User^.curFileArea;
   oString(strFaInfoAskFile);
   Par := UpStr(Par);
   if Par = '' then
   begin
      Fn := iReadString('',inUpper,chFilename,'',12);
      if Fn = '' then Exit;
   end else
   begin
      Fn := Par;
      oWriteLn(Par);
   end;

   oString(strFaSearching);

   N := faFileSearch(Fn,D,A);

   oDnLn(1);

   if N = 0 then
   begin
      oStringLn(strFaFileNotFound);
      Exit;
   end;

   faFileInfo(D);
end;

function faListFiles(Scn : Boolean; Idx : pFileScanIdx; idxFiles : Word) : Boolean;
var Ans, lfDone, lfQuit, listDraw, infoDraw, First, scrnDraw, fwd, neDesc : Boolean; listTop, listBot,
    ListLns, xx : Byte; cl : array[1..6] of tColorRec;
    numFiles, fileTop, fileBot, aFile : Word; pD : pFileDesc;
    fD : file of tFileRec; F : tFileRec; Ch : Char; SplitPos  : Word;
    descF : file; Page : array[1..25] of record Filename : String[12]; Y : Byte; inbat : Boolean; end;
    onPage, barPos, curMnu, sel : Byte;
    mnu : array[1..2] of record
       num : Byte;
       pos : Byte;
       cmd : array[1..10] of String[15];
       off : array[1..10] of Boolean;
       xp  : array[1..10] of Byte;
    end;


 procedure lfDoFn(pn : Word; hi : Boolean);
 var S, fns : String; P : Byte;
 begin
    P := Pos('.',page[pn].Filename);
    if P = 0 then fns := '' else fns := Copy(page[pn].Filename,P+1,3);
    if P = 0 then P := Length(page[pn].Filename)+1;
    fns := Resize(Copy(page[pn].Filename,1,P-1),9)+fns;

    if hi then
    begin
       if Page[pn].inbat then
       begin
          oSetColRec(cl[6]);
          oWriteChar('(');
       end else
       begin
          oSetColRec(cl[4]);
          oWriteChar(' ');
       end;
       oSetColRec(cl[4]);
       oWrite(fns);
       if Page[pn].inbat then
       begin
          oSetColRec(cl[6]);
          oWriteChar(')');
       end else oWriteChar(' ');
    end else
    begin
       if Page[pn].inbat then
       begin
          oSetColRec(cl[3]);
          oWriteChar('(');
       end else
       begin
          oSetColRec(cl[1]);
          oWriteChar(' ');
       end;
       oSetColRec(cl[1]);
       oWrite(fns);
       if Page[pn].inbat then
       begin
          oSetColRec(cl[3]);
          oWriteChar(')');
       end else oWriteChar(' ');
    end;
 end;

 procedure lfDescLn(Num, pn : Word; Ext : String; First : Boolean);
 begin
    if First then
    begin
       if sfPos[5].Ok then
       begin
          oPosX(sfPos[5].X);
          oSetColRec(cl[1]);
          oWrite(St(Num));
       end;
       if sfPos[6].Ok then
       begin
          oPosX(sfPos[6].X-1);
          lfDoFn(pn,False);
       end;
       if sfPos[7].Ok then
       begin
          oPosX(sfPos[7].X);
          oSetColRec(cl[1]);
          oWrite(St(F.Size div 1024)+'k');
{         oSetColRec(cl[2]);
          oWritechar('k');}
       end;
       if sfPos[8].Ok then
       begin
          oPosX(sfPos[8].X);
          oSetColRec(cl[1]);
          oWrite(St(F.filePts));
       end;
    end;
    if sfPos[9].Ok then
    begin
       oPosX(sfPos[9].X);
       oSetColRec(cl[1]);
       oStrCtrLn(strSquish(Ext,79-oWhereX));
    end;
 end;

 procedure lfClearWindow;
 var N : Word;
 begin
    oGotoXY(1,listTop);
    if First then
    begin
       First := False;
       Exit;
    end;
    oSetColRec(cl[1]);
    oClrEol;
    for N := listTop+1 to listBot do
    begin
       oDnLn(1);
       oClrEol;
    end;
    oGotoXY(1,listTop);
 end;

 procedure lfShowDesc(cf,pn, fl,ll : Word);
 var X : Word;
 begin
    if neDesc then faReadDesc(descF,F,pD);
    if ll > F.DescLns then ll := F.DescLns;
    for X := fl to ll do lfDescLn(cf,pn, pD^[X],X=1);
    faKillDesc(F,pD);
 end;

 procedure lfUpdateBar;
 var Len, X : Byte; num1, num2 : Integer;
 begin
    if not ((sfPos[17].Ok) and (sfPos[18].Ok)) then Exit;
    oGotoXY(sfPos[17].X,sfPos[17].Y);
    Len := sfPos[18].X-sfPos[17].X+1;
    if fileTop = 1 then num1 := 1 else num1 := Len*fileTop div numFiles;
    if fileBot = numFiles then num2 := Len else num2 := Len*fileBot div numFiles;
    if num1 < 1 then num1 := 1;
    if num2 < num1 then num2 := num1;
    if num2 > Len then num2 := Len;
    if num1 > 1 then
    begin
       oSetColRec(sfPos[17].C);
       for X := 1 to num1-1 do oWriteChar(userCfg['A']);
    end;
    oSetColRec(sfPos[18].C);
    for X := num1 to num2 do oWriteChar(userCfg['B']);
    if num2 < Len then
    begin
       oSetColRec(sfPos[17].C);
       for X := num2+1 to Len do oWriteChar(userCfg['A']);
    end;
 end;

 procedure lfNoBar;
 begin
    if (barPos = 0) or (not sfPos[6].Ok) then Exit;
    oGotoXY(sfPos[6].X-1,Page[barPos].Y);
    lfDoFn(barPos,False);
 end;

 procedure lfBar;
 begin
    if (barPos = 0) or (not sfPos[6].Ok) then Exit;
    oGotoXY(sfPos[6].X-1,Page[barPos].Y);
    lfDoFn(barPos,True);
 end;

 procedure lfDrawList(redraw : boolean);
 var Cur, Lines, X, Sze : Word; Done : Boolean;
 begin
    if not listDraw then Exit;
    listDraw := False;
    onPage := 0;
    lfClearWindow;
    FillChar(Page,SizeOf(Page),0);
    if (splitPos > 0) or (not redraw) then barPos := 0;
    Done := False;
    if Scn then Seek(fD,Idx^[fileTop]-1) else Seek(fD,fileTop-1);
    Read(fD,F);
    Cur := fileTop;
    fileBot := fileTop;
    if (SplitPos > 0) and (fwd) then
    begin
       lfShowDesc(fileTop,1,SplitPos,SplitPos+listLns);
       if SplitPos+listLns >= F.DescLns then SplitPos := 0;
       onPage := 0;
       Done := True;
    end else
    if (Cfg^.descWrap) and (F.DescLns > listLns) then
    begin
       SplitPos := 1;
       onPage := 1;
       Page[1].Filename := F.Filename;
       Page[1].Y := oWhereY;
       Page[1].inbat := faInBatch(cur,User^.curFileArea);
       lfShowDesc(fileTop,1,1,listLns);
       Done := True;
    end else
    begin
       SplitPos := 0;
       Done := False;
       if F.DescLns > listLns then F.DescLns := listLns;
       Lines := F.DescLns;
       onPage := 1;
       Page[1].Filename := F.Filename;
       Page[1].Y := oWhereY;
       Page[1].inbat := faInBatch(cur,User^.curFileArea);
       if Lines = 0 then Lines := 1;
       if F.DescLns > 0 then lfShowDesc(Cur,1,1,F.DescLns) else
           lfDescLn(Cur,1,Cfg^.noDescLine,True);
    end;
    while (Cur < numFiles) and (not Done) do
    begin
       Inc(Cur);
       if Scn then Seek(fD,Idx^[Cur]-1);
       Read(fD,F);
       Sze := F.DescLns;
       if Sze = 0 then Sze := 1;
       if Sze+Lines <= listLns then
       begin
          Inc(Lines,Sze);
          Inc(onPage);
          Page[onPage].Y := oWhereY;
          Page[onPage].Filename := F.Filename;
          Page[onPage].inbat := faInBatch(cur,User^.curFileArea);
          if F.DescLns > 0 then lfShowDesc(Cur,onPage,1,F.DescLns)
             else lfDescLn(Cur,onPage,Cfg^.noDescLine,True);
          fileBot := Cur;
       end else Done := True;
    end;
    lfUpdateBar;
    if barPos > onPage then barPos := 0;
    fwd := False;
    if (barPos <> 0) and (redraw) then lfBar;
 end;

 procedure lfMenuDraw;
 var N : Byte;
 begin
    oGotoXY(1,sfPos[3].Y);
    oSetColRec(cl[1]);
    oClrEol;
    oWrite('  ');
    for N := 1 to mnu[curMnu].Num do
    begin
       if mnu[curMnu].off[N] then
       begin
          if mnu[curMnu].Pos = N then oSetColRec(cl[4])
                                 else oSetColRec(cl[1]);
       end else
       begin
          if mnu[curMnu].Pos = N then oSetColRec(cl[6])
                                 else oSetColRec(cl[3]);
       end;
       mnu[curMnu].xp[N] := oWhereX;
       oWrite(' '+mnu[curMnu].cmd[N,1]);
       if mnu[curMnu].off[N] then
       begin
          if mnu[curMnu].Pos = N then oSetColRec(cl[5])
                                 else oSetColRec(cl[2]);
       end else
       begin
          if mnu[curMnu].Pos = N then oSetColRec(cl[4])
                                 else oSetColRec(cl[1]);
       end;
       oWrite(Copy(mnu[curMnu].cmd[N],2,255)+' ');
    end;
    oSetColRec(cl[1]);
 end;

 procedure lfWriteInfo(S : String);
 begin
    oGotoXY(1,sfPos[4].Y);
    oSetColRec(cl[1]);
    oClrEol;
    oStr(S);
 end;

 procedure lfInfo;
 begin
    case curMnu of
       1 : lfWriteInfo(mStr(strFaListInfo));
       2 : lfWriteInfo(mStr(strFaListInfoBar));
    end;
    infoDraw := False;
 end;

 procedure lfBarUp;
 begin
    if onPage = 0 then Exit;
    if barPos = 0 then
    begin
       barPos := onPage;
       lfBar;
       curMnu := 2;
       lfMenuDraw;
       lfInfo;
    end else
    begin
       lfNoBar;
       Dec(barPos);
       if barPos = 0 then
       begin
          curMnu := 1;
          lfMenuDraw;
          lfInfo;
       end;
       lfBar;
    end;
    if barPos = 0 then curMnu := 1 else curMnu := 2;
 end;

 procedure lfBarDown;
 begin
    if onPage = 0 then Exit;
    if barPos = 0 then
    begin
       barPos := 1;
       lfBar;
       curMnu := 2;
       lfMenuDraw;
       lfInfo;
    end else
    begin
       lfNoBar;
       Inc(barPos);
       if barPos > onPage then
       begin
          barPos := 0;
          curMnu := 1;
          lfMenuDraw;
          lfInfo;
       end;
       lfBar;
    end;
 end;

 procedure lfMoveForward;
 begin
    if SplitPos > 0 then
    begin
       Inc(SplitPos,listLns);
       fwd := True;
       listDraw := True;
    end else if fileBot < numFiles then
    begin
       fileTop := fileBot+1;
       fwd := True;
       listDraw := True;
    end else lfDone := True;
 end;

 procedure lfMoveBackward;
 begin
    if SplitPos > 0 then
    begin
       if fileTop > 1 then Dec(fileTop);
       SplitPos := 0;
       listDraw := True;
    end else if fileTop > 1 then
    begin
       Dec(fileTop);
       listDraw := True;
    end;
 end;

 procedure lfDownload;
 begin
    oClrScr;
    if barPos <> 0 then faDownload(Page[barPos].Filename) else
                        faDownload('');
    listDraw := True;
    scrnDraw := True;
    oPromptKey;
 end;

 procedure lfDrawScreen;
 begin
    if not scrnDraw then Exit;
    if Scn then numFiles := idxFiles else numFiles := FileSize(fD);
    sfStr[1] := fArea^.Name;
    Ans := sfShowTextFile(txListFiles,ftListFiles);
    if Ans then
    begin
       listTop := sfPos[1].Y;
       listBot := sfPos[2].Y;
       cl[1] := sfPos[11].C;
       cl[2] := sfPos[12].C;
       cl[3] := sfPos[13].C;
       cl[4] := sfPos[14].C;
       cl[5] := sfPos[15].C;
       cl[6] := sfPos[16].C;
    end else
    begin
       oClrScr;
       listTop := 3;
       listBot := 20;
       sfPos[4].Ok := True;
       oGotoXY(1,21);
       oStrCtr('|U2-- |U1File Listing Command|U2: ');
       sfPos[4].X := oWhereX;
       sfPos[4].Y := 21;
       sfPos[4].C := User^.Color[3];
       cl[1] := User^.Color[1];
       cl[2] := User^.Color[2];
       cl[3] := User^.Color[3];
       cl[4] := User^.Color[4];
       cl[5] := User^.Color[5];
       cl[6] := User^.Color[6];
    end;
    listLns := ListBot-listTop+1;
 end;

 procedure lfDoHelp;
 begin
    sfShowTextfile(txFileListHelp,ftNormal);
    oPromptKey;
    scrnDraw := True;
    listDraw := True;
 end;

 procedure lfEdit;
 var Num : Word;
 begin
    if not acsOk(cfg^.acsCoSysOp) then Exit;
    if Scn then
    begin
       if barPos = 0 then Num := Idx^[fileTop] else
                          Num := Idx^[fileTop+barPos-1];
    end else
    begin
       if barPos = 0 then Num := fileTop else
                          Num := fileTop+barPos-1;
    end;
    cfgFileEditor(Num,False);

    scrnDraw := True;
    listDraw := True;
 end;

 procedure lfMenuBar;
 begin
    oGotoXY(mnu[curMnu].xp[mnu[curMnu].pos],sfPos[3].Y);
    if mnu[curMnu].off[mnu[curMnu].pos] then oSetColRec(cl[4]) else oSetColRec(cl[6]);
    oWrite(' '+mnu[curMnu].cmd[mnu[curMnu].pos,1]);
    if mnu[curMnu].off[mnu[curMnu].pos] then oSetColRec(cl[5]) else oSetColRec(cl[4]);
    oWrite(Copy(mnu[curMnu].cmd[mnu[curMnu].pos],2,255)+' ');
    oSetColRec(cl[1]);
 end;

 procedure lfMenuNoBar;
 begin
    oGotoXY(mnu[curMnu].xp[mnu[curMnu].pos],sfPos[3].Y);
    if mnu[curMnu].off[mnu[curMnu].pos] then oSetColRec(cl[1]) else oSetColRec(cl[3]);
    oWrite(' '+mnu[curMnu].cmd[mnu[curMnu].pos,1]);
    if mnu[curMnu].off[mnu[curMnu].pos] then oSetColRec(cl[2]) else oSetColRec(cl[1]);
    oWrite(Copy(mnu[curMnu].cmd[mnu[curMnu].pos],2,255)+' ');
    oSetColRec(cl[1]);
 end;

 procedure lfFlagFile;
 var Fn : String; D : tFileRec; A, N : Word;
 begin
    A := User^.curFileArea;
    if barPos <> 0 then
    begin
       if Scn then N := Idx^[fileTop+barPos-1] else N := fileTop+barPos-1;
       faLoadFile(N,D);

       case faAddToBatch(N,A) of
           0 : begin
                  logWrite('File added to batch: '+D.Filename);
                  lfWriteInfo(strCode(mStr(strFaBatchAdded),1,D.Filename));
                  Page[barPos].inbat := True;
                  if not Cfg^.advFileBar then lfBar;
               end;
           1 : lfWriteInfo(mStr(strFaBatchFull));
           2 : lfWriteInfo(mStr(strFaBatchAlready));
       end;
       infoDraw := True;
       if Cfg^.advFileBar then
       begin
          lfNoBar;
          Inc(barPos);
          if barPos > onPage then
          begin
             barPos := 0;
             curMnu := 1;
             lfMenuDraw;
          end;
          lfBar;
       end;
       Exit;
   end;
   lfWriteInfo(mStr(strFaBatchAskAdd));
   Fn := iReadString('',inUpper,chFilename,'',12);
   if Fn = '' then
   begin
      lfInfo;
      Exit;
   end;

   lfWriteInfo(mStr(strFaSearching));

   N := faFileSearch(Fn,D,A);

   if N = 0 then
   begin
      lfWriteInfo(mStr(strFaFileNotFound));
      infoDraw := True;
      Exit;
   end;

   case faAddToBatch(N,A) of
       0 : begin
              logWrite('File added to batch: '+D.Filename);
              lfWriteInfo(strCode(mStr(strFaBatchAdded),1,D.Filename));

              for n := 1 to onPage do if D.Filename = Page[n].Filename then
              begin
                 barPos := n;
                 Page[n].inbat := True;
                 lfNoBar;
              end;

              barPos := 0;
           end;
       1 : lfWriteInfo(mStr(strFaBatchFull));
       2 : lfWriteInfo(mStr(strFaBatchAlready));
   end;
   infoDraw := True;
 end;

 procedure lfView;
 var Fn : String; D : tFileRec; oA, A, N : Word;
 begin
   oA := User^.curFileArea;
   if barPos <> 0 then
   begin
      if Scn then N := Idx^[fileTop+barPos-1] else N := fileTop+barPos-1;
      faLoadFile(N,D);
      if not archView(fArea^.Path+D.Filename) then Exit;
      oPromptKey;
      listDraw := True;
      scrnDraw := True;
      Exit;
   end;
   lfWriteInfo(mStr(strFaViewAskFile));
   Fn := iReadString('',inUpper,chFilename,'',12);
   if Fn = '' then
   begin
      lfInfo;
      Exit;
   end;

   lfWriteInfo(mStr(strFaSearching));

   N := faFileSearch(Fn,D,A);

   if N = 0 then
   begin
      lfWriteInfo(mStr(strFaFileNotFound));
      infoDraw := True;
      Exit;
   end;

   User^.curFileArea := A;
   faLoad;
   if archView(fArea^.Path+D.Filename) then
   begin
      oPromptKey;
      scrnDraw := True;
      listDraw := True;
   end else lfInfo;
   User^.curFileArea := oA;
   faLoad;
end;

 procedure lfFileInfo;
 var Fn : String; D : tFileRec; oA, A, N : Word;
 begin
   oA := User^.curFileArea;
   if barPos <> 0 then
   begin
      if Scn then N := Idx^[fileTop+barPos-1] else N := fileTop+barPos-1;
      faLoadFile(N,D);
      oClrScr;
      faFileInfo(D);
      oPromptKey;
      listDraw := True;
      scrnDraw := True;
      Exit;
   end;
   lfWriteInfo(mStr(strFaInfoAskFile));
   Fn := iReadString('',inUpper,chFilename,'',12);
   if Fn = '' then
   begin
      lfInfo;
      Exit;
   end;

   lfWriteInfo(mStr(strFaSearching));

   N := faFileSearch(Fn,D,A);

   if N = 0 then
   begin
      lfWriteInfo(mStr(strFaFileNotFound));
      infoDraw := True;
      Exit;
   end;

   oClrScr;
   faFileInfo(D);
   oPromptKey;
   scrnDraw := True;
   listDraw := True;
   faLoad;
end;

begin
   Assign(fD,Cfg^.pathData+fArea^.Filename+extFileDir);
   {$I-}
   Reset(fD);
   {$I+}
   if ioResult <> 0 then
   begin
      if not Scn then oStringLn(strFaNoFilesInArea);
      Exit;
   end else if FileSize(fD) = 0 then
   begin
      Close(fD);
      if not Scn then oStringLn(strFaNoFilesInArea);
      Exit;
   end;
   fArea^.Files := FileSize(fD);
   Assign(descF,Cfg^.pathData+fileFileDesc);
   {$I-}
   Reset(descF,SizeOf(tFileDescLn));
   {$I+}
   neDesc := ioResult = 0;

   scrnDraw := True;

   fileTop := 1;
   lfDone := False;
   lfQuit := False;
   listDraw := True;
   infoDraw := False;

   SplitPos := 0;
   barPos := 0;
   First := True;
   fwd := False;

   curMnu := 1;
   FillChar(mnu,SizeOf(mnu),0);
   with mnu[1] do
   begin
      num := 10;
      pos := 1;
      cmd[1] := 'next';
      cmd[2] := 'previous';
      cmd[3] := 'flag';
      cmd[4] := 'download';
      cmd[5] := 'view';
      cmd[6] := 'info';
      cmd[7] := 'edit';
      cmd[8] := 'help';
      cmd[9] := 'skip';
      cmd[10] := 'quit';
      off[7] := not acsOk(Cfg^.acsCoSysOp);
      off[9] := not skipOk;
   end;
   with mnu[2] do
   begin
      num := 6;
      pos := 1;
      cmd[1] := 'flag';
      cmd[2] := 'download';
      cmd[3] := 'view';
      cmd[4] := 'info';
      cmd[5] := 'edit';
      cmd[6] := 'quit';
      off[5] := not acsOk(Cfg^.acsCoSysOp);
   end;

   repeat
      lfDrawScreen;
      if scrnDraw then
      begin
         lfMenuDraw;
         lfInfo;
      end;
      lfDrawList(scrnDraw);
      if (barPos = 0) and (curMnu > 1) then
      begin
         curMnu := 1;
         lfMenuDraw;
      end else
      if (barPos > 0) and (curMnu = 1) then
      begin
         curMnu := 2;
         lfMenuDraw;
      end;
      scrnDraw := False;

      Ch := UpCase(iReadKey);
      if Ch = #27 then Ch := 'Q';
      if Ch = '?' then Ch := 'H';
      if infoDraw then lfInfo;
      if extKey <> #0 then
      case extKey of
        rtArrow : begin
                     lfMenuNoBar;
                     Inc(mnu[curMnu].Pos);
                     if mnu[curMnu].Pos > mnu[curMnu].Num then
                        mnu[curMnu].Pos := 1;
                     lfMenuBar;
                  end;
        lfArrow : begin
                     lfMenuNoBar;
                     Dec(mnu[curMnu].Pos);
                     if mnu[curMnu].Pos < 1 then
                        mnu[curMnu].Pos := mnu[curMnu].Num;
                     lfMenuBar;
                  end;
        upArrow : lfBarUp;
        dnArrow : lfBarDown;
      end else
      begin
         Sel := 0;
         for xx := 1 to mnu[curMnu].Num do
             if (Ch = UpCase(mnu[curMnu].Cmd[xx,1])) and
                (not mnu[curMnu].off[xx]) then
         begin
            if mnu[curMnu].Pos <> xx then
            begin
               lfMenuNoBar;
               mnu[curMnu].Pos := xx;
               lfMenuBar;
            end;
            Sel := xx;
         end;

         if Ch = #13 then Sel := mnu[curMnu].Pos;

         if curMnu = 1 then
         case Sel of
             1  : lfMoveForward;
             2  : lfMoveBackward;
             3  : lfFlagFile;
             4  : lfDownload;
             5  : lfView;
             6  : lfFileInfo;
             7  : lfEdit;
             8  : lfDoHelp;
             9  : if skipOk then begin lfDone := True; end;
             10 : begin lfDone := True; lfQuit := True; end;
         end else
         if curMnu = 2 then
         case Sel of
             1  : lfFlagFile;
             2  : lfDownload;
             3  : lfView;
             4  : lfFileInfo;
             5  : lfEdit;
             6  : begin lfDone := True; lfQuit := True; end;
         end;
      end;
   until (HangUp) or (lfDone);
   faListfiles := (not lfQuit) and (not HangUp);
   sfGotoPos(maxPos);
   Close(fD);
   if neDesc then Close(descF);
   faSave;
end;

function faBuildScanIdx(var Idx : tFileScanIdx; Typ : Char; nfo : String) : Word;
var F : file; x, N, rN : Word; D : tFileRec; pd : pFileDesc; fnd : Boolean;
begin
   faBuildScanIdx := 0;
   FillChar(Idx,SizeOf(Idx),0);
   Assign(F,Cfg^.pathData+fArea^.Filename+extFileDir);
   {$I-}
   Reset(F,SizeOf(D));
   {$I+}
   if ioResult <> 0 then Exit;
   N := 0;
   rN := 0;
   while (N < maxFiles) and (not Eof(F)) do
   begin
      BlockRead(F,D,1);
      Inc(N);
      if Typ = 'N' then
      begin
         if dtDateToJulian(D.ulDate) >= dtDateToJulian(User^.fileScan) then
         begin
            Inc(rN);
            Idx[rN] := N;
         end;
      end else
      if Typ = 'L' then
      begin
         if strWildCard(D.Filename,nfo) then
         begin
            Inc(rN);
            Idx[rN] := N;
         end;
      end else
      if Typ = 'D' then
      begin
         fnd := False;
         faLoadDesc(d,pd);
         for x := 1 to d.descLns do if Pos(nfo,upStr(pd^[x])) > 0 then fnd := True;
         faKillDesc(d,pd);
         if fnd then
         begin
            Inc(rN);
            Idx[rN] := N;
         end;
      end;
   end;
   Close(F);
   faBuildScanIdx := rN;
end;

procedure faNewScan(AllAreas : Boolean; Num : Word);
var N, Z, A : Word; Ok : Boolean; Idx : pFileScanIdx;
begin
   if numFileArea < 1 then Exit;
   A := User^.curFileArea;
   Ok := True;
   New(Idx);
   if AllAreas then
   begin
      logWrite('Global file newscan');
{     oStringLn(strFaNewScanInit);}
      skipOk := numFileArea <> 1;
      for N := 1 to numFileArea do if Ok then
      begin
         User^.curFileArea := N;
         faLoad;
         if faHasAccess then
         begin
            oStr(strCode(strCode(mStr(strFaNewScanning),1,fArea^.Name),2,St(fArea^.Files)));
            Z := faBuildScanIdx(Idx^,'N','');
            cCheckUser;
            oDnLn(1);
            if Z > 0 then Ok := (not HangUp) and (faListFiles(True,Idx,Z)) and (not (iKeyPressed and (iReadKey = ' ')));
         end;
      end;
      skipOk := False;
{     oStringLn(strFaNewScanDone);}
   end else
   begin
      skipOk := False;
      if Num = 0 then N := User^.curFileArea else N := Num;
      if N > numFileArea then N := numFileArea else if N < 1 then N := 1;
      User^.curFileArea := N;
      faLoad;
      if faHasAccess then
      begin
         logWrite('Newscanned file area "'+fArea^.Name+'"');
         oStr(strCode(strCode(mStr(strFaNewScanning),1,fArea^.Name),2,St(fArea^.Files)));
         Z := faBuildScanIdx(Idx^,'N','');
         oDnLn(1);
         if Z > 0 then faListFiles(True,Idx,Z);
      end;
   end;
   Dispose(Idx);
   User^.curFileArea := A;
   faLoad;
end;

procedure faNewScanAsk(Par : String);
var All : Boolean; Num : Word;
begin
   oDnLn(1);
   All := False;
   Num := 0;
   if Par <> '' then
   begin
      Par := UpStr(Par);
      All := (Par[1] = 'A');
      if not All then Num := StrToInt(Par);
   end;
   if (not All) and (Num = 0) then
   begin
      oString(strFaNewScanAskAll);
      All := iYesNo(True);
      oDnLn(1);
   end;
   faNewScan(All,Num);
end;

procedure faSetNewScanDate;
var D : String;
begin
   oString(strFaAskNewScanDate);
   D := iReadDate(User^.FileScan);
   if not dtValidDate(D) then Exit;
   User^.fileScan := D;
   userSave(User^);
end;

procedure faEditFileDesc(var Fil : tFileRec);
var Head : ^tMsgHeaderRec; Txt : ^tMessage; X, nS : Word; pD : pFileDesc;
    S : tFileDescLn; Ok : Boolean; eF : file of tFileDescLn;
begin
   faLoadDesc(Fil,pD);
   New(Txt);
   New(Head);

   FillChar(Head^,SizeOf(Head^),0);
   Head^.Status := [];
   with Head^.ToInfo do
   begin
      UserNum := 0;
      Alias := 'None';
      RealName := 'None';
      Name := 'n/a';
      UserNote := 'None';
   end;
   Head^.Subject := #10'Desc ['+Fil.Filename+']';
   with Head^.FromInfo do
   begin
      UserNum := User^.Number;
      Alias := User^.UserName;
      RealName := User^.RealName;
      Name := User^.UserName;
      UserNote := User^.UserNote;
   end;
   Head^.Replies := 0;
   Head^.Date := dtDateTimePacked;

   FillChar(Txt^,SizeOf(Txt^),0);
   for X := 1 to Fil.DescLns do Txt^[X] := pD^[X];
   Head^.Size := Fil.DescLns;
   Head^.sigPos := 0;
   Head^.incFile := 0;
   if Fil.DescLns > 0 then faKillDesc(Fil,pD);

   Ok := fsEdit(Txt^,Head^,False,nil,nil,False,False);
   if Ok then
   begin
      if Head^.Size > maxDescLns then Head^.Size := maxDescLns;
      while (Head^.Size > 0) and (CleanUp(Txt^[Head^.Size]) = '') do Dec(Head^.Size);
      nS := Head^.Size;
      if nS = 0 then
      begin
         Fil.DescLns := 0;
         Fil.DescPtr := 0;
      end else
      if nS > Fil.DescLns then
      begin
         Fil.DescLns := nS;
         Assign(eF,Cfg^.pathData+fileFileDesc);
         {$I-}
         Reset(eF);
         {$I+}
         if ioResult <> 0 then {$I-} Rewrite(eF) {$I+} else
            Seek(eF,FileSize(eF));
         Fil.DescPtr := FilePos(eF);
         for X := 1 to Fil.DescLns do
         begin
            S := Txt^[X];
            Write(eF,S);
         end;
         Close(eF);
      end else
      if nS <= Fil.DescLns then
      begin
         Fil.DescLns := nS;
         Assign(eF,Cfg^.pathData+fileFileDesc);
         {$I-}
         Reset(eF);
         {$I+}
         if ioResult = 0 then
         begin
            Seek(eF,Fil.DescPtr);
            for X := 1 to Fil.DescLns do
            begin
               S := Txt^[X];
               Write(eF,S);
            end;
            Close(eF);
         end;
      end;
   end;

   Dispose(Txt);
   Dispose(Head);
end;

procedure faAskListFiles;
var S : String; All : Boolean; Idx : pFileScanIdx; Z : Word;
begin
   if not faHasAccess then Exit;
   oString(strFaAskListFiles);
   skipOk := False;
   S := iReadString('',inUpper,chFilename+['*','?'],'',12);
   All := (S = '*.*') or (S = '') or (S = '*') or (S = '????????.???') or (S = '????????');
   if All then faListFiles(False,nil,0) else
   begin
      if Pos('.',S) = 0 then S := S+'.';
      New(Idx);
      Z := faBuildScanIdx(Idx^,'L',S);
      if Z > 0 then faListFiles(True,Idx,Z) else oStringLn(strFaNoMatchingFiles);
      Dispose(Idx);
   end;
end;

function faTestFile(Fn : String) : Boolean;
var Ans, ok : Boolean; tp, fnp : String; sl : Byte; old, new : LongInt;
{ yup ... GOTOs.  I know, they suck, but tell me there isn't a better
  way to do this ... :)                                               }
label gInteg, gDecomp, gVirus, gAge, gDel, gAdd, gComment, gExternal, gDiz, gSauce, gDone;
 procedure tfStat(S : String);
 begin
    if not sfGotoPos(3) then Exit;
    oStr(strEnlarge(S,sl));
    sl := Length(NoColor(S));
 end;
begin
   faTestFile := False;
   if not fExists(Fn) then Exit;
   faTestFile := True;
   fn := UpStr(fn);
   if ArchType(Fn) = 0 then Exit;
   faTestFile := False;
   fnp := strFilename(fn);
   tp := fTempPath('A');
   fCreateDir(tp,False);
   fClearDir(tp);
   oDnLn(1);
   ok := True;
   sl := 0;
   sfStr[1] := fnp;
   sfStr[2] := Stc(fFileSize(Fn));
   Ans := sfShowTextFile(txFileTest,ftFileTest);
   if not Ans then oStrLn('|U2-- |U1Processing |U3'+fnp+'|U2, |U3'+stc(fFileSize(Fn))+'|U1 bytes|U2 ...');

{ integrity check }
gInteg:
   if Ans then sfLight(5) else oStr('|U2-- |U1File integrity check|U2 ... ');
   if archTest(fn) then
   begin
      if Ans then sfOkLight(5) else oStrLn('|U1passed|U2.');
      tfStat(strCode(mStr(strFaTestCRCok),1,fnp));
   end else
   begin
      if Ans then sfFailLight(5) else oStrLn('|U1failed|U2.');
      tfStat(strCode(mStr(strFaTestCRCfail),1,fnp));
      Ok := False;
   end;
   if not Ok then goto gDone;

{ archive decompression }
gDecomp:
   if Ans then sfLight(6) else oStr('|U2-- |U1Decompressing archive|U2 ... ');
   if archUnzip(fn,'*.*',tp) then
   begin
      if Ans then sfOkLight(6) else oStrLn('|U1ok|U2.');
      tfStat(strCode(mStr(strFaTestDecompOk),1,fnp));
   end else
   begin
      if Ans then sfFailLight(6) else oStrLn('|U1error|U2.');
      tfStat(strCode(mStr(strFaTestDecompFail),1,fnp));
      Ok := False;
   end;
   if not Ok then goto gDone;

{ virus scan }
gVirus:
   if Ans then sfLight(7) else oStr('|U2-- |U1Scanning for viruses|U2 ... ');
   if archScan(tp+'*.*') then
   begin
      if Ans then sfOkLight(7) else oStrLn('|U1passed|U2.');
      tfStat(strCode(mStr(strFaTestVirusOk),1,fnp));
   end else
   begin
      if Ans then sfFailLight(7) else oStrLn('|U1failed|U2.');
      tfStat(strCode(mStr(strFaTestVirusFail),1,fnp));
      Ok := False;
   end;
   if not Ok then goto gDone;

{ age test }
gAge:
   if Ans then sfLight(8) else oStr('|U2-- |U1Performing age test|U2 ... ');
   fFindFile(tp+'*.*');
   old := dtDateTimePacked;
   new := 0;
   while FileFound do
   begin
      if Search.Time < old then old := Search.Time;
      if Search.Time > new then new := Search.Time;
      fFindNext;
   end;
   if not Cfg^.strictAge then old := new;
   if dtAge(dtDatePackedString(old)) <= Cfg^.maxFileAge then
   begin
      if Ans then sfOkLight(8) else oStrLn('|U1passed|U2.');
      tfStat(strCode(strCode(mStr(strFaTestAgeOk),1,fnp),2,dtDatePackedString(old)));
   end else
   begin
      if Ans then sfFailLight(8) else oStrLn('|U1failed|U2.');
      tfStat(strCode(strCode(mStr(strFaTestAgeFail),1,fnp),2,dtDatePackedString(old)));
      Ok := False;
   end;
   if not Ok then goto gDone;

   { delete crap files }
gDel:
   if Ans then sfLight(9) else oStr('|U2-- |U1Removing useless files from archive|U2 ... ');
   if (Cfg^.delFile <> '') and (fExists(Cfg^.pathData+Cfg^.delFile)) then
       archDelete(fn,'@'+Cfg^.pathData+Cfg^.delFile);
   if Ans then sfOkLight(9) else oStrLn('|U1done|U2.');
   tfStat(strCode(mStr(strFaTestFilesRemoved),1,fnp));

   { add new files }
gAdd:
   if Ans then sfLight(10) else oStr('|U2-- |U1Adding BBS files|U2 ... ');
   if (Cfg^.addFile <> '') and (fExists(Cfg^.pathData+Cfg^.addFile)) then
       archZip(fn,'@'+Cfg^.pathData+Cfg^.addFile,0);
   if Ans then sfOkLight(10) else oStrLn('|U1done|U2.');
   tfStat(strCode(mStr(strFaTestFilesAdded),1,fnp));

   { add comment }
gComment:
   if Ans then sfLight(11) else oStr('|U2-- |U1Adding archive comment|U2 ... ');
   if (Cfg^.comFile <> '') and (fExists(Cfg^.pathData+Cfg^.comFile)) then
       archComment(fn,Cfg^.pathData+cfg^.comFile);
   if Ans then sfOkLight(11) else oStrLn('|U1done|U2.');
   tfStat(strCode(mStr(strFaTestCommented),1,fnp));

   { external maintenence }
gExternal:
   if Ans then sfLight(12) else oStr('|U2-- |U1External maintenence|U2 ... ');
   if (Cfg^.extMaint) and (fExists(Cfg^.pathData+fileExtMaint)) then
       fShellDos(Cfg^.pathData+fileExtMaint+' '+Fn,Cfg^.ArchiverSwap,False,False);
   if Ans then sfOkLight(12) else oStrLn('|U1done|U2.');
   tfStat(strCode(mStr(strFaTestExternal),1,fnp));

gDiz:
   if Ans then sfLight(13) else oStr('|U2-- |U1Searching for description|U2 ... ');
   fClearDir(tp);
   if (Cfg^.importDescs) and (archUnzip(fn,Cfg^.fileDesc1+' '+Cfg^.fileDesc2,Tp)) then
   begin
      if Ans then sfOkLight(13) else oStrLn('|U1found|U2.');
      tfStat(strCode(mStr(strFaTestDescFound),1,fnp));
   end else
   begin
      if Ans then sfOkLight(13) else oStrLn('|U1none found|U2.');
      tfStat(strCode(mStr(strFaTestNoDesc),1,fnp));
   end;

gSauce:
   if Ans then sfLight(14) else oStr('|U2-- |U1Checking for sauce description|U2 ... ');
   if (Cfg^.importDescs) and (sauceDiz(fn,tp+cfg^.fileDesc1)) then
   begin
      if Ans then sfOkLight(14) else oStrLn('|U1found|U2.');
      tfStat(strCode(mStr(strFaTestDescFound),1,fnp));
   end else
   begin
      if Ans then sfOkLight(14) else oStrLn('|U1none found|U2.');
      tfStat(strCode(mStr(strFaTestNoSauce),1,fnp));
   end;

gDone:
   if Ok then
   begin
      tfStat(strCode(mStr(strFaTestPassed),1,fnp));
      faTestFile := True;
   end else
   begin
      tfStat(strCode(mStr(strFaTestFailed),1,fnp));
      faTestFile := False;
   end;
   sfGotoPos(maxPos);
end;

function faUploadSearch(var Fn : String) : Boolean;
var F : file; A, cA : Word; D : tFileRec; Found : Boolean;
begin
   faUploadSearch := True;
   if Cfg^.ulSearch = 1 then Exit;
   if Cfg^.ulSearch = 2 then
   begin
      faUploadSearch := faFileExists(fn);
      Exit;
   end;
   A := User^.curFileArea;
   Found := False;
   cA := 0;
   oString(strFaSearching);
   fConfAll := Cfg^.ulSearch = 4;
   repeat
      Inc(cA);
      User^.curFileArea := cA;
      if (faLoad) and (faHasAccess) and (fArea^.Password = '') then
      begin
         Assign(F,Cfg^.pathData+fArea^.Filename+extFileDir);
         {$I-}
         Reset(F,SizeOf(tFileRec));
         {$I+}
         if ioResult = 0 then
         begin
            while (not Found) and (not Eof(F)) do
            begin
               BlockRead(F,D,1);
               Found := faCloseEnough(UpStr(Fn),D.Filename);
               if Found then Fn := D.Filename;
            end;
            Close(F);
         end;
      end;
   until (Found) or (cA >= numFileArea);
   fConfAll := False;
   faUploadSearch := Found;
   User^.curFileArea := A;
   faLoad;
   oBack(oWhereX);
end;

procedure faUpload;
const maxBatchUL = 60;
var batchUL : array[1..maxBatchUL] of String[12]; fn : String; num, z, l : Byte;
    Ok, bl : Boolean; tp, rp, dp : String; numUL : Word; F : tFileRec; pD : pFileDesc;
    cmd : array[1..2] of String; sr : SearchRec;

 function ulBatchNum(fn : String) : Byte;
 var x : Byte;
 begin
    for x := 1 to num do if fn = batchUL[x] then
    begin
       ulBatchNum := x;
       Exit;
    end;
    ulBatchNum := 0;
 end;

 procedure ulGetDesc(z : Byte);
 var T : Text; S : String;
 begin
    oDnLn(1);
    Assign(T,tp+'FILEDESC.'+St(z));
    {$I-}
    Rewrite(T);
    {$I+}
    oStrLn(strCode(mStr(strFaULdescribe),1,batchUL[z]));
    l := 0;
    repeat
       Inc(l);
       oStr(strCode(mStr(strFaULdescLine),1,St(l)));
       S := iReadString('',inNormal,chNormal,rsNoCR,maxDescLen);
       if S <> '' then
       begin
          WriteLn(T,S);
          oDnLn(1);
       end else
       begin
          oMoveLeft(80);
          oClrEol;
       end;
    until (HangUp) or (l >= maxDescLns) or (S = '');
    Close(T);
    if HangUp then {$I-} Erase(T); {$I+}
 end;

begin
   oDnLn(1);
   if not acsOk(fArea^.acsUL) then
   begin
      oStringLn(strFaULnoAccess);
      Exit;
   end;
   if Cfg^.allowBlind then
   begin
      oString(strFaULaskBlind);
      bl := iYesNo(False);
      oDnLn(1);
   end else bl := False;
   tp := fTempPath('D');
   fClearDir(tp);
   num := 0;
   if not bl then
   begin
      oStrLn(strCode(mStr(strFaULenterFiles),1,St(maxBatchUL)));
      oStringLn(strFaULenterToEnd);
      oDnLn(1);
      repeat
         Inc(num);
         repeat
            oStr(strCode(mStr(strFaULenterFilename),1,St(num)));
            fn := iReadString('',inUpper,chFilename,'',12);
            if (fn <> '') and (ulBatchNum(fn) > 0) then ok := False else
            if (fn <> '') and (faUploadSearch(fn)) then
            begin
               oStrLn(strCode(mStr(strFaULfileExists),1,fn));
               Ok := False;
            end else ok := True;
         until (HangUp) or (ok);
         batchUL[num] := fn;
      until (HangUp) or (fn = '') or (num >= maxBatchUL);
      Dec(num);
      if num = 0 then Exit;
      oDnLn(1);
      cmd[1] := 'Now';
      cmd[2] := 'Later';
      oString(strFaULaskDescNow);
      if iXprompt(cmd,2,1) = 1 then
         for z := 1 to num do ulGetDesc(z);
   end;
   rp := fTempPath('X');
   fClearDir(rp);
   fCreateDir(rp,False);
   if not xferReceive('',[protActive,protBatch]) then
   begin
      logWrite('Upload aborted');
      Exit;
   end;
   fCreateDir(rp,False);
   oDnLn(1);

   numUL := 0;
   FindFirst(rp+'*.*',0,sr);
   while dosError = 0 do
   begin
      z := ulBatchNum(sr.Name);
      fn := sr.Name;
      if (num < maxBatchUL) and (z = 0) and (Cfg^.allowBlind) then
      begin
         oStrLn(strCode(mStr(strFaULfileFound),1,fn));
         if faUploadSearch(fn) then oStrLn(strCode(mStr(strFaULfileExists),1,fn)) else
         begin
            Inc(num);
            batchUL[num] := fn;
            z := num;
         end;
      end;
      if z > 0 then
      begin
         if faTestFile(rp+sr.Name) then
         begin
            dp := fTempPath('A');
            if not ((fExists(dp+Cfg^.fileDesc1)) and (fCopyFile(dp+Cfg^.fileDesc1,tp+'FILEDESC.'+St(z)))) then
            if not ((fExists(dp+Cfg^.fileDesc2)) and (fCopyFile(dp+Cfg^.fileDesc2,tp+'FILEDESC.'+St(z)))) then
            if not fExists(tp+'FILEDESC.'+St(z)) then ulGetDesc(z);
            oDnLn(1);
            oStrLn(strCode(mStr(strFaULaddingFile),1,sr.Name));
            with F do
            begin
               Filename := sr.Name;
               Downloads := 0;
               Size := sr.Size;
               Uploader := User^.UserName;
               Date := dtDatePackedString(sr.Time);
               ulDate := dtDateString;
               if fExists(tp+'FILEDESC.'+St(z)) then
                  DescLns := faLoadDescFile(tp+'FILEDESC.'+St(z),pD) else
                  DescLns := 0;
               Valid := Cfg^.autoValidate;
               filePts := Size div (Cfg^.kbPerFilePoint*1024);
               faAddFile(F,pD^);
               faKillDesc(F,pD);
               if not fMoveFile(rp+sr.Name,fArea^.Path+sr.Name) then
                  logWrite('-Error moving file: '+rp+sr.Name+' to '+fArea^.Path);
               Inc(Stat^.Uploads);
               Inc(Stat^.UploadKb,Size div 1024);
               Inc(His^.Uploads);
               Inc(His^.UploadKb,Size div 1024);
               if Valid then
               begin
                  Inc(User^.Uploads);
                  Inc(User^.UploadKb,Size div 1024);
                  if (Cfg^.useFilePoints) and (Cfg^.filePtsPer > 0) then
                  begin
                     Inc(User^.filePts,filePts*Cfg^.filePtsPer div 100);
                  end;
               end;
            end;
            oStrLn(strCode(strCode(mStr(strFaULfileAdded),1,sr.Name),2,St(F.DescLns)));
         end;
      end;
      FindNext(sr);
   end;
   statSave;
   hisSave;
   userSave(User^);
   oDnLn(1);
end;

procedure faSearchFile(fs : Boolean);
var Fn : String; D : tFileRec; sA, eA, cA, oA, N : Word;
    all, conf, any, ok : Boolean; idx : pFileScanIdx;
begin
   oDnLn(1);
   oA := User^.curFileArea;

   if fs then
   begin
      oString(strFaSearchAskFile);
      Fn := iReadString('',inUpper,chFilename+['*','?'],'',12);
      if (fn <> '') and (Pos('.',fn) = 0) then fn := fn+'.*';
   end else
   begin
      oString(strFaSearchAskDesc);
      Fn := upStr(iReadString('',inNormal,chNormal,'',50));
   end;
   if Fn = '' then Exit;

   oString(strFaSearchAskAll);
   all := iYesNo(True);

   if all then
   begin
      oString(strFaSearchAskConfs);
      conf := iYesNo(True);
   end else conf := False;

   if all then
   begin
      sA := 1;
      eA := numFileArea;
   end else
   begin
      sA := oA;
      eA := oA;
   end;

   any := False;
   if conf then fConfAll := True;
   New(Idx);
   ok := True;
   for cA := sA to eA do if ok then
   begin
      User^.curFileArea := cA;
      if (faLoad) and (faHasAccess) and (fArea^.Password = '') then
      begin
         oStr(strCode(mStr(strFaSearchArea),1,fArea^.Name));
         if fs then n := faBuildScanIdx(idx^,'L',fn) else
                    n := faBuildScanIdx(idx^,'D',fn);
         oDnLn(1);
         if n > 0 then
         begin
            ok := (not HangUp) and (faListFiles(True,idx,n)) and (not (iKeypressed and (iReadKey = ' ')));
            any := True;
         end;
      end;
   end;
   fConfAll := False;
   Dispose(Idx);

   User^.curFileArea := oA;
   faLoad;
   if not any then oStringLn(strFaSearchNone);
end;

end.