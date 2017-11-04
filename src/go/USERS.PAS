{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Users;

interface

uses Global;

procedure userAdd(var U : tUserRec);
procedure userCheckIndex;
procedure userConfiguration(app : Boolean);
function  userLoad(var U : tUserRec) : Boolean;
procedure userLogonInit;
procedure userPassword;
procedure userPrelogonInit;
procedure userReset;
procedure userSave(var U : tUserRec);
function  userSearch(var U : tUserRec; DelToo : Boolean) : Boolean;
procedure userShowList;

var
  userCfg : array['A'..'Z'] of Char;

implementation

uses Output, Input, Strings, ShowFile, Files, Misc, Logs, DateTime, StatBar,
     Stats, History, Wait4Cal, Callers, Levels;

procedure userShowList;
var Ans : Boolean; F : file of tUserRec; U : ^tUserRec; N : Word;
begin
   Assign(F,Cfg^.pathData+fileUsers);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   logWrite('Displayed user listing');
   New(U);
   Ans := (sfGetTextFile(txUserLtop,ftTopLine) <> '') and
          (sfGetTextFile(txUserLmid,ftNormal) <> '') and
          (sfGetTextFile(txUserLbot,ftNormal) <> '');
   PausePos := 1;
   PauseAbort := False;
   if Ans then
   begin
      sfShowTextFile(txUserLtop,ftTopLine);
      sfGotoPos(1);
      oUpPause(ansiRows-1);
      sfLoadRepeat(txUserLmid);
   end else
   begin
      oClrScr;
      oSetCol(colInfo);
      oCWriteLn('|U4 Num   Username                 Location              Calls  Baud    Access');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(3);
   end;
   N := 0;
   while (not HangUp) and (not PauseAbort) and (not Eof(F)) do
   begin
      Read(F,U^);
      Inc(N);
      if acDeleted in U^.acFlag then begin end else
      if Ans then
      begin
         sfStr[1]  := St(U^.Number);
         sfStr[2]  := U^.UserName;
         sfStr[3]  := U^.RealName;
         sfStr[4]  := U^.LastCall;
         sfStr[5]  := St(U^.TotalCalls);
         sfStr[6]  := St(U^.SL);
         sfStr[7]  := St(U^.DSL);
         sfStr[8]  := U^.Usernote;
         sfStr[9]  := U^.Location;
         sfStr[10] := mBaudString(U^.Baudrate);
         sfStr[11] := mSexString(U^.Sex);
         sfStr[12] := Copy(U^.PhoneNum,2,3);
         sfShowRepeat(ftUserList);
         if oWhereX <> 1 then oDnLn(1);
         oUpPause(1);
      end else
      begin
         oCWriteLn('|U1'+
                   ' '+Resize(St(N),5)+
                   ' '+Resize(U^.Username,24)+
                   ' '+Resize(U^.Location,21)+
                   ' '+Resize(St(U^.TotalCalls),6)+
                   ' '+Resize(mBaudString(U^.Baudrate),7)+
                   ' '+strSquish(St(U^.SL),3));
         oUpPause(1);
      end;
   end;
   sfKillRepeat;
   Close(F);
   if Ans then
   begin
      sfShowTextFile(txUserLbot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
   end;
   PausePos := 0;
   Dispose(U);
end;

procedure userSave(var U : tUserRec);
var F : file; Fi : file; Idx : tUserIndexRec;
begin
   if U.Number < 1 then Exit;
   Assign(F,Cfg^.pathData+fileUsers);
   {$I-}
   Reset(F,SizeOf(tUserRec));
   {$I+}
   if ioResult <> 0 then userAdd(U) else
   begin
      FillChar(Idx,SizeOf(Idx),0);
      Idx.Username := U.Username;
      Idx.Realname := U.Realname;
      Idx.Deleted  := acDeleted in U.acFlag;
      Seek(F,U.Number-1);
      BlockWrite(F,U,1);
      Close(F);
      Assign(Fi,Cfg^.pathData+fileUserIndex);
      {$I-}
      Reset(Fi,SizeOf(tUserIndexRec));
      {$I+}
      if ioResult = 0 then
      begin
         Seek(Fi,U.Number-1);
         BlockWrite(Fi,Idx,1);
         Close(Fi);
      end;
   end;
end;

function userLoad(var U : tUserRec) : Boolean;
var F : file;
begin
   userLoad := False;
   if U.Number < 1 then Exit;
   Assign(F,Cfg^.pathData+fileUsers);
   {$I-}
   Reset(F,SizeOf(tUserRec));
   {$I+}
   if ioResult <> 0 then Exit;
   numUsers := FileSize(F);
   Seek(F,U.Number-1);
   {$I-}
   BlockRead(F,U,1);
   {$I+}
   userLoad := ioResult = 0;
   Close(F);
end;

procedure userAdd(var U : tUserRec);
var F : file of tUserRec; Fi : file of tUserIndexRec;
    N : Word; T : tUserRec; Done : Boolean; Idx : tUserIndexRec;
begin
   Assign(F,Cfg^.pathData+fileUsers);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      U.Number := 1;
      Rewrite(F);
   end else
   begin
      N := 0;
      Done := False;
      while not Done do
      begin
         Read(F,T);
         Inc(N,1);
         Done := (Eof(F)) or (acDeleted in T.acFlag);
      end;
      U.Number := N;
      if not Eof(F) then Seek(F,N-1) else U.Number := N+1;
   end;
   Write(F,U);
   numUsers := FileSize(F);
   Close(F);
   FillChar(Idx,SizeOf(Idx),0);
   Idx.Username := U.Username;
   Idx.Realname := U.Realname;
   Idx.Deleted  := acDeleted in U.acFlag;
   Assign(Fi,Cfg^.pathData+fileUserIndex);
   {$I-}
   Reset(Fi);
   {$I+}
   if ioResult <> 0 then Rewrite(Fi) else Seek(Fi,U.Number-1);
   Write(Fi,Idx);
   Close(Fi);
end;

function userSearch(var U : tUserRec; DelToo : Boolean) : Boolean;
var F : file; T : tUserIndexRec; Done : Boolean; S : String;
    Un, N : Integer;
begin
   userSearch := False;
   Assign(F,Cfg^.pathData+fileUserIndex);
   {$I-}
   Reset(F,SizeOf(tUserIndexRec));
   {$I+}
   if ioResult <> 0 then Exit;
   S := UpStr(U.Username);
   U.Number := 0;
   N := 0;
   Un := strToInt(S);
   if (Un > numUsers) or (Un < 1) then Un := 0;
   while (not Eof(F)) and (U.Number = 0) do
   begin
      BlockRead(F,T,1);
      Inc(N,1);
      if ((S = UpStr(T.UserName)) or (S = UpStr(T.RealName)) or (Un = N))
         and ((not T.Deleted) or (DelToo))
         then U.Number := N;
   end;
   numUsers := FileSize(F);
   Close(F);
   userSearch := U.Number <> 0;
end;
(*
function userSelectName(ss : String) : Word;
var F : file; T : tUserIndexRec; Done : Boolean; S : String;
    Un, N : Integer;
begin
   userSeletName := 0;
   Assign(F,Cfg^.pathData+fileUserIndex);
   {$I-}
   Reset(F,SizeOf(tUserIndexRec));
   {$I+}
   if ioResult <> 0 then Exit;
   S := UpStr(ss);
   N := 0;
   Un := strToInt(S);
   if (Un > numUsers) or (Un < 1) then Un := 0;
   while (not Eof(F)) and (U.Number = 0) do
   begin
      BlockRead(F,T,1);
      Inc(N,1);
      if ((S = UpStr(T.UserName)) or (S = UpStr(T.RealName)) or (Un = N))
         and ((not T.Deleted) or (DelToo))
         then U.Number := N;
   end;
   numUsers := FileSize(F);
   Close(F);
   userSearch := U.Number <> 0;
end;
*)
procedure userReset;
var N : Word;
begin
   User^.Number := 1;
   if not userLoad(User^) then
   with User^ do
   begin
      Number       := 1;
      UserName     := 'SysOp';
      RealName     := 'System Operator';
      Password     := 'SYSOP';
      PhoneNum     := '(000)000-0000';
      BirthDate    := '01/01/80';
      Location     := 'Somewhere, XX';
      Address      := 'Unknown';
      UserNote     := 'SysOp';
      Sex          := 'M';
      SL           := 255;
      DSL          := 255;
      BaudRate     := 0;
      TotalCalls   := 1;
      curMsgArea   := 1;
      curFileArea  := 1;
      acFlag       := [acANSi,acYesNoBar,acHotKey,acPause,acQuote];
      Color        := Cfg^.DefaultCol;
      LastCall     := '01/01/89';
      PageLength   := 24;
      EmailWaiting := 0;
      Level        := 'E';
      timeToday    := 60;
      timePerDay   := 60;
      AutoSigLns   := 0;
      FillChar(AutoSig,SizeOf(AutoSig),0);
      confMsg      := 1;
      confFile     := 1;

      FirstCall    := dtDateString;
      StartMenu    := Cfg^.StartMenu;
      fileScan     := '01/01/80';
      SysOpNote    := 'None';
      Posts        := 0;
      Email        := 0;
      Uploads      := 0;
      Downloads    := 0;
      UploadKb     := 0;
      DownloadKb   := 0;
      CallsToday   := 0;
      Flag         := [];
      filePts      := 0;
      postCall     := 0;
      limitDL      := 0;
      limitDLkb    := 0;
      todayDL      := 0;
      todayDLkb    := 0;
      lastQwkDate  := 0;
      uldlRatio    := 0;
      kbRatio      := 0;
      textLib      := 1;
      zipCode      := '0000-0000';
      voteYes      := 0;
      voteNo       := 0;

      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

procedure userRebuildIndex;
var F : file of tUserIndexRec; uF : file of tUserRec; U : ^tUserRec;
      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

procedure userRebuildIndex;
var F : file of tUserIndexRec; uF : file of tUserRec; U : ^tUserRec;
    Idx : tUserIndexRec;
begin
   Assign(F,Cfg^.pathData+fileUserIndex);
   Assign(uF,Cfg^.pathData+fileUsers);
      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

procedure userRebuildIndex;
var F : file of tUserIndexRec; uF : file of tUserRec; U : ^tUserRec;
    Idx : tUserIndexRec;
begin
   Assign(F,Cfg^.pathData+fileUserIndex);
   Assign(uF,Cfg^.pathData+fileUsers);
    Idx : tUserIndexRec;
begin
   Assign(F,Cfg^.pathData+fileUserIndex);
   Assign(uF,Cfg^.pathData+fileUsers);
   {$I-}
   Reset(uF);
   {$I+}
   if ioResult <> 0 then Exit;
   numUsers := FileSize(uF);
   {$I-}
   Rewrite(F);
   {$I+}
   if ioResult <> 0 then Exit;

   New(U);
   while not Eof(uF) do
   begin
      Read(uF,U^);
      FillChar(Idx,SizeOf(Idx),0);
      Idx.Username := U^.Username;
      Idx.Realname := U^.Realname;
      Idx.Deleted  := acDeleted in U^.acFlag;
      Write(F,Idx);
   end;

   Close(F);
   Close(uF);
   Dispose(U);
end;

procedure userCheckIndex;
var F : file of tUserIndexRec; uF : file of tUserRec; uS, iS : LongInt; Ok : Boolean;
begin
   Assign(F,Cfg^.pathData+fileUserIndex);
   Assign(uF,Cfg^.pathData+fileUsers);
   {$I-}
   Reset(uF);
   {$I+}
   if ioResult <> 0 then Exit;
   uS := FileSize(uF);
   numUsers := uS;
   Close(uF);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Ok := False else
   begin
      Ok := True;
      iS := FileSize(F);
      Close(F);
   end;
   if (not Ok) or (iS <> uS) then userRebuildIndex;
end;

procedure userPrelogonInit;
begin
   with User^ do
   begin
      Number := 0;
      UserName := 'Unknown';
      RealName := 'Unknown';
      Password := '';
      PhoneNum := '(000)000-0000';
      BirthDate := '00/00/00';
      Location := 'Somewhere, XX';
      Address := 'Unknown';
      UserNote := 'None';
      Sex := 'M';
      SL := 25;
      DSL := 25;
{     BaudRate := BaudRate;}
      TotalCalls := 0;
      curFileArea := 1;
      curMsgArea := 1;
{     acFlag := [];}
      Color := Cfg^.DefaultCol;
      LastCall := '00/00/00';
      PageLength := 24;
      EmailWaiting := 0;
      Level := 'A';
      timeToday := 15;
      timePerDay := 15;
      AutoSigLns := 0;
      FillChar(AutoSig,SizeOf(AutoSig),0);
      confMsg := 1;
      confFile := 1;

      FirstCall := dtDateString;
      StartMenu := Cfg^.StartMenu;
      fileScan := '01/01/80';
      SysOpNote := 'None';
      Posts := 0;
      Email := 0;
      Uploads := 0;
      Downloads := 0;
      UploadKb := 0;
      DownloadKb := 0;
      CallsToday := 0;
      Flag := [];
      filePts := 0;
      postCall := 0;
      limitDL := 0;
      limitDLkb := 0;
      todayDL := 0;
      todayDLkb := 0;
      lastQwkDate := 0;
      uldlRatio := 0;
      kbRatio := 0;
      textLib := 1;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      zipCode := '0000-0000';
      voteYes := 0;
      voteNo := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
   end;
   macroNum := 0;
   macroPos := 0;
end;

procedure userLogonInit;
begin
   if (User^.LastCall <> dtDateString) or (Cfg^.TimeLimitPerCall) then User^.timeToday := User^.timePerDay;
   if not menuLaunch then
   begin
      if User^.LastCall <> dtDateString then
      begin
         User^.todayDL := 0;
         User^.todayDLkb := 0;
         User^.callsToday := 1;
      end else Inc(User^.CallsToday);
      Inc(User^.TotalCalls);
      User^.fileScan := User^.LastCall;
      User^.LastCall := dtDateString;
      userSave(User^);
      if (not LocalIO) or (Cfg^.AddLocalCalls) then
      begin
         Inc(Stat^.Calls);
         Inc(His^.Calls);
         statSave;
         hisSave;
      end;
      callAdd;
   end;
   timeEvent := 0;
   timeExtra := 0;
   timeFree  := 0;
   numPaged := 0;
   dtGetDateTime(TimeOn);
   TempSysOp := False;
   PausePos := 0;
   realSL := User^.SL;
   realDSL := User^.DSL;
   mandMsg := False;
   fConfAll := False;
   numPaged := 0;
   emailTag := 0;
   readTag := 0;
   numBatch := 0;
   useTag := False;
   chatReason := 'None';
   if User^.curMsgArea < 1 then User^.curMsgArea := 1 else
   if User^.curMsgArea > numMsgArea then User^.curMsgArea := 1;
   if User^.curFileArea < 1 then User^.curFileArea := 1 else
   if User^.curFileArea > numFileArea then User^.curFileArea := 1;
   fLibraryInstall;
end;

procedure userConfiguration(app : Boolean);
var Ans, B : Boolean; Ch, aCh : Char; aPos, dl, al, lib : Byte; ucDone : Boolean;
    S, D, A : String; N : Word; U : tUserRec;
 function ucActualKey : Char;
 var C, K : Char;
 begin
    C := #0;
    for K := 'A' to 'Z' do if userCfg[K] = Ch then C := K;
    ucActualKey := C;
 end;
 procedure ucShow(S : String);
 begin
    if sfGotoPos(aPos) then oCWrite(S);
 end;
begin
   ucDone := False;
   U := User^;
   lib := User^.textLib;
   FillChar(userCfg,SizeOf(userCfg),0);
   if App then Ans := sfShowTextfile(txNewConfig,ftUserConfig) else
               Ans := sfShowTextfile(txUserConfig,ftUserConfig);
   if not Ans then exit;
   if sfGotoPos(1) then  oWrite(U.Password);
   if sfGotoPos(2) then  oWrite(U.PhoneNum);
   if sfGotoPos(3) then  oWrite(U.BirthDate);
   if sfGotoPos(4) then  oWrite(U.Location);
   if sfGotoPos(5) then  oWrite(U.Address);
   if sfGotoPos(6) then  oCWrite(U.UserNote);
   if sfGotoPos(7) then  oWrite(St(U.PageLength));
   if sfGotoPos(8) then  oWrite(B2St(acYesNoBar in U.acFlag));
   if sfGotoPos(9) then  oWrite(B2St(acExpert in U.acFlag));
   if sfGotoPos(10) then oWrite(B2St(acHotKey in U.acFlag));
   if sfGotoPos(11) then oWrite(B2St(acPause in U.acFlag));
   if sfGotoPos(12) then oWrite(B2St(acQuote in U.acFlag));
   if sfGotoPos(13) then oWrite(mEmulation(U));
   if tLibOpen then D := textLib^.Desc else D := 'n/a';
   if tLibOpen then A := textLib^.Author else A := 'n/a';
   dl := Length(NoColor(d));
   al := Length(NoColor(a));
   if sfGotoPos(14) then oCWrite(D);
   if sfGotoPos(15) then oWrite(U.zipCode);
      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

         oSetCol(colInfoHi);
         case aCh of
           'A' : begin
                S := iReadString(U.Password,inUpper,chNormal,rsMin,20);
                if Length(S) >= 4 then U.Password := S;
                ucShow(U.Password);
             end;
           'B' : begin
                U.PhoneNum := iReadPhone(U.PhoneNum);
                ucShow(U.PhoneNum);
             end;
           'C' : begin
                S := iReadDate(U.BirthDate);
                if dtValidDate(S) then U.BirthDate := S;
                ucShow(U.BirthDate);
             end;
           'D' : begin
                U.Location := iReadString(U.Location,inNormal,chNormal,rsMin,40);
                ucShow(U.Location);
             end;
           'E' : begin
                U.Address := iReadString(U.Address,inMixed,chNormal,rsMin,36);
                ucShow(U.Address);
             end;
           'F' : begin
                U.UserNote := iReadString(U.UserNote,inNormal,chNormal,rsMin,40);
                ucShow(U.UserNote);
             end;
           'G' : begin
                N := strToInt(iReadString(St(U.PageLength),inUpper,chNumeric,'',3));
                if (N >= 5) and (N <= 500) then U.PageLength := N;
      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

procedure userRebuildIndex;
var F : file of tUserIndexRec; uF : file of tUserRec; U : ^tUserRec;
    Idx : tUserIndexRec;
begin
   Assign(F,Cfg^.pathData+fileUserIndex);
   Assign(uF,Cfg^.pathData+fileUsers);
                ucShow(St(U.PageLength));
             end;
           'H' : begin
                B := not (acYesNoBar in U.acFlag);
                if B then U.acFlag := U.acFlag+[acYesNoBar] else
                          U.acFlag := U.acFlag-[acYesNoBar];
                ucShow(Resize(B2St(B),3));
             end;
           'I' : begin
                B := not (acExpert in U.acFlag);
                if B then U.acFlag := U.acFlag+[acExpert] else
                          U.acFlag := U.acFlag-[acExpert];
                ucShow(Resize(B2St(B),3));
             end;
           'J' : begin
                B := not (acHotKey in U.acFlag);
                if B then U.acFlag := U.acFlag+[acHotKey] else
                          U.acFlag := U.acFlag-[acHotKey];
                ucShow(Resize(B2St(B),3));
             end;
           'K' : begin
                B := not (acPause in U.acFlag);
                if B then U.acFlag := U.acFlag+[acPause] else
                          U.acFlag := U.acFlag-[acPause];
                ucShow(Resize(B2St(B),3));
             end;
           'L' : begin
                B := not (acQuote in U.acFlag);
                if B then U.acFlag := U.acFlag+[acQuote] else
                          U.acFlag := U.acFlag-[acQuote];
                ucShow(Resize(B2St(B),3));
             end;
           'M' : begin
                U.acFlag := U.acFlag+[acAnsi];
                if acRip in U.acFlag then
                begin
                   U.acFlag := U.acFlag-[acRip];
                   U.acFlag := U.acFlag+[acAvatar];
                end else
                if acAvatar in U.acFlag then
                   U.acFlag := U.acFlag-[acAvatar] else
                   U.acFlag := U.acFlag+[acRip];
                ucShow(Resize(mEmulation(U),6));
             end;
           'N' : if (Cfg^.useTextLibs) and (numLib > 0) then begin
                if User^.textLib >= numLib then User^.textLib := 1 else
                   Inc(User^.textLib);
                fLibraryInstall;
                ucShow(strEnlarge(textLib^.Desc,dl));
                dl := Length(NoColor(textLib^.Desc));
                aPos := maxPos-2;
                ucShow(strEnlarge(textLib^.Author,al));
                al := Length(NoColor(textLib^.Author));
             end;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

           'O' : begin
                U.zipCode := iReadString(U.zipCode,inUpper,chNormal,rsMin,10);
                ucShow(U.zipCode);
             end;
         end;
      end;
   until ucDone;
   sfGotoPos(maxPos);
   if (not HangUp) and (Ch = #13) then
   begin
      U.textLib := User^.textLib;
      User^ := U;
      userSave(User^);
   end else
   if lib <> User^.textLib then
   begin
      User^.textLib := lib;
      fLibraryInstall;
   end;
end;

procedure userPassword;
var S, s2 : String; ok : Boolean;
begin
   oDnLn(1);
   oString(strPwAskOld);
   S := iReadString('',inUpper,chNormal,rsPassword+rsNoEdit,20);
   if S <> User^.Password then
   begin
      oStringLn(strPwWrong);
      Exit;
   end;
   Ok := False;
   repeat
      oString(strPwNewPassword);
      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

procedure userRebuildIndex;
var F : file of tUserIndexRec; uF : file of tUserRec; U : ^tUserRec;
    Idx : tUserIndexRec;
begin
   Assign(F,Cfg^.pathData+fileUserIndex);
   Assign(uF,Cfg^.pathData+fileUsers);
   if HangUp then Exit;
   Ok := False;
   oString(strPwValidate);
   s2 := iReadString('',inUpper,chNormal,rsPassword+rsNoEdit+rsMin,20);
   if S <> s2 then
   begin
      oStringLn(strPwNoMatch);
      Exit;
   end;
      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;


      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      levelChange(User^,'E');
   end;
      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

   userSave(User^);
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;
      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      FillChar(Reserved,SizeOf(Reserved),0);
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;

      voteYes      := 0;
      voteNo       := 0;
      voteNo       := 0;

      FillChar(Reserved,SizeOf(Reserved),0);
      levelChange(User^,'E');
   end;
   fLibraryInstall;
end;


