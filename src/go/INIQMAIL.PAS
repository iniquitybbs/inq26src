{F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
{$M 40000,0,100000}

(*                                                                          *)
(*   Iniquity EchoMail Manager                                              *)
(*   (C)Copyright 1994, Mike Fricker                                        *)
(*                                                                          *)

program iniqMail;

uses
   Dos, Crt, Global, FastIO, Strings, Misc; {, Files, Misc, Strings, MsgArea, DateTime;}

type
   tMailOp = (mailNone,mailScan,mailToss,mailPurge,mailReset);

   tFidoHeadRec = record
      maFrom,
      maTo           : array[1..36] of Char;
      maSubject      : array[1..72] of Char;
      maDate         : array[1..20] of Char;
      maTimesRead,
      nodeDest,
      nodeOrig,
      maCost,
      netOrig,
      netDest,
      zoneOrig
      zoneDest,
      pointOrig,
      pointDest       : Integer;
      maRef           : Integer;
      maAttrL,
      maAttrH         : Byte;
      UnReply         : Integer;
   end;

var
   fCfg   : file of tCfgRec;
   fMa    : file of tMsgAreaRec;
   aOpen  : Boolean;
   mailOp : tMailOp;

procedure mailError;
begin
   if cfg <> nil then Dispose(cfg);
   if mArea <> nil then Dispose(mArea);
   if aOpen then Close(fMa);
   ioTextAttr($07);
   ioWrite(' '#8);
   Halt(255);
end;

procedure mailInit;
begin
   cfg := nil;
   mArea := nil;
   aOpen := False;

   TextMode(co80);
   ioInitFastIO;
   ioClrScr;
   ioCwriteLn('|08%% |15iniqMail |07v'+bbsVersion+'|08  |07(c)Copyright 1995, Mike Fricker; all rights reserved');
   ioCwriteLn('|08'+sRepeat('Ä',80));
   ioGotoXY(1,3);

   Assign(fCfg,fileConfig);
   {$I-} Reset(fCfg); {$I+}
   if ioResult <> 0 then
   begin
      ioCwriteLn('|12'+fileConfig+' |04not found in current directory.');
      ioCwriteLn('|04Please change to your Iniquity directory before executing iniqMail.');
      mailError;
   end;

   New(cfg);
   Read(fCfg,cfg^);
   Close(fCfg);

   Assign(fMa,Cfg^.pathData+fileMsgArea);
   {$I-} Reset(fMa); {$I+}
   if ioResult <> 0 then
   begin
      ioCwriteLn('|12'+fileMsgArea+' |04not found in your data directory ('+Cfg^.pathData+').');
      ioCwriteLn('|04Please ensure that your pathnames are configured properly in Iniquity.');
      mailError;
   end;
   aOpen := True;
   New(mArea);
end;

procedure mailEnd;
begin
   Dispose(cfg);
   Dispose(mArea);
   Close(fMa);
   ioTextAttr($07);
   ioWrite(' '#8);
end;

procedure mailProcess;
begin
   if mailOp = mailNone then
   begin
      if ParamCount = 0 then ioCwriteLn('|04No mail operation specified') else
                             ioCwriteLn('|04Invalid mail command');
      ioCwriteLn('');
      ioCwriteLn('|08syntax: |15'+paramStr(0)+' |07<command>');
      ioCwriteLn('');
      ioCwriteLn(' |15scan     |07scan/export new outbound messages');
      ioCwriteLn(' |15toss     |07toss incoming messages to echomail msg areas');
      ioCwriteLn(' |15purge    |07destroy messages in echomail directories');
      ioCwriteLn(' |15reset    |07reset echoscan pointers to current date');
      mailError;
   end;

   Seek(fMa,0);
   while not Eof(fMa) do
   begin
      Read(fMa,mArea^);
      if mArea^.areaType = mareaEchomail then
      begin
         ioGotoXY(1,ioWhereY);
         ioClrEol;
         ioCwrite('|09a|01nalyzing |09a|01rea|08: |09'+mArea^.name+'|08 ...');

      end;
   end;
end;

begin
   mailInit;

   mailOp := mailNone;
   if mParam('SCAN')  then mailOp := mailScan else
   if mParam('TOSS')  then mailOp := mailToss else
   if mParam('PURGE') then mailOp := mailPurge else
   if mParam('RESET') then mailOp := mailReset;

   mailProcess;

   mailEnd;
end.