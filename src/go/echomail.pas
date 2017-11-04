{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,N-,E+}

unit Emulate;

interface

uses
   {$IFDEF OS2} Use32, {$ENDIF}
   Crt;

procedure emuAnsiInit;
procedure emuAnsiWriteChar(Ch : Char); far;
procedure emuANSitoScreen;
procedure emuANSiWrite(S : String); far;
procedure emuANSiWriteLn(S : String); far;
procedure emuScreenToANSi;
procedure fxInit;
procedure fxInitOnce;
procedure fxResetConsole(rem : boolean);
procedure vtInit;
function  vtKey(ch : Char) : String;

type
   tColorPalette  = array[0..255] of record r, g, b : byte; end;
   tColorPalList  = array['A'..'E'] of tColorPalette;
   tColorUPalList = array['1'..'3'] of tColorPalette;
   tParamList     = array[1..4096] of byte;

var
   vt100 : Boolean;
   fxPal : ^tColorPalList;
   fxUserPal : ^tColorUPalList;
   fxPar : ^tParamList;
   fxStage   : Integer;      { current tfx command stage }

implementation

uses
   Dos,
   Global, Misc, StatBar, ShowFile, FastIO, Output, StrProc, Files, Terminal, eComm;

type
   tVtAttr = set of (aBold,aLowint,aUline,aBlink,aReverse,aInvis);

var
   ansiCode   : String;
   ansiSaveX  : Byte;
   ansiSaveY  : Byte;
   ansiEsc    : Byte;
   avtCmd     : Byte;
   avtStage   : Byte;
   avtPar1    : Byte;
   avtPar2    : Byte;

   vtCode     : String;
   vtStage    : Byte;
   vtCmd      : Byte;
   vtSaveX    : Byte;
   vtSaveY    : Byte;
   vtSaveA    : tColorRec;
   vtAttr     : tVtAttr;
   vtBuf      : array[1..3] of Char;

   tab        : array[1..80] of ByteBool;

const
   fxPrefix         = #27;   { tfx command prefix character }
   fxAttrDef : byte = $07;   { default text color attribute }

