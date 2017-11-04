{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Terminal;

interface

procedure tmResetPhone;
procedure tmTerminalMode;

implementation

uses Crt,
     Global, FastIO, Strings, Fossil, Emulate, Comm, Files, Transfer, Logs,
     Misc;

const
   tmBufSize = 30;
   maxPhone  = 50;
   maxWin    = 10;

type
   tBBSrec = record
      Desc     : String[30];
      PhoneNum : String[20];
      Password : String[20];
   end;

   tWinBuf = array[1..2000] of Word;
   pWinBuf = ^tWinBuf;

   tWinRec = record
      x1, y1, x2, y2 : Byte;
      Win : pWinBuf;
   end;

   pPhone = ^tPhone;
   tPhone = array[1..maxPhone] of record
      Desc : String[30];
      PhoneNum : String[20];
   end;

var
   tmBuf : array[1..tmBufSize] of Char;
   tmDone : Boolean;
   tmWin : array[1..maxWin] of tWinRec;
   Ch : Char;
   scrPtr : pWinBuf;
   BBS : tBBSrec;
   Phone : pPhone;
   numBBS : Word;
   numWin : Word;
   wx, wy : Byte;

function tmCol(C : Byte) : Byte;
begin
   tmCol := ioGetAttr(Cfg^.DefaultCol[C].Fore,Cfg^.DefaultCol[C].Back,
                      Cfg^.DefaultCol[C].Blink);
end;

procedure tmSaveWin(xx1,yy1,xx2,yy2 : Byte);
var Y, W, H : Word; Adr : Integer;
begin
   if numWin >= maxWin then Exit;
   Inc(numWin);
   with tmWin[numWin] do
   begin
      x1 := xx1;
      y1 := yy1;
      x2 := xx2;
      y2 := yy2;
      W := x2-x1+1;
      H := y2-y1+1;
      GetMem(Win,W*H*2);
      for Y := y1 to y2 do
         Move(scrPtr^[Y*80-80+x1],Win^[(Y-y1+1)*W-W+1],W*2);
   end;
end;

procedure tmRestoreWin;
var Y, W, H : Word;
begin
   if numWin < 1 then Exit;
   with tmWin[numWin] do
   begin
      W := x2-x1+1;
      H := y2-y1+1;
      for Y := y1 to y2 do
         Move(Win^[(Y-y1+1)*W-W+1],scrPtr^[Y*80-80+x1],W*2);
      FreeMem(Win,W*H*2);
   end;
   Dec(numWin);
end;

procedure tmOpenWin(x1,y1,x2,y2 : Byte);
const Blank : record C, A : Byte; end = (C:32;A:$07);
var C, Y : Byte;
begin
   tmSaveWin(x1,y1,x2,y2);
   for Y := y1 to y2 do mFillWord(scrPtr^[Y*80-80+x1],(x2-x1+1),Word(Blank));
   C := tmCol(colBorder);
   fWrite(x1,y1,'/-Ä',C);
   fWrite(x2-2,y1,'--\',C);
   fWrite(x1,y2,'\-Ä',C);
   fWrite(x2-2,y2,'--/',C);
   fWrite(x1+3,y1,sRepeat('Ä',(x2-x1+1)-6),C);
   fWrite(x1+3,y2,sRepeat('Ä',(x2-x1+1)-6),C);
   fWrite(x1,y1+1,':',C);
   fWrite(x1,y2-1,':',C);
   fWrite(x2,y1+1,':',C);
   fWrite(x2,y2-1,':',C);
   for Y := y1+2 to y2-2 do fWrite(x1,Y,'³',C);
   for Y := y1+2 to y2-2 do fWrite(x2,Y,'³',C);
   wx := tmWin[numWin].x1+2;
   wy := tmWin[numWin].y1+1;
end;

procedure tmOnWin(Msg : String; Wait : Boolean);
var P : Byte;
begin
   P := 40-(Length(Msg) div 2)-2;
   tmOpenWin(P-1,8,P+Length(Msg)+4,12);
   fWrite(P+2,10,Msg,tmCol(1));
   if not Wait then Exit;
   ReadKey;
   while Keypressed do ReadKey;
   tmRestoreWin;
end;

function tmBufStr(S : String) : Boolean;
var N : Word; OK : Boolean;
begin
   OK := True;
   for N := 1 to Length(S) do if tmBuf[tmBufSize-Length(S)+N-1] <> S[N] then OK := False;
   tmBufStr := OK;
end;

procedure tmWrite(S : String);
begin
   ComWrite(Modem^.ComPort,S);
end;

procedure tmDownload;
begin
   fCreateDir(Cfg^.pathDnld,False);
{  xferReceive('',6);}
   Move(tmBuf[2],tmBuf[1],tmBufSize-1);
   tmBuf[3] := #0;
end;

procedure tmCheckBuffer;
begin
   if tmBufStr(#27+'[6n') then tmWrite(#27+'['+St(ioWhereY)+';'+St(ioWhereY)+'R');
{  if tmBufStr('rz'+#13+'**') then tmDownload;}
end;

procedure tmClrScr;
begin
   emuANSiInit;
   ioTextAttr($07);
   ioClrScr;
   FillChar(tmBuf,tmBufSize,0);
end;

procedure tmHangUp;
begin
   tmOnWin('Hanging up',False);
   cHangUp;
   tmRestoreWin;
end;

procedure tmJumpToDOS;
begin
   fShellDos('',True,False,False);
end;

procedure tmInitModem;
begin
   cModemWrite(Modem^.sInit1);
   cModemWrite(Modem^.sInit2);
   cModemWrite(Modem^.sInit3);
end;

procedure tmLoadBBS(Num : Word);
var F : file of tBBSrec;
begin
   Assign(F,Cfg^.pathData+filePhoneBook);
    if Z = 0 then Z := 1;
    if Ps = Z then Exit;
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Seek(F,Num-1);
   Read(F,BBS);
   cModemWrite(Modem^.sInit1);
   cModemWrite(Modem^.sInit2);
   cModemWrite(Modem^.sInit3);
   Close(F);
end;

procedure tmSaveBBS(Num : Word);
var F : file of tBBSrec;
begin
   Assign(F,Cfg^.pathData+filePhoneBook);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Seek(F,Num-1);
   Write(F,BBS);
   Close(F);
end;

procedure tmSortBBSs;
var fD : file of tBBSrec;
    bubblesortend : Integer;
    Temp : tBBSrec;
    I : LongInt;

function Precedes (A, B : tBBSrec) : boolean;
begin
   Precedes := A.Desc < B.Desc;
end;

procedure Swap (Index1, Index2 : Integer; Temp1, Temp2 : tBBSrec);
    begin {Swap}
        Seek (fD, Index1);
        Write (fD, Temp2);
        Seek (fD, Index2);
        Write (fD, Temp1);
    end; {Swap}
procedure ShellSortInsertion (NumVals : Integer);
var
    EleDist : Integer;
    Temp1, Temp2 : tBBSrec;
    procedure SegmentedInsertion (N, K : Integer);
    var
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
begin {ShellSortInsertion}
    EleDist :=  NumVals div 2;
    while EleDist > 0 do
        begin
            SegmentedInsertion (NumVals, EleDist);
            EleDist := EleDist div 2;
        end;
end; {ShellSortInsertion}

begin
   Assign(fD,Cfg^.pathData+filePhoneBook);
   {$I-}
   Reset(fD);
   {$I+}
   if ioResult <> 0 then Exit;
   ShellSortInsertion(FileSize(fD));
   Close(fD);
end;

procedure tmResetPhone;
var F : file of tBBSrec;
begin
   Assign(F,Cfg^.pathData+filePhoneBook);
   {$I-}
   Rewrite(F);
   {$I+}
   FillChar(BBS,SizeOf(BBS),0);
   if ioResult <> 0 then Exit;
   with BBS do
   begin
      Desc := 'Eternity [iniquity whq]';
      PhoneNum := '902-469-4463';
      Password := '';
   end;
   Write(F,BBS);
   FillChar(BBS,SizeOf(BBS),0);
   with BBS do
   begin
      Desc := 'Sunfire [alpha]';
      PhoneNum := '902-445-5171';
      Password := '';
   end;
   Write(F,BBS);
   Close(F);
end;

procedure tmReadPhone;
var F : file of tBBSrec; B : tBBSrec;
begin
   numBBS := 0;
   Assign(F,Cfg^.pathData+filePhoneBook);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      tmResetPhone;
      {$I-}
      Reset(F);
      {$I+}
      if ioResult <> 0 then Exit;
   end;
   while not Eof(F) do
   begin
      Read(F,B);
      Inc(numBBS,1);
      with Phone^[numBBS] do
      begin
         Desc := B.Desc;
         PhoneNum := B.PhoneNum;
      end;
   end;
   Close(F);
end;

function tmReadString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte) : String;
var
   Ch      : Char;
   Done    : Boolean;
   Ins     : Boolean;
   S       : String;
   Ps      : Byte;
   Sze     : Byte;
   Int     : Integer;

   Password : Boolean;
   NoCR     : Boolean;
   NoIns    : Boolean;
   NoEdit   : Boolean;
   Min      : Boolean;
   Space    : Boolean;
   Req      : Boolean;
   NoClean  : Boolean;
   Abort    : Boolean;
   Backgr   : Boolean;

 procedure UpdateString(Add : Boolean);
 begin
    ioWrite(Copy(S,Ps,255));
    if Add then
    begin
       ioWrite(' ');
       ioGotoXY(ioWhereX-(Sze-Ps+1),ioWhereY);
    end else ioGotoXY(ioWhereX-(Sze-Ps),ioWhereY);
 end;

 procedure GetOptions;
 begin
    Password := Pos(rsPassword,Opt) > 0;
    NoCR     := Pos(rsNoCR,Opt)     > 0;
    NoIns    := Pos(rsNoIns,Opt)    > 0;
    NoEdit   := Pos(rsNoEdit,Opt)   > 0;
    Min      := Pos(rsMin,Opt)      > 0;
    Space    := Pos(rsSpace,Opt)    > 0;
    Req      := Pos(rsReq,Opt)      > 0;
    NoClean  := Pos(rsNoClean,Opt)  > 0;
    Abort    := Pos(rsAbort,Opt)    > 0;
    Backgr   := Pos(rsBackGr,Opt)   > 0;
 end;

 procedure ProcessChar(var C : Char);
 begin
    case iFl of
    inCapital : begin
                   if (Ps > 1) and (not (UpCase(S[Ps-1]) in ['A'..'Z','0'..'9','''','"']))
                      then C := UpCase(C); { else C := LowCase(C);}
                   if Ps = 1 then C := UpCase(C);
                end;
      inUpper : C := UpCase(C);
      inLower : C := LowCase(C);
      inMixed : begin
                   if (Ps > 1) and (not (UpCase(S[Ps-1]) in ['A'..'Z','0'..'9','''','"']))
                      then C := UpCase(C) else C := LowCase(C);
                   if Ps = 1 then C := UpCase(C);
                end;
      inWeird : if UpCase(C) in ['A','E','I','O','U'] then C := LowCase(C) else
                   C := UpCase(C);
     inWarped : if UpCase(C) in ['A','E','I','O','U'] then C := UpCase(C) else
                   C := LowCase(C);
       inCool : if UpCase(C) = 'I' then C := LowCase(C) else C := UpCase(C);
    end;
 end;

 procedure AddChar(C : Char);
 begin
    if (Ps >= Len) or (Sze >= Len) or ((Ps = 1) and (C = ' ') and
       (not Space)) then Exit;

    ProcessChar(C);

    if not (C in iCh) then Exit;

    ioWriteChar(C);
    if Ps = Sze then
    begin
       S := S + C;
       Inc(Sze,1);
       Inc(Ps,1);
    end else if Ins then
    begin
       Insert(C,S,Ps);
       Inc(Sze,1);
       Inc(Ps,1);
       UpdateString(False);
    end else
    begin
       S[Ps] := C;
       Inc(Ps,1);
    end;
 end;

 procedure Backspace;
 begin
    if Ps <= 1 then Exit;
    ioWrite(#8#32#8);
    Dec(Ps,1);
    Dec(Sze,1);
    Delete(S,Ps,1);
    if Ps < Sze then UpdateString(True);
 end;

 procedure DelChar;
 begin
    if (Sze < 2) or (Ps >= Sze) then Exit;
    Delete(S,Ps,1);
    {sRepeat(EchoCh,Sze-Ps-1)+' ')}
    ioWrite(Copy(S,Ps,255)+' ');
    ioGotoXY(ioWhereX-(Sze-Ps),ioWhereY);
    Dec(Sze,1);
 end;

 procedure NextWord;
 var N, Z : Byte;
 begin
    if Ps = Sze then Exit;
    Z := 0;
    for N := Ps+1 to Sze do if (Z = 0) and (S[N] in [' ','-']) then Z := N;
    if Z = 0 then Z := Sze;
    if Ps = Z then Exit;
    ioGotoXY(ioWhereX+(-Ps+Z),ioWhereY);
    Ps := Z;
 end;

 procedure LastWord;
 var N, Z : Byte;
 begin
    if (Ps = 1) or (Sze < 2) then Exit;
    Z := 0;
    for N := Ps-1 downto 1 do if (Z = 0) and (S[N] in [' ','-']) then Z := N;
    if Z = 0 then Z := 1;
    if Ps = Z then Exit;
    if Z > Ps then ioGotoXY(ioWhereX+(Z-Ps),ioWhereY) else ioGotoXY(ioWhereX-(Ps-Z),ioWhereY);
    Ps := Z;
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
    if Z = 0 then Z := 1;
    if Ps = Z then Exit;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
 end;

 procedure ClearEol;
 var Z : Byte;
 begin
    if (Ps = Sze) then Exit;
    for Z := Ps to Sze do ioWrite(' ');
    ioGotoXY(ioWhereX-(Sze-Ps+1),ioWhereY);
    Delete(S,Ps,255);
    Sze := Ps;
 end;

 procedure ClearItAll;
 var Z : Byte;
 begin
    if (Sze = 1) then Exit;
    ioGotoXY(ioWhereX-(Ps-1),ioWhereY);
    for Z := 1 to Sze do ioWriteChar(' ');
    ioGotoXY(ioWhereX-Sze,ioWhereY);
    Delete(S,1,255);
    Sze := 1;
    Ps := 1;
 end;

 procedure DoTab;
 var Z : Byte;
 begin
    for Z := 1 to 4 do AddChar(' ');
 end;

 procedure DrawBackground;
 begin
{   oSetCol(colEdit);
    oWrite(sRepeat(' ',Len));
    oWrite(sRepeat(#8,Len));}
 end;

 procedure InitVars;
 begin
    Ch      := #1;
    Done    := False;
    Ins     := True;
    S       := '';
    Ps      := 1;
    Sze     := 1;
    Int     := 1;

    Password := False;
    NoCR     := False;
    NoIns    := False;
    NoEdit   := False;
    Min      := False;
    Space    := False;
    Req      := False;
    NoClean  := False;
    Abort    := False;
    Backgr   := False;
 end;

begin
   InitVars;
   GetOptions;
{  if Backgr then DrawBackground;}
   Inc(Len,1);
{  if not emuANSi then NoEdit := True;}
   Ins := not NoIns;
   if Def <> '' then for Int := 1 to Length(Def) do AddChar(Def[Int]);
   repeat
      Ch := ReadKey;
      if (Ch = #0) then
      begin
         Ch := ReadKey;
         case extKey of
{Left}     #75  : if (not NoEdit) and (Ps > 1) then begin Dec(Ps,1); ioGotoXY(ioWhereX-1,ioWhereY); end;
{Right}    #77  : if (not NoEdit) and (Ps < Sze) then begin Inc(Ps,1); ioGotoXY(ioWhereX+1,ioWhereY); end;
{Home}     #71  : if (not NoEdit) and (Ps > 1) then begin ioGotoXY(ioWhereX-(Ps-1),ioWhereY); Ps := 1; end;
{End}      #79  : if (not NoEdit) and (Ps < Sze) then begin ioGotoXY(ioWhereX+(Sze-Ps),ioWhereY); Ps := Sze; end;
{Insert}   #82  : if (not NoIns) and (not NoEdit) then Ins := not Ins;
{Delete}   #83  : if not NoEdit then DelChar;
{Ctrl <-}  #115 : if not NoEdit then LastWord;
{Ctrl ->}  #116 : if not NoEdit then NextWord;
{Ctrl End} #117 : if not NoEdit then ClearEol;
         end;
      end else
      case Ch of
{Enter}    #13 : if ((not Min) or (Ps > 1)) and
                    ((not Req) or (Ps = Len)) then Done := True;
{Bkspace}  #8  : Backspace;
{Tab}      #9  : DoTab;
{Ctrl Y}   #25 : if not NoEdit then ClearItAll;
{ESC / ^Z} #26..#27 : if Abort then begin S := ''; Done := True; end;
{Anything} #32..#254 : AddChar(Ch);
      end;
   until (HangUp) or (Done);
   if (HangUp) and (S = '') then S := Def;
   if not NoClean then S := CleanUp(S);
   tmReadString := S;
end;

procedure tmDialer;
const
   dTop = 2;
   dBot = 11;
   dLen = dBot-dTop+1;
   dXps = 3;
var
   dSrt, dPos, dNum : Word;
   hiCol, loCol, phCol : Byte;
   Ch : Char;
   dDone : Boolean;
   Cnct : Boolean;
   oAttr, oX, oY : Byte;

 procedure dialBar;
 begin
    fWrite(dXps,dTop+dPos-dSrt,' '+Resize(Phone^[dPos].Desc,31),hiCol);
 end;

 procedure dialNoBar;
 begin
    fWrite(dXps,dTop+dPos-dSrt,' '+Resize(Phone^[dPos].Desc,31),loCol);
 end;

 procedure dialUpdateScr;
 var Y : Byte;
 begin
    for Y := dTop to dBot do if dSrt+Y-dTop <= dNum then
    begin
       if dSrt+Y-dTop = dPos then
         fWrite(dXps,Y,' '+Resize(Phone^[dSrt+Y-dTop].Desc,31),hiCol) else
         fWrite(dXps,Y,' '+Resize(Phone^[dSrt+Y-dTop].Desc,31),loCol);
       fWrite(dXps+38,Y,Resize(Phone^[dSrt+Y-dTop].PhoneNum,20),phCol);
    end;
 end;

 procedure dialEntry;
 var Res : Byte;
 begin
    tmLoadBBS(dPos);
    tmOpenWin(1,16,80,18);
    fWrite(wx, wy,'Dialing',tmCol(4));
    fWrite(wx+7, wy,':',tmCol(5));
    fWrite(wx+9,wy,BBS.Desc,tmCol(6));
    tmWrite(#13);
    Delay(100);
    tmWrite(Modem^.sDialPrefix+BBS.PhoneNum+#13#10);
    Res := 0;
    repeat
       if Keypressed then
       begin
          Res := 1;
          while Keypressed do ReadKey;
       end else
       while CharWaiting(Modem^.ComPort) do
       begin
          Move(tmBuf[2],tmBuf[1],tmBufSize-1);
          tmBuf[tmBufSize] := ComReadChar(Modem^.ComPort);
          if tmBufStr('CONNECT') then Res := 2 else
          if tmBufStr(Modem^.rError) then Res := 3 else
          if tmBufStr(Modem^.rBusy) then Res := 4 else
          if tmBufStr(Modem^.rNoCarrier) then Res := 5;
       end;
    until Res <> 0;
    if Res <> 1 then
    begin
       case Res of
          2 : tmOnWin('Connection established',False);
          3 : tmOnWin('Modem command error',False);
          4 : tmOnWin('Busy signal received',False);
          5 : tmOnWin('No carrier received',False);
       end;
       Delay(1600);
       tmRestoreWin;
    end else
    begin
       tmWrite(#13#13);
       cClearInBuffer;
       while CharWaiting(Modem^.ComPort) do ComReadChar(Modem^.ComPort);
    end;
    tmRestoreWin;
    Cnct := Res = 2;
 end;

 procedure dialBarUp;
 begin
    if dPos <= 1 then Exit;
    if dPos-1 < dSrt then
    begin
       Dec(dPos);
       Dec(dSrt);
       dialUpdateScr;
    end else
    begin
       dialNoBar;
       Dec(dPos);
       dialBar;
    end;
 end;

 procedure dialBarDown;
 begin
    if dPos >= dNum then Exit;
    if dPos+1 > dSrt+dLen-1 then
    begin
       Inc(dPos);
       Inc(dSrt);
       dialUpdateScr;
    end else
    begin
       dialNoBar;
       Inc(dPos);
       dialBar;
    end;
 end;

 function dialEditEntry : Boolean;
 var Ch : Char;
 begin
    tmOpenWin(14,6,66,14);
    fWrite(wx,wy,  '1  Description',tmCol(1));
    fWrite(wx,wy+1,'2  Phone number',tmCol(1));
    fWrite(wx,wy+2,'3  Password',tmCol(1));
    fWrite(wx+16,wy,  BBS.Desc,tmCol(3));
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
    fWrite(wx+16,wy+1,BBS.PhoneNum,tmCol(3));
    fWrite(wx+16,wy+2,BBS.Password,tmCol(3));
    fWrite(wx,wy+5,'Enter: Save    Escape: Abort',tmCol(2));
    repeat
       Ch := UpCase(ReadKey);
       case Ch of
        '1' : begin
                 ioGotoXY(wx+16,wy);
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
                 ioTextAttr(tmCol(6));
                 BBS.Desc := tmReadString(BBS.Desc,inNormal,chNormal,'',30);
                 fWrite(wx+16,wy,  BBS.Desc,tmCol(3));
              end;
        '2' : begin
                 ioGotoXY(wx+16,wy+1);
                 ioTextAttr(tmCol(6));
                 BBS.PhoneNum := tmReadString(BBS.PhoneNum,inUpper,chNormal,'',20);
                 fWrite(wx+16,wy+1,  BBS.PhoneNum,tmCol(3));
              end;
        '3' : begin
                 ioGotoXY(wx+16,wy+2);
                 ioTextAttr(tmCol(6));
                 BBS.Password := tmReadString(BBS.Password,inNormal,chNormal,'',20);
                 fWrite(wx+16,wy+2,  BBS.Password,tmCol(3));
              end;
       end;
    until Ch in [#13,#27];
    dialEditEntry := Ch = #13;
    tmRestoreWin;
 end;

 procedure dialAddEntry;
 var F : file of tBbsRec;
 begin
    if dNum >= maxPhone then Exit;
    Assign(F,Cfg^.pathData+filePhoneBook);
    {$I-}
    Reset(F);
    {$I+}
    if ioResult <> 0 then Exit;
    Seek(F,FileSize(F));
    FillChar(BBS,SizeOf(BBS),0);
    with BBS do
    begin
       Desc := 'Unknown';
       PhoneNum := '';
       Password := '';
    end;
    if dialEditEntry then
    begin
       Write(F,BBS);
       Close(F);
       tmReadPhone;
       dNum := numBBS;
       dialUpdateScr;
    end else Close(F);
 end;

begin
   tmReadPhone;
   oX := ioWhereX;
   oY := ioWhereY;
   oAttr := colAttr;
   if numBBS < 1 then Exit;
   tmOpenWin(1,1,80,12);
   dNum := numBBS;
   hiCol := tmCol(colItemSel);
   loCol := tmCol(colItem);
   phCol := tmCol(colTextLo);
   dPos := 1;
   dSrt := 1;
   dDone := False;
   dialUpdateScr;
   Cnct := False;
   repeat
      Ch := UpCase(ReadKey);
      if Ch = #0 then
      begin
         Ch := ReadKey;
   cModemWrite(Modem^.sInit1);
   cModemWrite(Modem^.sInit2);
   cModemWrite(Modem^.sInit3);
         case Ch of
            upArrow : dialBarUp;
            dnArrow : dialBarDown;
         end;
      end else
      case Ch of
         #27     : dDone := True;
         #13,'D' : dialEntry;
         'A'     : dialAddEntry;
         'E'     : begin
                      tmLoadBBS(dPos);
                      if dialEditEntry then
                      begin
                         tmSaveBBS(dPos);
                         tmReadPhone;
                         dNum := numBBS;
                         dialUpdateScr;
                      end;
                   end;
         'S'     : begin
                      tmSortBBSs;
                      tmReadPhone;
                      dNum := numBBS;
                      dialUpdateScr;
                   end;
      end;
   until (Cnct) or (dDone);
   tmRestoreWin;
   ioGotoXY(oX,oY);
   ioTextAttr(oAttr);
end;

procedure tmDoHelp;
begin
   tmOpenWin(10,5,70,18);
   fWrite(15,8,'Help not implemented.',tmCol(1));
   ReadKey;
   while Keypressed do ReadKey;
   tmRestoreWin;
end;

procedure tmSendPw;
begin
   tmWrite(BBS.Password+#10#13);
end;

procedure tmTerminalMode;
var VideoMode : ^Byte;
begin
   if (MaxAvail < SizeOf(tPhone)) or (ModemOff) then Exit;
   numWin := 0;
   VideoMode := Ptr(Seg0040,$0049);
   if VideoMode^ = 7 then ScrPtr := Ptr(SegB000,$0000) else ScrPtr := Ptr(SegB800,$0000);
   New(Phone);
   FillChar(Phone^,SizeOf(Phone^),0);
   TextMode(Co80);
   tmClrScr;
   tmDone := False;
   logWrite('*Terminal system loaded');
   FillChar(BBS,SizeOf(BBS),0);
   if cNoCarrier then tmInitModem;
   repeat
      if CharWaiting(Modem^.ComPort) then
      begin
         posUpdate := False;
         while CharWaiting(Modem^.ComPort) do
         begin
            Move(tmBuf[2],tmBuf[1],tmBufSize-1);
            tmBuf[tmBufSize] := ComReadChar(Modem^.ComPort);
            emuAnsiWriteChar(tmBuf[tmBufSize]);
            tmCheckBuffer;
         end;
         ioUpdatePos;
      end;
      if Keypressed then
      begin
         Ch := ReadKey;
         if Ch = #0 then
         begin
            Ch := ReadKey;
            case Ch of
               F1       : tmDoHelp;
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
              upArrow  : tmWrite(#27'[A');
               dnArrow  : tmWrite(#27'[B');
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
               rtArrow  : tmWrite(#27'[C');
               lfArrow  : tmWrite(#27'[D');
               PgDn     : tmDownload;
               altC     : tmClrScr;
               altD     : tmDialer;
               altJ     : tmJumpToDOS;
               altH     : tmHangUp;
               altI     : tmInitModem;
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
               altS     : tmSendPw;
               altX     : tmDone := True;
            end;
         end else ComWriteChar(Modem^.ComPort,Ch);
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
    end; {SegmentedInsertion}
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
                    bein
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
     end;
   until tmDone;
   fCreateDir(StartDir,False);
   Dispose(Phone);
end;

end.
