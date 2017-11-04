{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}

unit Emulate;

interface

procedure emuAnsiInit;
procedure emuAnsiWriteChar(Ch : Char); far;
procedure emuANSitoScreen;
procedure emuANSiWrite(S : String); far;
procedure emuANSiWriteLn(S : String); far;
procedure emuScreenToANSi;

implementation

uses Crt,
     Global, ShowFile, FastIO, Output, Strings, Files;

var
   ansiCode   : String;
   ansiSaveX  : Byte;
   ansiSaveY  : Byte;
   ansiEsc    : Byte;
   avtCmd     : Byte;
   avtStage   : Byte;
   avtPar1    : Byte;
   avtPar2    : Byte;

procedure emuAnsiInit;
begin
   ansiCode := '';
   ansiSaveX := 1;
   ansiSaveY := 1;
   ansiEsc := 0;
   avtCmd := 0;
   avtStage := 0;
   avtPar1 := 0;
   avtPar2 := 0;
end;

function ansiNum : Byte;
var i, j, k : Integer; temp1 : String;
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
                       if Ord(ansiCode[0]) = 0 then ansiCode := '0';
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
                       Y := ioWhereY-Y;
                       if Y < 1 then Y := 1;
                       ioGotoXY(ioWhereX,Y);
                    end;
         'B'      : begin
                       ansiEsc := 0;
                       Y := ansiNum;
                       if Y = 0 then Y := 1;
                       Y := ioWhereY+Y;
                       if Y > 25 then Y := 25;
                       ioGotoXY(ioWhereX,Y);
                    end;
         'C'      : begin
                       ansiEsc := 0;
                       X := ansiNum;
                       if X = 0 then X := 1;
                       X := ioWhereX+X;
                       if X > 80 then X := 1;
                       ioGotoXY(X,ioWhereY);
                    end;
         'D'      : begin
                       ansiEsc := 0;
                       X := ansiNum;
                       if X = 0 then X := 1;
                       X := ioWhereX-X;
                       if X < 1 then X := 1;
                       ioGotoXY(X,ioWhereY);
                    end;
         's'      : begin
                       ansiEsc := 0;
                       ansiSaveX := ioWhereX;
                       ansiSaveY := ioWhereY;
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
      ^C : begin ioGotoXY(ioWhereX,ioWhereY-1); avtCmd := 0; end;
      ^D : begin ioGotoXY(ioWhereX,ioWhereY+1); avtCmd := 0; end;
      ^E : begin ioGotoXY(ioWhereX-1,ioWhereY); avtCmd := 0; end;
      ^F : begin ioGotoXY(ioWhereX+1,ioWhereY); avtCmd := 0; end;
      ^G : begin ioClrEol; avtCmd := 0; end;
      ^H : begin avtCmd := 3; avtStage := 1; end;
     else avtCmd := 0;
   end else
   begin
      case Ch of
        { Avatar/0 commands }
          ^L : begin ioTextAttr($03); ioClrScr; end;
          ^Y : begin avtCmd := 100; avtStage := 1; end;
          ^V : avtCmd := 1;

         #27 : ansiEsc := 1;
         #9  : begin
                  X := ((ioWhereX div 8)+1)*8;
                  ioGotoXY(X, ioWhereY);
               end;
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
    Screen   : ScreenType absolute $b800:0000;
    ThisAttr, TestAttr : byte;
    LoopRow, LoopCol, LineLen, numR : integer;
  begin {Xlate}
    ThisAttr := $FF; {Force attribute to be set}
    if Cfg^.StatBarOn then numR := 24 else numR := 25;
    For LoopRow := 1 to numR do begin

      LineLen := NUMCOLS;   {Find length of line}
      While (LineLen > 0) and (Screen[LoopRow, LineLen].ch = ' ')
            and not AttrChanged($00, Screen[LoopRow, LineLen])
        do Dec(LineLen);

      For LoopCol := 1 to LineLen do begin {Send stream to file}
        If AttrChanged(ThisAttr, Screen[LoopRow, LoopCol])
          then ChangeAttr(Outfile, ThisAttr, Screen[LoopRow, LoopCol].Attr);
        write(Outfile, Screen[LoopRow, LoopCol].ch);
      end;
    If (LineLen < 80) and (LoopRow <> numR) then writeln(OutFile); {else wraparound occurs}
    end;
  end; {Xlate}

begin
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
end;

procedure emuANSitoScreen;
begin
   sfShowFile(fTempPath('T')+fileTempScr,ftNoCode);
   oGotoXY(scrX,scrY);
   oSetColRec(scrCol);
end;

end.