var
   fxCmd     : Char;         { current tfx command }
   fxNum     : Word;         { number of parameter bytes req'd for command }
   fxSaveX   : byte;         { saved screen column }
   fxSaveY   : byte;         { saved screen row }
   fxAttrSav : byte;         { saved color attribute }

{ reset tfx code variables }
procedure fxReset;
begin
   fxStage := -1;
end;

{ set a single rgb color value }
procedure fxRGB(c, r, g, b : Byte);
begin
{$IFNDEF OS2}
   Port[$3c6] := $ff;
   Port[$3c8] := c;
   Port[$3c9] := r;
   Port[$3c9] := g;
   Port[$3c9] := b;
{$ENDIF}
end;

{ enable/disable high intensity background colors (icecolor) }
procedure fxBright(on : Boolean); assembler;
asm
{$IFNDEF OS2}
   mov     bl,on
   xor     bl,1
   mov     ax,1003h
   int     10h
{$ENDIF}
end;

{ change text screen mode to make colors and fonts look better }
procedure fxTextWidth; assembler;
asm
{$IFNDEF OS2}
   mov     dx,03c4h
   mov     ax,0100h
   out     dx,ax

   mov     dx,03c4h
   mov     ax,0301h
   out     dx,ax

   mov     dx,03c2h
   mov     al,063h
   out     dx,al

   mov     dx,03c4h
   mov     ax,0300h
   out     dx,ax

   mov     dx,03d4h
   mov     ax,4f09h
   out     dx,ax
{$ENDIF}
end;

{ set textmode font }
procedure fxFont(var f);
{$IFNDEF OS2}
var r : Registers;
{$ENDIF}
begin
{$IFNDEF OS2}
   r.bx := $1000;
   r.es := seg(f);
   r.bp := ofs(f);
   r.ax := $1110;
   r.cx := 256;
   r.dx := 0;
   intr($10,r);
{$ENDIF}
   fontchanged := true;
end;

{ set partial textmode font }
procedure fxPartialFont(var f; s, n : word);
{$IFNDEF OS2}
var r : Registers;
{$ENDIF}
begin
{$IFNDEF OS2}
   r.bx := $1000;
   r.es := seg(f);
   r.bp := ofs(f);
   r.ax := $1110;
   r.cx := n;
   r.dx := s;
   intr($10,r);
{$ENDIF}
   fontchanged := true;
end;

{ reset font/palette/screen }
procedure fxResetConsole(rem : boolean);
begin
{$IFDEF OS2}
   textmode(co80);
{$ELSE}
   if (emuTextFX) and (cfg^.tfxFullReset) then textmode(co80+font8x8);
{$ENDIF}
   ioTextMode;
   Window(1,scrTop,maxX,scrBot);
   sbClear;
   sbUpdate;
   posx := 1;
   posy := 1;
   iogotoxy(posx,posy);
   if not emuTextFX then exit;
   if cfg^.tfxFontTweaking then fxTextWidth;
   fxBright(true);
   ioTextAttr(fxAttrDef);
   if rem then oWriteRem(#27'Z');
   fontchanged := false;
end;

{ save the current color palette in a buffer }
procedure fxGetColorPalette(var p : tColorPalette);
var i : byte;
begin
{$IFNDEF OS2}
   for i := 0 to 255 do
   begin
      Port[$3C7] := i;
      p[i].r := Port[$3C9];
      p[i].g := Port[$3C9];
      p[i].b := Port[$3C9];
   end;
{$ENDIF}
end;

{ create default greyscale palette by averaging color indexes }
procedure fxGreyscale;
var z, x : integer;
begin
   for z := 0 to 255 do with fxPal^['E',z] do
   begin
      x := (fxPal^['D',z].r+fxPal^['D',z].g+fxPal^['D',z].b) div 3;
      r := x;
      g := x;
      b := x;
   end;
end;

procedure fxInitOnce;
begin
   fillchar(fxPal^['A'],256,63);
   fillchar(fxPal^['B'],256,0);
   fxGetColorPalette(fxPal^['D']);
   move(fxPal^['D'],fxPal^['C'],sizeof(tColorPalette));
   fxGreyscale;
end;

{ init the textfx engine }
procedure fxInit;
begin
   if not emuTextFX then exit;
   fxResetConsole(true);
   fxAttrDef := $07;
   fillchar(fxUserPal^['1'],256,0);
   fillchar(fxUserPal^['2'],256,0);
   fillchar(fxUserPal^['3'],256,0);
   fxReset;
end;

{ set entire color palette to params }
procedure fxSetFXColorPalette;
var x, z : byte;
begin
   for x := 0 to 63 do
   begin
      z := x*3;
      fxRGB(x,fxPar^[z+1],fxPar^[z+2],fxPar^[z+3]);
   end;
   fontchanged := true;
   fxGetColorPalette(fxPal^['C']);
end;

{ set color palette }
procedure fxSetColorPalette(var p : tColorPalette);
var i : Byte;
begin
{$IFNDEF OS2}
   Port[$3C8] := $00;
   for i := 0 to 255 do
   begin
      Port[$3C8] := i;
      Port[$3C9] := p[i].r;
      Port[$3C9] := p[i].g;
      Port[$3C9] := p[i].b;
   end;
{$ENDIF}
   fontchanged := true;
   fxGetColorPalette(fxPal^['C']);
end;

{ morph from one palette to another smoothly in a specified number of steps }
procedure fxMorphPalette(palfrom, palto : tColorPalette; colFirst, numCol, numStep : Byte); assembler;
label Start, DummyPalette, numColX3, DummySub, StepLoop, ColorLoop, SubLoop,
      RetrLoop1, RetrLoop2, Over1, Over2;
asm
{$IFNDEF OS2}
        jmp        Start
 DummyPalette:
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DummySub:
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 numColX3 :
  dw          0
 Start:
        push ds

        lds         si, palTo
  les         di, palFrom
  xor  ch, ch
  mov         cl, numCol
  shl         cx, 1
  add         cl, numCol
  adc  ch, 0
  mov         word ptr cs:[numColX3], cx
  mov         bx, 0
  push di
 SubLoop:
        lodsb
        sub         al, byte ptr es:di
        mov         byte ptr cs:[DummySub+bx], al
  inc         di
  inc         bx
        loop SubLoop
  pop         di

  push cs
  pop         ds
        mov         dh, 0
  mov  dl, numStep
 StepLoop:
  push di
  mov         cx, word ptr cs:[numColX3]
  mov         bx, 0
 ColorLoop:
  xor         ah, ah
        mov         al, byte ptr cs:[DummySub+bx]
  or         al, al
  jns         over1
  neg         al
 over1:
  mul         dh
  div         dl
  cmp  byte ptr cs:[DummySub+bx], 0
  jge         over2
  neg         al
 over2:
  mov         ah, byte ptr es:[di]
  add         ah, al
  mov         byte ptr cs:[DummyPalette+bx], ah
  inc         bx
  inc         di
  loop ColorLoop

  push dx
  mov  si, offset DummyPalette
  mov  cx, word ptr cs:[numColX3]

  mov  dx, 03DAh
 retrloop1:
  in          al, dx
  test al, 8
  jnz  retrloop1
 retrloop2:
  in          al, dx
  test al, 8
  jz   retrloop2

  mov  dx, 03C8h
  mov  al, colFirst
  out  dx, al
  inc  dx
  rep         outsb

  pop         dx

  pop         di
  inc         dh
  cmp         dh, dl
  jbe         StepLoop

  pop         ds
{$ENDIF}
end;

{ textfx terminal extender commands }
procedure fxCommand;
var x, y, z : Byte;
begin
   case fxCmd of
      'a' : ioGotoXY(posX,posY-1);
      'A' : ioGotoXY(posX,posY-fxPar^[1]);
      'b' : ioGotoXY(posX,posY+1);
      'B' : ioGotoXY(posX,posY+fxPar^[1]);
      'c' : ioGotoXY(posX+1,posY);
      'C' : ioGotoXY(posX+fxPar^[1],posY);
      'd' : ioGotoXY(posX-1,posY);
      'D' : ioGotoXY(posX-fxPar^[1],posY);
      'E' : if interminal then putstring(#27'ENViniqterm v'+bbsVersion+#0);
      'F' : begin fxFont(fxPar^); sbInfo('',false); end;
      'h' : ioGotoXY(1,1);
      'H' : ioGotoXY(fxPar^[1],fxPar^[2]);
      'i' : ioTextAttr(fxAttrSav);
      'I' : fxAttrSav := colAttr;
      'j' : begin ioTextAttr(fxAttrDef); Clrscr; end;
      'J' : ioClrscr;
      'k' : begin ioTextAttr(fxAttrDef); Clreol; end;
      'K' : ioClreol;
      'l' : fxAttrDef := fxPar^[1];
      'M' : ioTextAttr(fxPar^[1]);
      'p' : if char(fxPar^[1]) in ['1'..'3'] then
               fxSetColorPalette(fxUserPal^[char(fxPar^[1])]) else
               fxSetColorPalette(fxPal^[char(fxPar^[1])]);
      'P' : fxSetFXColorPalette;
      'Q' : fxGetColorPalette(fxUserPal^[char(fxPar^[1])]);
      'r' : for z := 1 to fxPar^[2] do { -- } ioWriteChar(char(fxPar^[1]));
      'R' : begin
               fxRGB(fxPar^[1],fxPar^[2],fxPar^[3],fxPar^[4]);
               fxGetColorPalette(fxPal^['C']);
            end;
      's' : ioGotoXY(fxSaveX,fxSaveY);
      'S' : begin fxSaveX := posX; fxSaveY := posY; end;
      't' : ioScrollDown;
      'T' : for z := 1 to fxPar^[1] do ioScrollDown;
      'u' : ioScrollUp;
      'U' : for z := 1 to fxPar^[1] do ioScrollUp;
      'V' : if interminal then putstring(#27'TFX'#1);
      'W' : Window(fxPar^[1],fxPar^[2],fxPar^[3],fxPar^[4]);
      'X' : begin
            if (char(fxPar^[1]) in ['1'..'3']) and (char(fxPar^[2]) in ['1'..'3']) then
               fxMorphPalette(fxUserPal^[char(fxPar^[1])],fxUserPal^[char(fxPar^[2])],0,255,fxPar^[3]) else
            if (char(fxPar^[1]) in ['1'..'3']) and (not (char(fxPar^[2]) in ['1'..'3'])) then
               fxMorphPalette(fxUserPal^[char(fxPar^[1])],fxPal^[char(fxPar^[2])],0,255,fxPar^[3]) else
            if (not (char(fxPar^[1]) in ['1'..'3'])) and ((char(fxPar^[2]) in ['1'..'3'])) then
               fxMorphPalette(fxPal^[char(fxPar^[1])],fxUserPal^[char(fxPar^[2])],0,255,fxPar^[3]) else
               fxMorphPalette(fxPal^[char(fxPar^[1])],fxPal^[char(fxPar^[2])],0,255,fxPar^[3]);
            fxGetColorPalette(fxPal^['C']);
            end;
      'z' : begin
               if ByteBool(fxPar^[1]) then Window(1,1,80,25);
               if ByteBool(fxPar^[2]) then fxSetColorPalette(fxPal^['D']);
               if ByteBool(fxPar^[3]) then ; { reset font }
            end;
      'Z' : fxResetConsole(false);
   end;
   if fxCmd = 'G' then { handle variable font sizes for escG code }
   begin
      if fxNum = 2 then
      begin
         fxPartialFont(fxPar^[3],fxPar^[1],fxPar^[2]);
         fxReset;
      end else
      begin
         Inc(fxStage);
         fxNum := fxPar^[2]+2;
      end;
   end else fxReset;
end;

{ main textfx output engine }
procedure fxOut(ch : Char);
begin
   if fxStage = -1 then
   case ch of
      fxPrefix : fxStage := 0;
      else ioWriteChar(ch); {-}
   end else
   if fxStage = 0 then
   begin
      fxCmd := ch;
      case ch of
         'a','b','c','d','E','h','i','I','j','J','k','K','s','S','t','u','V','Z' : fxNum := 0;
         'A','B','C','D','l','M','p','Q','T','U' : fxNum := 1;
         'G','H','r' : fxNum := 2;
         'z','X' : fxNum := 3;
         'R','W' : fxNum := 4;
         'P' : fxNum := 192;
         'F' : begin sbInfo('[ sending textmode font data ]',True); fxNum := 4096; end;
         else begin fxReset; ioWriteChar(ch); end;
      end;
      if fxStage = fxNum then fxCommand else Inc(fxStage);
   end else
   begin
      fxPar^[fxStage] := Byte(ch);
      if fxStage = fxNum then fxCommand else Inc(fxStage);
   end;
end;

procedure vtTabs;
begin
   FillChar(tab,80,0);
   tab[9] := True;
   tab[17] := True;
   tab[25] := True;
   tab[33] := True;
   tab[41] := True;
   tab[49] := True;
   tab[57] := True;
   tab[65] := True;
   tab[73] := True;
   tab[80] := True;
end;

procedure emuAnsiInit;
begin
   vtTabs;
   ansiCode := '';
   ansiSaveX := 1;
   ansiSaveY := 1;
   ansiEsc := 0;
   avtCmd := 0;
   avtStage := 0;
   avtPar1 := 0;
   avtPar2 := 0;
   fxStage := -1;
   vt100 := False;
end;

procedure vtCol;
var at : tVtAttr; new : tColorRec;
begin
   at := vtAttr;

   at := at-[aInvis]; { not sure what this is yet :) }
   at := at-[aLowInt]; { ditto.. }

   if aBlink in at then new.Blink := True else new.Blink := False;
   at := at-[aBlink];
   if aReverse in at then
   begin
      at := at-[aReverse];
      new.Back := 1;
      if at = [aBold]  then new.Fore := 7 else
      if at = [aUline] then new.Fore := 9 else
      if at = [aUline,aBold] then new.Fore := 15 else
                            new.Fore := 0;
   end else
   begin
      new.back := 0;
      if at = [aBold]  then new.Fore := 15 else
      if at = [aUline] then new.Fore := 8 else
      if at = [aUline,aBold] then new.Fore := 11 else
                            new.Fore := 7;
   end;
   ioTextColRec(new);
end;

procedure vtInit;
begin
   vt100      := True;
   vtTabs;
   vtCode     := '';
   vtStage    := 0;
   vtCmd      := 0;
   vtSaveX    := 1;
   vtSaveY    := 1;
   vtBuf[1]   := #0;
   vtBuf[2]   := #0;
   vtBuf[3]   := #0;
   with vtSaveA do
   begin
      Fore := 7;
      Back := 0;
      Blink := False;
   end;
   FillChar(vtAttr,SizeOf(vtAttr),0);
   vtCol;
end;

procedure vtReset;
begin
   vtCode[0] := #0;
   vtCmd := 0;
end;

function vtNum : Byte;
var i, j : Integer; temp1 : String;
begin
   Val(vtCode,i,j);
   if j = 0 then vtCode := '' else
   begin
      temp1 := Copy(vtCode,1,j-1);
      Delete(vtCode,1,j);
      Val(temp1,i,j);
   end;
   vtNum := i;
end;

procedure vtTab;
var x : Byte;
begin
   x := posX;
   Inc(x);
   if x > 80 then x := 80 else
   while (x < 80) and (not tab[x]) do Inc(x);
   ioGotoXY(x,posY);
end;

procedure vtOut(ch : Char);
var x, y : Byte;
begin
   if vtCmd = 1 then
   case ch of
      '[' : vtCmd := 2;
      'c' : begin vtInit; end;
      'D' : begin ioScrollDown; vtReset; end;
      'M' : begin ioScrollUp; vtReset; ioGotoXY(1,1); end;
      'E' : begin ioWrite(#13#10); vtReset; end;
      '7' : begin vtSaveX := posX; vtSaveY := posY; vtSaveA := Col; vtReset; end;
      '8' : begin ioGotoXY(vtSaveX,vtSaveY); ioTextColRec(vtSaveA); vtReset; end;
      'A' : begin ioGotoXY(posX,posY-1); vtReset; end;
      'B' : begin ioGotoXY(posX,posY+1); vtReset; end;
      'C' : begin ioGotoXY(posX+1,posY); vtReset; end;
{     'D' : begin ioGotoXY(posX-1,posY); vtReset; end;}
      'H' : begin ioGotoXY(1,1); vtReset; end;
      'K' : begin ioClrEol; vtReset; end;
      '(' : vtCmd := 3;
      ')' : vtCmd := 4;
       else vtReset;
   end else
   if vtCmd = 2 then
   case ch of
      '0'..'9',';'
          : vtCode := vtCode+ch;
      'm' : begin
               if vtCode[0] = #0 then vtCode := '0';
               while Ord(vtCode[0]) > 0 do
               begin
                  case vtNum of
                    0   : begin ioTextColor(7,0,False); vtAttr := []; end;
                    1   : begin ioHighVideo; vtAttr := vtAttr+[aBold];
                                if (aReverse in vtAttr) or (aUline in vtAttr) then vtCol;
                          end;
                    2   : begin vtAttr := vtAttr+[aLowint]; vtCol; end;
                    4   : begin vtAttr := vtAttr+[aUline]; vtCol; end;
                    5   : begin vtAttr := vtAttr+[aBlink]; vtCol; end;
                    7   : begin vtAttr := vtAttr+[aReverse]; vtCol; end;
                    8   : begin vtAttr := vtAttr+[aInvis]; vtCol; end;
              {     5   : ioTextAttr(colAttr or $80);}
                  { 7   : Reverse_Video; }
                    30  : ioTextAttr((colAttr and $F8)+0);
                    31  : ioTextAttr((colAttr and $F8)+4);
                    32  : ioTextAttr((colAttr and $F8)+2);
                    33  : ioTextAttr((colAttr and $F8)+6);
                    34  : ioTextAttr((colAttr and $F8)+1);
                    35  : ioTextAttr((colAttr and $F8)+5);
                    36  : ioTextAttr((colAttr and $F8)+3);
                    37  : ioTextAttr((colAttr and $F8)+7);
                    40  : ioTextBack(0);
                    41  : ioTextBack(4);
                    42  : ioTextBack(2);
                    43  : ioTextBack(6);
                    44  : ioTextBack(1);
                    45  : ioTextBack(5);
                    46  : ioTextBack(3);
                    47  : ioTextBack(7);
                  end;
               end;
               vtReset;
            end;
      'A' : begin x := vtNum; if x = 0 then x := 1; ioGotoXY(posX,posY-x); vtReset; end;
      'B' : begin x := vtNum; if x = 0 then x := 1; ioGotoXY(posX,posY+x); vtReset; end;
      'C' : begin x := vtNum; if x = 0 then x := 1; ioGotoXY(posX+x,posY); vtReset; end;
      'D' : begin x := vtNum; if x = 0 then x := 1; ioGotoXY(posX-x,posY); vtReset; end;
      'H','f'
          : begin y := vtNum; if y = 0 then ioGotoXY(1,1) else ioGotoXY(vtNum,y); vtReset; end;
      'J' : begin
               case vtNum of
                  0 : ioClrDown;
                  1 : ioClrUp;
                  2 : ioClrScr;
               end;
               vtReset;
            end;
      'K' : begin
               case vtNum of
                  0 : ioClrEol;
               end;
               vtReset;
            end;
      'r' : begin Window(1,vtNum,80,vtNum); ioGotoXY(1,1); vtReset; end;
       else vtReset;
   end else
   if vtCmd in [3,4] then  { keyboard/character set codes }
   case ch of
      'A' : vtReset;
      'B' : vtReset;
      '0' : vtReset;
      '1' : vtReset;
      '2' : vtReset;
       else vtReset;
   end else
   case ch of
      #27 : vtCmd := 1;
      #9  : vtTab;
      #12 : ioClrScr;
      '[' : begin vtBuf[1] := '['; ioWriteChar(Ch); end;
      #15 : { wtf is this?? } begin end;
      #2  : begin if aBold in vtAttr then vtAttr := vtAttr-[aBold] else
                      vtAttr := vtAttr+[aBold]; vtCol; end;
      #22 : begin if aReverse in vtAttr then vtAttr := vtAttr-[aReverse] else
                                             vtAttr := vtAttr+[aReverse]; vtCol; end;
      #31 : begin if aUline in vtAttr then vtAttr := vtAttr-[aUline] else
                                           vtAttr := vtAttr+[aUline]; vtCol; end;
       #7 : if tmBeeps then ioWriteChar(Ch);
       else ioWriteChar(Ch);
   end;
end;

function vtKey(ch : Char) : String;
var s : String;
begin
   case ch of
      f1        : s := #27'[[A';
      f2        : s := #27'[[B';
      f3        : s := #27'[[C';
      f4        : s := #27'[[D';
      f5        : s := #27'[[E';
      f6        : s := #27'[[F';
      f7        : s := #27'[[G';
      f8        : s := #27'[[H';
      f9        : s := #27'[[I';
      f10       : s := #27'[[J';
      upArrow   : s := #27'[A';
      dnArrow   : s := #27'[B';
      rtArrow   : s := #27'[C';
      lfArrow   : s := #27'[D';
      DeleteKey : s := ^D;
      else s := '';
   end;
   vtKey := s;
end;

function ansiNum : Byte;
var i, j : Integer; temp1 : String;
begin
   Val(ansiCode,i,j);
   if j = 0 then ansiCode := '' else
   begin
      temp1 := Copy(ansiCode,1,j-1);
      Delete(ansiCode,1,j);
      Val(temp1,i,j);
   end;
   ansiNum := i;
end;

procedure emuAnsiWriteChar(Ch : Char);
var Col, X, Y : Integer;
begin
   if vt100 then vtOut(ch) else
   if fxStage > 0 then fxOut(ch) else
   if avtCmd = 100 then
   begin
      if avtStage = 1 then begin avtPar1 := Ord(Ch); Inc(avtStage); end else
      if avtStage = 2 then
      begin
         ioWrite(sRepeat(Chr(avtPar1),Ord(Ch)));
         avtCmd := 0;
      end;
   end else
   if ansiEsc > 0 then
   case ansiEsc of
     1 : begin
            if Ch = '[' then
            begin
               ansiEsc := 2;
               ansiCode := '';
            end else if emuTextFX then
            begin
               ansiEsc := 0;
               fxStage := 0;
               fxOut(ch);
            end else ansiEsc := 0;
         end;
     2 :
      case Ch of
         '0'..'9',
         ';'      : ansiCode := ansiCode+Ch;
         '?'      : ;
         'h'      : ansiEsc := 0;
         'm'      : begin
                       ansiEsc := 0;
                       if ansiCode[0] = #0 then ansiCode := '0';
                       while Ord(ansiCode[0]) > 0 do
                       begin
                          Col := ansiNum;
                          case Col of
                            0   : ioTextColor(7,0,False);
                            1   : ioHighVideo;
                            5   : ioTextAttr(colAttr or $80);
                          { 7   : Reverse_Video; }
                            30  : ioTextAttr((colAttr and $F8)+0);
                            31  : ioTextAttr((colAttr and $F8)+4);
                            32  : ioTextAttr((colAttr and $F8)+2);
                            33  : ioTextAttr((colAttr and $F8)+6);
                            34  : ioTextAttr((colAttr and $F8)+1);
                            35  : ioTextAttr((colAttr and $F8)+5);
                            36  : ioTextAttr((colAttr and $F8)+3);
                            37  : ioTextAttr((colAttr and $F8)+7);
                            40  : ioTextBack(0);
                            41  : ioTextBack(4);
                            42  : ioTextBack(2);
                            43  : ioTextBack(6);
                            44  : ioTextBack(1);
                            45  : ioTextBack(5);
                            46  : ioTextBack(3);
                            47  : ioTextBack(7);
                          end;
                       end;
                    end;
         'H','f'  : begin
                       ansiEsc := 0;
                       Y := ansiNum;
                       if Y > 25 then Y := 25 else if Y < 1 then Y := 1;
                       X := ansiNum;
                       if X > 80 then X := 80 else if X < 1 then X := 1;
                       ioGotoXY(X,Y);
                    end;
         'A'      : begin
                       ansiEsc := 0;
                       Y := ansiNum;
                       if Y = 0 then Y := 1;
                       Y := posY-Y;
                       if Y < 1 then Y := 1;
                       ioGotoXY(posX,Y);
                    end;
         'B'      : begin
                       ansiEsc := 0;
                       Y := ansiNum;
                       if Y = 0 then Y := 1;
                       Y := posY+Y;
                       if Y > 25 then Y := 25;
                       ioGotoXY(posX,Y);
                    end;
         'C'      : begin
                       ansiEsc := 0;
                       X := ansiNum;
                       if X = 0 then X := 1;
                       X := posX+X;
                       if X > 80 then X := 1;
                       ioGotoXY(X,posY);
                    end;
         'D'      : begin
                       ansiEsc := 0;
                       X := ansiNum;
                       if X = 0 then X := 1;
                       X := posX-X;
                       if X < 1 then X := 1;
                       ioGotoXY(X,posY);
                    end;
         's'      : begin
                       ansiEsc := 0;
                       ansiSaveX := posX;
                       ansiSaveY := posY;
                    end;
         'u'      : begin
                       ansiEsc := 0;
                       ioGotoXY(ansiSaveX,ansiSaveY);
                    end;
         'J'      : begin
                       ansiEsc := 0;
                       ioClrScr;
                    end;
         'K'      : begin
                       ansiEsc := 0;
                       ioClrEol;
                    end;
        else ansiEsc := 0;
      end;
     else begin
             ansiEsc := 0;
             ansiCode := '';
          end;

   end else
   if avtCmd > 1 then
   case avtCmd of
      2 : begin ioTextAttr(Ord(Ch)); avtCmd := 0; end;
      3 : case avtStage of
            1 : begin avtPar1 := Ord(Ch); Inc(avtStage); end;
            2 : begin avtPar2 := Ord(Ch); ioGotoXY(avtPar2,avtPar1); avtCmd := 0; end;
            else avtCmd := 0;
          end;
      else avtCmd := 0;
   end else
   if avtCmd = 1 then
   case Ch of
      ^A : begin avtCmd := 2; avtStage := 1; end;
      ^B : begin ioTextBlink(True); avtCmd := 0; end;
      ^C : begin ioGotoXY(posX,posY-1); avtCmd := 0; end;
      ^D : begin ioGotoXY(posX,posY+1); avtCmd := 0; end;
      ^E : begin ioGotoXY(posX-1,posY); avtCmd := 0; end;
      ^F : begin ioGotoXY(posX+1,posY); avtCmd := 0; end;
      ^G : begin ioClrEol; avtCmd := 0; end;
      ^H : begin avtCmd := 3; avtStage := 1; end;
     else avtCmd := 0;
   end else
   begin
      case Ch of
        { Avatar/0 commands }
{         ^L : begin ioTextAttr($03); ioClrScr; end;}
          ^Y : begin avtCmd := 100; avtStage := 1; end;
          ^V : avtCmd := 1;

         #27 : ansiEsc := 1;
         #9  : vtTab;
         #12 : ioClrScr;
         else ioWriteChar(Ch);
      end;
   end;
end;

procedure emuAnsiWrite(S : String);
var N : Byte;
begin
   posUpdate := False;
   for N := 1 to Ord(S[0]) do emuAnsiWrite(S[N]);
   ioUpdatePos;
end;

procedure emuAnsiWriteLn(S : String);
begin
   emuAnsiWrite(S+#13#10);
end;

procedure emuScreenToANSi;
var ansScr : Text;

  Procedure Xlate(var OutFile : text);
  const
    NUMROWS = 25;
    NUMCOLS = 80;
  type
    ElementType = record
                    ch   : char;
                    Attr : byte;
                  end;
    ScreenType = array[1..NUMROWS,1..NUMCOLS] of ElementType;

  const
    TextMask = $07; {0000 0111}
    BoldMask = $08; {0000 1000}
    BackMask = $70; {0111 0000}
    FlshMask = $80; {1000 0000}
    BackShft = 4;

    ESC = #$1B;

    ANSIcolors : array[0..7] of byte = (0, 4, 2, 6, 1, 5, 3, 7);

    Procedure ChangeAttr(var Outfile : text; var OldAtr : byte; NewAtr : byte);
    var
      Connect : string[1]; {Is a seperator needed?}
    begin
      Connect := '';
      write(Outfile, ESC, '['); {Begin sequence}
      If (OldAtr AND (BoldMask+FlshMask)) <>     {Output flash & blink}
         (NewAtr AND (BoldMask+FlshMask)) then begin
        write(Outfile, '0');
        If NewAtr AND BoldMask <> 0 then write(Outfile, ';1');
        If NewAtr AND FlshMask <> 0 then write(Outfile, ';5');
        OldAtr := $FF; Connect := ';';   {Force other attr's to print}
      end;

      If OldAtr AND BackMask <> NewAtr AND BackMask then begin
        write(OutFile, Connect,
              ANSIcolors[(NewAtr AND BackMask) shr BackShft] + 40);
        Connect := ';';
      end;

      If OldAtr AND TextMask <> NewAtr AND TextMask then begin
        write(OutFile, Connect,
              ANSIcolors[NewAtr AND TextMask] + 30);
      end;

      write(outfile, 'm'); {Terminate sequence}
      OldAtr := NewAtr;
    end;

    {Does this character need a changing of the attribute?  If it is a space,
     then only the background color matters}

    Function AttrChanged(Attr : byte; ThisEl : ElementType) : boolean;
    var
      Result : boolean;
    begin
      Result := FALSE;
      If ThisEl.ch = ' ' then begin
        If ThisEl.Attr AND BackMask <> Attr AND BackMask then
          Result := TRUE;
      end else begin
        If ThisEl.Attr <> Attr then Result := TRUE;
      end;
      AttrChanged := Result;
    end;

  var
    Screen   : ^ScreenType;
    ThisAttr, TestAttr : byte;
    LoopRow, LoopCol, LineLen, numR : integer;
  begin {Xlate}
    ThisAttr := $FF; {Force attribute to be set}
    pointer(Screen) := fastio.screen;
    if Cfg^.StatBarOn then numR := 24 else numR := 25;
    For LoopRow := 1 to numR do begin

      LineLen := NUMCOLS;   {Find length of line}
      While (LineLen > 0) and (Screen^[LoopRow, LineLen].ch = ' ')
            and not AttrChanged($00, Screen^[LoopRow, LineLen])
        do Dec(LineLen);

      For LoopCol := 1 to LineLen do begin {Send stream to file}
        If AttrChanged(ThisAttr, Screen^[LoopRow, LoopCol])
          then ChangeAttr(Outfile, ThisAttr, Screen^[LoopRow, LoopCol].Attr);
        write(Outfile, Screen^[LoopRow, LoopCol].ch);
      end;
    If (LineLen < 80) and (LoopRow <> numR) then writeln(OutFile); {else wraparound occurs}
    end;
  end; {Xlate}

begin
(* {$IFNDEF OS2} *)
   Assign(ansScr,fTempPath('T')+fileTempScr);
   {$I-}
   Rewrite(ansScr);
   {$I+}
   if ioResult <> 0 then Exit;
   Write(ansScr,#27'[0m'#27'[2J');
   Xlate(ansScr);
   Close(ansScr);
   scrX := oWhereX;
   scrY := oWhereY;
   scrCol := Col;
(* {$ENDIF} *)
end;

procedure emuANSitoScreen;
begin
(* {$IFNDEF OS2} *)
   sfShowFile(fTempPath('T')+fileTempScr,ftNoCode);
   oGotoXY(scrX,scrY);
   oSetColRec(scrCol);
(* {$ENDIF} *)
end;

end.
