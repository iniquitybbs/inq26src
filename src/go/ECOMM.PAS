unit eComm;

interface

{$IFDEF OS2}uses use32, os2def, os2base;{$ENDIF}

var
  activeComPort: word;
  b: byte;
{$IFDEF OS2}
  portHandle: hfile;
  wrote: ulong;
  eHandle: hfile;
  eHandleActive: boolean;

const {for modem stuff}
  IOCTL_ASYNC = $0001; ASYNC_GETINQUECOUNT = $0068;

type
  rxqueue = record
    Used: SmallWord;
    Size: SmallWord
  end;
{$ENDIF}

function einit(comport, baud: word): boolean;
procedure putstring(const s: string);
function echarready: boolean;
procedure egetchar(var c: char);
procedure eputchar(c: char);
function echeckdcd: boolean;
procedure eclosemodem;
function echeckRI: boolean;
procedure eFlushOutBuffer;
procedure eFlushInBuffer;
function eOutBuffUsed: integer;
procedure esetDTR(b: boolean);
{$IFDEF OS2}
function egetahandle: longint;
procedure epurgehandle;
{$ENDIF}

implementation

{$IFDEF OS2}
procedure setdcb;
type
  dcbinfo = record
              writetimeout : smallword;
              readtimeout  : smallword;
              flags1       : byte;
              flags2       : byte;
              flags3       : byte;
              error        : byte;
              break        : byte;
              XON,XOFF     : byte;
            end;
var
  dcb: dcbinfo;
  plen: ulong;
begin
  dcb.writetimeout := 100;
  dcb.readtimeout := 100;
  dcb.flags1 := $01;          // enable DTR,
  dcb.flags2 := $40;          // enable RTS, disable XON/XOFF
  dcb.flags3 := $04;          // recv timeout mode
  dcb.error := 0;             // no error translate
  dcb.break := 0;             // no break translate
  dcb.xon  := $11;            // standard XON
  dcb.xoff := $13;            // standard XOFF
  plen:=sizeof(dcb);
  dosdevioctl(porthandle, IOCTL_ASYNC, ASYNC_SETDCBINFO,
              @dcb, SizeOf(dcbinfo), @plen, nil, 0, nil);
end;
{$ENDIF}

Function modemInit(port, baud: word): Boolean;
{$IFDEF OS2}
var
  Com: string[5];
  Action: ulong;
  Error: apiret;
Begin
  com:='COM'+char(port+48)+#0;
  Error:=DosOpen(@Com[1], PortHandle, Action, 0, $0000, OPEN_ACTION_OPEN_IF_EXISTS,
                 OPEN_ACCESS_READWRITE OR OPEN_SHARE_DENYNONE, nil);
  if Error<>NO_ERROR then PortHandle:=0;
  setdcb;
  if PortHandle=0 then modemInit:=false else modemInit:=true;
{$ELSE}
var
  Temp: Word;
  Baud57600: boolean;
begin
  activecomport:=port-1;
  asm
    mov ah, $04
    mov bx, $00
    mov dx, activecomPort
    int $14
    mov temp, ax
  end;
  If Temp=$1954 then
    begin
      modeminit:=True;
      if Baud <= 38400 then
        begin
          case baud of
            300  : B:=$43;
            600  : B:=$63;
            1200 : B:=$83;
            2400 : B:=$A3;
            4800 : B:=$C3;
            9600 : B:=$E3;
            19200: B:=$03;
            else   B:=$23; {38400}
          end;
          asm
            mov ah, $00
            mov al, b
            mov dx, activecomPort
            int $14
          end;
        end else
        begin
          if baud=57600 then baud57600:=true else baud57600:=false;
          asm
            mov ah, 1Eh
            mov bx, 0000h
            mov ch, 03h
            mov dx, activecomPort
            cmp baud57600, true
            je @1
            mov cl, 84h
            jmp @int
           @1:
            mov cl, 82h
           @int:
            int 14h
          end;
        end;
    end else modeminit:=False;
{$ENDIF}
end;

function einit(comport, baud: word): boolean;
begin
{initialise the com port (0 based)}
  activeComPort:=comport;
  einit:=modemInit(activeComPort, baud);
end;

procedure putstring(const s: string);
var b: byte;
begin
{$IFDEF OS2}
  doswrite(porthandle, S[1], length(s), wrote);
{$ELSE}
  for b:=1 to length(s) do
    eputchar(s[b]);
{$ENDIF}
end;

function echarready: boolean;
{$IFDEF OS2}
var
  ParmLen: ulong;
  Receive: RxQueue;
  Error  : ApiRet;
begin
  ParmLen:=SizeOf(RXQUEUE); Receive.Used:=0; Receive.Size:=$0FFF;
  Error:=DosDevIoCtl(PortHandle, IOCTL_ASYNC, ASYNC_GETINQUECOUNT, nil, 0, nil,
                     @Receive, SizeOf(Receive), @ParmLen);
  echarready:=(Error=No_Error) and (Receive.Used>0);
{$ELSE}
Begin
  Asm
    mov ah, $03
    mov dx, activecomPort
    int $14
    mov b, ah
  End;
  If (B And 1)=1 Then
    echarready:=True
  Else echarready:=False;
{$ENDIF}
end;

