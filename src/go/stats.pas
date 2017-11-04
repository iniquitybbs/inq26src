{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,N-,E+}
unit Sauce;

interface

function sauceDiz(fn, dn : String) : Boolean;

implementation

uses
   StrProc;

type  DataTypes      = (None, Character, GFX, Vector, Sounds);
      CharacterFiles = (ASCII, ANSi, ANSiMation, RIP, PCBoard, AVATAR);
      GFXFiles       = (GIF, PCX, LBM, TGA, FLI, FLC, BMP, GL, DL, WPG);
      VectorFiles    = (DXF, ACAD_DWG, DrawPerfect);
      SoundFiles     = (_MOD, _669, _STM, _S3M, _MTM, _FAR, _ULT, _AMF, _DMF,
                        _OKT, _ROL, _CMF, _MIDI, _SADT, _VOC, _WAV,
                        _Sample8, _Sample8Stereo, _Sample16, _Sample16Stereo);

      Char2    = Array [0..1]  of Char;
      Char5    = Array [0..4]  of Char;
      Char8    = Array [0..7]  of Char;
      Char20   = Array [0..19] of Char;
      Char35   = Array [0..34] of Char;
      Char64   = Array [0..63] of Char;

const SAUCE_ID      : Char5 = 'SAUCE';
      SAUCE_Version : Char2 = '00';
      CMT_ID        : Char5 = 'COMNT';
      MaxCMT        = 10;

type  SAUCERec = record                { ��� Implemented in Version ?        }
                   ID       : Char5;   { 00  'SAUCE'                         }
                   Version  : Char2;   { 00  '00'                            }
                   Title    : Char35;  { 00  Title of the file               }
                   Author   : Char20;  { 00  Creator of the file             }
                   Group    : Char20;  { 00  Group creator belongs to        }
                   Date     : Char8;   { 00  CCYYMMDD                        }
                   FileSize : Longint; { 00  Original FileSize               }
                   DataType : Byte;    { 00  type of Data                    }
                   FileType : Byte;    { 00  What type of file is it ?       }
                   TInfo1   : Word;    { 00  \                               }
                   TInfo2   : Word;    { 00   \ type Info Zone            *2*}
                   TInfo3   : Word;    { 00   /                              }
                   TInfo4   : Word;    { 00  /                               }
                   Comments : Byte;    { 00  Number of Comment lines      *1*}
                   Filler   : Array[1..23] of Char;
                 end;
      CMTRec   = Char64;
      CMTBlock = record
                   ID       : Char5;
                   Comment  : Array[1..MaxCMT] of CMTRec;
                 end;

const SAUCE_SIZ= Sizeof(SAUCEREC);
      CMTR_SIZ = Sizeof(CMTRec);
      CMTB_SIZ = Sizeof(CMTBlock);

var   sa       : SAUCERec;
      CMT      : CMTBlock;

