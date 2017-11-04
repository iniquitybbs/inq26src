{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config6;

interface

procedure cfgLevelEditor;

implementation

uses Global, Config, Strings, Files, Misc, Input, Logs, Levels, Users;

procedure cfgLevelEditor;
var C : Char; Lev : tLevels; B : Boolean; N, U : Word;
begin
   C := 'A';
   logWrite('*Access level edit.');
   levelLoad(Lev);
   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit(bbsTitle+' Access Level Editor');
      cfgItem('--Current level',1,C,'');
      cfgItem('A Description',40,Lev[C].Desc,
              'Text description of this access level');
      cfgItem('B Security level',3,St(Lev[C].SL),
              'Security level (SL) for this access level');
      cfgItem('C File security level',3,St(Lev[C].DSL),
              'File (download) security level (DSL) for this access level');
      cfgItem('D User note',40,Lev[C].UserNote,
              'Default user note to be given to user when validated at this level');
      cfgItem('E Time limit',5,St(Lev[C].timeLimit),
              'Daily time limit for users at this access level');
      cfgItem('F Post/call ratio',6,St(Lev[C].PostCall)+'%',
              'Default post/call ratio for users with this access');
      cfgItem('G File points',5,St(Lev[C].filePts),
              'File points for users at this access level');
      cfgItem('H Download limit',5,St(Lev[C].limitDL),
              'Allowed number of downloads per day at this level');
      cfgItem('I Download kb limit',7,St(Lev[C].limitDLkb)+'kb',
              'Allowed number of downloaded kilobytes per day at this level');
      cfgItem('J UL/DL ratio',5,St(Lev[C].uldlRatio),
              'Allowed number of downloads for each file uploaded');
      cfgItem('K UL/DL kb ratio',5,St(Lev[C].kbRatio),
              'Allowed number of downloadable kilobytes for every kb uploaded');
      cfgItem('= Update users',0,'',
              'Update all users at this level with the above level stats? ');
      cfgItem('[ Previous level',0,'','');
      cfgItem('] Next level',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Lev[C].Desc,inNormal,chNormal,'',False);
                 Lev[C].Desc := cfgRead;
                 cfgSetItem(Lev[C].Desc);
              end;
        'B' : begin
                 cfgReadInfo(St(Lev[C].SL),inUpper,chNumeric,'',True);
                 Lev[C].SL := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(Lev[C].SL));
              end;
        'C' : begin
                 cfgReadInfo(St(Lev[C].DSL),inUpper,chNumeric,'',True);
                 Lev[C].DSL := mClip(StrToInt(cfgRead),0,255);
                 cfgSetItem(St(Lev[C].DSL));
              end;
        'D' : begin
                 cfgReadInfo(Lev[C].UserNote,inNormal,chNormal,'',False);
                 Lev[C].UserNote := cfgRead;
                 cfgSetItem(Lev[C].UserNote);
              end;
        'E' : begin
                 cfgReadInfo(St(Lev[C].timeLimit),inUpper,chNumeric,'',True);
                 Lev[C].timeLimit := mClip(StrToInt(cfgRead),1,64000);
                 cfgSetItem(St(Lev[C].timeLimit));
              end;
        'F' : begin
                 cfgSetItem('         ');
                 cfgReadInfo(St(Lev[C].PostCall),inUpper,chNumeric,'',True);
                 Lev[C].PostCall := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Lev[C].PostCall)+'%');
              end;
        'G' : begin
                 cfgReadInfo(St(Lev[C].filePts),inUpper,chNumeric,'',True);
                 Lev[C].filePts := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Lev[C].filePts));
              end;
        'H' : begin
                 cfgReadInfo(St(Lev[C].limitDL),inUpper,chNumeric,'',True);
                 Lev[C].limitDL := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Lev[C].limitDL));
              end;
        'I' : begin
                 cfgSetItem('         ');
                 cfgReadInfo(St(Lev[C].limitDLkb),inUpper,chNumeric,'',True);
                 Lev[C].limitDLkb := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Lev[C].limitDLkb)+'kb');
              end;
        'J' : begin
                 cfgReadInfo(St(Lev[C].uldlRatio),inUpper,chNumeric,'',True);
                 Lev[C].uldlRatio := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Lev[C].uldlRatio));
              end;
        'K' : begin
                 cfgReadInfo(St(Lev[C].kbRatio),inUpper,chNumeric,'',True);
                 Lev[C].kbRatio := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Lev[C].kbRatio));
              end;
        '=' : begin
                 B := False;
                 cfgReadBoolean(B);
                 if B then
                 begin
                    cfgInfo('-- Updating user levels.  Please wait ...');
                    userSave(User^);
                    N := User^.Number;
                    for U := 1 to numUsers do
                    begin
                       User^.Number := U;
                       if (userLoad(User^)) and (User^.Level = C) then
                       begin
                          levelSet(User^,Lev,C);
                          userSave(User^);
                       end;
                    end;
                    User^.Number := N;
                    userLoad(User^);
                    cfgInfo('');
                 end;
              end;
        '[' : begin if C = 'A' then C := 'Z' else Dec(C); cfgDraw := True; cfgOver := True; end;
        ']' : begin if C = 'Z' then C := 'A' else Inc(C); cfgDraw := True; cfgOver := True; end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
   cfgInfo('Save access levels? ');
   if iYesNo(True) then levelSave(Lev);
end;

end.