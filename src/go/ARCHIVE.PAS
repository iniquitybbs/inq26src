{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Archive;

interface

uses Global;

function  archComment(Arch,Fs : String) : Boolean;
function  archDelete(Arch,Fs : String) : Boolean;
procedure archLoadArch(var A : tArchiverRec; N : Byte);
procedure archSaveArch(var A : tArchiverRec; N : Byte);
function  archScan(Arch : String) : Boolean;
function  archTest(Arch : String) : Boolean;
function  archType(Arch : String) : Word;
function  archUnzip(Arch,Fs,Wd : String) : Boolean;
function  archView(Fn : String) : Boolean;
function  archZip(Arch,Fs : String; x : Word) : Boolean;

implementation

uses Dos,
     BBSinit, Strings, Files, Misc, Output, ShowFile, DateTime;

procedure archLoadArch(var A : tArchiverRec; N : Byte);
var F : file of tArchiverRec;
begin
   FillChar(A,SizeOf(A),0);
   Assign(F,Cfg^.pathData+fileArchiver);
   {$I-}
   Reset(F);
   {$I-}
   if (ioResult <> 0) then
   begin
      resetArchivers;
      Reset(F);
   end;
   if FileSize(F) <> maxArchiver then
   begin
      Close(F);
      resetArchivers;
      Reset(F);
   end;
   Seek(F,N-1);
   Read(F,A);
   Close(F);
end;

procedure archSaveArch(var A : tArchiverRec; N : Byte);
var F : file of tArchiverRec;
begin
   Assign(F,Cfg^.pathData+fileArchiver);
   {$I-}
   Reset(F);
   {$I-}
   if (ioResult <> 0) then
   begin
      resetArchivers;
      Reset(F);
   end;
   if FileSize(F) <> maxArchiver then
   begin
      Close(F);
      resetArchivers;
      Reset(F);
   end;
   Seek(F,N-1);
   Write(F,A);
   Close(F);
end;

function archSigID(var A : tArchiverRec; Fn : String) : Boolean;
var F : file; Sig, Rd : String; L : Byte;
begin
   archSigID := False;
   if A.fileSig = '' then Exit;
   Sig := mArchSig(A.fileSig);
   if Sig = '' then Exit;
   Assign(F,Fn);
   {$I-}
   Reset(F,1);
   {$I+}
   L := Length(Sig);
   if FileSize(F) >= L then
   begin
      Rd[0] := Sig[0];
      BlockRead(F,Rd[1],L);
      archSigID := Rd = Sig;
   end;
   Close(F);
end;

function archType(Arch : String) : Word;
var F : file of tArchiverRec; Found : Boolean; A : tArchiverRec; N : Word;
begin
   archType := 0;
   if (Length(Arch) < 2) or (Pos('.',Arch) = 0) then Exit;
   Assign(F,Cfg^.pathData+fileArchiver);
   {$I-}
   Reset(F);
   {$I-}
   if (ioResult <> 0) then
   begin
      resetArchivers;
      Reset(F);
   end;
   if FileSize(F) <> maxArchiver then
   begin
      Close(F);
      resetArchivers;
      Reset(F);
   end;
   Found := False;
   N := 0;
   while (not Found) and (not Eof(F)) do
   begin
      Read(F,A);
      Inc(N);
      Found := (A.Active) and
              ((A.Extension = UpStr(Copy(Arch,Pos('.',Arch)+1,255))) or
               (archSigID(A,Arch)));
   end;
   Close(F);
   if Found then archType := N;
end;

function archUnzip(Arch,Fs,Wd : String) : Boolean;
var A : tArchiverRec; x : Word; S : String;
begin
   archUnzip := False;
   x := archType(Arch);
   if x = 0 then Exit;
   fCreateDir(Wd,False);
   archLoadArch(A,x);
   S := strReplace(A.cmdUnzip,'%AF',Arch);
   S := strReplace(S,'%FN',Fs);
   fShellDos(Cfg^.pathArch+S,Cfg^.ArchiverSwap,False,True);
   if A.CheckEL then archUnzip :=
      (Lo(execLevel) = A.okErrLevel) and
      (Hi(execLevel) = 0)
      else archUnzip := True;
end;

function archDelete(Arch,Fs : String) : Boolean;
var A : tArchiverRec; x : Word; S : String;
begin
   archDelete := False;
   x := archType(Arch);
   if x = 0 then Exit;
   archLoadArch(A,x);
   S := strReplace(A.cmdDelete,'%AF',Arch);
   if Fs[1] = '@' then Fs[1] := A.listChar;
   S := strReplace(S,'%FN',Fs);
   fShellDos(Cfg^.pathArch+S,Cfg^.ArchiverSwap,False,True);
   if A.CheckEL then archDelete :=
      (Lo(execLevel) = A.okErrLevel) and
      (Hi(execLevel) = 0)
      else archDelete := True;
end;

function archComment(Arch,Fs : String) : Boolean;
var A : tArchiverRec; x : Word; S : String;
begin
   archComment := False;
   x := archType(Arch);
   if x = 0 then Exit;
   archLoadArch(A,x);
   S := strReplace(A.cmdComment,'%AF',Arch);
   S := strReplace(S,'%CF',Fs);
   fShellDos(Cfg^.pathArch+S,Cfg^.ArchiverSwap,False,True);
   if A.CheckEL then archComment:=
      (Lo(execLevel) = A.okErrLevel) and
      (Hi(execLevel) = 0)
      else archComment := True;
end;

function archZip(Arch,Fs : String; x : Word) : Boolean;
var A : tArchiverRec; S : String;
begin
   archZip := False;
   if x = 0 then x := archType(Arch);
   if x = 0 then Exit;
   archLoadArch(A,x);
   S := strReplace(A.cmdZip,'%AF',Arch);
   if Fs[1] = '@' then Fs[1] := A.listChar;
   S := strReplace(S,'%FN',Fs);
   fShellDos(Cfg^.pathArch+S,Cfg^.ArchiverSwap,False,True);
   if A.CheckEL then archZip :=
      (Lo(execLevel) = A.okErrLevel) and
      (Hi(execLevel) = 0)
      else archZip := True;
end;

function archTest(Arch : String) : Boolean;
var A : tArchiverRec; S : String; x : Byte;
begin
   archTest := False;
   x := archType(Arch);
   if x = 0 then Exit;
   archLoadArch(A,x);
   S := strReplace(A.cmdTest,'%AF',Arch);
   fShellDos(Cfg^.pathArch+S,Cfg^.ArchiverSwap,False,True);
   if A.CheckEL then archTest :=
      (Lo(execLevel) = A.okErrLevel) and
      (Hi(execLevel) = 0)
      else archTest := True;
end;

function archScan(Arch : String) : Boolean;
var cmd : String;
begin
   archScan := True;
   if Cfg^.virusScan = '' then Exit;
   cmd := strReplace(Cfg^.virusScan,'%FN',Arch);
   fShellDos(Cfg^.pathArch+cmd,Cfg^.ArchiverSwap,False,True);
   archScan := (Lo(execLevel) = Cfg^.virusOk) and
               (Hi(execLevel) = 0);
end;

function archView(Fn : String) : Boolean;
var Ans : Boolean; z : Byte; Final : String; F : file; Arch : tArchiverRec;
    tmStr : array[1..8] of String[20];

 procedure avZip;
 const zipSig = $04034B50;
       zipComp : array[0..8] of String[9] =
              ('Stored','Shrunk','Reduced/1','Reduced/2','Reduced/3',
               'Reduced/4','Imploded','Tokenized','Deflated');
 type zipHeader = record
         Signature  : LongInt;
         Version,
         GPBFlag,
         Compress,
         Time, Date  : Word;
         CRC32,
         CSize,
         USize      : LongInt;
         FNameLen,
         ExtraField : Word;
      end;

 var z, rat : Integer; totalu, totalc, dtp : LongInt; Hdr : zipHeader;
     S, s2 : String; dt : Dos.DateTime; l : String[80];

  function format_date(date: word): string;
  var s,s2: string; y,m,d: word;
  begin
     m:=(date shr 5) and 15;
     d:=( (date      ) and 31);
     y:=(((date shr 9) and 127)+80);
     str(m,s);
     while length(s)<2 do s:='0'+s;
     s:=s+'/';
     str(d,s2);
     while length(s2)<2 do s2:='0'+s2;
     s:=s+s2+'/';
     str(y,s2);
     while length(s2)<2 do s2:='0'+s2;
     s:=s+s2;
     format_date:=s;
  end;

  function format_time(time: word): string;
  var s,s2,p: string; h,m,se: word; pm : Boolean;
  begin
     h:=(time shr 11) and 31;
     m:=(time shr  5) and 63;
     se:=(time shl  1) and 63;
     Pm := H >= 12;
     if H > 12 then Dec(H,12);
     if H = 0 then H := 12;
     if pm then p := 'pm' else p := 'am';
     str(h,s);
     s:=s+':';
     str(m,s2);
     while length(s2)<2 do s2:='0'+s2;
     s:=s+s2+p;
     format_time:=s;
  end;

 begin
    z := 0;
    totalu := 0;
    totalc := 0;
    repeat
       FillChar(S,SizeOf(S),#0);
       BlockRead(F,Hdr,SizeOf(zipHeader));
       BlockRead(F,Mem[Seg(S):Ofs(S)+1],Hdr.FNameLen);
       s[0] := Chr(Hdr.FNameLen);
       S := strFilename(S);
       if Pos('.',s) > 0 then
       begin
          s2 := strFileExt(S);
          Delete(s,Pos('.',s),255);
       end else s2 := '';
       if Hdr.Signature = zipSig then
       begin
          Inc(Z);
          if Hdr.uSize = 0 then rat := 0 else rat := Trunc(100-Hdr.CSize/Hdr.USize*100);
          if rat > 99 then rat := 99;

          if Ans then
          begin
             sfStr[1] := St(Z);
             sfStr[2] := Resize(S,9)+Resize(s2,4);
             sfStr[3] := Stc(Hdr.uSize);
             sfStr[4] := Stc(Hdr.cSize);
             sfStr[5] := St(rat)+'%';
             sfStr[6] := zipComp[Hdr.Compress];
             sfStr[7] := format_date(hdr.Date);
             sfStr[8] := format_time(hdr.Time);
             sfShowRepeat(ftArchiver);
             if oWhereX <> 1 then oDnLn(1);
          end else
          oWriteLn(' '+Resize(S,9)+Resize(s2,4)+
                   ' '+ResizeRt(Stc(Hdr.uSize),10)+' '+
                   ' '+ResizeRt(Stc(Hdr.cSize),10)+' '+
                   ' '+Resize(St(rat)+'%',6)+
                   ' '+Resize(zipComp[Hdr.Compress],10)+
                   ' '+Resize(format_date(hdr.Date),9)+
                   ' '+format_time(hdr.Time));
          oUpPause(1);
          Inc(TotalU,Hdr.USize);
          Inc(TotalC,Hdr.CSize);
       end;
       Seek(F,FilePos(F)+Hdr.CSize+Hdr.ExtraField);
    until (pauseAbort) or (Hdr.Signature <> zipSig);
    GetFTime(F,dtp);
    UnPackTime(dtp,dt);
    if TotalU > 0 then Rat := Trunc(100-TotalC/TotalU*100) else Rat := 0;
    if Rat > 99 then Rat := 99;

    tmStr[1] := '--';
    tmStr[2] := St(Z)+' files';
    tmStr[3] := Stc(TotalU);
    tmStr[4] := Stc(TotalC);
    tmStr[5] := St(Rat)+'%';
    tmStr[6] := '---';
    tmStr[7] := '---';
    tmStr[8] := '---';

    Final := ' '+Resize(St(Z)+' files',13)+
             ' '+ResizeRt(Stc(TotalU),10)+' '+
             ' '+ResizeRt(Stc(TotalC),10)+' '+
             ' '+Resize(St(rat)+'%',6)+
             ' '+Resize('---',10)+
             ' '+Resize('---',9)+
             ' '+'---';
 end;

begin
   archView := False;
   z := archType(Fn);
   if z = 0 then Exit;
   archLoadArch(Arch,z);

   if not (Arch.Viewer in [2]) then Exit;
   Assign(F,Fn);
   {$I-}
   Reset(F,1);
   {$I-}
   if ioResult <> 0 then Exit;

   pausePos := 1;
   pauseAbort := False;
   Ans := (sfGetTextFile(txArchTop,ftTopLine) <> '') and
          (sfGetTextFile(txArchMid,ftArchiver) <> '') and
          (sfGetTextFile(txArchBot,ftNormal)  <> '');
   archView := True;
   if Ans then
   begin
      sfShowTextFile(txArchTop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txArchMid);
   end else
   begin
      oClrScr;
      oDnLn(1);
      oSetCol(colInfo);
      oWriteLn(' Filename            Size        Comp  Ratio  Method     Date      Time');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(3);
      oSetCol(colText);
   end;

   case Arch.Viewer of
      2 : avZip;
   end;

   Close(F);
   if Ans then
   begin
      sfShowTextFile(txArchBot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
      oSetCol(colText);
   end;
   if Ans then
   begin
      sfStr[1] := tmStr[1];
      sfStr[2] := tmStr[2];
      sfStr[3] := tmStr[3];
      sfStr[4] := tmStr[4];
      sfStr[5] := tmStr[5];
      sfStr[6] := tmStr[6];
      sfStr[7] := tmStr[7];
      sfStr[8] := tmStr[8];
      sfShowRepeat(ftArchiver);
      if oWhereX <> 1 then oDnLn(1);
   end else oWriteLn(Final);
   oUpPause(1);
   sfKillRepeat;
   PausePos := 0;
end;

end.