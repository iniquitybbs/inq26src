{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit MCIcodes;

interface

function mciProcess(S : String; Len : Byte) : String;
function mciProcessControlCode(C : String) : Boolean;
function mciProcessMCICode(C : String) : Boolean;

implementation

uses Crt,
     Global, Output, Strings, Misc, DateTime, Input;

function mciProcessControlCode(C : String) : Boolean;
begin
   mciProcessControlCode := False;
   if (Length(C) <> 3) or (C[1] <> ctrHeader) then Exit;
   Delete(C,1,1);
   C := UpStr(C);
   mciProcessControlCode := True;
   case C[1] of
     '0' : case C[2] of
             '0' : oSetFore(0);
             '1' : oSetFore(1);
             '2' : oSetFore(2);
             '3' : oSetFore(3);
             '4' : oSetFore(4);
             '5' : oSetFore(5);
             '6' : oSetFore(6);
             '7' : oSetFore(7);
             '8' : oSetFore(8);
             '9' : oSetFore(9);
           end;
     '1' : case C[2] of
             '0' : oSetFore(10);
             '1' : oSetFore(11);
             '2' : oSetFore(12);
             '3' : oSetFore(13);
             '4' : oSetFore(14);
             '5' : oSetFore(15);
             '6' : oSetBack(0);
             '7' : oSetBack(1);
             '8' : oSetBack(2);
             '9' : oSetBack(3);
           end;
     '2' : case C[2] of
             '0' : oSetBack(4);
             '1' : oSetBack(5);
             '2' : oSetBack(6);
             '3' : oSetBack(7);
           end;
     'A' : case C[2] of
              'S' : saveCol := Col;
              'L' : oSetColRec(saveCol);
           end;
     'B' : case C[2] of
             '0' : oSetBack(0);
             '1' : oSetBack(1);
             '2' : oSetBack(2);
             '3' : oSetBack(3);
             '4' : oSetBack(4);
             '5' : oSetBack(5);
             '6' : oSetBack(6);
             '7' : oSetBack(7);
           end;
     'C' : case C[2] of
              'B' : oMoveDown(25);
              'D' : oMoveDown(1);
              'E' : oMoveRight(80);
              'H' : oMoveLeft(80);
              'L' : oMoveLeft(1);
              'R' : oMoveRight(1);
              'S' : oClrScr;
              'T' : oMoveUp(25);
              'U' : oMoveUp(1);
              'Z' : oClrEol;
           end;
     'D' : case C[2] of
              'E' : Delay(750);
              'H' : Delay(500);
              'M' : Delay(100);
              'S' : Delay(1000);
           end;
     'H' : case C[2] of
              'C' : oGotoXY(1,1);
           end;
     'L' : case C[2] of
              'C' : oRestoreCursor;
              'F' : oWrite(#13#10);
           end;
     'P' : case C[2] of
              'A' : oPromptKey;
              'K' : iReadKey;
              'S' : oPause;
           end;
     'S' : case C[2] of
              'C' : oSaveCursor;
           end;
     'U' : case C[2] of
              '0' : oSetCol(colError);
              '1' : oSetCol(colText);
              '2' : oSetCol(colTextLo);
              '3' : oSetCol(colTextHi);
              '4' : oSetCol(colInfo);
              '5' : oSetCol(colInfoLo);
              '6' : oSetCol(colInfoHi);
              '7' : oSetCol(colItem);
              '8' : oSetCol(colItemSel);
              '9' : oSetCol(colBorder);
           end;
     else mciProcessControlCode := False;
   end;
end;

function mciProcessMCICode(C : String) : Boolean;
var S : String;
begin
   mciProcessMCIcode := False;
   S := '';
   C := UpStr(C);
   if (Length(C) <> 3) or (C[1] <> mciHeader) then Exit;
   mciProcessMCIcode := True;
   Delete(C,1,1);
   case C[1] of
     'A' : case C[2] of
         '1'..'6' : if User^.AutoSigLns >= StrToInt(C[2]) then
                    S := User^.AutoSig[StrToInt(C[2])] else S := '';
              'C' : S := mAreaCode;
              'D' : S := User^.Address;
              'L' : S := St(User^.AutoSigLns);
              'Q' : S := B2St(acQuote in User^.acFlag);
           end;
     'B' : case C[2] of
              'D' : S := User^.Birthdate;
              'L' : S := Cfg^.bbsLocation;
              'N' : S := Cfg^.BBSname;
              'P' : S := Cfg^.BBSphone;
              'R' : S := mBaudString(User^.BaudRate);
           end;
     'C' : case C[2] of
              'F' : S := fConf^.Desc;
              'M' : S := mConf^.Desc;
              'T' : S := Stc(User^.CallsToday);
           end;
     'D' : case C[2] of
              'C' : S := Stc(His^.Calls);
              'D' : S := Stc(His^.Downloads);
              'F' : S := dtDateFullString(dtDateString);
              'K' : S := Stc(User^.DownloadKb)+'k';
              'L' : S := Stc(User^.Downloads);
              'P' : S := Stc(His^.Posts);
              'S' : S := St(User^.DSL);
              'T' : S := dtDateString;
              'U' : S := Stc(His^.Uploads);
           end;
     'E' : case C[2] of
              'M' : S := mEmulation(User^);
           end;
     'F' : case C[2] of
              'A' : S := fArea^.Name;
              'C' : S := User^.FirstCall;
              'D' : S := User^.fileScan;
              'P' : S := St(User^.filePts);
              'I' : S := St(User^.curFileArea);
              'S' : S := User^.fileScan;
           end;
     'H' : case C[2] of
              'K' : S := B2St(acHotKey in User^.acFlag);
           end;
     'I' : case C[2] of
              'D' : S := St(User^.Number);
              'N' : S := bbsTitle;
              'S' : S := inputString;
              'V' : S := bbsVersion;
           end;
     'L' : case C[2] of
              'A' : if tLibOpen then S := textLib^.Author else S := 'n/a';
              'C' : S := User^.LastCall;
              'D' : if tLibOpen then S := textLib^.Desc else S := 'n/a';
              'O' : S := User^.Location;
           end;
     'M' : case C[2] of
              'A' : S := mArea^.Name;
              'I' : S := St(User^.curMsgArea);
              'N' : S := St(curMsg);
              'P' : S := Menu^.PromptName;
              'T' : S := St(numMsg);
              'W' : S := St(User^.EmailWaiting);
           end;
     'N' : case C[2] of
              'D' : S := St(node);
           end;
     'P' : case C[2] of
              'A' : S := B2St(acPause in User^.acFlag);
              'L' : S := St(User^.PageLength);
              'N' : S := User^.PhoneNum;
              'W' : S := User^.Password;
           end;
     'R' : case C[2] of
              'N' : S := User^.RealName;
              'T' : S := ripTerm;
           end;
     'S' : case C[2] of
              'L' : S := St(User^.SL);
              'N' : S := Cfg^.SysOpAlias;
              'O' : S := User^.SysopNote;
              'R' : S := Cfg^.SysOpName;
              'X' : S := mSexString(User^.Sex);
           end;
     'T' : case C[2] of
              'C' : S := Stc(Stat^.Calls);
              'D' : S := Stc(Stat^.Downloads);
              'E' : S := Stc(Stat^.Email);
              'I' : S := dtTimeStr12;
              'L' : S := St(mTimeLeft('M'));
              'M' : S := dtTimeStr24;
              'P' : S := Stc(Stat^.Posts);
              'T' : S := St(User^.TimePerDay);
              'U' : S := Stc(numUsers);
              'Z' : S := mRatio(Stat^.Posts,Stat^.Calls);
           end;
     'U' : case C[2] of
              'A' : S := User^.Level;
              'C' : S := Stc(User^.TotalCalls);
              'E' : S := Stc(User^.Email);
              'I' : S := mInitials(User^.Username);
              'K' : S := Stc(User^.UploadKb)+'k';
              'L' : S := Stc(User^.Uploads);
              'N' : S := User^.UserName;
              'O' : S := User^.UserNote;
              'P' : S := Stc(User^.Posts);
              'Z' : S := mRatio(User^.Posts,User^.TotalCalls);
           end;
     'V' : case C[2] of
              'L' : S := bbsVerLong;
              'N' : S := Stc(User^.voteNo);
              'Y' : S := Stc(User^.voteYes);
           end;
     'X' : case C[2] of
              'M' : S := B2St(acExpert in User^.acFlag);
           end;
     'Y' : case C[2] of
              'N' : S := B2St(acYesNoBar in User^.acFlag);
           end;
     '@' : case C[2] of
         'A'..'Z' : S := B2St(C[2] in User^.Flag);
           end;
     else begin mciProcessMCIcode := False; S := mciHeader+C; end;
   end;
   mciString := S;
end;

function mciProcess(S : String; Len : Byte) : String;
var Cd : String; N : Byte;
begin
   mciProcess := '';
   N := 0;
   if S = '' then Exit;
   while N < Length(S) do
   begin
      Inc(N);
      if S[N] = mciHeader then
      begin
         if mciProcessMCICode(Copy(S,N,3)) then
         begin
            Delete(S,N,3);
            if Len <> 0 then mciString := strSquish(mciString,Len);
            Insert(mciString,S,N);
            Dec(N);
         end;
      end;
   end;
   mciProcess := S;
end;

end.