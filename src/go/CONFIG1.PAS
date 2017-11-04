{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config1;

interface

procedure cfgSystemConfig;

implementation

uses
   Crt,
   Global, Output, Strings, Input, Files, Config, Misc, StatBar, Logs, Users;

procedure cfgMainBBSConfig;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Main BBS Configuration');
      cfgItem('A BBS name',40,Cfg^.bbsName,
              'Name of this bulletin board system.');
      cfgItem('B BBS phone number',13,Cfg^.bbsPhone,
              'BBS phone number with area code.');
      cfgItem('C BBS location',40,Cfg^.bbsLocation,
              'Location of the BBS (format: city, state/prov)');
      cfgItem('D SysOp handle',35,Cfg^.SysOpAlias,
              'The SysOp''s alias or handle.');
      cfgItem('E SysOp name',35,Cfg^.SysOpName,
              'The SysOp''s first and last REAL name.');
      cfgItem('F SysOp access password',20,Cfg^.SystemPW,
              'Password required to use most extended SysOp commands. (Blank=Disabled)');
      cfgItem('G Full sysop access',20,Cfg^.acsSysOp,
              'Full SysOp access.  Allows access to ALL modules of the board.');
      cfgItem('H Full co-sysop access',20,Cfg^.acsCoSysOp,
              'Full co-sysop access.  Allows access to almost ALL areas of the board.');
      cfgItem('I Direct video writes',3,B2St(Cfg^.DirectWrites),
              'Write text to the screen "directly"?  Should disable if MultiTasking');
      cfgItem('J Snow checking (CGA)',3,B2St(Cfg^.SnowChecking),
              'Check for CGA "snow" flickering?  (Usually older monitors)');
      cfgItem('K Load overlay to EMS',3,B2St(Cfg^.OverlayToEMS),
              'Load overlay file into expanded memory (if available, otherwise disk)');
      cfgItem('L Real name system',3,B2St(Cfg^.RealNameSystem),
              'Do you want real names used only on the BBS? (no aliases/handles)');
      cfgItem('M Show passwords',3,B2St(Cfg^.ShowPwLocal),
              'Show actual characters in password instead of echo characters to local end?');
      cfgItem('N Run '+bbsTitle+' as door',3,B2St(Cfg^.iniqAsDoor),
              'When "'+paramQuitAfter+'" parameter is used, '+bbsTitle+' won''t hangup after calls.');
      cfgItem('O Check inactivity',3,B2St(Cfg^.inactTime),
              'Hangup on users when they have been excessively inactive');
      cfgItem('P Inactivity timeout',6,St(Cfg^.inactSeconds),
              '[30-64000] Number of seconds that a user can idle before '+bbsTitle+' will hangup');
      cfgItem('Q Inactivity warning',6,St(Cfg^.inactWarning),
              '[30-'+St(Cfg^.inactSeconds)+'] Number of seconds of inactivity before '+bbsTitle+' will warn user (beep)');
      cfgItem('R Local inactivity',3,b2St(Cfg^.inactLocal),
              'Check user inactivity when logged on locally?');
      cfgItem('S Multi-node system?',3,b2St(Cfg^.MultiNode),
              'Are you running a multiple node BBS? (reload '+bbstitle+' to take effect)');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Cfg^.bbsName,inNormal,chNormal,'',False);
                 Cfg^.bbsName := cfgRead;
                 cfgSetItem(Cfg^.bbsName);
              end;
        'B' : begin
                 cfgReadPhone;
                 Cfg^.bbsPhone := cfgRead;
                 cfgSetItem(Cfg^.bbsPhone);
              end;
        'C' : begin
                 cfgReadInfo(Cfg^.bbsLocation,inNormal,chNormal,'',False);
                 Cfg^.bbsLocation := cfgRead;
                 cfgSetItem(Cfg^.bbsLocation);
              end;
        'D' : begin
                 cfgReadInfo(Cfg^.SysOpAlias,inNormal,chNormal,'',False);
                 Cfg^.SysOpAlias := cfgRead;
                 cfgSetItem(Cfg^.SysOpAlias);
              end;
        'E' : begin
                 cfgReadInfo(Cfg^.SysOpName,inNormal,chNormal,'',False);
                 Cfg^.SysOpName := cfgRead;
                 cfgSetItem(Cfg^.SysOpName);
              end;
        'F' : begin
                 cfgReadInfo(Cfg^.SystemPW,inUpper,chNormal,'',False);
                 Cfg^.SystemPW := cfgRead;
                 cfgSetItem(Cfg^.SystemPW);
              end;
        'G' : begin
                 cfgReadInfo(Cfg^.acsSysOp,inLower,chNormal,'',True);
                 Cfg^.acsSysOp := cfgRead;
                 cfgSetItem(Cfg^.acsSysOp);
              end;
        'H' : begin
                 cfgReadInfo(Cfg^.acsCoSysOp,inLower,chNormal,'',True);
                 Cfg^.acsCoSysOp := cfgRead;
                 cfgSetItem(Cfg^.acsCoSysOp);
              end;
        'I' : begin
                 cfgReadBoolean(Cfg^.DirectWrites);
                 cfgSetItem(B2St(Cfg^.DirectWrites));
                 DirectVideo := Cfg^.DirectWrites;
              end;
        'J' : begin
                 cfgReadBoolean(Cfg^.SnowChecking);
                 cfgSetItem(B2St(Cfg^.SnowChecking));
                 CheckSnow := Cfg^.SnowChecking;
              end;
        'K' : begin
                 cfgReadBoolean(Cfg^.OverlayToEMS);
                 cfgSetItem(B2St(Cfg^.OverlayToEMS));
              end;
        'L' : begin
                 cfgReadBoolean(Cfg^.RealNameSystem);
                 cfgSetItem(B2St(Cfg^.RealNameSystem));
              end;
        'M' : begin
                 cfgReadBoolean(Cfg^.ShowPwLocal);
                 cfgSetItem(B2St(Cfg^.ShowPwLocal));
              end;
        'N' : begin
                 cfgReadBoolean(Cfg^.iniqAsDoor);
                 cfgSetItem(B2St(Cfg^.iniqAsDoor));
              end;
        'O' : begin
                 cfgReadBoolean(Cfg^.inactTime);
                 cfgSetItem(B2St(Cfg^.inactTime));
              end;
        'P' : begin
                 cfgReadInfo(St(Cfg^.inactSeconds),inUpper,chNumeric,'',True);
                 Cfg^.inactSeconds := mClip(StrToInt(cfgRead),30,64000);
                 cfgSetItem(St(Cfg^.inactSeconds));
              end;
        'Q' : begin
                 cfgReadInfo(St(Cfg^.inactWarning),inUpper,chNumeric,'',True);
                 Cfg^.inactWarning := mClip(StrToInt(cfgRead),30,Cfg^.inactSeconds);
                 cfgSetItem(St(Cfg^.inactWarning));
              end;
        'R' : begin
                 cfgReadBoolean(Cfg^.inactLocal);
                 cfgSetItem(B2St(Cfg^.inactLocal));
              end;
        'S' : begin
                 cfgReadBoolean(Cfg^.MultiNode);
                 cfgSetItem(B2St(Cfg^.MultiNode));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgStatusBar;
var B : Boolean; U : Byte; cD, cN, cB : tColorRec;
    optBarLoc : array[1..2] of String;
