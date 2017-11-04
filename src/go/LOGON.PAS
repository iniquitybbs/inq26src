{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Logon;

interface

function  logonGetLogin : Boolean;
procedure logonInit;
procedure logonSystem;

implementation

uses Crt,
     Global, Output, Detect, Misc, Strings, Input, Files, ShowFile, MsgArea,
     StatBar, BBSinit, Levels, Apply, Callers, Logs, Users, FastIO;

procedure logonInit;
var Z : Byte; S, X : String;
begin
   PausePos := 0;
   if not ((LocalIO) and (Cfg^.SysOpAutologin)) then
   begin
      sbInfo('Initializing logon system...',True);
      User^.acFlag := User^.acFlag - [acANSi,acRIP,acAVATAR];
      if not LocalIO then
      begin
         Delay(1200);
         oDnLn(1); {ClrScr;}
         sbInfo('Attempting to detect emulation...',True);
         User^.BaudRate := BaudRate;
         ioTextAttr($07);
         oString(strDetectEmu);
         detEmulation;
         if DetANSi then User^.acFlag := User^.acFlag + [acANSI];
         if DetRIP then User^.acFlag := User^.acFlag + [acRIP];
         if DetAVATAR then User^.acFlag := User^.acFlag + [acAVATAR];
         if DetRIP then oStrLn(strCode(mStr(strDetectRIP),1,detRIPterminal)) else
         if DetAVATAR then oStringLn(strDetectAVATAR) else
         if DetANSi then oStringLn(strDetectANSI) else oStringLn(strDetectNone);
         if acRIP in User^.acFlag then    S := 'Rip terminal detected. ('+detRIPterminal+')' else
         if acAVATAR in User^.acFlag then S := 'Avatar/Ansi terminal detected.' else
         if acANSi in User^.acFlag then   S := 'Ansi terminal detected.' else
                                          S := 'Emulation detect failed. (Ansi enabled anyway)';
         sbInfo(S,True);
{}       User^.acFlag := User^.acFlag + [acANSI];
         User^.BaudRate := BaudRate;
         oStrLn(strCode(mStr(strConnectedAt),1,mBaudString(User^.BaudRate)));
         Delay(1200);
         oSetColor(7,0);
{         oClrScr;}
(*       X := '|U1שש |U3the '+bbsTitle+' bulletin board system |U1שש';
         oMoveRight(CenterPos(X));
         oStrCtrLn(X);
         oStrCtrLn('|U2/'+sRepeat('ִ',77)+'\');
         oStrCtr('|U2:');
         X := '|U1(c)copyright 1994-1995, mike fricker ש preliminary alpha test version';
         oMoveRight(CenterPos(X)-1);
         oStrCtrLn(X);
         X := '|U1version '+bbsVerLong+' ש release '+bbsRelease+', created by mike fricker [fiend]';
         oMoveRight(CenterPos(X));
         oStrCtr(X);
         oGotoXY(79,oWhereY);
         oStrCtrLn('|U2:');
         oStrCtrLn('|U2\'+sRepeat('ִ',77)+'/');
{$IFDEF iniRegistered}
         S := mRegString;
         while (Ord(S[0]) > 0) and (S[Ord(S[0])] = #0) do Dec(S[0]);
         if S <> 'None' then
         X := '|U1registered to: |U3'+CleanUp(S) else
         X := '|U1registered to: |U3fiend|U1, |U3eternity bbs';
         oMoveRight(CenterPos(X));
         oStrCtrLn(X);
{$ENDIF}
(*         oCWriteLn('|07 the |15'+bbsTitle+' |07bulletin board system|08 -- (|07c|08)|07copyright 1994-1995, mike fricker');
         oCWriteLn('|07 version |15'+bbsVersion+'|08 -- |07written by'+
                   ' |15mike fricker |08[|07fiend|08] |08-- |07release |15'+bbsRelease);}
         logWrite('Logon system initialized.  '+S);
         oCwriteLn('|08'+sRepeat('ִ',79));
{$IFDEF iniRegistered}
         oCwrite('|08-- |09R|01egistered |09t|01o|08: |09');
         if mRegString <> 'None' then oCwriteLn(mRegString) else
                                      oCwriteLn('Fiend|08, |01Eternity BBS');
{$ENDIF}
         Delay(2200);
         while oWhereY < 1 do
         begin
            oGotoXY(oWhereX,oWhereY-1);
            oClrEol;
         end;        *)
      end else
      begin
         detEmulation;
         User^.acFlag := User^.acFlag+[acANSi];
         User^.BaudRate := 0;
         oSetColor(7,0);
      end;
      oClrScr;
      sbInfo('',False);
      sfShowTextFile(txPrelogon,ftNormal);
   end;
   LoggedIn := False;
end;

procedure logonSystem;
var N : Byte; Ok : Boolean;
begin
   if (logonGetLogin) and (not LoggedIn) then applyToBBS;
   if (not LoggedIn) and (not Cfg^.MatrixLogin) then HangUp := True;
   if not ((LocalIO) and (Cfg^.SysOpAutoLogin)) then
   begin
      sfShowTextFile(txWelcome,ftNormal);
      N := 1;
      repeat
         Ok := sfShowTextFile(txWelcome+'.'+St(N),ftNormal);
         Inc(N,1);
      until (N > 9) or (not Ok);
      sfShowTextFile(txSL+St(User^.SL),ftNormal);
      sfShowTextFile(txDSL+St(User^.DSL),ftNormal);
   end;
end;

function logonGetLogin : Boolean;
var Found, Ans : Boolean; Pw, Un, Ph, Bd, sPw : String; Try : Word; Ok : Boolean;
    Len, iLen, hLen : Byte;

 procedure glWriteHelp(S : String);
 begin
    if (not Ans) or (not sfGotoPos(4)) then Exit;
    if hLen > 0 then
    begin
       oWrite(sRepeat(' ',hLen));
       sfGotoPos(4);
    end;
    hLen := Length(NoColor(S));
    oStr(S);
 end;

 procedure glWriteInfo(S : String);
 begin
    if (not Ans) or (not sfGotoPos(3)) then Exit;
    if iLen > 0 then
    begin
       oWrite(sRepeat(' ',iLen));
       sfGotoPos(3);
    end;
    iLen := Length(NoColor(S));
    oStr(S);
 end;

begin
   logonGetLogin := False;
   hLen := 0;
   iLen := 0;
   if (LocalIO) and (Cfg^.SysOpAutoLogin) then
   begin
      logWrite('*SysOp autologin initiated.');
      userReset;
      User^.BaudRate := 0;
      logonGetLogin := True;
      LoggedIn := True;
      Exit;
   end;
   sbInfo('Preparing login system.',True);
   Ans := sfShowTextFile(txLogin,ftLogin);
   Len := Length(NoColor(mStr(strLoginUnknown)));
   if Length(NoColor(mStr(strLoginError))) > Len then
      Len := Length(NoColor(mStr(strLoginError)));
   if Length(NoColor(mStr(strLoginAskApply)))+11 > Len then
      Len := Length(NoColor(mStr(strLoginAskApply)))+11;
   if not Ans then
   begin
      oClrScr;
      oGotoXY(1,8);
   end;
   Try := 0;
   Ok := False;
   User^.UserName := '';
   Pw := '';
   Un := '';
   repeat
      UserPrelogonInit;
      sbInfo('Awaiting user login.',True);
      if Ans then
      begin
         glWriteHelp(mStr(strLoginHelpName));
         glWriteInfo('');
         if Pw <> '' then
         begin
            sfClearPos(2,Length(Pw));
            sfClearPos(1,Length(Un));
         end else sfGotoPos(1);
      end else oString(strLoginName);
      Un := iReadString('',mAliasFormat,chNormal,rsNoEdit+rsMin,36);
      User^.UserName := Un;
      Ok := False;
      if (Cfg^.AskApply) and (upStr(User^.UserName) = 'NEW') then
      begin
         logWrite('User logged in as ''new''; application system loaded');
         Found := False;
         LoggedIn := False;
         Ok := True;
      end else Found := userSearch(User^,False);
      if (not Found) and (not Ok) then
      begin
         sbInfo('Unknown user.',True);
         if Ans then glWriteHelp(mStr(strLoginUnknown)) else
            oStringLn(strLoginUnknown);
         if Cfg^.AskApply then
         begin
            logWrite('-User not found in records ('+User^.Username+'), offering application');
            Pw := '--';
            if Ans then
            begin
               if not HangUp then Delay(1000);
               glWriteHelp(mStr(strLoginHelpApply));
               glWriteInfo(mStr(strLoginAskApply));
               Inc(iLen,10);
            end else oString(strLoginAskApply);
            Ok := iYesNo(False);
            LoggedIn := False;
         end else logWrite('-User not found in records ('+User^.Username+')');
      end;
      if (Found) and (userLoad(User^)) then
      begin
         sbInfo('|MUser |L[|H'+User^.Username+'|L] -- |MPassword |L[|H'+User^.Password+'|L]',True);
         glWriteHelp(mStr(strLoginHelpPw));
         if Ans then sfGotoPos(2) else oString(strLoginPassword);
         User^.BaudRate := BaudRate;
         Ph := '';
         Bd := '';
         Ok := True;
         Pw := iReadString('',inUpper,chNormal,rsNoEdit+rsPassword+rsMin,20);
         if (Cfg^.CallsPhone > 0) and (User^.TotalCalls mod Cfg^.CallsPhone = 0) then
         begin
            sbInfo('|MUser |L[|H'+User^.Username+'|L] -- |MPhone Number |L[|H'+User^.PhoneNum+'|L]',True);
            glWriteHelp(mStr(strLoginHelpPhone));
            if Ans then glWriteInfo(mStr(strLoginPhone)) else
               oString(strLoginPhone);
            Inc(iLen,4);
            Ph := iReadString('',inUpper,chNumeric,rsNoEdit+rsReq,4);
            if Ok then
            begin
               Ok := Ph = Copy(User^.PhoneNum,10,4);
               if not Ok then
               begin
                  logWrite('-User "'+User^.Username+'" failed phone number verification test');
                  logWrite('-Phone number is '+Copy(User^.PhoneNum,10,4)+'.  User entered '+Ph);
               end;
            end;
         end;
         if (Cfg^.CallsBirth > 0) and (User^.TotalCalls mod Cfg^.CallsBirth = 0) then
         begin
            sbInfo('|MUser |L[|H'+User^.Username+'|L] -- |MBirthdate |L[|H'+User^.Birthdate+'|L]',True);
            glWriteHelp(mStr(strLoginHelpBirth));
            if Ans then glWriteInfo(mStr(strLoginBDate)) else
               oString(strLoginBDate);
            Inc(iLen,8);
            Bd := iReadDate('');
            if Ok then
            begin
               Ok := Bd = User^.BirthDate;
               if not Ok then
               begin
                  logWrite('-User "'+User^.Username+'" failed birthdate verification test');
                  logWrite('-Birthdate is '+User^.Birthdate+'.  User entered '+Bd);
               end;
            end;
         end;
         if Ok then
         begin
            Ok := Pw = User^.Password;
            if not Ok then
            begin
               logWrite('-User "'+User^.Username+'" entered password incorrectly');
               logWrite('-Password is "'+User^.Password+'".  User entered "'+Pw+'"');
            end;
         end;
         if (Ok) and (Cfg^.SystemPW <> '') and (acsOk(Cfg^.acsSystemPWLogin)) then
         begin
            sbInfo('|MUser |L[|H'+User^.Username+'|L] -- |MAwaiting system password.',True);
            glWriteHelp(mStr(strLoginHelpSysPw));
            if Ans then glWriteInfo(mStr(strLoginSystemPW)) else
               oString(strLoginSystemPW);
            sPw := iReadString('',inUpper,chNormal,rsNoEdit+rsPassword+rsMin,20);
            Inc(iLen,Length(sPw));
            Ok := sPw = Cfg^.SystemPW;
            if not Ok then
            begin
               logWrite('-Incorrect system password entered');
               logWrite('-Received: '+sPw+'.  Real: '+Cfg^.SystemPW);
            end;
         end;
         if not Ok then
         begin
            sbInfo('Invaid login attempt.',True);
            if Ans then glWriteHelp(mStr(strLoginError)) else
               oStringLn(strLoginError);
            Delay(1000);
         end else LoggedIn := True;
      end;
      Inc(Try);
   until (HangUp) or (Ok) or ((Cfg^.LoginTrys > 0) and (Try >= Cfg^.LoginTrys));
   logonGetLogin := (Ok) and (not HangUp);
   sbInfo('',False);
end;

end.