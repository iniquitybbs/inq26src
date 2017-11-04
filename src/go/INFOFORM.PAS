{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Infoform;

interface

procedure ifInfoforms(quit : Boolean);
procedure ifPutString(cs : String);
procedure ifReadString(cs : String; len : Byte; min : Boolean);
procedure ifReset(z : Byte);
procedure ifResetForm(un, z : Word);
procedure ifResetUser(z : Word);
function  ifShowForm(num, un : Word; nuvi : Boolean) : Boolean;

implementation

uses
   Global, Strings, Input, ShowFile, Output, Misc;

var
  inf : file;
  ins : Word;
  mxs : Word;

procedure ifReset(z : Byte);
var f : file; x : Word; var buf : array[1..maxUsers] of Byte;
begin
   Assign(f,Cfg^.pathData+fileInfoPre+z3(z));
   {$I-}
   Rewrite(F,1);
   {$I+}
   if ioResult <> 0 then Exit;
   FillChar(buf,sizeOf(buf),0);
   for x := 1 to 6 do BlockWrite(f,buf,maxUsers);
   Close(f);
end;

procedure ifResetUser(z : Word);
var fi : file of tInfoformRec; f : file; x : Word; r : tInfoIdxRec; i : tInfoformRec;
begin
   Assign(fi,Cfg^.pathData+fileInfoform);
   {$I-}
   Reset(fi);
   {$I+}
   if ioResult <> 0 then Exit;
   numInfo := FileSize(fi);
   x := 0;
   FillChar(r,SizeOf(r),0);
   while not Eof(fi) do
   begin
      Read(fi,i);
      Inc(x);
      Assign(f,Cfg^.pathData+fileInfoPre+z3(x));
      {$I-}
      Reset(f,1);
      {$I+}
      if ioResult = 0 then
      begin
         Seek(f,z*6-6);
         BlockWrite(f,r,6);
         Close(f);
      end else ifReset(x);
   end;
   Close(fi);
end;

procedure ifResetForm(un, z : Word);
var fi : file of tInfoformRec; f : file; x : Word; r : tInfoIdxRec; i : tInfoformRec;
begin
   Assign(fi,Cfg^.pathData+fileInfoform);
   {$I-}
   Reset(fi);
   {$I+}
   if ioResult <> 0 then Exit;
   numInfo := FileSize(fi);
   if (z < 0) or (z > numInfo) then
   begin
      Close(fi);
      Exit;
   end;
   Seek(fi,z-1);
   Read(fi,i);
   Close(fi);

   FillChar(r,SizeOf(r),0);
   Assign(f,Cfg^.pathData+fileInfoPre+z3(x));
   {$I-}
   Reset(f,1);
   {$I+}
   if ioResult = 0 then
   begin
      Seek(f,un*6-6);
      BlockWrite(f,r,6);
      Close(f);
   end else ifReset(z);
end;

procedure ifReadString(cs : String; len : Byte; min : Boolean);
var s, l : String;
begin
   s := '';
   if min then l := rsMin else l := '';
   if cs = '' then cs := 'SN';
   case cs[1] of
     'S' : case cs[2] of
       'N' : s := iReadString('',inNormal,chNormal,l,Len);
       'M' : s := iReadString('',inMixed,chNormal,l,Len);
       'U' : s := iReadString('',inUpper,chNormal,l,Len);
       'L' : s := iReadString('',inLower,chNormal,l,Len);
       'C' : s := iReadString('',inCapital,chNormal,l,Len);
       'E' : s := iReadString('',inWeird,chNormal,l,Len);
       'W' : s := iReadString('',inWarped,chNormal,l,Len);
       'I' : s := iReadString('',inCool,chNormal,l,Len);
     end;
     'B' : case cs[2] of
       'D' : s := iReadDate('');
     end;
     'P' : case cs[2] of
       'N' : s := iReadPhone('');
     end;
     'N' : case cs[2] of
       'M' : s := iReadString('',inNormal,chNumeric,l,Len);
     end;
     'F' : case cs[2] of
       'N' : s := iReadString('',inUpper,chFilename,l,Len);
     end;
   end;
   BlockWrite(inf,s,Length(s)+1);
   Inc(ins);
end;

procedure ifPutString(cs : String);
var s : String; l : Byte;
begin
   if ins >= mxs then Exit;
   if not (cs[1] in ['S','B','P','N','F',#0]) then Exit;
   BlockRead(inf,l,1);
   s[0] := chr(l);
   BlockRead(inf,s[1],l);
   oCWrite(s);
   Inc(ins);
end;

function ifDo(var i : tInfoformRec; var Idx : tInfoIdxRec) : Boolean;
begin
   FillChar(idx,SizeOf(idx),0);
   ifDo := False;
   Seek(inf,FileSize(inf));
   ins := 0;
   idx.Pos := FilePos(inf);
   idx.Size := 0;
   if (not sfShowTextFile(i.Filename,ftInfoform)) or (HangUp) then Exit;
   if ins = 0 then Exit;
   ifDo := True;
   idx.Size := ins;
end;

function ifShowForm(num, un : Word; nuvi : Boolean) : Boolean;
var idx : tInfoIdxRec; f : file of tInfoFormRec; i : tInfoFormRec;
begin
   ifShowForm := False;
   if num = 0 then Exit;
   Assign(f,Cfg^.pathData+fileInfoform);
   {$I-}
   Reset(f);
   {$I+}
   if ioResult <> 0 then Exit;
   if FileSize(f) < num then
   begin
      Close(f);
      Exit;
   end;
   Seek(f,num-1);
   Read(f,i);
   Close(f);
   if nuvi and (not i.nuv) then Exit;
   Assign(inf,Cfg^.pathData+fileInfoPre+z3(num));
   {$I-}
   Reset(inf,1);
   {$I+}
   if ioResult <> 0 then Exit;
   Seek(inf,un*6-6);
   BlockRead(inf,idx,6);
   if idx.Size = 0 then
   begin
      Close(inf);
      Exit;
   end;
   ins := 0;
   mxs := idx.Size;
   Seek(inf,idx.Pos);
   if sfShowTextFile(i.Filename,ftInfoDisp) then
   begin
      iReadKey;
      ifShowForm := True;
   end;
   Close(inf);
end;

procedure ifInfoforms(quit : Boolean);
var i : tInfoFormRec; f : file of tInfoformRec; z : Byte;
    idx : tInfoIdxRec; Ans, Ac : Boolean; s, c : String; x : Word;
begin
   Assign(f,Cfg^.pathData+fileInfoform);
   {$I-}
   Reset(f);
   {$I+}
   if ioResult <> 0 then Exit;
   if FileSize(f) = 0 then
   begin
      Close(f);
      Exit;
   end;
   numInfo := FileSize(f);
   z := 0;
   Ac := False;
   while not Eof(f) do
   begin
      Read(f,i);
      Inc(z);
      if acsOk(i.Acs) then ac := True;
      if i.Mand then
      begin
         Assign(inf,Cfg^.pathData+fileInfoPre+z3(z));
         {$I-}
         Reset(inf,1);
         {$I+}
         if ioResult = 0 then
         begin
            Seek(inf,User^.Number*6-6);
            BlockRead(inf,idx,6);
            if (acsOk(i.Acs)) and (idx.Size = 0) then
            begin
               if (ifDo(i,idx)) and (ins > 0) then
               begin
                  Seek(inf,User^.Number*6-6);
                  BlockWrite(inf,idx,6);
               end;
            end;
            Close(inf);
         end;
      end;
   end;
   if (quit) or (not Ac) then
   begin
      Close(f);
      Exit;
   end else Seek(f,0);

   PausePos := 1;
   PauseAbort := False;
   Ans := (sfGetTextFile(txInfoTop,ftTopLine)  <> '') and
          (sfGetTextFile(txInfoMid,ftInfoList) <> '') and
          (sfGetTextFile(txInfoBot,ftNormal)   <> '');
   if Ans then
   begin
      sfShowTextFile(txInfoTop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txInfoMid);
   end else
   begin
      oClrScr;
      oDnLn(1);
      oSetCol(colInfo);
      oCWriteLn(' '+Resize('Num',4)+
                ' '+Resize('Description',20)+
                ' '+Resize('Type',13)+
                ' '+'Complete');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',50));
      oUpPause(3);
      oSetCol(colText);
   end;
   z := 0;
   while (not HangUp) and (not Eof(f)) and (not PauseAbort) do
   begin
      Read(f,i);
      Inc(z);
      s := '';
      if i.Mand then s := 'Mandatory/';
      if i.Nuv then s := s+'NUV';
      if s = '' then s := 'Normal' else
      if s[Length(s)] = '/' then Dec(s[0]);

      Assign(inf,Cfg^.pathData+fileInfoPre+z3(z));
      {$I-}
      Reset(inf,1);
      {$I+}
      if ioResult = 0 then
      begin
         Seek(inf,User^.Number*6-6);
         BlockRead(inf,idx,6);
         if idx.Size = 0 then c := 'No' else
                              c := 'Yes';
         Close(inf);
      end else c := '---';

      if not acsOk(i.Acs) then begin { nothing .. } end else
      if Ans then
      begin
         sfStr[1] := St(z);
         sfStr[2] := i.Desc;
         sfStr[3] := s;
         sfStr[4] := c;
         sfShowRepeat(ftInfoList);
         if oWhereX <> 1 then oDnLn(1);
         oUpPause(1);
      end else
      begin
         oCWriteLn(' '+Resize(St(z),4)+
                   ' '+Resize(i.Desc,20)+
                   ' '+Resize(s,13)+
                   ' '+c);
         oUpPause(1);
      end;
   end;
   sfKillRepeat;
   Close(f);
   if Ans then
   begin
      sfShowTextFile(txInfoBot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',50));
      oUpPause(1);
   end;
   PausePos := 0;
   oStr(strCode(mStr(strInfoAskWhich),1,St(numInfo)));
   s := iReadString('',inNormal,chNumeric,'',3);
   x := strToInt(s);
   if (x < 1) or (x > numInfo) or (s = '') then Exit;

   Reset(f);
   Seek(f,x-1);
   Read(f,i);
   Close(f);

   if not acsOk(i.Acs) then Exit;

   Assign(inf,Cfg^.pathData+fileInfoPre+z3(z));
   {$I-}
   Reset(inf,1);
   {$I+}
   if ioResult <> 0 then Exit;
   Seek(inf,User^.Number*6-6);
   BlockRead(inf,idx,6);
   if idx.Size <> 0 then
   begin
      oString(strInfoAskReplace);
      if not iYesNo(False) then
      begin
         Close(inf);
         Exit;
      end;
   end;
   if (ifDo(i,idx)) and (ins > 0) then
   begin
      Seek(inf,User^.Number*6-6);
      BlockWrite(inf,idx,6);
   end;
   Close(inf);
end;

end.