begin
   cfgDraw := True;
   cfgOver := False;
   optBarLoc[1] := 'Bottom of screen';
   optBarLoc[2] := 'Top of screen';
   repeat
      cD.Back := Cfg^.StatLo shr 4;
      cD.Fore := Cfg^.StatLo xor (cD.Back shl 4);
      if cD.Back > 7 then begin cD.Blink := True; Dec(B,8); end else cD.Blink := False;

      cN.Back := Cfg^.StatTxt shr 4;
      cN.Fore := Cfg^.StatTxt xor (cN.Back shl 4);
      if cN.Back > 7 then begin cN.Blink := True; Dec(B,8); end else cN.Blink := False;

      cB.Back := Cfg^.StatHi shr 4;
      cB.Fore := Cfg^.StatHi xor (cB.Back shl 4);
      if cB.Back > 7 then begin cB.Blink := True; Dec(B,8); end else cB.Blink := False;

      cfgInit('Status Bar Options');
      cfgCol := 40;
      cfgItem('A Enable status line',3,B2St(Cfg^.StatOnDefault),
              'Automatically turn on the status line when a user is logging on?');
      cfgItem('B Status bar on?',3,B2St(Cfg^.StatBarOn),
              'Is the status bar currently enabled? (visible)');
      cfgItem('C Bar location',30,cfgOption(optBarLoc,Cfg^.StatType),
              'Default screen location of status bar.');
      cfgItem('D Current bar display',2,St(Cfg^.StatBar),
              'Current status bar line displayed.');
      cfgItem('1 Dark text',40,    strColor(cD),'');
      cfgItem('2 Normal text',40,  strColor(cN),'');
      cfgItem('3 Bright text',40,  strColor(cB),'');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadBoolean(Cfg^.StatOnDefault);
                 cfgSetItem(B2St(Cfg^.StatOnDefault));
              end;
        'B' : begin
                 B := Cfg^.StatBarOn;
                 cfgReadBoolean(B);
                 cfgSetItem(B2St(B));
                 sbStatBar(B);
                 Cfg^.StatBarOn := B;
              end;
        'C' : begin
                 U := Cfg^.StatType;
                 cfgReadOption(optBarLoc,2,U);
                 if U <> Cfg^.StatType then sbToggleMode;
                 cfgSetItem(cfgOption(optBarLoc,Cfg^.StatType));
              end;
        'D' : begin
                 cfgReadInfo(St(Cfg^.StatBar),inUpper,chNumeric,'',True);
                 Cfg^.StatBar := mClip(StrToInt(cfgRead),1,maxStatBar);
                 cfgSetItem(St(Cfg^.StatBar));
                 sbUpdate;
              end;
        '1' : begin
                 cfgReadColor(cD);
                 TextColor(cD.Fore);
                 TextBackground(cD.Back);
                 if cD.Blink then TextColor(cD.Fore+128);
                 Cfg^.StatLo := TextAttr;
                 TextAttr := $60;
                 Col.Fore := 00;
                 Col.Back := 6;
              end;
        '2' : begin
                 cfgReadColor(cN);
                 TextColor(cN.Fore);
                 TextBackground(cN.Back);
                 if cD.Blink then TextColor(cN.Fore+128);
                 Cfg^.StatTxt := TextAttr;
                 TextAttr := $60;
                 Col.Fore := 00;
                 Col.Back := 6;
              end;
        '3' : begin
                 cfgReadColor(cB);
                 TextColor(cB.Fore);
                 TextBackground(cB.Back);
                 if cB.Blink then TextColor(cB.Fore+128);
                 Cfg^.StatHi := TextAttr;
                 TextAttr := $60;
                 Col.Fore := 00;
                 Col.Back := 6;
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgColorConfig;
var B : Boolean; U, N : Word;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Default Color Configuration');
      cfgCol := 30;
      cfgItem('A Normal text',40,  strColor(Cfg^.DefaultCol[colText]),'');
      cfgItem('B Dark text',40,    strColor(Cfg^.DefaultCol[colTextLo]),'');
      cfgItem('C Bright text',40,  strColor(Cfg^.DefaultCol[colTextHi]),'');
      cfgItem('D Normal info',40,  strColor(Cfg^.DefaultCol[colInfo]),'');
      cfgItem('E Dark info',40,    strColor(Cfg^.DefaultCol[colInfoLo]),'');
      cfgItem('F Bright info',40,  strColor(Cfg^.DefaultCol[colInfoHi]),'');
      cfgItem('G Menu item',40,    strColor(Cfg^.DefaultCol[colItem]),'');
      cfgItem('H Selected item',40,strColor(Cfg^.DefaultCol[colItemSel]),'');
      cfgItem('I Line/border',40,  strColor(Cfg^.DefaultCol[colBorder]),'');
      cfgItem('J Error/warning',40,strColor(Cfg^.DefaultCol[colError]),'');
      cfgItem('K Input color',40,   strColor(Cfg^.DefaultCol[colEdit]),'');
      if cfgDraw then
      begin
         oSetCol(colBorder);
         oDnLn(1);
         oWriteLn(sRepeat('Ä',79));
         Inc(cfgLn,1);
         Inc(cfgBot,1);
         Inc(cfgCol,2);
         cfgItem('1 Apply colors to all users',0,'',
                 'Are you sure you wish to reset ALL user-defined color settings?');
      end;
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
         'A' : cfgReadColor(Cfg^.DefaultCol[colText]);
         'B' : cfgReadColor(Cfg^.DefaultCol[colTextLo]);
         'C' : cfgReadColor(Cfg^.DefaultCol[colTextHi]);
         'D' : cfgReadColor(Cfg^.DefaultCol[colInfo]);
         'E' : cfgReadColor(Cfg^.DefaultCol[colInfoLo]);
         'F' : cfgReadColor(Cfg^.DefaultCol[colInfoHi]);
         'G' : cfgReadColor(Cfg^.DefaultCol[colItem]);
         'H' : cfgReadColor(Cfg^.DefaultCol[colItemSel]);
         'I' : cfgReadColor(Cfg^.DefaultCol[colBorder]);
         'J' : cfgReadColor(Cfg^.DefaultCol[colError]);
         'K' : cfgReadColor(Cfg^.DefaultCol[colEdit]);
         '1' : begin
                  B := False;
                  cfgReadBoolean(B);
                  if B then
                  begin
                     cfgInfo('-- Setting user colors.  Please wait ...');
                     userSave(User^);
                     N := User^.Number;
                     for U := 1 to numUsers do
                     begin
                        User^.Number := U;
                        if userLoad(User^) then
                        begin
                           User^.Color := Cfg^.DefaultCol;
                           userSave(User^);
                        end;
                     end;
                     User^.Number := N;
                     userLoad(User^);
                     cfgInfo('');
                  end;
               end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

function cfgAddressStr(A : tNetAddressRec) : String;
begin
   cfgAddressStr := St(A.Zone)+':'+St(A.Net)+'/'+St(A.Node)+'.'+St(A.Point);
end;

function cfgToAddress(var A : tNetAddressRec; S : String) : Boolean;
var Z : String;
begin
   cfgToAddress := False;
   if S = '' then Exit;
   Z := '';
   while (S <> '') and (S[1] in ['0'..'9']) do
   begin
      Z := Z+S[1];
      Delete(S,1,1);
   end;
   if Z = '' then Exit;
   A.Zone := StrToInt(Z);
   cfgToAddress := True;
   if (S = '') or (S[1] <> ':') then Exit else Delete(S,1,1);
   if S = '' then Exit;
   Z := '';
   while (S <> '') and (S[1] in ['0'..'9']) do
   begin
      Z := Z+S[1];
      Delete(S,1,1);
   end;
   if Z = '' then Exit;
   A.Net := StrToInt(Z);
   if (S = '') or (S[1] <> '/') then Exit else Delete(S,1,1);
   if S = '' then Exit;
   Z := '';
   while (S <> '') and (S[1] in ['0'..'9']) do
   begin
      Z := Z+S[1];
      Delete(S,1,1);
   end;
   if Z = '' then Exit;
   A.Node := StrToInt(Z);
   if (S = '') or (S[1] <> '.') then Exit else Delete(S,1,1);
   if S = '' then Exit;
   Z := '';
   while (S <> '') and (S[1] in ['0'..'9']) do
   begin
      Z := Z+S[1];
      Delete(S,1,1);
   end;
   if Z = '' then Exit;
   A.Point := StrToInt(Z);
end;

procedure cfgNetAddress;
var N : Byte; A : tNetAddressRec;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Network Address Configuration');
      cfgCol := 19;
      for N := 1 to 10 do
      cfgItem(Chr(64+N)+' Address #'+St(N),15,cfgAddressStr(Cfg^.Address[N]),
              'Network address #'+St(N)+' (zone:net/node.point).  Applied to echomail messages');
      cfgLn := cfgTop;
      cfgSrt := 41;
      cfgCol := 59;
      for N := 11 to 20 do
      cfgItem(Chr(64+N)+' Address #'+St(N),15,cfgAddressStr(Cfg^.Address[N]),
              'Network address #'+St(N)+' (zone:net/node.point).  Applied to echomail messages');
      if cfgDraw then Dec(cfgBot,10);
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      N := Ord(cfgKey)-64;
      case cfgKey of
        'A'..Chr(64+maxOrigin) : begin
                 cfgReadInfo(cfgAddressStr(Cfg^.Address[N]),inUpper,chNumeric+['/','.',':'],'',True);
                 A := Cfg^.Address[N];
                 if cfgToAddress(A,cfgRead) then Cfg^.Address[N] := A;
                 cfgSetItem(cfgAddressStr(Cfg^.Address[N]));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgWaitForCall;
var optBlanker : array[1..3] of String;
    optWFCstat : array[1..8] of String;
