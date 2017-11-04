{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit MicroDOS;

interface


procedure dosExecuteMicroDOS;

implementation

uses Dos,
     Global, Strings, Output, Files, ShowFile, Input, Misc, Logs, Transfer,
     MsgArea;

var xWord : array[1..9] of String;

procedure dosParse(S : String);
var I, J, K : Integer;
begin
   S := UpStr(S);
   if S = 'DIR/W' then S := 'DIR *.* /W' else
   if Copy(S,1,3) = 'CD\' then Insert(' ',S,3) else
   if Copy(S,1,3) = 'CD.' then Insert(' ',S,3);
   for I := 1 to 9 do xWord[I] := '';
   I := 1; J := 1; K := 1;
   if (Length(S) = 1) then xWord[1] := S;
   while (I < Length(S)) do
   begin
      Inc(I);
      if ((S[I] = ' ') or (Length(S) = I)) then
      begin
         if (Length(S) = I) then Inc(I);
         xWord[K] := Copy(S,J,(I-J));
         J := I+1;
         Inc(K);
      end;
   end;
end;

procedure dosExecuteMicroDOS;
var CurDir, S, s1 : String;
    mdDone, NoCmd, NoSpace : Boolean;

 procedure mdVersion;
 begin
   oDnLn(1);
   oCWriteLn('|U5 -- |U6'+bbsTitle+' MicroDOS Version '+bbsVersion+' |U5ú (C)Copyright 1994-1995, Mike Fricker');
   oDnLn(1);
 end;

 function mdAlign(S : String) : String;
 begin
    if (S = '..') or (S = '.') or (Pos('.',S) = 0) then S := '|U6'+Resize(S,12)
       else S := '|U6'+Resize(Copy(S,1,Pos('.',S)-1),8)+' |U4'+Resize(Copy(S,Pos('.',S)+1,3),3);
    mdAlign := S;
 end;

 function mdFileInfo : String;
 var Pm : Char; I : Integer; S : String; Dt : DateTime;
  function fiTi(I : Integer) : String;
  var Z : String;
  begin
     Z := St(I);
     if Length(Z) = 1 then Insert('0',Z,1);
     fiTi := Z;
  end;
 begin
   S := Search.Name;
   if (Search.Attr and Directory) = Directory then S := mdAlign(S)+'  <DIR>  '
      else S := mdAlign(S)+'  |U6'+ResizeRt(St(Search.Size),7);
   UnPackTime(Search.Time,Dt);
   with Dt do
   begin
      if Hour < 13 then Pm := 'a' else
      begin
         Pm := 'p';
         Hour := Hour-12;
      end;
      S := S+'  |U4'+FiTi(Month)+'|U5-|U4'+fiTi(Day)+'|U5-|U4'+fiTi(Year-1900)+
             '  '+FiTi(Hour)+'|U5:|U4'+fiTi(Min)+Pm;
   end;
   mdFileInfo := S;
 end;

 procedure mdDirectory(Cd, X : String; Expanded : Boolean);
 var NoFiles : Boolean; S : String; onLin : Integer; Dfs : LongInt;
     numFiles : Integer;
 begin
    if (Copy(Cd,Length(Cd),1) <> '\') then Cd := Cd+'\';
    Cd := Cd+X;
    oCWriteLn('|U1 Directory of |U3'+Copy(Cd,1,Length(Cd)));
    oDnLn(1);
    S := ''; onLin := 0; numFiles := 0; noFiles := True;
    FindFirst(Cd,anyFile,Search);
    FileFound := (dosError = 0);
    while FileFound do
    begin
{       if not (Search.Attr and Directory = Directory) then}
         if not (Search.Attr and VolumeID = VolumeID) then
           if (not (Search.Attr and Hidden = Hidden)) or (acsOk(Cfg^.acsSysOp)) then
             if (Search.Attr and Hidden = Hidden) and
                (not (Search.Attr and Directory = Directory)) or
                (not (Search.Attr and Hidden = Hidden)) then
             begin
                noFiles := False;
                if (Expanded) then oCWriteLn(mdFileInfo) else
                begin
                   Inc(onLin);
                   S := S+mdAlign(Search.Name);
                   if onLin <> 5 then S := S+'    ' else
                   begin
                      oCWriteLn(S);
                      S := '';
                      onLin := 0;
                   end;
                end;
                Inc(numFiles);
             end;
             fFindNext;
    end;
    if (not FileFound) and (onLin in [1..5]) then oCWriteLn(S);
    Dfs := fFreeSpace;
    if noFiles then S := '|U0No files found' else
                    S := '|U3             '+St(numFiles)+'|U1 File(s)';
    oCWriteLn(S+'|U3'+ResizeRt(St(Dfs),10)+'|U1 bytes free');
 end;

 procedure mdMicroCommand(Cmd : String);
 var Fi : file of Byte; F : file; Ps, Ns, Es, Op, Np : String;
     s1, s2, s3 : String; numFiles, tSiz : LongInt; retLevel, I, J : Integer;
     B, Ok : Boolean;
 begin
    NoCmd := False;
    for I := 1 to 9 do xWord[I] := UpStr(xWord[I]);
    S := xWord[1];

    if (S = '?') or (S = 'HELP') then sfShowTextFile(txMicroHelp,ftNormal) else
    if (S = 'EDIT') or (S = 'EDLIN') then
    begin
       if xWord[2] <> '' then maEditTextFile(xWord[2]) else
          oWriteLn('Usage: EDIT filename.ext');
    end else
    if (S = 'EXIT') or (S = 'QUIT') then mdDone := True else
    if (S = 'DEL') or (S = 'ERASE') then
    begin
       if ((not fExists(xWord[2])) and (not strIsWild(xWord[2]))) or
          (xWord[2] = '') then oWriteLn('File not found.') else
       begin
          xWord[2] := fExpand(xWord[2]);
          fFindFile(xWord[2]);
          repeat
             if not ((Search.Attr and VolumeID = VolumeID) or
                     (Search.Attr and Directory = Directory)) then
             begin
                Assign(F,Search.Name);
                {$I-} Erase(F); {$I+}
                if (ioResult <> 0) then oWriteLn('Error deleting: "'+Search.Name+'"');
             end;
             fFindNext;
          until (not FileFound) or (HangUp);
       end;
    end else
    if (S = 'TYPE') then
    begin
       if not sfShowFile(fExpand(xWord[2]),ftNormal) then oWriteLn('File not found.');
    end else
    if ((S = 'REN') or (S = 'RENAME')) then
    begin
       if ((not fExists(xWord[2])) and (xWord[2] <> '')) then
          oWriteLn('File not found.') else
       begin
          xWord[2] := fExpand(xWord[2]);
          Assign(F,xWord[2]);
          {$I-} Rename(F,xWord[3]); {$I+}
          if (ioResult <> 0) then oWriteLn('File not found.');
       end;
    end else
    if (S = 'DIR') then
    begin
       B := True;
       for I := 2 to 9 do if (xWord[I] = '/W') then
       begin
          B := False;
          xWord[I] := '';
       end;
       if (xWord[2] = '') then xWord[2] := '*.*' else
       if (xWord[2,1] = '.') then Insert('*',xWord[2],1);
       s1 := CurDir;
       xWord[2] := fExpand(xWord[2]);
       fSplit(xWord[2],Ps,Ns,Es);
       s1 := Ps;
       s2 := Ns+Es;
       if (s2 = '') then s2 := '*.*';
       if (not strIsWild(xWord[2])) then
       begin
          FindFirst(xWord[2],anyFile,Search);
          FileFound := (dosError = 0);
          if ((FileFound) and (Search.Attr = Directory)) or
             ((Length(s1) = 3) and (s1[3] = '\')) then
          begin
             s1 := strBkSlash(True,xWord[2]);
             s2 := '*.*';
          end;
       end;
       oDnLn(1);
       mdDirectory(s1,s2,B);
       oDnLn(1);
    end else
    if ((S = 'CD') or (S = 'CHDIR')) and (xWord[2] <> '') then
    begin
       xWord[2] := fExpand(xWord[2]);
       {$I-} ChDir(xWord[2]); {$I+}
       if (ioResult <> 0) then oWriteLn('Invalid pathname.');
    end else
    if ((S = 'MD') or (S = 'MKDIR')) and (xWord[2]<>'') then
    begin
       {$I-} MkDir(xWord[2]); {$I+}
       if (ioResult <> 0) then oWriteLn('Unable to create directory.');
    end else
    if ((S = 'RD') or (S = 'RMDIR')) and (xWord[2]<>'') then
    begin
       {$I-} RmDir(xWord[2]); {$I+}
       if (ioResult <> 0) then oWriteLn('Unable to remove directory.');
    end else
{    if (S='COPY') and (not restr1) then begin
      if (xWord[2]<>'') then begin
        if (iswildcard(xWord[3])) then
          print('Wildcards not allowed in destination parameter!')
        else begin
          if (xWord[3]='') then xWord[3]:=curdir;
          xWord[2]:=bslash(False,fexpand(xWord[2]));
          xWord[3]:=fexpand(xWord[3]);
          ffile(xWord[3]);
          b:=((found) and (Search.Attr and directory=directory));
          if ((not b) and (copy(xWord[3],2,2)=':\') and
              (length(xWord[3])=3)) then b:=True;

          fsplit(xWord[2],op,ns,es);
          op:=bslash(True,op);

          if (b) then
            np:=bslash(True,xWord[3])
          else begin
            fsplit(xWord[3],np,ns,es);
            np:=bslash(True,np);
          end;

          j:=0;
          abort:=False; next:=False;
          ffile(xWord[2]);
          while (found) and (not abort) and (not hangup) do begin
            if (not ((Search.Attr=directory) or (Search.Attr=volumeid))) then
            begin
              s1:=op+Search.name;
              if (b) then s2:=np+Search.name else s2:=np+ns+es;
              prompt(s1+' -> '+s2+' :');
              copyfile(ok,nospace,True,s1,s2);
              if (ok) then begin
                inc(j);
                nl;
              end else
                if (nospace) then sprompt(#3#7+' - *Insufficient space*')
                else sprompt(#3#7+' - *Copy failed*');
              nl;
            end;
            if (not empty) then wkey(abort,next);
            nfile;
          end;
          if (j<>0) then begin
            prompt('  '+cstr(j)+' file');
            if (j<>1) then prompt('S');
            print(' copied.');
          end;
        end;
      end;
    end
    else
    if (S='MOVE') and (not restr1) then begin
      if (xWord[2]<>'') then begin
        if (iswildcard(xWord[3])) then
          print('Wildcards not allowed in destination parameter!')
        else begin
          if (xWord[3]='') then xWord[3]:=curdir;
          xWord[2]:=bslash(False,fexpand(xWord[2]));
          xWord[3]:=fexpand(xWord[3]);
          ffile(xWord[3]);
          b:=((found) and (Search.Attr and directory=directory));
          if ((not b) and (copy(xWord[3],2,2)=':\') and
              (length(xWord[3])=3)) then b:=True;

          fsplit(xWord[2],op,ns,es);
          op:=bslash(True,op);

          if (b) then
            np:=bslash(True,xWord[3])
          else begin
            fsplit(xWord[3],np,ns,es);
            np:=bslash(True,np);
          end;

          j:=0;
          abort:=False; next:=False;
          ffile(xWord[2]);
          while (found) and (not abort) and (not hangup) do begin
            if (not ((Search.Attr=directory) or (Search.Attr=volumeid))) then
            begin
              s1:=op+Search.name;
              if (b) then s2:=np+Search.name else s2:=np+ns+es;
              prompt(s1+' -> '+s2+' :');
              movefile(ok,nospace,True,s1,s2);
              if (ok) then begin
                inc(j);
                nl;
              end else
                if (nospace) then sprompt(#3#7+' - *Insufficient space*')
                else sprompt(#3#7+' - *Move failed*');
              nl;
            end;
            if (not empty) then wkey(abort,next);
            nfile;
          end;
          if (j<>0) then begin
            prompt('  '+cstr(j)+' file');
            if (j<>1) then prompt('S');
            print(' moved.');
          end;
        end;
      end;
    end
    else}
    if (S = 'CLS') then oClrScr else
    if (length(S)=2) and (S[1]>='A') and (S[1]<='Z') and (S[2]=':') then
    begin
      {$I-} getdir(ord(S[1])-64,s1); {$I+}
      if (ioresult<>0) then oWriteLn('Invalid drive.')
      else begin
        {$I-} chdir(s1); {$I+}
        if (ioresult<>0) then begin
          oWriteLn('Invalid drive.');
          chdir(curdir);
        end;
      end;
    end
    else
    if (S='IFL') then begin
      if (xWord[2]='') then begin
{
        nl;
        print('IFL v1.30 - May 09 1989 - Interior File Listing Utility');
        print('Copyright 1989 by Martin Pollard.  All rights reserved!');
        print('Licensed for internal usage in Telegard v'+ver);
}
        oDnLn(1);
        oWriteLn('Syntax is:   "IFL filename"');
        oDnLn(1);
{
        print('IFL produces a listing of files contained in an archive file.');
        print('Archive formats currently supported include:');
        nl;
        print('   ARC - Developed by System Enhancement Associates');
        print('            and enhanced by PKware (PKARC & PKPAK)');
        print('            and NoGate Consulting (PAK)');
        print('   LZH - Developed by Haruyasu Yoshizaki');
        print('   ZIP - Developed by PKware');
        print('   ZOO - Developed by Rahul Dhesi');
        nl;
        print('Support for other formats may be included in the future.');
        nl;
}
      end else
      begin
         s1:=xWord[2];
         if (pos('.',s1)=0) then s1:=s1+'*.*';
{         lfi(s1,abort,next);}
      end;
    end else
    if (S = 'SEND') and (xWord[2] <> '') then
    begin
       if fExists(xWord[2]) then xferSend(xWord[2],[protActive]) else
       if fExistsWild(xWord[2]) then xferSend(xWord[2],[protActive,protBatch]) else
       oWriteLn('No files found to transmit.');
    end else
    if (S = 'VER') then mdVersion else
    if (S = 'DIRSIZE') then begin
      oDnLn(1);
      if (xWord[2]='') then oWriteLn('Too few parameters.')
      else begin
        numfiles:=0; tsiz:=0;
        fFindFile(xWord[2]);
        while (FileFound) do
        begin
          inc(tsiz,Search.size);
          inc(numfiles);
          fFindNext;
        end;
        if (numfiles=0) then oWriteLn('No files found!')
          else oWriteLn('"'+UpStr(xWord[2])+'": '+St(numfiles)+' files, '+
                     St(tsiz)+' bytes.');
      end;
      oDnLn(1);
    end
    else
{    if (S = 'DISKFREE') then begin
      if (xWord[2]='') then j:=exdrv(curdir) else j:=exdrv(xWord[2]);
      nl;
      print(cstrl(freek(j)*1024)+' bytes free on '+chr(j+64)+':');
      nl;
    end
    else}
    if S = 'EXT' then
    begin
       s1 := Cmd;
       j := Pos('EXT',UpStr(s1))+3; s1 := Copy(s1,j,Length(s1)-(j-1));
       while Copy(s1,1,1) = ' ' do s1 := Copy(s1,2,Length(s1)-1);
       if Length(s1) > 127 then
       begin
          oDnLn(1);
          oWriteLn('Command exceeds maximum length.');
          oDnLn(1);
       end else fShellDos(s1,True,True,False);
    end else
    if S = 'RECEIVE' then
    begin
       if xWord[2] = '' then xferReceive('',[protActive,protBatch]) else
                             xferReceive(xWord[2],[protActive]);
    end else
(*    if ((S='CONVERT') or (S='CVT')) and (not restr1) then begin
      if (xWord[2]='') then begin
        nl;
        print(S+' - Telegard archive conversion command.');
        nl;
        print('Syntax is:   "'+S+' <Old Archive-name> <New Archive-extension>"');
        nl;
        print('Telegard will convert from the one archive format to the other.');
        print('You only need to specify the 3-letter extension of the new format.');
        nl;
      end else begin
        if (not exist(xWord[2])) or (xWord[2]='') then print('File not found.')
        else begin
          i:=arctype(xWord[2]);
          if (i=0) then invarc
          else begin
            s3:=xWord[3]; s3:=copy(s3,length(s3)-2,3);
            j:=arctype('FILENAME.'+s3);
            fsplit(xWord[2],ps,ns,es);
            if (length(xWord[3])<=3) and (j<>0) then
              s3:=ps+ns+'.'+systat.filearcinfo[j].ext
            else
              s3:=xWord[3];
            if (j=0) then invarc
            else begin
              ok:=True;
              conva(ok,i,j,systat.temppath+'1\',sqoutsp(fexpand(xWord[2])),
                    sqoutsp(fexpand(s3)));
              if (ok) then begin
                assign(fi,sqoutsp(fexpand(xWord[2])));
                {$I-} erase(fi); {$I+}
                if (ioresult<>0) then
                  star('Unable to delete original: "'+
                       sqoutsp(fexpand(xWord[2]))+'"');
              end else
                star('Conversion unsuccessful.');
            end;
          end;
        end;
      end;
    end else
    if ((S='UNARC') or (S='UNZIP') or
       (S='PKXARC') or (S='PKUNPAK') or (S='PKUNZIP')) and (not restr1) then begin
      if (xWord[2]='') then begin
        nl;
        print(S+' - Telegard archive de-compression command.');
        nl;
        print('Syntax is:   "'+S+' <Archive-name> Archive filespecs..."');
        nl;
        print('The archive type can be ANY archive format which has been');
        print('configured into Telegard via System Configuration.');
        nl;
      end else begin
        i:=arctype(xWord[2]);
        if (not exist(xWord[2])) then print('File not found.') else
          if (i=0) then invarc
          else begin
            s3:='';
            if (xWord[3]='') then s3:=' *.*'
            else
              for j:=3 to 9 do
                if (xWord[j]<>'') then s3:=s3+' '+fexpand(xWord[j]);
            s3:=copy(s3,2,length(s3)-1);
            shel1;
            pexecbatch(True,'tgtemp1.bat','',bslash(True,curdir),
                       arcmci(systat.filearcinfo[i].unarcline,fexpand(xWord[2]),s3),
                       retlevel);
            shel2;
          end;
      end;
    end
    else
    if ((S='ARC') or (S='ZIP') or
       (S='PKARC') or (S='PKPAK') or (S='PKZIP')) and (not restr1) then begin
      if (xWord[2]='') then begin
        nl;
        print(S+' - Telegard archive compression command.');
        nl;
        print('Syntax is:   "'+S+' <Archive-name> Archive filespecs..."');
        nl;
        print('The archive type can be ANY archive format which has been');
        print('configured into Telegard via System Configuration.');
        nl;
      end else begin
        i:=arctype(xWord[2]);
        if (i=0) then invarc
        else begin
          s3:='';
          if (xWord[3]='') then s3:=' *.*'
          else
            for j:=3 to 9 do
              if (xWord[j]<>'') then s3:=s3+' '+fexpand(xWord[j]);
          s3:=copy(s3,2,length(s3)-1);
          shel1;
          pexecbatch(True,'tgtemp1.bat','',bslash(True,curdir),
                     arcmci(systat.filearcinfo[i].arcline,fexpand(xWord[2]),s3),
                     retlevel);
          shel2;
        end;
      end;
    end else*)
    begin
       NoCmd := True;
       if (S <> '') then oWriteLn('Bad command or file name');
    end;
 end;

begin
   oClrScr;
   LogWrite('*Entered MicroDOS');
   ChDir(strBkSlash(False,StartDir));
   mdDone:=False;
   oCWriteLn('|U1Type "|U3EXIT|U1" to return to |U3'+bbsTitle+'.');
   oDnLn(1);
   mdVersion;
   repeat
      GetDir(0,curDir);
      oSetCol(colText);
      oCWrite('|U1'+curDir+'|U2>|U3');
      s1 := iReadString('',inNormal,chNormal,'',128);
      if (Cfg^.LogMicroDOS) and (s1 <> '') then logWrite('  '+curDir+'>'+s1);
      dosParse(s1);
      mdMicroCommand(s1);
   until (mdDone) or (HangUp);
   ChDir(strBkSlash(False,StartDir));
end;

end.