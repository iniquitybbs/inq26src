{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,N-,E+}

unit Events;

interface

procedure eventNext;
procedure eventReset;
function  eventScan : boolean;

implementation

uses
   Crt, Global, StrProc, DateTime, Files, Logs, Output, Comm;

var
   ignore : array[1..maxevent] of boolean;

procedure eventReset;
begin
   fillchar(ignore,maxevent,0);
end;

procedure eventNext;
var fe : file;
    closest, cevent, ddiff, tdiff, today, ntime, etime : LongInt;
begin
   curEvent := 0;
   Assign(fe,cfg^.pathData+fileEvent);
   if not fopen(fe,sizeof(teventrec),fflock+ffwait) then
   begin
      numEvent := 0;
      Exit;
   end;
   closest := 80000000;
   cevent := 0;
   ntime := dtTimeSec(dtTimeStr24);
   today := dtDayNum(dtDateString);
   while not eof(fe) do with event^ do
   begin
      Inc(curEvent);
      Blockread(fe,event^,1);
      etime := dtTimeSec(time);
      tdiff := dtSecDiff(ntime,etime);
      ddiff := today-lastExec;
      if (active) and (not ignore[curevent]) and ((event^.node = 0) or (event^.node = global.node)) and
         (ddiff > 0) then
      begin
         if etime = ntime then
         begin
            cevent := curEvent;
            closest := 0;
         end else
         if etime < ntime then
         begin
            if (runMissed) then
            begin
               cevent := curEvent;
               closest := 0;
            end;
         end else
         if tdiff < closest then
         begin
            cevent := curEvent;
            closest := tdiff;
         end;
      end;
   end;
   numEvent := curEvent;
   if cevent > 0 then
   begin
      Seek(fe,cevent-1);
      Blockread(fe,event^,1);
   end;
   curEvent := cevent;
   Close(fe);
end;

function eventRun : boolean;
begin
   eventRun := false;
   if (not event^.active) or ((event^.node <> 0) and (event^.node <> node))
                          or (ignore[curevent]) then exit;
   logWrite('Event: '+event^.desc+' @ '+dtTimeStr12+' on node '+st(node));
   if (not hangup) and (useron) then
   begin
      if event^.force then
      begin
         oStringLn(strEventNowBye);
         logWrite(User^.username+' was forced off for event initialization');
         Hangup := true;
      end else
      begin
         logWrite(User^.username+' is online, event will be executed later');
         ignore[curEvent] := True;
         Exit;
      end;
   end;
   event^.lastExec := dtDayNum(dtDateString);
   if (not modemoff) and (event^.offhook) then
   begin
      delay(1000);
      cModemWrite(modem^.sOffHook);
   end;
   if event^.command <> '' then fShellDos(event^.command,true,true,false);
   if (not modemoff) and (event^.offhook) then
   begin
      delay(1000);
      cModemWrite(modem^.sHangup);
   end;
   eventRun := True;
end;

function eventScan : boolean;
var ddiff, today, ntime, etime : LongInt; doit, newone : boolean;
    fe : file;
begin
   eventScan := false;
   if (ignore[curevent]) or (numEvent = 0) or (curEvent = 0) or (not event^.active) then exit;

   today := dtDayNum(dtDateString);
   etime := dtTimeSec(event^.time);
   ntime := dtTimeSec(dtTimeStr24);
   ddiff := today-event^.lastExec;

   doit := false;
   newone := false;
   if (event^.active) and ((event^.node = 0) or (event^.node = node)) and (ddiff > 0) then
   begin
      if ddiff > 1 then doit := true else
      if etime = ntime then doit := true else
      if (etime < ntime) and (event^.runMissed) then doit := true else
      if etime > ntime then newone := true;
   end else
   if ddiff <= 0 then newone := true;

   if doit then
   begin
      if eventRun then
      begin
         ignore[curevent] := true;
         assign(fe,cfg^.pathdata+fileevent);
         if fopen(fe,sizeof(teventrec),ffwait+fflock) then
         begin
            seek(fe,curevent-1);
            blockwrite(fe,event^,1);
            close(fe);
         end;
      end;
      eventNext;
      eventScan := True;
   end else
   if (newone) and (numEvent > 1) then eventNext;
end;

end.
