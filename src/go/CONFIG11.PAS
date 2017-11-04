{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config11;

interface

procedure cfgEventEditor;

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, bbsInit,
     MsgArea, Logs, DateTime;

var eF : file of tEventRec;
    Event : tEventRec;

procedure cfgInsertEvent;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   if numEvent >= maxEvent then
   begin
      oCWriteLn('|U0You may only have a maximum of '+St(maxEvent)+' events.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Insert before which event? |U5[|U61|U5-|U6'+St(numEvent+1)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numEvent+1) or (I < 1) then Exit;
   Dec(I,1);

   Reset(eF);
   if ((I >= 0) and (I <= FileSize(eF))) and (numEvent < maxEvent) then
   begin
      for Z := FileSize(eF)-1 downto I do
      begin
         Seek(eF,Z);
         Read(eF,Event);
         Write(eF,Event);
      end;
      maReset;
      Seek(eF,I);
      Write(eF,Event);
      Inc(numEvent,1);
   end;
   Close(eF);
end;

procedure cfgMoveEvent;
var K,X,Y,I,B : Word; J : Integer;
    mTemp : tEventRec;
begin
   oDnLn(2);
   if numEvent <= 1 then
   begin
      oCWriteLn('|U0There is only one event, no need to move it.');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Move which event? |U5[|U61|U5-|U6'+St(numEvent)+'|U5]: |U3');
   X := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (X > numEvent) or (X < 1) then Exit;

   oCWrite('|U1Move before which event? |U5[|U61|U5-|U6'+St(numEvent+1)+'|U5]: |U3');
   Y := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (Y > numEvent+1) or (Y < 1) then Exit;

   Dec(I,1);

   Reset(eF);

   K := Y;
   if (Y > X) then Dec(Y);
   Dec(X);
   Dec(Y);
   Seek(eF,X);
   Read(eF,mTemp);
   I := X;
   if (X > Y) then J := -1 else J := 1;
   while (I <> Y) do
   begin
      if (I+J < FileSize(eF)) then
      begin
         Seek(eF,I+J);
         Read(eF,Event);
         Seek(eF,I);
         Write(eF,Event);
      end;
      Inc(I,J);
   end;
   Seek(eF,Y);
   Write(eF,mTemp);
   Inc(X);
   Inc(Y);
   {y:=k;}
   Close(eF);
{
   if ((I >= 0) and (I <= FileSize(eF))) and (numEvent < maxEvent) then
   begin
      for Z := FileSize(eF)-1 downto I do
      begin
         Seek(eF,Z);
         Read(eF,Event);
         Write(eF,Event);
      end;
      maReset;
      Seek(eF,I);
      Write(eF,Event);
      Inc(numEvent,1);
   end;}
end;

procedure cfgDeleteEvent;
var I,X,Z,B : Byte;
begin
   oDnLn(2);
   if numEvent <= 1 then
   begin
      oCWriteLn('|U0You must have at least one event!');
      oDnLn(2);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Delete which event? |U5[|U61|U5-|U6'+St(numEvent)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numEvent) or (I < 1) then Exit;

   Dec(I,1);

   Reset(eF);
   if (I >= 0) and (I <= FileSize(eF)-2) then
   for Z := I to FileSize(eF)-2 do
   begin
      Seek(eF,Z+1);
      Read(eF,Event);
      Seek(eF,Z);
      Write(eF,Event);
   end;
   Seek(eF,FileSize(eF)-1);
   Truncate(eF);
   Dec(numEvent,1);
   Close(eF);
end;

procedure cfgEditEvent;
var an : Byte;
begin
   oDnLn(2);
   if numEvent = 0 then
   begin
      oCWriteLn('|U0Can''t continue.  No events exist.');
      oDnLn(1);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Begin edit at which event? |U5[|U61|U5-|U6'+St(numEvent)+'|U5]: |U3');
   An := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (An > numEvent) or (An < 1) then Exit;

   Reset(eF);
   Seek(eF,an-1);
   Read(eF,Event);

   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' Event Editor');
      cfgItem('--Event #',3,St(An),'');
      cfgItem('A Active?',3,b2st(Event.Active),
              'Is this event currently active?');
      cfgItem('B Description',40,Event.Desc,
              'A description of this event');
      cfgItem('C Time',5,Event.Time,
              'Time (24 hours format) that this event is to be executed');
      cfgItem('D Force event',3,b2st(Event.Force),
              'Hangup on user online when the event is about to run');
      cfgItem('E Always run?',3,b2st(Event.RunMissed),
              'Execute the event at the next chance possible, if it was missed?');
      cfgItem('F Offhook modem',3,b2st(Event.Offhook),
              'Offhook the modem before executing this event? (restore it when done)');
      cfgItem('G Node',3,St(Event.Node),
              'Which BBS node to run this event on (0 for all)');
      cfgItem('H Command',40,Event.Command,
              'DOS program/command to execute for this event (w/ full path)');
      cfgItem('I Last executed',5,St(Event.lastExec),
              'Day of the year that this event last ran.  (today is day #'+st(dtDayNum(dtDateString))+')');
      cfgItem('[ Previous event',0,'','');
      cfgItem('] Next event',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadBoolean(Event.Active);
                 cfgSetItem(B2St(Event.Active));
              end;
        'B' : begin
                 cfgReadInfo(Event.Desc,inNormal,chNormal,'',False);
                 Event.Desc := cfgRead;
                 cfgSetItem(Event.Desc);
              end;
        'C' : begin
                 cfgReadTime;
                 Event.Time := cfgRead;
                 cfgSetItem(Event.Time);
              end;
        'D' : begin
                 cfgReadBoolean(Event.Force);
                 cfgSetItem(B2St(Event.Force));
              end;
        'E' : begin
                 cfgReadBoolean(Event.RunMissed);
                 cfgSetItem(B2St(Event.RunMissed));
              end;
        'F' : begin
                 cfgReadBoolean(Event.Offhook);
                 cfgSetItem(B2St(Event.Offhook));
              end;
        'G' : begin
                 cfgReadInfo(St(Event.Node),inUpper,chNumeric,'',True);
                 Event.Node := mClip(StrToInt(cfgRead),0,maxNode);
                 cfgSetItem(St(Event.Node));
              end;
        'H' : begin
                 cfgEditInfo(Event.Command,200,inNormal,chDirectory,'',False);
                 Event.Command := cfgRead;
                 cfgSetItem(Event.Command);
              end;
        'I' : begin
                 cfgReadInfo(St(Event.lastExec),inUpper,chNumeric,'',True);
                 Event.lastExec := mClip(StrToInt(cfgRead),1,64000);
                 cfgSetItem(St(Event.lastExec));
              end;
        '[' : begin
                 Seek(eF,an-1);
                 Write(eF,Event);
                 if An = 1 then An := numEvent else Dec(An);
                 Seek(eF,an-1);
                 Read(eF,Event);

                 cfgDraw := True;
                 cfgOver := True;
              end;
        ']' : begin
                 Seek(eF,an-1);
                 Write(eF,Event);
                 if An >= numEvent then An := 1 else Inc(An);
                 Seek(eF,an-1);
                 Read(eF,Event);

                 cfgDraw := True;
                 cfgOver := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
   Seek(eF,an-1);
   Write(eF,Event);
   Close(eF);
end;

procedure cfgEventEditor;
var cmdEvEdit : array[1..5] of String;
begin
   cmdEvEdit[1] := 'I nsert';
   cmdEvEdit[2] := 'D elete';
   cmdEvEdit[3] := 'E dit';
   cmdEvEdit[4] := 'M ove';
   cmdEvEdit[5] := 'Esc Quit';

   cfgDone := False;
   logWrite('*Event edit.');
   repeat
      oClrScr;
      cfgDraw := True;
      cfgOver := False;
      PausePos := 1;
      PauseAbort := False;

      oSetCol(colText);

      oCWriteLn(' '+Resize('Num',4)+
                ' '+Resize('Description',26)+
                ' '+Resize('Time',6)+
                ' '+Resize('Node',4)+
                ' Command');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(2);

      numEvent := 0;

      Assign(eF,Cfg^.pathData+fileEvent);
      {$I-}
      Reset(eF);
      {$I+}
      if ioResult <> 0 then
      begin
         FillChar(Event,SizeOf(Event),0);
         with Event do
         begin
            Active    := False;
            Desc      := 'New '+bbsTitle+' event';
            Time      := '00:00';
            Force     := True;
            RunMissed := True;
            OffHook   := True;
            Node      := 0;
            Command   := '';
         end;
         Rewrite(eF);
         Write(eF,Event);
         Close(eF);
         Reset(eF);
      end;
      while (not PauseAbort) and (not Eof(eF)) do
      begin
         Read(eF,Event);
         Inc(numEvent);
         oSetCol(colInfo);
         oCWriteLn(' '+Resize(St(numEvent),4)+
                   ' '+Resize(Event.Desc,26)+
                   ' '+Resize(Event.Time,6)+
                   ' '+Resize(St(Event.Node),4)+
                   ' '+strSquish(Event.Command,34));
         oUpPause(1);
      end;
      numEvent := FileSize(eF);
      Close(eF);
      if numEvent = 0 then oWriteLn('No events currently exist.');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
      PausePos := 0;
      cfgPrompt(cmdEvEdit,5);
      repeat
         cfgKey := UpCase(iReadkey);
      until (HangUp) or (cfgKey in ['I','D','E','M',#27]);
      if cfgKey = #27 then oWrite('Quit') else oWriteChar(cfgKey);
      case cfgKey of
        'I' : cfgInsertEvent;
        'D' : cfgDeleteEvent;
        'E' : cfgEditEvent;
        'M' : cfgMoveEvent;
        #27 : cfgDone := True;
      end;
   until (HangUp) or (cfgDone);
end;

end.