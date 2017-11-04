{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit fsEditor;

interface

uses Global;

function fsEdit(var Msg : tMessage;  var Head : tMsgHeaderRec; newMsg : Boolean;
                rMsg : pMessage; rHead : pMsgHeaderRec; aq, af : Boolean) : Boolean;

implementation

uses Output, Input, Misc, ShowFile, Strings, DateTime, Attach;

function fsEdit(var Msg : tMessage;  var Head : tMsgHeaderRec; newMsg : Boolean;
                rMsg : pMessage; rHead : pMsgHeaderRec; aq, af : Boolean) : Boolean;
var
   scrTop     : Integer;
   scrBot     : Integer;
   scrLns     : Integer;
   scrCol     : Integer;

   tCol       : tColorRec;
   qCol       : tColorRec;

   oldX       : Integer;
   oldY       : Integer;
   msgX       : Integer;
   msgY       : Integer;
   msgTop     : Integer;
   msgCur     : Integer;
   msgLines   : Integer;
   infPos     : Integer;

   num        : Integer;

   insMode    : Boolean;
   useSig     : Boolean;
   togSig     : Boolean;
   msgDone    : Boolean;
   msgSave    : Boolean;
   msgInfo    : Boolean;
   Rep        : Boolean;

   headAnsi   : Boolean;

   saveLine   : String[80];

 procedure fsCheckYpos;
 begin
    msgY := msgCur-msgTop+1;
 end;

 procedure fsCheckXpos;
 var N : Integer;
 begin
    N := Length(Msg[msgCur])+1;
    if msgX > N then msgX := N;
 end;

 function fsWhereY : Byte;
 begin
    fsWhereY := oWhereY-scrTop+1;
 end;

 procedure fsColor(Z : Word);
 begin
    if Pos('>',Copy(Msg[Z],1,3)) > 0 then oSetColRec(qCol) else oSetColRec(tCol);
 end;

 procedure fsGotoXY(X,Y : Integer);
 begin
    if (oldY <> msgY) and (sfGotoPos(12)) then oWrite(z3(msgCur));
    if (oldX <> msgX) and (sfGotoPos(13)) then oWrite(z2(msgX));
    Y := Y+scrTop-1;
    if (X <> oWhereX) or (Y <> oWhereY) then oGotoXY(X,Y);
    fsColor(msgCur);
 end;

 procedure fsUpdatePos;
 begin
    fsCheckYpos;
{   if (msgY <> fsWhereY) or (msgX <> oWhereX) then}
    fsGotoXY(msgX,msgY);
 end;

 procedure fsDrawScreen;
 var N, Z : Integer;
 begin
    oClrScr;
    headAnsi := sfShowTextFile(txFsHeader,ftFsHeader);
    if not headAnsi then
    begin
       tCol := User^.Color[colTextHi];
       qCol := User^.Color[colText];
       oSetCol(colInfo);

   oCWriteLn('|U9Ú |U6'+bbsTitle+' FullScreen Message Editor |U9ÄÄÄÄÄÄÄÄ |U4Date|U5:           |U4Time|U5:           |U9¿');
   oCWriteLn('|U9À |U4Anon|U5:       |U4To|U5:                          |U4Subject|U5:                           |U9Ù');

       oSetCol(colBorder);
       oWrite   ('-ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ-Ä');
       oGotoXY(1,23);
       oWrite   ('-ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ-Ä');
       oSetCol(colText);
       oGotoXY(53,1);
       oWrite(dtDatePackedString(Head.Date));
       oGotoXY(69,1);
       oWrite(dtTimePackedString(Head.Date));
       oGotoXY(19,2);
       oStrCtr(strSquish(Head.ToInfo.Name,36));
       oGotoXY(53,2);
       oStrCtr(strSquish(Head.Subject,40));
       oGotoXY(9,2);
       oWrite(b2st(msgAnonymous in Head.Status));
       oldX := 0;
       oldY := 0;
       scrTop := 4;
       scrBot := 22;
       infPos := 4;
    end else
    begin
       if sfGotoPos(1) then oStrCtr(Head.Subject);
       if sfGotoPos(2) then oStrCtr(Head.FromInfo.Name);
       if sfGotoPos(3) then oStrCtr(Head.ToInfo.Name);
       if sfGotoPos(4) then oStrCtr(dtDatePackedString(Head.Date));
       if sfGotoPos(5) then oStrCtr(dtTimePackedString(Head.Date));
       if not sfPos[7].Ok then scrTop := 4 else
       begin
          scrTop := sfPos[7].Y;
          qCol := sfPos[7].C;
       end;
       if not sfPos[8].Ok then scrBot := 22 else
       begin
          scrBot := sfPos[8].Y;
          tCol := sfPos[8].C;
       end;
       if sfGotoPos(9) then oCWrite(b2st(msgAnonymous in Head.Status));
       if sfGotoPos(10) then
       begin
          if useSig then oWrite('On ') else oWrite('Off');
       end;
       if sfGotoPos(11) then if insMode then oWrite('On ') else oWrite('Off');
       if not sfPos[14].Ok then infPos := scrTop else infPos := sfPos[14].y;
    end;
    scrLns := scrBot-scrTop+1;
    scrCol := 79;
{   if msgTop < msgCur then msgTop := msgCur;}
    if (msgCur-msgTop+1 < 1) or (msgCur-msgTop+1 > scrLns) then msgTop := msgCur-3;
    if msgTop < 1 then msgTop := 1;
    fsCheckYpos;
    fsGotoXY(1,1);
    for N := 1 to scrLns do
    begin
       Z := N+msgTop-1;
       if Z <= msgLines then
       begin
          fsColor(Z);
          oWrite(Msg[Z]);
          if N <> msgLines then oDnLn(1);
       end;
    end;
    fsUpdatePos;
 end;

 procedure fsScreenRefresh;
 var N, Z : Integer;
 begin
    if msgTop < 1 then msgTop := 1;
    fsCheckYpos;
    fsGotoXY(1,1);
    for N := 1 to scrLns do
    begin
       Z := N+msgTop-1;
       if Z <= msgLines then
       begin
          fsColor(Z);
          oWrite(Msg[Z]);
          oClrEol;
       end else oClrEol;
       if N <> msgLines then oDnLn(1);
    end;
    fsUpdatePos;
 end;

 procedure fsCheckSpaces;
 begin
    while Msg[msgCur,Length(Msg[msgCur])] = ' ' do
          Msg[msgCur,0] := Pred(Msg[msgCur,0]);
 end;

 procedure fsReposition(Refresh : Boolean);
 var cl, tl : Integer;
 begin
    fsCheckSpaces;
    cl := msgCur;
    tl := msgTop;
    if msgCur < 1 then msgCur := 1;
    if msgCur > msgLines then msgCur := msgLines;
    if msgTop > msgCur then msgTop := msgCur;
    if msgTop+scrLns < msgCur then msgTop := msgCur-scrLns;
    if msgTop < 1 then msgTop := 1;
    fsCheckXpos;
    fsCheckYpos;
    if (cl = msgCur) and (tl = msgTop) and (not Refresh) then fsUpdatePos
                                                         else fsScreenRefresh;
    fsColor(msgCur);
 end;

 procedure fsPartialRefresh;
 var Cnt,N : Integer;
 begin
    if msgTop < 1 then fsReposition(True) else
    begin
       fsGotoXY(1,msgY);
       for Cnt := msgY to scrLns do
       begin
          N := Cnt+msgTop-1;
          fsColor(N);
          if N <= msgLines then oWrite(Msg[N]);
          oClrEol;
          if Cnt <> scrLns then oDnLn(1);
       end;
       fsUpdatePos;
    end;
    fsColor(msgCur);
 end;

 procedure fsUpdateEol;
 var Cnt : Integer;
 begin
    oSaveCursor;
    oWrite(Copy(Msg[msgCur],msgX,255));
    oClrEol;
    oRestoreCursor;
    fsColor(msgCur);
 end;

 procedure fsScrollDown;
 begin
    msgTop := msgCur-scrLns+5;
    fsReposition(True);
 end;

 procedure fsScrollUp;
 begin
    if msgTop < 1 then
    begin
       Inc(msgTop);
       fsGotoXY(1,scrLns);
       fsCheckYpos;
       oDnLn(1);
    end else
    begin
       msgTop := msgCur-4;
       fsReposition(True);
    end;
 end;

 procedure fsCursorLeft;
 begin
    if msgX = 1 then
    begin
       if msgCur = 1 then Exit;
       fsCheckSpaces;
       Dec(msgCur,1);
       Dec(msgY,1);
       msgX := Length(Msg[msgCur])+1;
       if msgY < 1 then fsScrollDown else fsUpdatePos;
    end else
    begin
       Dec(msgX,1);
       oMoveLeft(1);
    end;
 end;

 procedure fsCursorRight;
 begin
    if msgX > Length(Msg[msgCur]) then
    begin
       if msgCur = maxMsgLines then Exit;
       fsCheckSpaces;
       Inc(msgCur,1);
       if msgCur > msgLines then msgLines := msgCur;
       Inc(msgY,1);
       msgX := 1;
       if msgY > scrLns then fsScrollUp else fsUpdatePos;
    end else
    begin
       Inc(msgX,1);
       oMoveRight(1);
    end;
 end;

 procedure fsInsertAbove;
 var Z : Integer;
 begin
    if msgLines = maxMsgLines then Exit;
    for Z := msgLines downto msgCur do Msg[Z+1] := Msg[Z];
    Msg[msgCur] := '';
    Inc(msgLines,1);
 end;

 procedure fsInsertUnder;
 var Z : Integer;
 begin
    if msgLines >= maxMsgLines then msgLines := maxMsgLines-1;
    for Z := msgLines downto msgCur+1 do Msg[Z+1] := Msg[Z];
    Msg[msgCur+1] := '';
    Inc(msgLines);
 end;

 procedure fsInsertAt;
 var Z : Integer;
 begin
    if msgLines >= maxMsgLines then msgLines := maxMsgLines-1;
    for Z := msgLines downto msgCur do Msg[Z+1] := Msg[Z];
    Msg[msgCur] := '';
    Inc(msgLines);
 end;

 procedure fsAddChar(C : Char);
 var W : String; oX, N : Integer; Z : Char; Inserted, Refresh : Boolean;
  procedure acScrollWrap;
  begin
     if msgTop > 0 then
     begin
        fsScrollUp;
        Exit;
     end;
     msgY := msgY-1;
     fsGotoXY(Length(Msg[msgCur-1])+1,msgY);
     oClrEol;
     oDnLn(1);
     oWrite(Msg[msgCur]);
     Inc(msgTop,1);
     msgX := oWhereX;
  end;

 begin
    if Length(Msg[msgCur]) >= scrCol then
    begin
       if msgCur = maxMsgLines then exit;
       if msgX <= Length(Msg[msgCur]) then Exit;
       Msg[msgCur] := Msg[msgCur]+C;
       W := '';
       msgX := Length(Msg[msgCur]);
       repeat
          Z := Msg[msgCur,msgX];
          if Z <> ' ' then Insert(Z,W,1);
          Dec(msgX,1);
       until (Z = ' ') or (msgX < 1);
       if msgX < 1 then
       begin
          msgX := Length(Msg[msgCur])-1;
          W := C;
       end;
       Msg[msgCur,0] := Chr(msgX);
       fsCheckSpaces;
       msgCur := msgCur+1;
       if msgCur > msgLines then msgLines := msgCur;
       Inserted := Msg[msgCur] <> '';
       if Inserted then fsInsertAbove;
       Msg[msgCur] := W;
       Inc(msgY,1);
       oX := msgX;
       msgX := Length(W)+1;
       Refresh := msgY > scrLns;
       if Refresh then acScrollWrap else
       begin
          if Length(W) > 0 then
          begin
             fsGotoXY(oX+1,msgY-1);
             for N := 1 to Length(W) do oWriteChar(' ')
          end;
          if Inserted and (msgLines > msgCur) then fsPartialRefresh else
          begin
             fsGotoXY(1,msgY);
             oWrite(Msg[msgCur]);
          end;
       end;
       Exit;
    end;
    if insMode then Insert(C,Msg[msgCur],msgX) else
    begin
       while Length(Msg[msgCur]) < msgX do Msg[msgCur] := Msg[msgCur]+' ';
       Msg[msgCur,msgX] := C;
    end;
    oWriteChar(C);
    Inc(msgX);
    if insMode and (msgX <= Length(Msg[msgCur])) then fsUpdateEol;
 end;

 procedure fsDeleteLine;
 var Cnt : Integer;
 begin
    if msgLines = 1 then
    begin
       FillChar(Msg[1],SizeOf(Msg[1]),0);
       msgX := 1;
       Exit;
    end else
    if msgCur >= msgLines then
    begin
       msgCur := msgLines;
       FillChar(Msg[msgCur],SizeOf(Msg[msgCur]),0);
       msgX := 1;
       Exit;
    end;
    for Cnt := msgCur+1 to msgLines do Msg[Cnt-1] := Msg[Cnt];
    FillChar(Msg[msgLines],SizeOf(Msg[msgLines]),0);
    Dec(msgLines);
    fsCheckXpos;
 end;

 procedure fsDeleteChar;
 var Cnt : Word;
 begin
    if (Length(Msg[msgCur]) = 0) and (msgCur < msgLines) then
    begin
       fsDeleteLine;
       fsPartialRefresh;
       Exit;
    end;
    if (msgCur < msgLines) and (msgX > Length(Msg[msgCur])) and (Length(Msg[msgCur+1])+Length(Msg[msgCur]) <= 79) then
    begin
       Msg[msgCur] := Msg[msgCur]+Msg[msgCur+1];
       for Cnt := msgCur+2 to msgLines do Msg[Cnt-1] := Msg[Cnt];
       FillChar(Msg[msgLines],SizeOf(Msg[msgLines]),0);
       Dec(msgLines);
       fsPartialRefresh;
    end else if msgX <= Length(Msg[msgCur]) then
    begin
       Delete(Msg[msgCur],msgX,1);
       fsUpdateEol;
    end;
 end;

 procedure fsBackSpace;
 var pos : Byte;
 begin
    if msgX = 1 then
    begin
       if (msgCur = 1) or (Length(Msg[msgCur])+Length(Msg[msgCur-1]) > 79) then Exit;
       Pos := Length(Msg[msgCur-1])+1;
       Msg[msgCur-1] := Msg[msgCur-1]+Msg[msgCur];
       fsDeleteLine;
       fsCheckSpaces;
       Dec(msgCur);
       Dec(msgY);
       msgX := Pos;
       fsCheckSpaces;
       if msgY < 1 then fsScrollDown else fsPartialRefresh;
       Exit;
    end;
    if msgX = 1 then Exit;
    msgX := msgX-1;
    oWriteChar(#8);
    fsDeleteChar;
 end;

 procedure fsCursorUp;
 var chx : Boolean; L : Integer;
 begin
    fsCheckSpaces;
    if msgCur = 1 then Exit;
    Dec(msgCur);
    L := Length(Msg[msgCur]);
    chx := msgX > L;
    if chx then msgX := L+1;
    Dec(msgY,1);
    if msgY > 0 then if chx then fsUpdatePos else oMoveUp(1) else fsScrollDown;
    fsColor(msgCur);
 end;

 procedure fsCursorDown;
 var chx : Boolean; L : Integer;
 begin
    fsCheckSpaces;
    if msgCur = maxMsgLines then Exit;
    Inc(msgCur,1);
    if msgCur > msgLines then msgLines := msgCur;
    L := Length(Msg[msgCur]);
    chx := msgX > L;
    if chx then msgX := L+1;
    Inc(msgY,1);
    if msgY <= scrLns
       then if chx
         then fsUpdatePos
      else oMoveDown(1)
    else fsScrollUp;
    fsColor(msgCur);
 end;

 procedure fsBreakLine;
 begin
    if (msgLines >= maxMsgLines) or (msgCur = scrLns) or
       (msgX > Length(Msg[msgCur])) then Exit;
    fsInsertAbove;
    Msg[msgCur] := Copy(Msg[msgCur+1],1,msgX-1);
    Delete(Msg[msgCur+1],1,msgX-1);
    fsPartialRefresh;
 end;

 procedure fsNextLine;
 begin
    if msgCur >= maxMsgLines then Exit;
    fsCheckSpaces;
    if msgX <= Length(Msg[msgCur]) then fsBreakLine else
    if msgCur < msgLines then
    begin
       fsInsertUnder;
       fsPartialRefresh;
    end;
    if msgX > 1 then
    begin
       msgX := 1;
       fsUpdatePos;
    end;
    Inc(msgCur);
    if msgCur > msgLines then msgLines := msgCur;
    Inc(msgY);
    if msgY <= scrLns then fsUpdatePos else fsScrollUp;
 end;

 procedure fsPageUp;
 begin
    fsCheckSpaces;
    if msgCur = 1 then Exit;
    msgCur := msgCur-scrLns+4;
    msgTop := msgTop-scrLns+4;
    fsReposition(True);
 end;

 procedure fsPageDown;
 begin
    fsCheckSpaces;
    if msgCur = msgLines then Exit;
    msgCur := msgCur+scrLns-4;
    msgTop := msgTop+scrLns-4;
    fsReposition(True);
 end;

 procedure fsDoTab;
 var n, cnt : Integer;
 begin
    n := 4;             { ! }
    if (n+Length(Msg[msgCur]) >= scrCol) then Exit;
    for Cnt := 1 to n do Insert(' ',Msg[msgCur],msgX);
    fsUpdateEol;
    Inc(msgX,n);
    fsUpdatePos;
 end;

 procedure fsCursorHome;
 begin
    if msgX = 1 then Exit;
    msgX := 1;
    fsUpdatePos;
 end;

 procedure fsCursorEnd;
 var dx : Integer;
 begin
    dx := Length(Msg[msgCur])+1;
    if msgX = dx then Exit;
    msgX := dx;
    fsUpdatePos;
 end;

 function fsOnWord : Boolean;
 begin
    fsOnWord := False;
    if (msgX > Length(Msg[msgCur])) or (msgX = 0) then Exit;
    fsOnWord := True;
    if msgX = 1 then Exit;
    if (Msg[msgCur,msgX-1] = ' ') and (Msg[msgCur,msgX] <> ' ') then Exit;
    fsOnWord := False;
 end;

 procedure fsWordLeft;
 begin
    repeat
       Dec(msgX,1);
       if msgX < 1 then
       begin
          if msgCur = 1 then
          begin
             msgX := 1;
             fsReposition(False);
             Exit;
          end;
          fsCheckSpaces;
          Dec(msgCur,1);
          Dec(msgY,1);
          msgX := Length(Msg[msgCur]);
       end;
   until fsOnWord;
   if msgX = 0 then msgX := 1;
   if msgY < 1 then fsReposition(True) else fsUpdatePos;
 end;

 procedure fsWordRight;
 begin
    repeat
       Inc(msgX,1);
       if msgX > Length(Msg[msgCur]) then
       begin
          if msgCur = msgLines then
          begin
             fsReposition(False);
             Exit;
          end;
          fsCheckSpaces;
          Inc(msgCur,1);
          Inc(msgY,1);
          msgX := 1;
       end;
     until fsOnWord;
     if msgY > scrLns then fsReposition(True) else fsUpdatePos;
 end;

 procedure fsInfo(Inf : String);
 begin
    oGotoXY(1,infPos);
    oSetCol(colText);
    if (msgInfo) and (Inf = '') then
    begin
       if infPos in [scrTop..scrBot] then
       begin
          fsColor(msgTop+(infPos-scrTop));
          oWrite(Msg[msgTop+(infPos-scrTop)]);
       end;
       oClrEol;
       msgInfo := False;
    end else
    begin
       oStr(Inf);
       oClrEol;
       msgInfo := True;
    end;
 end;

 procedure fsCheckLines;
 var Z : Word;
 begin
    Z := maxMsgLines;
    while (Msg[Z] = '') and (Z > 1) do Dec(Z,1);
    msgLines := Z+1;
    if msgLines > maxMsgLines then msgLines := Z;
    if msgCur > msgLines then msgCur := msgLines;
 end;

 procedure fsQuotePos(var One, Two : Word);
 begin
    if rHead^.sigPos > 0 then Two := rHead^.sigPos-1 else Two := rHead^.Size;
    if Two < 1 then
    begin
       Two := 0;
       One := 0;
       Exit;
    end;
    One := 1;
    while (Two > 1) and ((rMsg^[Two] = '') or (Pos(#27,rMsg^[Two]) > 0)) do Dec(Two);
    if Two-One+1 > Cfg^.maxQuoteLines then One := Two-Cfg^.maxQuoteLines+1;
    while (One < Two) and
          (((Pos('>',rMsg^[One]) > 0) and (Length(rMsg^[One]) <= 4)) or
          (rMsg^[One] = '') or (Pos(#27,rMsg^[One]) > 0)) do Inc(One);
 end;

 procedure fsSaveMessage;
 begin
    fsInfo(mStr(strFsSavingMsg));
    msgSave := True;
    msgDone := True;
 end;

 procedure fsGetCommand;
 var Cmd : Char; gcSlash : Boolean; TempC1 : Char;

  procedure gcAbortMessage;
  begin
     fsInfo(mStr(strFsAskAbort));
     if iYesNo(False) then
     begin
        msgSave := False;
        msgDone := True;
     end;
  end;

  procedure gcFsEditorHelp;
  begin
     if sfShowTextFile(txFsHelp,ftNoCode) then oPromptKey;
     fsDrawScreen;
  end;

  procedure gcAlterTitle;
  begin
     if (sfPos[1].Ok) and (headAnsi) then
     begin
        fsInfo(mStr(strMsgAlterTitle));
        sfGotoPos(1);
        Head.Subject := iReadString(Head.Subject,inNormal,chNormal,'',40);
        if Head.Subject = '' then
        begin
           Head.Subject := 'None';
           sfGotoPos(1);
           oWrite(Head.Subject);
        end;
     end else if not headAnsi then
     begin
        fsInfo(mStr(strMsgAlterTitle));
        oGotoXY(53,2);
        oSetCol(colText);
        Head.Subject := iReadString(Head.Subject,inNormal,chNormal,'',40);
        if Head.Subject = '' then
        begin
           Head.Subject := 'None';
           oGotoXY(53,2);
           oSetCol(colText);
           oWrite(Head.Subject);
        end;
     end;
  end;

  procedure gcQuoteMessage;
  var N, X, One, Two : Word; D, S, Z : String; Quote : Boolean;
  begin
     if (not Rep) or (rHead^.Size < 1) then Exit;
     oClrScr;
     Quote := False;
     N := 1;
     pauseAbort := False;
     pausePos := 1;
     while (not HangUp) and (not pauseAbort) and (N <= rHead^.Size) do
     begin
        if Pos(#27,rMsg^[N]) = 0 then
            oCWriteLn('|U4'+Resize(St(N),3)+'|U5: |U1'+strSquish(NoColor(rMsg^[N]),74)) else
            oCWriteLn('|U4'+Resize(St(N),3)+'|U5: |U1'+Cfg^.ansiString);
        oUpPause(1);
        Inc(N);
     end;
     oDnLn(1);
     oUpPause(1);
     pausePos := 0;
     oStr(strCode(mStr(strMsgQuoteFirst),1,St(rHead^.Size)));
     fsQuotePos(One,Two);
     if (One > 0) and (Cfg^.DefaultQuoteNum) and
                      (not (acQuote in User^.acFlag)) then D := St(One) else D := '';
     S := iReadString(D,inUpper,chNumeric,'',3);
     One := StrToInt(S);
     if (S <> '') and (One >= 1) and (One <= rHead^.Size) then
     begin
        oStr(strCode(strCode(mStr(strMsgQuoteSecond),1,St(One)),2,St(rHead^.Size)));
        if (Two >= One) and (Cfg^.DefaultQuoteNum) and
                       (not (acQuote in User^.acFlag)) then D := St(Two) else D := '';
        S := iReadString(D,inUpper,chNumeric,'',3);
        if S = '' then Two := One else Two := StrToInt(S);
        if (Two >= One) and (Two <= rHead^.Size) then Quote := True;
     end;
     if not Quote then
     begin
        fsDrawScreen;
        Exit;
     end;
     while msgCur+Two-1 >= maxMsgLines do Dec(Two,1);
     if msgAnonymous in rHead^.Status then Z := '??' else
                                           Z := mInitials(rHead^.FromInfo.Name);
     for N := One to Two do
     begin
        S := NoColor(rMsg^[N]);
        if Pos('>',Copy(S,1,3)) = 0 then Insert(Z+'> ',S,1);
        S := strSquish(S,79);
        for X := msgLines downto msgCur do Msg[X+1] := Msg[X];
        Msg[msgCur] := S;
        Inc(msgCur,1);
     end;
     fsCheckLines;
     fsDrawScreen;
  end;

  procedure gcAnonMsg;
  begin
     if (useSig) or (not acsOk(Cfg^.acsAnonymous)) or (not (maAnonymous in mArea^.Flag)) or
        (msgPrivate in Head.Status) then Exit;
     if msgAnonymous in Head.Status then
     begin
        Head.Status := Head.Status-[msgAnonymous];
        if maRealName in mArea^.Flag then Head.FromInfo.Name := Head.FromInfo.RealName else
                                          Head.FromInfo.Name := Head.FromInfo.Alias;
     end else
     begin
        Head.Status := Head.Status+[msgAnonymous];
        Head.FromInfo.Name := mStr(strAnonymous);
     end;
     if (sfPos[9].Ok) and (headAnsi) then
     begin
        sfGotoPos(9);
        oWrite(Resize(b2st(msgAnonymous in Head.Status),3));
     end else if not headAnsi then
     begin
        oGotoXY(9,2);
        oSetCol(colText);
        oWrite(Resize(b2st(msgAnonymous in Head.Status),3));
     end;
  end;

  procedure gcAutoSig;
  begin
     if (not togSig) or (msgAnonymous in Head.Status) then Exit;
     useSig := not useSig;
     if (sfPos[10].Ok) and (headAnsi) then
     begin
        sfGotoPos(10);
        if useSig then oWrite('On ') else oWrite('Off');
     end;{ else if not headAnsi then
     begin
        oGotoXY(17,23);
        oSetCol(colText);
        oWrite(Resize(b2st(msgAnonymous in Head.Status),3));
     end;}
  end;

  procedure gcAttachFile;
  begin
     if not af then Exit;
     atAttachFile(Head);
     fsDrawScreen;
  end;

 begin
    gcSlash := False;
    if Rep then TempC1 := 'Q' else TempC1 := #27;
    if not sfPos[6].Ok then
    begin
       fsInfo(mStr(strFsAskCommand));
       oSetCol(colInfoHi);
    end else
    begin
       fsInfo(mStr(strFsCommandHelp));
       sfGotoPos(6);
    end;
    repeat
       Cmd := UpCase(iReadKey);
    until (HangUp) or (extKey = #0) and (Cmd in [#27,'C',#13,'/', 'N','S','A','?','T','U','I',TempC1]);
    if Cmd in [#13,#27] then Cmd := 'C';
    oWriteChar(Cmd);
    case Cmd of
       'A' : gcAbortMessage;
       'I' : gcAttachFile;
       'N' : gcAnonMsg;
       'U' : gcAutoSig;
       'S' : fsSaveMessage;
       '?' : gcFsEditorHelp;
       '/' : gcSlash := True;
       'T' : gcAlterTitle;
       'Q' : gcQuoteMessage;
    end;
    if not msgDone then
    begin
       fsInfo('');
       if sfPos[6].Ok then
       begin
          sfGotoPos(6);
          oWriteChar(' ');
       end;
    end;
    fsGotoXY(msgX,msgY);
    fsUpdatePos;
    if gcSlash then fsAddChar('/');
 end;

 procedure fsAutoQuoteIt;
 var N, X, One, Two : Word; S, Z : String; Quote : Boolean;
 begin
    if rHead^.Size < 1 then Exit;
    Quote := False;
    fsQuotePos(One,Two);
    if (Two >= One) and (Two <= rHead^.Size) then Quote := True;
    if not Quote then Exit;
    while msgCur+Two-1 >= maxMsgLines do Dec(Two,1);
    if msgAnonymous in rHead^.Status then Z := '??' else
                                          Z := mInitials(rHead^.FromInfo.Name);
    for N := One to Two do
    begin
       S := NoColor(rMsg^[N]);
       if Pos('>',Copy(S,1,3)) = 0 then Insert(Z+'> ',S,1);
       S := strSquish(S,79);
       for X := msgLines downto msgCur do Msg[X+1] := Msg[X];
       Msg[msgCur] := S;
       Inc(msgCur,1);
    end;
    fsCheckLines;
 end;

 procedure fsInsert;
 begin
    insMode := not InsMode;
    if sfGotoPos(11) then if insMode then oWrite('On ') else oWrite('Off');
    fsUpdatePos;
 end;

 procedure fsProcessKey;
 var C : Char;
 begin
    C := iReadKey;
    if (extKey <> #0) then
    begin
       case extKey of
           #75  : fsCursorLeft;
           #77  : fsCursorRight;
           #72  : fsCursorUp;
           #80  : fsCursorDown;
           #82  : fsInsert;
           #73  : fsPageUp;
           #81  : fsPageDown;
           #83  : fsDeleteChar;
           #71  : fsCursorHome;
           #79  : fsCursorEnd;
           #115 : fsWordLeft;
           #116 : fsWordRight;
       end;
    end else
    case C of
           ^B        : fsBreakLine;
           ^D        : fsDeleteChar;
           ^K        : if (msgCur <= msgLines) then
                       begin
                          saveLine := Msg[msgCur];
                          fsDeleteLine;
                          fsPartialRefresh;
                       end;
           ^L        : fsDrawScreen;
           ^U        : if (saveLine <> '') then
                       begin
                          fsInsertAt;
                          Msg[msgCur] := saveLine;
                          fsPartialRefresh;
                       end;
           ^V        : fsInsert;
           ^X        : fsSaveMessage;
           ^Y        : if (msgCur <= msgLines) then
                       begin
                          fsDeleteLine;
                          msgX := 1;
                          fsPartialRefresh;
                       end;

           #8        : fsBackspace;
           #9        : fsDoTab;
           #13       : fsNextLine;
           #27       : fsGetCommand;
           #32..#254 : if (msgX = 1) and (C = '/') then
                       fsGetCommand else
                       fsAddChar(C);
    end;
 end;

begin
   insMode := True;
   msgDone := False;
   msgSave := True;
   msgInfo := False;
   togSig  := (Head.Subject[1] <> #10) and (acsOk(Cfg^.acsAutoSigUse));
   if Head.Subject[1] = #10 then Delete(Head.Subject,1,1);
   useSig := (acsOk(Cfg^.acsAutoSigUse)) and (togSig) {and (newMsg)} and (not (msgAnonymous in Head.Status));
   msgX := 1;
   msgY := 1;
   oldX := 0;
   oldY := 0;
   msgCur := 1;
   msgTop := 1;
   Rep := (rMsg <> nil) and (rHead <> nil);
   saveLine := '';

   if Head.Size <= 0 then newMsg := True;
   if newMsg then
   begin
      FillChar(Msg,SizeOf(Msg),#0);
      msgLines := 1;
      Head.sigPos := 0;
   end else
   begin
      msgLines := Head.Size;
      if Head.sigPos <> 0 then
      begin
         for num := Head.sigPos to msgLines do Msg[num,0] := #0;
         msgLines := Head.sigPos-1;
         if msgLines < 1 then msgLines := 1;
      end;
   end;
   if (Rep) and (aq) and (rHead^.Size > 0) then   { autoQuote! }
      fsAutoQuoteIt;

   fsDrawScreen;

   repeat
      fsProcessKey;
   until (msgDone) or (HangUp);
   if HangUp then msgSave := False;
   fsCheckLines;
   if (useSig) and (User^.AutoSigLns > 0) and (User^.AutoSigLns <= maxSigLines)
               and (msgLines < maxMsgLines-maxSigLines) then
   begin
      Head.sigPos := msgLines;
      Inc(msgLines,1);
      Msg[msgLines] := '';
      for msgY := 1 to User^.AutoSigLns do Msg[msgLines+msgY-1] := User^.AutoSig[msgY];
      Inc(msgLines,User^.AutoSigLns);
   end else Head.sigPos := 0;

   Head.Size := msgLines;

   if not sfGotoPos(maxPos) then oGotoXY(1,24);

   fsEdit := msgSave;
end;

end.