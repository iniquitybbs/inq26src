program Ren2iNiQ;

uses Dos, Crt,
     Global, Misc, FastIO, Strings;

type
  acrq='@'..'Z';                  { Access Restriction flags }
  mzscanr  = set of 1..250;              { Which message bases to scan }
  fzscanr  = set of 1..250;             { Which file bases to scan }
  mhireadr = array[1..250] of longint;   { Lastread pointers }
  colors   = array[FALSE..TRUE,0..9] of byte; { Color tables }
  uflags =
   (rlogon,                       { L - Limited to one call a day }
    rchat,                        { C - No SysOp paging }
    rvalidate,                    { V - Posts are unvalidated }
    ruserlist,                    { U - Can't list users }
    ramsg,                        { A - Can't post an auto message }
    rpostan,                      { * - Can't post anonymously }
    rpost,                        { P - Can't post }
    remail,                       { E - Can't send email }
    rvoting,                      { K - Can't use voting booth }
    rmsg,                         { M - Force email deletion }
    vt100,                        { Supports VT100 }
    hotkey,                       { hotkey input mode }
    avatar,                       { Supports Avatar }
    pause,                        { screen pausing }
    novice,                       { user requires novice help }
    ansi,                         { Supports ANSI }
    color,                        { Supports color }
    alert,                        { Alert SysOp upon login }
    smw,                          { Short message(s) waiting }
    nomail,                       { Mailbox is closed }
    fnodlratio,                   { 1 - No UL/DL ratio }
    fnopostratio,                 { 2 - No post/call ratio }
    fnocredits,                   { 3 - No credits checking }
    fnodeletion);                 { 4 - Protected from deletion }

  suflags =
    (lockedout,                   { if locked out }
    deleted,                      { if deleted }
    trapactivity,                 { if trapping users activity }
    trapseparate,                 { if trap to seperate TRAP file }
    chatauto,                     { if auto chat trapping }
    chatseparate,                 { if separate chat file to trap to }
    slogseparate,                 { if separate SysOp log }
    clsmsg,                       { if clear-screens }
    RIP,                          { if RIP graphics can be used }
    fseditor,                     { if Full Screen Editor }
    AutoDetect                    { Use auto-detected emulation }
  );

  tRenUserRec =
  record
    name:string[36];                  { system name      }
    realname:string[36];              { real name        }
    pw:string[20];                    { password         }
    ph:string[12];                    { phone #          }
    bday:string[8];                   { birthdate        }
    firston:string[8];                { first on date    }
    laston:string[8];                 { last on date     }
    street:string[30];                { street address   }
    citystate:string[30];             { city, state      }
    zipcode:string[10];               { zipcode          }
    usrdefstr:array[1..3] of string[35]; { type of computer }
                                      { occupation       }
                                      { BBS reference    }
    note:string[35];                  { SysOp note       }
    userstartmenu:string[8];          { menu to start at }
    lockedfile:string[8];             { print lockout msg}
    flags:set of uflags;              { flags            }
    sflags:set of suflags;            { status flags     }
    ar:set of acrq;                   { AR flags         }
    vote:array[1..25] of byte;        { voting data      }

    sex:char;                         { gender           }
    ttimeon,                          { total time on    }
    uk,                               { UL k             }
    dk:longint;                       { DL k             }
    tltoday,                          { # min left today }
    forusr,                           { forward mail to  }
    junkfp:integer;               { # of file points }

    uploads,downloads,                { # of ULs/# of DLs}
    loggedon,                         { # times on       }
    msgpost,                          { # message posts  }
    emailsent,                        { # email sent     }
    feedback,                         { # feedback sent  }
    timebank,                         { # mins in bank   }
    timebankadd,                      { # added today    }
    dlktoday,                         { # kbytes dl today}
    dltoday:word;                     { # files dl today }

    waiting,                          { mail waiting     }
    linelen,                          { line length      }
    pagelen,                          { page length      }
    ontoday,                          { # times on today }
    illegal,                          { # illegal logons }
    barf,
    lastmbase,                        { # last msg base  }
    lastfbase,                        { # last file base }
    sl,dsl:byte;                      { SL / DSL         }

    mhiread:mhireadr;                 { Message last read date ptrs}
    mzscan:mzscanr;                   { Which message bases to scan}
    fzscan:fzscanr;                   { Which file bases to scan}

    cols:colors;                      { user colors }

    garbage:byte;
    timebankwith:word;                { amount of time withdrawn today}
    passwordchanged:word;             { last day password changed }
    defarctype:byte;                  { default QWK archive type }
    lastconf:char;                    { last conference they were in }
    lastqwk:longint;                  { date/time of last qwk packet }
    getownqwk,                        { add own messages to qwk packet? }
    scanfilesqwk,                     { scan file bases for qwk packets? }
    privateqwk:boolean;               { get private mail in qwk packets? }

    credit,                           { Amount of credit a user has }
    debit:longint;                    { Amount of debit a user has }
    expiration:longint;               { Expiration date of this user }
    expireto:char;                    { Subscription level to expire to }
    ColorScheme:byte;                 { User's color scheme # }
    TeleConfEcho,                     { echo Teleconf lines? }
    TeleConfInt:boolean;              { interrupt during typing? }
  end;

var renU : tRenUserRec;
    iniU : tUserRec;
    renF : file of tRenUserRec;
    iniF : file of tUserRec;
    cfgF : file of tCfgRec;

    numU : Word;
    curU : Word;
    cfg  : tCfgRec;

begin
   TextMode(co80);
   ioInitFastIO;
   ioClrScr;
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($0F);
   ioWriteLn('Ren2iniq v'+bbsVersion+'  (c)Copyright 1995, Mike Fricker');
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($07);
   ioWriteLn('Renegade to Iniquity user file conversion utility');
   ioTextAttr($08);
   ioWrite(sRepeat('Ä',80));
   ioTextAttr($07);
   Assign(cfgF,fileConfig);
   {$I-}
   Reset(cfgF);
   {$I+}
   if ioResult <> 0 then
   begin
      ioWriteLn(fileConfig+' not found in current directory.');
      ioWriteLn('Please change to your Iniquity directory before executing this program.');
      Halt(255);
   end;
   Read(cfgF,cfg);
   Close(cfgF);

   if ParamCount < 1 then
   begin
      ioWriteLn('Please specify the full path to your renegade user file USERS.DAT');
      ioWriteLn('when executing the program.');
      Halt(255);
   end;
   Assign(renF,ParamStr(1));
   {$I-}
   Reset(renF);
   {$I+}
   if ioResult <> 0 then
   begin
      Assign(renF,ParamStr(1)+'\USERS.DAT');
      {$I-}
      Reset(renF);
      {$I+}
      if ioResult <> 0 then
      begin
         ioWriteLn('Renegade user file USERS.DAT not found in the path specified.');
         Halt(255);
      end;
   end;
   numU := FileSize(renF);
   curU := 0;
   ioWriteLn('USERS.DAT found in specified path ('+St(numU)+' users).');
   ioWriteLn('Renaming previous Iniquity user file to USERS.OLD.');
   Assign(iniF,cfg.pathData+fileUsers);
   {$I-}
   Rename(iniF,cfg.pathData+'USERS.OLD');
   {$I+}
   if ioResult <> 0 then ioWriteLn('Error renaming old data file, continuing...');

   Assign(iniF,cfg.pathData+fileUsers);
   {$I-}
   Rewrite(iniF);
   {$I+}
   if ioResult <> 0 then
   begin
      ioWriteLn('Unable to create Iniquity user file '+cfg.pathData+fileUsers);
      Halt(255);
   end;
   ioWriteLn('Creating '+cfg.pathData+fileUsers+'...');
   ioWrite('Building Iniquity user data file: ');
   while not Eof(renF) do
   begin
      ioWrite(St(Round(curU / numU * 100))+'%');
      ioGotoXY(35,ioWhereY);
      Read(renF,renU);
      if renU.Name <> '' then
      begin
         Inc(curU);
         FillChar(iniU,SizeOf(iniU),0);
         with iniU do
         begin
            Number              := curU;
            UserName            := strMixed(renU.Name);
            RealName            := strMixed(renU.RealName);
            Password            := renU.Pw;
            PhoneNum            := renU.Ph;
            Insert('(',PhoneNum,1);
            PhoneNum[5] := ')';
            Birthdate           := renU.bDay;
            Location            := renU.CityState;
            Address             := renU.Street;
            UserNote            := 'Normal User Access';
            Sex                 := renU.Sex;
            SL                  := renU.SL;
            DSL                 := renU.DSL;
            BaudRate            := 14400;
            TotalCalls          := renU.LoggedOn;
            curMsgArea          := 1;
            curFileArea         := 1;
            acFlag              := [acANSi,acHotKey,acYesNoBar,acQuote,acPause];
            Color               := cfg.DefaultCol;
            LastCall            := renU.LastOn;
            PageLength          := cfg.DefaultPageLen;
            EmailWaiting        := 0;
            Level               := 'B';
            timeToday           := 60;
            timePerDay          := 60;
            autoSigLns          := 0;
            FillChar(autoSig,SizeOf(autoSig),0);
            confMsg             := 1;
            confFile            := 1;

            FirstCall           := renU.FirstOn;
            StartMenu           := cfg.StartMenu;
            fileScan            := '01/01/80';
            SysOpNote           := 'None';
            Posts               := renU.msgPost;
            Email               := renU.EmailSent;
            Uploads             := renU.Uploads;
            Downloads           := renU.Downloads;
            UploadKb            := renU.uk;
            DownloadKb          := renU.dk;
            CallsToday          := 0;
            Flag                := [];
            filePts             := 0;
            postCall            := 0;
            limitDL             := 0;
            limitDLkb           := 0;
            todayDL             := 0;
            todayDLkb           := 0;

            lastQwkDate         := 0;
            uldlRatio           := 0;
            kbRatio             := 0;
            textLib             := 1;
            zipCode             := renU.zipCode;
            voteYes             := 0;
            voteNo              := 0;
         end;
         Write(iniF,iniU);
      end else Dec(numU,1);
   end;
   ioWriteLn(St(curU div numU * 100)+'%');
   Close(renF);
   Close(iniF);
   ioWriteLn('Conversion process complete.');
   ioWriteLn('Old Iniquity user file renamed to USERS.OLD.');
end.