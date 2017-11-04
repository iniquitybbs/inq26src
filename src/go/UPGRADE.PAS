program Upgrade;

uses
   Dos, Crt, Global, FastIO, Files, Strings, Misc;

var
   cfgF : file of tCfgRec;
   cfg  : tCfgRec;
   ch : Char;

begin
   TextMode(co80);
   ioInitFastIO;
   ioClrScr;
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($0F);
   ioWriteLn('iniqUpgrade v'+bbsVersion+'  (c)Copyright 1995, Mike Fricker');
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($07);
   ioWriteLn('Upgrades Iniquity v1.00a23 data files to v'+bbsVerLong+' compatibility');
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
   if ((cfg.nuvVotesYes <> 0) or (cfg.nuvVotesNo <> 0) or (cfg.nuvUserLevel <> #0)) and (not mParam('FORCE')) then
   begin
      ioWriteLn('This copy of Iniquity appears to be up to date.  An upgrade should not be');
      ioWriteLn('necessary.  If you wish to force an upgrade (a23 -> a25) then invoke this');
      ioWriteLn('program with the parameter "FORCE" ..');
      Halt(255);
   end;
   ioWriteLn('The following changes must be made for a successful upgrade from a23 to a25:');
   ioWriteLn('');
   ioWriteLn('  % All NEW a25 system configuration options must be configured.');
   ioWriteLn('  - Old EVENTS.DAT (event list) must be deleted.');
   ioWriteLn('  - Old FILEATCH.DAT (file attach list) must be deleted.');
   ioWriteLn('  - Any files currently attached to messages will be erased.');
   ioWriteLn('');
   ioWriteLn('This program can make these changes for you, automatically.');
   ioWrite('Do you wish to proceed with the upgrade? [y/n] ');
   repeat
      ch := upcase(ReadKey);
   until ch in [#27,'Y','N'];
   if ch = #27 then ch := 'N';
   if ch = 'N' then
   begin
      ioWriteLn('no');
      ioWriteLn('');
      ioWriteLn('Upgrade aborted.');
      Halt(255);
   end;
   ioWriteLn('yes');
   ioWriteLn('');
   ioWriteLn('New alpha 25 config options will be set to Iniquity defaults.  Check the');
   ioWriteLn('WHATSNEW.A25 history file for infomation on all new commands and options.');
   ioWriteLn('');
   ioWrite('Upgrading Iniquity .. please wait.');

   with cfg do
   begin
      soundRestrict          := True;
      inactLocal             := True;
      allowBlind             := True;
      nuvVotesYes            := 5;
      nuvVotesNo             := 3;
      nuvAccess              := '!s50';
      nuvVoteAccess          := 's50';
      nuvInitials            := True;
      nuvUserLevel           := 'B';
      nuvValidation          := True;
   end;

   Assign(cfgF,fileConfig);
   Rewrite(cfgF);
   Write(cfgF,cfg);
   Close(cfgF);

   fDeleteFile(cfg.pathData+fileAttach);
   fDeleteFile(cfg.pathData+fileEvent);
   fClearDir(cfg.pathAtch);

   ioWriteLn('');
   ioWriteLn('Upgrade successful.');
   ioWriteLn('');
   ioWriteLn('New configurable strings will be filled in with defaults upon loading');
   ioWriteLn('Iniquity 1.00 alpha 25.  You should copy the new NUV.ANS from the');
   ioWriteLn('original distribution package.');
end.