{$A+,O+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-}
unit Apply;

interface


  procedure applyToBBS;

  implementation

    sfShowTextFile(txApply,ftNormal);

    if Cfg^.newVerify then
    begin
        oString(strNuAskApply);
        if not iYesNo(True) then Exit;
    end;

    logWrite('-New user app process started');

    oDnLn(1);

    Ok := False;
    if Cfg^.NewUserPW <> '' then
    begin
        oString(strNuEnterNewUserPW);
        S := iReadString('',inUpper,chNormal,rsNoEdit+rsPassword+rsMin,20);
        if S <> Cfg^.NewUserPW then
        begin
          oStringLn(strNuBadNewUserPW);
          logWrite('-Incorrect application password entered ('+S+').  Aborting.');
        end else Ok := True;
    end else Ok := True;
    if (not Ok) or (HangUp) then Exit;

    Ok := False;
    if not Cfg^.RealNameSystem then
    begin
        repeat
          oString(strNuHandle);
          User^.UserName := iReadString('',mAliasFormat,chNormal,rsMin,36);
          if (UpStr(User^.UserName) = 'NEW') or (UpStr(User^.UserName) = 'ALL') or
              (User^.UserName[1] in ['0'..'9']) then
          begin
              oStringLn(strNuBadAlias);
              logWrite('Invalid new user alias entered ('+User^.Username+').');
          end else
          if userSearch(User^,True) then
          begin
              oStringLn(strNuDupUser);
              logWrite('New user entered duplicate handle ('+User^.Username+').');
          end else Ok := True;
        until (HangUp) or (Ok);
        if HangUp then Exit;
    end;

    Ok := False;
    S := User^.UserName;
    repeat
        oString(strNuName);
        User^.RealName := iReadString('',inMixed,chNormal,rsMin,36);
        User^.UserName := User^.RealName;
        if (User^.UserName[1] in ['0'..'9']) then
        begin
          oStringLn(strNuBadName);
          logWrite('Invalid real name entered in application ('+User^.UserName+').');
        end else
        if Pos(' ',User^.UserName) = 0 then
        begin
          oStringLn(strNuFullName);
          oStringLn(strNuFullName);
          logWrite('User did not enter FULL real name ('+User^.Username+').');
        end else
        if userSearch(User^,True) then
        begin
          oStringLn(strNuDupUser);
          logWrite('New user entered duplicate real name ('+User^.Username+').');
        end else Ok := True;
    until (Ok) or (HangUp);
          logWrite('User did not enter FULL real name ('+User^.Username+').');
        end else
        if userSearch(User^,True) then
        begin
          oStringLn(strNuDupUser);
          logWrite('New user entered duplicate real name ('+User^.Username+').');
          oStringLn(strNuFullName);
          logWrite('User did not enter FULL real name ('+User^.Username+').');
        end else
        if userSearch(User^,True) then
        begin
          oStringLn(strNuDupUser);
          logWrite('New user entered duplicate real name ('+User^.Username+').');
        end else Ok := True;
    until (Ok) or (HangUp);
          oStringLn(strNuFullName);
          logWrite('User did not enter FULL real name ('+User^.Username+').');
        end else
        if userSearch(User^,True) then
        begin
          oStringLn(strNuDupUser);
          logWrite('New user entered duplicate real name ('+User^.Username+').');
        end else Ok := True;
    until (Ok) or (HangUp);
        end else Ok := True;
    until (Ok) or (HangUp);
    if HangUp then Exit;
    User^.UserName := S;
    if Cfg^.RealNameSystem then User^.Username := User^.Realname;

    Ok := False;
    repeat
          oStringLn(strNuFullName);
          logWrite('User did not enter FULL real name ('+User^.Username+').');
        end else
        if userSearch(User^,True) then
        begin
          oStringLn(strNuDupUser);
          logWrite('New user entered duplicate real name ('+User^.Username+').');
        end else Ok := True;
    until (Ok) or (HangUp);
          oStringLn(strNuFullName);
          logWrite('User did not enter FULL real name ('+User^.Username+').');
        end else
        if userSearch(User^,True) then
        begin
          oStringLn(strNuDupUser);
          logWrite('New user entered duplicate real name ('+User^.Username+').');
        end else Ok := True;
    until (Ok) or (HangUp);
        oString(strNuBirthDate);
        User^.BirthDate := iReadDate('');
        if (dtValidDate(User^.Birthdate)) and (dtAge(User^.BirthDate) < 3) or
          (dtAge(User^.BirthDate) > 90) then
        begin
          oStringLn(strNuBadBirth);
          logWrite('Invalid birthdate entered.');
        end else Ok := True;
    until (Ok) or (HangUp);
    if HangUp then Exit;

    oStrLn(strCode(mStr(strNuYourAgeIs),1,St(dtAge(User^.BirthDate))));

    oString(strNuPhoneNum);
    User^.PhoneNum := iReadPhone('');

    oString(strNuAddress);
    User^.Address := iReadString('',inMixed,chNormal,rsMin,36);

    oString(strNuLocation);
    User^.Location := iReadString('',inMixed,chNormal,rsMin,36);

    oString(strNuAskCountry);
    repeat
        ch := UpCase(iReadKey);
    until (HangUp) or (ch in ['U','C','O']);
    if HangUp then Exit;
    case ch of
      'U' : oWriteLn('USA');
      'C' : oWriteLn('Canada');
      'O' : oWriteLn('Other');
    end;

    if ch in ['U','C'] then
    begin
        oString(strNuAskState);
        S := iReadString('',inUpper,chAlpha,rsReq,2);
    end else
    begin
        oString(strNuEnterCountry);
        S := iReadString('',inMixed,chNormal,rsMin,20);
    end;
    User^.Location := User^.Location+', '+S;

    case ch of
      'U' : S := '#####-####';
      'C' : S := 'l#l-l#l';
      'O' : S := 'n/a';
    end;

    oStr(strCode(mStr(strNuEnterZipCode),1,S));
    case ch of
      'U' : User^.ZipCode := iReadZipCode;
      'C' : User^.ZipCode := iReadPostalCode;
      'O' : User^.ZipCode := iReadString('',inUpper,chNormal,rsMin,10);
    end;

    oString(strNuAskSex);
    repeat
        User^.Sex := UpCase(iReadKey);
    until (HangUp) or (User^.Sex in ['M','F']);
    if HangUp then Exit;
    case User^.Sex of
      'M' : oWriteLn('Male');
      'F' : oWriteLn('Female');
    end;

    if Cfg^.NewAskPageLen then
    begin
        oString(strNuAskPageLen);
        User^.PageLength := StrToInt(iReadString(St(Cfg^.DefaultPageLen),inUpper,chNumeric,'',3));
        if User^.PageLength < 5 then User^.PageLength := 5;
        if User^.PageLength > 200 then User^.PageLength := 200;
    end else User^.PageLength := Cfg^.DefaultPageLen;

    User^.acFlag := [acANSi,acPause];

    B := Cfg^.newHotKeys;
    if Cfg^.NewAskHotKeys then
    begin
        oString(strNuHotKey);
        B := iYesNo(Cfg^.newHotKeys);
    end;
    if B then User^.acFlag := User^.acFlag+[acHotKey];

    B := Cfg^.newExpert;
    if Cfg^.NewAskExpert then
    begin
        oString(strNuExpertMode);
        B := iYesNo(Cfg^.newExpert);
    end;
    if B then User^.acFlag := User^.acFlag+[acExpert];

    B := Cfg^.newPause;
    if Cfg^.NewAskPause then
    begin
        oString(strNuPausing);
        B := iYesNo(Cfg^.newPause);
    end;
    if not B then User^.acFlag := User^.acFlag-[acPause];

    B := Cfg^.newQuote;
    if Cfg^.NewAskQuote then
    begin
        oString(strNuAutoQuote);
        B := iYesNo(Cfg^.newQuote);
    end;
    if B then User^.acFlag := User^.acFlag+[acQuote];

    B := Cfg^.newYesNoBars;
    if Cfg^.NewAskYesNoBars then
    begin
        oString(strNuYesNoBar);
        B := iYesNo(Cfg^.newYesNoBars);
    end;
    if B then User^.acFlag := User^.acFlag+[acYesNoBar];

    repeat
        Ok := False;
        repeat
          oString(strNuPassword);
          User^.Password := iReadString('',inUpper,chNormal,rsPassword+rsNoEdit+rsMin,20);
          if Length(User^.Password) < 4 then
          begin
              oStringLn(strNuSmallPassword);
              logWrite('New user entered small password ('+User^.Password+').');
          end else Ok := True;
        until (HangUp) or (Ok);
        if HangUp then Exit;
        Ok := False;
        oString(strNuValidatePW);
        S := iReadString('',inUpper,chNormal,rsPassword+rsNoEdit+rsMin,20);
        if S <> User^.Password then
        begin
          oStringLn(strNuPWnoMatch);
          logWrite('New user failed to verify password.');
        end else Ok := True;
    until (HangUp) or (Ok);
    if HangUp then Exit;

    logWrite('New user successfully completed application.');

    User^.TotalCalls := 0;
    User^.BaudRate := BaudRate;
    User^.SL := 25;
    User^.DSL := 25;
    User^.Color := Cfg^.DefaultCol;
    User^.UserNote := 'New User Access';       { ----------- }
    User^.Level := 'A';
    User^.LastCall := dtDateString;
    User^.curMsgArea := 1;
    User^.curFileArea := 1;
    User^.confMsg := 1;
    User^.confFile := 1;

    User^.FirstCall := dtDateString;
    User^.StartMenu := Cfg^.StartMenu;
    User^.fileScan := '01/01/80';
    User^.SysOpNote := 'None';
    User^.Posts := 0;
    User^.Email := 0;
    User^.Uploads := 0;
    User^.Downloads := 0;
    User^.UploadKb := 0;
    User^.DownloadKb := 0;
    User^.CallsToday := 0;
    User^.Flag := [];
    User^.filePts := 0;
    User^.postCall := 0;
    User^.limitDL := 0;
    User^.limitDLkb := 0;
    User^.todayDL := 0;
    User^.todayDLkb := 0;
    User^.lastQwkDate := 0;
    User^.uldlRatio := 0;
    User^.kbRatio := 0;

    levelChange(User^,'A');

    oString(strNuSavingInfo);

    NewUserOn := True;
          oStringLn(strNuFullName);
          logWrite('User did not enter FULL real name ('+User^.Username+').');
        end else
        if userSearch(User^,True) then
        begin
          oStringLn(strNuDupUser);
          logWrite('New user entered duplicate real name ('+User^.Username+').');
        end else Ok := True;
    until (Ok) or (HangUp);

    userAdd(User^);
    with Scan^ do
    begin
        scnMsg := True;
        ptrMsg := 0;
    end;
          oStringLn(strNuFullName);
          logWrite('User did not enter FULL real name ('+User^.Username+').');
        end else
        if userSearch(User^,True) then
        begin
          oStringLn(strNuDupUser);
          logWrite('New user entered duplicate real name ('+User^.Username+').');
        end else Ok := True;
    until (Ok) or (HangUp);
          oStringLn(strNuFullName);
          logWrite('User did not enter FULL real name ('+User^.Username+').');
        end else
        if userSearch(User^,True) then
        begin
          oStringLn(strNuDupUser);
          logWrite('New user entered duplicate real name ('+User^.Username+').');
        end else Ok := True;
    until (Ok) or (HangUp);
    maUpdateAllScanFiles;
    maSaveScan(Scan^,User^.Number);
    ifResetUser(User^.Number);
    nuvReset(User^.Number);

    Inc(His^.NewUsers);
    hisSave;

    userConfiguration(True);

    logWrite('New user information saved');

    if not Cfg^.MatrixLogin then LoggedIn := True;

    oDnLn(1);
  end;
end.
