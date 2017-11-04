program obv2iniq;

uses
   WinDos, Crt, Global, Misc, FastIO, StrProc, DateTime;

type
   tObvUserRec = record
      Username,
      Realname,
      PhoneNum,
      Address,
      Location,
      Password,
      Usernote  : String[35];
      BirthDate : String[8];
      Other1    : array[1..10] of Byte;
      SL        : Integer;
      DSL       : Integer;
      Other     : array[1..2389-(7*36+9+10+2+2)] of Byte;
   end;

var obvU : tobvUserRec;
    iniU : tUserRec;
    obvF : file of tobvUserRec;
    iniF : file of tUserRec;
    cfgF : file of tCfgRec;

    numU : Word;
    curU : Word;
    cfg  : tCfgRec;

begin
   ioInitFastIO;
   ioTextMode;
   ioClrScr;
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($0F);
   ioWriteLn('Obv2iniq v'+bbsVersion+'  (c)Copyright 1996, Mike Fricker');
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($07);
   ioWriteLn('Oblivion/2 --> Iniquity user file conversion utility');
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
      ioWriteLn('Please specify the full path to your Oblivion/2 user file USER.LST');
      ioWriteLn('when executing the program.');
      Halt(255);
   end;
   Assign(obvF,ParamStr(1));
   {$I-}
   Reset(obvF);
   {$I+}
   if ioResult <> 0 then
   begin
      Assign(obvF,ParamStr(1)+'\USER.LST');
      {$I-}
      Reset(obvF);
      {$I+}
      if ioResult <> 0 then
      begin
         ioWriteLn('Oblivion/2 user file USER.LST not found in the path specified.');
         Halt(255);
      end;
   end;
   numU := FileSize(obvF);
   curU := 0;
   ioWriteLn('USER.LST found in specified path ('+St(numU)+' users).');
   ioWriteLn('Renamed previous Iniquity user file to USERS.OLD.');
   Assign(iniF,cfg.pathData+fileUsers);
   {$I-}
   Rename(iniF,cfg.pathData+'USERS.OLD');
   {$I+}
   if ioResult <> 0 then ioWriteLn('Error obvaming old data file, continuing...');

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
   while not Eof(obvF) do
   begin
      ioWrite(St(Round(curU / numU * 100))+'%');
      ioGotoXY(35,ioWhereY);
      Read(obvF,obvU);
      if obvU.Username <> '' then
      begin
         Inc(curU);
         FillChar(iniU,SizeOf(iniU),0);
         with iniU do
         begin
            Number              := curU;
            UserName            := obvU.Username;
            RealName            := obvU.Realname;
            Password            := UpStr(obvU.Password);
            PhoneNum            := obvU.PhoneNum;
            Insert('(',PhoneNum,1);
            Insert(')',PhoneNum,5);
            Insert('-',PhoneNum,9);
            Birthdate           := obvU.BirthDate;
            Location            := obvU.Location;
            Address             := obvU.Address;
            UserNote            := obvU.UserNote;
            Sex                 := 'M'; {obvU.Sex;}
            SL                  := obvU.SL;
            DSL                 := obvU.DSL;
            BaudRate            := 14400;
            TotalCalls          := 0;
            curMsgArea          := 1;
            curFileArea         := 1;
            acFlag              := [acANSi,acHotKey,acYesNoBar,acPause,acQuote];
            Color               := cfg.DefaultCol;
            LastCall            := dtDateString;
            PageLength          := cfg.DefaultPageLen;
            EmailWaiting        := 0;
            Level               := 'B';
            timeToday           := 60;
            timePerDay          := 60;
            autoSigLns          := 0;
            FillChar(autoSig,SizeOf(autoSig),0);
            confMsg             := 1;
            confFile            := 1;

            FirstCall           := dtDateString;
            StartMenu           := cfg.StartMenu;
            fileScan            := '01/01/80';
            SysOpNote           := 'None';
            Posts               := 0;
            Email               := 0;
            Uploads             := 0;
            Downloads           := 0;
            UploadKb            := 0;
            DownloadKb          := 0;
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
            zipCode             := '0000-00000';
            voteYes             := 0;
            voteNo              := 0;
         end;
         Write(iniF,iniU);
      end else Dec(numU,1);
   end;
   ioWriteLn(St(curU div numU * 100)+'%');
   Close(obvF);
   Close(iniF);
   ioWriteLn('Conversion process complete.');
   ioWriteLn('Old Iniquity user file renamed to USERS.OLD.');
   ioWriteLn('');
   ioWriteLn('Note:  Users on record are now "Male".  Please alter female user''s sex');
   ioWriteLn('       manually with Iniquity''s user editor.');
end.
