{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config7;

interface

procedure cfgProtocolEditor;

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, bbsInit,
     MsgArea, Logs, Transfer;

procedure cfgProtocolEditor;
var optCode : array[1..2] of String;
    curProt, Z : Byte; B : Boolean; X : Byte;
begin
   optCode[1] := 'Transfer successful';
   optCode[2] := 'Transfer failed';
   curProt := 1;
   logWrite('*Protocol edit.');
   xferLoadProt(curProt);
   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' Protocol Editor');
      cfgCol := 25;
      cfgItem('--Current Protocol #',2,St(curProt),'');
      Dec(cfgLn);
      cfgCol := 50;
      cfgSrt := 40;
      cfgItem('[ Prev',0,'','');
      cfgSrt := 60;
      cfgCol := 70;
      Dec(cfgLn);
      cfgItem('] Next',0,'','');
      cfgSrt := 1;
      cfgCol := 25;
      if cfgDraw then Dec(cfgBot,2);
      cfgItem('A Active Protocol',3,b2st(protActive in Prot^.Flag),
              'Is this protocol currently active or disabled?');
      Dec(cfgLn,1);
      cfgSrt := 40;
      cfgCol := 65;
      cfgItem('B Batch Protocol',3,b2st(protBatch in Prot^.Flag),
              'Is this protocol used in batch (multiple file) transfers?');
      cfgSrt := 1;
      cfgCol := 25;
      cfgItem('C Bidirectional',3,b2st(protBiDir in Prot^.Flag),
              'Is this protocol bidirectional? (simultaneous two-way)');
      Dec(cfgLn,1);
      cfgSrt := 40;
      cfgCol := 65;
      cfgItem('D Activation Key',1,Prot^.Key,
              'Key pressed to select this protocol.');
      cfgSrt := 1;
      cfgCol := 25;
      if cfgDraw then Dec(cfgBot,2);
      cfgItem('E Description',36,Prot^.Desc,
              'Name of this protcol.');
      cfgItem('F Access Required',20,Prot^.Acs,
              'Access condition required to initiate this prtotocol.');
      cfgItem('G Log File',25,Prot^.Log,
              'Log file with transfer result. %TD=Work dir, %ND=Node');
      cfgItem('H Receive Command',53,Prot^.cmdUL,
              'Executed when receiving files.');
      cfgItem('I Send Command',53,Prot^.cmdDL,
              'Executed when sending files.');  { ----- ^^^^^ }
      cfgItem('J Filename Position',5,St(Prot^.posFile),
              'Position in log file where the filename is located.');
      cfgItem('K Status Position',5,St(Prot^.posStat),
              'Position in log file where transfer status is located.');
      cfgItem('L Batch List Filename',25,Prot^.listDL,
              'Filename to store download batch list in. %M=Work dir, %N=Node');
      cfgItem('M Environment Cmd',40,Prot^.cmdEnv,
              'Environment command to be set when executing protocol. %L=Log dir');
      cfgItem('N Result Code Means',20,cfgOption(optCode,Prot^.codeIs),
              'Do codes mean success or failure?');

      for Z := 1 to 6 do
      cfgItem(Chr(Ord('O')-1+Z)+' Receive Code #'+St(Z),6,Prot^.codeUL[Z],
              'Result code number '+St(Z)+' when receiving files.');
      Dec(cfgLn,6);
      cfgCol := 65;
      cfgSrt := 40;
      for Z := 1 to 6 do
      cfgItem(Chr(Ord('U')-1+Z)+' Send Code #'+St(Z),6,Prot^.codeDL[Z],
              'Result code number '+St(Z)+' when sending files.');
      if cfgDraw then Dec(cfgBot,6);
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 B := protActive in Prot^.Flag;
                 cfgReadBoolean(B);
                 cfgSetItem(b2st(B));
                 if B then Prot^.Flag := Prot^.Flag+[protActive] else
                           Prot^.Flag := Prot^.Flag-[protActive];
              end;
        'B' : begin
                 B := protBatch in Prot^.Flag;
                 cfgReadBoolean(B);
                 cfgSetItem(b2st(B));
                 if B then Prot^.Flag := Prot^.Flag+[protBatch] else
                           Prot^.Flag := Prot^.Flag-[protBatch];
              end;
        'C' : begin
                 B := protBiDir in Prot^.Flag;
                 cfgReadBoolean(B);
                 cfgSetItem(b2st(B));
                 if B then Prot^.Flag := Prot^.Flag+[protBiDir] else
                           Prot^.Flag := Prot^.Flag-[protBiDir];
              end;
        'D' : begin
                 cfgReadInfo(Prot^.Key,inUpper,chAlpha,'',False);
                 Prot^.Key := cfgRead[1];
                 cfgSetItem(Prot^.Key);
              end;
        'E' : begin
                 cfgReadInfo(Prot^.Desc,inNormal,chNormal,rsNoClean,False);
                 Prot^.Desc := cfgRead;
                 cfgSetItem(Prot^.Desc);
              end;
        'F' : begin
                 cfgReadInfo(Prot^.Acs,inLower,chNormal,'',False);
                 Prot^.Acs := cfgRead;
                 cfgSetItem(Prot^.Acs);
              end;
        'G' : begin
                 cfgReadInfo(Prot^.Log,inUpper,chDirectory,'',False);
                 Prot^.Log := cfgRead;
                 cfgSetItem(Prot^.Log);
              end;
        'H' : begin
                 cfgEditInfo(Prot^.cmdUL,78,inNormal,chNormal,'',False);
                 Prot^.cmdUL := cfgRead;
                 cfgSetItem(Prot^.cmdUL);
              end;
        'I' : begin
                 cfgEditInfo(Prot^.cmdDL,78,inNormal,chNormal,'',False);
                 Prot^.cmdDL := cfgRead;
                 cfgSetItem(Prot^.cmdDL);
              end;
        'J' : begin
                 cfgReadInfo(St(Prot^.posFile),inUpper,chNumeric,'',False);
                 Prot^.posFile := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Prot^.posFile));
              end;
        'K' : begin
                 cfgReadInfo(St(Prot^.posStat),inUpper,chNumeric,'',False);
                 Prot^.posStat := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Prot^.posStat));
              end;
        'L' : begin
                 cfgReadInfo(Prot^.listDL,inUpper,chDirectory,'',False);
                 Prot^.listDL := cfgRead;
                 cfgSetItem(Prot^.listDL);
              end;
        'M' : begin
                 cfgReadInfo(Prot^.cmdEnv,inNormal,chNormal,'',False);
                 Prot^.cmdEnv := cfgRead;
                 cfgSetItem(Prot^.cmdEnv);
              end;
        'N' : begin
                 cfgReadOption(optCode,2,Prot^.codeIs);
                 cfgSetItem(cfgOption(optCode,Prot^.codeIs));
              end;

        'O'..'T' :
              begin
                 X := Ord(cfgKey)-Ord('O')+1;
                 cfgReadInfo(Prot^.codeUL[X],inNormal,chNormal,'',False);
                 Prot^.codeUL[X] := cfgRead;
                 cfgSetItem(Prot^.codeUL[X]);
              end;
        'U'..'Z' :
              begin
                 X := Ord(cfgKey)-Ord('U')+1;
                 cfgReadInfo(Prot^.codeDL[X],inNormal,chNormal,'',False);
                 Prot^.codeDL[X] := cfgRead;
                 cfgSetItem(Prot^.codeDL[X]);
              end;
        '[' : begin
                 xferSaveProt(curProt);
                 Dec(curProt,1);
                 if curProt < 1 then curProt := maxProt;
                 xferLoadProt(curProt);
                 cfgDraw := True;
                 cfgOver := True;
              end;
        ']' : begin
                 xferSaveProt(curProt);
                 Inc(curProt,1);
                 if curProt > maxProt then curProt := 1;
                 xferLoadProt(curProt);
                 cfgDraw := True;
                 cfgOver := True;
              end;
      end;
   until (HangUp) or (cfgDone);
   xferSaveProt(curProt);
   cfgDone := False;
end;

end.