procedure sauceClear;
begin
  FillChar(sa,sizeof(sa),#0);
  FillChar(CMT,sizeof(CMT),#0);
end;

var Name0 : Array [0..80] of CHAR;

function sauceGet(FileName : String) : Boolean; assembler;
{ function returns TRUE if we have a sa record                            }
{ It will continue to try reading a COMMENT block if it's there.  You should }
{ check the sa ID to assure a commentblock was succesfully read           }
var           RetVal : Boolean;

asm
{$IFDEF OS2} { disable sauce for now ... === }
   mov al, 0
{$ELSE}
              MOV    [RetVal],FALSE    { Assume theer's gonna be no sa    }
              PUSH   DS                { Save DS                             }
              CALL   sauceClear        {                                     }
              CLD

              MOV    AX,Seg Name0      { \                                   }
              MOV    ES,AX             {  > ES:DI -> Name0 (asciiz filename) }
              MOV    DI,Offset Name0   { /                                   }
              LDS    SI,[FileName]     { DS:SI -> Filename (Pascal String)   }
              LODSB                    { Get Length of String                }
              MOV    CL,AL             { \ Length in CX                      }
              XOR    CH,CH             { /                                   }
              JCXZ   @FinishPatch      { Length == 0 ?                       }
              REP    MOVSB             { Copy Filename                       }
              MOV    AL,0              { \ Store NULL Terminator             }
              STOSB                    { /                                   }

              MOV    AH,03Dh           { Open a file (using a handle)        }
              MOV    AL,000h           { Filemode = Non shared, Read only.   }
              PUSH   ES                { \                                   }
              POP    DS                {  > DS:DX = Filename                 }
              MOV    DX,Offset Name0   { /                                   }
              INT    21h               { And open the File..                 }
              JNC    @FileOpenOK       { IF CF=0 then file is correctly open }

@FinishPatch: JMP    @Finish           { Patch to jump to @Finish label, but }
                                       { too far away for a conditional jump }
                                       { like the JCXZ a couple lines above  }

@FileOpenOk:  MOV    BX,AX             { Handle in BX !! DO NOT CHANGE BX !! }

              MOV    AH,042h           { Move file pointer (LSEEK)           }
              MOV    AL,2              { Move from end of file               }
              MOV    CX,0FFFFh         { \ Seek from EOF -128 bytes          }
              MOV    DX,-SAUCE_SIZ     { /                                   }
              INT    21h               { Do LSEEK ! BX has handle !          }
              JC     @Close            { Seek Failed, Stop reading           }

              MOV    AH,03Fh           { Read from File                      }
              MOV    CX,SAUCE_SIZ      { Read 128 Bytes                      }
              MOV    DX,Seg sa      { \                                   }
              MOV    DS,DX             {  > DS:DX -> Buffer for read         }
              MOV    DX,Offset sa   { /                                   }
              INT    21h               { Read file ! BX has handle !         }
              JC     @Close            { Read Failed, Stop reading           }
              CMP    AX,CX             { \ Stop if we didn't read what we    }
              JNE    @Close            { / wanted.                           }

              MOV    DI,Offset sa
              CMP    Word PTR DS:[DI],'AS'   { \   ID = sa ???            }
              JNE    @Close                  {  \  Note, Intel big-endian    }
              CMP    Word PTR DS:[DI+2],'CU' {   >                           }
              JNE    @Close                  {  /                            }
              CMP    Byte PTR DS:[DI+4],'E'  { /                             }
              JNE    @Close
              { If we get here, we have a valid sa record                 }
              { DS Still points to Segment of sa record                   }
              MOV    [RetVal],TRUE     { We have sa                       }

              MOV    AL,sa.Comments
              OR     AL,AL
              JZ     @Close            { No Comment Block, our work is done  }
              { Comment block is here.  Check it out                         }
              XOR    AH,AH             { # of lines in AX                    }
              MOV    DX,CMTR_SIZ       { DX = Size fo Comment line           }
              MUL    DX                { AX, has size of Comment block.      }
                                       { Max size CMT block: 64*256 = 16K    }
              ADD    AX,5              { Add size of Comment ID              }
              ADD    AX,128            { Add size of sa                   }
              MOV    DI,AX             { DI = Loc from EOF for CMT rec       }

              MOV    AH,042h           { Move file pointer (LSEEK)           }
              MOV    AL,2              { Move from end of file               }
              MOV    CX,0FFFFh         { \  Seek from EOF to start of CMT    }
              MOV    DX,DI             {  > record                           }
              NEG    DX                { /                                   }
              INT    21h               { Do LSEEK ! BX has handle !          }
              JC     @Close            { Seek Failed, Stop reading           }

              CMP    DI,CMTB_SIZ
              JB     @CMT_OK
              { CMT record in file is bigger than the one we support         }
              { Some Data will be clipped away.                              }
              MOV    DI,CMTB_SIZ       { Read maximum we support             }
@CMT_OK:      MOV    AH,03Fh           { Read from File                      }
              MOV    CX,DI             { Read DI Bytes                       }
              MOV    DX,Seg CMT        { \                                   }
              MOV    DS,DX             {  > DS:DX -> Buffer for read         }
              MOV    DX,Offset CMT     { /                                   }
              INT    21h               { Read file ! BX has handle !         }
              JC     @Close            { Read Failed, Stop reading           }
              CMP    AX,CX             { \ Stop if we didn't read what we    }
              JNE    @Close            { / wanted                            }

              { FUTURE add-ons to sa will be processed here               }

@Close:       MOV    AH,3Eh            { Close Handle                        }
              INT    21h               { And do the close, !BX has handle !! }

@Finish:      MOV    AL,[RetVal]       { Return Value                        }
              POP    DS
{$ENDIF}
end;

function sauceDiz(fn, dn : String) : Boolean;
var f : Text; s : String; z, l : Byte;
begin
   sauceClear;
   sauceDiz := False;
   if not sauceGet(fn) then Exit;
   Assign(f,dn);
   {$I-}
   Rewrite(f);
   {$I+}
   if ioResult <> 0 then Exit;
   l := 0;

   s := cleanUp(sa.title);
   if s <> '' then WriteLn(f,' title: '+s);
   if Ord(s[0]) > l then l := Ord(s[0]);
   s := cleanUp(sa.author);
   if s <> '' then WriteLn(f,'author: '+s);
   if Ord(s[0]) > l then l := Ord(s[0]);
   s := cleanUp(sa.group);
   if s <> '' then WriteLn(f,' group: '+s);
   if Ord(s[0]) > l then l := Ord(s[0]);

   if (sa.comments > 0) and (sa.comments <= maxCmt) and (cmt.id = cmt_id) then
   begin
      WriteLn(f,sRepeat('~',8+l));
      for z := 1 to sa.comments do
      begin
         s := cleanUp(cmt.comment[z]);
         WriteLn(f,s);
      end;
   end;

   sauceDiz := True;

   Close(f);
end;

end.