begin
   cfgDraw := True;
   cfgOver := False;
   optBlanker[1] := 'Disabled';
   optBlanker[2] := 'Blank screen';
   optBlanker[3] := 'Text palette morph';
   optWFCstat[1] := 'System information';
   optWFCstat[2] := '--- reserved';
   optWFCstat[3] := 'System totals';
   optWFCstat[4] := 'Today''s statistics';
   optWFCstat[5] := 'Last few callers';
   optWFCstat[6] := '--- reserved';
   optWFCstat[7] := '--- reserved';
   optWFCstat[8] := bbsTitle+' information';
   repeat
      cfgInit('Wait-For-Call Configuration');
      cfgCol := 40;
      cfgItem('A Allow ESC to exit',3,B2St(Cfg^.ESCtoExit),
              'If enabled, hitting the ESC key at the WFCscreen will exit '+bbsTitle);
      cfgItem('B Offhook w/local login',3,B2St(Cfg^.OffhookLocal),
              'Take modem offhook before logging on locally?');
      cfgItem('C VGA fading effects',3,B2St(Cfg^.VgaEffects),
              'Enable special VGA color effects? (Disabled if multitasking or no VGA card)');
      cfgItem('D Screen saver type',20,cfgOption(optBlanker,Cfg^.ScreenSaver+1),
              'The desired screen saver type.');
      cfgItem('E Screen blank time',3,St(Cfg^.BlankSeconds),
              '[10-5000] Number of seconds before auto-activating screen saver.');
      cfgItem('F Default WFC stat',30,cfgOption(optWFCstat,Cfg^.DefWFCstat),
              'Default WFC status screen display.');
      cfgItem('G Connect seconds',6,St(Cfg^.waitConnect),
              'Number of seconds to wait for connection after sending answer string');
      cfgItem('H Modem re-init time',6,St(Cfg^.modemReInit),
              'Seconds of inactivity before modem will be re-inited [0 to disable]');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadBoolean(Cfg^.ESCtoExit);
                 cfgSetItem(B2St(Cfg^.ESCtoExit));
              end;
        'B' : begin
                 cfgReadBoolean(Cfg^.OffhookLocal);
                 cfgSetItem(B2St(Cfg^.OffhookLocal));
              end;
        'C' : begin
                 cfgReadBoolean(Cfg^.VgaEffects);
                 cfgSetItem(B2St(Cfg^.VgaEffects));
              end;
        'D' : begin
                 Inc(Cfg^.ScreenSaver);
                 cfgReadOption(optBlanker,3,Cfg^.ScreenSaver);
                 cfgSetItem(cfgOption(optBlanker,Cfg^.ScreenSaver));
                 Dec(Cfg^.ScreenSaver);
              end;
        'E' : begin
                 cfgReadInfo(St(Cfg^.BlankSeconds),inUpper,chNumeric,'',True);
                 Cfg^.BlankSeconds := mClip(StrToInt(cfgRead),10,5000);
                 cfgSetItem(St(Cfg^.BlankSeconds));
              end;
        'F' : begin
                 cfgReadOption(optWFCstat,8,Cfg^.DefWFCstat);
                 cfgSetItem(cfgOption(optWFCstat,Cfg^.DefWFCstat));
              end;
        'G' : begin
                 cfgReadInfo(St(Cfg^.waitConnect),inUpper,chNumeric,'',True);
                 Cfg^.waitConnect := mClip(StrToInt(cfgRead),5,64000);
                 cfgSetItem(St(Cfg^.waitConnect));
              end;
        'H' : begin
                 cfgReadInfo(St(Cfg^.modemReInit),inUpper,chNumeric,'',True);
                 Cfg^.modemReInit := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Cfg^.modemReInit));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgPaths;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Filenames and Directories');
      cfgItem('A Data directory',40,Cfg^.pathData,
              'Path to '+bbsTitle+' data and configuration files');
      cfgItem('B Text directory',40,Cfg^.pathText,
              'Path to miscellaneous text files');
      cfgItem('C Menu directory',40,Cfg^.pathMenu,
              'Path to menu (*.MNU) files');
      cfgItem('D Message directory',40,Cfg^.pathMsgs,
              'Path to message base data and header files');
      cfgItem('E Swapping directory',40,Cfg^.pathSwap,
              'Directory to perform disk swapping in. (if nessesary)');
      cfgItem('F Doors directory',40,Cfg^.pathDoor,
              'Directory in which '+bbsTitle+' will create door drop files in.');
      cfgItem('G Protocol directory',40,Cfg^.pathProt,
              'Directory where all external protocols are found.');
      cfgItem('H Temporary directory',40,Cfg^.pathTemp,
              'Directory in which temporary files will be stored.');
      cfgItem('I Download directory',40,Cfg^.pathDnld,
              'Directory where downloaded files will be placed. (from terminal)');
      cfgItem('J Logfiles directory',40,Cfg^.pathLogs,
              'Directory where system log files are created and stored in.');
      cfgItem('K Archivers directory',40,Cfg^.pathArch,
              'Directory where archivers are found, for file compression/decompression.');
      cfgItem('L File attach path',40,Cfg^.pathAtch,
              'Directory where included files from messages are uploaded and stored.');
      cfgItem('M Textfile library path',40,Cfg^.pathLibs,
              'Directory where textfile library (*.TFL) files are stored');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Cfg^.pathData,inUpper,chDirectory,'',True);
                 Cfg^.pathData := cfgRead;
                 if Cfg^.pathData[Length(Cfg^.pathData)] <> '\' then
                    Cfg^.pathData := Cfg^.pathData+'\';
                 cfgSetItem(Cfg^.pathData);
                 cfgAskCreate(Cfg^.pathData);
              end;
        'B' : begin
                 cfgReadInfo(Cfg^.pathText,inUpper,chDirectory,'',True);
                 Cfg^.pathText := cfgRead;
                 if Cfg^.pathText[Length(Cfg^.pathText)] <> '\' then
                    Cfg^.pathText := Cfg^.pathText+'\';
                 cfgSetItem(Cfg^.pathText);
                 cfgAskCreate(Cfg^.pathText);
              end;
        'C' : begin
                 cfgReadInfo(Cfg^.pathMenu,inUpper,chDirectory,'',True);
                 Cfg^.pathMenu := cfgRead;
                 if Cfg^.pathMenu[Length(Cfg^.pathMenu)] <> '\' then
                    Cfg^.pathMenu := Cfg^.pathMenu+'\';
                 cfgSetItem(Cfg^.pathMenu);
                 cfgAskCreate(Cfg^.pathMenu);
              end;
        'D' : begin
                 cfgReadInfo(Cfg^.pathMsgs,inUpper,chDirectory,'',True);
                 Cfg^.pathMsgs := cfgRead;
                 if Cfg^.pathMsgs[Length(Cfg^.pathMsgs)] <> '\' then
                    Cfg^.pathMsgs := Cfg^.pathMsgs+'\';
                 cfgSetItem(Cfg^.pathMsgs);
                 cfgAskCreate(Cfg^.pathMsgs);
              end;
        'E' : begin
                 cfgReadInfo(Cfg^.pathSwap,inUpper,chDirectory,'',True);
                 Cfg^.pathSwap := cfgRead;
                 if Cfg^.pathSwap[Length(Cfg^.pathSwap)] <> '\' then
                    Cfg^.pathSwap := Cfg^.pathSwap+'\';
                 cfgSetItem(Cfg^.pathSwap);
                 cfgAskCreate(Cfg^.pathSwap);
              end;
        'F' : begin
                 cfgReadInfo(Cfg^.pathDoor,inUpper,chDirectory,'',True);
                 Cfg^.pathDoor := cfgRead;
                 if Cfg^.pathDoor[Length(Cfg^.pathDoor)] <> '\' then
                    Cfg^.pathDoor := Cfg^.pathDoor+'\';
                 cfgSetItem(Cfg^.pathDoor);
                 cfgAskCreate(Cfg^.pathDoor);
              end;
        'G' : begin
                 cfgReadInfo(Cfg^.pathProt,inUpper,chDirectory,'',True);
                 Cfg^.pathProt := cfgRead;
                 if Cfg^.pathProt[Length(Cfg^.pathProt)] <> '\' then
                    Cfg^.pathProt := Cfg^.pathProt+'\';
                 cfgSetItem(Cfg^.pathProt);
                 cfgAskCreate(Cfg^.pathProt);
              end;
        'H' : begin
                 cfgReadInfo(Cfg^.pathTemp,inUpper,chDirectory,'',True);
                 Cfg^.pathTemp := cfgRead;
                 if Cfg^.pathTemp[Length(Cfg^.pathTemp)] <> '\' then
                    Cfg^.pathTemp := Cfg^.pathTemp+'\';
                 cfgSetItem(Cfg^.pathTemp);
                 cfgAskCreate(Cfg^.pathTemp);
              end;
        'I' : begin
                 cfgReadInfo(Cfg^.pathDnld,inUpper,chDirectory,'',True);
                 Cfg^.pathDnld := cfgRead;
                 if Cfg^.pathDnld[Length(Cfg^.pathDnld)] <> '\' then
                    Cfg^.pathDnld := Cfg^.pathDnld+'\';
                 cfgSetItem(Cfg^.pathDnld);
                 cfgAskCreate(Cfg^.pathDnld);
              end;
        'J' : begin
                 cfgReadInfo(Cfg^.pathLogs,inUpper,chDirectory,'',True);
                 Cfg^.pathLogs := cfgRead;
                 if Cfg^.pathLogs[Length(Cfg^.pathLogs)] <> '\' then
                    Cfg^.pathLogs := Cfg^.pathLogs+'\';
                 cfgSetItem(Cfg^.pathLogs);
                 cfgAskCreate(Cfg^.pathLogs);
              end;
        'K' : begin
                 cfgReadInfo(Cfg^.pathArch,inUpper,chDirectory,'',True);
                 Cfg^.pathArch := cfgRead;
                 if Cfg^.pathArch[Length(Cfg^.pathArch)] <> '\' then
                    Cfg^.pathArch := Cfg^.pathArch+'\';
                 cfgSetItem(Cfg^.pathArch);
                 cfgAskCreate(Cfg^.pathArch);
              end;
        'L' : begin
                 cfgReadInfo(Cfg^.pathAtch,inUpper,chDirectory,'',True);
                 Cfg^.pathAtch := cfgRead;
                 if Cfg^.pathAtch[Length(Cfg^.pathAtch)] <> '\' then
                    Cfg^.pathAtch := Cfg^.pathAtch+'\';
                 cfgSetItem(Cfg^.pathAtch);
                 cfgAskCreate(Cfg^.pathAtch);
              end;
        'M' : begin
                 cfgReadInfo(Cfg^.pathLibs,inUpper,chDirectory,'',True);
                 Cfg^.pathLibs := cfgRead;
                 if Cfg^.pathLibs[Length(Cfg^.pathLibs)] <> '\' then
                    Cfg^.pathLibs := Cfg^.pathLibs+'\';
                 cfgSetItem(Cfg^.pathLibs);
                 cfgAskCreate(Cfg^.pathLibs);
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgLoggingOptions;
var B : Boolean;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('BBS Logging Options');
      cfgCol := 40;
      cfgItem('A System logging',3,B2St(not Cfg^.NoBBSlogging),
              'Create log files of system activity?');
      cfgItem('B Log line-chat',3,B2St(Cfg^.LogLineChat),
              'Record line-chat to '+fileChatLog+'?');
      cfgItem('C Log split-screen chat',3,B2St(Cfg^.LogSplitChat),
              'Record splitscreen chat to '+fileChatLog+'?');
      cfgItem('D MicroDOS logging',3,B2St(Cfg^.LogMicroDOS),
              'Record all commands entered in artifical DOS to log file?');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 B := not Cfg^.NoBBSlogging;
                 cfgReadBoolean(B);
                 Cfg^.NoBBSlogging := not B;
                 cfgSetItem(B2St(B));
              end;
        'B' : begin
                 cfgReadBoolean(Cfg^.LogLineChat);
                 cfgSetItem(B2St(Cfg^.LogLineChat));
              end;
        'C' : begin
                 cfgReadBoolean(Cfg^.LogSplitChat);
                 cfgSetItem(B2St(Cfg^.LogSplitChat));
              end;
        'D' : begin
                 cfgReadBoolean(Cfg^.LogMicroDOS);
                 cfgSetItem(B2St(Cfg^.LogMicroDOS));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgSwappingSetup;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Swapping Setup');
      cfgCol := 40;
      cfgItem('A Swap when shelling',3,B2St(Cfg^.SwapInShell),
              'Swap to disk (or EMS if enabled) to free more memory with external programs');
      cfgItem('B Use EMS for swapping',3,B2St(Cfg^.SwapToEMS),
              'Allow use of expanded memory for swapping (if available, otherwise disk)');
      cfgItem('C Protocol swapping',3,B2St(Cfg^.ProtocolSwap),
              'Swap to EMS or DISK when executing external protocols?');
      cfgItem('D Archiver swapping',3,B2St(Cfg^.ArchiverSwap),
              'Swap to EMS or DISK when executing archiver programs?');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadBoolean(Cfg^.SwapInShell);
                 cfgSetItem(B2St(Cfg^.SwapInShell));
              end;
        'B' : begin
                 cfgReadBoolean(Cfg^.SwapToEMS);
                 cfgSetItem(B2St(Cfg^.SwapToEMS));
              end;
        'C' : begin
                 cfgReadBoolean(Cfg^.ProtocolSwap);
                 cfgSetItem(B2St(Cfg^.ProtocolSwap));
              end;
        'D' : begin
                 cfgReadBoolean(Cfg^.ArchiverSwap);
                 cfgSetItem(B2St(Cfg^.ArchiverSwap));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgLoginConfig;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('BBS Login Configuration');
      cfgCol := 40;
      cfgItem('A System access password',20,Cfg^.BbsAccessPW,
              'Password required to login to the BBS (Blank=Disabled).');
      cfgItem('B Baud override password',20,Cfg^.NoBaudPW,
              'Password required to logon below the minimum baudrate (Blank=Disabled).');
      cfgItem('C SysOp autologin',3,B2St(Cfg^.SysOpAutoLogin),
              'Automatically login "instantly", bypassing all logon prompts/screens.');
      cfgItem('D Use matrix login',3,B2St(Cfg^.MatrixLogin),
              'Enable use of "MATRIX.MNU", a pre-login command menu.');
      cfgItem('E Offer application?',3,B2St(Cfg^.AskApply),
              'If a user isn''t found in the user file, will be offered to apply as new');
      cfgItem('F Time limit per call',3,B2St(Cfg^.TimeLimitPerCall),
              'Is user time limit for each call or each day?');
      cfgItem('G System password login',20,Cfg^.acsSystemPWLogin,
              'Access level to enforce the system password when logging in.');
      cfgItem('H Calls before birthdate check',3,St(Cfg^.CallsBirth),
              '[0-255] How often to perform birthdate validation check. (0 = Disabled)');
      cfgItem('I Calls before phone # check',3,St(Cfg^.CallsPhone),
              '[0-255] How often to perform phone number validation check. (0 = Disabled)');
      cfgItem('J Maximum logon attempts',3,St(Cfg^.LoginTrys),
              '[0-255] Number of tries a user has to logon to system. (0 = Infinite)');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Cfg^.BbsAccessPW,inUpper,chNormal,'',False);
                 Cfg^.BbsAccessPW := cfgRead;
                 cfgSetItem(Cfg^.BbsAccessPW);
              end;
        'B' : begin
                 cfgReadInfo(Cfg^.NoBaudPW,inUpper,chNormal,'',False);
                 Cfg^.NoBaudPW := cfgRead;
                 cfgSetItem(Cfg^.NoBaudPW);
              end;
        'C' : begin
                 cfgReadBoolean(Cfg^.SysOpAutoLogin);
                 cfgSetItem(B2St(Cfg^.SysOpAutoLogin));
              end;
        'D' : begin
                 cfgReadBoolean(Cfg^.MatrixLogin);
                 cfgSetItem(B2St(Cfg^.MatrixLogin));
              end;
        'E' : begin
                 cfgReadBoolean(Cfg^.AskApply);
                 cfgSetItem(B2St(Cfg^.AskApply));
              end;
        'F' : begin
                 cfgReadBoolean(Cfg^.TimeLimitPerCall);
                 cfgSetItem(B2St(Cfg^.TimeLimitPerCall));
              end;
        'G' : begin
                 cfgReadInfo(Cfg^.acsSystemPWLogin,inLower,chNormal,'',True);
                 Cfg^.acsSystemPWLogin := cfgRead;
                 cfgSetItem(Cfg^.acsSystemPWLogin);
              end;
        'H' : begin
                 cfgReadInfo(St(Cfg^.CallsBirth),inUpper,chNumeric,'',True);
                 Cfg^.CallsBirth := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(Cfg^.CallsBirth));
              end;
        'I' : begin
                 cfgReadInfo(St(Cfg^.CallsPhone),inUpper,chNumeric,'',True);
                 Cfg^.CallsPhone := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(Cfg^.CallsPhone));
              end;
        'J' : begin
                 cfgReadInfo(St(Cfg^.LoginTrys),inUpper,chNumeric,'',True);
                 Cfg^.LoginTrys := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(Cfg^.LoginTrys));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgOriginLines;
