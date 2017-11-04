program iniqMenu;

uses Dos, Crt, Global, Strings, FastIO;

procedure imMenuConvert(Fn : String);
var F : Text; I : Word; Z : String; nF : file;
begin
   Assign(F,Fn+'.MNU');
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   numCmds := 0;
   FillChar(Menu^,SizeOf(Menu^),0);
   FillChar(Cmd^,SizeOf(Cmd^),0);

   with Menu^ do
   begin
      ReadLn(F,MenuName);
      ReadLn(F);
      ReadLn(F,PromptName);
      ReadLn(F,HelpFile);
      ReadLn(F);
      ReadLn(F,Prompt);
      if UpStr(prompt) = 'LIGHTBAR' then mType := 3 else mType := 1;
      ReadLn(F,ACS);
      Readln(F,Password);
      ReadLn(F,Fallback);
      ReadLn(F);
      Expert := 1;
      ReadLn(F,genColumns);
      HotKey := 1;
      ReadLn(F);
      ReadLn(F);
      ReadLn(F);
      Readln(F,Z);
      Z := UpStr(Z);
      ClearBefore := Pos('C',Z) > 0;
      CenterTtl := not (Pos('D',Z) > 0);
      ShowPrompt := not (Pos('N',Z) > 0);
      PauseBefore := Pos('P',Z) > 0;
      GlobalUse := Pos('G',Z) > 0;
      InputUp := True;
   end;
   while (numCmds < maxMenuCmd) and (not Eof(F)) do
   begin
      Inc(numCmds);
      with Cmd^[numCmds] do
      begin
         ReadLn(F,Help);
         ReadLn(F,Desc);
         while Pos(']',Help) > 0 do Delete(Help,1,Pos(']',Help));
         while Pos(')',Help) > 0 do Delete(Help,1,Pos(')',Help));
         if Help[1] = ' ' then Delete(Help,1,1);
         while Pos(']',Desc) > 0 do Delete(Desc,1,Pos(']',Desc));
         while Pos(')',Desc) > 0 do Delete(Desc,1,Pos(')',Desc));
         if Desc[1] = ' ' then Delete(Desc,1,1);
         ReadLn(F,Keys);
         ReadLn(F,ACS);
         ReadLn(F,Command);
         ReadLn(F,Param);
         ReadLn(F,Z);  { Reserved }
         Hidden := Pos('H',Z) > 0;
      end;
   end;
   Close(F);
{  Rename(F,Fn+'.OLD');}
   Assign(nf,Fn+'.MNU');
   {$I-}
   Rewrite(nf,1);
   {$I+}
   if ioResult <> 0 then Exit;
   BlockWrite(nf,Menu^,SizeOf(Menu^));
   BlockWrite(nf,Cmd^,SizeOf(Cmd^[1])*numCmds);
   Close(nf);
end;

var s : SearchRec; z : string;

begin
   TextMode(Co80);
   ioInitFastIO;
   ioClrScr;
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($0F);
   ioWriteLn('iniqMenu v'+bbsVersion+'  (c)Copyright 1995, Mike Fricker');
   ioTextAttr($08);
   ioWrite('-- ');
   ioTextAttr($07);
   ioWriteLn('Upgrade utility for Iniquity menu files (1.00a20r2 -> '+bbsVersion+')');
   ioTextAttr($08);
   ioWrite(sRepeat('Ä',80));
   ioTextAttr($07);
   New(Menu);
   New(Cmd);
   FindFirst('*.MNU',0,s);
   while dosError = 0 do
   begin
      z := s.name;
      ioWrite('Converting ');
      ioTextAttr($0F);
      ioWrite(s.name);
      ioTextAttr($08);
      ioWrite(' ...');
      Delete(z,Pos('.',z),255);
      imMenuConvert(z);
      FindNext(s);
      ioTextAttr($07);
      ioWriteLn('done');
   end;

   Dispose(Menu);
   Dispose(Cmd);
   ioTextAttr($07);
end.