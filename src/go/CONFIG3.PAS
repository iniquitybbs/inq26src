{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config3;

interface

procedure cfgStringEditor;

implementation

uses
   Crt,
   Global, Output, Strings, Input, Files, Config, BBSinit, Logs, Misc;

const
   maxStr = 5;

var
   curStr : Integer;
   sStr : String;

function cfgStringHeader(N : Word) : String;
var S : String;
begin
   S := '';
   case N of
     strDetectEmu         : S := '[misc]  Detecting emulation';
     strDetectNone        : S := '[misc]  No emulation detected';
     strDetectANSi        : S := '[misc]  ANSI detected';
     strDetectAVATAR      : S := '[misc]  Avatar/ANSI detected';
     strDetectRIP         : S := '[misc]  RIP/ANSI detected (terminal: %S1)';
     strConnectedAt       : S := '[misc]  Connected at %S1 baud';
     strLoginSystemPW     : S := '[login] Enter system password: ';
     strAskSystemPW       : S := '[misc]  System password: ';
     strPause             : S := '[misc]  Paused - [S]top / [C]ontinuous';
     strHitAKey           : S := '[misc]  Press a key to continue';
     strMenuPassword      : S := '[menu]  Menu password: ';
     strMenuAccessDenied  : S := '[menu]  Menu access denied.';
     strCmdAccessDenied   : S := '[menu]  Command access denied.';
     strInvalidCommand    : S := '[menu]  Invalid menu command.';
     strInvalidMnuCmd     : S := '[menu]  Invalid menu command: "%S1"';
     strLoginName         : S := '[login] Enter your name, handle, or user number: ';
     strLoginPassword     : S := '[login] Enter your password: ';
     strLoginPhone        : S := '[login] Complete phone number: (###)###-';
     strLoginBDate        : S := '[login] Enter your birthdate [mm/dd/yy]: ';
     strLoginUnknown      : S := '[login] Unknown user';
     strLoginError        : S := '[login] Login error';
     strLoginAskApply     : S := '[login] Apply as a NEW user? ';
     strNuHandle          : S := '[new]   Please Select an Alias: ';
     strNuName            : S := '[new]   Enter Your REAL First and Last Name: ';
     strNuBirthDate       : S := '[new]   Enter Your Date of Birth [MM/DD/YY]: ';
     strNuPhoneNum        : S := '[new]   Enter Your Voice Phone Number: ';
     strNuAddress         : S := '[new]   Enter Your Address: ';
     strNuLocation        : S := '[new]   Enter Your City name: ';
     strNuYesNoBar        : S := '[new]   Do You Wish to Use Yes/No Selection Bars? ';
     strNuHotKey          : S := '[new]   Enable HotKeys for Faster Menu Input? ';
     strNuExpertMode      : S := '[new]   Enable "Expert" Mode? ';
     strNuPassword        : S := '[new]   Please Select a Password: ';
     strNuBadAlias        : S := '[new]   Invalid Alias.  Choose Another.';
     strNuDupUser         : S := '[new]   Duplicate User.';
     strNuBadName         : S := '[new]   Invalid Name.';
     strNuFullName        : S := '[new]   You Must Enter Your FIRST And LAST Name.';
     strNuBadBirth        : S := '[new]   Invalid Birthdate.';
     strNuSmallPassword   : S := '[new]   Password Too Short.  It Must Be At Least 4 Characters in Length.';
     strNuValidatePW      : S := '[new]   --   Password Validation: ';
     strNuPWnoMatch       : S := '[new]   Passwords Do Not Match.  Try Again.';
     strNuSavingInfo      : S := '[new]   Saving information....';
     strNuYourAgeIs       : S := '[new]   You Are Currently %S1 Years Old.';
     strNuAskSex          : S := '[new]   Your Sex? [M]ale [F]emale: ';
     strNuEnterNewUserPW  : S := '[new]   Enter NewUser Application Password: ';
     strNuBadNewUserPW    : S := '[new]   Incorrect NewUser Password.';
     strChatInitiate      : S := '[chat]  - Chat Mode Initiated -';
     strChatTerminate     : S := '[chat]  - Chat Mode Terminated -';
     strJumpToDOS         : S := '[dos]   -] SysOp in DOS. Please Wait [-';
     strBackFromDOS       : S := '[dos]   -] SysOp has Returned From DOS [-';
     strFsAskAbort        : S := '[fse]   Abort Message?';
     strFsAskCommand      : S := '[fse]   Message Editor Command [?/Help]: ';
     strFsCommandHelp     : S := '[fse]   Enter '+bbsTitle+' Message Editor Command.  Hit ''?'' for Help.';
     strFsSavingMsg       : S := '[fse]   Saving Message...';
     strMsgNoPostAcs      : S := '[msg]   Insufficient ACS to Post in This Area.';
     strMsgAskWhoTo       : S := '[msg]   |CSMessage Destination: ';
     strMsgAskPrivate     : S := '[msg]   Private Message? ';
     strMsgAskTitle       : S := '[msg]   Enter Message Title: ';
     strMsgReadNoMsgs     : S := '[msg]   There Are No Messages in the Current Message Area.';
     strMsgReadStartAt    : S := '[msg]   Start Reading At Which Message? [1-%S1] [Current=%S2]: ';
     strMsgReadPrompt     : S := '[msg]   -- Reading Message %S1 of %S2 ù Command [?/HelpùCR/Next]: ';
     strMsgReadAskPost    : S := '[msg]   Post a Message in This Area? ';
     strMsgAlterTitle     : S := '[msg]   Enter New Message Title.';
     strMsgQuoteFirst     : S := '[msg]   Enter First Line of Message to Quote [1-%S1]: ';
     strMsgQuoteSecond    : S := '[msg]   Enter Second Line of Message to Quote [%S1-%S2]: ';
     strMsgDeleted        : S := '[msg]   Message Deleted.';
     strMsgUndeleted      : S := '[msg]   Message Undeleted.';
     strMsgNewScanInit    : S := '[msg]   -- Global Message NewScan Initiated';
     strMsgNewScanDone    : S := '[msg]   -- Global Message NewScan Completed';
     strMsgNewScanStart   : S := '[msg]   Message area %S1 - [%S2] Msgs þ Newscanning...';
     strMsgNewScanEnd     : S := '[msg]   Message area %S1 - [%S2] Msgs þ Complete...';
     strMsgNewScanAskAll  : S := '[msg]   Newscan all message areas? ';
     strMsgPackStart      : S := '[msg]   Packing Message Area [%S1] - %S2 Msgs... ';
     strMsgPackEnd        : S := '[msg]   Message Packing Complete.';
     strMsgPackAskAll     : S := '[msg]   Pack All Message Areas? ';
     strAnonymous         : S := '[msg]   Anonymous';
     strNoAutoMsg         : S := '[auto]  No AutoMessage Currently Exists.';
     strMsgAskAnonymous   : S := '[msg]   Post Anonymously? ';
     strBBSaskName        : S := '[bbs]   Enter the Name of the BBS to Add: ';
     strBBSexists         : S := '[bbs]   That BBS Already Exists in the List.';
     strBBSaskPhone       : S := '[bbs]   Enter BBS Phone Number: ';
     strBBSaskSysOp       : S := '[bbs]   Enter SysOp of the BBS: ';
     strBBSaskBaud        : S := '[bbs]   Enter the BBS''s Maximum BaudRate: ';
     strBBSaskSoftware    : S := '[bbs]   Enter BBS Software: ';
     strBBSaskStorage     : S := '[bbs]   Enter the BBS''s Maximum Storage in MegaBytes: ';
     strBBSaskInfo        : S := '[bbs]   Other Info: ';
     strBBSsavingEntry    : S := '[bbs]   Adding BBS to List...';
     strBBSaskSaveBBS     : S := '[bbs]   Save This System to BBS List? ';
     strAutoMsgAnon       : S := '[auto]  Can''t reply to an anonymous automessage!';
     strMsgReadMandatory  : S := '[msg]   You Must Read ALL Messages in This Area.';
     strBBSnoSystems      : S := '[bbs]   There Are Currently No Boards in the List.';
     strBBSshowOne        : S := '[bbs]   Enter system number to display [1-%S1]: ';
     strNuAskPageLen      : S := '[new]   Enter your screen length in rows: ';
     strBBSdeleteOne      : S := '[bbs]   Remove which BBS from list? [1-%S1]: ';
     strBBSverifyKill     : S := '[bbs]   Delete this system? ';
     strBBSclearAll       : S := '[bbs]   Clear the entire BBS list? ';
     strEmailUserUnknown  : S := '[email] That user doesn''t exist.';
     strEmailNoMail       : S := '[email] You currently have no mail waiting.';
     strEmailSelectToRead : S := '[email] Enter number of message to begin reading at [1-%S1]: ';
     strEmailReadPrompt   : S := '[email] -- Reading Email %S1 of %S2 ù Command [?/HelpùCR/Next]:';
     strEmailNoAccess     : S := '[email] Email access denied.';
     strLoginHelpName     : S := '[login] Enter your name, handle or user number.';
     strLoginHelpPw       : S := '[login] Enter your password.';
     strLoginHelpPhone    : S := '[login] Please complete your phone number.';
     strLoginHelpBirth    : S := '[login] Enter your birthdate.';
     strLoginHelpApply    : S := '[login] Logon to system as a new user?';
     strLoginHelpSysPw    : S := '[login] Enter system password.';
     strEmailKillOriginal : S := '[email] Delete original message?';
     strNuAskState        : S := '[new]   Enter your state or province abbreviation: ';
     strMsgSetPointer     : S := '[msg]   Message base newscan pointer set to current message.';
     strPageAskWhy        : S := '[chat]  Why do you wish to chat with the SysOp?: ';
     strPageSysOpNotAvail : S := '[chat]  The SysOp is currently not available to chat.  Try leaving mail.';
     strPagePaging        : S := '[chat]  Paging!';
     strPageNoAnswer      : S := '[chat]  Sorry, the SysOp was unable to answer your page.';
     strEmailAskRead      : S := '[email] You have email.  Read it? ';
     strMsgAskChangeArea  : S := '[msg]   Change to which message area? ';
     strMsgChangedAreas   : S := '[msg]   Current message area is now %S1.';
     strTimeExpired       : S := '[misc]  Sorry, your time has expired.';
     strMsgAskPointer     : S := '[msg]   Enter new message pointer date [mm/dd/yy]: ';
     strMsgAskAllPointers : S := '[msg]   Update all message area pointers? ';
     strXferSelectProtocol: S := '[xfer]  Select protocol [CR/Abort]: ';
     strMsgAskUploadMsg   : S := '[msg]   Upload prepared message? ';
     strAutoSigChanged    : S := '[sig]   AutoSig saved.';
     strAutoSigAskDelete  : S := '[sig]   Delete current AutoSig? ';
     strAutoSigDeleted    : S := '[sig]   AutoSig deleted.';
     strAutoSigShow       : S := '[sig]   Current AutoSig:';
     strAutoSigNone       : S := '[sig]   You have no AutoSig.';
     strAutoSigAskUpload  : S := '[sig]   Upload prepared AutoSignature? ';
     strMsgScanMandatory  : S := '[msg]   Scanning for mandatory messages...';
     strEmailSent         : S := '[email] Email sent to %S1';
     strEmailAskKillAll   : S := '[email] Delete all read email? ';
     strMsgAskPassword    : S := '[msg]   Enter password for this message area: ';
     strFaAskPassword     : S := '[file]  Enter password for this file area: ';
     strFaAskChangeArea   : S := '[file]  Change to which file area? ';
     strFaChangedAreas    : S := '[file]  Current file area is now %S1.';
     strFaNoFilesInArea   : S := '[file]  Sorry, this file area contains no files.';
     strFaSortStart       : S := '[file]  Sorting file area [%S1] - %S2 files... ';
     strFaSortEnd         : S := '[file]  Sorting complete.';
     strFaSortAskAll      : S := '[file]  Sort all file areas? ';
     strInitBBS           : S := '[misc]  Initializing '+bbsTitle+'...';
     strConfMsgSelect     : S := '[conf]  Select message conference to join [?/list]: ';
     strConfFileSelect    : S := '[conf]  Select file conference to join [?/list]: ';
     strConfMsgChanged    : S := '[conf]  Joined message conference: %S1';
     strConfFileChanged   : S := '[conf]  Joined file conference: %S1';
     strNuPausing         : S := '[new]   Enable screen pausing? ';
     strNuAutoQuote       : S := '[new]   Use reply AutoQuoting? ';
     strMsgAskQuote       : S := '[msg]   AutoQuote text from message? ';
     strAtchAskDesc       : S := '[atch]  Enter description of attached file: ';
     strAtchFileAttached  : S := '[atch]  File "%S1" successfully attached to message.';
     strAtchAlreadyInc    : S := '[atch]  There is already a file attached to this message.  Replace it?';
     strAtchIsAttached    : S := '[atch]  There is a file attached to this message.';
     strAtchShowDesc      : S := '[atch]  Attached file description: %S1';
     strAtchShowInfo      : S := '[atch]  Attached file name: %S1, size: %S2';
     strAtchAskDownload   : S := '[atch]  Do you wish to download this file now? ';
     strFaAskFileDownload : S := '[file]  Enter filename to download: ';
     strFaSearching       : S := '[file]  Searching for file ... ';
     strFaFileNotFound    : S := '[file]  File not found.';
     strFaFoundInArea     : S := '[file]  %S1 found in file area: %S2';
     strFaFileNotThere    : S := '[file]  File %S1 does not actually exist.';
     strFaDownloadPrompt  : S := '[file]  File download -- [Enter/C] Continue, [Esc/A] Abort: ';
     strFaNoTimeForDL     : S := '[file]  %S1: Insufficient time remaining for download.';
     strFaNewScanning     : S := '[file]  File area %S1 - [%S2] files þ Newscanning...';
     strFaNewScanAskAll   : S := '[file]  Newscan all file areas? ';
     strFaAskNewScanDate  : S := '[file]  Enter file newscan date [mm/dd/yy]: ';
     strFaNoFilePts       : S := '[file]  %S3: Insufficient file points for file [have: %S1; need: %S2]';
     strFaOverDLlimit     : S := '[file]  %S2 would exceed your daily download limit of %S1 files p/day.';
     strFaOverDLkbLimit   : S := '[file]  %S2 would exceed your daily download kb limit of %S1kb p/day.';
     strFaFileNotValid    : S := '[file]  Sorry, %S1 has not yet been validated.';
     strQwkDLaskCurConf   : S := '[qwk]   Gather messages from current conference only? ';
     strQwkDLerror        : S := '[qwk]   Error encountered while creating QWK message packet, inform SysOp.';
     strQwkDLaskDownload  : S := '[qwk]   QWK packet size: %S1 bytes ... Download it? ';
     strQwkDLnoNewMsgs    : S := '[qwk]   Sorry, there are no new messages.';
     strQwkDLaskUpdatePtrs: S := '[qwk]   Update message area newscan pointers?';
     strQwkDLupdatingPtrs : S := '[qwk]   Updating message pointers ... Please wait.';
     strQwkULerror        : S := '[qwk]   Error encountered while processing REP packet, inform SysOp.';
     strMsgPublicPosted   : S := '[msg]   Message posted in area: %S1';
     strFaAskListFiles    : S := '[file]  Enter filespec to list [Enter for all]';
     strFaNoMatchingFiles : S := '[file]  No matching files found.';
     strQwkULalready      : S := '[qwk]   This REP packet has already been uploaded!';
     strQwkDLownMsgs      : S := '[qwk]   Include your own messages in packet?';
     strFaBatchFull       : S := '[file]  Sorry, your download batch is full.';
     strFaBatchAskAdd     : S := '[file]  Enter filename to add to batch:';
     strFaBatchAdded      : S := '[file]  File "%S1" added to batch.';
     strFaBatchFileDL     : S := '[file]  Selected for download: %S1 [size = %S2 bytes, time = %S3]';
     strFaBatchDLtotal    : S := '[file]  Total selected: %S1 files, %S2 bytes [time = %S3]';
     strFaBatchAskDL      : S := '[file]  %S1 files in batch, download them now?';
     strFaBatchAlready    : S := '[file]  That file is already in your download batch.';
     strFaXferFailed      : S := '[file]  Transfer failed';
     strFaXferSuccess     : S := '[file]  Transfer successful';
     strFaXferFilesSent   : S := '[file]  %S2 bytes sent in %S1 file(s)';
     strFaListInfo        : S := '[file]  Listing files - up/dn: file selector; left/right: lightbar';
     strFaListInfoBar     : S := '[file]  File selector - up/dn: filebar; left/right: menu lightbar';
     strFaViewAskFile     : S := '[file]  Enter archive name to view:';
     strFaInfoAskfile     : S := '[file]  Show information on which file?';
     strFaULnoAccess      : S := '[file]  You do not have upload access in this area.';
     strFaDLnoAccess      : S := '[file]  You do not have download access in this area.';
     strFaDLaccessDenied  : S := '[file]  %S1: Download access denied.';
     strFaTestCRCok       : S := '[scan]  %S1 passed integrity (CRC) check.';
     strFaTestCRCfail     : S := '[scan]  %S1 failed integrity check!';
     strFaTestDecompOk    : S := '[scan]  %S1 decompressed successfully.';
     strFaTestDecompFail  : S := '[scan]  Error decompressing %S1!';
     strFaTestVirusOk     : S := '[scan]  %S1 passed virus scan.';
     strFaTestVirusFail   : S := '[scan]  %S1 failed virus scan!';
     strFaTestAgeOk       : S := '[scan]  %S1 passed age test.  File date: %S2';
     strFaTestAgeFail     : S := '[scan]  %S1 failed age test!  File date: %S2';
     strFaTestFilesRemoved: S := '[scan]  Useless files removed from %S1.';
     strFaTestFilesAdded  : S := '[scan]  Necessary files added to %S1.';
     strFaTestCommented   : S := '[scan]  BBS file comment successfully added to %S1.';
     strFaTestExternal    : S := '[scan]  External maintenence on %S1 complete.';
     strFaTestDescFound   : S := '[scan]  Description found in %S1.';
     strFaTestNoDesc      : S := '[scan]  No description found in %S1.';
     strFaTestSauceFound  : S := '[scan]  Sauce description found in %S1.';
     strFaTestNoSauce     : S := '[scan]  %S1 does not contain a sauce description.';
     strFaTestPassed      : S := '[scan]  %S1 has passed all file tests.';
     strFaTestFailed      : S := '[scan]  %S1 failed.';
     strFaULenterFiles    : S := '[file]  Enter up to %S1 files to upload.';
     strFaULenterToEnd    : S := '[file]  Hit ENTER on a blank line when done.';
     strFaULenterFilename : S := '[file]  [%S1] File to upload: ';
     strFaULfileExists    : S := '[file]  Sorry, %S1 is already on this BBS.';
     strFaULaskDescNow    : S := '[file]  Enter file description(s) now or after transfer?';
     strFaULaddingFile    : S := '[file]  Adding %S1 to file area ...';
     strFaULfileAdded     : S := '[file]  %S1 added [%S2 line description]';
     strFaULdescribe      : S := '[file]  Enter file description for %S1.  Blank line when done';
     strFaULdescLine      : S := '[file]  Desc line #%S1: ';
     strFaULDLratioBad    : S := '[file]  %S1 would put your UL/DL ratio out of balance.';
     strFaKBratioBad      : S := '[file]  %S1 would put your UL/DL kilobyte ratio out of balance.';
     strFaLowestArea      : S := '[file]  Lowest accessible file area.';
     strFaHighestArea     : S := '[file]  Highest accessible file area.';
     strMsgLowestArea     : S := '[msg]   Lowest accessible message area.';
     strMsgHighestArea    : S := '[msg]   Highest accessible message area.';
     strInfoAskWhich      : S := '[info]  Fill out which infoform? [1-%S1]';
     strInfoAskReplace    : S := '[info]  This infoform has already been completed.  Continue?';
     strNuAskCountry      : S := '[new]   Your country? [U]nited States / [C]anada / [O]ther: ';
     strNuEnterCountry    : S := '[new]   Enter the name of your country:';
     strNuEnterZipCode    : S := '[new]   Enter your postal/zip code [format: %S1]:';
     strNuAskApply        : S := '[new]   Proceed with new user application process?';
     strPwAskOld          : S := '[pass]  Enter current password:';
     strPwWrong           : S := '[pass]  Incorrect password.';
     strPwNewPassword     : S := '[pass]  Enter your new password:';
     strPwTooSmall        : S := '[pass]  Password must be at least 4 characters long.';
     strPwValidate        : S := '[pass]  Verify new password:';
     strPwNoMatch         : S := '[pass]  Passwords do not match!';
     strPwChanged         : S := '[pass]  Password successfully changed.';
     strPageNoMore        : S := '[chat]  Sorry, you can''t page the sysop (maximum per call = %S1)';
     strPageAskOverride   : S := '[chat]  Chat availability is disabled.  Do you wish to override?';
     strPageAskPassword   : S := '[chat]  Enter chat override password:';
     strPageBadPw         : S := '[chat]  Incorrect override password.';
     strTimeInactive      : S := '[misc]  Sorry, you have been auto-logged off due to inactivity.';
     strPageBegin         : S := '[chat]  Paging sysop ... (press any key to abort page)';
     strPageLeaveEmail    : S := '[chat]  Send email to the sysop (%S1)?';
     strFaSearchAskFile   : S := '[file]  Enter filespec to search for: ';
     strFaSearchAskAll    : S := '[file]  Search all file areas?';
     strFaSearchAskConfs  : S := '[file]  Search all file conferences?';
     strFaSearchArea      : S := '[file]  Searching file area %S1 ...';
     strFaSearchNone      : S := '[file]  No matching files found';
     strFaULfileFound     : S := '[file]  Blind upload detected.  Found: %S1';
     strFaULaskBlind      : S := '[file]  Perform a "blind" upload?';
     strNuvScanning       : S := '[nuv]   Checking for new users to vote on ...';
     strNuvVote           : S := '[nuv]   Your vote for %S1? [y)es n)o a)bstain i)nfoforms]';
     strNuvAskComment     : S := '[nuv]   Leave a comment about this user?';
     strNuvComment        : S := '[nuv]   Enter nuv comment:';
     strNuvValidated      : S := '[nuv]   %S1 has been auto-validated.';
     strNuvDeleted        : S := '[nuv]   %S1 has been deleted.';
     strNuvNoInfoforms    : S := '[nuv]   No NUV infoforms exist for this user.';
     strNuvIsDisabled     : S := '[nuv]   New user voting is disabled on this BBS.';
     strFaSearchAskDesc   : S := '[file]  Enter text to search for: ';
     strNuvNone           : S := '[nuv]   There are no new users to vote on.';
     strNodeNotMulti      : S := '[node]  This is not a multi-node BBS, function disabled';
   end;
   cfgStringHeader := S;
end;

procedure cfgWriteStrings;
var N : Byte;
begin
   for N := 1 to maxStr do if curStr+N-1 <= numString then
   begin
      oCWriteLn('|U1'+St(N)+'|U2:|U1'+z3(curStr+N-1)+
                '|U2, |U4'+cfgStringHeader(curStr+N-1));
      oSetCol(colInfo);
      oCWriteLn(mStr(curStr+N-1));
      oDnLn(1);
   end;
end;

procedure cfgEditString(N : Byte);
begin
   oDnLn(2);
   oSetCol(colInfo);
   oWriteLn(cfgStringHeader(curStr+N-1));
   oSetCol(colBorder);
   oWriteLn(sRepeat('Ä',79));
   oSetCol(colInfoHi);
   mStrSet(curStr+N-1,
      iEditString(mStr(curStr+N-1),inNormal,chNormal,rsNoClean+rsSpace+rsAbort,255,79));
end;

procedure cfgSearchString;
var S : String; Col : Boolean; Fnd, N, ss1, ss2, sc1, sc2 : Word;
begin
   oDnLn(2);
   if sStr <> '' then oStrCtrLn('|U2-- |U1Current|U2: |U3'+strSquish(sStr,65));
   oStrCtr('|U2-- |U1Enter text to search for |U5[|U6enter|U5/|U4next|U5]: |U3');
   S := UpStr(iReadString('',inNormal,chNormal,rsNoClean+rsSpace,200));
   if S = '' then S := sStr;
   if S = '' then Exit;
   sStr := S;
   Col := NoColor(S) <> S;
   ss1 := curStr+maxStr;
   if ss1 > numString then ss1 := numString;
   ss2 := numString;
   sc1 := 1;
   sc2 := curStr+maxStr-1;
   Fnd := 0;
   for N := ss1 to ss2 do if Fnd = 0 then
   begin
      if Col then Fnd := Pos(sStr,UpStr(mStr(N))) else
                  Fnd := Pos(sStr,UpStr(NoColor(mStr(N))));
      if Fnd > 0 then Fnd := N;
   end;
   if Fnd = 0 then
   for N := sc1 to sc2 do if Fnd = 0 then
   begin
      if Col then Fnd := Pos(sStr,UpStr(mStr(N))) else
                  Fnd := Pos(sStr,UpStr(NoColor(mStr(N))));
      if Fnd > 0 then Fnd := N;
   end;
   if Fnd > 0 then
   begin
      curStr := Fnd;
      if curStr > numString-maxStr+1 then curStr := numString-maxStr+1;
   end;
end;

procedure cfgGotoString;
var S : String; N : Word;
begin
   oDnLn(2);
   oStrCtr('|U2-- |U1Enter string number to jump to |U5[|U41|U5-|U4'+St(numString)+'|U5] |U3');
   S := iReadString('',inNormal,chNumeric,'',3);
   if S = '' then Exit;
   n := strToInt(s);
   if (n = 0) or (n > numString) then Exit;
   curStr := n;
   if curStr > numString-maxStr+1 then curStr := numString-maxStr+1;
end;

procedure cfgStringEditor;
var Ch : Char;
    cmdStrEdit : array[1..6] of String;
begin
   cmdStrEdit[1] := '[ Previous';
   cmdStrEdit[2] := '] Next';
   cmdStrEdit[3] := '1-5 Edit string';
   cmdStrEdit[4] := '/ Search';
   cmdStrEdit[5] := '= Jump';
   cmdStrEdit[6] := 'Esc Quit';
   curStr := 1;
   cfgDone := False;
   sStr := '';
   logWrite('*Strings edited.');
   StringEdit := True;
   repeat
      oClrScr;
      cfgWriteStrings;
      oDnLn(1);
      cfgPrompt(cmdStrEdit,5);
      repeat
         Ch := UpCase(iReadKey);
      until (HangUp) or (Ch in ['1'..'5','[',']','/','=',#27]);
      if HangUp then Ch := #27;
      if Ch = #27 then oWrite('Quit') else oWriteChar(Ch);

      case Ch of
         #27 : cfgDone := True;
         '1'..'5' : cfgEditString(StrToInt(Ch));
         '/' : cfgSearchString;
         '=' : cfgGotoString;
         '[' : begin Dec(curStr,maxStr); if curStr < 1 then curStr := numString-maxStr+1; end;
         ']' : begin Inc(curStr,maxStr); if curStr > numString then curStr := 1; end;
      end;
   until (HangUp) or (cfgDone);
   oDnLn(2);
{  oSetCol(colInfo);
   oWrite('Save changes? ');
   if iYesNo(True) then fSaveStrings else fLoadStrings;}
   StringEdit := False;
end;

end.