program commdev;

uses
   WinDos, Crt;

{ OOP Communications Device Unit - Written by Mike Fricker, April 96 }

type

   pCommObj = ^tCommObj;
   tCommObj = object
      constructor init;
      function detect : Boolean; virtual;
      function open(pn, br : Word; pr : Byte) : Boolean; virtual;
      procedure close; virtual;
      procedure outch(ch : Char); virtual;
      function more : Boolean; virtual;
      function getch : Char; virtual;
      function carrier : Boolean; virtual;
      destructor done;
   end;

   pFossilObj = ^tFossilObj;
   tFossilObj = object(tCommObj)
      constructor init;
      function detect : Boolean; virtual;
      function open(pn, br : Word; pr : Byte) : Boolean; virtual;
      procedure close; virtual;
      procedure outch(ch : Char); virtual;
      function more : Boolean; virtual;
      function getch : Char; virtual;
      function carrier : Boolean; virtual;
   end;

   pAsynchObj = ^tAsynchObj;
   tAsynchObj = object(tCommObj)
      constructor init;
      function detect : Boolean; virtual;
      function open(pn, br : Word; pr : Byte) : Boolean; virtual;
      procedure close; virtual;
      procedure outch(ch : Char); virtual;
      function more : Boolean; virtual;
      function getch : Char; virtual;
      function carrier : Boolean; virtual;
   end;

   tBuffer = array[0..64000] of Char;
   tComBuffer = record
      Active         : Boolean;
      R_Buffer       : ^tBuffer;
      R_Head         : Word;
      R_Tail         : Word;
      R_Size         : Word;
      T_Buffer       : ^tBuffer;
      T_Head         : Word;
      T_Tail         : Word;
      T_Size         : Word;
      UART_Data      : Word;
      UART_IER       : Word;
      UART_IIR       : Word;
      UART_LCR       : Word;
      UART_MCR       : Word;
      UART_LSR       : Word;
      UART_MSR       : Word;
      OLD_MCR        : Byte;
      Org_Vector     : Pointer;
   end;

const
   portBase : array[1..4] of Word = ($3F8,$2F8,$3E8,$2E8);
   portIRQ  : array[1..4] of Byte = (   4,   3,   4,   3);

var
   cport : Word;

   commBuf : array[1..4] of tComBuffer;
   commTsize, commRsize : Word;

   commFossil : pFossilObj;
   commAsynch : pAsynchObj;
   comm : pCommObj;

{ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%[ tCommObj methods ]%%% }
constructor tCommObj.init;
begin
end;

function tCommObj.detect : Boolean;
begin
   detect := True;
end;

function tCommObj.open(pn, br : Word; pr : Byte) : Boolean;
begin
   open := True;
end;

procedure tCommObj.close;
begin
end;

procedure tCommObj.outch(ch : Char);
begin
end;

function tCommObj.more : Boolean;
begin
   more := False;
end;

function tCommObj.getch : Char;
begin
   getch := #0;
end;

function tCommObj.carrier : Boolean;
begin
   carrier := False;
end;

destructor tCommObj.done;
begin
end;

{ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%[ tFossilObj methods ]%%% }
constructor tFossilObj.init;
begin
end;

function tFossilObj.detect : Boolean;
var w : Word;
begin
   asm
      mov ah,04h
      mov dx,00ffh
      int 14h
      mov w,ax
   end;
   detect := w = $1954;
end;

function tFossilObj.open(pn, br : Word; pr : Byte) : Boolean;
var w : Word;
begin
   open := False;
   cport := pn-1;
   asm
      mov ah,04h
      mov dx,cport
      int 14h
   end;

   case br of
      300   : br := $40;    { 01000000 }
      600   : br := $60;    { 01100000 }
      1200  : br := $80;    { 10000000 }
      2400  : br := $a0;    { 10100000 }
      4800  : br := $c0;    { 11000000 }
      9600  : br := $e0;    { 11100000 }
      19200 : br := $00;    { 00000000 }
      38400,
      14400,
      16800 : br := $20;    { 00100000 }
         else br := $23;
   end;
   pr := pr or br;  { merge baud bits with parm bits }

   asm
      mov ah,00h
      mov al,pr
      mov dx,cport
      int 14h
      mov w,ax
   end;

   open := ((w and $10) = $10) or     { clear to send }
           ((w and $20) = $20) or     { data set ready }
           ((w and $40) = $40) or     { ring indicator }
           ((w and $80) = $80);       { data carrier detect }
