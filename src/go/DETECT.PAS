{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Detect;

interface

{function  detAdlib : Boolean;}
{procedure detAnySoundBlaster;}
function  detDOSversion : String;
procedure detEmulation;
procedure detOperator;
procedure detProcessor;
function  detRemoteANSi : Boolean;
function  detRemoteRIP : Boolean;
function  detRIPTerminal : String;
{function  detUART(Port : Word) : Word;}
{function  detUltraSound : Word;}
procedure detVideoCard;

implementation

uses Dos, Crt,
     Global, Comm, Fossil, Strings, Output, DateTime;

var oprVer : Word;

procedure detEmulation;
var S : String; N, X : Byte; L : LongInt;
label Again;
begin
   detANSI := True;
   detAvatar := False;
   detRIP := False;
   if LocalIO then Exit;
   Col.Fore := 0;
   oWriteRem(#13#10);
   oWriteRem(#27'[0;30m'#13'       '#13);
   cClearInBuffer;

   N := 0;
Again:
   oWriteRem(#13#27'[6n'#13'    '#13);
   S := '';
{  L := Round(dtTimer);
   while (Round(dtTimer)-L < 2) and (not CharWaiting(Modem^.ComPort)) do;}
   Delay(500);
   while (CharWaiting(Modem^.ComPort)) and (Length(S) < 16) do S := S + UpCase(ComReadChar(Modem^.ComPort));
   DetANSi := (S <> '') and (Pos(#27,S) > 0) or (Pos('[',S) > 0) or (Pos(';',S) > 0);
   Inc(N);
   if (not detANSi) and (N <= 3) then goto Again;
   if not detANSI then Exit;

   cClearInBuffer;
   oWriteRem(#27'[!'#13'   '#13);

   Delay(600);
{  L := Round(dtTimer);
   while (Round(dtTimer)-L < 2) and (not CharWaiting(Modem^.ComPort)) do;}
   S := ''; N := 0;
   while (CharWaiting(Modem^.ComPort)) and (N < 14) do
   begin
      S := S + ComReadChar(Modem^.ComPort);
      Inc(N);
   end;
   DetRIP := (Length(S) >= 14) and (Copy(S,1,8) = 'RIPSCRIP');
   if DetRIP then
   begin
      N := StrToInt(Copy(S,9,2));
      case N of
        1 : RIPterm := 'RIPterm';
        2 : RIPterm := 'Qmodem';
       else RIPterm := '???';
      end;
      N := StrToInt(Copy(S,13,2));
      RIPterm := RIPterm + ' v'+St(N);
      if RIPterm[Length(RIPterm)] = '0' then Delete(RIPterm,Length(RIPterm),1);
      N := StrToInt(Copy(S,11,2));
      RIPterm := RIPterm + '.'+St(N);
   end else RIPterm := '';
   cClearInBuffer;
   if detRIP then Exit;

   oWriteRem(#13^V^F#27+'[6n');
   S := '';
{  L := Round(dtTimer);
   while (Round(dtTimer)-L < 2) and (not CharWaiting(Modem^.ComPort)) do;}
   Delay(600);
   while (CharWaiting(Modem^.ComPort)) and (Length(S) < 16) do S := S + UpCase(ComReadChar(Modem^.ComPort));
   detAvatar := StrToInt(Copy(S,Pos(';',S)+1,1)) = 1;
   oWriteRem(#13'      '#13);
   cClearInBuffer;
end;

function detRemoteANSi : Boolean;
var S : String; N : Byte;
label Again;
begin
   N := 0;
   DetANSi := True;
   DetAvatar := False;
   DetRemoteANSi := True;
   if LocalIO then Exit;
   cClearInBuffer;
 Again:
   ComWrite(Modem^.ComPort,#27+'[6n'{+#8#8#8#8});
   Delay(600);
   S := '';
   while (CharWaiting(Modem^.ComPort)) and (Length(S) < 255) do S := S + UpCase(ComReadChar(Modem^.ComPort));
   DetANSi := (Pos(#27,S) > 0) or (Pos('[',S) > 0) or (Pos(';',S) > 0);
   Inc(N,1);
   if (not detANSi) and (N <= 3) then goto Again;
   detRemoteANSi := DetANSi;
   cClearInBuffer;
end;

function detRemoteRIP : Boolean;
var S : String; N : Byte;
Begin
   DetRIP := False;
   detRemoteRIP := False;
   if LocalIO then Exit;
   cClearInBuffer;
   ComWrite(Modem^.ComPort,' '+#27+'['+'!'+#8+' '+#8);
{  ComWrite(Modem^.ComPort,#13#13);}
   Delay(600);
   S := ''; N := 0;
   while (CharWaiting(Modem^.ComPort)) and (N < 14) do
   begin
      S := S + ComReadChar(Modem^.ComPort);
      Inc(N,1);
   end;
   DetRIP := (Length(S) >= 14) and (Copy(S,1,8) = 'RIPSCRIP');
   if DetRIP then
   begin
      N := StrToInt(Copy(S,9,2));
      case N of
        1 : RIPterm := 'RIPterm';
        2 : RIPterm := 'Qmodem';
       else RIPterm := '???';
      end;
      N := StrToInt(Copy(S,13,2));
      RIPterm := RIPterm + ' v'+St(N);
      if RIPterm[Length(RIPterm)] = '0' then Delete(RIPterm,Length(RIPterm),1);
      N := StrToInt(Copy(S,11,2));
      RIPterm := RIPterm + '.'+St(N);
   end else RIPterm := '';
   cClearInBuffer;
   detRemoteRIP := DetRIP;
end;

function detRIPTerminal : String;
begin
   detRIPTerminal := RIPterm;
end;

{$L CPU.OBJ}

{$F+}
function WhichCPU : Byte; external;
{$F-}

procedure detProcessor;
begin
   cpuType := WhichCPU;
end;

procedure detVideoCard;
var
  code : Byte;
  Regs : Registers;
begin
  Regs.AH := $1A;      (* call VGA Identify Adapter Function *)
  Regs.AL := $00;      (* clear AL to 0...*)
  Intr($10, Regs);     (* call BIOS *)
  If Regs.AL = $1A then
  begin
    Case Regs.BL of
      $00 : vidType := vidNone;       (* no Graphic card *)
      $01 : vidType := vidMDA;        (* monochrome *)
      $02 : vidType := vidCGA;        (* cga *)
      $04 : vidType := vidEGA;        (* ega color *)
      $05 : vidType := vidEGAmono;    (* ega mono*)
      $07 : vidType := vidVGAmono;    (* vga mono *)
      $08 : vidType := vidVGA;        (* vga color *)
      $0A,
      $0C : vidType := vidMCGA;       (* mcga color *)
      $0B : vidType := vidMCGAmono;   (* mcga mono *)
      Else
        vidType := vidCGA
    end
  end
  Else
  begin
    Regs.AH := $12;         (* use another Function service *)
    Regs.BX := $10;         (* BL = $10 means return EGA info *)
    Intr($10, Regs);        (* call BIOS video Function *)
    If Regs.bx <> $10 Then  (* bx unchanged means EGA is not present *)
    begin
      Regs.AH := $12;
      Regs.BL := $10;
      Intr($10, Regs);
      If Regs.BH = 0 Then
        vidType := vidEGA
      Else
        vidType := vidEGAmono
    end
    Else
    begin
      Intr($11, Regs);     (* eguipment determination service *)
      code := (Regs.AL and $30) shr 4;
      If (code = 3) Then
        vidType := vidMDA
      Else
        vidType := vidCGA
    end
  end
end; (* vidType *)

function detDOSversion : String;
var Reg : Registers; S : String; Z : Word;
begin
   Reg.AH := $30;
   MsDos(Reg);
   Z := Reg.AL;
   if Z < 2 then Z := 1;
   S := St(Z)+'.'+St(Reg.AH);
   detDOSversion := S;
end;

procedure detMultiTasker; Assembler;
Asm
  mov  oprType, 0
  mov  oprVer, 0
  mov  Ah, 30h
  mov  Al, 01h
  int  21h
  cmp  Al, 20
  je   @OS2
  mov  Ax, 160Ah
  int  2Fh
  cmp  Ax, 0
  je   @Windows
  mov  Ax, 1022h
  mov  Bx, 0000h
  int  15h
  cmp  Bx, 0
  jne  @DESQview
  mov  Ah, 2Bh
  mov  Al, 01h
  mov  Cx, 4445h
  mov  Dx, 5351h
  int  21h
  cmp  Al, $FF
  jne  @TopView
  jmp  @Fin
@Windows:
  Mov  oprType, 1
  Mov  oprVer, BX
  jmp  @Fin
@OS2:
  Mov  oprType, 2
  Mov  Bh, Ah
  Xor  Ah, Ah
  Mov  Cl, 10
  Div  Cl
  Mov  Ah, Bh
  Xchg Ah, Al
  Mov  oprVer, AX
  jmp  @Fin
@DESQview:
  mov  oprType, 3
  jmp  @Fin
@TopView:
  mov  oprType, 4
@Fin:
End;

procedure detOperator;
var Z : Byte;
begin
   oprType := oprDOS;
   oprVersion := '';
   detMultiTasker;
   case oprType of
     oprDOS     : oprVersion := detDOSversion;
     oprWindows,
     oprOS2     : oprVersion := St(Hi(oprVer))+'.'+St(Lo(oprVer));
   end;
end;

end.

function detAdlib : Boolean;
Var
  Val1,Val2 : Byte;
begin
  Port[$388] := 4;      (* Write 60h to register 4 *)
  Delay(3);             (* Which resets timer 1 and 2 *)
  Port[$389] := $60;
  Delay(23);
  Port[$388] := 4;      (* Write 80h to register 4 *)
  Delay(3);             (* Which enables interrupts *)
  Port[$389] := $80;
  Delay(23);
  Val1 := Port[$388];   (* Read status Byte *)
  Port[$388] := 2;      (* Write ffh to register 2 *)
  Delay(3);             (* Which is also Timer 1 *)
  Port[$389] := $FF;
  Delay(23);
  Port[$388] := 4;      (* Write 21h to register 4 *)
  Delay(3);             (* Which will Start Timer 1 *)
  Port[$389] := $21;
  Delay(85);            (* wait 85 microseconds *)
  Val2 := Port[$388];   (* read status Byte *)
  Port[$388] := 4;      (* Repeat the first to steps *)
  Delay(3);             (* Which will reset both Timers *)
  Port[$389] := $60;
  Delay(23);
  Port[$388] := 4;
  Delay(3);
  Port[$389] := $80;    (* Now test the status Bytes saved *)
  detAdlib := ((Val1 And $e0) = 0) And ((Val2 And $e0) = $c0);
end;

function detUltraSound : Word;
const
  GUSPort     : WORD = $FFFF;

  grReset           = $4C;
  grActiveVoices    = $0E;

  grStartAddrHigh   = $02;

 PROCEDURE SetGusRegister8 (Reg, Val : BYTE); ASSEMBLER;
   ASM
                MOV     DX,[GUSPort]
                ADD     DX,103h
                MOV     AL,[Reg]
                OUT     DX,AL
                ADD     DX,2
                MOV     AL,[Val]
                OUT     DX,AL
  END;

 PROCEDURE SetGusRegister16 (Reg: BYTE; Val : WORD); ASSEMBLER;
  ASM
                MOV     DX,[GUSPort]
                ADD     DX,103h
                MOV     AL,[Reg]
                OUT     DX,AL
                INC     DX
                MOV     AX,[Val]
                OUT     DX,AX
  END;

 PROCEDURE GusDelay; ASSEMBLER;
  ASM
                MOV     DX,[GUSPort]
                IN      AL,DX
                IN      AL,DX
                IN      AL,DX
                IN      AL,DX
                IN      AL,DX
                IN      AL,DX
                IN      AL,DX
  END;

 PROCEDURE SetGusVoice (Voice: BYTE); ASSEMBLER;
  ASM
                MOV     DX,[GUSPort]
                ADD     DX,102h
                MOV     AL,[Voice]
                OUT     DX,AL
  END;

 FUNCTION GetGusRegister16 (Reg : BYTE) : WORD; ASSEMBLER;
  ASM
                MOV     DX,[GUSPort]
                ADD     DX,103h
                MOV     AL,[Reg]
                CMP     AL,$40
                JNC     @@c1
                 ADD    AL,80h
        @@c1:   OUT     DX,AL
                INC     DX
                IN      AX,DX
  END;

 FUNCTION ProbeUltrasound : BOOLEAN;
  VAR
    v0, v1 : WORD;
  LABEL
    Fin;
  BEGIN
    ProbeUltrasound := FALSE;

    ASM CLI END;

    SetGusRegister8  (grReset, 0);
    GusDelay;
    SetGusRegister8  (grReset, 7);
    SetGusRegister8  (grActiveVoices, $C0+31);

    SetGusVoice(0);
    v0 := GetGusRegister16(grStartAddrHigh);
    SetGusRegister16(grStartAddrHigh, $16D8);
    SetGusVoice(1);
    v1 := GetGusRegister16(grStartAddrHigh);
    SetGusRegister16(grStartAddrHigh, $0F83);

    SetGusVoice(0);
    IF (GetGusRegister16(grStartAddrHigh) AND $1FFF) <> $16D8 THEN GOTO Fin;
    SetGusVoice(1);
    IF (GetGusRegister16(grStartAddrHigh) AND $1FFF) <> $0F83 THEN GOTO Fin;

    ProbeUltrasound := TRUE;
Fin:
    SetGusVoice(0);
    SetGusRegister16(grStartAddrHigh, v0);
    SetGusVoice(1);
    SetGusRegister16(grStartAddrHigh, v1);

    ASM STI END;

  END;

 FUNCTION DetectUltrasound : BOOLEAN;
  CONST
    GUSPorts : ARRAY[1..12] OF WORD = ( $220, $240, $200, $210, $230, $250,
                                        $260, $270, $280, $290, $2A0, $2B0 );
  VAR
    i : WORD;
  BEGIN
    DetectUltrasound := TRUE;

    IF GUSPort = $FFFF THEN
      FOR i := 1 TO 12 DO
        BEGIN
          GUSPort := GUSPorts[i];
          IF ProbeUltrasound THEN EXIT;
        END
    ELSE
      IF ProbeUltrasound THEN EXIT;

    DetectUltrasound := FALSE;

 END;

begin
   GUSport := $FFFF;
   if DetectUltrasound then detUltraSound := GUSport else detUltraSound := $00;
end;

procedure detAnySoundBlaster;
{ I/O Port offsets. }
CONST
  CMS1DataPortOffset = $00;  { CM/S 1-6  Data port.             Write Only. }
  CMS1AddrPortOffset = $01;  { CM/S 1-6  Address port.          Write Only. }
  CMS2DataPortOffset = $02;  { CM/S 7-12 Data port.             Write Only. }
  CMS2AddrPortOffset = $03;  { CM/S 7-12 Address port.          Write Only. }

  MixAddrPortOffset  = $04;  { Mixer register port.             Write Only. }
  MixDataPortOffset  = $05;  { Mixer data port.                 Read/Write. }

  FMStatPortOffset   = $08;  { Mono FM Status port.             Read  Only. }
  FMAddrPortOffset   = $08;  { Mono FM Address port.            Write Only. }
  FMDataPortOffset   = $09;  { Mono FM Data port.               Write Only. }

  LFMStatPortOffset  = $00;  { Left FM Status port.             Read  Only. }
  LFMAddrPortOffset  = $00;  { Left FM Address port.            Write Only. }
  LFMDataPortOffset  = $01;  { Left FM Data port.               Write Only. }

  RFMStatPortOffset  = $02;  { Right FM Status port.            Read  Only. }
  RFMAddrPortOffset  = $02;  { Right FM Address port.           Write Only. }
  RFMDataPortOffset  = $03;  { Right FM Data port.              Write Only. }

  DSPResetPortOffset = $06;  { DSP Reset port.                  Write Only. }
  DSPReadPortOffset  = $0A;  { DSP Read data port.              Read  Only. }
  DSPLifePortOffset  = $0A;  { DSP Read data port.              Read  Only. }
  DSPWStatPortOffset = $0C;  { DSP Write buffer status port.    Write Only. }
  DSPWritePortOffset = $0C;  { DSP Write data port.             Write Only. }
  DSPRStatPortOffset = $0E;  { DSP Read buffer status port.     Read  Only. }
  DSP8AckPortOffset  = $0E;  {  8 bit DMA IRQ Acknowledge port. Write Only. }
  DSP16AckPortOffset = $0F;  { 16 bit DMA IRQ Acknowledge port. Write Only. }

  CDDataPortOffset   = $10;  { CD-ROM Data port.                Read  Only. }
  CDCmdPortOffset    = $10;  { CD-ROM Command port.             Write Only. }
  CDStatPortOffset   = $11;  { CD-ROM Status port.              Read  Only. }
  CDResetPortOffset  = $12;  { CD-ROM Reset port.               Write Only. }
  CDEnablePortOffset = $13;  { CD-ROM Enable port.              Write Only. }


{ I/O Ports. Same as above. }

CONST
  CMS1DataPort : WORD    = $220 + CMS1DataPortOffset;
  CMS1AddrPort : WORD    = $220 + CMS1AddrPortOffset;
  CMS2DataPort : WORD    = $220 + CMS2DataPortOffset;
  CMS2AddrPort : WORD    = $220 + CMS2AddrPortOffset;

  MixAddrPort  : WORD    = $220 + MixAddrPortOffset;
  MixDataPort  : WORD    = $220 + MixDataPortOffset;

  FMStatPort   : WORD    = $220 + FMStatPortOffset;
  FMAddrPort   : WORD    = $220 + FMAddrPortOffset;
  FMDataPort   : WORD    = $220 + FMDataPortOffset;

  LFMStatPort  : WORD    = $220 + LFMStatPortOffset;
  LFMAddrPort  : WORD    = $220 + LFMAddrPortOffset;
  LFMDataPort  : WORD    = $220 + LFMDataPortOffset;

  RFMStatPort  : WORD    = $220 + RFMStatPortOffset;
  RFMAddrPort  : WORD    = $220 + RFMAddrPortOffset;
  RFMDataPort  : WORD    = $220 + RFMDataPortOffset;

  DSPResetPort : WORD    = $220 + DSPResetPortOffset;
  DSPReadPort  : WORD    = $220 + DSPReadPortOffset;
  DSPLifePort  : WORD    = $220 + DSPLifePortOffset;
  DSPWStatPort : WORD    = $220 + DSPWStatPortOffset;
  DSPWritePort : WORD    = $220 + DSPWritePortOffset;
  DSPRStatPort : WORD    = $220 + DSPRStatPortOffset;
  DSP8AckPort  : WORD    = $220 + DSP8AckPortOffset;
  DSP16AckPort : WORD    = $220 + DSP16AckPortOffset;

  CDDataPort   : WORD    = $220 + CDDataPortOffset;
  CDCmdPort    : WORD    = $220 + CDCmdPortOffset;
  CDStatPort   : WORD    = $220 + CDStatPortOffset;
  CDResetPort  : WORD    = $220 + CDResetPortOffset;
  CDEnablePort : WORD    = $220 + CDEnablePortOffset;


{ Configuration. }

CONST
  SbPort       : WORD    = $FFFF; { Base port. $FFFF Means Autodetect.      }
  SbIrq        : WORD    = 7;     { DMA IRQ level.                          }
  SbDMAChan    : WORD    = 1;     { DMA channel.                            }
  SbDefTimeout : WORD    = 5000;  { Default DSP timeout.                    }
  SbHiSpeed    : BOOLEAN = TRUE;  { User Desires HS DMA mode if TRUE.       }
  SbForce      : BOOLEAN = FALSE; { Force TRUE the detection of the SB.     }
  MixerForce   : BOOLEAN = FALSE; { Force TRUE the detection of the Mixer.  }
  SbProForce   : BOOLEAN = FALSE; { Force TRUE the detection of the SB Pro. }
  Sb16Force    : BOOLEAN = FALSE; { Force TRUE the detection of the SB 16.  }


{ Card information. }

CONST
  SbVersionMin : BYTE       = 0;
  SbVersionMaj : BYTE       = 0;
  SbVersionStr : STRING[ 5] = '';
  SbCopyright  : STRING[80] = '';
  SbResponse1  : BYTE       = 0;
  SbResponse2  : BYTE       = 0;

VAR
  SbVersion    : WORD    ABSOLUTE SbVersionMin;


{ Run-time information. }

CONST
  SbRegDetected     : BOOLEAN = FALSE;
  SbRegInited       : BOOLEAN = FALSE;
  SbProDetected     : BOOLEAN = FALSE;
  SbProInited       : BOOLEAN = FALSE;
  Sb16Detected      : BOOLEAN = FALSE;
  Sb16Inited        : BOOLEAN = FALSE;
  MixerDetected     : BOOLEAN = FALSE;

  SbWorksOk         : BOOLEAN = TRUE;  { Set to FALSE if DSP timeouts.         }
  HSBlockSpecified  : WORD    = 0;     { Set to the last hi-speed block size.  }
  Sb16BlockSpecified: WORD    = 0;     { Set to the last Sb 16 block size.     }
  SbStereo          : BOOLEAN = FALSE; { Stereo DMA mode if TRUE.              }
  SbFilter          : BOOLEAN = FALSE; { SB Pro output filter ON if TRUE.      }

  DoHiSpeed         : BOOLEAN = FALSE; { Hi speed DMA mode if TRUE.            }
  Sb16Bit           : BOOLEAN = FALSE; { 16 bit output if TRUE.                }

  TimeConst         : BYTE    = 0;

  DMAStart          : BOOLEAN = FALSE;
  DMAStop           : BOOLEAN = FALSE;
  DMAStopped        : BOOLEAN = FALSE;

  DMAIrqWatch       : BYTE    = 0;



{ DSP Commands. }

CONST
  sdcSendOneSample  = $10;  { Send a sample to the DAC directly (mono mode only). }
  sdcStartLSpeedDMA = $14;  { Start a low-speed DMA transfer.                     }
  sdcSetTimeConst   = $40;  { Set the time constant.                              }
  sdcSetHSpeedSize  = $48;  { Set hi-speed DMA transfer length.                   }
  sdcStartHSpeedDMA = $91;  { Start a hi-speed DMA transfer.                      }
  sdcTurnOnSpeaker  = $D1;  { Turn on the SB speaker.                             }
  sdcTurnOffSpeaker = $D3;  { Turn off the SB speaker.                            }
  sdcGetDSPVersion  = $E1;  { Get the DSP version number.                         }
  sdcGetCopyright   = $E3;  { Get the card copyright string.                      }


{ Mixer registers. }

CONST
  mxrDataReset    = $00;
  mxrDACVolume    = $04;
  mxrMicMixing    = $0A;
  mxrInSetting    = $0C;
  mxrOutSetting   = $0E;
  mxrMasterVolume = $22;
  mxrFMVolume     = $26;
  mxrCDVolume     = $28;
  mxrLineVolume   = $2E;


{ Bit masks for the mixer registers. }

CONST
  mxiFilterVal = $38;
  mxiADCVal    = $06;
  mxoFilterNeg = $20;
  mxoStereoOn  = $02;

TYPE
  TMixerVolume = (mvMaster,
                  mvVoice,
                  mvFM,
                  mvLine,
                  mvMicrophone,
                  mvSpeaker,
                  mvCD);

CONST
  SbProRegs : ARRAY[mvMaster..mvCD] OF BYTE = ( $22, $04, $26, $2E, $0A, $00, $28 );
  Sb16Regs  : ARRAY[mvMaster..mvCD] OF BYTE = ( $30, $32, $34, $38, $3A, $3B, $34 );

{----------------------------------------------------------------------------}
{ Sound Blaster basic routines.                                              }
{____________________________________________________________________________}

FUNCTION SbReset : BOOLEAN;
  CONST
    ready = $AA;
  VAR
    ct, stat : BYTE;
  BEGIN
    PORT[DSPResetPort] := 1;
    FOR ct := 1 TO 100 DO;
    PORT[DSPResetPort] := 0;

    stat := 0;
    ct   := 0;
    WHILE (stat <> ready) AND (ct < 100) DO BEGIN
      stat := PORT[DSPRStatPort];
      stat := PORT[DSPReadPort];
      INC(ct);
    END;

    SbReset := stat = ready;
  END;


PROCEDURE SbWriteLoop(t: WORD); ASSEMBLER;
  ASM

                MOV     BX,t
                MOV     DX,[DSPWritePort]
@@lp:            DEC    BX
                 JZ     @@fin
                 IN     AL,DX
                 ADD    AL,AL
                 JC     @@lp
@@fin:          OR      BL,BH
                MOV     [SbWorksOk],BL
  END;


PROCEDURE SbWriteByte(t: WORD; b: BYTE); ASSEMBLER;
  ASM

                MOV     AL,b
                XOR     AH,AH
                PUSH    AX
                PUSH    $60

                MOV     AX,t
                PUSH    AX
                CALL    SbWriteLoop
                JNZ     @@ya

                MOV     DX,[DSPLifePort]
                IN      AL,DX

                MOV     AX,t
                PUSH    AX
                CALL    SbWriteLoop

@@ya:           MOV     AL,b
                OUT     DX,AL

                MOV     AL,[SbWorksOk]
                ADD     AL,'A'
                XOR     AH,AH
                PUSH    AX
                PUSH    $40

  END;


PROCEDURE SbReadLoop(t: WORD); ASSEMBLER;
  ASM

                MOV     BX,t
                MOV     DX,[DSPRStatPort]
@@lp:            DEC    BX
                 JZ     @@fin
                 IN     AL,DX
                 ADD    AL,AL
                 JNC    @@lp
@@fin:          OR      BL,BH
                MOV     [SbWorksOk],BL
                MOV     DX,[DSPReadPort]
  END;


FUNCTION SbReadByte(t: WORD) : BYTE; ASSEMBLER;
  ASM
                MOV     AX,t
                PUSH    AX
                CALL    SbReadLoop
                JNZ     @@ya
{
                MOV     DX,[DSPLifePort]
                IN      AL,DX

                MOV     AX,t
                PUSH    AX
                CALL    SbReadLoop
}
@@ya:           IN      AL,DX
  END;




{----------------------------------------------------------------------------}
{ Mixer basic routines.                                                      }
{____________________________________________________________________________}

PROCEDURE SbWriteMixerReg(Reg, Val: BYTE); ASSEMBLER;
  ASM

                MOV     DX,[MixAddrPort]
                MOV     AL,[Reg]
                OUT     DX,AL

                MOV     DX,[MixDataPort]
                MOV     AL,[Val]
                OUT     DX,AL

  END;


FUNCTION SbReadMixerReg(Reg: BYTE) : BYTE; ASSEMBLER;
  ASM

                MOV     DX,[MixAddrPort]
                MOV     AL,[Reg]
                OUT     DX,AL

                MOV     DX,[MixDataPort]
                IN      AL,DX

  END;




{----------------------------------------------------------------------------}
{ Regular Sound Blaster generic routines.                                    }
{____________________________________________________________________________}

FUNCTION SbRegDetect : BOOLEAN;
  VAR
    Port, Lst : WORD;
  BEGIN

    SbRegDetect := SbRegDetected;

    IF SbRegDetected THEN EXIT;

    IF SbPort < $8000 THEN
      BEGIN
        Port := SbPort;
        Lst  := SbPort;
      END
    ELSE
      BEGIN
        Port := $210;
        Lst  := $280;
      END;

    WHILE (NOT SbRegDetected) AND (Port <= Lst) DO BEGIN
      CMS1DataPort := Port + CMS1DataPortOffset;
      CMS1AddrPort := Port + CMS1AddrPortOffset;
      CMS2DataPort := Port + CMS2DataPortOffset;
      CMS2AddrPort := Port + CMS2AddrPortOffset;

      MixAddrPort  := Port + MixAddrPortOffset;
      MixDataPort  := Port + MixDataPortOffset;

      FMStatPort   := Port + FMStatPortOffset;
      FMAddrPort   := Port + FMAddrPortOffset;
      FMDataPort   := Port + FMDataPortOffset;

      LFMStatPort  := Port + LFMStatPortOffset;
      LFMAddrPort  := Port + LFMAddrPortOffset;
      LFMDataPort  := Port + LFMDataPortOffset;

      RFMStatPort  := Port + RFMStatPortOffset;
      RFMAddrPort  := Port + RFMAddrPortOffset;
      RFMDataPort  := Port + RFMDataPortOffset;

      DSPResetPort := Port + DSPResetPortOffset;
      DSPReadPort  := Port + DSPReadPortOffset;
      DSPLifePort  := Port + DSPLifePortOffset;
      DSPWStatPort := Port + DSPWStatPortOffset;
      DSPWritePort := Port + DSPWritePortOffset;
      DSPRStatPort := Port + DSPRStatPortOffset;
      DSP8AckPort  := Port + DSP8AckPortOffset;
      DSP16AckPort := Port + DSP16AckPortOffset;

      CDDataPort   := Port + CDDataPortOffset;
      CDCmdPort    := Port + CDCmdPortOffset;
      CDStatPort   := Port + CDStatPortOffset;
      CDResetPort  := Port + CDResetPortOffset;
      CDEnablePort := Port + CDEnablePortOffset;

      SbRegDetected := SbReset;

      IF NOT SbRegDetected THEN INC(Port, $10);
    END;

    SbRegDetect := SbRegDetected;

  END;


PROCEDURE SbGetDSPVersion;
  VAR
    i : WORD;
    t : WORD;
    s : STRING[2];
  BEGIN
    SbWriteByte(SbDefTimeout, sdcGetDSPVersion); { Send command. }
    t := 0;
    REPEAT
      SbVersionMaj := SbReadByte($FFFF);
      INC(t);
    UNTIL ((SbVersionMaj <> $AA) AND SbWorksOk) OR (t >= 10);
    SbVersionMin := SbReadByte(SbDefTimeout);

    STR(SbVersionMaj, SbVersionStr);
    SbVersionStr := SbVersionStr + '.';
    STR(SbVersionMin, s);
    IF SbVersionMin > 9 THEN SbVersionStr := SbVersionStr +       s
                        ELSE SbVersionStr := SbVersionStr + '0' + s;
  END;


PROCEDURE SbRegInit;
  BEGIN

    IF NOT SbRegDetect THEN EXIT;

    IF NOT SbRegInited THEN
      BEGIN
(*
        SbWriteByte(SbDefTimeout, $E0);
        SbWriteByte(SbDefTimeout, $AA);
        SbResponse1 := SbReadByte (SbDefTimeout); { $55 }
        SbWriteByte(SbDefTimeout, $E4);
        SbWriteByte(SbDefTimeout, $AA);
        SbWriteByte(SbDefTimeout, $E8);
        SbResponse2 := SbReadByte (SbDefTimeout); { $AA }
*)
        SbGetDSPVersion;

        DoHiSpeed := (SbVersion >= $200) AND SbHiSpeed {AND FALSE};
{
        IF DoHiSpeed THEN
          BEGIN
            SbWriteByte(SbDefTimeout, $48);
            SbWriteByte(SbDefTimeout, $00);
            SbWriteByte(SbDefTimeout, $00);
            SbWriteByte(SbDefTimeout, $91);
          END;
}
        SbWriteByte(SbDefTimeout, sdcTurnOnSpeaker);

      END;

    SbRegInited := TRUE;

  END;


PROCEDURE SbRegDone;
  BEGIN
    IF NOT (SbRegDetected AND SbRegInited) THEN EXIT;
    SbWriteByte(SbDefTimeout, sdcTurnOffSpeaker);
  END;




PROCEDURE SbGetCopyrightString;
  VAR
    t : WORD;
  BEGIN
    SbWriteByte(SbDefTimeout, sdcGetCopyright); { Send command. }
    t := 0;
    REPEAT
      SbCopyright := CHAR(SbReadByte($FFFF));
      INC(t);
    UNTIL ((SbCopyright[1] <> #$AA) AND SbWorksOk) OR (t = 10);

    WHILE SbWorksOk AND (Length(SbCopyright) < 80) DO
      SbCopyright := SbCopyright + CHAR(SbReadByte(SbDefTimeout));

    DEC(SbCopyright[0]);
  END;


PROCEDURE SbSetTimeConst(tc: BYTE);
  BEGIN
    IF Sb16Detected THEN
      BEGIN
        IF Sb16Bit THEN
          SbWriteByte(SbDefTimeout, $D9)  { Send time constant command.             }
        ELSE
          SbWriteByte(SbDefTimeout, $DA); { Send time constant command.             }
      END;
    SbWriteByte(SbDefTimeout,   sdcSetTimeConst); { Send time constant command.             }
    SbWriteByte(SbDefTimeout*4, tc);              { Send the time constant.                 }
    TimeConst := 0;                               { Reset time constant to already changed. }
    IF Sb16Detected THEN
      IF Sb16Bit THEN
        SbWriteByte(SbDefTimeout, $47)  { Send time constant command.             }
      ELSE
        SbWriteByte(SbDefTimeout, $45); { Send time constant command.             }
  END;


PROCEDURE SbUpdateTimeConst;
  BEGIN
    IF TimeConst = 0 THEN EXIT;                 { If not changed then do nothing.         }
    SbSetTimeConst(TimeConst);
  END;


PROCEDURE SbStartSampleLS(Len: WORD; Cont: BOOLEAN);
  BEGIN
    HSBlockSpecified := 0;   { Reset Hi-speed block specifier, just in case. }

{WriteChar(CHAR(BYTE(SbWorksOk) + BYTE('A')), $40);}
    SbWriteByte(SbDefTimeout, sdcStartLSpeedDMA); { Start DMA low speed command.   }
{WriteChar(CHAR(BYTE(SbWorksOk) + BYTE('A')), $40);}
    SbWriteByte(SbDefTimeout, LO(Len));           { Low & high bytes of size.      }
{WriteChar(CHAR(BYTE(SbWorksOk) + BYTE('A')), $40);}
    SbWriteByte(SbDefTimeout, HI(Len));

{WriteChar(CHAR(BYTE(SbWorksOk) + BYTE('A')), $40);}

  END;


PROCEDURE SbStartSampleHS(Len: WORD; Cont: BOOLEAN);
  BEGIN
{WriteChar(CHAR(BYTE(SbWorksOk) + BYTE('A')), $40);}
    IF HSBlockSpecified <> Len THEN Cont := FALSE;
    IF NOT Cont THEN
      BEGIN
        SbWriteByte(SbDefTimeout, sdcSetHSpeedSize);  { Set hi speed DMA block command. }
{WriteChar(CHAR(BYTE(SbWorksOk) + BYTE('A')), $40);}
        SbWriteByte(SbDefTimeout, LO(Len));           { Low & high bytes of size.       }
{WriteChar(CHAR(BYTE(SbWorksOk) + BYTE('A')), $40);}
        SbWriteByte(SbDefTimeout, HI(Len));
{WriteChar(CHAR(BYTE(SbWorksOk) + BYTE('A')), $40);}
        HSBlockSpecified := Len;

      END;

    IF NOT (Sb16Detected AND Cont) THEN
      SbWriteByte(SbDefTimeout, sdcStartHSpeedDMA); { Start DMA in hi speed mode.    }
{WriteChar(CHAR(BYTE(SbWorksOk) + BYTE('A')), $40);}
  END;

PROCEDURE Sb16StartSample(Len: WORD; Cont: BOOLEAN);
  BEGIN

    IF (NOT Cont) OR (Sb16BlockSpecified <> Len){ OR TRUE }THEN
      BEGIN
        IF Sb16Bit THEN
          SbWriteByte(SbDefTimeout, $B6)    { Set 16 bit DMA transfer command. }
        ELSE
          SbWriteByte(SbDefTimeout, $C6);   { Set  8 bit DMA transfer command. }
        IF SbStereo THEN
          SbWriteByte(SbDefTimeout, $20)    { Set stereo mode.                 }
        ELSE
          SbWriteByte(SbDefTimeout, $00);   { Set mono mode.                   }
        SbWriteByte(SbDefTimeout, LO(Len));
        SbWriteByte(SbDefTimeout, HI(Len)); { Low & high bytes of size.        }
        Sb16BlockSpecified := Len;
      END
    ELSE
      BEGIN
        IF Sb16Bit THEN
          SbWriteByte(SbDefTimeout, $47)    { 16 bit DMA continue command. }
        ELSE
          SbWriteByte(SbDefTimeout, $45);   {  8 bit DMA continue command. }
      END;

  END;



PROCEDURE SbPlaySample(Len: WORD; Cont: BOOLEAN);
  BEGIN

    IF Len < 10 THEN EXIT;   { Too short -> Discard. It wouldn't sound anyway. }

    IF SbStereo THEN INC(Len, Len); { Twice as big a buffer if stereo mode. }
    DEC(Len);                       { DMA sizes are always size - 1.        }


    IF Sb16Detected AND (SbStereo OR Sb16Bit) THEN
      Sb16StartSample(Len, Cont)
    ELSE IF DoHiSpeed THEN
      SbStartSampleHS(Len, Cont)
    ELSE
      SbStartSampleLS(Len, Cont);
  END;




{----------------------------------------------------------------------------}
{ Mixer generic routines.                                                    }
{____________________________________________________________________________}

FUNCTION MixerDetect : BOOLEAN;
  VAR
    SaveReg : WORD;
    NewReg  : WORD;
  BEGIN
    MixerDetect := MixerDetected;
    IF NOT SbRegDetect OR MixerDetected THEN EXIT;

    SaveReg := SbReadMixerReg($22);
    SbWriteMixerReg($22, 243);
    NewReg  := SbReadMixerReg($22);

    IF NewReg = 243 THEN
      MixerDetected := TRUE;

    SbWriteMixerReg($22, SaveReg);

    MixerDetect := MixerDetected;
  END;




PROCEDURE MixerSetVolume(Reg: TMixerVolume; VolLeft, VolRight: BYTE);
  VAR
    Addr   : BYTE;
    VolMax : BYTE;
  BEGIN
    IF NOT MixerDetected THEN EXIT;

    IF Sb16Detected THEN Addr := Sb16Regs [Reg]
                    ELSE Addr := SbProRegs[Reg];

    IF VolLeft > VolRight THEN VolMax := VolLeft
                          ELSE VolMax := VolRight;

    CASE Reg OF
      mvMicrophone : BEGIN
                       IF Sb16Detected THEN SbWriteMixerReg(Addr, VolMax)
                                       ELSE SbWriteMixerReg(Addr, VolMax SHR 5);
                     END;
      mvSpeaker    : BEGIN
                       IF Sb16Detected THEN SbWriteMixerReg(Addr, VolMax);
                     END;
    ELSE

      IF Sb16Detected THEN
        BEGIN
          SbWriteMixerReg(Addr,     VolLeft);
          SbWriteMixerReg(Addr + 1, VolRight);
        END
      ELSE
        SbWriteMixerReg(Addr, (VolLeft  AND $F0) +
                              (VolRight SHR   4));

    END;

  END;


FUNCTION MixerGetVolume(Reg: TMixerVolume; VAR VolLeft, VolRight: BYTE) : BOOLEAN;
  VAR
    Addr   : BYTE;
    VolMax : BYTE;
  BEGIN
    MixerGetVolume := FALSE;

    IF NOT MixerDetected THEN EXIT;

    IF Sb16Detected THEN Addr := Sb16Regs [Reg]
                    ELSE Addr := SbProRegs[Reg];

    VolLeft  := 0;
    VolRight := 0;

    MixerGetVolume := TRUE;

    CASE Reg OF
      mvMicrophone : BEGIN
                       IF Sb16Detected THEN VolLeft := SbReadMixerReg(Addr)
                                       ELSE VolLeft := SbReadMixerReg(Addr) SHL 5;
                       VolRight := VolLeft;
                     END;
      mvSpeaker    : BEGIN
                       IF Sb16Detected THEN VolLeft := SbReadMixerReg(Addr)
                                       ELSE MixerGetVolume := FALSE;
                       VolRight := VolLeft;
                     END;
    ELSE

      IF Sb16Detected THEN
        BEGIN
          VolLeft  := SbReadMixerReg(Addr);
          VolRight := SbReadMixerReg(Addr + 1);
        END
      ELSE
        BEGIN
          VolLeft  := SbReadMixerReg(Addr);
          VolRight := VolLeft SHL 4;
          VolLeft  := VolLeft AND $F0;
        END;

    END;

  END;




{----------------------------------------------------------------------------}
{ Sound Blaster Pro generic routines.                                        }
{____________________________________________________________________________}

FUNCTION SbProDetect : BOOLEAN;
  BEGIN
    SbProDetect := SbProDetected;
    IF SbProDetected THEN EXIT;

    IF NOT SbRegInited THEN SbRegInit;

    SbProDetected := SbRegDetect AND MixerDetect AND (SbVersion < $400);
    SbProDetect   := SbProDetected;
  END;


PROCEDURE SbProInit;
  BEGIN
    IF NOT SbProDetect THEN EXIT;
    SbProInited := TRUE;
  END;


PROCEDURE SbProDone;
  BEGIN
    SbRegDone;
  END;




PROCEDURE SbProSetStereo(Stereo: BOOLEAN);
  VAR
    i : BYTE;
  BEGIN
    IF NOT SbProDetected THEN EXIT;
    SbStereo := Stereo;
    i := SbReadMixerReg(mxrOutSetting);
    SbWriteMixerReg(mxrOutSetting, (i      AND NOT mxoStereoOn) +
                                   (BYTE(Stereo) * mxoStereoOn));
  END;


PROCEDURE SbProSetFilter(Filter: BOOLEAN);
  VAR
    i : BYTE;
  BEGIN
    IF NOT SbProDetected THEN EXIT;
    SbFilter := Filter;
    i := SbReadMixerReg(mxrOutSetting);
    SbWriteMixerReg(mxrOutSetting, (i      AND NOT mxoFilterNeg) +
                                   (BYTE(Filter) * mxoFilterNeg));
  END;




{----------------------------------------------------------------------------}
{ Sound Blaster 16 generic routines.                                         }
{____________________________________________________________________________}

FUNCTION Sb16Detect : BOOLEAN;
  BEGIN
    Sb16Detect := Sb16Detected;
    IF Sb16Detected THEN EXIT;

    IF NOT SbRegInited THEN SbRegInit;

    Sb16Detected := SbRegDetect AND MixerDetect AND (SbVersion >= $400);
    Sb16Detect   := Sb16Detected;
  END;


PROCEDURE Sb16Init;
  BEGIN
    IF NOT Sb16Detect THEN EXIT;

    SbGetCopyrightString;

    Sb16Inited := TRUE;
  END;


PROCEDURE Sb16Done;
  BEGIN
    SbRegDone;
  END;

begin
   SbPort := $FFFF;
   sndType := sndNone;
   sbRegDetect;
   sbProDetect;
   sb16Detect;
   if sbRegDetected then sndType := sndSoundBlaster;
   if sbProDetected then sndType := sndSoundBlasterPro;
   if sb16Detected then sndType := sndSoundBlaster16;
   if sndType <> sndNone then sndPort := CMS1dataPort;
end;

function detUART(Port : Word) : Word; assembler;
asm
   mov  cx,Port          {1..4}
   push ds
   mov  ds,seg0040       {Use BIOS table to find port addr}
   xor  si,si            {Offset 0 in BIOS table segment}
   rep  lodsw            {Get the right one}
   pop  ds
   or   ax,ax            {Test port address}
   jz   @no_uart         {If zero --> no port}
   mov  dx,ax            {Base address}
   add  dx,4             {Base+4}
   cli
   in   al,dx            {Modem Control Register}
   and  al,11100000b     {Check bit 5-7}
   jnz  @no_uart         {Non-zero --> no UART}
   sub  dx,2             {Base+2}
   jmp  @1               {Give hardware some time}
@1:
   in   al,dx            {Interrupt Identification Register}
   and  al,11110000b     {Check bit 4-7}
   cmp  al,11000000b     {FIFO enabled?}
   jz   @is16550         {Yes, it is a 16550}
   and  al,00110000b     {Check reserved bits}
   jnz  @no_uart         {Non-zero --> No UART}
   mov  al,00000111b     {16550 FIFO enable}
   out  dx,al            {FIFO control register}
   jmp  @2
@2:
   in   al,dx            {FIFO control register}
   and  al,11110000b     {Check bit 4-7}
   mov  ah,al            {Save for later}
   jmp  @3
@3:
   mov  al,00000110b     {16550 FIFO disable}
   out  dx,al            {FIFO control register}
   cmp  ah,11000000b     {FIFO still not enabled?}
   jz   @is16550         {Yes, it is a 16550}
   mov  ax,1
   jmp  @quit
@is16550:
   mov  ax,2
   jmp  @quit
@no_uart:
   xor  ax,ax
@quit:
   sti
end;

end.