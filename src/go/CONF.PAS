{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Conf;

interface

uses Global;

procedure confDefault(Msg : Boolean);
procedure confList(Msg : Boolean);
procedure confLoad(Msg : Boolean);
procedure confReset(Msg : Boolean);
procedure confSave(Msg : Boolean);
procedure confSelect(Msg : Boolean; Par : String);

implementation

uses Logs, Output, Input, Misc, Strings, Showfile, MsgArea, FileArea;

procedure confDefault(Msg : Boolean);
var C : ^tConfRec;
begin
   if Msg then C := @mConf^ else C := @fConf^;
   FillChar(C^,SizeOf(C^),0);
   with C^ do
   begin
      if Msg then Desc := 'New Message Conference' else
                  Desc := 'New File Conference';
      Acs := '';
      Key := 'X';
   end;
end;

procedure confReset(Msg : Boolean);
var F : file of tConfRec; C : ^tConfRec; N, X : Word;
begin
   if Msg then
   begin
      C := @mConf^;
      N := User^.confMsg;
      Assign(F,Cfg^.pathData+fileConfMsg);
   end else
   begin
      C := @fConf^;
      N := User^.confFile;
      Assign(F,Cfg^.pathData+fileConfFile);
   end;
   {$I-}
   Rewrite(F);
   {$I+}
   if ioResult <> 0 then Exit;
   confDefault(Msg);
   Write(F,C^);
   Close(F);
   if Msg then numMsgConf := 1 else numFileConf := 1;
end;

procedure confLoad(Msg : Boolean);
var F : file of tConfRec; C : ^tConfRec; N, X : Word;
begin
   if Msg then
   begin
      C := @mConf^;
      N := User^.confMsg;
      Assign(F,Cfg^.pathData+fileConfMsg);
   end else
   begin
      C := @fConf^;
      N := User^.confFile;
      Assign(F,Cfg^.pathData+fileConfFile);
   end;
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      confReset(Msg);
      Exit;
   end;
   if Msg then
   begin
      numMsgConf := FileSize(F);
      if N > numMsgConf then N := numMsgConf;
      if N < 1 then N := 1;
      User^.confMsg := N;
   end else
   begin
      numFileConf := FileSize(F);
      if N > numFileConf then N := numFileConf;
      if N < 1 then N := 1;
      User^.confFile := N;
   end;
   Seek(F,N-1);
   Read(F,C^);
   Close(F);
end;

procedure confSave(Msg : Boolean);
var F : file of tConfRec; C : ^tConfRec; N, X : Word;
begin
   if Msg then
   begin
      C := @mConf^;
      N := User^.confMsg;
      Assign(F,Cfg^.pathData+fileConfMsg);
   end else
   begin
      C := @fConf^;
      N := User^.confFile;
      Assign(F,Cfg^.pathData+fileConfFile);
   end;
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult <> 0 then Exit;
      Write(F,C^);
      if Msg then numMsgConf := 1 else numFileConf := 1;
      Exit;
   end;
   if Msg then
   begin
      numMsgConf := FileSize(F);
      if N > numMsgConf then N := numMsgConf;
      if N < 1 then N := 1;
      User^.confMsg := N;
   end else
   begin
      numFileConf := FileSize(F);
      if N > numFileConf then N := numFileConf;
      if N < 1 then N := 1;
      User^.confFile := N;
   end;
   Seek(F,N-1);
   Write(F,C^);
   Close(F);
end;

procedure confList(Msg : Boolean);
var Ans : Boolean; B : file of tConfRec; c : tConfRec; N : Word;
begin
   if Msg then
   begin
      logWrite('Changed message conference');
      Assign(B,Cfg^.pathData+fileConfMsg);
   end else
   begin
      logWrite('Changed file conference');
      Assign(B,Cfg^.pathData+fileConfFile);
   end;
   {$I-}
   Reset(B);
   {$I+}
   if ioResult <> 0 then Exit;
   if FileSize(B) < 1 then
   begin
      Close(B);
      Exit;
   end;
   PausePos := 1;
   PauseAbort := False;
   if Msg then
   Ans := (sfGetTextFile(txConfMsgTop,ftTopLine) <> '') and
          (sfGetTextFile(txConfMsgMid,ftConf) <> '') and
          (sfGetTextFile(txConfMsgBot,ftNormal)  <> '') else
   Ans := (sfGetTextFile(txConfFileTop,ftTopLine) <> '') and
          (sfGetTextFile(txConfFileMid,ftConf) <> '') and
          (sfGetTextFile(txConfFileBot,ftNormal)  <> '');
   if Ans then
   begin
      if Msg then sfShowTextFile(txConfMsgTop,ftTopLine) else
                  sfShowTextFile(txConfFileTop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      if Msg then sfLoadRepeat(txConfMsgMid) else sfLoadRepeat(txConfFileMid);
   end else
   begin
      oClrScr;
      oDnLn(1);
      oSetCol(colInfo);
      oCWriteLn('|U4 Key  Description');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(3);
      oSetCol(colText);
   end;
   N := 0;
   while (not HangUp) and (not Eof(B)) and (not PauseAbort) do
   begin
      Read(B,C);
      Inc(N);
      if acsOk(C.ACS) then
      begin
         if Ans then
         begin
            sfStr[1] := C.Key;
            sfStr[2] := C.Desc;
            sfShowRepeat(ftConf);
            if oWhereX <> 1 then oDnLn(1);
            oUpPause(1);
         end else
         begin
            oWriteLn(' '+Resize(C.Key,4)+
                     ' '+C.Desc);
            oUpPause(1);
         end;
      end;
   end;
   sfKillRepeat;
   Close(B);
   if Ans then
   begin
      if Msg then sfShowTextFile(txConfMsgBot,ftNormal) else
                  sfShowTextFile(txConfFileBot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
   end;
   PausePos := 0;
end;

function confKey(Msg : Boolean; Ch : Char) : Word;
var F : file of tConfRec; N : Word; Found : Boolean; C : tConfRec;
begin
   confKey := 0;
   if Msg then Assign(F,Cfg^.pathData+fileConfMsg) else
               Assign(F,Cfg^.pathData+fileConfFile);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   Found := False;
   N := 0;
   while (not Found) and (not Eof(F)) do
   begin
      Read(F,C);
      Inc(N);
      Found := (acsOk(C.Acs)) and (Ch = C.Key);
   end;
   if not Found then N := 0;
   confKey := N;
end;

procedure confSelect(Msg : Boolean; Par : String);
var N, Old : Word; Done : Boolean; Ch : Char;
begin
   if (Par <> '') and (UpStr(Par) <> 'LIST') then N := confKey(Msg,UpCase(Par[1])) else N := 0;
   if ((Msg) and (N > 0) and (N <= numMsgConf)) or
      ((not Msg) and (N > 0) and (N <= numFileConf)) then
   begin
      if Msg then Old := User^.confMsg else Old := User^.confFile;
      if Msg then User^.confMsg := N else User^.confFile := N;
      confLoad(Msg);
      if ((Msg) and (not (acsOk(mConf^.Acs)))) or
         ((not Msg) and (not (acsOk(fConf^.Acs)))) then
      begin
         if Msg then User^.confMsg := Old else User^.confFile := Old;
         confLoad(Msg);
      end;
      Exit;
   end;
   Done := False;
   if UpCase(Par[1]) = 'L' then confList(Msg);
   repeat
      if Msg then oString(strConfMsgSelect) else
                  oString(strConfFileSelect);
      Ch := UpCase(iReadKey);
      if Ch = '?' then
      begin
         oWrite(Ch);
         confList(Msg);
      end else Done := True;
   until (HangUp) or (Done);
   if (Ch = #13) or ((Msg)     and (Ch = mConf^.Key)) or
                    ((not Msg) and (Ch = fConf^.Key)) then
   begin
      oWriteLn(Ch);
      Exit;
   end;
   N := confKey(Msg,Ch);
   if N = 0 then
   begin
      oWriteLn('Abort');
      Exit;
   end;
   if Msg then User^.confMsg := N else
               User^.confFile := N;
   confLoad(Msg);
   if Msg then oWriteLn(mConf^.Key) else oWriteLn(fConf^.Key);
   if Msg then oStrLn(strCode(mStr(strConfMsgChanged),1,mConf^.Desc)) else
               oStrLn(strCode(mStr(strConfFileChanged),1,fConf^.Desc));
   if Msg then maFindAreaWithAccess else
               faFindAreaWithAccess;
end;

end.