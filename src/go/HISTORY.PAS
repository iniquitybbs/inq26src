{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,N-,E+}
unit History;

interface

procedure hisLoad;
procedure hisSave;
procedure hisView;

implementation

uses
   Global, Misc, DateTime, Logs, StrProc, Showfile, Output;

procedure hisLoad;
var F : file of tHistoryRec; X : tHistoryRec;
begin
   with his^ do
   begin
      Date := dtDateString;
      Calls := 0;
      NewUsers := 0;
      Posts := 0;
      Email := 0;
      Uploads := 0;
      Downloads := 0;
      UploadKb := 0;
      DownloadKb := 0;
   end;
   Assign(F,Cfg^.pathData+fileHistory);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult <> 0 then Exit;
      Write(F,His^);
   end else
   begin
      if fileSize(f) = 0 then Write(F,his^);
      Seek(F,FileSize(F)-1);
      Read(F,x);
      if x.date <> his^.Date then Write(f,his^) else his^ := x;
   end;
   Close(F);
end;

procedure hisSave;
var F : file of tHistoryRec; X : tHistoryRec;
begin
   Assign(F,Cfg^.pathData+fileHistory);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(f);
      {$I+}
      if ioresult <> 0 then Exit;
   end;
   if fileSize(f) = 0 then Write(F,His^);
   Seek(F,FileSize(F)-1);
   Read(F,X);
   if His^.Date = X.Date then Seek(F,FileSize(F)-1);
   Write(F,His^);
   Close(F);
end;

procedure hisView;
var Ans : Boolean; f : file of tHistoryRec; h : tHistoryRec; n : Word;
begin
   logWrite('Viewed system history');
   Assign(f,cfg^.pathData+fileHistory);
   {$I-}
   Reset(f);
   {$I+}
   if ioResult <> 0 then Exit;
   if FileSize(f) < 1 then
   begin
      Close(f);
      Exit;
   end;
   PausePos := 1;
   PauseAbort := False;
   Ans := (sfGetTextFile(txHistTop,ftTopLine) <> '') and
          (sfGetTextFile(txHistMid,ftHistory) <> '') and
          (sfGetTextFile(txHistBot,ftNormal)  <> '');
   if Ans then
   begin
      sfShowTextFile(txHistTop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txHistMid);
   end else
   begin
      oDnLn(1);
      oSetCol(colInfo);
      oWriteLn(' '+Resize('Date',12)+
               ' '+Resize('Calls',6)+
               ' '+Resize('New',5)+
               ' '+Resize('Posts',7)+
               ' '+Resize('Email',7)+
               ' '+Resize('# ULs',7)+
               ' '+Resize('# DLs',7)+
               ' '+Resize('UL kb',7)+
               ' DL kb');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(3);
      oSetCol(colText);
   end;
   n := 0;
   while (not HangUp) and (not Eof(f)) and (not PauseAbort) do
   begin
      Read(f,h);
      Inc(n);
      if Ans then
      begin
         sfStr[1] := h.date;
         sfStr[2] := stc(h.calls);
         sfStr[3] := stc(h.newusers);
         sfStr[4] := stc(h.posts);
         sfStr[5] := stc(h.email);
         sfStr[6] := stc(h.uploads);
         sfStr[7] := stc(h.downloads);
         sfStr[8] := stc(h.uploadkb);
         sfStr[9] := stc(h.downloadkb);
         sfShowRepeat(ftHistory);
         if oWhereX <> 1 then oDnLn(1);
         oUpPause(1);
      end else
      begin
         oWriteLn(' '+Resize(h.date,12)+
                  ' '+Resize(stc(h.calls),6)+
                  ' '+Resize(stc(h.newusers),5)+
                  ' '+Resize(stc(h.posts),7)+
                  ' '+Resize(stc(h.email),7)+
                  ' '+Resize(stc(h.uploads),7)+
                  ' '+Resize(stc(h.downloads),7)+
                  ' '+Resize(stc(h.uploadkb),7)+
                  ' '+strSquish(stc(h.downloadkb),7));
         oUpPause(1);
      end;
   end;
   sfKillRepeat;
   Close(f);
   if Ans then
   begin
      sfShowTextFile(txHistBot,ftNormal);
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