var N : Byte;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Origin Line Setup');
      cfgCol := 16;
      for N := 1 to 10 do
      cfgItem(Chr(64+N)+' Origin #'+St(N),23,Cfg^.Origin[N],
              'Origin line number '+St(N)+'.  Applied to echomail messages');
      cfgLn := cfgTop;
      cfgSrt := 41;
      cfgCol := 56;
      for N := 11 to 20 do
      cfgItem(Chr(64+N)+' Origin #'+St(N),23,Cfg^.Origin[N],
              'Origin line number '+St(N)+'.  Applied to echomail messages');
      if cfgDraw then Dec(cfgBot,10);
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      N := Ord(cfgKey)-64;
      case cfgKey of
        'A'..Chr(64+maxOrigin) : begin
                 cfgEditInfo(Cfg^.Origin[N],75,inNormal,chNormal,'',False);
                 Cfg^.Origin[N] := cfgRead;
                 cfgSetItem(Cfg^.Origin[N]);
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgChatSetup;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Chat Mode Setup');
      cfgCol := 40;
      cfgItem('A Chat override password',20,Cfg^.NoChatPW,
              'Password required to page sysop when not available (Blank=Disabled)');
      cfgItem('B Chat pager noise',3,B2St(Cfg^.ChatPageNoise),
              'Allow chat pager to actually beep when paged?');
      cfgItem('C Maximum page times',3,St(Cfg^.maxPageTimes),
              '[0-30] Number of times user may page the sysop per call (0 = Infinite)');
      cfgItem('D Page beeps',3,St(Cfg^.maxPageBeeps),
              '[1-20] Number of beeps to output when paging SysOp');
      cfgItem('E Restore chat time',3,B2St(Cfg^.RestoreChatTime),
              'Restore all time spent while in chat mode?');
      cfgItem('F Availablity start time',5,Cfg^.chatStart,
              'Time (24 hour) that users will be allowed to page sysop from until end time');
      cfgItem('G Availablity end time',5,Cfg^.chatEnd,
              'Time (24 hour) that chat availability will be automatically disabled at');
      cfgItem('H Page override ACS',20,Cfg^.chatOverAcs,
              'Access condition required to override chat availibality');
      cfgItem('I Chat inactivity check',3,b2st(Cfg^.inactInChat),
              'Enable inactivity checking in while chat mode?');
      cfgItem('J Ask leave email?',3,B2St(Cfg^.pageAskEmail),
              'Prompt to send email to the sysop after an unsucessful chat attempt?');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Cfg^.NoChatPW,inUpper,chNormal,'',False);
                 Cfg^.NoChatPW := cfgRead;
                 cfgSetItem(Cfg^.NoChatPW);
              end;
        'B' : begin
                 cfgReadBoolean(Cfg^.ChatPageNoise);
                 cfgSetItem(B2St(Cfg^.ChatPageNoise));
              end;
        'C' : begin
                 cfgReadInfo(St(Cfg^.maxPageTimes),inUpper,chNumeric,'',True);
                 Cfg^.maxPageTimes := mClip(StrToInt(cfgRead),0,30);
                 cfgSetItem(St(Cfg^.maxPageTimes));
              end;
        'D' : begin
                 cfgReadInfo(St(Cfg^.maxPageBeeps),inUpper,chNumeric,'',True);
                 Cfg^.maxPageBeeps := mClip(StrToInt(cfgRead),1,20);
                 cfgSetItem(St(Cfg^.maxPageBeeps));
              end;
        'E' : begin
                 cfgReadBoolean(Cfg^.RestoreChatTime);
                 cfgSetItem(B2St(Cfg^.RestoreChatTime));
              end;
        'F' : begin
                 cfgReadTime;
                 Cfg^.chatStart := cfgRead;
                 cfgSetItem(Cfg^.chatStart);
              end;
        'G' : begin
                 cfgReadTime;
                 Cfg^.chatEnd := cfgRead;
                 cfgSetItem(Cfg^.chatEnd);
              end;
        'H' : begin
                 cfgReadInfo(Cfg^.chatOverAcs,inLower,chNormal,'',True);
                 Cfg^.chatOverAcs := cfgRead;
                 cfgSetItem(Cfg^.chatOverAcs);
              end;
        'I' : begin
                 cfgReadBoolean(Cfg^.inactInChat);
                 cfgSetItem(B2St(Cfg^.inactInChat));
              end;
        'J' : begin
                 cfgReadBoolean(Cfg^.pageAskEmail);
                 cfgSetItem(B2St(Cfg^.pageAskEmail));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgMiscOptions;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Miscellaneous Options');
      cfgCol := 40;
      cfgItem('A Password echo character',1,Cfg^.PwEchoChar,
              'Character shown when entering or displaying hidden information');
      cfgItem('B Remove pause prompts',3,B2St(Cfg^.RemovePause),
              'Erase (backspace over) pause prompts after a key is hit?');
      cfgItem('C Record local calls',3,B2St(Cfg^.AddLocalCalls),
              'Record local logins to system statistics and last caller records?');
      cfgItem('D Last callers shown',3,St(Cfg^.numLastCalls),
              '[1-255] Number of last callers to display in last callers listing');
      cfgItem('E Light character',1,Cfg^.lightChar,
              'Character used as a "light" in applicible textfiles');
      cfgItem('F Light "ok" character',1,Cfg^.lightCharOk,
              'Character displayed when an operation was successful');
      cfgItem('G Light "fail" character',1,Cfg^.lightCharFail,
              'Character displayed when an operation failed');
      cfgItem('H Use textfile libraries',3,B2St(Cfg^.useTextLibs),
              'Load textfiles from user selectable libraries (.TFL files) if possible?');
      cfgItem('I Yes/no prompt (yes)',30,Cfg^.pmtYes,
              'Yes/no prompt to display when "Yes" is the default answer');
      cfgItem('J Yes/no prompt (no)',30,Cfg^.pmtNo,
              'Yes/no prompt to display when "No" is the default answer');
      cfgItem('K Yes/no "Yes" word',20,Cfg^.pmtYesWord,
              'String to display when a user chooses "Yes" at a yes/no prompt');
      cfgItem('L Yes/no "No" word',20,Cfg^.pmtNoWord,
              'String to display when a user chooses "No" at a yes/no prompt');
      cfgItem('M Yes/no bar prompt (yes)',30,Cfg^.pmtYesBar,
              'Yes/no bar displayed when "Yes" is currently selected');
      cfgItem('N Yes/no bar prompt (no)',30,Cfg^.pmtNoBar,
              'Yes/no bar displayed when "No" is currently selected');
      cfgItem('O Local sound restriction',3,B2St(Cfg^.soundRestrict),
              'If enabled, local beeps will only be enabled if the sysop is available');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Cfg^.PwEchoChar,inNormal,chNormal,'',True);
                 Cfg^.PwEchoChar := cfgRead[1];
                 cfgSetItem(Cfg^.PwEchoChar);
              end;
        'B' : begin
                 cfgReadBoolean(Cfg^.RemovePause);
                 cfgSetItem(B2St(Cfg^.RemovePause));
              end;
        'C' : begin
                 cfgReadBoolean(Cfg^.AddLocalCalls);
                 cfgSetItem(B2St(Cfg^.AddLocalCalls));
              end;
        'D' : begin
                 cfgReadInfo(St(Cfg^.numLastCalls),inUpper,chNumeric,'',True);
                 Cfg^.numLastCalls := mClip(StrToInt(cfgRead),1,255);
                 cfgSetItem(St(Cfg^.numLastCalls));
              end;
        'E' : begin
                 cfgReadInfo(Cfg^.lightChar,inNormal,chNormal,'',True);
                 Cfg^.lightChar := cfgRead[1];
                 cfgSetItem(Cfg^.lightChar);
              end;
        'F' : begin
                 cfgReadInfo(Cfg^.lightCharOk,inNormal,chNormal,'',True);
                 Cfg^.lightCharOk := cfgRead[1];
                 cfgSetItem(Cfg^.lightCharOk);
              end;
        'G' : begin
                 cfgReadInfo(Cfg^.lightCharFail,inNormal,chNormal,'',True);
                 Cfg^.lightCharFail := cfgRead[1];
                 cfgSetItem(Cfg^.lightCharFail);
              end;
        'H' : begin
                 cfgReadBoolean(Cfg^.useTextLibs);
                 cfgSetItem(B2St(Cfg^.useTextLibs));
              end;
        'I' : begin
                 cfgReadInfo(Cfg^.pmtYes,inNormal,chNormal,rsNoClean+rsSpace,True);
                 Cfg^.pmtYes := cfgRead;
                 cfgSetItem(Cfg^.pmtYes);
              end;
        'J' : begin
                 cfgReadInfo(Cfg^.pmtNo,inNormal,chNormal,rsNoClean+rsSpace,True);
                 Cfg^.pmtNo := cfgRead;
                 cfgSetItem(Cfg^.pmtNo);
              end;
        'K' : begin
                 cfgReadInfo(Cfg^.pmtYesWord,inNormal,chNormal,rsNoClean+rsSpace,True);
                 Cfg^.pmtYesWord := cfgRead;
                 cfgSetItem(Cfg^.pmtYesWord);
              end;
        'L' : begin
                 cfgReadInfo(Cfg^.pmtNoWord,inNormal,chNormal,rsNoClean+rsSpace,True);
                 Cfg^.pmtNoWord := cfgRead;
                 cfgSetItem(Cfg^.pmtNoWord);
              end;
        'M' : begin
                 cfgReadInfo(Cfg^.pmtYesBar,inNormal,chNormal,rsNoClean+rsSpace,True);
                 Cfg^.pmtYesBar := cfgRead;
                 cfgSetItem(Cfg^.pmtYesBar);
              end;
        'N' : begin
                 cfgReadInfo(Cfg^.pmtNoBar,inNormal,chNormal,rsNoClean+rsSpace,True);
                 Cfg^.pmtNoBar := cfgRead;
                 cfgSetItem(Cfg^.pmtNoBar);
              end;
        'O' : begin
                 cfgReadBoolean(Cfg^.soundRestrict);
                 cfgSetItem(B2St(Cfg^.soundRestrict));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgMessageSystem;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Message system configuration');
      cfgCol := 28;
      cfgItem('A Post electronic mail',20,Cfg^.acsPostEmail,
              'Access condition required to post electroic mail (Email).');
      cfgItem('B Anonymous post access',20,Cfg^.acsAnonymous,
              'Access condition required to post anonymous messages (if allowed).');
      cfgItem('C Anonymous automsg acs',20,Cfg^.acsAnonAutoMsg,
              'Access condition required to post an anonymous auto-message.');
      cfgItem('D Upload message access',20,Cfg^.acsUploadMessage,
              'Access condition required to upload a prepared message.');
      cfgItem('E Autosignature access',20,Cfg^.acsAutoSigUse,
              'Access condition required for AutoSignature use.');
      cfgItem('F Public attach access',20,Cfg^.acsAttachPublic,
              'Access condition required to attach files to public messages.');
      cfgItem('G Email attach access',20,Cfg^.acsAttachEmail,
              'Access condition required to attach files to electronic mail.');
      cfgItem('H Abort mandatory okay',3,B2St(Cfg^.AbortMandOk),
              'Allow user to abort reading messages (with ''Q'') in a mandatory area?');
      cfgItem('I Ask private message',3,B2St(Cfg^.AskPrivateMsg),
              'Offer private message when posting to a specific user?');
      cfgItem('J Ask private reply',3,B2St(Cfg^.AskPrivateReply),
              'Offer private message when replying to a user?');
      cfgItem('K Ask post in area',3,B2St(Cfg^.AskPostInArea),
              'Ask user if he/she wishes to post when area reading complete?');
      cfgItem('L Ask upload reply',3,B2St(Cfg^.AskUploadReply),
              'Offer prepared message upload when user is replying?');
      cfgItem('M Ask upload email',3,B2St(Cfg^.AskUploadEmail),
              'Offer prepared message upload when user is sending email?');
      cfgItem('N Ask delete email msg',3,B2St(Cfg^.AskKillMsg),
              'Ask user if he/she wishes to delete the message they replied to?');
      cfgItem('O Ask kill all email',3,B2St(Cfg^.AskKillAllMsg),
              'Ask user if he/she wishes to kill all undeleted email when through reading?');
      cfgItem('P Ask autoquote reply',3,B2St(Cfg^.AskAutoQuote),
              'Ask user if he/she wishes to auto-quote the message they''re replying to?');
      cfgItem('Q Default quote lines',3,B2St(Cfg^.DefaultQuoteNum),
              'Default /Q line #s to ones chosen by '+bbsTitle+'? (if autoquote is off)');
      cfgItem('R Max autoquote lines',2,St(Cfg^.maxQuoteLines),
              '[0-20] Maximum amount of lines to be AutoQuoted from message (0 = full msg)');
      cfgItem('S Ignore conf w/mand',3,B2St(Cfg^.confIgnoreMsg),
              'Ignore current message conference when scanning for mandatory messages?');
      cfgLn := cfgTop+7;
      cfgSrt := 40;
      cfgCol := 68;
      cfgItem('T Compress area #''s',3,B2St(Cfg^.compMsgAreas),
              'Compress message area listing numbers, to make sequential?');
      cfgItem('U Echomail errorlevel',3,St(Cfg^.echomailLev),
              'Errorlevel to exit to DOS with when a message is posted in an echo area');
      cfgItem('V Ansi quote string',11,Cfg^.ansiString,
              'String to be displayed in place of text when quoting text with ansi codes');
      if cfgDraw then Dec(cfgBot,3);
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Cfg^.acsPostEmail,inLower,chNormal,'',True);
                 Cfg^.acsPostEmail := cfgRead;
                 cfgSetItem(Cfg^.acsPostEmail);
              end;
        'B' : begin
                 cfgReadInfo(Cfg^.acsAnonymous,inLower,chNormal,'',True);
                 Cfg^.acsAnonymous := cfgRead;
                 cfgSetItem(Cfg^.acsAnonymous);
              end;
        'C' : begin
                 cfgReadInfo(Cfg^.acsAnonAutoMsg,inLower,chNormal,'',True);
                 Cfg^.acsAnonAutoMsg := cfgRead;
                 cfgSetItem(Cfg^.acsAnonAutoMsg);
              end;
        'D' : begin
                 cfgReadInfo(Cfg^.acsUploadMessage,inLower,chNormal,'',True);
                 Cfg^.acsUploadMessage := cfgRead;
                 cfgSetItem(Cfg^.acsUploadMessage);
              end;
        'E' : begin
                 cfgReadInfo(Cfg^.acsAutoSigUse,inLower,chNormal,'',True);
                 Cfg^.acsAutoSigUse := cfgRead;
                 cfgSetItem(Cfg^.acsAutoSigUse);
              end;
        'F' : begin
                 cfgReadInfo(Cfg^.acsAttachPublic,inLower,chNormal,'',True);
                 Cfg^.acsAttachPublic := cfgRead;
                 cfgSetItem(Cfg^.acsAttachPublic);
              end;
        'G' : begin
                 cfgReadInfo(Cfg^.acsAttachEmail,inLower,chNormal,'',True);
                 Cfg^.acsAttachEmail := cfgRead;
                 cfgSetItem(Cfg^.acsAttachEmail);
              end;
        'H' : begin
                 cfgReadBoolean(Cfg^.AbortMandOk);
                 cfgSetItem(B2St(Cfg^.AbortMandOk));
              end;
        'I' : begin
                 cfgReadBoolean(Cfg^.AskPrivateMsg);
                 cfgSetItem(B2St(Cfg^.AskPrivateMsg));
              end;
        'J' : begin
                 cfgReadBoolean(Cfg^.AskPrivateReply);
                 cfgSetItem(B2St(Cfg^.AskPrivateReply));
              end;
        'K' : begin
                 cfgReadBoolean(Cfg^.AskPostInArea);
                 cfgSetItem(B2St(Cfg^.AskPostInArea));
              end;
        'L' : begin
                 cfgReadBoolean(Cfg^.AskUploadReply);
                 cfgSetItem(B2St(Cfg^.AskUploadReply));
              end;
        'M' : begin
                 cfgReadBoolean(Cfg^.AskUploadEmail);
                 cfgSetItem(B2St(Cfg^.AskUploadEmail));
              end;
        'N' : begin
                 cfgReadBoolean(Cfg^.AskKillMsg);
                 cfgSetItem(B2St(Cfg^.AskKillMsg));
              end;
        'O' : begin
                 cfgReadBoolean(Cfg^.AskKillAllMsg);
                 cfgSetItem(B2St(Cfg^.AskKillAllMsg));
              end;
        'P' : begin
                 cfgReadBoolean(Cfg^.AskAutoQuote);
                 cfgSetItem(B2St(Cfg^.AskAutoQuote));
              end;
        'Q' : begin
                 cfgReadBoolean(Cfg^.DefaultQuoteNum);
                 cfgSetItem(B2St(Cfg^.DefaultQuoteNum));
              end;
        'R' : begin
                 cfgReadInfo(St(Cfg^.maxQuoteLines),inUpper,chNumeric,'',True);
                 Cfg^.maxQuoteLines := mClip(StrToInt(cfgRead),0,20);
                 cfgSetItem(St(Cfg^.maxQuoteLines));
              end;
        'S' : begin
                 cfgReadBoolean(Cfg^.confIgnoreMsg);
                 cfgSetItem(B2St(Cfg^.confIgnoreMsg));
              end;
        'T' : begin
                 cfgReadBoolean(Cfg^.compMsgAreas);
                 cfgSetItem(B2St(Cfg^.compMsgAreas));
              end;
        'U' : begin
                 cfgReadInfo(St(Cfg^.echomailLev),inUpper,chNumeric,'',True);
                 Cfg^.echomailLev := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(Cfg^.echomailLev));
              end;
        'V' : begin
                 cfgEditInfo(Cfg^.ansiString,75,inNormal,chNormal,'',True);
                 Cfg^.ansiString := cfgRead;
                 cfgSetItem(Cfg^.ansiString);
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgNewUserOptions;
var optAlias   : array[1..8] of String;
begin
   cfgDraw := True;
   cfgOver := False;
   optAlias[1] := 'Normal (as entered)';
   optAlias[2] := 'Capitalized (ie Fiend)';
   optAlias[3] := 'Upper case (ie FIEND)';
   optAlias[4] := 'Lower case (ie fiend)';
   optAlias[5] := 'Proper case (ie Peter Piper)';
   optAlias[6] := 'Small vowels (ie FieND)';
   optAlias[7] := 'Big vowels (ie fIEnd)';
   optAlias[8] := 'Small "i"s (ie FiEND)';
   repeat
      cfgInit('New User Options');
      cfgCol := 40;

      cfgItem('A New user password',20,Cfg^.NewUserPW,
              'Password required to apply as a new user (Blank=Disabled)');
      cfgItem('B User alias format',30,cfgOption(optAlias,Cfg^.AliasFormat),
              'Case conversion applied to usernames');
      cfgItem('C Default screen length',3,St(Cfg^.DefaultPageLen),
              '[5-200] The default number of lines displayed before a pause');
      cfgItem('D New user expert',3,B2St(Cfg^.NewExpert),
              'Default new users to expert mode enabled?');
      cfgItem('E New user hot-keys',3,B2St(Cfg^.NewHotKeys),
              'Default new users to "hot-keys" enabled?');
      cfgItem('F New user yes/no bars',3,B2St(Cfg^.NewYesNoBars),
              'Default new users to yes/no selection bars enabled?');
      cfgItem('G New user pausing',3,B2St(Cfg^.NewPause),
              'Default new users to screen pausing enabled?');
      cfgItem('H New user autoquote',3,B2St(Cfg^.NewQuote),
              'Default new users to message autoquoting enabled?');
      cfgItem('I Ask user expert',3,B2St(Cfg^.NewAskExpert),
              'Default new users to expert mode enabled?');
      cfgItem('J Ask hot-keys',3,B2St(Cfg^.NewAskHotKeys),
              'Ask new users if they want "hot-keys" enabled?');
      cfgItem('K Ask yes/no bars',3,B2St(Cfg^.NewAskYesNoBars),
              'Ask new users if they want yes/no selection bars enabled?');
      cfgItem('L Ask screen pausing',3,B2St(Cfg^.NewAskPause),
              'Ask new users if they want screen pausing enabled?');
      cfgItem('M Ask autoquote',3,B2St(Cfg^.NewAskQuote),
              'Ask new users if they want message AutoQuoting enabled?');
      cfgItem('N Ask screen length',3,B2St(Cfg^.NewAskPageLen),
              'Default new users to yes/no selection bars enabled?');
      cfgItem('O Default start menu',8,Cfg^.StartMenu,
              'The first menu to load and execute after logging in');
      cfgItem('P New user config',3,B2St(Cfg^.newConfig),
              'Present new users with a config screen after applying?');
      cfgItem('Q Verify apply command',3,B2St(Cfg^.newVerify),
              'Ask user if he/she still wants to apply after displaying APPLY.ANS?');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Cfg^.NewUserPW,inUpper,chNormal,'',False);
                 Cfg^.NewUserPW := cfgRead;
                 cfgSetItem(Cfg^.NewUserPW);
              end;
        'B' : begin
                 cfgReadOption(optAlias,8,Cfg^.AliasFormat);
                 cfgSetItem(cfgOption(optAlias,Cfg^.AliasFormat));
              end;
        'C' : begin
                 cfgReadInfo(St(Cfg^.DefaultPageLen),inUpper,chNumeric,'',True);
                 Cfg^.DefaultPageLen := mClip(StrToInt(cfgRead),5,200);
                 cfgSetItem(St(Cfg^.DefaultPageLen));
              end;
        'D' : begin
                 cfgReadBoolean(Cfg^.NewExpert);
                 cfgSetItem(B2St(Cfg^.NewExpert));
              end;
        'E' : begin
                 cfgReadBoolean(Cfg^.NewHotKeys);
                 cfgSetItem(B2St(Cfg^.NewHotKeys));
              end;
        'F' : begin
                 cfgReadBoolean(Cfg^.NewYesNoBars);
                 cfgSetItem(B2St(Cfg^.NewYesNoBars));
              end;
        'G' : begin
                 cfgReadBoolean(Cfg^.NewPause);
                 cfgSetItem(B2St(Cfg^.NewPause));
              end;
        'H' : begin
                 cfgReadBoolean(Cfg^.NewQuote);
                 cfgSetItem(B2St(Cfg^.NewQuote));
              end;
        'I' : begin
                 cfgReadBoolean(Cfg^.NewAskExpert);
                 cfgSetItem(B2St(Cfg^.NewAskExpert));
              end;
        'J' : begin
                 cfgReadBoolean(Cfg^.NewAskHotKeys);
                 cfgSetItem(B2St(Cfg^.NewAskHotKeys));
              end;
        'K' : begin
                 cfgReadBoolean(Cfg^.NewAskYesNoBars);
                 cfgSetItem(B2St(Cfg^.NewAskYesNoBars));
              end;
        'L' : begin
                 cfgReadBoolean(Cfg^.NewAskPause);
                 cfgSetItem(B2St(Cfg^.NewAskPause));
              end;
        'M' : begin
                 cfgReadBoolean(Cfg^.NewAskQuote);
                 cfgSetItem(B2St(Cfg^.NewAskQuote));
              end;
        'N' : begin
                 cfgReadBoolean(Cfg^.NewAskPageLen);
                 cfgSetItem(B2St(Cfg^.NewAskPageLen));
              end;
        'O' : begin
                 cfgReadInfo(Cfg^.StartMenu,inUpper,chFilename,'',True);
                 Cfg^.StartMenu := cfgRead;
                 cfgSetItem(Cfg^.StartMenu);
              end;
        'P' : begin
                 cfgReadBoolean(Cfg^.newConfig);
                 cfgSetItem(B2St(Cfg^.newConfig));
              end;
        'Q' : begin
                 cfgReadBoolean(Cfg^.newVerify);
                 cfgSetItem(B2St(Cfg^.newVerify));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgMacroStrings;