procedure egetchar(var c: char);
begin
{$IFDEF OS2}
  dosread(PortHandle, c, 1, wrote);
{$ELSE}
  b:=0;
  Asm
    mov ah, $03
    mov dx, activecomport
    int $14
    mov b, ah
  End;
  If (B And 1)=1 Then
    Begin
      Asm
        mov ah, $02
        mov dx, activecomport
        int $14
        mov b, al
      End;
      c:=Chr(B);
    End;
{  Asm
    mov ah, $02
    mov dx, activecomPort
    int $14
    mov b, al
  End;
  c:=Chr(B);}
{$ENDIF}
end;

procedure eputchar(c: char);
begin
{$IFDEF OS2}
  doswrite(porthandle, c, 1, wrote);
{$ELSE}
  B:=Ord(c);
  Asm
    mov al, B
    mov dx, activecomPort
    mov ah, $01
    int $14
  End;
{$ENDIF}
end;

function echeckdcd: boolean;
begin
{$IFDEF OS2}
  dosdevioctl(porthandle, IOCTL_ASYNC, ASYNC_GETMODEMINPUT, nil, 0, nil,
              @b, sizeof(b), nil);
  if ((b and DCD_ON)>0) then echeckdcd:=true else echeckdcd:=false;
{$ELSE}
  Asm
    mov ah, $03
    mov dx, activecomPort
    int $14
    mov b, al
  End;
  If (B And $80)<>0 Then
    echeckdcd:=True
  Else echeckdcd:=False;
{$ENDIF}
end;

procedure eclosemodem;
begin
{$IFDEF OS2}
  DosClose(PortHandle);
{$ELSE}
  Asm
    mov ah, $05
    mov dx, activecomPort
    int $14
  End;
{$ENDIF}
end;

function echeckRI: boolean;
const
  RI = $40;
begin
{$IFDEF OS2}
  echeckri:=false;
{$ELSE}
  Asm
    mov ah, 03h
    mov dx, activecomport
    int 14h
    mov b, al
  End;
  echeckri := (b AND RI) = RI;
{$ENDIF}
end;

procedure eFlushOutBuffer;
begin
{$IFNDEF OS2}
  Asm
    mov ah, $08
    mov dx, activecomport
    int $14
  End;
{$ENDIF}
end;

procedure eFlushInBuffer;
var c: array[1..8064] of byte;
begin
{$IFDEF OS2}
  if echarready then dosread(porthandle, c, sizeof(c), wrote);
{$ELSE}
  Asm
    mov ah, $0A
    mov dx, activecomPort
    int $14
  End;
{$ENDIF}
end;

function eOutBuffUsed: integer;
begin
  eOutBuffUsed:=0; {allways 0 unless async}
end;

procedure esetDTR(b: boolean);
{$IFDEF OS2}
type
  CommErr     = (ReceiveQueueOverrun,ReceiveHardwareOverrun,
                 ParityError,FramingError,Undef4,Undef5,Undef6,Undef7,Undef8);
  CommErrSet  = SET OF CommErr;
  MODEMSTATUS = RECORD
                  OnMask              : BYTE;
                  OffMask             : BYTE
                END;

VAR
  MS: MODEMSTATUS;
  ERR: ApiRet;
  COM: CommErrSet;
  comerr: commerrset;
  DataLen: ULONG;
  ParmLen: ULONG;
  P: POINTER;
  W: CommErrSet;
  onmask, offmask: byte;
begin
{hangup}
  if b=false then
    begin onmask:=$00; offmask:=$FE; end
  else
    begin onmask:=$01; offmask:=$FF; end;

    MS.OnMask:=OnMask; MS.OffMask:=OffMask;
    ParmLen:=SizeOf(MODEMSTATUS); DataLen:=SizeOf(CommErrSet); P:=@ComErr;
    IF P=NIL THEN P:=@W;
    DosDevIoCtl(portHandle,IOCTL_ASYNC,ASYNC_SETMODEMCTRL,
                @MS,SizeOf(MODEMSTATUS),ADDR(ParmLen),
                P,SizeOf(CommErrSet),ADDR(DataLen))
end;
{$ELSE}
var
  x: byte;
begin
  if b=true then x:=1 else x:=0;
  Asm
    mov dx, activecomPort
    mov al, x
    mov ah, $06
    int 14h
  End;
end;
{$ENDIF}

{$IFDEF OS2}
function egetahandle: longint;
var
  Com: string[5];
  Action: ulong;
  Error: apiret;
begin
  com:='COM'+char(activecomport+48)+#0;
  Error:=DosOpen(@Com[1], eHandle, Action, 0, $0000, OPEN_ACTION_OPEN_IF_EXISTS,
                 OPEN_ACCESS_READWRITE OR OPEN_SHARE_DENYNONE, nil);
  if Error<>NO_ERROR then eHandle:=0;
  if eHandle<>0 then eHandleActive:=true;
  egetahandle:=eHandle;
end;

procedure epurgehandle;
begin
  if (eHandleActive=true) then dosclose(eHandle);
end;
{$ENDIF}

begin
  activeComPort:=0;
  b:=0;
{$IFDEF OS2}
  portHandle:=0;
  wrote:=0;
  eHandle:=0;
  eHandleActive:=false;
{$ENDIF}
end.

