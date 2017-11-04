{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config2;

interface

procedure cfgCommunicationsSetup;

implementation

uses
   Crt,
   Global, Output, Strings, Input, Files, Config, Misc, Logs;

var Mdm : tModemRec;

procedure cfgModemConfig;
var Baud, Par : Byte;
    optComPort : array[1..5] of String;
    optBaudRate : array[1..19] of String;
    optDataBits : array[1..2] of String;
    optParity : array[1..3] of String;
    optStopBits : array[1..2] of String;
begin
   optDataBits[1] := '7';
   optDataBits[2] := '8 [standard]';
   optParity[1] := 'None [standard]';
   optParity[2] := 'Even';
   optParity[3] := 'Odd';
   optStopBits[1] := '1 [standard]';
   optStopBits[2] := '2';
   optComPort[1] := 'COM1';
   optComPort[2] := 'COM2';
   optComPort[3] := 'COM3';
   optComPort[4] := 'COM4';
   optComPort[5] := 'Local';
   optBaudRate[1] := '300';
   optBaudRate[2] := '1200';
   optBaudRate[3] := '1275';
   optBaudRate[4] := '2400';
   optBaudRate[5] := '4800';
   optBaudRate[6] := '7200';
   optBaudRate[7] := '9600';
   optBaudRate[8] := '12000';
   optBaudRate[9] := '14400';
   optBaudRate[10] := '16800';
   optBaudRate[11] := '19200';
   optBaudRate[12] := '21600';
   optBaudRate[13] := '24000';
   optBaudRate[14] := '26400';
   optBaudRate[15] := '28800';
   optBaudRate[16] := '38400';
   optBaudRate[17] := '57600';
   optBaudRate[18] := '64000';
   optBaudRate[19] := '115200';
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('General Modem Options (Node '+St(Node)+')');

      Baud := 1;
      while (Baud < 20) and (strToInt(optBaudRate[Baud]) <> Mdm.BaudRate) do Inc(Baud,1);
      if Baud = 20 then begin Mdm.BaudRate := 38400; Baud := 16; end;

      case Mdm.Parity of
         'N' : Par := 1;
         'E' : Par := 2;
         'O' : Par := 3;
         else begin Mdm.Parity := 'N'; Par := 1; end;
      end;

      cfgItem('A Com Port',6,cfgOption(optComPort,Mdm.ComPort+1),
              'Modem communcations port number.');
      cfgItem('B Baud Rate',10,cfgOption(optBaudRate,Baud),
              'Maximum baud rate for this modem.');
      cfgItem('C Data Bits',12,cfgOption(optDataBits,Mdm.DataBits-6),
              'Modem communication data bits.');
      cfgItem('D Parity',16,cfgOption(optParity,Par),
              'Modem communication parity.');
      cfgItem('E Stop Bits',12,cfgOption(optStopBits,Mdm.StopBits),
              'Modem communication stop bits.');
      cfgItem('F Locked Port',3,B2St(Mdm.LockedPort),
              'Is the FOSSIL driver LOCKED at the specified baudrate? (Usually if high speed)');
      cfgItem('G Multi-Ring',3,B2St(Mdm.MultiRing),
              'Multi-Ring support, for joint data and voice phone lines');
      cfgItem('H Modem IRQ Number',1,St(Mdm.irqNumber),
              'Modem''s IRQ number, for protocols or doors.');
      cfgItem('I IRQ Address String',4,Mdm.irqString,
              'Modem''s IRQ address (usually in hex), for protocols or doors.');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 Inc(Mdm.ComPort,1);
                 cfgReadOption(optComPort,5,Mdm.ComPort);
                 cfgSetItem(cfgOption(optComPort,Mdm.ComPort));
                 Dec(Mdm.ComPort,1);
              end;
        'B' : begin
                 cfgReadOption(optBaudRate,19,Baud);
                 Mdm.BaudRate := strToInt(optBaudrate[Baud]);
                 cfgSetItem(cfgOption(optBaudRate,Baud));
              end;
        'C' : begin
                 Dec(Mdm.DataBits,6);
                 cfgReadOption(optDataBits,2,Mdm.DataBits);
                 cfgSetItem(cfgOption(optDataBits,Mdm.DataBits));
                 Inc(Mdm.DataBits,6);
              end;
        'D' : begin
                 cfgReadOption(optParity,3,Par);
                 case Par of
                    1 : Mdm.Parity := 'N';
                    2 : Mdm.Parity := 'E';
                    3 : Mdm.Parity := 'O';
                 end;
                 cfgSetItem(cfgOption(optParity,Par));
              end;
        'E' : begin
                 cfgReadOption(optStopBits,2,Mdm.StopBits);
                 cfgSetItem(cfgOption(optStopBits,Mdm.StopBits));
              end;
        'F' : begin
                 cfgReadBoolean(Mdm.LockedPort);
                 cfgSetItem(B2St(Mdm.LockedPort));
              end;
        'G' : begin
                 cfgReadBoolean(Mdm.MultiRing);
                 cfgSetItem(B2St(Mdm.MultiRing));
              end;
        'H' : begin
                 cfgReadInfo(St(Mdm.irqNumber),inUpper,chNumeric,'',False);
                 Mdm.irqNumber := mClip(strToInt(cfgRead),0,8);
                 cfgSetItem(St(Mdm.irqNumber));
              end;
        'I' : begin
                 cfgReadInfo(Mdm.irqString,inUpper,chNormal,'',False);
                 Mdm.irqString := cfgRead;
                 cfgSetItem(Mdm.irqString);
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgCommandStrings;
var iCmd : String;
begin
   cfgDraw := True;
   cfgOver := False;
   iCmd := '(''~'' = Delay, ''^'' = DTR, ''|'' = CR)  ';
   repeat
      cfgInit('Modem Command Strings');
      cfgItem('A Init String #1',45,Mdm.sInit1,
              iCmd+'Modem initialization string #1');
      cfgItem('B Init String #2',45,Mdm.sInit2,
              iCmd+'Modem initialization string #2');
      cfgItem('C Init String #3',45,Mdm.sInit3,
              iCmd+'Modem initialization string #3');
      cfgItem('D Exit String',45,Mdm.sExitStr,
              iCmd+'Sent before exiting '+bbsTitle);
      cfgItem('E Answer String',45,Mdm.sAnswer,
              iCmd+'Command to answer modem');
      cfgItem('F Hangup String',45,Mdm.sHangup,
              iCmd+'Modem hangup string');
      cfgItem('G Offhook String',45,Mdm.sOffhook,
              iCmd+'Command to offhook modem');
      cfgItem('H Dialing Prefix',45,Mdm.sDialPrefix,
              'Prefix sent to modem before phone number to dial');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Mdm.sInit1,inNormal,chNormal,'',False);
                 Mdm.sInit1 := cfgRead;
                 cfgSetItem(Mdm.sInit1);
              end;
        'B' : begin
                 cfgReadInfo(Mdm.sInit2,inNormal,chNormal,'',False);
                 Mdm.sInit2 := cfgRead;
                 cfgSetItem(Mdm.sInit2);
              end;
        'C' : begin
                 cfgReadInfo(Mdm.sInit3,inNormal,chNormal,'',False);
                 Mdm.sInit3 := cfgRead;
                 cfgSetItem(Mdm.sInit3);
              end;
        'D' : begin
                 cfgReadInfo(Mdm.sExitStr,inNormal,chNormal,'',False);
                 Mdm.sExitStr := cfgRead;
                 cfgSetItem(Mdm.sExitStr);
              end;
        'E' : begin
                 cfgReadInfo(Mdm.sAnswer,inNormal,chNormal,'',False);
                 Mdm.sAnswer := cfgRead;
                 cfgSetItem(Mdm.sAnswer);
              end;
        'F' : begin
                 cfgReadInfo(Mdm.sHangup,inNormal,chNormal,'',False);
                 Mdm.sHangup := cfgRead;
                 cfgSetItem(Mdm.sHangup);
              end;
        'G' : begin
                 cfgReadInfo(Mdm.sOffhook,inNormal,chNormal,'',False);
                 Mdm.sOffhook := cfgRead;
                 cfgSetItem(Mdm.sOffhook);
              end;
        'H' : begin
                 cfgReadInfo(Mdm.sDialPrefix,inNormal,chNormal,'',False);
                 Mdm.sDialPrefix := cfgRead;
                 cfgSetItem(Mdm.sDialPrefix);
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgResultStrings;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Modem Result Strings');
      cfgItem('A Command Error',45,Mdm.rError,
              'Returned when a modem command error occurs');
      cfgItem('B No Carrier',45,Mdm.rNoCarrier,
              'Returned when the connection is broken, and carrier is lost');
      cfgItem('C Command Ok',45,Mdm.rOk,
              'Returned when a modem command is successful');
      cfgItem('D Ring',45,Mdm.rRing,
              'Returned when the modem is ringing');
      cfgItem('E Busy',45,Mdm.rBusy,
              'Returned when a dial attempt reports a busy signal');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Mdm.rError,inNormal,chNormal,'',True);
                 Mdm.rError := cfgRead;
                 cfgSetItem(Mdm.rError);
              end;
        'B' : begin
                 cfgReadInfo(Mdm.rNoCarrier,inNormal,chNormal,'',True);
                 Mdm.rNoCarrier := cfgRead;
                 cfgSetItem(Mdm.rNoCarrier);
              end;
        'C' : begin
                 cfgReadInfo(Mdm.rOk,inNormal,chNormal,'',True);
                 Mdm.rOk := cfgRead;
                 cfgSetItem(Mdm.rOk);
              end;
        'D' : begin
                 cfgReadInfo(Mdm.rRing,inNormal,chNormal,'',True);
                 Mdm.rRing := cfgRead;
                 cfgSetItem(Mdm.rRing);
              end;
        'E' : begin
                 cfgReadInfo(Mdm.rBusy,inNormal,chNormal,'',True);
                 Mdm.rBusy := cfgRead;
                 cfgSetItem(Mdm.rBusy);
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgConnectStrings;
begin
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit('Modem Connect Messages');
      cfgItem('A Connect 300',45,Mdm.c300,
              'Connected at 300 baud');
      cfgItem('B Connect 1200',45,Mdm.c1200,
              'Connected at 1200 baud');
      cfgItem('C Connect 1275',45,Mdm.c1275,
              'Connected at 1275 baud');
      cfgItem('D Connect 2400',45,Mdm.c2400,
              'Connected at 2400 baud');
      cfgItem('E Connect 4800',45,Mdm.c4800,
              'Connected at 4800 baud');
      cfgItem('F Connect 7200',45,Mdm.c7200,
              'Connected at 7200 baud');
      cfgItem('G Connect 9600',45,Mdm.c9600,
              'Connected at 9600 baud');
      cfgItem('H Connect 12000',45,Mdm.c12000,
              'Connected at 12000 baud');
      cfgItem('I Connect 14400',45,Mdm.c14400,
              'Connected at 14400 baud');
      cfgItem('J Connect 16800',45,Mdm.c16800,
              'Connected at 16800 baud');
      cfgItem('K Connect 19200',45,Mdm.c19200,
              'Connected at 19200 baud');
      cfgItem('L Connect 21600',45,Mdm.c21600,
              'Connected at 21600 baud');
      cfgItem('M Connect 24000',45,Mdm.c24000,
              'Connected at 24000 baud');
      cfgItem('N Connect 26400',45,Mdm.c26400,
              'Connected at 26400 baud');
      cfgItem('O Connect 28800',45,Mdm.c28800,
              'Connected at 28800 baud');
      cfgItem('P Connect 38400',45,Mdm.c38400,
              'Connected at 38400 baud');
      cfgItem('Q Connect 57600',45,Mdm.c57600,
              'Connected at 57600 baud');
      cfgItem('R Connect 64000',45,Mdm.c64000,
              'Connected at 64000 baud');
      cfgItem('S Connect 115200',45,Mdm.c115200,
              'Connected at 115200 baud');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Mdm.c300,inNormal,chNormal,'',True);
                 Mdm.c300 := cfgRead;
                 cfgSetItem(Mdm.c300);
              end;
        'B' : begin
                 cfgReadInfo(Mdm.c1200,inNormal,chNormal,'',True);
                 Mdm.c1200 := cfgRead;
                 cfgSetItem(Mdm.c1200);
              end;
        'C' : begin
                 cfgReadInfo(Mdm.c1275,inNormal,chNormal,'',True);
                 Mdm.c1275 := cfgRead;
                 cfgSetItem(Mdm.c1275);
              end;
        'D' : begin
                 cfgReadInfo(Mdm.c2400,inNormal,chNormal,'',True);
                 Mdm.c2400 := cfgRead;
                 cfgSetItem(Mdm.c2400);
              end;
        'E' : begin
                 cfgReadInfo(Mdm.c4800,inNormal,chNormal,'',True);
                 Mdm.c4800 := cfgRead;
                 cfgSetItem(Mdm.c4800);
              end;
        'F' : begin
                 cfgReadInfo(Mdm.c7200,inNormal,chNormal,'',True);
                 Mdm.c7200 := cfgRead;
                 cfgSetItem(Mdm.c7200);
              end;
        'G' : begin
                 cfgReadInfo(Mdm.c9600,inNormal,chNormal,'',True);
                 Mdm.c9600 := cfgRead;
                 cfgSetItem(Mdm.c9600);
              end;
        'H' : begin
                 cfgReadInfo(Mdm.c12000,inNormal,chNormal,'',True);
                 Mdm.c12000 := cfgRead;
                 cfgSetItem(Mdm.c12000);
              end;
        'I' : begin
                 cfgReadInfo(Mdm.c14400,inNormal,chNormal,'',True);
                 Mdm.c14400 := cfgRead;
                 cfgSetItem(Mdm.c14400);
              end;
        'J' : begin
                 cfgReadInfo(Mdm.c16800,inNormal,chNormal,'',True);
                 Mdm.c16800 := cfgRead;
                 cfgSetItem(Mdm.c16800);
              end;
        'K' : begin
                 cfgReadInfo(Mdm.c19200,inNormal,chNormal,'',True);
                 Mdm.c19200 := cfgRead;
                 cfgSetItem(Mdm.c19200);
              end;
        'L' : begin
                 cfgReadInfo(Mdm.c21600,inNormal,chNormal,'',True);
                 Mdm.c21600 := cfgRead;
                 cfgSetItem(Mdm.c21600);
              end;
        'M' : begin
                 cfgReadInfo(Mdm.c24000,inNormal,chNormal,'',True);
                 Mdm.c24000 := cfgRead;
                 cfgSetItem(Mdm.c24000);
              end;
        'N' : begin
                 cfgReadInfo(Mdm.c26400,inNormal,chNormal,'',True);
                 Mdm.c26400 := cfgRead;
                 cfgSetItem(Mdm.c26400);
              end;
        'O' : begin
                 cfgReadInfo(Mdm.c28800,inNormal,chNormal,'',True);
                 Mdm.c28800 := cfgRead;
                 cfgSetItem(Mdm.c28800);
              end;
        'P' : begin
                 cfgReadInfo(Mdm.c38400,inNormal,chNormal,'',True);
                 Mdm.c38400 := cfgRead;
                 cfgSetItem(Mdm.c38400);
              end;
        'Q' : begin
                 cfgReadInfo(Mdm.c57600,inNormal,chNormal,'',True);
                 Mdm.c57600 := cfgRead;
                 cfgSetItem(Mdm.c57600);
              end;
        'R' : begin
                 cfgReadInfo(Mdm.c64000,inNormal,chNormal,'',True);
                 Mdm.c64000 := cfgRead;
                 cfgSetItem(Mdm.c64000);
              end;
        'S' : begin
                 cfgReadInfo(Mdm.c115200,inNormal,chNormal,'',True);
                 Mdm.c115200 := cfgRead;
                 cfgSetItem(Mdm.c115200);
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgCommunicationsSetup;
var oldBar : Byte;
begin
   Mdm := Modem^;
   logWrite('*Modem configuration edited.');
   oldBar := 1;
   repeat
      cfgDraw := True;
      cfgOver := False;
      cfgInit(bbsTitle+' v'+bbsVersion+' Communications Setup');
      cfgBarPos := oldBar;
      cfgItem('A Modem Configuration',0,'','');
      cfgItem('B Command Strings',0,'','');
      cfgItem('C Result Strings',0,'','');
      cfgItem('D Connect Strings',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      oldBar := cfgBarPos;
      case cfgKey of
        'A' : cfgModemConfig;
        'B' : cfgCommandStrings;
        'C' : cfgResultStrings;
        'D' : cfgConnectStrings;
      end;
   until (HangUp) or (cfgDone);
   cfgInfo('Save Modem Configuration? ');
   if iYesNo(True) then
   begin
      Modem^ := Mdm;
      if (Modem^.ComPort = 4) and (not ModemOff) then ModemOff := True;
      fSaveModem(Node);
   end;
end;

end.