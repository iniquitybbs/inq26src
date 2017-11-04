{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Attach;

interface

uses Global;

procedure atAskDownload(var Head : tMsgHeaderRec);
function  atAttachFile(var Head : tMsgHeaderRec) : Boolean;
procedure atKillAttach(N : Word);

implementation

uses Files, Transfer, MsgArea, Strings, Output, Input, DateTime, Misc;

function atAddFile(var A : tAttachRec) : Word;
var F : file of tAttachRec; R : tAttachRec; N : Word; Found : Boolean;
begin
   atAddFile := 0;
   Assign(F,Cfg^.pathData+fileAttach);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(F);
      {$I+}
      if ioResult <> 0 then Exit;
      Write(f,a);
      n := 1;
      atAddFile := n;
      Close(f);
      Exit;
   end;

   found := False;
   n := 0;
   while (not (found or Eof(f))) do
   begin
      Read(f,r);
      Inc(n);
      found := r.filename = '';
   end;
   if found then
   begin
      Seek(f,n-1);
      Write(f,a);
      Close(f);
      atAddFile := n;
      Exit;
   end;
   Seek(F,fileSize(f));
   Write(F,A);
   N := fileSize(f);
   Close(F);
   atAddFile := N;
end;

procedure atKillAttach(N : Word);
var F : file of tAttachRec; A : tAttachRec; x : Word;
begin
   if N = 0 then Exit;
   Assign(F,Cfg^.pathData+fileAttach);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   if N <= FileSize(F) then
   begin
      Seek(f,n-1);
      Read(f,a);
      fDeleteFile(Cfg^.pathAtch+A.Filename);
      Seek(f,n-1);
      a.filename := '';
      Write(f,a);
{     for x := fileSize(f) downto n+1 do
      begin
         Seek(f,x-1);
         Read(f,a);
         Seek(f,x-2);
         Write(f,a);
      end;
      Seek(f,fileSize(f)-1);
      Truncate(f);}
   end;
   Close(F);
end;

function atAttachFile(var Head : tMsgHeaderRec) : Boolean;
var A : tAttachRec; S, T : String; Ok : Boolean; Z : Word; F : file;
begin
   atAttachFile := False;
   FillChar(A,SizeOf(A),0);
   oClrScr;
   if Head.incFile > 0 then
   begin
      oString(strAtchAlreadyInc);
      if not iYesNo(False) then Exit;
      atKillAttach(Head.incFile);
      Head.incFile := 0;
   end;
   S := '';
   if acsOk(Cfg^.acsSysOp) then
   begin
      oStrCtrLn('|U5-- |U4Enter filename to attach to message |U2[|U3Enter|U2/|U1Upload|U2]|U5');
      oStrCtr('|U5: |U6');
      S := iReadString('',inUpper,chDirectory,'',70);
      if S <> '' then
      begin
         if not fExists(S) then Exit;
         fFindFile(S);
         if not fileFound then Exit;
         if not fCopyFile(S,Cfg^.pathAtch+Search.Name) then Exit;
         S := Search.Name;
      end;
   end;
   if S = '' then
   begin
      T := fTempPath('I');
      fClearDir(T);
      fCreateDir(T,False);
      if not xferReceive('',[protActive,protBatch]) then Exit;
      fCreateDir(T,False);
      fFindFile(T+'*.*');
      if not fileFound then Exit;
      S := Search.Name;
      Ok := fCopyFile(T+S,Cfg^.pathAtch+S);
      fClearDir(T);
      if not Ok then Exit;
   end;
   A.ulDate := dtDateString;
   A.Filename := UpStr(S);
   A.Size := fFileSize(Cfg^.pathAtch+A.Filename);
   oString(strAtchAskDesc);
   A.Desc := iReadString('',inNormal,chNormal,rsMin,70);
   Head.incFile := atAddFile(A);
   if Head.incFile = 0 then Exit;
   oStrLn(strCode(mStr(strAtchFileAttached),1,A.Filename));
   oDnLn(1);
   oPromptKey;
   atAttachFile := True;
end;

procedure atAskDownload(var Head : tMsgHeaderRec);
var A : tAttachRec; F : file of tAttachRec; Send : Boolean; S : String;
begin
   if Head.incFile = 0 then Exit;
   Assign(F,Cfg^.pathData+fileAttach);
   {$I-}
   Reset(F);
   {$I+}
   if ioResult <> 0 then Exit;
   if Head.incFile <= FileSize(F) then
   begin
      Seek(F,Head.incFile-1);
      Read(F,A);
   end else
   begin
      Close(F);
      Head.incfile := 0;
      Exit;
   end;
   Close(F);
   if oWhereX <> 1 then oDnLn(1);
   oStringLn(strAtchIsAttached);
   oStrLn(strCode(mStr(strAtchShowDesc),1,A.Desc));
   oStrLn(strCode(strCode(mStr(strAtchShowInfo),1,A.Filename),2,Stc(A.Size)));
   oString(strAtchAskDownload);
   Send := False;
   if iYesNo(False) then
   begin
      if acsOk(Cfg^.acsSysOp) then
      begin
         oStrCtr('|U5-- |U4Enter directory to copy file to |U2[|U3Enter|U2/|U1Download|U2]|U5');
         oStrCtr('|U5: |U6');
         S := iReadString('',inUpper,chDirectory,'',76);
         if S = '' then Send := True else
         begin
            if S[Length(S)] <> '\' then S := S+'\';
            if fDirExists(S) then
            begin
               Send := not fCopyFile(Cfg^.pathAtch+A.Filename,S+A.Filename);
            end else Send := True;
         end;
      end else Send := True;
      if Send then xferSend(Cfg^.pathAtch+A.Filename,[protActive]);
   end;
   oDnLn(1);
end;

end.