end;

procedure tFossilObj.close; assembler;
asm
   mov ax,05h
   mov dx,cport
   int 14h
end;

procedure tFossilObj.outch(ch : Char);
var b : Byte; i : Integer;
label resend;
begin
   b := Byte(ch);
resend:
   asm
      mov ah,0Bh
      mov al,b
      mov dx,cport
      int 14h
      mov i,ax
   end;
   if i <> $0001 then goto resend;
{  begin
      cCheckIt;
      if HangUp then Exit else goto Send;
   end;}
end;

function tFossilObj.more : Boolean;
var b : Byte;
begin
   asm
      mov ah,03h
      mov dx,cport
      int 14h
      mov b,ah
   end;
   more := (b and $01) = $01; { character waiting }
end;

function tFossilObj.getch : Char;
var b : Byte;
begin
   asm
      mov ah,02h
      mov dx,cport
      int 14h
      mov b,al
   end;
   getch := Char(b);
end;

function tFossilObj.carrier : Boolean;
var d : Byte;
begin
   asm
     mov ah,03h
     mov dx,cport
     int 14h
     mov d,al
   end;
   carrier := (d and $80) = $80;
end;

{ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%[ tAsynchObj methods ]%%% }
procedure commISR; interrupt;
const
   Ktr : Byte = 0;
   IIR : Byte = 0;
begin
   for Ktr := 1 to 4 do
   begin
      with commBuf[Ktr] do
      begin
         if Active then
         begin
            iir := Port[UART_IIR];
            while not Odd(IIR) do
            begin
               case (iir shr 1) of
                  0 : iir := Port[UART_MSR];
                  1 : if T_Head = T_Tail then Port[UART_IER] := Port[UART_IER] and not 2 else
                      begin
                         Port[UART_DATA] := Byte(T_Buffer^[T_Head]);
                         Inc(T_Head);
                         if T_Head > T_Size then T_Head := 0;
                      end;
                  2 : begin
                         R_Buffer^[R_Tail] := Char(Port[Uart_Data]);
                         Inc(R_Tail);
                         if R_Tail > R_Size then R_Tail := 0;
                         if R_Tail = R_Head then
                         begin
                            Inc(R_Head);
                            if R_Head > R_Size then R_Head := 0;
                         end;
                      end;
                  3 : iir := Port[UART_LSR];
               end;
               iir := Port[UART_IIR];
            end;
         end;
      end;
   end;
   Port[$20] := $20;
end;

constructor tAsynchObj.init;
begin
   commTsize := 4096;
   commRsize := 4096;
end;

function tAsynchObj.detect : Boolean;
begin
   detect := True;
end;

function tAsynchObj.open(pn, br : Word; pr : Byte) : Boolean;
var inUse : Boolean; Ktr, lcr : Byte; divs : Word;
begin
   open := False;
   divs := 115200 div br;
   cport := pn;

   if (pn < 1) or (pn > 4) or (commBuf[pn].active) then Exit;

   GetMem(commBuf[cport].R_Buffer,commRsize);
   commBuf[cport].R_Size := commRsize;
   GetMem(commBuf[cport].T_Buffer,commTsize);
   commBuf[cport].T_Size := commTsize;

   commBuf[cport].UART_DATA := portBase[cport]+0;
   commBuf[cport].UART_IER  := portBase[cport]+1;
   commBuf[cport].UART_IIR  := portBase[cport]+2;
   commBuf[cport].UART_LCR  := portBase[cport]+3;
   commBuf[cport].UART_MCR  := portBase[cport]+4;
   commBuf[cport].UART_LSR  := portBase[cport]+5;
   commBuf[cport].UART_MSR  := portBase[cport]+6;

   inUse := False;
   for Ktr := 1 to 4 do
      if (portIRQ[Ktr] = portIRQ[cport]) and commBuf[Ktr].Active then
         inUse := True;

   inline($FA);

   if not inUse then
   begin
      Port[$21] := Port[$21] or (1 shl portIRQ[cport]);
      GetIntVec(8+portIRQ[cport],commBuf[cport].Org_Vector);
      SetIntVec(8+portIRQ[cport],@commISR);
      Port[$21] := Port[$21] and not (1 shl portIRQ[cport]);
   end;

   commBuf[cport].Old_MCR := Port[commBuf[cport].UART_MCR];
   Port[commBuf[cport].UART_LCR] := 3;
   Port[commBuf[cport].UART_IER] := 1;


   commBuf[cport].Active := True;

   Port [commBuf[cport].uart_lcr ] := Port[commBuf[cport].uart_lcr] or $80;
   Portw[commBuf[cport].uart_Data] := divs;
   Port [commBuf[cport].uart_lcr]  := Port[commBuf[cport].uart_lcr] and not $80;
   lcr:= $00 or $03;

