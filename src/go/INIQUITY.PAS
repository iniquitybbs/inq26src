{$D+,A+,O+,R-,S+,I+,Q-,V-,B-,X+,T-,P-}

(*
-$a. ------------------ .a$ ---------------------------- %$!, ----------------%
 `$�   .%$$^�$$aa.     .�$`        .        .a$a$$.      `�$%  $a$.        .
-.aaa$ $$$$'- $$$$$.- $aaa. -.a%$^"$$aa -- .$$$$$'- $$a. $aaa. `$,$ ----------%
;$$$$',a$a$  d$%$$$$$,'$$$$;$$$$$  $$$$$., $$%$$"  d$a$$ '$$$$; $$$   .a%$  $$a
:$$$$;$$$$%; Z$$$$$$$$;$$$$:$$$$$. $$$$^$,;$$&$$   Z$$$$,;$$$$.a$$$a..$$$   $$$
.$$$$ `$$$$.  $$$%$$$' $$$$.`$$$$  $$%$$$$ `$$$$.   $%$$$ $$$$""$$$" $$$$:  a$$
 `$$$a.$$%$   $$$$$$';a$$$`  `�$$aa$$$$&$': `$$$$a. $$$$'a$$$`.$$'$  $$$$;  $$$
%-----.------ $$$$'--------------- $$%$$' -- `�$$$$$%$�' ---- $$�$a. `"$&$$#$%$
dz      .   .:'�'     .        .   $$$$'     .        .       `�$$$$y.     `$$&
%--------- a`-----------.--------- $$�' -----.------------.---------------- $$$
   .      !a    . .    .      .   .:'   .  .                  .        .:.a$$$�
.      .  '$a,          .        a` .   'a          .   .             s` .  . .
      .    �$Aa         .       !a       a!      .    .         ..   %s      .s
   .         ��'     . .        '$$Aa.aA$$'        . .               `!$%a.a%#$
==============================================================================
   t h e    i n i q u i t y    b u l l e t i n    b o a r d    s y s t e m
==============================================================================
*)

{$UNDEF RELEASE}
{$DEFINE OVERLAY}

{$M 60000,0,400000}
{$IFDEF RELEASE} {$D-} {$ELSE} {$D+} {$ENDIF}
{$IFDEF DPMI} {$UNDEF OVERLAY} {$C FIXED PRELOAD PERMANENT} {$ENDIF}
{$IFDEF OS2} {$UNDEF OVERLAY} {$ENDIF}

{ Iniquity BBS (c)Copyright 1995-1996 Mike Fricker; All rights reserved }
program Iniquity;

