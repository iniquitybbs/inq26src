{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Doors;

interface

procedure doorExecute(Fn : String; Dt : Char);

implementation

   WriteLn(F,NoColor(Cfg^.bbsName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   end;
   WriteLn(F,First);
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   WriteLn(F,Last);

   if User^.Baudrate = 0 then WriteLn(F,'COM0') else WriteLn(F,'COM'+St(Modem^.ComPort+1));
   if (User^.Baudrate > 0) and (Modem^.LockedPort) then S := St(Modem^.BaudRate) else
                                                        S := St(User^.BaudRate);
   WriteLn(F,S+' BAUD,'+Modem^.Parity+','+St(Modem^.DataBits)+','+St(Modem^.StopBits));

   WriteLn(F,'0');

   if Pos(' ',User^.Username) = 0 then
   begin
      First := User^.Username;
      Last := '';
   end else
   begin
      First := Copy(User^.Username,1,Pos(' ',User^.Username)-1);
      Last := Copy(User^.Username,Length(First)+2,Length(User^.Username));
   end;

   WriteLn(F,First);
   WriteLn(F,Last);

   WriteLn(F,User^.Location);

   if emuANSi then WriteLn(F,'1') else WriteLn(F,'0');

   WriteLn(F,User^.SL);

   S := St(mTimeLeft('M'));
   if Length(S) > 3 then S := '999';
   WriteLn(F,S);
   WriteLn(F,'0');
   Close(F);
end;

procedure doorCreateDoorSys;
var F : Text; S : String;
begin
   Assign(F,'DOOR.SYS');
   Rewrite(F);
   if User^.Baudrate = 0 then WriteLn(F,'COM0:') else WriteLn(F,'COM'+St(Modem^.ComPort+1)+':');
   if (User^.Baudrate > 0) and (Modem^.LockedPort) then
                   WriteLn(F,Modem^.Baudrate) else
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   WriteLn(F,Copy(User^.PhoneNum,2,3)+' '+CoUser^.PhoneNum,6,255));;
   WriteLn(F,User^.Password);
   WriteLn(F,User^.SL);
   WriteLn(F,User^.TotalCalls);
   WriteLn(F,User^.LastCall);
   WriteLn(F,mTimeLeft('S'));
   WriteLn(F,mTimeLeft('M'));
   if emuANSi then WriteLn(F,'GR') else WriteLn(F,'NG');
   WriteLn(F,User^.PageLength);
   if acExpert in User^.acFlag then WriteLn(F,'Y') else WriteLn(F,'N');
   S := '1234567';  { ----- Flags }
   WriteLn(F,S);
   WriteLn(F,'7');
   WriteLn(F,'01/01/99');
   WriteLn(F,St(User^.Number));
   WriteLn(F,'Z');
   WriteLn(F,User^.Uploads); { ---- Uploads }
   WriteLn(F,User^.Downloads); { ---- Downloads }
   WriteLn(F,User^.DownloadKb); { ---- Downloaded Kb }
   WriteLn(F,User^.limitDLkb);
   Close(F);
end;

procedure doorCreateChainTxt;
var F : Text; Ton, Used : Real; S : String;
 function Bo(B : Boolean) : String;
 begin
    if B then Bo := '1' else Bo := '0';
 end;
begin
   Assign(F,'CHAIN.TXT');
   Rewrite(F);
   with User^ do
   begin
      WriteLn(F,Number);
      WriteLn(F,UserName);
      WriteLn(F,RealName);
      WriteLn(F,'');
      WriteLn(F,dtAge(BirthDate));
      WriteLn(F,Sex);
      WriteLn(F,'0.00'); { credit.. ?}
      WriteLn(F,LastCall);
      WriteLn(F,'80');
      WriteLn(F,PageLength);
      WriteLn(F,SL);
      WriteLn(F,Bo(acsOk(Cfg^.acsSysOp)));
      WriteLn(F,Bo(acsOk(Cfg^.acsCoSysOp)));
      WriteLn(F,Bo(emuANSi));
      WriteLn(F,Bo(not LocalIO));
      WriteLn(F,mTimeLeft('S')); { --- nsl:10:2 }
      WriteLn(F,Cfg^.pathData);
      WriteLn(F,Cfg^.pathData);
      WriteLn(F,'XX.XX');      { Sys Log }
      if (User^.Baudrate > 0) and (Modem^.LockedPort) then
                      WriteLn(F,Modem^.Baudrate) else
                      WriteLn(F,User^.BaudRate);
      WriteLn(F,Modem^.ComPort+1);
      WriteLn(F,NoColor(Cfg^.bbsName));
      WriteLn(F,Cfg^.SysOpName);
      WriteLn(F,'123456'); { Sec since midnight }
      WriteLn(F,'123456'); { Time used }
      WriteLn(F,'0'); { Uploaded K }
      WriteLn(F,'0'); { Uploads }
      WriteLn(F,'0'); { Downloaded K }
      WriteLn(F,'0'); { Downloads }
      WriteLn(F,St(Modem^.DataBits)+Modem^.Parity+St(Modem^.StopBits));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   end;
   Close(F);
end;

procedure doorExecute(Fn : String; Dt : Char);
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
begin
   if Fn = '' then Exit;
   logWrite('Online door game execution.');
   fCreateDir(Cfg^.pathDoor,False);
   case UpCase(Dt) of
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
   if Pos(' ',Cfg^.SysOpName) = 0 then
   begin
      First := Cfg^.SysOpName;
      Last := '';
   end else
   begin
      First := Copy(Cfg^.SysOpName,1,Pos(' ',Cfg^.SysOpName)-1);
      Last := Copy(Cfg^.SysOpName,Length(First)+2,Length(Cfg^.SysOpName));
      '1' : doorCreateDorInfo;
      '2' : doorCreateDoorSys;
      '3' : doorCreateChainTxt;
      'Z' : begin doorCreateDoorSys; doorCreateDorInfo; end;
   end;
   userSave(User^);
{  cTerminateFossil;}
   fn := strReplace(fn,'%PD',Cfg^.pathData);
   fn := strReplace(fn,'%PT',Cfg^.pathText);
   fn := strReplace(fn,'%PM',Cfg^.pathMenu);
   fn := strReplace(fn,'%PP',Cfg^.pathProt);
   fn := strReplace(fn,'%PL',Cfg^.pathLogs);
   fn := strReplace(fn,'%PA',Cfg^.pathArch);
   fn := strReplace(fn,'%BR',St(User^.BaudRate));
   fn := strReplace(fn,'%BP',St(Modem^.BaudRate));
   fn := strReplace(fn,'%CP',St(Modem^.ComPort+1));
   fn := mciProcess(fn,0);
   fShellDos(Fn,True,True,False);
   cInitFossil;
   userLoad(User^);
   fCreateDir(StartDir,False);
end;

end.
