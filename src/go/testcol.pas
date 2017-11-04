
type
   tACString = String[20];

   tStrings = array[1..maxString] of String[255];
   tStrIdx  = array[1..maxString] of Word;

   tInFlag = (               { Input flags for "dReadString"                }
      inNormal,              { No case conversion is performed.             }
      inCapital,             { First letter capitallized.                   }
      inUpper,               { All characters are converted to upper case   }
      inLower,               { All characters are converted to lower case   }
      inMixed,               { Mixed case. AKA: word Auto-Capitalization    }
      inWeird,               { All vowels are lowered (ie. MiKe FRiCKeR)    }
      inWarped,              { All constants are lowered (ie. mIkE frIckEr) }
      inCool,                { Only "I"s are lowered (ie. FiEND)            }
      inHandle);             { reserved for alias format                    }

   tInChar = set of Char;

   { node configuration structure - node??.dat, single record }
   tModemRec = record
      ComDevice     : Byte;            { 0/none 1/uart 2/int14 3=fosl 4/digi }
      ComPort       : Byte;            { device comport # }
      BaudRate      : LongInt;         { device baud rate }
      Parity        : Char;            { parity (n/e/o) }
      StopBits      : Byte;            { stop bits, usually 1 }
      DataBits      : Byte;            { data bits, usually 8 }
      RecvBuff      : Word;            { receive buffer size }
      SendBuff      : Word;            { transmit buffer size }
      LockedPort    : Boolean;         { locked port? }
      MultiRing     : Boolean;         { use select-ring detection }
      irqNumber     : Byte;            { com irq }
      baseAddr      : String[4];       { uart base address }

      sInit1        : String[45];
      sInit2        : String[45];
      sInit3        : String[45];
      sExitStr      : String[45];
      sAnswer       : String[45];
      sHangup       : String[45];
      sOffhook      : String[45];
      sDialPrefix   : String[45];

      rError        : String[45];
      rNoCarrier    : String[45];
      rOK           : String[45];
      rRing         : String[45];
      rBusy         : String[45];
      rNoDialTone   : String[45];

      c300          : String[45];
      c1200         : String[45];
      c2400         : String[45];
      c4800         : String[45];
      c7200         : String[45];
      c9600         : String[45];
      c14400        : String[45];
      c16800        : String[45];
      c19200        : String[45];
      c21600        : String[45];
      c24000        : String[45];
      c26400        : String[45];
      c28800        : String[45];
      c31200        : String[45];
      c33600        : String[45];
      c38400        : String[45];
      c57600        : String[45];
      c64000        : String[45];
      c115200       : String[45];

      Reserved      : array[1..1024] of Byte;
   end;

   tColorRec = record
      Fore  : Byte;
      Back  : Byte;
      Blink : Boolean;
   end;

   tColor = array[0..maxColor] of tColorRec;

   tNetAddressRec = record
      Zone          : Word;
      Net           : Word;
      Node          : Word;
      Point         : Word;
   end;

   tMacros = array[1..10] of String[255];

   { main bbs configuration structure - iniquity.dat, single record }
   tCfgRec = record
      bbsName          : String[40];   { name of bbs                         }
      bbsPhone         : String[13];   { bbs phone number "(xxx)xxx-xxxx"    }
      SysOpAlias       : String[36];   { sysop's handle                      }
      SysOpName        : String[36];   { sysop's real name                   }
      SystemPW         : String[20];   { sysop access password               }
      acsSysOp         : tACString;    { bbs sysop acs                       }
      acsCoSysOp       : tACString;    { bbs co-sysop acs                    }
      DirectWrites     : Boolean;      { use direct video writes?            }
      SnowChecking     : Boolean;      { check for cga snow?                 }
      OverlayToEMS     : Boolean;      { load overlays to ems if possible?   }
      RealNameSystem   : Boolean;      { use only real names on this bbs?    }
      ShowPwLocal      : Boolean;      { display password input locally?     }

      StatOnDefault    : Boolean;      { status bar on when user logs in?    }
      StatBarOn        : Boolean;      { is the status bar currently on?     }
      StatType         : Byte;         { 1 (sbBot) = bottom, 2 (sbTop) = top }
      StatBar          : Byte;         { current sb display (1-maxStatBar)   }
      StatLo           : Byte;         { status bar low color attribute      }
      StatTxt          : Byte;         { status bar normal color attrib      }
      StatHi           : Byte;         { status bar bright color attrib      }

      DefaultCol       : tColor;       { default bbs generic colors          }

      Address          : array[1..maxAddress] of tNetAddressRec;
                                       { ^^ bbs net addresses                }
      ESCtoExit        : Boolean;      { allow wfc termination w/ escape?    }
      OffhookLocal     : Boolean;      { offhook modem w/ local login?       }
      VgaEffects       : Boolean;      { use vga effects? soon to be gone..  }
      ScreenSaver      : Byte;         { scrn saver (1=none,2=blank,3=morph) }
      BlankSeconds     : Word;         { # secs before initiating scrn saver }
      DefWFCstat       : Byte;         { default wfc stats display (1-8)     }

      pathData         : String[40];   { path to iniquity's data files       }
      pathText         : String[40];   { path to text/infoform files         }
      pathMenu         : String[40];   { path to menu files                  }
      pathMsgs         : String[40];   { path to message area data files     }
      pathSwap         : String[40];   { path to swapfile directory          }
      pathDoor         : String[40];   { path to door *.bat & drop files     }
      pathProt         : String[40];   { path to external protocols          }
      pathTemp         : String[40];   { path to temporary work directory    }
      pathDnld         : String[40];   { download directory - future use     }
      pathLogs         : String[40];   { path to log file directory          }

      NoBBSlogging     : Boolean;      { disable all bbs logging?            }
      LogLineChat      : Boolean;      { log line chat mode text & users?    }
      LogSplitChat     : Boolean;      { log split-screen chat text/users?   }
      LogMicroDOS      : Boolean;      { log microdos activity?              }

      SwapInShell      : Boolean;      { swap out memory when shelling?      }
      SwapToEMS        : Boolean;      { use ems for swapping if available?  }
      ProtocolSwap     : Boolean;      { swap before executing protocols?    }

      BbsAccessPw      : String[20];   { pw needed to login to bbs (unused)  }
      NoBaudPW         : String[20];   { pw needed to login w/banned baud    }
      SysOpAutoLogin   : Boolean;      { auto-login as user #1 if local?     }
      MatrixLogin      : Boolean;      { use matrix.mnu as a prelogon menu?  }
      AskApply         : Boolean;      { offer unknown users chance to apply?}
      TimeLimitPerCall : Boolean;      { is time limit per/call? or per/day  }
      acsSystemPWLogin : tACString;    { acs to force user to enter sysop pw }
      CallsBirth       : Byte;         { # of calls before birthdate check   }
      CallsPhone       : Byte;         { # of calls before phone # check     }
      LoginTrys        : Byte;         { max login attempts before booting   }

      Origin           : array[1..maxOrigin] of String[75];
                                       { ^^ echo/netmail origin lines        }
      NoChatPW         : String[20];   { pw needed to page sysop w/not avail }
      ChatPageNoise    : Boolean;      { use chat pager noise at all?        }
      maxPageTimes     : Byte;         { maximum page attempts p/call        }
      maxPageBeeps     : Byte;         { number of times to beep when paging }

      PwEchoChar       : Char;         { password echo character             }
      RemovePause      : Boolean;      { backspace over pause/cont? prompts? }
      AddLocalCalls    : Boolean;      { record local calls to bbs stats?    }
      numLastCalls     : Byte;         { # of calls to show in last callers  }

      acsPostEmail     : tACString;    { acs required to post email          }
      acsAnonymous     : tACString;    { acs needed to post anonymous msgs   }
      acsAnonAutoMsg   : tACString;    { acs needed to post an anon automsg  }
      acsUploadMessage : tACString;    { acs required to upload a msg        }
      acsAutoSigUse    : tACString;    { acs required to use autosigs        }
      AbortMandOk      : Boolean;      { allow quit reading mandatory msgs?  }
      AskPrivateMsg    : Boolean;      { prompt private msg when posting?    }
      AskPrivateReply  : Boolean;      { prompt private msg when replying?   }
      AskPostInArea    : Boolean;      { ask post in msgarea when reading?   }
      AskUploadReply   : Boolean;      { ask upload message when replying?   }
      AskUploadEmail   : Boolean;      { ask upload message in email?        }
      AskKillMsg       : Boolean;      { ask delete email msg after reply?   }
      AskKillAllMsg    : Boolean;      { ask delete all email after read?    }

      NewUserPW        : String[20];   { new user password                   }
      AliasFormat      : Byte;         { new user alias format type (1-8)    }
      DefaultPageLen   : Byte;         { default page length for new users   }
      NewExpert        : Boolean;      { default new user expert mode?       }
      NewYesNoBars     : Boolean;      { default new user yes/no bars?       }
      NewHotKeys       : Boolean;      { default new user hot keys?          }
      NewAskExpert     : Boolean;      { ask new user expert mode?           }
      NewAskYesNoBars  : Boolean;      { ask new user yes/no bars?           }
      NewAskHotKeys    : Boolean;      { ask new user hot keys?              }
      NewAskPageLen    : Boolean;      { ask new user page length?           }
      StartMenu        : String[8];    { default startup menu for new users  }

      Macro            : tMacros;      { bbs function key macros             }

      pathArch         : String[40];   { path to archiver programs           }
      ArchiverSwap     : Boolean;      { swap before executing archivers?    }
      NewPause         : Boolean;      { default new user screen pausing?    }
      NewQuote         : Boolean;      { default new user autoquote?         }
      NewAskPause      : Boolean;      { ask new user screen pausing?        }
      NewAskQuote      : Boolean;      { ask new user autoquote?             }
      AskAutoQuote     : Boolean;      { ask autoquote when replying?        }
      DefaultQuoteNum  : Boolean;      { use default quote #s w/no aquote?   }
      MaxQuoteLines    : Byte;         { # of lines to autoquote from msg    }

      iniqAsDoor       : Boolean;      { run iniquity as a door?             }
      pathAtch         : String[40];   { path to file attach directory       }
      acsAttachPublic  : tACString;    { acs needed to attach a file public  }
      acsAttachEmail   : tACString;    { acs req to attach a file in email   }
      confIgnoreMsg    : Boolean;      { ignore msg conf in mandatory scan?  }
      compMsgAreas     : Boolean;      { compress message listing area #s    }
      compFileAreas    : Boolean;      { compress file listing area #s       }
      RestoreChatTime  : Boolean;      { restore users time elapsed in chat? }
      kbPerFilePoint   : Word;         { 1 file point = ?? kb                }
      useFilePoints    : Boolean;      { use file point system on bbs?       }
      importDescs      : Boolean;      { import file descriptons from archs? }
      useDLlimit       : Boolean;      { use daily download limits?          }
      useDLkbLimit     : Boolean;      { use daily download-kb limits?       }
      bbsLocation      : String[40];   { bbs location (city, state/prov)     }
      qwkFilename      : String[8];    { qwk filename prefix                 }
      qwkWelcome       : String[12];   { qwk welcome textfile (in text dir)  }
      qwkNews          : String[12];   { qwk news textfile (in text dir)     }
      qwkGoodbye       : String[12];   { qwk goodbye textfile (in text dir)  }
      qwkLocalPath     : String[40];   { local qwk download path             }
      qwkIgnoreTime    : Boolean;      { ignore time remaining to xfer qwk?  }
      qwkStripSigs     : Boolean;      { strip autosigs when exporting msgs? }
      noDescLine       : String[50];   { "no file description" string        }
      waitConnect      : Word;         { # secs to wait for modem to answer  }
      modemReInit      : Word;         { # secs before re-initializing modem }
      lightChar        : Char;         { wavefile [lit] light character      }
      lightCharOk      : Char;         { light "ok" character                }
      lightCharFail    : Char;         { light "error" character             }
      virusScan        : String[50];   { virus scanner command               }
      virusOk          : Byte;         { scanner "ok" errorlevel             }
      maxFileAge       : Byte;         { oldest file in years to allow pass  }
      strictAge        : Boolean;      { use "strict" age file tester?       }
      delFile          : String[12];   { file list (data dir) to remove      }
      addFile          : String[12];   { file list (data dir) to add         }
      comFile          : String[12];   { file comment (data dir) to apply    }
      extMaint         : Boolean;      { external maintenence when testing?  }
      ulSearch         : Byte;         { upload search type (1-4)            }
      autoValidate     : Boolean;      { auto-validate uploaded files        }
      filePtsPer       : Word;         { file point return % w/uploads       }
      useUlDlratio     : Boolean;      { use upload/download ratio?          }
      useKbRatio       : Boolean;      { use upload/download-kb ratio?       }

      fileDesc1        : String[13];   { primary file description filename   }
      fileDesc2        : String[13];   { secondary file description name     }
      useTextLibs      : Boolean;      { use textfile libraries?             }
      pathLibs         : String[40];   { path to textfile libraries *.tfl    }
      echomailLev      : Byte;         { posted echomail exit errorlevel     }

      newConfig        : Boolean;      { use newuser configuration screen?   }
      newVerify        : Boolean;      { prompt newuser to proceed w/app?    }

      pmtYes           : String[30];   { default "(Y/n)" prompt              }
      pmtNo            : String[30];   { default "(y/N)" prompt              }
      pmtYesWord       : String[20];   { default "Yes" string                }
      pmtNoWord        : String[20];   { default "No" string                 }
      pmtYesBar        : String[30];   { default "[yes] no " bar prompt      }
      pmtNoBar         : String[30];   { default " yes [no]" bar prompt      }

      descWrap         : Boolean;      { wrap +1page descs to multi-page?    }
      chatStart        : String[5];    { chat avail start time (hh:mm)       }
      chatEnd          : String[5];    { chat avail end time (hh:mm)         }
      chatOverAcs      : tACString;    { acs needed to override availability }
      advFileBar       : Boolean;      { advance file listing bar w/ flag    }
      inactTime        : Boolean;      { use inactivity timeout?             }
      inactInChat      : Boolean;      { use inactivity timeout in chatmode? }
      inactSeconds     : Word;         { inactivity timeout seconds          }
      inactWarning     : Word;         { seconds before warning inact user   }
      ansiString       : String[75];   { "ansi codes detected" quote string  }
      pageAskEmail     : Boolean;      { ask leave email to sysop w/no page  }
      soundRestrict    : Boolean;      { restrict local sound to avail hours }
      inactLocal       : Boolean;      { inactivity timeout w/ local login?  }
      allowBlind       : Boolean;      { allow blind file uploads?           }
      nuvVotesYes      : Byte;         { nuv votes required to validate      }
      nuvVotesNo       : Byte;         { nuv votes required to delete        }
      nuvAccess        : tACString;    { acs for users to be voted on        }
      nuvVoteAccess    : tACString;    { acs needed to vote                  }
      nuvInitials      : Boolean;      { display initials beside comments?   }
      nuvUserLevel     : Char;         { nuv validated user level            }
      nuvValidation    : Boolean;      { use new user voting on bbs?         }

      MultiNode        : Boolean;      { is this a multinode bbs?            }
      pathIPLx         : String[40];   { path to ipl executables *.ipx       }
      askXferHangup    : Boolean;      { prompt for 'autologout after xfer'? }
      xferAutoHangup   : Byte;         { # of secs to wait before autohangup }
      ifNoAnsi         : Byte;         { no ansi? 1=hangup/2=ask/3=continue  }
      minBaud          : LongInt;      { minimum allowed connection baudrate }
      newUserLogin     : Boolean;      { auto-login new users from matrix?   }
      SysopPwCheck     : Boolean;      { check sysop pw on *? command use?   }
      SupportRIP       : Boolean;      { support remote imaging protocol     }
      SupportTextFX    : Boolean;      { allow textfx extended emulation?    }
      tfxFontTweaking  : Boolean;      { tweak textmode fonts to 8bit planar }
      tfxResetOnClear  : Boolean;      { reset console on non-TFX clear code }
      tfxFullReset     : Boolean;      { full video mode reset required? }

      Reserved         : array[1..3953] of Byte;
                                       { reserved space for future variables }
   end;

   tUserACflag = (
      acAnsi,
      acAvatar,
      acRip,
      acYesNoBar,
      acDeleted,
      acExpert,
      acHotKey,
      acPause,
      acQuote
   );

   tScanRec = record
      scnMsg : Boolean;
      ptrMsg : LongInt;
   end;

   tAutoSig = array[1..maxSigLines] of String[80];

   tUserFlags = set of 'A'..'Z';

   tUserRec = record
      Number             : Integer;
      UserName           : String[36];
      RealName           : String[36];
      Password           : String[20];
      PhoneNum           : String[13];
      BirthDate          : String[8];
      Location           : String[40];
      Address            : String[36];
      UserNote           : String[40];
      Sex                : Char;
      SL                 : Byte;
      DSL                : Byte;
      BaudRate           : LongInt;
      TotalCalls         : Word;
      curMsgArea         : Word;
      curFileArea        : Word;
      acFlag             : set of tUserACflag;
      Color              : tColor;
      LastCall           : String[8];
      PageLength         : Word;
      EmailWaiting       : Word;
      Level              : Char;
      timeToday          : Word;
      timePerDay         : Word;
      AutoSigLns         : Byte;
      AutoSig            : tAutoSig;
      confMsg            : Byte;
      confFile           : Byte;
      FirstCall          : String[8];
      StartMenu          : String[8];
      fileScan           : String[8];
      SysOpNote          : String[40];
      Posts              : Word;
      Email              : Word;
      oldUploads         : Word;
      oldDownloads       : Word;
      oldUploadKb        : Word;
      oldDownloadKb      : Word;
      CallsToday         : Word;
      Flag               : tUserFlags;
      filePts            : Word;
      postCall           : Word;
      limitDL            : Word;
      limitDLkb          : Word;
      todayDL            : Word;
      todayDLkb          : Word;
      lastQwkDate        : LongInt;
      uldlRatio          : Word;
      kbRatio            : Word;
      textLib            : Byte;
      zipCode            : String[10];
      voteYes            : Byte;
      voteNo             : Byte;
      Uploads            : LongInt;
      Downloads          : LongInt;
      UploadKb           : LongInt;
      DownloadKb         : LongInt;

      Reserved           : array[1..364] of Byte;
   end;

   tMenuRec = record
      mType         : Byte;
      MenuName      : String[255];
      PromptName    : String[60];
      HelpFile      : String[8];
      Prompt        : String[255];
      Acs           : tACString;
      Password      : String[20];
      Fallback      : String[8];
      Expert        : Byte;
      GenColumns    : Byte;
      HotKey        : Byte;
      ClearBefore   : Boolean;
      CenterTtl     : Boolean;
      ShowPrompt    : Boolean;
      PauseBefore   : Boolean;
      GlobalUse     : Boolean;
      InputUp       : Boolean;
      Reserved      : array[1..100] of Byte;
   end;

   tCommandRec = record
      Desc      : String[35];
      Help      : String[70];
      Keys      : String[14];
      Acs       : tACString;
      Command   : String[2];
      Param     : String[70];
      Hidden    : Boolean;
   end;

   tCommands = array[1..maxMenuCmd] of tCommandRec;

   tMsgStatusFlag =
     (msgDeleted,
      msgSent,
      msgAnonymous,
      msgEchoMail,
      msgPrivate,
      msgForwarded);

   tNetAttribFlag =
     (nPrivate,
      nCrash,
      nReceived,
      nSent,
      nFileAttached,
      nInTransit,
      nOrphan,
      nKillSent,
      nLocal,
      nHold,
      nUnused,
      nFileRequest,
      nReturnReceiptRequest,
      nIsReturnReceipt,
      nAuditRequest,
      nFileUpdateRequest);

   tMsgInfoRec = record
      UserNum       : Word;
      Alias         : String[36];
      Realname      : String[36];
      Name          : String[36];
      UserNote      : String[40];
      Address       : tNetAddressRec;
  end;

   pMsgHeaderRec = ^tMsgHeaderRec;
   tMsgHeaderRec = record
      FromInfo      : tMsgInfoRec;
      ToInfo        : tMsgInfoRec;
      Pos           : LongInt;
      Size          : Word;
      Date          : LongInt;
      Status        : set of tMsgStatusFlag;
      Replies       : Word;
      Subject       : String[40];
      NetFlag       : set of tNetAttribFlag;
      SigPos        : Word;
      incFile       : Word;
      msgTag        : Word;
      Reserved      : array[1..54] of Byte;
   end;

   tMsgAreaFlag =
     (maUnhidden,
      maRealName,
      maPrivate,
      maMandatory,
      maAnonymous);

   tMsgAreaRec = record
      Name          : String[40];
      Filename      : String[8];
      MsgPath       : String[40];
      Sponsor       : String[36];
      Acs           : tACString;
      PostAcs       : tACString;
      MaxMsgs       : Word;
      Msgs          : Word;
      Password      : String[20];
      Flag          : set of tMsgAreaFlag;
      AreaType      : Byte;
      Origin        : Byte;
      Address       : Byte;
      qwkName       : String[16];
      Reserved      : array[1..83] of Byte;
   end;

   pMessage = ^tMessage;
   tMessage = array[1..maxMsgLines] of String[80];

   tBBSlistRec = record
      Name       : String[40];
      SysOp      : String[36];
      Phone      : String[13];
      Baud       : LongInt;
      Software   : String[12];
      Storage    : String[20];
      Info       : String[75];
      WhoAdded   : String[36];
   end;

   tMenuItemRec = record
      Txt    : String;
      HiCol  : tColorRec;
      LoCol  : tColorRec;
      X, Y   : Byte;
   end;

   tLevelRec = record
      Desc       : String[40];
      SL         : Byte;
      DSL        : Byte;
      timeLimit  : Word;
      filePts    : Word;
      PostCall   : Word;
      limitDL    : Word;
      limitDLkb  : Word;
      UserNote   : String[40];
      uldlRatio  : Word;
      kbRatio    : Word;
      Reserved   : array[1..196] of Byte;
   end;

   tLevels = array['A'..'Z'] of tLevelRec;

   tProtFlag = (
      protActive,
      protBatch,
      protBiDir);

   tProtFlagSet = set of tProtFlag;

   { protocol description structure - protocol.dat, 26 records total }
   tProtRec = record
      Desc     : String[36];           { name of this protocol on list       }
      Flag     : tProtFlagSet;         { protocol flags (see above)          }
      Key      : Char;                 { menu key to select this protocol    }
      Acs      : tACString;            { access required to use this         }
      Log      : String[25];           { external- log filename              }
      cmdUL    : String[78];           { external- receive command           }
      cmdDL    : String[78];           { external- transmit command          }
      cmdEnv   : String[60];           { environment variable                }
      codeUL   : array[1..6] of String[6]; { ext- receive log result codes   }
      codeDL   : array[1..6] of String[6]; { ext- transmit log result codes  }
      codeIs   : Byte;                 { external- what result means         }
      listDL   : String[25];           { external- batch list                }
      posFile  : Word;                 { external- log file filename column  }
      posStat  : Word;                 { external- log file status column    }
      ptype    : Byte;                 { protocol type                       }
      Reserved : array[1..49] of Byte; { reserved space                      }
   end;

   { today's caller records - callers.dat, multiple records }
   tCallRec = record
      CallNum  : LongInt;              { call number }
      Username : String[36];           { user's username }
      Usernum  : Word;                 { user number }
      Location : String[40];           { user's location }
      Baud     : LongInt;              { baudrate connected @ }
      Date     : String[8];            { date called }
      Time     : String[7];            { time called }
      NewUser  : Boolean;              { was this a new user? }
      AreaCode : String[3];            { area code calling from }
   end;

   { system statistics structure - stats.dat, single record }
   tStatRec = record
      FirstDay   : String[8];          { mm/dd/yy - first day loaded         }
      Calls      : Word;               { total number of calls to your bbs   }
      Posts      : Word;               { total number of messages posted     }
      Email      : Word;               { total number of email sent          }
      Uploads    : LongInt;            { number of uploads to the bbs        }
      Downloads  : LongInt;            { number of downloads from the bbs    }
      UploadKb   : LongInt;            { total uploaded kilobytes            }
      DownloadKb : LongInt;            { total downloaded kilobytes          }
      Reserved   : array[1..1024] of Byte; { reserved space for new vars     }
   end;

   { daily history data structure - history.dat, multiple records }
   tHistoryRec = record
      Date       : String[8];          { date of this entry }
      Calls      : Word;               { number of calls this day }
      NewUsers   : Word;               { # of new users this day }
      Posts      : Word;               { # of posts this day }
      Email      : Word;               { total email sent this day }
      Uploads    : Word;               { uploads on this day }
      Downloads  : Word;               { # of downloads }
      UploadKb   : Word;               { uploaded kb this day }
      DownloadKb : Word;               { downloaded kb }
   end;

   tFileAreaRec = record
      Name     : String[40];
      Filename : String[8];
      Path     : String[40];
      Sponsor  : String[36];
      acs      : tACString;
      acsUL    : tACString;
      acsDL    : tACString;
      Password : String[20];
      Files    : Word;
      SortType : Byte;
      SortAcen : Boolean;
      Reserved : array[1..100] of Byte;
   end;

   tFileDescLn = String[maxDescLen];
   tFileDesc = array[1..maxDescLns] of tFileDescLn;
   pFileDesc = ^tFileDesc;

   tFileRec = record
      Filename      : String[12];
      Size          : LongInt;
      Date          : String[8];
      Downloads     : Word;
      filePts       : Word;
      Uploader      : String[36];
      ulDate        : String[8];
      DescPtr       : LongInt;
      DescLns       : Byte;
      Valid         : Boolean;
      Reserved      : array[1..40] of Byte;
   end;

   tUserIndexRec = record
      UserName : String[36];
      RealName : String[36];
      Deleted  : Boolean;
   end;

   tDateTimeRec = record
      Day,
      Hour,
      Min,
      Sec : LongInt;
   end;

   tArchiverRec = record
      Active     : Boolean;
      Extension  : String[3];
      fileSig    : String[20];
      cmdZip     : String[40];
      cmdUnzip   : String[40];
      cmdTest    : String[40];
      cmdComment : String[40];
      cmdDelete  : String[40];
      listChar   : Char;
      Viewer     : Byte;
      okErrLevel : Byte;
      CheckEL    : Boolean;
      Reserved   : array[1..200] of Byte;
   end;

   tEventRec = record
      Active     : Boolean;
      Desc       : String[30];
      Time       : String[5];
      Force      : Boolean;
      RunMissed  : Boolean;
      OffHook    : Boolean;
      Node       : Word;
      Command    : String[200];
      lastExec   : Word;
   end;

   tConfRec = record
      Desc       : String[30];
      Acs        : tACString;
      Key        : Char;
   end;

   tRepAnsiBuf = array[1..maxRepeatBuf] of Byte;

   tAttachRec = record
      Desc       : String[70];
      Filename   : String[12];
      ulDate     : String[8];
      size       : LongInt;
   end;

   pFileScanIdx = ^tFileScanIdx;
   tFileScanIdx = array[1..maxFiles] of Word;

   tTextLibIndex = record
      fileName : String[13];
      filePos  : LongInt;
      fileSize : Word;
   end;
   tTextLibIndexList = array[1..maxTextLib] of tTextLibIndex;
   tTextLib = record
      Desc     : String[36];
      Author   : String[36];
      numLib   : Byte;
      tIndex    : ^tTextLibIndexList;
   end;

   tTextLibRec = record
      Filename : String[8];
   end;

   tTetrisHiRec = record
      Name     : String[36];
      Level    : Byte;
      Lines    : Word;
      Score    : LongInt;
   end;

   tInfoIdxRec = record
      Pos      : LongInt;
      Size     : Word;
   end;

   tInfoformRec = record
      Desc      : String[40];
      Filename  : String[13];
      Mand      : Boolean;
      Nuv       : Boolean;
      Acs       : tACString;
   end;

   tNodeRec = record
      NodeNum   : Byte;
      Username  : String[36];
      Realname  : String[36];
      Usernum   : Word;
      Sex       : Char;
      Baudrate  : LongInt;
      Login     : tDateTimeRec;
      Bdate     : String[8];
      Status    : String[50];
      Data      : LongInt;
   end;

   tNodePtrList = array[1..maxNode] of LongInt;
   tNodeBufList = array[1..maxNodeBuf] of Byte;
