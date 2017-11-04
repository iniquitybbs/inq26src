{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config;

interface

uses Global;

const
   maxItem        = 56;
   cfgTop         = 4;

var
   numItem      : Byte;
   cfgBot       : Byte;
   cfgCol       : Byte;
   cfgLn        : Byte;
   cfgSel       : Byte;
   cfgKey       : Char;
   cfgDone      : Boolean;
   cfgDraw      : Boolean;
   cfgOver      : Boolean;
   cfgRead      : String;
   cfgStat      : Byte;
   cfgSrt       : Byte;
   cfgBarPos    : Byte;

procedure cfgAskCreate(Dir : String);
procedure cfgBar;
procedure cfgDrawAllItems;
procedure cfgEditInfo(Def : String; Max : Byte; iFl : tInFlag;
                      iCh : tInChar; Opt : String; Bl : Boolean);
function  cfgFlags(var F : tUserFlags) : String;
procedure cfgInit(Ttl : String);
procedure cfgInfo(Info : String);
procedure cfgItem(Itm : String; Len : Byte; Res : String; Info : String);
function  cfgItemNumber(Ch : Char) : Byte;
procedure cfgItemXY(X,Y,C : Byte; Itm : String; Len : Byte; Res : String; Info : String);
function  cfgOption(var Opt; Cur : Byte) : String;
procedure cfgPrompt(var Opt; Num : Byte);
procedure cfgPromptCommand;
procedure cfgReadBoolean(var B : Boolean);
procedure cfgReadColor(var Col : tColorRec);
procedure cfgReadDate;
procedure cfgReadFlags(var F : tUserFlags);
procedure cfgReadInfo(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Bl : Boolean);
procedure cfgReadOption(var Opt; Num : Byte; var Pick : Byte);
procedure cfgReadPhone;
procedure cfgReadTime;
procedure cfgSetItem(Res : String);
function  cfgYesNo(Def : Boolean) : Boolean;

implementation

uses
   Crt,
   Output, Strings, Input, Files, Misc;

type
   tItem = record
      Key     : Char;
      sX      : Byte;
      pX      : Byte;
      pY      : Byte;
      Len     : Byte;
      Res     : String;
      Info    : String[78];
   end;

var
   Item : array[1..maxItem] of tItem;

procedure cfgInit(Ttl : String);
begin
   if not cfgDraw then Exit;
   if not cfgOver then
   begin
{     oClrScr;
      oStrCtr(' |U3c|U1ommand|U2:');
      oMoveRight(60);
      oStrCtr('|U3e|U1sc|U2/|U3q|U1uit');
      Insert('- ',ttl,1);
      Ttl := Ttl+' -';
      oGotoXY(CenterPos(Ttl),1);
      oStrCtr('|U4'+Ttl);
      oDnLn(1);
      oStrCtr('|U2'+sRepeat('ƒ',79));
      oDnLn(1);
      FillChar(Item,SizeOf(Item),#0);}
      oSetCol(colText);
      oClrScr;
      oStrCtr('|U5ﬁ‹');
      oMoveRight(75);
      oStrCtr('‹›');
      Insert('- ',ttl,1);
      Ttl := Ttl+' -';
      oGotoXY(CenterPos(Ttl),1);
      oStrLn('|U4'+Ttl);
      oStrCtrLn('|U5 ﬂ≤‹‹‹‹‹‹≤˛[|U4command:       |U5]˛‹‹‹‹‹‹‹‹‹‹˛‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹'+
                '‹‹˛[|U4esc|U5/|U4quit|U5]˛≤‹‹‹‹‹‹≤ﬂ');
      FillChar(Item,SizeOf(Item),#0);
      cfgBarPos := 1;
   end;
   numItem := 0;
   cfgCol := 30;
   cfgLn  := cfgTop;
   cfgSel := 0;
   cfgKey := #0;
   cfgDone := False;
   cfgStat := 0;
   cfgSrt := 1;
   cfgBot := 0;
end;

procedure cfgBar;
begin
   if (not cfgDraw) or (cfgOver) then Exit;
   oGotoXY(1,cfgTop+cfgBot);
   oDnLn(1);
   oStrCtr('|U5ﬂ˛|U4[');
   oMoveRight(73);
   oStrCtr(']|U5˛ﬂ');
{  oStrCtr('|U2'+sRepeat('ƒ',79));}
end;

procedure cfgInfo(Info : String);
var T : Byte;
begin
   if Info = '' then
   begin
      if cfgStat = 0 then Exit;
      oGotoXY(4,cfgTop+1+cfgBot);
      oWrite(sRepeat(' ',cfgStat));
{     oClrEol;}
      cfgStat := 0;
   end else
   begin
      T := cfgStat;
      cfgStat := Length(NoColor(Info));
      while Length(NoColor(Info)) < T do Info := Info+' ';
      oSetCol(colInfoHi);
      oGotoXY(4,cfgTop+1+cfgBot);
      oStrCtr(Info);
   end;
end;

procedure cfgBarOff(i : Byte);
begin
   with Item[i] do
   begin
      oGotoXY(sX,pY);
      oSetCol(colInfoLo);
      oWriteChar('[');
      oSetCol(colInfoHi);
      case Key of
         #8 : oWrite('Tab');
        #32 : oWrite('Space');
        else oWriteChar(Key);
      end;
      oSetCol(colInfoLo);
      oWriteChar(']');
   end;
end;

procedure cfgBarOn(i : Byte);
begin
   with Item[i] do
   begin
      oGotoXY(sX,pY);
      oSetCol(colItemSel);
      case Key of
         #8 : oWrite(' Tab ');
        #32 : oWrite(' Space ');
        else oWrite(' '+Key+' ');
      end;
   end;
end;

procedure cfgItemXY(X,Y,C : Byte; Itm : String; Len : Byte; Res : String; Info : String);
begin
   if (numItem = maxItem) or (not cfgDraw) then Exit;
   Inc(numItem);
   if not cfgOver then
   begin
      if Itm[2] <> ' ' then Item[numItem].Key := #1 else
      Item[numItem].Key  := Itm[1];
      Item[numItem].Len  := Len;
      Item[numItem].sX   := X;
      Item[numItem].pX   := C;
      Item[numItem].pY   := cfgTop+Y-1;
      Item[numItem].Info := Info;
   end;
   Item[numItem].Res  := Res;
   if (cfgOver) or (Length(CleanUp(Itm)) < 1) then Exit;
   if Itm[2] <> ' ' then
   begin
      if cfgBarPos = numItem then Inc(cfgBarPos);
      oGotoXY(X,Item[numItem].pY);
      oSetCol(colInfoLo);
      oWrite('---');
   end else if cfgBarPos = numItem then cfgBarOn(numItem) else cfgBarOff(numItem);
{  begin
      oGotoXY(X,Item[numItem].pY);
      oSetCol(colInfoLo);
      oWriteChar('[');
      oSetCol(colInfoHi);
      case Itm[1] of
         #8 : oWrite('Tab');
        #32 : oWrite('Space');
        #13 : oWrite('Enter');
        #27 : oWrite('Esc');
        else oWriteChar(Itm[1]);
      end;
      oSetCol(colInfoLo);
      oWriteChar(']');
   end;}
   oSetCol(colInfo);
   oWrite(' '+Copy(Itm,3,255));
end;

procedure cfgItem(Itm : String; Len : Byte; Res : String; Info : String);
begin
   if (numItem = maxItem) or (not cfgDraw) then Exit;
   cfgItemXY(cfgSrt,cfgLn-cfgTop+1,cfgCol,Itm,Len,Res,Info);
   Inc(cfgBot);
   Inc(cfgLn);
end;

procedure cfgDrawItem(Itm : Byte; Over : Boolean);
begin
   if Item[Itm].Len = 0 then Exit;
   oGotoXY(Item[Itm].pX,Item[Itm].pY);
   oSetCol(colText);
   if Over then oCWrite(Resize(Item[Itm].Res,Item[Itm].Len)) else
                oCWrite(strSquish(Item[Itm].Res,Item[Itm].Len));
end;

procedure cfgDrawAllItems;
var N : Byte;
begin
   if cfgDraw then for N := 1 to numItem do cfgDrawItem(N,cfgOver);
   cfgDraw := False;
   cfgOver := False;
end;

procedure cfgKeyDown;
var x, dis, nearest : Integer;
begin
   nearest := 0;
   dis := 255;
   for x := 1 to numItem do
       if (Item[x].pY > Item[cfgBarPos].pY) and
          (Item[x].pY-Item[cfgBarPos].pY < dis) and
          (Item[x].Key <> #1) and
          (Item[x].sX = Item[cfgBarPos].sX) then
   begin
      nearest := x;
      dis := Item[x].pY-Item[cfgBarPos].pY;
   end;
   if nearest = 0 then Exit;
   cfgBarOff(cfgBarPos);
   cfgBarPos := nearest;
   cfgBarOn(cfgBarPos);
   oGotoXY(22,2);
   oSetCol(colInfoHi);
   oWrite(' '#8);
end;

procedure cfgKeyRight;
var x, dis, nearest : Integer;
begin
   nearest := 0;
   dis := 255;
   for x := 1 to numItem do
       if (Item[x].sX > Item[cfgBarPos].sX) and
          (Item[x].sX-Item[cfgBarPos].sX < dis) and
          (Item[x].Key <> #1) and
          (Item[x].pY = Item[cfgBarPos].pY) then
   begin
      nearest := x;
      dis := Item[x].sX-Item[cfgBarPos].sX;
   end;
   if nearest = 0 then Exit;
   cfgBarOff(cfgBarPos);
   cfgBarPos := nearest;
   cfgBarOn(cfgBarPos);
   oGotoXY(22,2);
   oSetCol(colInfoHi);
   oWrite(' '#8);
end;

procedure cfgKeyUp;
var x, dis, nearest : Integer;
begin
   nearest := 0;
   dis := 255;
   for x := 1 to numItem do
       if (Item[x].pY < Item[cfgBarPos].pY) and
          (Item[cfgBarPos].pY-Item[x].pY < dis) and
          (Item[x].Key <> #1) and
          (Item[x].sX = Item[cfgBarPos].sX) then
   begin
      nearest := x;
      dis := Item[cfgBarPos].pY-Item[x].pY;
   end;
   if nearest = 0 then Exit;
   cfgBarOff(cfgBarPos);
   cfgBarPos := nearest;
   cfgBarOn(cfgBarPos);
   oGotoXY(22,2);
   oSetCol(colInfoHi);
   oWrite(' '#8);
end;

procedure cfgKeyLeft;
var x, dis, nearest : Integer;
begin
   nearest := 0;
   dis := 255;
   for x := 1 to numItem do
       if (Item[x].sX < Item[cfgBarPos].sX) and
          (Item[cfgBarPos].sX-Item[x].sX < dis) and
          (Item[x].Key <> #1) and
          (Item[x].pY = Item[cfgBarPos].pY) then
   begin
      nearest := x;
      dis := Item[cfgBarPos].sX-Item[x].sX;
   end;
   if nearest = 0 then Exit;
   cfgBarOff(cfgBarPos);
   cfgBarPos := nearest;
   cfgBarOn(cfgBarPos);
   oGotoXY(22,2);
   oSetCol(colInfoHi);
   oWrite(' '#8);
end;

procedure cfgPromptCommand;
var Ch : Char; Pk, N : Byte; isQ : Boolean;
begin
   oGotoXY(22,2);
   oSetCol(colInfoHi);
   oWrite(' '#8);
   Pk := 0;
   repeat
      Ch := UpCase(iReadKey);
      isQ := False;
      if extKey <> #0 then
      case extKey of
         UpArrow : cfgKeyUp;
         DnArrow : cfgKeyDown;
         LfArrow : cfgKeyLeft;
         RtArrow : cfgKeyRight;
      end else
      for N := 1 to numItem do
      begin
         if (Item[N].Key <> #1) and (Ch = Item[N].Key) then Pk := N;
         if (not isQ) and (Item[N].Key = 'Q') then isQ := True;
      end;
      cfgDone := (Ch in [#27,#13]) or ((not isQ) and (Ch = 'Q'));
   until (HangUp) or (cfgDone) or (Pk > 0);
   if HangUp then
   begin
      cfgDone := True;
      Ch := #27;
   end;
   if Ch = #13 then
   begin
      Ch := Item[cfgBarPos].Key;
      Pk := cfgBarPos;
      cfgDone := False;
   end;
   case Ch of
      #8 : oWrite('Tab');
     #32 : oWrite('Space');
     #27 : begin
              oWrite('Quit');
              oGotoXY(1,24);
           end;
      else oWriteChar(Ch);
   end;
   if (ch <> #13) and (not cfgDone) then
   begin
      if Pk <> cfgBarPos then
      begin
         cfgBarOff(cfgBarPos);
         cfgBarPos := Pk;
         cfgBarOn(cfgBarPos);
         oSetCol(colInfoHi);
      end;
   end;
   cfgSel := Pk;
   cfgKey := Ch;
end;

function cfgItemNumber(Ch : Char) : Byte;
var N : Byte;
begin
   cfgItemNumber := 0;
   for N := 1 to numItem do if Item[N].Key = Ch then cfgItemNumber := N;
end;

procedure cfgEditInfo(Def : String; Max : Byte; iFl : tInFlag;
                      iCh : tInChar; Opt : String; Bl : Boolean);
var I, L : Byte;
begin
   I := cfgItemNumber(cfgKey);
   if Item[I].Info <> '' then cfgInfo(Item[I].Info);
   oGotoXY(Item[I].pX,Item[I].pY);
   oSetCol(colTextHi);
   L := Item[I].Len;
   if max = 0 then
   begin
      max := Item[I].Len;
      Inc(L);
   end;

   cfgRead := iEditString(Def,iFl,iCh,rsAbort+rsNoCR+Opt,Max,L);
   if (Bl) and (cfgRead = '') then cfgRead := Def;
   cfgInfo('');
end;

procedure cfgReadInfo(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Bl : Boolean);
begin
   cfgEditInfo(Def,0,iFl,iCh,rsNoCR+rsAbort+Opt,Bl);
end;

procedure cfgReadPhone;
var I : Byte;
begin
   I := cfgItemNumber(cfgKey);
   if Item[I].Info <> '' then cfgInfo(Item[I].Info);
   oGotoXY(Item[I].pX,Item[I].pY);
   oSetCol(colTextHi);
   cfgRead := iReadPhone(Item[I].Res);
   cfgInfo('');
end;

procedure cfgReadTime;
var I : Byte;
begin
   I := cfgItemNumber(cfgKey);
   if Item[I].Info <> '' then cfgInfo(Item[I].Info);
   oGotoXY(Item[I].pX,Item[I].pY);
   oSetCol(colTextHi);
   cfgRead := iReadTime(Item[I].Res);
   cfgInfo('');
end;

procedure cfgReadDate;
var I : Byte;
begin
   I := cfgItemNumber(cfgKey);
   if Item[I].Info <> '' then cfgInfo(Item[I].Info);
   oGotoXY(Item[I].pX,Item[I].pY);
   oSetCol(colTextHi);
   cfgRead := iReadDate(Item[I].Res);
   cfgInfo('');
end;

{ Add BLINK!!!!!!!!!! }
procedure cfgReadColor(var Col : tColorRec);
var I : Byte; Ch : Char; F,B : Integer; Bl : Boolean; X : tColorRec;
begin
   I := cfgItemNumber(cfgKey);
   cfgInfo('[up/down: foreground; left/right: background; enter: done; esc: abort]');
   oGotoXY(Item[I].pX,Item[I].pY);
   X  := Col;
   F  := Col.Fore;
   B  := Col.Back;
   Bl := Col.Blink;
   repeat
      oCWrite(Resize(strColor(Col),40));
      oGotoXY(Item[I].pX,Item[I].pY);
      Ch := UpCase(iReadKey);
      case extKey of
         #75 : begin
                  Dec(B,1);
                  if B < 0 then B := 7;
                  Col.Back := B;
               end;
         #77 : begin
                  Inc(B,1);
                  if B > 7 then B := 0;
                  Col.Back := B;
               end;
         #80 : begin
                  Dec(F,1);
                  if F < 0 then F := 15;
                  Col.Fore := F;
               end;
         #72 : begin
                  Inc(F,1);
                  if F > 15 then F := 0;
                  Col.Fore := F;
               end;
      end;
   until (HangUp) or (Ch in [#27,#13]);
   if (Ch = #27) or (HangUp) then Col := X;
   oCWrite(Resize(strColor(Col),40));
   cfgRead := '';
   cfgInfo('');
end;

function cfgYesNo(Def : Boolean) : Boolean;
var C : Char; Yes : Boolean;
 procedure WriteNo;
 begin
    oMoveLeft(9);
    oCWrite('|U4 Yes |U5[|U6No|U5]');
    Yes := False;
 end;
 procedure WriteYes;
 begin
    oMoveLeft(9);
    oCWrite('|U5[|U6Yes|U5]|U4 No ');
    Yes := True;
 end;
begin
   mCursor(False);
   if Def then oCWrite('|U5[|U6Yes|U5]|U4 No ') else oCWrite('|U4 Yes |U5[|U6No|U5]');
   Yes := Def;
   repeat
      C := UpCase(iReadKey);
      if (Yes)     and ((extKey in [#77,#75]) or (C in [' ','N'])) then WriteNo else
      if (not Yes) and ((extKey in [#77,#75]) or (C in [' ','Y'])) then WriteYes;
   until (HangUp) or (C in [#13,'Y','N']);
   oSetCol(colInfo);
   if C = 'Y' then Yes := True else if C = 'N' then Yes := False;
   mCursor(True);
   if HangUp then cfgYesNo := Def else cfgYesNo := Yes;
end;

procedure cfgReadBoolean(var B : Boolean);
var I : Byte;
begin
   I := cfgItemNumber(cfgKey);
   if Item[I].Info <> '' then cfgInfo(Item[I].Info);
   oGotoXY(Item[I].pX-1,Item[I].pY);
   B := cfgYesNo(B);
   oGotoXY(Item[I].pX-1,Item[I].pY);
   oWrite(sRepeat(' ',10));
   cfgInfo('');
end;

procedure cfgSetItem(Res : String);
var I : Byte;
begin
   I := cfgItemNumber(cfgKey);
   Item[I].Res := Res;
   oSetCol(colText);
   cfgDrawItem(I,True);
end;

procedure cfgAskCreate(Dir : String);
begin
   if Dir[Length(Dir)] = '\' then Delete(Dir,Length(Dir),1);
   if fDirExists(Dir) then Exit;
   cfgInfo('Create Directory? ');
   if iYesNo(True) then fCreateDir(Dir,True);
   Inc(cfgStat,10);
   cfgInfo('');
end;

function cfgOption(var Opt; Cur : Byte) : String;
type tStrArray = array[1..20] of String;
var Choice : ^tStrArray;
begin
   Choice := @Opt;
   cfgOption := Choice^[Cur];
end;

procedure cfgReadOption(var Opt; Num : Byte; var Pick : Byte);
type tStrArray = array[1..20] of String;
var Sel : ^tStrArray; I, Cur : Byte; Ch :  Char;
begin
   Sel := @Opt;
   I := cfgItemNumber(cfgKey);
   if Item[I].Info <> '' then cfgInfo('[space/arrows: select; enter: done] '+Item[I].Info);
   oGotoXY(Item[I].pX,Item[I].pY);
   oSetCol(colTextHi);
   if Pick < 1 then Pick := 1 else if Pick > num then Pick := num;
   Cur := Pick;
   repeat
      oWrite(Resize(Sel^[Cur],Item[I].Len)); {Resize(Sel^[Cur],30));  --  ?? }
      oGotoXY(Item[I].pX,Item[I].pY);
      Ch := UpCase(iReadKey);
      if extKey = #0 then case Ch of
         ' ' : begin
                  Inc(Cur,1);
                  if Cur > Num then Cur := 1;
               end;
      end else
      case extKey of
         #75,#80 : begin
                      Dec(Cur,1);
                      if Cur < 1 then Cur := Num;
                   end;
         #77,#72 : begin
                      Inc(Cur,1);
                      if Cur > Num then Cur := 1;
                   end;
      end;
   until (HangUp) or (Ch in [#27,#13]);
   cfgInfo('');
   if Ch = #13 then Pick := Cur;
end;

procedure cfgPrompt(var Opt; Num : Byte);
type tStrArray = array[1..20] of String;
var Cmd : ^tStrArray; Z : Byte;
begin
   Cmd := @Opt;
   oCWrite('|U2-- ');
   for Z := 1 to Num do
      oCWrite('|U2[|U3'+Copy(Cmd^[Z],1,Pos(' ',Cmd^[Z])-1)+'|U2]|U1'+Copy(Cmd^[Z],Pos(' ',Cmd^[Z])+1,255)+' ');
   oCWrite('|U2˘ |U4Command|U5: |U6');
end;

procedure cfgReadFlags(var F : tUserFlags);
var I, cur : Byte; z, ch : Char;
 procedure rfDrawCur;
 begin
    oGotoXY(Item[I].pX+cur,Item[I].pY);
    oSetCol(3);
    if z in F then oWriteChar(z) else oWriteChar(LowCase(z));
    oMoveLeft(1);
 end;
 procedure rfNoCur;
 begin
    oGotoXY(Item[I].pX+cur,Item[I].pY);
    oSetCol(1);
    if z in F then oWriteChar(z) else oWriteChar(LowCase(z));
 end;
begin
   I := cfgItemNumber(cfgKey);
   cfgInfo('[left/right: select; space/a-z: toggle; enter: done] '+Item[I].Info);
   oGotoXY(Item[I].pX,Item[I].pY);
   oSetCol(2);
   oWriteChar('[');
   oSetCol(1);
   for z := 'A' to 'Z' do if z in F then oWriteChar(z) else oWriteChar(LowCase(z));
   oSetCol(2);
   oWriteChar(']');
   cur := 1;
   z := 'A';
   rfDrawCur;

   repeat
      Ch := UpCase(iReadKey);
      if extKey = #0 then case Ch of
         'A'..'Z'
             : begin
                  if z <> ch then rfNoCur;
                  z := ch;
                  cur := Ord(Ch)-64;
                  if z in F then F := F-[z] else
                                 F := F+[z];
                  rfDrawCur;
               end;
         ' ' : begin
                  if z in F then F := F-[z] else
                                 F := F+[z];
                  rfDrawCur;
               end;
      end else
      case extKey of
         #75 : begin
                  rfNoCur;
                  Dec(Cur);
                  Dec(z);
                  if Cur < 1 then
                  begin
                     cur := 26;
                     z := 'Z';
                  end;
                  rfDrawCur;
               end;
         #77 : begin
                  rfNoCur;
                  Inc(Cur);
                  Inc(z);
                  if Cur > 26 then
                  begin
                     cur := 1;
                     z := 'A';
                  end;
                  rfDrawCur;
               end;
      end;
   until (HangUp) or (Ch in [#27,#13]);
   cfgInfo('');
end;

function cfgFlags(var F : tUserFlags) : String;
var z : Char; s : String;
begin
   s := '|U2[|U1';
   for z := 'A' to 'Z' do if z in F then s := s+z else s := s+LowCase(z);
   s := s+'|U2]';
   cfgFlags := s;
end;

end.