var N : Byte;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('SysOp Macro Strings');
      cfgCol := 17;
      for N := 1 to 10 do
      cfgItem(Chr(64+N)+' F'+Resize(St(N),3)+'Macro',58,Cfg^.Macro[N],
              'SysOp macro string for function key: F'+St(N)+'.');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      N := Ord(cfgKey)-64;
      case cfgKey of
        'A'..Chr(64+10) : begin
                 cfgEditInfo(Cfg^.Macro[N],255,inNormal,chNormal,'',False);
                 Cfg^.Macro[N] := cfgRead;
                 cfgSetItem(Cfg^.Macro[N]);
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgFileSystem;
var optSearch : array[1..4] of String;
begin
   optSearch[1] := 'Disabled';
   optSearch[2] := 'Current area';
   optSearch[3] := 'All areas';
   optSearch[4] := 'All areas and conferences';
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('File System Configuration');
      cfgCol := 28;
      cfgItem('A Compress area #''s',3,B2St(Cfg^.compFileAreas),
              'Compress file area list numbers to make sequential?');
      cfgItem('B Import descriptions',3,B2St(Cfg^.importDescs),
              'Import FILE_ID.DIZ or DESC.SDI descriptions from uploads?');
      cfgItem('C Use file point system',3,B2St(Cfg^.useFilePoints),
              'Use the file point system when downloading and uploading?');
      cfgItem('D Kb per file point',5,St(Cfg^.kbPerFilePoint),
              'Value of one file point (in kilobyes)');
      cfgItem('E Use daily DL limit',3,B2St(Cfg^.useDLlimit),
              'Enforce a limit to the number of files downloadable per day?');
      cfgItem('F Use daily DL kb limit',3,B2St(Cfg^.useDLkbLimit),
              'Enforce a limit to the number of kilobytes downloadable per day?');
      cfgItem('G No description string',40,Cfg^.noDescLine,
              'Description to display in file listings for files w/o defined descriptions');
      cfgItem('H Virus scan command',40,Cfg^.virusScan,
              'Command to execute when scanning for viruses [archiver dir] %FN = Filespec');
      cfgItem('I Scan success level',3,St(Cfg^.virusOk),
              'Success errorlevel retured by the virus scanning program');
      cfgItem('J Upload file age limit',3,St(Cfg^.maxFileAge),
              'Files uploaded that are older then this age (in years) will be rejected');
      cfgItem('K Strict age tester',3,B2St(Cfg^.strictAge),
              'Have age tester reject archive if ANY file is beyond age limit?');
      cfgItem('L Delete list filename',12,Cfg^.delFile,
              'List of files to be removed from archives [Ascii file in data dir]');
      cfgItem('M Add list filename',12,Cfg^.addFile,
              'List of files to be added to archives [Ascii file in data dir]');
      cfgItem('N BBS archive comment',12,Cfg^.comFile,
              'Comment file to apply to processed files [Ascii file in data dir]');
      cfgItem('O External maintenence',3,B2St(Cfg^.extMaint),
              'Run "'+fileExtMaint+' [filename]" when processing? [Batch file; data dir]');
      cfgItem('P Upload search method',26,cfgOption(optSearch,Cfg^.ulSearch),
              'Duplicate upload scan method');
      cfgItem('Q Auto-validate uploads',3,B2St(Cfg^.autoValidate),
              'Default uploaded files to being "validated" for transfer?');
      cfgItem('R File point return %',6,St(Cfg^.filePtsPer)+'%',
              'Percentage of uploaded file''s file point value the user will receive');
      cfgItem('S Use UL/DL ratio',3,B2St(Cfg^.useUlDlratio),
              'Allow only a certain number of downloads per each upload?');
      cfgSrt := 40;
      cfgLn := 4;
      cfgCol := 64;
      cfgItem('T Use UL/DL kb ratio',3,B2St(Cfg^.useKbRatio),
              'Limit the number of kilobytes downloadable per each uploaded kilobyte?');
      cfgItem('U Desc filename #1',13,Cfg^.fileDesc1,
              'Primary description filename [used when importing descs from archives]');
      cfgItem('V Desc filename #2',13,Cfg^.fileDesc2,
              'Secondary description filename [used when importing descs from archives]');
      cfgItem('W Wrap file descs',3,B2St(Cfg^.descWrap),
              'Wrap long file descriptions to span multiple pages or clip to screen limit?');
      cfgItem('X Advance file bar',3,B2St(Cfg^.advFileBar),
              'Advance the file listing hilight bar to the next file after flagging?');
      cfgItem('Y Allow blind uploads',3,B2St(Cfg^.allowBlind),
              'Process all files uploaded, even if they were not specified in batch?');
      if cfgDraw then Dec(cfgBot,6);
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadBoolean(Cfg^.compFileAreas);
                 cfgSetItem(B2St(Cfg^.compFileAreas));
              end;
        'B' : begin
                 cfgReadBoolean(Cfg^.importDescs);
                 cfgSetItem(B2St(Cfg^.importDescs));
              end;
        'C' : begin
                 cfgReadBoolean(Cfg^.useFilePoints);
                 cfgSetItem(B2St(Cfg^.useFilePoints));
              end;
        'D' : begin
                 cfgReadInfo(St(Cfg^.kbPerFilePoint),inUpper,chNumeric,'',True);
                 Cfg^.kbPerFilePoint := mClip(StrToInt(cfgRead),1,10000);
                 cfgSetItem(St(Cfg^.kbPerFilePoint));
              end;
        'E' : begin
                 cfgReadBoolean(Cfg^.useDLlimit);
                 cfgSetItem(B2St(Cfg^.useDLlimit));
              end;
        'F' : begin
                 cfgReadBoolean(Cfg^.useDLkbLimit);
                 cfgSetItem(B2St(Cfg^.useDLkbLimit));
              end;
        'G' : begin
                 cfgEditInfo(Cfg^.noDescLine,50,inNormal,chNormal,'',False);
                 Cfg^.noDescLine := cfgRead;
                 cfgSetItem(Cfg^.noDescLine);
              end;
        'H' : begin
                 cfgEditInfo(Cfg^.virusScan,50,inNormal,chNormal,'',False);
                 Cfg^.virusScan := cfgRead;
                 cfgSetItem(Cfg^.virusScan);
              end;
        'I' : begin
                 cfgReadInfo(St(Cfg^.virusOk),inUpper,chNumeric,'',True);
                 Cfg^.virusOk := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(Cfg^.virusOk));
              end;
        'J' : begin
                 cfgReadInfo(St(Cfg^.maxFileAge),inUpper,chNumeric,'',True);
                 Cfg^.maxFileAge := mClip(StrToInt(cfgRead),1,255);
                 cfgSetItem(St(Cfg^.maxFileAge));
              end;
        'K' : begin
                 cfgReadBoolean(Cfg^.strictAge);
                 cfgSetItem(B2St(Cfg^.strictAge));
              end;
        'L' : begin
                 cfgReadInfo(Cfg^.delFile,inUpper,chFilename,'',False);
                 Cfg^.delFile := cfgRead;
                 cfgSetItem(Cfg^.delFile);
              end;
        'M' : begin
                 cfgReadInfo(Cfg^.addFile,inUpper,chFilename,'',False);
                 Cfg^.addFile := cfgRead;
                 cfgSetItem(Cfg^.addFile);
              end;
        'N' : begin
                 cfgReadInfo(Cfg^.comFile,inUpper,chFilename,'',False);
                 Cfg^.comFile := cfgRead;
                 cfgSetItem(Cfg^.comFile);
              end;
        'O' : begin
                 cfgReadBoolean(Cfg^.extMaint);
                 cfgSetItem(B2St(Cfg^.extMaint));
              end;
        'P' : begin
                 cfgReadOption(optSearch,4,Cfg^.ulSearch);
                 cfgSetItem(cfgOption(optSearch,Cfg^.ulSearch));
              end;
        'Q' : begin
                 cfgReadBoolean(Cfg^.autoValidate);
                 cfgSetItem(B2St(Cfg^.autoValidate));
              end;
        'R' : begin
                 cfgSetItem('       ');
                 cfgReadInfo(St(Cfg^.filePtsPer),inUpper,chNumeric,'',True);
                 Cfg^.filePtsPer := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Cfg^.filePtsPer)+'%');
              end;
        'S' : begin
                 cfgReadBoolean(Cfg^.useUlDlratio);
                 cfgSetItem(B2St(Cfg^.useUlDlratio));
              end;
        'T' : begin
                 cfgReadBoolean(Cfg^.useKbratio);
                 cfgSetItem(B2St(Cfg^.useKbratio));
              end;
        'U' : begin
                 cfgReadInfo(Cfg^.fileDesc1,inUpper,chFilename,'',False);
                 Cfg^.fileDesc1 := cfgRead;
                 cfgSetItem(Cfg^.fileDesc1);
              end;
        'V' : begin
                 cfgReadInfo(Cfg^.fileDesc2,inUpper,chFilename,'',False);
                 Cfg^.fileDesc2 := cfgRead;
                 cfgSetItem(Cfg^.fileDesc2);
              end;
        'W' : begin
                 cfgReadBoolean(Cfg^.descWrap);
                 cfgSetItem(B2St(Cfg^.descWrap));
              end;
        'X' : begin
                 cfgReadBoolean(Cfg^.advFileBar);
                 cfgSetItem(B2St(Cfg^.advFileBar));
              end;
        'Y' : begin
                 cfgReadBoolean(Cfg^.allowBlind);
                 cfgSetItem(B2St(Cfg^.allowBlind));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgOfflineMail;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Offline Mail Setup');
      cfgItem('A QWK filename prefix',8,Cfg^.qwkFilename,
              'QWK/ID filename prefix for QWK and REP packets');
      cfgItem('B Welcome filename',12,Cfg^.qwkWelcome,
              'QWK welcome banner filename, must be in text directory');
      cfgItem('C News filename',12,Cfg^.qwkNews,
              'QWK news filename, must be in text directory');
      cfgItem('D Goodbye filename',12,Cfg^.qwkGoodbye,
              'QWK goodbye filename, must be in text directory');
      cfgItem('E Local QWK path',40,Cfg^.qwkLocalPath,
              'Path where .QWK files will be placed when downloaded locally');
      cfgItem('F Ignore time left',3,b2St(Cfg^.qwkIgnoreTime),
              'Ignore time remaining online when downloading QWK packets?');
      cfgItem('G Strip autosigs',3,b2St(Cfg^.qwkStripSigs),
              'Strip autosignatures from messages before exporting QWK?');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Cfg^.qwkFilename,inUpper,chFileNoExt,'',True);
                 Cfg^.qwkFilename := cfgRead;
                 cfgSetItem(Cfg^.qwkFilename);
              end;
        'B' : begin
                 cfgReadInfo(Cfg^.qwkWelcome,inUpper,chFilename,'',False);
                 Cfg^.qwkWelcome := cfgRead;
                 cfgSetItem(Cfg^.qwkWelcome);
              end;
        'C' : begin
                 cfgReadInfo(Cfg^.qwkNews,inUpper,chFilename,'',False);
                 Cfg^.qwkNews := cfgRead;
                 cfgSetItem(Cfg^.qwkNews);
              end;
        'D' : begin
                 cfgReadInfo(Cfg^.qwkGoodbye,inUpper,chFilename,'',False);
                 Cfg^.qwkGoodbye := cfgRead;
                 cfgSetItem(Cfg^.qwkGoodbye);
              end;
        'E' : begin
                 cfgReadInfo(Cfg^.qwkLocalPath,inUpper,chDirectory,'',True);
                 Cfg^.qwkLocalPath := cfgRead;
                 if Cfg^.qwkLocalPath[Length(Cfg^.qwkLocalPath)] <> '\' then
                    Cfg^.qwkLocalPath := Cfg^.qwkLocalPath+'\';
                 cfgSetItem(Cfg^.qwkLocalPath);
                 cfgAskCreate(Cfg^.qwkLocalPath);
              end;
        'F' : begin
                 cfgReadBoolean(Cfg^.qwkIgnoreTime);
                 cfgSetItem(B2St(Cfg^.qwkIgnoreTime));
              end;
        'G' : begin
                 cfgReadBoolean(Cfg^.qwkStripSigs);
                 cfgSetItem(B2St(Cfg^.qwkStripSigs));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgNewUserVoting;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('New User Voting Config');
      cfgItem('A "Yes" votes to validate',3,st(cfg^.nuvVotesYes),
              '[1-255] Number of "yes" votes required for a user to be auto-validated');
      cfgItem('B "No" votes to delete',3,st(cfg^.nuvVotesNo),
              '[1-255] Number of "no" votes necessary for a user to be terminated');
      cfgItem('C Unvalidated user access',20,cfg^.nuvAccess,
              'Users who meet this condition are prospects for new user voting');
      cfgItem('D Access to vote',20,cfg^.nuvVoteAccess,
              'Access condition required to vote on new users');
      cfgItem('E Comment initials',3,b2st(cfg^.nuvInitials),
              'Apply user''s alias initials (ie fiend = fi) to NUV comments?');
      cfgItem('F Validation level',1,cfg^.nuvUserLevel,
              'Access level (set in level editor) to upgrade user to if voted in');
      cfgItem('G Use new user voting?',3,b2st(cfg^.nuvValidation),
              'Do you want to use NUV as a validation method on this BBS?');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(st(cfg^.nuvVotesYes),inUpper,chNumeric,'',True);
                 cfg^.nuvVotesYes := mClip(strToInt(cfgRead),1,255);
                 cfgSetItem(st(cfg^.nuvVotesYes));
              end;
        'B' : begin
                 cfgReadInfo(st(cfg^.nuvVotesNo),inUpper,chNumeric,'',True);
                 cfg^.nuvVotesNo := mClip(strToInt(cfgRead),1,255);
                 cfgSetItem(st(cfg^.nuvVotesNo));
              end;
        'C' : begin
                 cfgReadInfo(cfg^.nuvAccess,inLower,chNormal,'',True);
                 cfg^.nuvAccess := cfgRead;
                 cfgSetItem(cfg^.nuvAccess);
              end;
        'D' : begin
                 cfgReadInfo(cfg^.nuvVoteAccess,inLower,chNormal,'',True);
                 cfg^.nuvVoteAccess := cfgRead;
                 cfgSetItem(cfg^.nuvVoteAccess);
              end;
        'E' : begin
                 cfgReadBoolean(cfg^.nuvInitials);
                 cfgSetItem(b2st(cfg^.nuvInitials));
              end;
        'F' : begin
                 cfgReadInfo(cfg^.nuvUserLevel,inUpper,chAlpha,'',True);
                 cfg^.nuvUserLevel := cfgRead[1];
                 cfgSetItem(cfg^.nuvUserLevel);
              end;
        'G' : begin
                 cfgReadBoolean(cfg^.nuvValidation);
                 cfgSetItem(b2st(cfg^.nuvValidation));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgSystemConfig;
