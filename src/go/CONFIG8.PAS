{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config8;

interface

procedure cfgUserEditor(uN : Word);

implementation

uses Global, Config, Strings, Files, Misc, Input, Logs, Output, Levels,
     Users, AutoSig, Infoform;

procedure cfgUserColors(var Col : tColor);
var B : Boolean; U, N : Word;
begin
   cfgDraw := True;
   cfgOver := False;
   cfgDone := False;
   repeat
      cfgInit('User Color Configuration');
      cfgCol := 30;
      cfgItem('A Normal text',40,  strColor(Col[colText]),'');
      cfgItem('B Dark text',40,    strColor(Col[colTextLo]),'');
      cfgItem('C Bright text',40,  strColor(Col[colTextHi]),'');
      cfgItem('D Normal info',40,  strColor(Col[colInfo]),'');
      cfgItem('E Dark info',40,    strColor(Col[colInfoLo]),'');
      cfgItem('F Bright info',40,  strColor(Col[colInfoHi]),'');
      cfgItem('G Menu item',40,    strColor(Col[colItem]),'');
      cfgItem('H Selected item',40,strColor(Col[colItemSel]),'');
      cfgItem('I Line/border',40,  strColor(Col[colBorder]),'');
      cfgItem('J Error/warning',40,strColor(Col[colError]),'');
      cfgItem('K Input color',40,   strColor(Col[colEdit]),'');
      if cfgDraw then
      begin
         Inc(cfgLn);
         Inc(cfgBot);
      end;
      if cfgDraw and (not cfgOver) then
      begin
         oSetCol(colBorder);
         oDnLn(1);
         oWriteLn(sRepeat('Ä',79));
      end;
      cfgItem('1 Set to defaults',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
         'A' : cfgReadColor(Col[colText]);
         'B' : cfgReadColor(Col[colTextLo]);
         'C' : cfgReadColor(Col[colTextHi]);
         'D' : cfgReadColor(Col[colInfo]);
         'E' : cfgReadColor(Col[colInfoLo]);
         'F' : cfgReadColor(Col[colInfoHi]);
         'G' : cfgReadColor(Col[colItem]);
         'H' : cfgReadColor(Col[colItemSel]);
         'I' : cfgReadColor(Col[colBorder]);
         'J' : cfgReadColor(Col[colError]);
         'K' : cfgReadColor(Col[colEdit]);
         '1' : begin
            Col := Cfg^.DefaultCol;
            cfgOver := True; cfgDraw := True;
         end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgUserPrefs(var U : tUserRec);
var B : Boolean;
begin
   cfgDraw := True;
   cfgOver := False;
   cfgDone := False;
   repeat
      cfgInit('User Preference Editor');
      cfgCol := 22;
      cfgItem('1 Yes/No bars',3,b2St(acYesNoBar in U.acFlag),
              'Does user have Yes/No selection bars activated?');
      cfgItem('2 Expert mode',3,b2St(acExpert in U.acFlag),
              'Does user have "expert" mode enabled?');
      cfgItem('3 Hot keys',3,b2St(acHotKey in U.acFlag),
              'Does user have "hot key" menu entry mode activated?');
      cfgItem('4 Screen pausing',3,b2St(acPause in U.acFlag),
              'Does user have screen pausing enabled?');
      cfgItem('5 Autoquote',3,b2St(acQuote in U.acFlag),
              'Does user want message autoquoting?');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        '1' : begin
                 B := acYesNoBar in U.acFlag;
                 cfgReadBoolean(B);
                 if not B then U.acFlag := U.acFlag - [acYesNoBar] else
                               U.acFlag := U.acFlag + [acYesNoBar];
                 cfgSetItem(B2St(B));
              end;
        '2' : begin
                 B := acExpert in U.acFlag;
                 cfgReadBoolean(B);
                 if not B then U.acFlag := U.acFlag - [acExpert] else
                               U.acFlag := U.acFlag + [acExpert];
                 cfgSetItem(B2St(B));
              end;
        '3' : begin
                 B := acHotKey in U.acFlag;
                 cfgReadBoolean(B);
                 if not B then U.acFlag := U.acFlag - [acHotKey] else
                               U.acFlag := U.acFlag + [acHotKey];
                 cfgSetItem(B2St(B));
              end;
        '4' : begin
                 B := acPause in U.acFlag;
                 cfgReadBoolean(B);
                 if not B then U.acFlag := U.acFlag - [acPause] else
                               U.acFlag := U.acFlag + [acPause];
                 cfgSetItem(B2St(B));
              end;
        '5' : begin
                 B := acQuote in U.acFlag;
                 cfgReadBoolean(B);
                 if not B then U.acFlag := U.acFlag - [acQuote] else
                               U.acFlag := U.acFlag + [acQuote];
                 cfgSetItem(B2St(B));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgUserEditor(uN : Word);
var optSex : array[1..2] of String;
    numU, uuN : Word; U : tUserRec;
    Sx, eMode, sa1, sa2, sb1, sb2, sb3, sc1, sc2, sc3, sc4,
    num,       ca1, ca2, cb1, cb2, cb3, cc1, cc2, cc3, cc4 : Byte;
    F : file of tUserRec; B, any : Boolean;
    S, Us : String;
begin
   optSex[1] := 'Male';
   optSex[2] := 'Female';
   userSave(User^);
   Assign(F,Cfg^.pathData+fileUsers);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   numU := FileSize(F);
   Close(F);
   if numU < 1 then Exit;
   if (uN = 0) or (uN > numU) then uN := 1;
   U.Number := uN;
   if not userLoad(U) then Exit;
   logWrite('*User edit.');
   eMode := 1;

   sa1 := 1;
   sa2 := 40;

   sb1 := 1;
   sb2 := 26;
   sb3 := 52;

   sc1 := 1;
   sc2 := 20;
   sc3 := 40;
   sc4 := 60;

   ca1 := 17;
   ca2 := 57;

   cb1 := 17;
   cb2 := 43;
   cb3 := 69;

   cc1 := 10;
   cc2 := 30;
   cc3 := 50;
   cc4 := 70;

   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit(bbsTitle+' v'+bbsVersion+' User Editor');
      if acDeleted in U.acFlag then S := '|U1[|U3Deleted|U1]' else S := U.Username;
      if U.Sex = 'M' then Sx := 1 else Sx := 2;
      cfgItemXY(sb1,1,cb1,'/ Current #',12,St(uN)+' of '+St(numU),'');
      cfgItemXY(40,1,1,'[ Previous',0,'','');
      cfgItemXY(59,1,1,'] Next',0,'','');

      cfgItemXY(sa1,2 ,ca1,'A Handle',22,S,
                'User''s handle or alias');
      cfgItemXY(sa2,2 ,ca2,'B Password',22,U.Password,
                'User''s password.  Should be at least 4 characters.  Used when logging in');

      cfgItemXY(sa1,3 ,ca1,'C Real name',22,U.Realname,
                'User''s real first and last name');
      cfgItemXY(sa2,3 ,ca2,'D Phone number',13,U.PhoneNum,
                'User''s voice phone number');

      cfgItemXY(sa2,4 ,ca2,'E Location',22,U.Location,
                'User''s location  [format: city, state]');
      cfgItemXY(sa1,4 ,ca1,'F Address',22,U.Address,
                'User''s street address');

      cfgItemXY(sa2,5 ,ca2,'G Usernote',22,U.UserNote,
                'Usernote for this user');
      cfgItemXY(sa1,5 ,ca1,'H SysOp note',22,U.SysOpNote,
                'SysOp note/comment for this user');

      cfgItemXY(sa1,6, ca1,'= User flags',28,cfgFlags(U.Flag),'User''s flags');
      cfgItemXY(sb3,6 ,cb3,'# Zip code',10,U.ZipCode,
                'This user''s zip/postal code');

      cfgItemXY(sb1,7 ,cb1,'I Birthdate',8,U.Birthdate,
                'User''s date of birth [format: mm/dd/yy]');
      cfgItemXY(sb2,7 ,cb2,'J Gender',6,cfgOption(optSex,Sx),
                'User''s sex');
      cfgItemXY(sb3,7 ,cb3,'K Baudrate',6,St(U.Baudrate),
                'User''s baudrate (from previous login)');

      cfgItemXY(sb1,8 ,cb1,'L Level ID',1,U.Level,
                'User''s current access level identification');
      cfgItemXY(sb2,8 ,cb2,'M SL',3,St(U.SL),
                'User''s security level (SL)');
      cfgItemXY(sb3,8 ,cb3,'N DSL',3,St(U.DSL),
                'User''s download (file) security level');

      cfgItemXY(sb1,9,cb1,'O Msg area',4,St(U.curMsgArea),
                'User''s current message area number');
      cfgItemXY(sb2,9,cb2,'P File area',4,St(U.curFileArea),
                'User''s current file area number');
      cfgItemXY(sb3,9,cb3,'Q File pts',5,St(U.filePts),
                'Number of file points user has');

      cfgItemXY(sb1,10,cb1,'R Calls',5,St(U.TotalCalls),
                'User''s total number of calls to the system.');
      cfgItemXY(sb2,10,cb2,'S Last call',8,U.LastCall,
                'Date of user''s last call to the system');
      cfgItemXY(sb3,10,cb3,'T First call',8,U.FirstCall,
                'Date of this user''s first call to the system');

      cfgItemXY(sb1,11,cb1,'U Start menu',8,U.StartMenu,
                'Starting menu for this user');
      cfgItemXY(sb2,11,cb2,'V Page length',3,St(U.PageLength),
                'User''s terminal screen size in rows');
      cfgItemXY(sb3,11,cb3,'W Email now',5,St(U.EmailWaiting),
                'Number of email messages user has currently waiting');

      cfgItemXY(sb1,12,cb1,'X Time today',5,St(U.timeToday),
                'User''s time remaining today');
      cfgItemXY(sb2,12,cb2,'Y Time p/day',5,St(U.timePerDay),
                'User''s daily online time');
      cfgItemXY(sb3,12,cb3,'Z Calls today',5,St(U.CallsToday),
                'Number of times user has called today');

      cfgItemXY(sb1,13,cb1,'1 Posts',5,St(U.Posts),
                'User''s total number of public messages posted');
      cfgItemXY(sb2,13,cb2,'2 Email',5,St(U.Email),
                'User''s total number of private messages sent');
      cfgItemXY(sb3,13,cb3,'3 Post/call %',5,St(U.PostCall)+'%',
                'Percent of calls for each post user can make to keep post:call ratio ok');

      cfgItemXY(sb1,14,cb1,'4 Uploads',5,St(U.Uploads),
                'User''s total number of files uploaded');
      cfgItemXY(sb2,14,cb2,'5 Downloads',5,St(U.Downloads),
                'User''s total number of files downloaded');
      cfgItemXY(sb3,14,cb3,'6 Daily DL',5,St(U.limitDL),
                'Maximum number of files user may download in one day');

      cfgItemXY(sb1,15,cb1,'7 UL Kb',5,St(U.UploadKb)+'k',
                'User''s total number of kilobytes uploaded');
      cfgItemXY(sb2,15,cb2,'8 DL Kb',5,St(U.DownloadKb)+'k',
                'User''s total number of kilobytes downloaded');
      cfgItemXY(sb3,15,cb3,'9 Daily Kb',5,St(U.limitDLkb)+'k',
                 'Maximum number of kilobytes user may download in one day');

      cfgItemXY(sb1,16,cb1,'0 UL/DL ratio',5,St(U.uldlRatio),
                'Number of files user can download per each upload');
      cfgItemXY(sb2,16,cb2,'! U/D Kb ratio',5,St(U.kbRatio)+'k',
                'Number of kilobytes user can download per each kilobyte uploaded');
      cfgItemXY(sb3,16,cb3,'@ Textfile lib',3,St(U.textLib),
                'Current textfile library user has selected for display');

      cfgItemXY(sb1,17,cb1,'% "Yes" votes',3,St(U.voteYes),
                'Number of "yes" votes this user currently has (new user voting)');
      cfgItemXY(sb2,17,cb2,'$ "No" votes',3,St(U.voteNo),
                'Number of "no" votes this user currently has (new user voting)');

      cfgItemXY(sc1,18,cc1,'- Edit colors',0,'','');
      cfgItemXY(sc2,18,cc2,'+ Autosignature',0,'','');
      cfgItemXY(sc3,18,cc3,'? Edit user prefs',0,'','');
      cfgItemXY(sc4,18,cc4,'> Upgrade access',0,'','');

      cfgItemXY(sc1,19,cc1,'& View infoforms',0,'','');
      cfgItemXY(sc2,19,cc2,'~ Clear infoforms',0,'','');
      cfgItemXY(sc3,19,cc3,'* Delete user',0,'','');
      cfgItemXY(sc4,19,cc4,'< Lower access',0,'','');
      cfgBot := 19;
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        '/' : begin
                 cfgInfo('|U4User to edit (name/number)|U5: |U6');
                 Us := iReadString('',inUpper,chNormal,rsNoCR,36);
                 if Us <> '' then
                 begin
                    userSave(U);
                    Inc(cfgStat,Length(Us));
                    uuN := uN;
                    U.Username := Us;
                    if userSearch(U,True) then uN := U.Number else uN := uuN;
                    U.Number := uN;
                    userLoad(U);
                    cfgDraw := True;
                    cfgOver := True;
                 end;
                 cfgInfo('');
              end;
        '[' : begin
                 userSave(U);
                 if uN = 1 then uN := numU else Dec(uN);
                 U.Number := uN;
                 userLoad(U);
                 cfgDraw := True;
                 cfgOver := True;
              end;
        ']' : begin
                 userSave(U);
                 if uN = numU then uN := 1 else Inc(uN);
                 U.Number := uN;
                 userLoad(U);
                 cfgDraw := True;
                 cfgOver := True;
              end;
        'A' : if not (acDeleted in U.acFlag) then
              begin
                 cfgEditInfo(U.Username,36,inNormal,chNormal,'',False);
                 U.Username := cfgRead;
                 cfgSetItem(U.Username);
              end;
        'B' : begin
                 cfgReadInfo(U.Password,inUpper,chNormal,'',False);
                 U.Password := cfgRead;
                 cfgSetItem(U.Password);
              end;
        'C' : begin
                 cfgEditInfo(U.Realname,36,inNormal,chNormal,'',False);
                 U.Realname := cfgRead;
                 cfgSetItem(U.Realname);
              end;
        'D' : begin
                 cfgReadPhone;
                 U.PhoneNum := cfgRead;
                 cfgSetItem(U.PhoneNum);
              end;
        'E' : begin
                 cfgEditInfo(U.Location,40,inNormal,chNormal,'',False);
                 U.Location := cfgRead;
                 cfgSetItem(U.Location);
              end;
        'F' : begin
                 cfgEditInfo(U.Address,36,inNormal,chNormal,'',False);
                 U.Address := cfgRead;
                 cfgSetItem(U.Address);
              end;
        'G' : begin
                 cfgEditInfo(U.UserNote,40,inNormal,chNormal,'',False);
                 U.UserNote := cfgRead;
                 cfgSetItem(U.UserNote);
              end;
        'H' : begin
                 cfgReadInfo(U.SysOpNote,inNormal,chNormal,'',False);
                 U.SysOpNote := cfgRead;
                 cfgSetItem(U.SysOpNote);
              end;

        '=' : begin
                 cfgReadFlags(U.Flag);
                 cfgSetItem(cfgFlags(U.Flag));
              end;
        '#' : begin
                 cfgReadInfo(U.ZipCode,inUpper,chNormal,'',False);
                 U.ZipCode := cfgRead;
                 cfgSetItem(U.ZipCode);
              end;

        'I' : begin
                 cfgReadDate;
                 U.BirthDate := cfgRead;
                 cfgSetItem(U.Birthdate);
              end;
        'J' : begin
                 cfgReadOption(optSex,2,Sx);
                 if Sx = 1 then U.Sex := 'M' else U.Sex := 'F';
                 cfgSetItem(cfgOption(optSex,Sx));
              end;
        'K' : begin
                 cfgReadInfo(St(U.BaudRate),inUpper,chNumeric,'',False);
                 U.Baudrate := mClip(strToInt(cfgRead),0,38400);
                 cfgSetItem(St(U.BaudRate));
              end;
        'L' : begin
                 cfgReadInfo(U.Level,inUpper,chAlpha,'',False);
                 U.Level := cfgRead[1];
                 cfgSetItem(U.Level);
              end;
        'M' : begin
                 cfgReadInfo(St(U.SL),inUpper,chNumeric,'',False);
                 U.SL := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(U.SL));
              end;
        'N' : begin
                 cfgReadInfo(St(U.DSL),inUpper,chNumeric,'',False);
                 U.DSL := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(U.DSL));
              end;
        'O' : begin
                 cfgReadInfo(St(U.curMsgArea),inUpper,chNumeric,'',False);
                 U.curMsgArea := mClip(StrToInt(cfgRead),1,64000);
                 cfgSetItem(St(U.curMsgArea));
              end;
        'P' : begin
                 cfgReadInfo(St(U.curFileArea),inUpper,chNumeric,'',False);
                 U.curFileArea := mClip(StrToInt(cfgRead),1,64000);
                 cfgSetItem(St(U.curFileArea));
              end;
        'Q' : begin
                 cfgReadInfo(St(U.filePts),inUpper,chNumeric,'',False);
                 U.filePts := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.filePts));
              end;
        'R' : begin
                 cfgReadInfo(St(U.TotalCalls),inUpper,chNumeric,'',False);
                 U.TotalCalls := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.TotalCalls));
              end;
        'S' : begin
                 cfgReadDate;
                 U.LastCall := cfgRead;
                 cfgSetItem(U.LastCall);
              end;
        'T' : begin
                 cfgReadDate;
                 U.FirstCall := cfgRead;
                 cfgSetItem(U.FirstCall);
              end;
        'U' : begin
                 cfgReadInfo(U.StartMenu,inUpper,chFileNoExt,'',True);
                 U.StartMenu := cfgRead;
                 cfgSetItem(U.StartMenu);
              end;
        'V' : begin
                 cfgReadInfo(St(U.PageLength),inUpper,chNumeric,'',False);
                 U.PageLength := mClip(StrToInt(cfgRead),4,200);
                 cfgSetItem(St(U.PageLength));
              end;
        'W' : begin
                 cfgReadInfo(St(U.EmailWaiting),inUpper,chNumeric,'',False);
                 U.EmailWaiting := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.EmailWaiting));
              end;
        'X' : begin
                 cfgReadInfo(St(U.timeToday),inUpper,chNumeric,'',False);
                 U.timeToday := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.timeToday));
              end;
        'Y' : begin
                 cfgReadInfo(St(U.timePerDay),inUpper,chNumeric,'',False);
                 U.timePerDay := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.timePerDay));
              end;
        'Z' : begin
                 cfgReadInfo(St(U.CallsToday),inUpper,chNumeric,'',False);
                 U.CallsToday := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.CallsToday));
              end;
        '1' : begin
                 cfgReadInfo(St(U.Posts),inUpper,chNumeric,'',False);
                 U.Posts := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.Posts));
              end;
        '2' : begin
                 cfgReadInfo(St(U.Email),inUpper,chNumeric,'',False);
                 U.Email := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.Email));
              end;
        '3' : begin
                 cfgSetItem('         ');
                 cfgReadInfo(St(U.PostCall),inUpper,chNumeric,'',True);
                 U.PostCall := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.PostCall)+'%');
              end;
        '4' : begin
                 cfgReadInfo(St(U.Uploads),inUpper,chNumeric,'',False);
                 U.Uploads := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.Uploads));
              end;
        '5' : begin
                 cfgReadInfo(St(U.Downloads),inUpper,chNumeric,'',False);
                 U.Downloads := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.Downloads));
              end;
        '6' : begin
                 cfgReadInfo(St(U.limitDL),inUpper,chNumeric,'',False);
                 U.limitDL := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.limitDL));
              end;
        '7' : begin
                 cfgSetItem('         ');
                 cfgReadInfo(St(U.UploadKb),inUpper,chNumeric,'',False);
                 U.UploadKb := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.UploadKb)+'k');
              end;
        '8' : begin
                 cfgSetItem('         ');
                 cfgReadInfo(St(U.DownloadKb),inUpper,chNumeric,'',False);
                 U.DownloadKb := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.DownloadKb)+'k');
              end;
        '9' : begin
                 cfgSetItem('         ');
                 cfgReadInfo(St(U.limitDLkb),inUpper,chNumeric,'',False);
                 U.limitDLkb := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.limitDLkb)+'k');
              end;

        '0' : begin
                 cfgReadInfo(St(U.uldlRatio),inUpper,chNumeric,'',False);
                 U.uldlRatio := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.uldlRatio));
              end;
        '!' : begin
                 cfgSetItem('         ');
                 cfgReadInfo(St(U.kbRatio),inUpper,chNumeric,'',False);
                 U.kbRatio := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(U.kbRatio)+'k');
              end;
        '@' : begin
                 cfgReadInfo(St(U.textLib),inUpper,chNumeric,'',False);
                 U.textLib := mClip(StrToInt(cfgRead),1,numLib);
                 cfgSetItem(St(U.textLib));
              end;
        '%' : begin
                 cfgReadInfo(St(U.voteYes),inUpper,chNumeric,'',False);
                 U.voteYes := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(U.voteYes));
              end;
        '$' : begin
                 cfgReadInfo(St(U.voteNo),inUpper,chNumeric,'',False);
                 U.voteNo := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(U.voteNo));
              end;

        '&' : if numInfo > 0 then begin
                 cfgInfo('|U4Infoform to view |U5[|U61|U5-|U6'+St(numInfo)+'|U5;|U6=|U5/|U4all|U5] |U6');
                 Us := iReadString('',inUpper,chNormal,rsNoCR,3);
                 if Us <> '' then
                 begin
                    any := False;
                    if Us = '=' then
                    begin
                       for num := 1 to numInfo do if ifShowForm(num,U.Number,False) then Any := True;
                    end else
                    if ifShowForm(strToInt(us),U.Number,False) then any := True;
                    if any then
                    begin
                       cfgDraw := True;
                       cfgOver := False;
                    end else Inc(cfgStat,Length(Us));
                 end;
                 cfgInfo('');
              end;
        '~' : if numInfo > 0 then begin
                 cfgInfo('|U4Infoform to clear |U5[|U61|U5-|U6'+St(numInfo)+'|U5;|U6=|U5/|U4all|U5] |U6');
                 Us := iReadString('',inUpper,chNormal,rsNoCR,3);
                 if Us <> '' then
                 begin
                    if Us = '=' then ifResetUser(U.Number) else
                                     ifResetForm(U.Number,strToInt(us));
                    Inc(cfgStat,Length(Us));
                 end;
                 cfgInfo('');
              end;
        '-' : begin cfgUserColors(U.Color); cfgDraw := True; cfgOver := False; end;
        '+' : begin asEditAutoSig(U,False); cfgDraw := True; cfgOver := False; end;
        '?' : begin cfgUserPrefs(U); cfgDraw := True; cfgOver := False; end;
        '>' : begin levelUpgrade(U); cfgDraw := True; cfgOver := True; end;
        '<' : begin levelLower(U); cfgDraw := True; cfgOver := True; end;
        '*' : begin
                 if acDeleted in U.acFlag then U.acFlag := U.acFlag-[acDeleted] else
                                               U.acFlag := U.acFlag+[acDeleted];
                 cfgDraw := True; cfgOver := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
   cfgInfo('Save user? ');
   if iYesNo(True) then userSave(U);
   userLoad(User^);
end;

end.