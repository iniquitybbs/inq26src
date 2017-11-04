{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Comm;

interface

procedure cCheckIt;
procedure cCheckUser;
procedure cClearInBuffer;
procedure cClearOutBuffer;
function  cCommInfo : Byte;
function  cFossilInstalled : Boolean;
procedure cHangUp;
procedure cInitFossil;
function  cModemRinging : Boolean;
procedure cModemWrite(S : String);
function  cNoCarrier : Boolean;
function  cOutBufferEmpty : Boolean;
procedure cRaiseDTR;
function  cSetBaud(B : LongInt) : Boolean;
function  cSetupCommunications : Boolean;
procedure cTerminateFossil;

implementation

uses Crt, Dos,
     Global, Fossil, Strings, StatBar, Misc, Logs, Output,
     DateTime;

function cSetBaud(B : LongInt) : Boolean;
begin
   cSetBaud := True;
   if not ModemIO then Exit;
   cSetBaud := SetBaud(Modem^.ComPort,B,cCommInfo);
end;

function cOutBufferEmpty : Boolean;
begin
   if not ModemIO then Exit;
   cOutBufferEmpty := OutBufferEmpty(Modem^.ComPort);
end;

function cCommInfo : Byte;
var CommInfo : Byte;
begin
   if (Modem^.Parity='N') and (Modem^.DataBits=8) and (Modem^.StopBits=1) then CommInfo := N81 else
   if (Modem^.Parity='N') and (Modem^.DataBits=8) and (Modem^.StopBits=2) then CommInfo := N82 else
   if (Modem^.Parity='N') and (Modem^.DataBits=7) and (Modem^.StopBits=1) then CommInfo := N71 else
   if (Modem^.Parity='N') and (Modem^.DataBits=7) and (Modem^.StopBits=2) then CommInfo := N72 else
   if (Modem^.Parity='E') and (Modem^.DataBits=8) and (Modem^.StopBits=1) then CommInfo := E81 else
   if (Modem^.Parity='E') and (Modem^.DataBits=8) and (Modem^.StopBits=2) then CommInfo := E82 else
   if (Modem^.Parity='E') and (Modem^.DataBits=7) and (Modem^.StopBits=1) then CommInfo := E71 else
   if (Modem^.Parity='E') and (Modem^.DataBits=7) and (Modem^.StopBits=2) then CommInfo := E72 else
   if (Modem^.Parity='O') and (Modem^.DataBits=8) and (Modem^.StopBits=1) then CommInfo := O81 else
   if (Modem^.Parity='O') and (Modem^.DataBits=8) and (Modem^.StopBits=2) then CommInfo := O82 else
   if (Modem^.Parity='O') and (Modem^.DataBits=7) and (Modem^.StopBits=1) then CommInfo := O71 else
   if (Modem^.Parity='O') and (Modem^.DataBits=7) and (Modem^.StopBits=2) then CommInfo := O72 else
      CommInfo := N81;
   cCommInfo := CommInfo;
end;

function cSetupCommunications : Boolean;
var OK : Boolean;
begin
   OK := True;
   if (not ModemOff) and (ModemIO) then
   begin
      OK := cFossilInstalled;
      if OK then ActivatePort(Modem^.ComPort);
      if OK then OK := SetBaud(Modem^.ComPort,Modem^.BaudRate,cCommInfo);
   end;
   cSetupCommunications := OK;
end;

procedure cCheckIt;
begin
   if UserOn then sbUpdate;
   if not LocalIO then
   begin
{     if (dtTimeStr12 = '6:42am') or
         (dtTimeStr12 = '6:43am') or
         (dtTimeStr12 = '6:44am') or
         (dtTimeStr12 = '6:45am') or
         (dtTimeStr12 = '6:46am') or
         (dtTimeStr12 = '6:47am') or
         (dtTimeStr12 = '6:48am') or
         (dtTimeStr12 = '6:49am') or
         (dtTimeStr12 = '6:50am') then HangUp := True;}
      if (HangUp) and (not cNoCarrier) then
      begin
         HungUp := False;
         if not asDoor then cHangUp;
         RemoteOut := False;
         LocalIO := True;
         ModemIO := False;
      end else
      if cNoCarrier then
      begin
         HangUp := True;
         HungUp := True;
         logWrite('Carrier lost');
         if not asDoor then cHangUp;
         RemoteOut := False;
         LocalIO := True;
         ModemIO := False;
      end;
   end;
   if oprType > oprDOS then mTimeSlice;
end;

procedure cCheckUser;
begin
   if (not ChatModeOn) and (timeCheck) and (UserOn) and (LoggedIn) and (not HangUp) and (mTimeLeft('S') < 1) then
   begin
      oStringLn(strTimeExpired);
      logWrite('User''s time expired.');
      HangUp := True;
   end;
   cCheckIt;
end;

function cNoCarrier : Boolean;
begin
   cNoCarrier := False;
   if not ModemIO then Exit;
   cNoCarrier := not CarrierDetected(Modem^.ComPort);
end;

function cModemRinging : Boolean;
begin
   cModemRinging := (ModemIO) and (ModemRinging(Modem^.ComPort));
end;

procedure cClearOutBuffer;
begin
   if ModemIO then ClearOutBuffer(Modem^.ComPort);
end;

procedure cClearInBuffer;
begin
   if ModemIO then ClearInBuffer(Modem^.ComPort);
end;

procedure cHangUp;
begin
   if ModemIO then
   begin
      DTR(Modem^.ComPort,LOWER);
      Delay(500);
      DTR(Modem^.ComPort,RAISE);
   end;
end;

procedure cRaiseDTR;
begin
   if ModemIO then DTR(Modem^.ComPort,RAISE);
end;

procedure cInitFossil;
begin
   if ModemIO then ActivatePort(Modem^.ComPort);
end;

procedure cTerminateFossil;
begin
   if ModemIO then DeactivatePort(Modem^.ComPort);
end;

function cFossilInstalled : Boolean;
begin
   cFossilInstalled := (ModemOff) or (FossilPresent);
end;

procedure cModemWrite(S : String);
var P : Byte;
begin
   if not ModemIO then Exit;
   for P := 1 to Length(S) do
   begin
      case S[P] of
        '|' : ComWrite(Modem^.ComPort,#13);
        '~' : Delay(500);
        '^' : cHangUp;
        else ComWriteChar(Modem^.ComPort,S[P]);
      end;
   end;
end;

end.