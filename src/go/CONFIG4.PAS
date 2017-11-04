{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config4;

interface

procedure cfgMenuEditor;

implementation

uses Dos, Global, Strings, Config, Output, Input, Menus, Files, Misc, Logs;

procedure cfgNewCommand(I : Byte);
begin
   with Cmd^[I] do
   begin
      Desc         := 'New menu command';
      Help         := 'None';
      Keys         := 'X';
      Acs          := '';
      Command      := '';
      Param        := '';
      Hidden       := False;
   end;
end;

procedure cfgAddMenu;
var Fn : String;
begin
   oDnLn(1);
   oCWrite('|U1Enter new menu filename|U2: |U3');

   Fn := iReadString('',inUpper,chFileNoExt,'',8);
   if Fn = '' then Exit;

   if fExists(Cfg^.pathMenu+Fn+'.MNU') then
   begin
      oDnLn(1);
      oSetCol(colError);
      oWrite(Fn+'.MNU Already Exists.');
      oSetCol(colInfo);
      oWrite('  Overwrite It? ');
      if not iYesNo(False) then Exit else logWrite('*Menu "'+Fn+'" overwritten')
   end else logWrite('Menu file "'+Fn+'" created');

   numCmds := 1;

   FillChar(Menu^,SizeOf(Menu^),0);
   with Menu^ do
   begin
      mType        := 1;
      MenuName     := 'New '+bbsTitle+' Menu';
      PromptName   := strMixed(Fn);
      HelpFile     := Fn;
      Prompt       := 'Command: ';
      Acs          := '';
      Password     := '';
      Fallback     := 'MAIN';
      Expert       := 1;
      GenColumns   := 3;
      HotKey       := 1;
      ClearBefore  := True;
      CenterTtl    := True;
      ShowPrompt   := True;
      PauseBefore  := True;
      GlobalUse    := True;
      InputUp      := True;
   end;

   with Cmd^[1] do
   begin
      Desc         := 'Quit';
      Help         := 'Quit current menu';
      Keys         := 'Q';
      ACS          := '';
      Command      := '-\';
      Param        := 'MAIN';
      Hidden       := False;
   end;

   menuSave(Fn);
end;

procedure cfgDeleteMenu;
var Fn : String;
begin
   oDnLn(1);
   oCWrite('|U1Enter menu filename to delete|U2: |U3');

   Fn := iReadString('',inUpper,chFileNoExt,'',8);
   if Fn = '' then Exit;

   if fExists(Cfg^.pathMenu+Fn+'.MNU') then
   begin
      oDnLn(1);
      oSetCol(colTextHi);
      oWrite(Fn+'.MNU');
      oSetCol(colTextLo);
      oWrite(' - Delete this menu? ');
      if not iYesNo(True) then Exit;
   end;

   fDeleteFile(Cfg^.pathMenu+Fn+'.MNU');
   logWrite('*Menu file deleted: "'+Fn+'"');
end;

procedure cfgShowCommands(ListType : Byte);
var I, Z : Byte; S : String;
begin
   I := 1;
   PausePos := 1;
   PauseAbort := False;
   if numCmds <> 0 then
   begin
      case ListType of
         0 : begin
                oSetCol(colTextHi);
                oCWriteLn(' Desc                 Num  Keys    Hid  ACS     Cmd  Parameters');
                oSetCol(colBorder);
                oWriteLn(sRepeat('Ä',79));
                oUpPause(2);
                while (I <= numCmds) and (not PauseAbort) do
                begin
                   oSetCol(colText);
                   oCWriteLn(' '+Resize(Cmd^[I].Desc,20)+
                             ' '+Resize(St(I),4)+
                             ' '+Resize(Cmd^[I].Keys,7)+
                             ' '+Resize(B2St(Cmd^[I].Hidden),4)+
                             ' '+Resize(Cmd^[I].ACS,7)+
                             ' '+Resize(Cmd^[I].Command,4)+
                             ' '+Resize(Cmd^[I].Param,26));
                   Inc(I,1);
                   oUpPause(1);
                end;
             end;

         1 : begin
                oSetCol(colTextHi);
                oCWriteLn(' Num Key Acs Cmd Param    Num Key Acs Cmd Param    Num Key Acs Cmd Param   ');
                oSetCol(colBorder);
                oWriteLn(sRepeat('Ä',79));
                oUpPause(2);
                Z := 1;
                while (I <= numCmds) and (not PauseAbort) do
                begin
                   oSetCol(colText);
                   S := ' '+Resize(St(I),3)+
                        ' '+Resize(Cmd^[I].Keys,3)+
                        ' '+Resize(Cmd^[I].Acs,3)+
                        ' '+Resize(Cmd^[I].Command,3)+
                        ' '+Resize(Cmd^[I].Param,8);
                   if Z < 3 then oCWrite(S) else
                   begin
                      oCWriteLn(S);
                      oUpPause(1);
                   end;
                   Inc(I,1);
                   Inc(Z,1);
                   if Z > 3 then Z := 1;
                end;
                if Z <> 1 then oDnLn(1);
             end;
      end;
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
   end else
   begin
      oCWriteLn('|U0-- No commands exist');
      oDnLn(1);
   end;
   PausePos := 0;
end;

procedure cfgInsertMenuCommand;
var I,X,Z,B : Byte;
begin
   oDnLn(1);
   if numCmds >= maxMenuCmd then
   begin
      oSetCol(colError);
      oWriteLn('You may only have a maximum of '+St(maxMenuCmd)+' commands per menu');
      oDnLn(1);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Insert before which menu command|U2? |U5[|U61|U5-|U6'+St(numCmds+1)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > maxMenuCmd+1) or (I < 1) then Exit;
   oCWrite('|U1Number of commands to insert |U5[|U61|U5-|U6'+St(maxMenuCmd-numCmds)+'|U5]: |U3');
   X := StrToInt(iReadString('1',inUpper,chNumeric,'',3));
   if (X > maxMenuCmd-numCmds) or (X < 1) then Exit;
   for Z := I to I+X-1 do
      if (Z >= 1) and (Z <= numCmds+1) and (numCmds < maxMenuCmd) then
      begin
         Inc(numCmds);
         if (Z <> numCmds) then for B := numCmds downto Z do Cmd^[B] := Cmd^[B-1];
         cfgNewCommand(Z);
      end;
end;

procedure cfgDeleteMenuCommand;
var I,Z : Byte;
begin
   oDnLn(1);
   if numCmds = 0 then
   begin
      oSetCol(colError);
      oWriteLn('Can''t continue.  No menu commands exist.');
      oDnLn(1);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Delete which menu command|U2? |U5[|U61|U5-|U6'+St(numCmds)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numCmds) or (I < 1) then Exit;
   for Z := I+1 to numCmds do Cmd^[Z-1] := Cmd^[Z];
   Dec(numCmds);
end;

procedure cfgMoveMenuCommand;
var I,J,K,B,Z : Byte;
begin
   oDnLn(1);
   if numCmds = 0 then
   begin
      oSetCol(colError);
      oWriteLn('Can''t continue.  No menu commands exist.');
      oDnLn(1);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Move which menu command|U2? |U5[|U61|U5-|U6'+St(numCmds)+'|U5]: |U3');
   I := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (I > numCmds) or (I < 1) then Exit;
   oCWrite('|U1Move before which menu command|U2? |U5[|U61|U5-|U6'+St(numCmds+1)+'|U5]: |U3');
   J := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (J = I) or (I = I+1) or (J > numCmds+1) or (J < 1) then Exit;
   if (J >= 1) and (J <= numCmds+1) and (numCmds < maxMenuCmd) then
   begin
      Inc(numCmds);
      if (J <> numCmds) then for B := numCmds downto J do Cmd^[B] := Cmd^[B-1];
      cfgNewCommand(J);
   end;
   if J > I then K := I else K := I+1;
   Cmd^[J] := Cmd^[K];
   if J > I then for Z := I+1 to numCmds do Cmd^[Z-1] := Cmd^[Z]
            else for Z := I+2 to numCmds do Cmd^[Z-1] := Cmd^[Z];
   Dec(numCmds,1);
end;

procedure cfgEditMenuCommand;
var Cn : Byte;
begin
   oDnLn(1);
   if numCmds = 0 then
   begin
      oSetCol(colError);
      oWriteLn('Can''t continue.  No menu commands exist.');
      oDnLn(1);
      oPromptKey;
      Exit;
   end;
   oCWrite('|U1Begin edit at which menu command|U2? |U5[|U61|U5-|U6'+St(numCmds)+'|U5]: |U3');
   Cn := StrToInt(iReadString('',inUpper,chNumeric,'',3));
   if (Cn > numCmds) or (Cn < 1) then Exit;

   cfgDraw := True;
   cfgOver := False;
   repeat
      cfgInit(bbsTitle+' Menu Command Editor');
      cfgCol := 25;
      cfgItem('--Current command',8,St(Cn)+' of '+St(numCmds),'');
      cfgItem('A Description',35,Cmd^[Cn].Desc,
              'Description of this menu command (displayed in generic menus)');
      cfgItem('B Command help',54,Cmd^[Cn].Help,
              'Help string for this menu command');
      cfgItem('C Menu keys',14,Cmd^[Cn].Keys,
              'Menu key(s) used to activate this command (''FIRSTCMD'' = Immediate)');
      cfgItem('D Access',20,Cmd^[Cn].ACS,
              'Access condition required to activate this command');
      cfgItem('E Menu command',2,Cmd^[Cn].Command,
              'Command code this item executes when activated');
      cfgItem('F Parameters',54,Cmd^[Cn].Param,
              'Parameters passed to this command when activated');
      cfgItem('G Hidden',3,B2St(Cmd^[Cn].Hidden),
              'Is this menu command hidden from generic display?');
      cfgItem('[ Previous',0,'','');
      cfgItem('] Next',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadInfo(Cmd^[Cn].Desc,inNormal,chNormal,rsSpace+rsNoClean,False);
                 Cmd^[Cn].Desc := cfgRead;
                 cfgSetItem(Cmd^[Cn].Desc);
              end;
        'B' : begin
                 cfgEditInfo(Cmd^[Cn].Help,70,inNormal,chNormal,rsSpace+rsNoClean,False);
                 Cmd^[Cn].Help := cfgRead;
                 cfgSetItem(Cmd^[Cn].Help);
              end;
        'C' : begin
                 cfgReadInfo(Cmd^[Cn].Keys,inUpper,chNormal,'',False);
                 Cmd^[Cn].Keys := cfgRead;
                 cfgSetItem(Cmd^[Cn].Keys);
              end;
        'D' : begin
                 cfgReadInfo(Cmd^[Cn].ACS,inLower,chNormal,'',False);
                 Cmd^[Cn].ACS := cfgRead;
                 cfgSetItem(Cmd^[Cn].ACS);
              end;
        'E' : begin
                 cfgReadInfo(Cmd^[Cn].Command,inUpper,chNormal,'',False);
                 { Check 4 Help!!!!! }
                 Cmd^[Cn].Command := cfgRead;
                 cfgSetItem(Cmd^[Cn].Command);
              end;
        'F' : begin
                 cfgEditInfo(Cmd^[Cn].Param,70,inNormal,chNormal,rsNoClean+rsSpace,False);
                 Cmd^[Cn].Param := cfgRead;
                 cfgSetItem(Cmd^[Cn].Param);
              end;
        'G' : begin
                 cfgReadBoolean(Cmd^[Cn].Hidden);
                 cfgSetItem(B2St(Cmd^[Cn].Hidden));
              end;
        '[' : begin if Cn = 1 then Cn := numCmds else Dec(Cn); cfgDraw := True; cfgOver := True; end;
        ']' : begin if Cn = numCmds then Cn := 1 else Inc(Cn); cfgDraw := True; cfgOver := True; end;
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
end;

procedure cfgEditMenuCommands(Fn : String);
var ListM : Byte;
    cmdMenu : array[1..5] of String;
begin
   cfgDone := False;
   cmdMenu[1] := 'I nsert';
   cmdMenu[2] := 'D elete';
   cmdMenu[3] := 'E dit';
   cmdMenu[4] := 'M ove';
   cmdMenu[5] := 'Esc Quit';
   repeat
      oClrScr;
      if numCmds > 20 then ListM := 1 else ListM := 0;

      cfgShowCommands(ListM);

      cfgPrompt(cmdMenu,5);
      repeat
         cfgKey := UpCase(iReadkey);
      until (HangUp) or (cfgKey in ['I','D','M','E',#27,' ']);
      if cfgKey = #27 then oWrite('Quit') else oWriteChar(cfgKey);

      case cfgKey of
        'I' : cfgInsertMenuCommand;
        'D' : cfgDeleteMenuCommand;
        'E' : cfgEditMenuCommand;
        'M' : cfgMoveMenuCommand;
        ' ',
        #27 : cfgDone := True;
      end;
   until (HangUp) or (cfgDone);

   cfgDone := False;
   cfgDraw := True;
end;

procedure cfgEditMenu;
var Fn, S : String; mnuOld : tMenuRec; cmdOld : tCommands; B : Boolean;
    optMt, optEx : array[1..3] of String;
begin
   oDnLn(1);
   oCWrite('|U1Enter menu filename to edit|U2: |U3');

   optMt[1] := 'Normal';
   optMt[2] := 'Generic';
   optMt[3] := 'LightBar';

   optEx[1] := 'Normal';
   optEx[2] := 'Forced';
   optEx[3] := 'Disabled';

   mnuOld := Menu^;
   cmdOld := Cmd^;

   Fn := iReadString('',inUpper,chFileNoExt,'',8);
   if (Fn = '') or (not fExists(Cfg^.pathMenu+Fn+'.MNU')) or
      (not menuLoad(Fn,False)) then
   begin
      Menu^ := mnuOld;
      Exit;
   end;

   logWrite('*Edited menu file: "'+Fn+'"');
   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' Menu Editor ['+Fn+'.MNU]');
      cfgCol := 25;
      cfgItem('A Menu type',8,cfgOption(optMt,Menu^.mType),
              'Menu interface type');
      cfgItem('B Menu title',54,Menu^.MenuName,
              'Title of this menu (displayed in generic menus)');
      cfgItem('C Prompt name',54,Menu^.PromptName,
              'Name of menu that will be displayed in prompt (with %MP code)');
      cfgItem('D Help filename',8,Menu^.HelpFile,
              'Text file displayed to user at normal help level');
      cfgItem('E Menu prompt',53,Menu^.Prompt,
              'Prompt displayed for this menu.');
      cfgItem('F Access',20,Menu^.Acs,
              'Access condition required to enter this menu');
      cfgItem('G Password',20,Menu^.Password,
              'Password required to access this menu');
      cfgItem('H Fallback menu',8,Menu^.Fallback,
              'Menu filename to drop to, if unable to access this menu');
      cfgItem('I Expert status',8,cfgOption(optEx,Menu^.Expert),
              'Menu expert mode status');
      cfgItem('J Generic columns',1,St(Menu^.GenColumns),
              'Number of command columns (when displaying the generic menu)');
      cfgItem('K Hotkey status',8,cfgOption(optEx,Menu^.HotKey),
              'Menu hotkey status');
      cfgLn := cfgTop+5;
      cfgSrt := 46;
      cfgCol := 66;
      cfgItem('1 Clear before',3,B2St(Menu^.ClearBefore),
              'Clear the screen before displaying this menu?');
      cfgItem('2 Center title',3,B2St(Menu^.CenterTtl),
              'Center the menu name when displaying a generic menu?');
      cfgItem('3 Show prompt',3,B2St(Menu^.ShowPrompt),
              'Display the menu prompt for this menu?');
      cfgItem('4 Pause before',3,B2St(Menu^.PauseBefore),
              'Pause before displaying this menu?');
      cfgItem('5 Global use',3,B2St(Menu^.GlobalUse),
              'Include menu commands found in GLOBAL.MNU into this menu?');
      cfgItem('6 Upcase input',3,B2St(Menu^.InputUp),
              'Should menu input be converted to uppercase?');
      if cfgDraw then Dec(cfgBot,5);
      cfgSrt := 1;
      cfgCol := 25;
      cfgLn := cfgTop+12;
      cfgItem('  Edit menu commands',0,'','');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadOption(optMt,3,Menu^.mType);
                 cfgSetItem(cfgOption(optMt,Menu^.mType));
              end;
        'B' : begin
                 cfgEditInfo(Menu^.MenuName,255,inNormal,chNormal,rsNoClean+rsSpace,False);
                 Menu^.MenuName := cfgRead;
                 cfgSetItem(Menu^.MenuName);
              end;
        'C' : begin
                 cfgEditInfo(Menu^.PromptName,60,inNormal,chNormal,rsNoClean+rsSpace,False);
                 Menu^.PromptName := cfgRead;
                 cfgSetItem(Menu^.PromptName);
              end;
        'D' : begin
                 cfgReadInfo(Menu^.HelpFile,inUpper,chFilename,'',False);
                 Menu^.HelpFile := cfgRead;
                 cfgSetItem(Menu^.HelpFile);
              end;
        'E' : begin
                 cfgEditInfo(Menu^.Prompt,255,inNormal,chNormal,rsNoClean+rsSpace,False);
                 Menu^.Prompt := cfgRead;
                 cfgSetItem(Menu^.Prompt);
              end;
        'F' : begin
                 cfgReadInfo(Menu^.ACS,inLower,chNormal,'',False);
                 Menu^.ACS := cfgRead;
                 cfgSetItem(Menu^.ACS);
              end;
        'G' : begin
                 cfgReadInfo(Menu^.Password,inUpper,chNormal,'',False);
                 Menu^.Password := cfgRead;
                 cfgSetItem(Menu^.Password);
              end;
        'H' : begin
                 cfgReadInfo(Menu^.Fallback,inUpper,chFileNoExt,'',False);
                 Menu^.Fallback := cfgRead;
                 cfgSetItem(Menu^.Fallback);
              end;
        'I' : begin
                 cfgReadOption(optEx,3,Menu^.Expert);
                 cfgSetItem(cfgOption(optEx,Menu^.Expert));
              end;
        'J' : begin
                 cfgReadInfo(St(Menu^.GenColumns),inUpper,chNumeric,'',True);
                 Menu^.GenColumns := mClip(StrToInt(cfgRead),1,7);
                 cfgSetItem(St(Menu^.GenColumns));
              end;
        'K' : begin
                 cfgReadOption(optEx,3,Menu^.Hotkey);
                 cfgSetItem(cfgOption(optEx,Menu^.Hotkey));
              end;
        '1' : begin
                 cfgReadBoolean(Menu^.ClearBefore);
                 cfgSetItem(B2St(Menu^.ClearBefore));
              end;
        '2' : begin
                 cfgReadBoolean(Menu^.CenterTtl);
                 cfgSetItem(B2St(Menu^.CenterTtl));
              end;
        '3' : begin
                 cfgReadBoolean(Menu^.ShowPrompt);
                 cfgSetItem(B2St(Menu^.ShowPrompt));
              end;
        '4' : begin
                 cfgReadBoolean(Menu^.PauseBefore);
                 cfgSetItem(B2St(Menu^.PauseBefore));
              end;
        '5' : begin
                 cfgReadBoolean(Menu^.GlobalUse);
                 cfgSetItem(B2St(Menu^.GlobalUse));
              end;
        '6' : begin
                 cfgReadBoolean(Menu^.InputUp);
                 cfgSetItem(B2St(Menu^.InputUp));
              end;
{       'O' : begin
                 oClrScr;
                 menuGeneric(2);
                 oPromptKey;
                 cfgDraw := True;
              end;
        'P' : begin
                 oClrScr;
                 menuGeneric(1);
                 oPromptKey;
                 cfgDraw := True;
              end;}
        ' ' : cfgEditMenuCommands(Fn);
      end;
   until (HangUp) or (cfgDone);
   cfgDone := False;
   cfgInfo('Save menu file? ');
   if iYesNo(True) then menuSave(Fn) else
   begin
      Menu^ := mnuOld;
      Cmd^ := cmdOld;
   end;
end;

procedure cfgMenuEditor;
var SR : SearchRec; Col : Byte;
    cmdMnuEdit : array[1..4] of String;
begin
   if HangUp then Exit;
   cmdMnuEdit[1] := 'A dd menu';
   cmdMnuEdit[2] := 'D elete menu';
   cmdMnuEdit[3] := 'E dit menu';
   cmdMnuEdit[4] := 'Esc Quit';
   cfgDone := False;
   logWrite('*Menu editor loaded');
   repeat
      oClrScr;
      cfgOver := False;
      cfgDraw := True;
      oSetCol(colText);
      PausePos := 1;
      PauseAbort := False;
      oWrite('   '+bbsTitle+' v'+bbsVersion+' ');
      oSetCol(colTextHi);
      oWriteLn('Menu Editing System');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oSetCol(colInfo);
      oUpPause(2);
      FindFirst(Cfg^.pathMenu+'*.MNU',0,SR);
      if DosError <> 0 then oWriteLn(' -- No menu files found.');
      Col := 1;
      while (not PauseAbort) and (DosError = 0) do
      begin
         if Col > 7 then
         begin
            Col := 1;
            oDnLn(1);
            oUpPause(1);
         end;
         if Pos('.',SR.Name) > 0 then oWrite(Resize(Copy(SR.Name,1,Pos('.',SR.Name)-1),11)) else
            oWrite(Resize(SR.Name,11));
         FindNext(SR);
         Inc(Col,1);
      end;
      if Col > 1 then oDnLn(1);
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
      PausePos := 0;
      cfgPrompt(cmdMnuEdit,4);
      repeat
         cfgKey := UpCase(iReadkey);
      until (HangUp) or (cfgKey in ['A','D','E',#27]);
      if cfgKey = #27 then oWrite('Quit') else oWriteChar(cfgKey);
      oDnLn(1);
      case cfgKey of
        'A' : cfgAddMenu;
        'D' : cfgDeleteMenu;
        'E' : cfgEditMenu;
        #27 : cfgDone := True;
      end;
   until (HangUp) or (cfgDone);
   if LoggedIn then menuInstall;
end;

end.