{  case upcase(Parity) Of
      'N': lcr:= $00 or $03;
      'E': lcr:= $18 or $02;
      'O': lcr:= $08 Or $02;
      'S': lcr:= $38 Or $02;
      'M': lcr:= $28 OR $02;
      Else}
{  End;}

{  If StopBits = 2 Then lcr:= Lcr OR $04;}

   Port[commBuf[cport].Uart_lcr] := Port[commBuf[cport].uart_lcr] and $40 or lcr;
   Port[commBuf[cport].Uart_MCR] := 11;
   inline($FB);

   open := True;
end;

procedure tAsynchObj.close;
var inUse : Boolean; Ktr  : byte;
begin
   inUse := False;
   for Ktr := 1 to 4 do
      if (portIRQ[Ktr] = portIRQ[cport]) and commBuf[Ktr].Active then
         inUse := True;

   inline($FA);

   Port[commBuf[cport].UART_MCR] := commBuf[cport].Old_MCR;
   Port[commBuf[cport].UART_IER] := 0;


   if not inUse then
   begin
      Port[$21] := Port[$21] or ($01 shr portIRQ[cport]);
      SetIntVec(8+portIRQ[cport],commBuf[cport].Org_Vector);
   end;

   inline($FB);

   cport := 0;

   Freemem(commBuf[cport].R_Buffer,commBuf[cport].R_Size);
   Freemem(commBuf[cport].T_Buffer,commBuf[cport].T_Size);
   commBuf[cport].Active := False;
end;

procedure tAsynchObj.outch(ch : Char);
begin
   with commBuf[cport] do
   begin
      T_Buffer^[T_Tail] := ch;
      Inc(T_Tail);
      if T_Tail > T_Size then T_Tail := 0;
      if T_Tail = T_Head then
      begin
         Inc(T_Head);
         if T_Head > T_Size then T_Head := 0;
      end;
      inline($FA);
      Port[UART_IER] := Port[UART_IER] or 2;
      inline($FB);
   end;
end;

function tAsynchObj.more : Boolean;
begin
   more := commBuf[cport].R_Head <> commBuf[cport].R_Tail;
end;

function tAsynchObj.getch : Char;
begin
   getch := #0;
   with commBuf[cport] do
   begin
      if R_Head = R_Tail then getch := #0 else
      begin
         getch := R_Buffer^[R_Head];
         Inc(R_Head);
         if R_Head > R_Size then R_Head := 0;
      end;
   end;
end;

function tAsynchObj.carrier : Boolean;
begin
   carrier := Port[commBuf[cport].UART_MSR] and $80 > 0;
end;

{ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% }

var done : Boolean; c : Char; z : Byte;

begin
   for z := 1 to 4 do
   begin
      commBuf[z].Active   := False;
      commBuf[z].R_Buffer := nil;
      commBuf[z].R_Head   := 0;
      commBuf[z].R_Tail   := 0;
      commBuf[z].R_Size   := 0;
      commBuf[z].T_Buffer := nil;
      commBuf[z].T_Head   := 0;
      commBuf[z].T_Tail   := 0;
      commBuf[z].T_Size   := 0;
   end;

   New(commAsynch,init);
   comm := commAsynch;

   clrscr;
   if not comm^.detect then Halt;
   if not comm^.open(2,19200,$03) then Halt;
   if comm^.carrier then WriteLn('carrier detected.') else WriteLn('loaded.');

   done := False;
   repeat
      if keypressed then
      begin
         c := readkey;
         if c = #27 then done := True else
            comm^.outch(c);
      end;
      while comm^.more do Write(comm^.getch);
   until done;

   comm^.close;

   Dispose(commAsynch,done);
end.