var cfgOld  : tCfgRec; oldBar : Byte;
begin
   cfgOld := Cfg^;
   logWrite('*System configuration edit');
   oldBar := 1;
   repeat
      cfgDraw := True;
      cfgOver := False;
      cfgInit(bbsTitle+' v'+bbsVersion+' System Configuration');
      cfgBarPos := oldBar;
      cfgItem('A Main BBS configuration',0,'','');
      cfgItem('B Status bar options',0,'','');
      cfgItem('C Color configuration',0,'','');
      cfgItem('D Network address setup',0,'','');
      cfgItem('E Edit macro strings',0,'','');
      cfgItem('F Filenames and paths',0,'','');
      cfgItem('G Wait-for-call config',0,'','');
      cfgItem('H Miscellaneous options',0,'','');
      cfgItem('I Offline mail setup',0,'','');
      cfgSrt := 38;
      cfgCol := 60;
      cfgLn := cfgTop;
      cfgItem('J Swapping setup',0,'','');
      cfgItem('K Login configuration',0,'','');
      cfgItem('L Origin line configuration',0,'','');
      cfgItem('M Logging options',0,'','');
      cfgItem('N Message system config',0,'','');
      cfgItem('O New user options',0,'','');
      cfgItem('P Chat mode setup',0,'','');
      cfgItem('Q File system config',0,'','');
      cfgItem('R New user voting config',0,'','');
      if cfgDraw then Dec(cfgBot,9);
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      oldBar := cfgBarPos;
      case cfgKey of
        'A' : cfgMainBBSConfig;
        'B' : cfgStatusBar;
        'C' : cfgColorConfig;
        'D' : cfgNetAddress;
        'E' : cfgMacroStrings;
        'F' : cfgPaths;
        'G' : cfgWaitForCall;
        'H' : cfgMiscOptions;
        'I' : cfgOfflineMail;

        'J' : cfgSwappingSetup;
        'K' : cfgLoginConfig;
        'L' : cfgOriginLines;
        'M' : cfgLoggingOptions;
        'N' : cfgMessageSystem;
        'O' : cfgNewUserOptions;
        'P' : cfgChatSetup;
        'Q' : cfgFileSystem;
        'R' : cfgNewUserVoting;
      end;
   until (HangUp) or (cfgDone);
   cfgInfo('Save configuration? ');
   if iYesNo(True) then fSaveCfg else Cfg^ := cfgOld;
end;

end.