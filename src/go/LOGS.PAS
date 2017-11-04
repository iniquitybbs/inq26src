{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Logs;

interface

procedure logChatWrite(toLog : String);
procedure logWrite(toLog : String);

implementation

uses Global, Strings, Misc, DateTime;

procedure logWrite(toLog : String);
var F : Text; S, Pre : String;
begin
   if Cfg^.NoBBSlogging then Exit;
   if toLog[Length(toLog)] = '.' then Delete(toLog,Length(toLog),1);
   S := dtDateString;
   S[3] := '-';
   S[6] := '-';
   Assign(F,Cfg^.pathLogs+S+extLog);
   {$I-}
   Append(F);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult <> 0 then Exit;
      WriteLn(F,'%% '+bbsTitle+' version '+bbsVersion+'; System log file');
      WriteLn(F,'%% Created '+dtDateFullString(dtDateString)+' at '+dtTimeStr12);
      WriteLn(F,sRepeat('=',79));
   end;
   Pre := '    ';
   if Length(toLog) > 0 then
   begin
      case toLog[1] of
        '*' : Pre := '  * ';
        '>' : Pre := '';
        '-' : Pre := '  - ';
        'x' : Pre := '  x ';
      end;
      if toLog[1] in ['*','-','>','x'] then Delete(toLog,1,1);
   end;
   {$I-}
   if toLog = '' then WriteLn(F) else WriteLn(F,Resize(dtTimeStr12,9)+Pre+NoColor(toLog));
   {$I+}
   Close(F);
end;

procedure logChatWrite(toLog : String);
var F : Text;
begin
   if Cfg^.NoBBSlogging then Exit; { ---- }
   Assign(F,Cfg^.pathLogs+fileChatLog);
   {$I-}
   Append(F);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult <> 0 then Exit;
      WriteLn(F,' -- '+bbsTitle+' Version '+bbsVersion+' Chat Logging File');
      WriteLn(F,'    Created '+dtDateFullString(dtDateString)+' at '+dtTimeStr12);
      WriteLn(F,sRepeat('Ä',79));
   end;
   {$I-}
   WriteLn(F,toLog);
   {$I+}
   Close(F);
end;

end.