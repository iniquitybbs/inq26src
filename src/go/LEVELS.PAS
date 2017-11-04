{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Levels;

interface

uses Global;

procedure levelChange(var U : tUserRec; Lev : Char);
procedure levelLoad(var Lev : tLevels);
procedure levelLower(var U : tUserRec);
procedure levelSave(var Lev : tLevels);
procedure levelSet(var U : tUserRec; var L : tLevels; Lev : Char);
procedure levelUpgrade(var U : tUserRec);

implementation

uses Files;

procedure levelSet(var U : tUserRec; var L : tLevels; Lev : Char);
begin
   U.SL := L[Lev].SL;
   U.DSL := L[Lev].DSL;
   U.filePts := L[Lev].filePts;
   U.PostCall := L[Lev].PostCall;
   U.limitDL := L[Lev].limitDL;
   U.limitDLkb := L[Lev].limitDLkb;
   U.UserNote := L[Lev].UserNote;
   U.timePerDay := L[Lev].timeLimit;
   U.timeToday := L[Lev].timeLimit;
   U.uldlRatio := L[Lev].uldlRatio;
   U.kbRatio := L[Lev].kbRatio;
   U.Level := Lev;
end;

procedure levelChange(var U : tUserRec; Lev : Char);
var L : tLevels;
begin
   levelLoad(L);
   if L[Lev].Desc <> '' then levelSet(U,L,Lev);
end;

procedure levelUpgrade(var U : tUserRec);
var X : Char; L : tLevels;
begin
   levelLoad(L);
   X := U.Level;
   if X = 'Z' then X := 'A' else Inc(X);
   while (L[X].Desc = '') and (X < 'Z') do Inc(X);
   if L[X].Desc = '' then Exit;
   levelChange(U,X);
end;

procedure levelLower(var U : tUserRec);
var X : Char; L : tLevels;
begin
   levelLoad(L);
   X := U.Level;
   if X = 'A' then X := 'Z' else Dec(X);
   while (L[X].Desc = '') and (X > 'A') do Dec(X);
   if L[X].Desc = '' then Exit;
   levelChange(U,X);
end;

procedure levelLoad(var Lev : tLevels);
var F : file of tLevels;
begin
   Assign(F,Cfg^.pathData+fileLevels);
   FillChar(Lev,SizeOf(Lev),0);
   {$I-}
   Reset(F);
   if ioResult <> 0 then
   begin
      Rewrite(F);

      Lev['A'].Desc      := 'New user access level';
      Lev['A'].SL        := 25;
      Lev['A'].DSL       := 25;
      Lev['A'].UserNote  := 'New user access';
      Lev['A'].timeLimit := 25;
      Lev['A'].filePts   := 0;
      Lev['A'].postCall  := 20;
      Lev['A'].limitDL   := 5;
      Lev['A'].limitDLkb := 100;
      Lev['A'].uldlRatio := 1;
      Lev['A'].kbRatio   := 10;

      Lev['B'].Desc      := 'Normal user access level';
      Lev['B'].SL        := 50;
      Lev['B'].DSL       := 50;
      Lev['B'].UserNote  := 'Normal access';
      Lev['B'].timeLimit := 60;
      Lev['B'].filePts   := 50;
      Lev['B'].postCall  := 20;
      Lev['B'].limitDL   := 10;
      Lev['B'].limitDLkb := 600;
      Lev['B'].uldlRatio := 5;
      Lev['B'].kbRatio   := 15;

      Lev['C'].Desc      := 'Enhanced user access level';
      Lev['C'].SL        := 100;
      Lev['C'].DSL       := 100;
      Lev['C'].UserNote  := 'Enhanced access';
      Lev['C'].timeLimit := 80;
      Lev['C'].filePts   := 150;
      Lev['C'].postCall  := 10;
      Lev['C'].limitDL   := 15;
      Lev['C'].limitDLkb := 1500;
      Lev['C'].uldlRatio := 10;
      Lev['C'].kbRatio   := 30;

      Lev['D'].Desc      := 'Co-SysOp access level';
      Lev['D'].SL        := 250;
      Lev['D'].DSL       := 250;
      Lev['D'].UserNote  := 'Co-SysOp access';
      Lev['D'].timeLimit := 120;
      Lev['D'].filePts   := 200;
      Lev['D'].postCall  := 0;
      Lev['D'].limitDL   := 20;
      Lev['D'].limitDLkb := 5000;
      Lev['D'].uldlRatio := 30;
      Lev['D'].kbRatio   := 100;

      Lev['E'].Desc      := 'SysOp access level';
      Lev['E'].SL        := 255;
      Lev['E'].DSL       := 255;
      Lev['E'].UserNote  := 'SysOp access';
      Lev['E'].timeLimit := 64000;
      Lev['E'].filePts   := 64000;
      Lev['E'].postCall  := 0;
      Lev['E'].limitDL   := 64000;
      Lev['E'].limitDLkb := 64000;
      Lev['E'].uldlRatio := 64000;
      Lev['E'].kbRatio   := 64000;

      Write(F,Lev);
   end else Read(F,Lev);
   Close(F);
   {$I+}
end;

procedure levelSave(var Lev : tLevels);
var F : file of tLevels;
begin
   Assign(F,Cfg^.pathData+fileLevels);
   {$I-}
   Rewrite(F);
   if ioResult <> 0 then Exit;
   Write(F,Lev);
   Close(F);
   {$I+}
end;

end.