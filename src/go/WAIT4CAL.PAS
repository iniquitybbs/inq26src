{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Wait4Cal;

interface

var menuLaunch : Boolean;

procedure wfcOnline(Bd : LongInt);
procedure wfcWaitForCall;

implementation

uses Crt, Dos, Overlay,
     Global, Strings, Comm, Fossil, Output, Input, HardANSI, Misc, BBSInit,
     Config1, Config2, Config3, Config4, Config5, Config6, Config7, Config8,
     Config9, Config10, Config11, Config12, Config14, Config15, Config16,
     Config17, Files, MicroDOS, FsEditor, MsgArea, Detect, Screen, FastIO,
     Terminal, History, Callers, Logs, Email, Users, DateTime, FileSort,
     Nodes;

const MaxWFCItem = 6; MaxCmds = 8;

type ItemRec = array[1..MaxWFCItem,1..MaxCmds] of String[14];
     ConfRec = record
                 nAttr, fAttr, hAttr : Byte;
                 XPos, YPos : Byte;
               end;

const WFCCom : ItemRec =
      (('local logon',
        'exit iniquity',
        'jump to dos',
        'init modem',
        'hangup modem',
        'offhook modem',
        'answer modem',
        'terminal mode'),
       ('system config',
        'modem setup',
        'string editor',
        'menu editor',
        'enter microdos',
        'msgarea editor',
        'pack msgareas',
        'level editor'),
       ('protocol cfg',
        'user editor',
        'launch menu',
        'read email',
        'view mailbox',
        'enter email',
        'filearea edit',
        'edit textfile'),
       ('archiver setup',
        'file conf edit',
        'msg conf edit',
        'sort all files',
        'stat editor',
        'bbslist editor',
        'event editor',
        'textfile libs'),
       ('edit infoforms',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---'),
       ('system info',
        '---',
        'system totals',
        'today''s stats',
        'last callers',
        '---',
        '---',
        'iniquity info'));

      WFCConfig : ConfRec =
      (nAttr : 1; fAttr: $17; hAttr : $1F; xPos : 58; yPos : 15-1);

   maxSB       = 30;

   terX1       = 5;
   terY1       = 20;
   terX2       = 51;
   terY2       = 22;

   colItem : Byte = 1;
   colLo   : Byte = 5;
   colHi   : Byte = 4;

   maxScroll   = 1400;

var Mnu, Pos, Res : Integer;
    SB : array[1..maxSB] of Char;
    Ch : Char;
    LocalMode, Saver : Boolean;
    Cnct, Try, Blank, LastInit : LongInt;
    fIn : Boolean;
    tX,tY : Byte;
    wfcL, wfcN, numDraw : Word;
    wfcScroll : array[1..maxScroll] of Char;
    Ti : String[10];
    lastDraw : Real;

procedure wfcReadModem;
begin
   if ModemOff then Exit;
   if CharWaiting(Modem^.ComPort) then
   begin
      Move(SB[2],SB[1],maxSB-1);
      SB[maxSB] := ComReadChar(Modem^.ComPort);
      if not Saver then Write(SB[maxSB]);
   end;
end;

procedure wfcFadefxOut;
var N : Byte;
begin
   if not Cfg^.VgaEffects then Exit;
   for N := 21 downto 0 do begin Delay(4); mSetColor(colItem,N,N,N); end;
end;

procedure wfcFadefxIn;
var N : Byte;
begin
   if not Cfg^.VgaEffects then Exit;
   for N := 0 to 21 do begin Delay(4); mSetColor(colItem,N,N,N); end;
 end;

procedure wfcFadefx;
begin
   if not Cfg^.VgaEffects then Exit;
   mSetColor(colItem,21,21,21);
   mSetColor(colLo,10,32,10);
   mSetColor(colHi,10,60,10);
end;

procedure wfcFadefxNormal;
begin
   if not Cfg^.VgaEffects then Exit;
   mSetColor(colItem,0,0,42);
   mSetColor(colLo,42,0,42);
   mSetColor(colHi,42,0,0);
end;

procedure wfcFadefxInit;
begin
   if not Cfg^.VgaEffects then Exit;
   mSetColor(colItem,0,0,0);
   mSetColor(colLo,0,0,0);
   mSetColor(colHi,0,0,0);
end;

procedure wfcFadeStatOut;
var N : Byte;
begin
   if not Cfg^.VgaEffects then Exit;
   for N := 60 downto 0 do
   begin
      Delay(3);
      if N <= 32 then mSetColor(colLo,N div 5,N,N div 5);
      mSetColor(colHi,N div 6,N,N div 6);
   end;
   fIn := False;
end;

procedure wfcFadeStatIn;
var N : Byte;
begin
   if not Cfg^.VgaEffects then Exit;
   for N := 0 to 60 do
   begin
      Delay(3);
      if N <= 32 then mSetColor(colLo,N div 5,N,N div 5);
      mSetColor(colHi,N div 6,N,N div 6);
   end;
   fIn := True;
end;

function wfcInSB(S : String) : Boolean;
var N, L : Byte; F : Boolean;
begin
   wfcInSB := False;
   if S = '' then Exit;
   F := True;
   L := Length(S);
   for N := 1 to Length(S) do
   begin
      if (SB[maxSB-L+N] = #13) or
         (SB[maxSB-L+N] = #10) or
         (SB[maxSB-L+N] = '/') then SB[maxSB-L+N] := '|';
      if UpCase(SB[maxSB-L+N]) <> UpCase(S[N]) then F := False;
   end;
   wfcInSB := F;
end;

function wfcResult(S : String) : Boolean;
var N : Word; OK : Boolean;
begin
   if ModemOff then Exit;
   Delay(300);
   N := 0;
   OK := False;
   repeat
      wfcReadModem;
      Inc(N,1);
      OK := wfcInSB(S);
   until (OK) or (N = 5000) or ((KeyPressed) and (ReadKey = #27));
   wfcResult := OK;
   while (not KeyPressed) and (CharWaiting(Modem^.ComPort)) do wfcReadModem;
   while Keypressed do ReadKey;
   tX := WhereX; tY := WhereY;
end;

procedure wfcInitModem;
begin
   lastInit := Trunc(dtTimer);
   cModemWrite(Modem^.sInit1);
   cModemWrite(Modem^.sInit2);
   cModemWrite(Modem^.sInit3);
   wfcResult(Modem^.rOk);
end;

procedure wfcDrawStats(Clear : Boolean);
const sx = 5;
      sy = 15;
      sa1 = sx;     sc1 = sx;
      sa2 = sx+23;  sc2 = sx+8;
      sb1 = sx;     sc3 = sx+16;
      sb2 = sx+10;  sc4 = sx+24;
      sb3 = sx+20;  sc5 = sx+32;
      sb4 = sx+30;  sc6 = sx+40;

var S : String; B : Byte; W : Word; R : Real; L : LongInt; Call : tCallRec;
const Ttl : array[1..8] of String = ('system information',
                                     '',
                                     'system statistics',
                                     'today''s statistics',
                                     'last four callers',
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
   end;
   case curStat of
     1:
   begin
      fWrite(sa1,sy+0,'CPU processor',colLo);
      fWrite(sa1,sy+1,'Video display',colLo);
      fWrite(sa1,sy+2,'Overlay buffer',colLo);
      fWrite(sa1,sy+3,'Running under',colLo);

      case cpuType of
         cpu8088    : S := '8088';
         cpu8086    : S := '8086';
         cpu80286   : S := '80286';
         cpu80386   : S := '80386';
         cpu80486   : S := '80486';
         cpuPentium : S := 'Pentium';
         cpuFuture  : S := 'Unknown';
      end;
     1:
   begin
      fWrite(sa1,sy+0,'CPU processor',colLo);
      fWrite(sa1,sy+1,'Video display',colLo);
      fWrite(sa1,sy+2,'Overlay buffer',colLo);
      fWrite(sa1,sy+3,'Running under',colLo);

      case cpuType of
         cpu8088    : S := '8088';
         cpu8086    : S := '8086';
         cpu80286   : S := '80286';
         cpu80386   : S := '80386';
         cpu80486   : S := '80486';
         cpuPentium : S := 'Pentium';
         cpuFuture  : S := 'Unknown';
      end;

begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
   end;
   case curStat of
     1:
   begin
      fWrite(sa1,sy+0,'CPU processor',colLo);
      fWrite(sa1,sy+1,'Video display',colLo);
      fWrite(sa1,sy+2,'Overlay buffer',colLo);
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
   end;
   case curStat of
     1:
   begin
      fWrite(sa1,sy+0,'CPU processor',colLo);
      fWrite(sa1,sy+1,'Video display',colLo);
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
   end;
   case curStat of
     1:
   begin
      fWrite(sa1,sy+0,'CPU processor',colLo);
      fWrite(sa1,sy+1,'Video display',colLo);
      fWrite(sa1,sy+2,'Overlay buffer',colLo);
      fWrite(sa1,sy+3,'Running under',colLo);

      case cpuType of
         cpu8088    : S := '8088';
         cpu8086    : S := '8086';
         cpu80286   : S := '80286';
         cpu80386   : S := '80386';
         cpu80486   : S := '80486';
         cpuPentium : S := 'Pentium';
         cpuFuture  : S := 'Unknown';
      end;
            fWrite(sx+7,sy+W-1,strSquish(Call.Username,23),colHi);
            if Call.NewUser then fWrite(sx+6,sy+W-1,'*',colLo);
            fWrite(sx+31,sy+W-1,ResizeRt(Call.Time,7),colLo);
            fWrite(sx+40,sy+W-1,ResizeRt(mBaudString(Call.Baud),6),colLo);
         end else fWrite(sx,sy+W-1,'---',colLo);
      end;
   end;
     8:
     begin             {                                              }
        fWrite(sx,sy+0,'      The '+bbsTitle+' Bulletin Board System',colHi);
        fWrite(sx,sy+1,'     (c)Copyright 1994-1995, Mike Fricker',colLo);
        fWrite(sx,sy+2,'     Version: '+bbsVersion+' ð Release: '+bbsRelease,colLo);
        fWrite(sx,sy+3,'        Alpha test copy (%) registered',colLo);
{       fWrite(sx,sy+0,'      The Iniquity Bulletin Board System',colHi);
        fWrite(sx,sy+1,'     (c)Copyright 1994-1995, Mike Fricker',colLo);
        fWrite(sx,sy+2,'      Version: 1.00a23, Release: 10/02/78'
        fWrite(sx,sy+3,'        Alpha test copy :: (registered)',colLo);}
   {$IFDEF iniRegistered}
{        fWrite(sx,sy+6,'Registered to: '+mRegString,colLo);}
   {$ENDIF}
     end;
   end;
end;

procedure wfcUpdate;
var mx : Word; scrS : String[50];
begin
   if Ti <> dtTimeStr12 then
   begin
      Ti := dtTimeStr12;
      fWrite(8,12,Ti,$02);
      if Ord(ti[0]) = 6 then fWrite(14,12,';',$08) else
                             fWrite(15,12,';',$08);
      fWrite(23,12,dtDateString,$02);
   end;
   if dtRealDiff(lastDraw,dtTimer) > 0.15 then
   begin
{      case numDraw of
        1 : begin
               fWrite(4,4,'ù',$08); fWrite(5,4,'ù',$07);
               fWrite(4,5,'ù',$07); fWrite(5,5,'ù',$0F);
            end;
        2 : begin
               fWrite(4,4,'ù',$07); fWrite(5,4,'ù',$08);
               fWrite(4,5,'ù',$0F); fWrite(5,5,'ù',$07);
            end;
        3 : begin
               fWrite(4,4,'ù',$0F); fWrite(5,4,'ù',$07);
               fWrite(4,5,'ù',$07); fWrite(5,5,'ù',$08);
             end;
        4 : begin
               fWrite(4,4,'ù',$07); fWrite(5,4,'ù',$0F);
               fWrite(4,5,'ù',$08); fWrite(5,5,'ù',$07);
            end;
      end;}
      mx := wfcN+44-1;
      if mx > wfcL then mx := wfcL;
      Dec(mx,wfcN);
      Move(wfcScroll[wfcN],scrS[1],mx);
      scrS[0] := Chr(mx);
      fWrite(37,12,scrS,$02);
      Inc(wfcN);
      if wfcN >= wfcL then wfcN := 1;
      Inc(numDraw);
      if numDraw > 4 then numDraw := 1;
      lastDraw := dtTimer;
   end;
end;

procedure wfcAnswerModem;
var Z : Byte; sta : LongInt;
begin
   if ModemOff then Exit;
   cModemWrite(Modem^.sAnswer);
   logWrite('Answering modem');
   while CharWaiting(Modem^.ComPort) do wfcReadModem;
   Cnct := 0;
   Try := 0;
   cClearInBuffer;
   while Keypressed do ReadKey;
   sta := Trunc(dtTimer);
   while (not CharWaiting(Modem^.ComPort)) and (dtSecDiff(sta,Trunc(dtTimer)) < Cfg^.waitConnect) and
         (not Keypressed) do
   begin
      wfcUpdate;
      Delay(100);
   end;
   while Keypressed do ReadKey;
   while (Cnct = 0) and (Try < 10000) and (not Keypressed) do
   begin
      wfcReadModem;
      if wfcInSB(Modem^.c300+'|') then Cnct := 300 else
      if wfcInSB(Modem^.c1200+'|') then Cnct := 1200 else
      if wfcInSB(Modem^.c1275+'|') then Cnct := 1275 else
      if wfcInSB(Modem^.c2400+'|') then Cnct := 2400 else
      if wfcInSB(Modem^.c4800+'|') then Cnct := 4800 else
      if wfcInSB(Modem^.c9600+'|') then Cnct := 9600 else
      if wfcInSB(Modem^.c12000+'|') then Cnct := 12000 else
      if wfcInSB(Modem^.c14400+'|') then Cnct := 14400 else
      if wfcInSB(Modem^.c16800+'|') then Cnct := 16800 else
      if wfcInSB(Modem^.c19200+'|') then Cnct := 19200 else
      if wfcInSB(Modem^.c21600+'|') then Cnct := 21600 else
      if wfcInSB(Modem^.c24000+'|') then Cnct := 24000 else
      if wfcInSB(Modem^.c26400+'|') then Cnct := 26400 else
      if wfcInSB(Modem^.c28800+'|') then Cnct := 28800 else
      if wfcInSB(Modem^.c38400+'|') then Cnct := 38400 else
      if wfcInSB(Modem^.c57600+'|') then Cnct := 57600 else
      if wfcInSB(Modem^.c64000+'|') then Cnct := 64000 else
      if wfcInSB(Modem^.c115200+'|') then Cnct := 115200;
      Inc(Try);
   end;
   while CharWaiting(Modem^.ComPort) do wfcReadModem;
   cClearInBuffer;
   cClearOutBuffer;
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
   end;
   case curStat of
     1:
   begin
      fWrite(sa1,sy+0,'CPU processor',colLo);
      fWrite(sa1,sy+1,'Video display',colLo);
      fWrite(sa1,sy+2,'Overlay buffer',colLo);
      fWrite(sa1,sy+3,'Running under',colLo);

      case cpuType of
         cpu8088    : S := '8088';
         cpu8086    : S := '8086';
         cpu80286   : S := '80286';
         cpu80386   : S := '80386';
         cpu80486   : S := '80486';
         cpuPentium : S := 'Pentium';
         cpuFuture  : S := 'Unknown';
      end;
end;

function wfcGetSel(var I : ItemRec; var Cf : ConfRec; Mnu : Integer) : Integer;
var N, CI, W : Integer; Cnt : LongInt; S : String; C : Char;
    wcDone : Boolean; lastRing : LongInt;

 procedure wfcClearSB;
 begin
    FillChar(SB,SizeOf(SB),#0);
 end;

 procedure wfcCheckRing;
 begin
    if ((LastRing > 0) and (Modem^.MultiRing) and (dtSecDiff(lastRing,Trunc(dtTimer)) <= 3))
       or (not Modem^.MultiRing) then wfcAnswerModem;
    LastRing := Trunc(dtTimer);
 end;
 procedure wfcDrawSelBar;
 var x : Byte;
 begin
    if cfg^.vgaEffects then
    begin
       S := Resize(' f'+St(CI),4);
       fWrite(Cf.Xpos,Cf.Ypos+CI,S,Cf.fAttr);
       S := Resize(I[Mnu,CI],16);
       fWrite(Cf.Xpos+4,Cf.Ypos+CI,S,Cf.hAttr);
       Exit;
    end;
    s := strResizeNc(' f'+st(ci),4)+strResizeNc(i[mnu,ci],16);
    for x := 1 to Ord(s[0]) do if (x > 2) and (s[x-1] = ' ')
        then fWrite(cf.xpos+x-1,cf.ypos+ci,s[x],$2F) else fWrite(cf.xpos+x-1,cf.ypos+ci,s[x],$2A);
 end;
 procedure wfcDrawNorBar;
 var x : Byte;
 begin
    if cfg^.vgaEffects then
    begin
       S := ' f'+St(CI);
       S := Resize(S,4);
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
   end;
   case curStat of
     1:
   begin
      fWrite(sa1,sy+0,'CPU processor',colLo);
      fWrite(sa1,sy+1,'Video display',colLo);
      fWrite(sa1,sy+2,'Overlay buffer',colLo);
      fWrite(sa1,sy+3,'Running under',colLo);

      case cpuType of
         cpu8088    : S := '8088';
         cpu8086    : S := '8086';
         cpu80286   : S := '80286';
         cpu80386   : S := '80386';
         cpu80486   : S := '80486';
         cpuPentium : S := 'Pentium';
         cpuFuture  : S := 'Unknown';
      end;
    wfcFadefx;
    scrRestoreScreen(2);
    Window(terX1,terY1,terX2,terY2);
    tX := scrX;
    tY := scrY;
    GotoXY(tX,tY);
    mCursor(True);
    fIn := True;
 end;

 procedure wfcBlankSaver;
 begin
    repeat
       if ((Cfg^.modemReInit > 0) and (dtSecDiff(lastInit,Trunc(dtTimer)) >= Cfg^.modemReInit))
          then wfcInitModem;
    until (Keypressed) or ((not modemOff) and (CharWaiting(Modem^.ComPort)));
 end;

 procedure wfcCopperSaver;
 var Pal     : array[0..2000-1] of Byte;
     sTab    : array[0..255] of Word;
     barTab  : array[0..10-1] of Word;
     Size    : Word;
     Step    : Word;
     Bars    : Word;
     a,b,c,d : Word;
 begin
    ansiHead;
    Size := 300+Random(100);
    Bars := 1+Random(4);
    Step := 5+Random(30);
    FillChar(Pal,SizeOf(Pal),0);
    for a := 0 to Bars-1 do barTab[a] := Step*a;
    for a := 0 to 255 do sTab[a] := Round(Sin(2*Pi*a/255)*86)+86;
    repeat
       FillChar(Pal,3*Size,0);
       for a := 0 to Bars-1 do
       begin
          for b:=0 to 63 do Pal[a mod 3+3*sTab[barTab[a]]+3*b] := b;
          for b:=0 to 63 do Pal[a mod 3+3*sTab[barTab[a]]+3*64+3*b] := 63-b;
          barTab[a] := 1+barTab[a] mod 255;
       end;

       asm cli end;
       while (Port[$3da] and 8) <> 0 do;
       while (Port[$3da] and 8) = 0 do;
       c := 0;
       for d := 0 to Size-1 do
       begin
          Port[$3c8] := 0;
          Port[$3c9] := Pal[c];
          Port[$3c9] := Pal[c+1];
          while (Port[$3da] and 1) <> 0 do;
          while (Port[$3da] and 1) = 0 do;
          Port[$3c9] := Pal[c+2];
          Inc(c,3);
       end;
       asm sti end;
       if ((Cfg^.modemReInit > 0) and (dtSecDiff(lastInit,Trunc(dtTimer)) >= Cfg^.modemReInit))
          then wfcInitModem;
    until (Keypressed) or ((not ModemOff) and (CharWaiting(Modem^.ComPort)));
 end;

begin
   wfcClearSB;
   Cf.nAttr := colItem;
   Cnt := 0;
   fWrite(63,23,'------',$08);
   if Mnu > 1 then fWrite(63+Mnu-2,23,'-',$07);
   fWrite(63+Mnu-1,23,'þ',$0F);
   if Mnu < 6 then fWrite(63+Mnu,23,'-',$07);
   fWrite(71,23,St(Mnu),$07);
   for CI := 1 to MaxCmds do if CI = Pos then wfcDrawSelBar else wfcDrawNorBar;
   wfcFadefxIn;
   CI := Pos;
   Blank := Trunc(dtTimer);
   wcDone := False;
   LastRing := 0;
   LastDraw := dtTimer;
   numDraw := 1;
   Ti := '';
   wfcUpdate;
{  fWrite(14,3,bbsVersion,$09);
   fWrite(34,3,bbsRelease,$09);}
   if not fIn then
   begin
      wfcDrawStats(False);
      wfcFadeStatIn;
   end;
   repeat
      if ((Cfg^.modemReInit > 0) and (dtSecDiff(lastInit,Trunc(dtTimer)) >= Cfg^.modemReInit))
         then wfcInitModem;
{     if dtTimeStr12 = '1:50am' then killTerminateBBS;}
{     if dtTimeStr12 = '6:45am' then
      begin
         errorLevel := 241;
         killTerminateBBS;
      end;
      if dtTimeStr12 = '6:50am' then
      begin
         errorLevel := 241;
         killTerminateBBS;
      end;}
      if (not Saver) and (Cfg^.ScreenSaver > 0) and
         (dtSecDiff(Blank,Trunc(dtTimer)) >= Cfg^.BlankSeconds) then
      begin
         Saver := True;
         scrStoreScreen(2);
         scrX := WhereX;
         scrY := WhereY;
         TextMode(Co80);
         mCursor(False);
         case Cfg^.ScreenSaver of
            1 : wfcBlankSaver;
            2 : wfcCopperSaver;
         end;
         wfcKillSaver;
         while Keypressed do ReadKey;
      end;
      if Keypressed then
      begin
         Ch := Readkey;
         Blank := Trunc(dtTimer);
      end else Ch := #1;
      if Ch = #0 then
      begin
         Ch := ReadKey;
         case Ch of
           #72 : begin
                    if (CI = 1) and (Mnu > 1) then
                    begin
                       CI := 11;
                       Pos := 8;
                       wcDone := True;
                    end else if CI <> 1 then
                    begin
                       wfcDrawNorBar;
                       Dec(CI);
                       Pos := CI;
                       wfcDrawSelBar;
                    end;
                 end;
           #80 : begin
                    if (CI = 8) and (Mnu < 6) then
                    begin
                       CI := 12;
                       Pos := 1;
                       wcDone := True;
                    end else if CI <> 8 then
                    begin
                       wfcDrawNorBar;
                       Inc(CI);
                       Pos := CI;
                       wfcDrawSelBar;
                    end;
                 end;
           #59 : begin wfcDrawNorBar; CI :=  1; Pos := CI; wfcDrawSelBar; wcDone := True; end;
           #60 : begin wfcDrawNorBar; CI :=  2; Pos := CI; wfcDrawSelBar; wcDone := True; end;
           #61 : begin wfcDrawNorBar; CI :=  3; Pos := CI; wfcDrawSelBar; wcDone := True; end;
           #62 : begin wfcDrawNorBar; CI :=  4; Pos := CI; wfcDrawSelBar; wcDone := True; end;
           #63 : begin wfcDrawNorBar; CI :=  5; Pos := CI; wfcDrawSelBar; wcDone := True; end;
           #64 : begin wfcDrawNorBar; CI :=  6; Pos := CI; wfcDrawSelBar; wcDone := True; end;
           #65 : begin wfcDrawNorBar; CI :=  7; Pos := CI; wfcDrawSelBar; wcDone := True; end;
           #66 : begin wfcDrawNorBar; CI :=  8; Pos := CI; wfcDrawSelBar; wcDone := True; end;
           #75 : if Mnu > 1 then begin CI := 11; wcDone := True; end;
           #77 : if Mnu < 6 then begin CI := 12; wcDone := True; end;
         end;
      end else
      case Ch of
         #13 : wcDone := True;
         #27 : if Cfg^.ESCtoExit then
               begin
                  cModemWrite(Modem^.sExitStr);
                  if ModemIO then while (not KeyPressed) and (CharWaiting(Modem^.ComPort)) do wfcReadModem;
                  mClearScr(True);
                  wfcFadefxNormal;
                  killTerminateBBS;
               end;
      end;
      wfcUpdate;
      wfcReadModem;
      if wfcInSB(Modem^.rRing+'|') then wfcCheckRing;
      if oprType > oprDOS then mTimeSlice;
   until ((ModemIO) and (not cNoCarrier)) or (wcDone);
   if (not cNoCarrier) and (ModemIO) then CI := 0 else wfcFadefxOut;
   wfcGetSel := CI;
end;

procedure wfcHangUpModem;
begin
   cModemWrite(Modem^.sHangUp);
   wfcResult(Modem^.rOK);
end;

procedure wfcOffHookModem;
begin
   cModemWrite(Modem^.sOffHook);
   wfcResult(Modem^.rOK);
end;
{
procedure wfcTerminalMode;
var terDone : Boolean; C : Char;
begin
   terDone := False;
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
   end;
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
   end;
   case curStat of
     1:
   begin
      fWrite(sa1,sy+0,'CPU processor',colLo);
      fWrite(sa1,sy+1,'Video display',colLo);
      fWrite(sa1,sy+2,'Overlay buffer',colLo);
      fWrite(sa1,sy+3,'Running under',colLo);

      case cpuType of
         cpu8088    : S := '8088';
         cpu8086    : S := '8086';
         cpu80286   : S := '80286';
         cpu80386   : S := '80386';
         cpu80486   : S := '80486';
         cpuPentium : S := 'Pentium';
         cpuFuture  : S := 'Unknown';
      end;
   oCWrite('|U2-- |U1Enter menu name to launch|U2: |U3');
   S := iReadString('',inUpper,chFilename,rsSpace+rsAbort,8);
   if (S = '') or (not fExists(Cfg^.pathMenu+S+'.MNU')) then
   begin
      menuLaunch := False;
      LocalMode := False;
      LocalIO := False;
      Exit;
   end;
   curMenu := S;
   logWrite('*Launched menu: "'+S+'"');
end;

procedure wfcReadEmail;
begin
   LocalMode := True;
   LocalIO := True;
   userReset;
   emailReadEmail(True,False);
   userSave(User^);
   LocalMode := False;
   LocalIO := False;
end;

procedure wfcViewMailbox;
begin
   LocalMode := True;
   LocalIO := True;
   oCWrite('|U2-- |U1View which user''s email|U2: |U3');
   User^.Username := iReadString('',inNormal,chNormal,rsSpace+rsAbort,36);
   if (User^.Username <> '') and (userSearch(User^,True)) then
   begin
      userLoad(User^);
      logWrite('*Checked '+User^.Username+'''s mailbox.');
      emailReadEmail(False,False);
      userSave(User^);
   end;
   LocalMode := False;
   LocalIO := False;
   userReset;
end;

procedure wfcEnterEmail;
begin
   LocalMode := True;
   LocalIO := True;
   userReset;
   emailEnterEmail('','',True);
   userSave(User^);
   LocalMode := False;
   LocalIO := False;
   userReset;
end;

procedure wfcEditTextfile;
var S : String;
begin
   LocalMode := True;
   LocalIO := True;
   userReset;
   oCWrite('|U2-- |U1Enter filename to edit|U2: |U3');
   S := iReadString('',inUpper,chDirectory,rsSpace+rsAbort,36);
   if S <> '' then
   begin
      maEditTextfile(S);
      userSave(User^);
   end;
   LocalMode := False;
   LocalIO := False;
   userReset;
end;

function wfcLocalCmd : Boolean;
begin
   wfcLocalCmd := ((Mnu = 1) and (Res in [2,3,8])) or
                  ((Mnu = 2) and (Res in [1..8])) or
                  ((Mnu = 3) and (Res in [1..8])) or
                  ((Mnu = 4) and (Res in [1..8])) or
                  ((Mnu = 5) and (Res in [1..1]));
end;

procedure wfcWaitForCall;
var S : String;
 procedure wfcAddScroll(add : String);
 var L : Byte;
 begin
    Add := Add+'    ';
    L := Length(add);
    if L+wfcL > maxScroll then L := maxScroll-wfcL;
    Move(Add[1],wfcScroll[wfcL+1],L);
    Inc(wfcL,L);
 end;
begin
   ioScreenOn;
   nodeUpdate('');
   NewUserOn := False;
   hisLoad;
   menuLaunch := False;
   timeCheck := False;
   if UserOn then Exit;
   logWrite('>Waiting for call');
   LocalIO := False;
   LocalMode := False;
   RemoteOut := True;
   RemoteIn := True;
   LoggedIn := False;
   HangUp := False;
   HungUp := False;
   ModemIO := not ModemOff;
   if not cNoCarrier then cHangUp;
   mClearScr(True);
{
   for ty := 1 to maxWfcItem do for tx := 1 to maxWfcCmds do
   begin
      pos := 1;
      while pos <= Length(wfcCom[ty,tx]) do
      begin
         if (pos = 1) or (wfcCom[ty,tx,pos-1] = ' ') then
         begin
            Insert('|02',wfcCom[ty,tx],pos);
            Insert('|08',wfcCom[ty,tx],pos+4);
         end;
         Inc(pos);
      end;
   end;
}
   Pos := 1;
   Mnu := 1;
   Res := 12;
   Saver := False;

   tX := 1; tY := 1;
   curStat := Cfg^.DefWFCstat;
   wfcFadefxInit;
   ansiWFCscreen;
   Window(terX1,terY1,terX2,terY2);
   TextAttr := $07;
   fIn := False;
   if ModemIO then
      while (CharWaiting(Modem^.ComPort)) and (not Keypressed) do ComReadChar(Modem^.ComPort);
   wfcInitModem;
   FillChar(wfcScroll,maxScroll,0);
   wfcL := 0;
   wfcN := 1;
   wfcAddScroll(sRepeat(' ',42));
   wfcAddScroll('== iniquity bbs version '+bbsVerLong+' ==');
   wfcAddScroll('(release '+bbsRelease+')');
   wfcAddScroll('(c)copyright 1994-1995, mike fricker; all rights reserved');
   wfcAddScroll('created by mike fricker (fiend)');
   wfcAddScroll('compiled with borland pascal 7.0');
   wfcAddScroll('internet email:');
   wfcAddScroll('daylight@ra.isisnet.com (iniqnet/comments/suggestions/bug-reports)');
   wfcAddScroll('ev@mcs.net (questions/help/bug-reports)');
   wfcAddScroll('015940B@axe.acadiau.ca (documentation comments/questions)');
   wfcAddScroll('thanks to:');
   wfcAddScroll('daylight (peter benson) - internet, testing & ideas');
   wfcAddScroll('electric visionary (todd hendricks) - testing & ideas');
   wfcAddScroll('blackball (chris bowlby) - ideas, testing & documentation');
   wfcAddScroll('illusionizer (mike annand) - ideas, ansi & distribution');
   wfcAddScroll('... as well as all those who''ve helped out with bug reports and ansi screens ...');
   wfcAddScroll('iniquity support boards:');
   wfcAddScroll('eternity bbs (902)469-4463 [iniquity world headquarters]');
   wfcAddScroll('sunfire bbs (902)445-4783 [alpha test site]');
   wfcAddScroll('disallusioned society (708)653-0376 [beta test site]');
   wfcAddScroll('internet ftp:');
   wfcAddScroll('ftp.isisnet.com (/pub/dos/bbs/iniquity)');
   wfcAddScroll('internet www:');
   wfcAddScroll('http://www.isisnet.com/iniquity');
   wfcAddScroll('== this is an alpha test copy of iniquity ==');
   repeat
       HangUp := False;
       ModemIO := not ModemOff;
       if Cfg^.VgaEffects then
       begin
          colItem := 1;
          colLo   := 5;
          colHi   := 4;
       end else
       begin
          colItem := 8;
          colLo   := 2;
          colHi   := 10;
       end;
       if wfcLocalCmd then
       begin
          wfcFadefxInit;
          mClearScr(True);
          ansiWFCscreen;
          Window(terX1,terY1,terX2,terY2);
          tX := 1;
          tY := 1;
          GotoXY(tX,tY);
          TextAttr := $07;
          fIn := False;
          wfcInitModem;
       end;
       Res := wfcGetSel(WFCCom, WFCConfig, Mnu);
       if not (Res in [11,12]) then userReset;
       if wfcLocalCmd then
       begin
          LocalIO := True;
          mClearScr(True);
          wfcFadefxNormal;
       end;
       if Mnu = 1 then case Res of

         1  : LocalMode := True;
         2  : begin
                 cModemWrite(Modem^.sExitStr);
                 killTerminateBBS;
              end;
         3  : fJumpToDOS(0);
         4  : wfcInitModem;
         5  : wfcHangupModem;
         6  : wfcOffHookModem;
         7  : wfcAnswerModem;
         8  : tmTerminalMode;

         12 : Mnu := 2;
       end else if Mnu = 2 then
       case Res of

         1  : cfgSystemConfig;
         2  : cfgCommunicationsSetup;
         3  : cfgStringEditor;
         4  : cfgMenuEditor;
         5  : dosExecuteMicroDOS;
         6  : cfgMsgAreaEditor;
         7  : maPackAreas(True,0);
         8  : cfgLevelEditor;

         11 : Mnu := 1;
         12 : Mnu := 3;
       end else if Mnu = 3 then
       case Res of

         1  : cfgProtocolEditor;
         2  : cfgUserEditor(1);
         3  : wfcLaunchMenu;
         4  : wfcReadEmail;
         5  : wfcViewMailbox;
         6  : wfcEnterEmail;
         7  : cfgFileAreaEditor;
         8  : wfcEditTextfile;

         11 : Mnu := 2;
         12 : Mnu := 4;
       end else if Mnu = 4 then
       case Res of

         1  : cfgArchiverEditor;
         2  : cfgConferenceEditor(False);
         3  : cfgConferenceEditor(True);
         4  : fsSortFileAreas('A');
         5  : cfgStatEditor;
         6  : cfgBbsListEditor;
         7  : cfgEventEditor;
         8  : cfgTextLibEditor;

         11 : Mnu := 3;
         12 : Mnu := 5;
       end else if Mnu = 5 then
       case Res of
         1  : cfgInfoformEditor;

         11 : Mnu := 4;
         12 : Mnu := 6;
       end else if Mnu = 6 then
       case Res of

         1,3..5,8 :
              begin
                 wfcFadeStatOut;
                 curStat := Res;
                 wfcDrawStats(True);
                 wfcFadeStatIn;
              end;

         11 : Mnu := 5;
       end;
       LocalIO := False;
   until (ModemIO) and (not cNoCarrier) or (LocalMode);
   if (LocalMode) and (Cfg^.OffhookLocal) then wfcOffhookModem;
   LocalIO := LocalMode;
   ModemIO := (not ModemOff) and (not LocalMode);
   UserOn := True;
   mClearScr(True);
   mClearScr(False);
   wfcFadefxNormal;
   TextAttr := $07;
   colAttr := $07;
end;

procedure wfcOnline(Bd : LongInt);
begin
   if Bd = 0 then
   begin
      RemoteOut := False;
      RemoteIn := False;
      LocalIO := True;
      ModemIO := False;
   end else
   begin
      RemoteOut := True;
      RemoteIn := True;
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
begin
   fWrite(9,23,Resize(Ttl[curStat],25),colHi);
   fWrite(44,23,st(curStat),$07);
   if (Cfg^.VGAeffects) or (Clear) then
   begin
      Window(sx,sy,51,18);
      TextAttr := $07;
      ClrScr;
      Window(terX1,terY1,terX2,terY2);
      GotoXY(tX,tY);
   end;
   case curStat of
     1:
   begin
      fWrite(sa1,sy+0,'CPU processor',colLo);
      fWrite(sa1,sy+1,'Video display',colLo);
      fWrite(sa1,sy+2,'Overlay buffer',colLo);
      fWrite(sa1,sy+3,'Running under',colLo);

      case cpuType of
         cpu8088    : S := '8088';
         cpu8086    : S := '8086';
         cpu80286   : S := '80286';
         cpu80386   : S := '80386';
         cpu80486   : S := '80486';
         cpuPentium : S := 'Pentium';
         cpuFuture  : S := 'Unknown';
      end;