uses
   Apply,        { New user application system                            }
   Archive,      { Archiver handling routines (ZIP / ARJ / UC2)           }
   Attach,       { Message file inclusion system                          }
   AutoMsg,      { AutoMessage Display / Creation Routines                }
   AutoSig,      { User auto-signiture system                             }
   BbsInit,      { BBS Initialization Process                             }
   BbsList,      { BBS Listing Module                                     }
   Callers,      { Call record accessing routines                         }
   ChatMode,     { User / SysOp Online Chatmode System                    }
   Comm,         { High Level Communication Routines                      }
   Conf,         { Conference system routines                             }
   Config,       { Configuration Operation Routines                       }
   Config1,      { System Configuration Module                            }
   Config2,      { Communication Setup Module                             }
   Config3,      { Online String Editing Module                           }
   Config4,      { Menu Editor Module                                     }
   Config5,      { Message Area Editor Module                             }
   Config6,      { Security Access Level Configuration System             }
   Config7,      { The Protocol Editor                                    }
   Config8,      { System User Editor                                     }
   Config9,      { File Area Editing Ssytem                               }
   Config10,     { Archiver editor                                        }
   Config11,     { Event editor                                           }
   Config12,     { Message and file conference editor                     }
   Config13,     { File editor                                            }
   Config14,     { Statistics editor                                      }
   Config15,     { BBS list editor                                        }
   Config16,     { Text library [*.TFL] editor                            }
   Config17,     { Infoform editor                                        }
   Crt,          { Standard TP7 Direct Screen Interface Unit              }
   DateTime,     { Date and time routines                                 }
   Detect,       { Emulation Detection Unit (ie ANSi, RIP, AVT)           }
   Doors,        { Door drop file creation and execution system           }
   Email,        { Electroic Private Mail System                          }
   Emulate,      { ANSI Color Graphics Emulation System                   }
   Errors,       { Critical DOS error messages                            }
   Events,       { System event handler                                   }
   FastIO,       { Enhanced Screen IO - Super FAST                        }
   FileArea,     { File section stuff...                                  }
   Files,        { File Initialization, Creation, and Handling Routines   }
   FileSort,     { File directory sorting system                          }
   FsEditor,     { Full Screen Message Editor                             }
   Global,       { Global Procedures, Functions, Variables, and Constants }
   HardAnsi,     { Hard-Coded Crunched ANSi Graphics (ie WFC Screen)      }
   History,      { History log file updation system                       }
   Infoform,     { Infoform management                                    }
   Input,        { High Level Input Routines                              }
   Iplx,         { Iniquity Programming Language - execution system       }
   Levels,       { User validating / updation system                      }
   Logon,        { BBS Logon System                                       }
   Logs,         { Logging System                                         }
   MciCodes,     { MCI Code Control and Replacement System                }
   MenuCmd,      { All Menu Command Procedures and Functions              }
   Menus,        { Menu Control Unit                                      }
   MicroDOS,     { Internal DOS Micro DOS-Emulator                        }
   Misc,         { Miscelleaneaus Peocedures and Functions                }
   MsgArea,      { Message Loading/Saving/Writing/Reading System          }
   Nodes,        { Multinode support and interaction routines             }
   Nuv,          { New user voting system                                 }
   Output,       { High Level Output Routines            } {$IFDEF OVERLAY}
   Overlay,      { Standard TP7 Overlay Control Unit             } {$ENDIF}
   QwkMail,      { QWK/REP offline mail processing system                 }
   Sauce,        { Sauce description loader [sauce by Tasmaniac <acid>]   }
   Screen,       { Screen Save / Restore Procedures                       }
   ShowFile,     { Text File Viewing System                               }
   StatBar,      { Status Bar Updation System                             }
   Stats,        { BBS statistics management                              }
   StrProc,      { String Handling Procedures and Functions               }
   Swap,         { Disk / EMS Memory Swapping System                      }
   Terminal,     { Terminal Mode Module                                   }
   Tetris,       { Iniquity's internal Tetris!                            }
   Transfer,     { File Transfer System                                   }
   Users,        { User record i/o                                        }
   Wait4Cal      { Wait-For-Call (WFC) Operations System                  }
{$IFDEF OS2}
  ,Os2Base
{$ENDIF};

  { WinDos;}       { Windows/DOS/DPMI disk/MSDOS interface                  }

{$IFDEF OVERLAY}
   {$O Apply   } {$O Archive } {$O Attach  } {$O AutoMsg } {$O AutoSig }
   {$O bbsInit } {$O bbsList } { O Callers } {$O ChatMode} { O Comm    }
   {$O Conf    } { O Config  } {$O Config1 } {$O Config2 } {$O Config3 }
   {$O Config4 } {$O Config5 } {$O Config6 } {$O Config7 } {$O Config8 }
   {$O Config9 } {$O Config10} {$O Config11} {$O Config12} {$O Config13}
   {$O Config14} {$O Config15} {$O Config16} {$O Config17} { O Crt     }
   { O DateTime} {$O Detect  } {$O Doors   } {$O Email   } { O Emulate }
   {$O Errors  } { O Events  } { O FastIO  } {$O FileArea} { O Files   }
   {$O FileSort} {$O FsEditor} { O Global  } {$O HardANSI} {$O History }
   {$O Infoform} { O Input   } {$O Iplx    } {$O Levels  } {$O Logon   }
   {$O Logs    } {$O MciCodes} {$O MenuCmd } {$O Menus   } {$O MicroDOS}
   { O Misc    } {$O MsgArea } { O Nodes   } {$O Nuv     } { O Output  }
   { O Overlay } {$O QwkMail } {$O Sauce   } { O Screen  } { O ShowFile}
   { O StatBar } {$O Stats   } { O StrProc } { O Swap    } {$O Terminal}
   {$O Tetris  } {$O Transfer} {$O Users   } {$O Wait4Cal} { O WinDos  }

{$ENDIF}

var
   I : Integer;
   S : String;
   L : LongInt;
   O : Boolean;
   D : tDateTimeRec;
   ExitSave : Pointer;

procedure bbsLoadConfiguration(var aCfg : tCfgRec);
var fCfg : file of tCfgRec; z : String;
begin
   S := '';
   z := ParamStr(0);
   while Pos('\',z) > 0 do
   begin
      S := S+Copy(z,1,Pos('\',z));
      Delete(z,1,Pos('\',z));
   end;
   S := S+fileConfig;
   Assign(fCfg,S);
   {$I-} Reset(fCfg); {$I+}
   if ioResult <> 0 then
   begin
      Assign(fCfg,fileConfig);
      {$I-} Reset(fCfg); {$I+}
      if ioResult <> 0 then
      begin
         WriteLn;
         WriteLn;
         WriteLn('The file "'+fileConfig+'" was not found in the directory which contains');
         WriteLn(bbsTitle+' or in the current directory.');
         WriteLn;
         WriteLn('This is the '+bbsTitle+' configuration file, and is REQUIRED to load the BBS.');
         WriteLn('Please either recreate this file using the '+bbsTitle+' initalization system,');
         WriteLn('or obtain it from the original archive');
         Halt(errFatal);
      end;
   end;
   {$I-} Read(fCfg,aCfg); {$I+}
   if ioResult <> 0 then
   begin
      WriteLn;
      WriteLn;
      WriteLn('The file "'+fileConfig+'" is incompatible with the current version');
      WriteLn('of '+bbsTitle);
      WriteLn;
      WriteLn('Please either recreate this file using the '+bbsTitle+' initalization system,');
      WriteLn('or obtain it from the original archive');
      Close(fCfg);
      Halt(errFatal);
   end;
   Close(fCfg);
   MultiNode := aCfg.MultiNode;  { check if bbs is multinode }
end;

procedure bbsErrorHandler; far;
var
   F : Text; z, y, x : Byte; S, em : String[80]; C : Char;
   so : array[1..2] of Word;
{$IFDEF OS2}
   sBuf: array[1..4000] of word;
   scrptr: pointer;
{$ENDIF}

 function HexW(W : Word) : string;
 const Digits : array[0..$F] of Char = '0123456789ABCDEF';
 begin
    HexW[0] := #4;
    HexW[1] := Digits[hi(W) shr 4];
    HexW[2] := Digits[hi(W) and $F];
    HexW[3] := Digits[lo(W) shr 4];
    HexW[4] := Digits[lo(W) and $F];
 end;
begin
   ExitProc := ExitSave;
   if (ErrorAddr <> nil) then
   begin
      z := 0;
      Assign(F,startdir+fileError);
      {$I-}
      Append(F);
      {$I+}
      if (ioResult <> 0) then
      begin
         {$I-}
         Rewrite(F);
         {$I+}
         z := ioresult;
         if z <> 0 then writeln('[error writing to ',startdir+fileError,']') else
         begin
            WriteLn(F,'%% '+bbsTitle+' '+bbsVersion+'; critical error log, created '+dtTimeStr12+', '+dtDateString);
            WriteLn(F,'================================================================================');
            WriteLn(F,'This file contains screen-shots of system crashes, along with the runtime error');
            WriteLn(F,'number.  Please report any unusual errors to the Iniquity staff, along with this');
            WriteLn(F,'error log if applicible.  You may delete this file at your discretion.  It is');
            WriteLn(F,'created for debugging purposes only.');
            WriteLn(F,'================================================================================');
         end;
      end;
      if z = 0 then
      begin
         WriteLn(F);
{$IFDEF OS2}
         vioGetBuf(scrptr,textbufsize,0);
         selToFlat(scrptr);
         move(scrptr^, sBuf, 4000);
{$ENDIF}
         for y := 0 to 24 do
         begin
            s := '';
            for x := 1 to 80 do
            begin
{$IFDEF OS2}
               c := char(lo(sBuf[(y*80)+x]));
{$ELSE}
               c := Chr(Mem[textvidseg:(160*(y)+2*(x))]);
{$ENDIF}
               if (c = #0) then c := #32;
               if ((x = (WhereX+1)) and (y = (WhereY+1))) then c := #240;
               if ((x <> 80) or ((x = 80) and (c <> #32))) then s := s + c;
            end;
            WriteLn(F,S);
         end;
      end;
      Move(erroraddr,so,4);
{$IFDEF OS2}
      em := errorMessage(ExitCode);
{$ELSE}
      if O then em := errorMessage(ExitCode) else em := 'Overlay error';
{$ENDIF}
      WriteLn(F,'�� runtime error '+St(ExitCode)+' ['+em+'] @ '+dtTimeStr12+
                ' ['+hexw(so[1])+':'+hexw(so[2])+'], ',
                dtDateString+'; [mem:'+stc(memAvail)+']');
      WriteLn(F,'================================================================================');
      Close(F);
      logWrite('xRuntime error '+St(ExitCode)+' ['+em+'] at '+dtTimeStr12+', '+dtDateString);
      if UserOn then logWrite('x'+User^.Username+' online when error occured');
      if not asDoor then cHangUp;
      ErrorLevel := errRuntime;
      write('[runtime error ',exitcode,' (',em,')');
      if z = 0 then writeln(' - check ',startdir+fileError,' for details]') else writeln(']');
      killTerminateBBS(false);
   end;
end;

procedure bbsInitOverlays;
var theCfg : tCfgRec; sBuf : LongInt;
begin
   o := false;
   bbsLoadConfiguration(theCfg);
   mWriteInit('initializing overlay file');
{$IFNDEF OVERLAY}
   {$IFDEF OS2} Write(' [OS/2]'); {$ELSE} Write(' [DPMI]'); {$ENDIF}
   mWriteInit('protected mode init ...');
   ovrInEMS := False;
{$ELSE}
   ovrFileMode := fmReadOnly+fmDenyWrite;
   ovrInit(fileOverlay);
   mWriteInit('checking overlay status');
   case ovrResult of
      ovrError       : S := 'Error loading overlay file';
      ovrNotFound    : S := bbsTitle+' overlay file not found: "'+fileOverlay+'"';
      ovrNoMemory    : S := 'Insufficient available memory to load overlay file';
      ovrIOError     : S := 'Overlay file i/o error';
   end;
procedure bbsInitOverlays;
var theCfg : tCfgRec; sBuf : LongInt;
procedure bbsInitOverlays;
var theCfg : tCfgRec; sBuf : LongInt;
begin
   o := false;
   bbsLoadConfiguration(theCfg);
   mWriteInit('initializing overlay file');
{$IFNDEF OVERLAY}
   {$IFDEF OS2} Write(' [OS/2]'); {$ELSE} Write(' [DPMI]'); {$ENDIF}
   mWriteInit('protected mode init ...');
   ovrInEMS := False;
{$ELSE}
   ovrFileMode := fmReadOnly+fmDenyWrite;
   ovrInit(fileOverlay);
   mWriteInit('checking overlay status');
   case ovrResult of
      ovrError       : S := 'Error loading overlay file';
      ovrNotFound    : S := bbsTitle+' overlay file not found: "'+fileOverlay+'"';
      ovrNoMemory    : S := 'Insufficient available memory to load overlay file';
      ovrIOError     : S := 'Overlay file i/o error';
   end;
procedure bbsInitOverlays;
var theCfg : tCfgRec; sBuf : LongInt;
begin
   o := false;
   bbsLoadConfiguration(theCfg);
   mWriteInit('initializing overlay file');
{$IFNDEF OVERLAY}
   {$IFDEF OS2} Write(' [OS/2]'); {$ELSE} Write(' [DPMI]'); {$ENDIF}
   mWriteInit('protected mode init ...');
   ovrInEMS := False;
{$ELSE}
   ovrFileMode := fmReadOnly+fmDenyWrite;
   ovrInit(fileOverlay);
   mWriteInit('checking overlay status');
   case ovrResult of
      ovrError       : S := 'Error loading overlay file';
      ovrNotFound    : S := bbsTitle+' overlay file not found: "'+fileOverlay+'"';
      ovrNoMemory    : S := 'Insufficient available memory to load overlay file';
      ovrIOError     : S := 'Overlay file i/o error';
   end;
      writeln('menu      enter the menu editor           modem     edit modem configuration');
      writeln('node %    launch specified node           nofx      disable vga effects');
      writeln('ovrbuf %  raise overlay buffer by % kb    pack      pack message areas and exit');
      writeln('quit      automatically exit after user   sort      sort file areas, then exit');
      writeln('string    edit configurable strings       share     disable fileshare detection');
      writeln('term      start in terminal (iniqterm)    user      load user editor');
      halt;
   end;

   Write(  'Loading Iniquity ... please wait');

   initNum := 0;
   fileMode := fmReadWrite+fmDenyNone;

   mWriteInit('---');
   mWriteInit('preparing system');
   CheckBreak := False;
   Randomize;
   OvrInEMS := False;

   mWriteInit('loading configuration');

   bbsInitOverlays;
   mWriteInit('initializing variables');

   if (not detShare) and (not mParam(paramShare)) then
   begin
      WriteLn;
      WriteLn(bbsTitle+' could not detect SHARE.EXE');
      WriteLn;
      WriteLn('SHARE.EXE is a TSR device driver included with MS-DOS and Windows 95.  This');
      WriteLn('driver must be loaded before using '+bbsTitle+'.  A good idea would be to');
      WriteLn('set up your autoexec.bat file to load this automatically at startup.');
procedure bbsInitOverlays;
var theCfg : tCfgRec; sBuf : LongInt;
begin
   o := false;
   bbsLoadConfiguration(theCfg);
   mWriteInit('initializing overlay file');
{$IFNDEF OVERLAY}
   {$IFDEF OS2} Write(' [OS/2]'); {$ELSE} Write(' [DPMI]'); {$ENDIF}
   mWriteInit('protected mode init ...');
   ovrInEMS := False;
{$ELSE}
   ovrFileMode := fmReadOnly+fmDenyWrite;
   ovrInit(fileOverlay);
   mWriteInit('checking overlay status');
   case ovrResult of
      ovrError       : S := 'Error loading overlay file';
      ovrNotFound    : S := bbsTitle+' overlay file not found: "'+fileOverlay+'"';
      ovrNoMemory    : S := 'Insufficient available memory to load overlay file';
      ovrIOError     : S := 'Overlay file i/o error';
   end;
   mWriteInit('checking for direct video');

   DirectVideo := Cfg^.DirectWrites;
   mWriteInit('checking for cga snow');
   CheckSnow   := Cfg^.SnowChecking;
   mWriteInit('checking vga effects');

   if (mParam(paramNoEffects)) or
      (not (vidType in [5..8])) or
      (oprType <> oprDOS)
      then Cfg^.VgaEffects := False;

   mWriteInit('loading sysop info');
   userReset;
   mWriteInit('updating logfiles');

   logWrite('-');
   mWriteInit('analyzing command line');
   logWrite('>'+bbsTitle+' version '+bbsVerLong+' loaded');
   mWriteInit('initialization complete');

{   ioInitFastIO;  hooplah}

   mClearScr(True);
   if cfg^.SupportTextFX then fxInitOnce;
   fxInit;

   initParameters;

   UserOn := False;

   if mParam(paramTerminalMode) then
   begin
      tmTerminalMode;
      if mParam(paramQuitAfter) then killTerminateBBS(true);
   end;

   S := mGetParam(paramOnlineBaud);
   if (not modemOff) and (S <> '') then
   begin
      L := strToInt(S);
      if (L >= 300) and (L <= 115200) then wfcOnline(L);
   end else
   if (s = '0') or (mParam(paramLocalLogon)) then wfcOnline(0);

   curStat := Cfg^.DefWFCstat;
   repeat
      fxResetConsole(false);
      if cfg^.SupportTextFX then fxInitOnce;
      wfcWaitForCall;
      nodeUpdate('User logging in ...');
      userPrelogonInit;
      sbReset;
      if Cfg^.StatOnDefault then
      begin
         Cfg^.StatBarOn := False;
         sbStatBar(True);
      end else Cfg^.StatBarOn := False;
      if not menuLaunch then
      begin
         logonInit;
         cPurgeInput;
         if (not ((Cfg^.SysOpAutoLogin) and (LocalIO) and (not HangUp))) and (Cfg^.MatrixLogin) then
         begin
            curMenu := 'MATRIX';
            menuInstall;
            NewMenuCmd := '';
            ExecFirst := False;
            while (not HangUp) and (not LoggedIn) do menuExec;
         end else logonSystem;
      end else
      begin
         userReset;
         detEmulation;
         fxInit;
         LoggedIn := True;
      end;
      if (LoggedIn) and (not HangUp) then
      begin
         oString(strInitBBS);
         userLogonInit;
         nodeUpdate('System initialization');
         logWrite(User^.Username+' ('+User^.Realname+') logged in');

         maFindAreaWithAccess;
         faFindAreaWithAccess;
         confLoad(True);
         confLoad(False);
         timeCheck := True;

         if not menuLaunch then
         begin
            curMenu := User^.StartMenu;
            if not fExists(Cfg^.pathMenu+curMenu+'.MNU') then curMenu := Cfg^.StartMenu;
         end;
         menuInstall;
         NewMenuCmd := '';
         I := 1;
         while (I <= numCmds) and (NewMenuCmd = '') do
         begin
            if (Cmd^[I].Keys = cmdFirst) and
               (acsOk(Cmd^[I].ACS)) then NewMenuCmd := cmdFirst;
            Inc(I,1);
         end;
         ExecFirst := NewMenuCmd = cmdFirst;

         nodeReset(True);
         nodeUpdate('User online');
         nodeProcess;

         oDnLn(1);
         while not Hangup do menuExec;

         nodeready := False;

         if TempSysOp then
         begin
            User^.SL := realSL;
            User^.DSL := realDSL;
            TempSysOp := False;
         end;
         if not asDoor then cHangUp;
procedure bbsInitOverlays;
var theCfg : tCfgRec; sBuf : LongInt;
begin
   o := false;
   bbsLoadConfiguration(theCfg);
   mWriteInit('initializing overlay file');
{$IFNDEF OVERLAY}
   {$IFDEF OS2} Write(' [OS/2]'); {$ELSE} Write(' [DPMI]'); {$ENDIF}
   mWriteInit('protected mode init ...');
   ovrInEMS := False;
{$ELSE}
   ovrFileMode := fmReadOnly+fmDenyWrite;
   ovrInit(fileOverlay);
   mWriteInit('checking overlay status');
   case ovrResult of
      ovrError       : S := 'Error loading overlay file';
      ovrNotFound    : S := bbsTitle+' overlay file not found: "'+fileOverlay+'"';
      ovrNoMemory    : S := 'Insufficient available memory to load overlay file';
      ovrIOError     : S := 'Overlay file i/o error';
   end;
