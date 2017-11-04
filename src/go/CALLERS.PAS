{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Callers;

interface

uses Global;

procedure callAdd;
procedure callLastCallersShow(All : Boolean);
procedure callLoad(N : Word; var C : tCallRec);

implementation

uses Misc, Logs, Strings, ShowFile, Output, DateTime;

procedure callAdd;
var F : file of tCallRec; C : tCallRec;
begin
   if (LocalIO) and (not Cfg^.AddLocalCalls) then Exit;
   Assign(F,Cfg^.pathData+fileCalls);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult <> 0 then Exit;
   end else
   begin
      if FileSize(F) > 0 then
      begin
         Read(F,C);
         if C.Date <> dtDateString then
         begin
            Close(F);
            Rewrite(F);
         end else Seek(F,FileSize(F));
      end;
   end;
   FillChar(C,SizeOf(C),0);
   with C do
   begin
      CallNum := Stat^.Calls;
      Username := User^.Username;
      Usernum := User^.Number;
      Location := User^.Location;
      Baud := User^.Baudrate;
      Date := dtDateString;
      Time := dtTimeStr12;
      NewUser := NewUserOn;
      AreaCode := mAreaCode;
   end;
   Write(F,C);
   Close(F);
end;

procedure callLoad(N : Word; var C : tCallRec);
var F : file of tCallRec; X : Integer;
begin
   FillChar(C,SizeOf(C),0);
   Assign(F,Cfg^.pathData+fileCalls);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   X := FileSize(F);
   X := X-N;
   if X >= 0 then
   begin
      Seek(F,X);
      Read(F,C);
   end;
   Close(F);
end;

procedure callLastCallersShow(All : Boolean);
var Ans : Boolean; F : file of tCallRec; C : tCallRec; N, Os : Word;
begin
   Assign(F,Cfg^.pathData+fileCalls);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Os := Cfg^.numLastCalls;
   if All then Os := FileSize(F);
   if Os > FileSize(F) then Os := FileSize(F);
   if All then logWrite('Displayed today''s callers') else
               logWrite('Displayed last callers listing');
   Ans := (sfGetTextFile(txLastCtop,ftTopLine) <> '') and
          (sfGetTextFile(txLastCmid,ftLastCalls) <> '') and
          (sfGetTextFile(txLastCbot,ftNormal) <> '');
   PausePos := 1;
   PauseAbort := False;
   if Ans then
   begin
      sfShowTextFile(txLastCtop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txLastCmid);
   end else
   begin
      oClrScr;
      oDnLn(1);
      oSetCol(colInfo);
      oCWriteLn('|U4 Num   Username                 Location              New  Baud    Time');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(3);
      oSetCol(colText);
   end;
   N := 0;
   Seek(F,FileSize(F)-Os);
   for N := 1 to Os do
   begin
      Read(F,C);
      if Ans then
      begin
         sfStr[1] := St(C.Callnum);
         sfStr[2] := C.Username;
         sfStr[3] := St(C.Usernum);
         sfStr[4] := C.Location;
         sfStr[5] := mBaudString(C.Baud);
         sfStr[6] := C.Date;
         sfStr[7] := C.Time;
         sfStr[8] := b2St(C.Newuser);
         sfStr[9] := C.AreaCode;
         sfShowRepeat(ftLastCalls);
         if oWhereX <> 1 then oDnLn(1);
         oUpPause(1);
      end else
      begin
         oCWriteLn(' '+Resize(St(C.Callnum),5)+
                   ' '+Resize(C.Username,24)+
                   ' '+Resize(C.Location,21)+
                   ' '+Resize(b2St(C.Newuser),4)+
                   ' '+Resize(mBaudString(C.Baud),7)+
                   ' '+strSquish(C.Time,7));
         oUpPause(1);
      end;
      if PauseAbort then Break;
   end;
   sfKillRepeat;
   Close(F);
   if Ans then
   begin
      sfShowTextFile(txLastCbot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
   end;
   PausePos := 0;
end;

end.