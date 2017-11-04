{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit ShowFile;

interface

procedure sfClearPos(P : Byte; L : Byte);
procedure sfClearPosList;
procedure sfFailLight(X : Byte);
function  sfGetTextFile(Fn : String; Ft : Byte) : String;
function  sfGotoPos(P : Byte) : Boolean;
function  sfGotoPos2(P : Byte) : Boolean;
procedure sfKillRepeat;
function  sfLoadRepeat(Fn : String) : Boolean;
procedure sfLight(X : Byte);
procedure sfOkLight(X : Byte);
procedure sfSetPos(P : Byte);
function  sfShowFile(Fn : String; Ft : Byte) : Boolean;
function  sfShowRepeat(Ft : Byte) : Boolean;
function  sfShowTextFile(Fn : String; Ft : Byte) : Boolean;
procedure sfWrite(Z : Byte);

implementation

uses Dos,
     Global, Output, Input, Files, Strings, MCIcodes, Emulate, Comm, FastIO,
     Users, FileArea, Infoform;

var mciLimit : Byte; mciPad : Boolean;

procedure sfSetPos(P : Byte);
begin
   sfPos[P].C := Col;
   sfPos[P].X := oWhereX;
   sfPos[P].Y := oWhereY;
   sfPos[P].Ok := True;
end;

procedure sfSetPos2(P : Byte);
begin
   sfPos2[P].C := Col;
   sfPos2[P].X := oWhereX;
   sfPos2[P].Y := oWhereY;
   sfPos2[P].Ok := True;
end;

function sfGotoPos(P : Byte) : Boolean;
begin
   sfGotoPos := sfPos[P].Ok;
   if not sfPos[P].Ok then Exit;
   oGotoXY(sfPos[P].X,sfPos[P].Y);
   oSetColRec(sfPos[P].C);
end;

function sfGotoPos2(P : Byte) : Boolean;
begin
   sfGotoPos2 := sfPos2[P].Ok;
   if not sfPos2[P].Ok then Exit;
   oGotoXY(sfPos2[P].X,sfPos2[P].Y);
   oSetColRec(sfPos2[P].C);
end;

procedure sfClearPos(P : Byte; L : Byte);
begin
   if not sfPos[P].Ok then Exit;
   oGotoXY(sfPos[P].X,sfPos[P].Y);
   oSetColRec(sfPos[P].C);
   oWrite(sRepeat(' ',L));
   oMoveLeft(L);
end;

procedure sfClearPosList;
var Z : Byte;
begin
   for Z := 1 to maxPos do with sfPos[Z] do
   begin
      Ok := False;
      X := 1;
      Y := 1;
      C := User^.Color[colInfo];
   end;
   for Z := 1 to maxPos do with sfPos2[Z] do
   begin
      Ok := False;
      X := 1;
      Y := 1;
      C := User^.Color[colInfo];
   end;
end;

procedure sfWrite(Z : Byte);
begin
   if mciPad then oStrCtr(Resize(sfStr[Z],mciLimit)) else
               oStrCtr(strSquish(sfStr[Z],mciLimit));
end;

procedure sfWriteStr(S : String);
begin
   if mciPad then oStrCtr(Resize(S,mciLimit)) else
               oStrCtr(strSquish(S,mciLimit));
end;

procedure sfLight(X : Byte);
begin
   if sfGotoPos(X) then oWriteChar(Cfg^.lightChar);
end;

procedure sfOkLight(X : Byte);
begin
   if sfGotoPos(X) then
   begin
      oSetBlink(False);
      oWriteChar(Cfg^.lightCharOk);
   end;
end;

procedure sfFailLight(X : Byte);
begin
   if sfGotoPos(X) then
   begin
      oSetBlink(False);
      oWriteChar(Cfg^.lightCharFail);
   end;
end;

function sfExists(fs : String; var fz : Word) : Boolean;
var z : Word; nfs : String;
begin
   fz := 0;
   sfExists := False;
   nfs := UpStr(strFilename(fs));
   if (Cfg^.useTextLibs) and (tLibOpen) then
   begin
      z := 0;
      while (z < textLib^.numLib) and (fz = 0) do
      begin
         Inc(z);
         if nfs = textLib^.Index[z].Filename then fz := z;
      end;
   end;
   if (fz <> 0) or (fExists(fs)) then sfExists := True;
end;

function sfGetTextFile(Fn : String; Ft : Byte) : String;
var S : String; Year,Month,Day,DayOfWeek, fz : Word;
    I,J : Integer; Dot : Boolean;
begin
   if ft <> ftNormal then repSize := 0;
   ansiRows := 0;
   Fn := UpStr(Fn);
   if Pos('\',Fn) = 0 then Insert(Cfg^.pathText,Fn,1);
   Dot := Pos('.',Fn) > 0;
   if not Dot then
   begin
      if (acRIP in User^.acFlag)    and (sfExists(Fn+'.RIP',fz)) and (Ft = ftNormal)
                                                              then Fn := Fn+'.RIP' else
      if (acAVATAR in User^.acFlag) and (sfExists(Fn+'.AVT',fz)) then Fn := Fn+'.AVT' else
      if (acANSI in User^.acFlag)   and (sfExists(Fn+'.ANS',fz)) then Fn := Fn+'.ANS' else
                                     if (sfExists(Fn+'.ASC',fz)) then Fn := Fn+'.ASC';
   end;
   S := Fn;
   if Copy(Fn,Length(Fn)-3,4) = '.ANS' then
   begin
      if sfExists(Copy(Fn,1,Length(Fn)-4)+'.AN1',fz) then
      repeat
         I := Random(10);
         if I = 0 then Fn := Copy(Fn,1,Length(Fn)-4)+'.ANS' else
                       Fn := Copy(Fn,1,Length(Fn)-4)+'.AN'+St(I);
      until sfExists(Fn,fz);
      GetDate(Year,Month,Day,DayOfWeek);
      S := Fn;
      S[Length(S)-1] := Chr(DayOfWeek+48);
      if sfExists(S,fz) then Fn := S;
   end;
   if not sfExists(Fn,fz) then Fn := '';
   sfGetTextFile := Fn;
end;

function sfShowFile(Fn : String; Ft : Byte) : Boolean;
const ansiBuf = 4096;
var aBuf : array[1..ansiBuf] of Char;
    sRead, tRead : LongInt;
    Read, X : Integer;
    Buf : array[1..3] of Char;
    Code, topY, infLim : Byte;
    Cs : String;
    okMci, lib, infMin : Boolean;
    fz : Word;
    F : file;
begin
   sfShowFile := False;
   fn := UpStr(fn);
{  if ft <> ftNormal then sfClearPosList;}
   infLim := 254;
   fz := 0;
   if (fn[1] = #0) and (fn[2] = #0) then fz := strToInt(Copy(fn,3,255));
   if fz > 0 then
   begin
      Seek(tLibFile,textLib^.Index[fz].filePos);
      sRead := textLib^.Index[fz].fileSize;
      lib := True;
   end else
   begin
      Assign(F,Fn);
      {$I-}
      Reset(F,1);
      {$I+}
      lib := False;
      if ioResult <> 0 then Exit;
      sRead := FileSize(F);
   end;
   emuANSIinit;
   FillChar(Buf,3,0);
   Code := 0;
   tRead := 0;
   posUpdate := False;
   mciPad := False;
   mciLimit := 255;
   infMin := False;
   topY := oWhereY;
   while (ioResult = 0) and (tRead < sRead) do
   begin
      {$I-}
      if lib then BlockRead(tLibFile,aBuf,ansiBuf,Read) else
                  BlockRead(F,aBuf,ansiBuf,Read);
      {$I+}
      Inc(tRead,Read);
      if tRead > sRead then Dec(Read,tRead-sRead);
      for X := 1 to Read do
      begin
         Move(Buf[2],Buf[1],2);
         Buf[3] := aBuf[X];
         if Buf[1] <> #0 then
         if (Buf[1] = '*') and (Code = 0) and (ft = ftInfoform) then ifReadString('',infLim,infMin) else
         if (Buf[1] = '*') and (Code = 0) and (ft = ftInfoDisp) then ifPutString(#0) else
         if (Buf[1] in [limHeader,padHeader,posHeader,rowHeader,mciHeader,ctrHeader,extHeader,ex2Header]) and
            (UpCase(Buf[2]) in ['A'..'Z','0'..'9','*']) and
            (Code = 0) and (ft <> ftNoCode) then
         begin
            okMci := Buf[1] = extHeader;
            Code := 2;
            Cs := UpStr(Buf[2])+UpStr(Buf[3]);
            case Buf[1] of
              limHeader : begin mciPad := False; mciLimit := StrToInt(Cs); end;
              padHeader : begin mciPad := True;  mciLimit := StrToInt(Cs); end;
              posHeader : oPosX(strToInt(Cs));
              rowHeader : oPosY(strToInt(Cs));
              mciHeader : if mciProcessMCICode(Buf) then sfWriteStr(mciString) else
                          begin
                             oWriteANSi(Buf[1]);
                             Code := 0;
                          end;
              ctrHeader : if not mciProcessControlCode(Buf) then
                          begin
                             oWriteANSi(Buf[1]);
                             Code := 0;
                          end;
              ex2Header : if (Cs[1] in ['0'..'9']) and (Cs[2] in ['0'..'9']) then sfSetPos2(strToInt(Cs));
              extHeader : case ft of
             ftLightBar : if Cs = 'HP' then sfSetPos(maxPos-1) else
                          if (Cs[1] in ['0'..'9']) and (Cs[2] in ['0'..'9']) then sfSetPos(strToInt(Cs));
           ftUserConfig : if Cs = '**' then sfSetPos(maxPos-1) else
                          if Cs = '*A' then sfSetPos(maxPos-2) else
                          if (Cs[1] in ['A'..'Z']) then
                          begin
                             userCfg[Cs[1]] := UpCase(Cs[2]);
                             sfSetPos(Ord(Cs[1])-64);
                          end;
             ftChatMode : case Cs[1] of
                       'S' : case Cs[2] of
                         'T' : sfSetPos(1);
                         'B' : sfSetPos(2);
                         end;
                       'U' : case Cs[2] of
                         'T' : sfSetPos(3);
                         'B' : sfSetPos(4);
                         end;
                       end;
                ftLogin : case Cs[1] of
                       'L' : case Cs[2] of
                         'N' : sfSetPos(1);
                         'P' : sfSetPos(2);
                         'I' : sfSetPos(3);
                         'H' : sfSetPos(4);
                       end;
                    end;
              ftFsHeader : if Cs = 'MT' then sfSetPos(1) else
                           if Cs = 'SN' then sfSetPos(2) else
                           if Cs = 'RN' then sfSetPos(3) else
                           if Cs = 'DT' then sfSetPos(4) else
                           if Cs = 'TI' then sfSetPos(5) else
                           if Cs = 'CM' then sfSetPos(6) else
                           if Cs = 'TL' then sfSetPos(7) else
                           if Cs = 'BL' then sfSetPos(8) else
                           if Cs = 'AN' then sfSetPos(9) else
                           if Cs = 'AS' then sfSetPos(10) else
                           if Cs = 'IN' then sfSetPos(11) else
                           if Cs = 'LN' then sfSetPos(12) else
                           if Cs = 'CN' then sfSetPos(13) else
                           if Cs = 'SL' then sfSetPos(14);
               ftAutoMsg : if Cs = 'MT' then sfWrite(1) else
                           if Cs = 'SN' then sfWrite(2) else
                           if Cs = 'TL' then sfSetPos(3);
                ftAddBBS : if Cs = 'BN' then sfSetPos(1) else
                           if Cs = 'PN' then sfSetPos(2) else
                           if Cs = 'SN' then sfSetPos(3) else
                           if Cs = 'BR' then sfSetPos(4) else
                           if Cs = 'SF' then sfSetPos(5) else
                           if Cs = 'ST' then sfSetPos(6) else
                           if Cs = 'IN' then sfSetPos(7) else
                           if Cs = 'OT' then sfSetPos(8);
               ftTopLine : if Cs = 'TL' then sfSetPos(1);
             ftListFiles : if Cs = 'TL' then sfSetPos(1) else
                           if Cs = 'BL' then sfSetPos(2) else
                           if Cs = 'PM' then sfSetPos(3) else
                           if Cs = 'PI' then sfSetPos(4) else

                           if Cs = 'FI' then sfSetPos(5) else
                           if Cs = 'FN' then sfSetPos(6) else
                           if Cs = 'FS' then sfSetPos(7) else
                           if Cs = 'FP' then sfSetPos(8) else
                           if Cs = 'FD' then sfSetPos(9) else
                           if Cs = 'FT' then sfSetPos(10) else

                           if Cs = 'C1' then sfSetPos(11) else
                           if Cs = 'C2' then sfSetPos(12) else
                           if Cs = 'C3' then sfSetPos(13) else
                           if Cs = 'C4' then sfSetPos(14) else
                           if Cs = 'C5' then sfSetPos(15) else
                           if Cs = 'C6' then sfSetPos(16) else
                           if Cs = 'FA' then sfWrite(1) else
                           if Cs[1] = 'S' then
                           begin
                              userCfg['A'] := UpCase(Cs[2]);
                              sfSetPos(17);
                           end else
                           if Cs[1] = 'E' then
                           begin
                              userCfg['B'] := UpCase(Cs[2]);
                              sfSetPos(18);
                           end;
             ftMsgHeader : if Cs = 'TI' then sfWrite(1) else
                           if Cs = 'DT' then sfWrite(2) else
                           if Cs = 'SN' then sfWrite(3) else
                           if Cs = 'RN' then sfWrite(4) else
                           if Cs = 'MT' then sfWrite(5) else
                           if Cs = 'MN' then sfWrite(6) else
                           if Cs = 'MA' then sfWrite(7) else
                           if Cs = 'RP' then sfWrite(8) else
                           if Cs = 'ST' then sfWrite(9) else
                           if Cs = 'UN' then sfWrite(10) else
                           if Cs = 'TL' then sfSetPos(11);
               ftBBSlist : if Cs = 'BN' then sfWrite(1) else
                           if Cs = 'PN' then sfWrite(2) else
                           if Cs = 'SN' then sfWrite(3) else
                           if Cs = 'BR' then sfWrite(4) else
                           if Cs = 'SF' then sfWrite(5) else
                           if Cs = 'ST' then sfWrite(6) else
                           if Cs = 'IN' then sfWrite(7) else
                           if Cs = 'NM' then sfWrite(8);
                 ftQwkDL : if Cs = 'LC' then sfSetPos(1) else
                           if Cs = 'LD' then sfSetPos(2) else
                           if Cs = 'LE' then sfSetPos(3) else
                           if Cs = 'LI' then sfSetPos(4) else
                           if Cs = 'LZ' then sfSetPos(5) else
                           if Cs = 'MA' then sfSetPos(6) else
                           if Cs = 'MS' then sfSetPos(7) else
                           if Cs = 'NM' then sfSetPos(8) else
                           if Cs = 'TS' then sfSetPos(9) else
                           if Cs = 'EA' then sfSetPos(10) else
                           if Cs = 'TN' then sfSetPos(11);
                 ftQwkUL : if Cs = 'LU' then sfSetPos(1) else
                           if Cs = 'LP' then sfSetPos(2) else
                           if Cs = 'LS' then sfSetPos(3) else
                           if Cs = 'MA' then sfSetPos(4) else
                           if Cs = 'TM' then sfSetPos(5) else
                           if Cs = 'SN' then sfSetPos(6) else
                           if Cs = 'RN' then sfSetPos(7) else
                           if Cs = 'MT' then sfSetPos(8);
              ftFileTest : if Cs = 'FN' then sfWrite(1) else
                           if Cs = 'FS' then sfWrite(2) else
                           if Cs = 'PI' then sfSetPos(3) else
                           if Cs = 'L0' then sfSetPos(5) else
                           if Cs = 'L1' then sfSetPos(6) else
                           if Cs = 'L2' then sfSetPos(7) else
                           if Cs = 'L3' then sfSetPos(8) else
                           if Cs = 'L4' then sfSetPos(9) else
                           if Cs = 'L5' then sfSetPos(10) else
                           if Cs = 'L6' then sfSetPos(11) else
                           if Cs = 'L7' then sfSetPos(12) else
                           if Cs = 'L8' then sfSetPos(13) else
                           if Cs = 'L9' then sfSetPos(14);
                ftTetris : if Cs = 'TL' then sfSetPos(1) else
                           if Cs = 'BR' then sfSetPos(2) else
                           if Cs = 'SC' then sfSetPos(3) else
                           if Cs = 'LN' then sfSetPos(4) else
                           if Cs = 'LV' then sfSetPos(5);
              ftNodeList : if Cs = 'ND' then sfWrite(1) else
                           if Cs = 'UN' then sfWrite(2) else
                           if Cs = 'RN' then sfWrite(3) else
                           if Cs = 'ID' then sfWrite(4) else
                           if Cs = 'BR' then sfWrite(5) else
                           if Cs = 'TO' then sfWrite(6) else
                           if Cs = 'ST' then sfWrite(7);
              ftInfoform : if (Cs[1] in ['0'..'9']) and (Cs[2] in ['0'..'9']) then infLim := strToInt(Cs) else
                           if Cs = '*-' then infMin := False else
                           if Cs = '*=' then infMin := True else
                           if Cs = '**' then infLim := 254 else
                           ifReadString(Cs,infLim,infMin);
              ftInfoDisp : ifPutString(Cs);
                   ftNuv : if Cs = 'UN' then sfWrite(1) else
                           if Cs = 'YV' then sfWrite(2) else
                           if Cs = 'NV' then sfWrite(3) else
                           if Cs = 'YN' then sfWrite(4) else
                           if Cs = 'NN' then sfWrite(5) else
                           if (Cs[1] in ['0'..'1']) and (Cs[2] in ['0'..'9']) and
                              (cs <> '00') and (strToInt(cs) <= 12) then sfWrite(5+strToInt(cs));
              ftFileInfo : if Cs = 'FN' then sfWrite(1) else
                           if Cs = 'DL' then sfWrite(2) else
                           if Cs = 'SZ' then sfWrite(3) else
                           if Cs = 'UL' then sfWrite(4) else
                           if Cs = 'DT' then sfWrite(5) else
                           if Cs = 'UD' then sfWrite(6) else
                           if Cs = 'TM' then sfWrite(7) else
                           if Cs = 'FP' then sfWrite(8) else
                           if (Cs[1] in ['0'..'9']) and (Cs[2] in ['0'..'9'])
                              and (strToInt(Cs) > 0) and (strToInt(Cs) <= maxDescLns) then
                              begin
                                 if strToInt(Cs) <= nDescLns then sfWriteStr(pDesc^[strToInt(Cs)]) else
                                 if strToInt(Cs) = 1 then sfWriteStr('No description');
                              end;
               end;
              else begin oWriteANSi(Buf[1]); okMci := False; end;
            end;
         end else if Code = 0 then oWriteANSi(Buf[1]) else Dec(Code);
      end;
   end;
   if Code = 0 then oWriteANSi(Buf[2]) else Dec(Code);
   if (Code = 0) and (Buf[3] <> #26) then oWriteANSi(Buf[3]);
   ioUpdatePos;
   if not Lib then Close(F);
   sfSetPos(maxPos);
   Read := oWhereY;
   if Read < topY then topY := 1;
   Read := Read-topY+1;
   if Read < 0 then Read := 0;
   ansiRows := Read;
   if ft <> ftNoCode then FillChar(sfStr,SizeOf(sfStr),0);
{  oWriteRem(#0#0#0);}
   sfShowFile := True;
end;

function sfShowTextFile(Fn : String; Ft : Byte) : Boolean;
var fz : Word;
begin
   sfShowTextFile := False;
   cCheckIt;
   if ft <> ftNormal then sfClearPosList;
   if HangUp then Exit;
   Fn := sfGetTextFile(Fn,Ft);
   if Fn = '' then Exit;
   if sfExists(Fn,fz) then
   begin
      if fz > 0 then Fn := #0#0+St(fz);
      sfShowTextFile := sfShowFile(Fn,Ft);
   end else sfShowTextFile := False;
end;

function sfLoadRepeat(Fn : String) : Boolean;
var Z : LongInt; fz : Word; F : file; lib : boolean;
begin
   sfLoadRepeat := False;
   repSize := 0;
   Fn := sfGetTextFile(Fn,0);
   if Fn = '' then Exit;
   if not sfExists(Fn,fz) then Exit;
   if fz > 0 then
   begin
      Seek(tLibFile,textLib^.Index[fz].filePos);
      Z := textLib^.Index[fz].fileSize;
      lib := True;
   end else
   begin
      Assign(F,Fn);
      {$I-}
      Reset(F,1);
      {$I+}
      if ioResult <> 0 then Exit;
      Z := FileSize(F);
      lib := False;
   end;
   if Z > maxRepeatBuf then Z := maxRepeatBuf;
   if Z = 0 then Exit;
   GetMem(repAnsi,Z);
   repSize := Z;
   {$I-}
   if lib then BlockRead(tLibFile,repAnsi^,Z) else
               BlockRead(F,repAnsi^,Z);
   {$I+}
   if not lib then Close(F);
   sfLoadRepeat := repSize > 0;
end;

procedure sfKillRepeat;
begin
   if repSize > 0 then FreeMem(repAnsi,repSize);
end;

function sfShowRepeat(Ft : Byte) : Boolean;
var Buf : array[1..3] of Char; X : Word;
    Code, topY : Byte;
    Cs : String;
    okMci : Boolean;
begin
   sfShowRepeat := False;
   if repSize < 1 then Exit;
   emuANSIinit;
   FillChar(Buf,3,0);
   Code := 0;
   posUpdate := False;
   mciPad := False;
   mciLimit := 255;
   for X := 1 to repSize do
   begin
      Move(Buf[2],Buf[1],2);
      Buf[3] := Char(repAnsi^[X]);
      if Buf[1] <> #0 then
      if (Buf[1] in [limHeader,padHeader,posHeader,rowHeader,mciHeader,ctrHeader,extHeader]) and
         (UpCase(Buf[2]) in ['A'..'Z','0'..'9','*']) then
      begin
         okMci := Buf[1] = extHeader;
         Code := 2;
         Cs := UpStr(Buf[2])+UpStr(Buf[3]);
         case Buf[1] of
           limHeader : begin mciPad := False; mciLimit := StrToInt(Cs); end;
           padHeader : begin mciPad := True;  mciLimit := StrToInt(Cs); end;
           posHeader : oPosX(strToInt(Cs));
           rowHeader : oPosY(strToInt(Cs));
           mciHeader : if mciProcessMCICode(Buf) then sfWriteStr(mciString) else
                       begin oWriteANSi(Buf[1]); Code := 0; end;
           ctrHeader : if not mciProcessControlCode(Buf) then
                       begin oWriteANSi(Buf[1]); Code := 0; end;
           extHeader : case Ft of
               ftBBSlist : if Cs = 'BN' then sfWrite(1) else
                           if Cs = 'PN' then sfWrite(2) else
                           if Cs = 'SN' then sfWrite(3) else
                           if Cs = 'BR' then sfWrite(4) else
                           if Cs = 'SF' then sfWrite(5) else
                           if Cs = 'ST' then sfWrite(6) else
                           if Cs = 'IN' then sfWrite(7) else
                           if Cs = 'NM' then sfWrite(8);
             ftLastCalls : if Cs = 'CN' then sfWrite(1) else
                           if Cs = 'UN' then sfWrite(2) else
                           if Cs = 'NM' then sfWrite(3) else
                           if Cs = 'LO' then sfWrite(4) else
                           if Cs = 'BR' then sfWrite(5) else
                           if Cs = 'DT' then sfWrite(6) else
                           if Cs = 'TI' then sfWrite(7) else
                           if Cs = 'NU' then sfWrite(8) else
                           if Cs = 'AC' then sfWrite(9);
              ftUserList : if Cs = 'ID' then sfWrite(1) else
                           if Cs = 'UN' then sfWrite(2) else
                           if Cs = 'RN' then sfWrite(3) else
                           if Cs = 'LC' then sfWrite(4) else
                           if Cs = 'UC' then sfWrite(5) else
                           if Cs = 'SL' then sfWrite(6) else
                           if Cs = 'DS' then sfWrite(7) else
                           if Cs = 'NT' then sfWrite(8) else
                           if Cs = 'LO' then sfWrite(9) else
                           if Cs = 'BR' then sfWrite(10) else
                           if Cs = 'SX' then sfWrite(11) else
                           if Cs = 'AC' then sfWrite(12);
             ftListMarea : if Cs = 'AT' then sfWrite(1) else
                           if Cs = 'AN' then sfWrite(2) else
                           if Cs = 'NM' then sfWrite(3) else
                           if Cs = 'SP' then sfWrite(4);
             ftListFarea : if Cs = 'AT' then sfWrite(1) else
                           if Cs = 'AN' then sfWrite(2) else
                           if Cs = 'NF' then sfWrite(3) else
                           if Cs = 'SP' then sfWrite(4);
              ftListMail : if Cs = 'MT' then sfWrite(1) else
                           if Cs = 'SN' then sfWrite(2) else
                           if Cs = 'RN' then sfWrite(3) else
                           if Cs = 'TI' then sfWrite(4) else
                           if Cs = 'DT' then sfWrite(5) else
                           if Cs = 'MN' then sfWrite(6);
               ftListMsg : if Cs = 'MN' then sfWrite(1) else
                           if Cs = 'SN' then sfWrite(2) else
                           if Cs = 'RN' then sfWrite(3) else
                           if Cs = 'TI' then sfWrite(4) else
                           if Cs = 'DT' then sfWrite(5) else
                           if Cs = 'MT' then sfWrite(6);
              ftListProt : if Cs = 'KY' then sfWrite(1) else
                           if Cs = 'PN' then sfWrite(2) else
                           if Cs = 'PT' then sfWrite(3) else
                           if Cs = 'NM' then sfWrite(4);
                  ftConf : if Cs = 'CK' then sfWrite(1) else
                           if Cs = 'CN' then sfWrite(2);
              ftArchiver : if Cs = 'NM' then sfWrite(1) else
                           if Cs = 'FN' then sfWrite(2) else
                           if Cs = 'SU' then sfWrite(3) else
                           if Cs = 'SC' then sfWrite(4) else
                           if Cs = 'RA' then sfWrite(5) else
                           if Cs = 'CM' then sfWrite(6) else
                           if Cs = 'DT' then sfWrite(7) else
                           if Cs = 'TI' then sfWrite(8);
               ftHiScore : if Cs = 'NM' then sfWrite(1) else
                           if Cs = 'UN' then sfWrite(2) else
                           if Cs = 'LV' then sfWrite(3) else
                           if Cs = 'LN' then sfWrite(4) else
                           if Cs = 'SC' then sfWrite(5);
              ftInfoList : if Cs = 'NM' then sfWrite(1) else
                           if Cs = 'DS' then sfWrite(2) else
                           if Cs = 'ST' then sfWrite(3) else
                           if Cs = 'CP' then sfWrite(4);
               ftCmdHelp : if Cs = 'KY' then sfWrite(1) else
                           if Cs = 'HL' then sfWrite(2) else
                           if Cs = 'DS' then sfWrite(3);
                  else begin oWriteANSi(Buf[1]); okMci := False; end;
                       end;
         end;
      end else if Code = 0 then oWriteANSi(Buf[1]) else Dec(Code);
   end;
   if Code = 0 then oWriteANSi(Buf[2]) else Dec(Code);
   if (Code = 0) and (Buf[3] <> #26) then oWriteANSi(Buf[3]);
   ioUpdatePos;
   sfShowRepeat := True;
end;

end.