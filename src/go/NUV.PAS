{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Nuv;

interface

procedure nuvReset(rn : Word);
procedure nuvVote(show : Boolean);

implementation

uses
   Global, Misc, Strings, Output, Input, Showfile, Infoform, Levels, Users,
   Files;

procedure nuvVote(show : Boolean);
var fu, fi : file; found, done, vote, some, any : Boolean; u : tUserRec; n, un, vn : Word;
    cmt, z : String; cmts : array[1..12] of String[85]; nc, b : Byte; c : Char;
 procedure vIndex;
 var ini : String[2];
 begin
    BlockRead(fi,un,2);
    BlockRead(fi,vn,2);
    ini[0] := Chr(2);
    BlockRead(fi,ini[1],2);
    BlockRead(fi,cmt[0],1);
    if Ord(cmt[0]) > 0 then
    begin
       BlockRead(fi,cmt[1],Ord(cmt[0]));
       if cfg^.nuvInitials then cmt := ini+' - '+cmt;
    end;
 end;
begin
   if not acsOk(cfg^.nuvVoteAccess) then Exit;
   if not cfg^.nuvValidation then
   begin
      if not show then Exit;
      oDnLn(1);
      oStringLn(strNuvIsDisabled);
      oDnLn(1);
      Exit;
   end;
   oDnLn(1);
   oString(strNuvScanning);
   Assign(fu,cfg^.pathData+fileUsers);
   {$I-}
   Reset(fu,1);
   {$I+}
   if ioResult <> 0 then Exit;
   some := False;
   Assign(fi,cfg^.pathData+fileNuv);
   {$I-}
   Reset(fi,1);
   {$I+}
   if ioResult <> 0 then
   begin
      {$I-}
      Rewrite(fi,1);
      {$I+}
      if ioResult <> 0 then
      begin
         Close(fu);
         Exit;
      end;
   end;
   n := 0;
   while (not Hangup) and (not Eof(fu)) do
   begin
      BlockRead(fu,u,SizeOf(u));
      Inc(n);
      if (not (acDeleted in u.acFlag)) and (mUserAcs(cfg^.nuvAccess,u)) then
      begin
         Seek(fi,0);
         found := False;
         while (not (found or Eof(fi))) do
         begin
            vIndex;
            found := (vn = u.Number) and (un = User^.Number);
         end;
         if not found then
         begin
            Seek(fi,0);
            some := True;
            nc := 0;
            while (nc < 12) and (not Eof(fi)) do
            begin
               vIndex;
               if vn = n then
               begin
                  Inc(nc);
                  cmts[nc] := cmt;
               end;
            end;
            oDnLn(1);

            vote := False;
            done := False;
            repeat
               sfStr[1] := u.Username;
               sfStr[2] := st(u.voteYes);
               sfStr[3] := st(u.voteNo);
               sfStr[4] := st(cfg^.nuvVotesYes);
               sfStr[5] := st(cfg^.nuvVotesNo);
               for b := 1 to 12 do if b <= nc then sfStr[5+b] := cmts[b] else sfStr[5+b] := '';
               if not sfShowTextFile(txNuv,ftNuv) then
               begin
                  oDnLn(1);
                  oStrCtrLn('|U1New user|U2: |U3'+u.Username+'|U2, |U1yes votes|U2: |U3'+st(u.voteYes)+
                                    '|U2, |U1no votes|U2: |U3'+st(u.voteNo));
                  oDnLn(1);
                  if nc > 0 then
                  begin
                     oStrCtrLn('|U1Comments|U2:');
                     for b := 1 to nc do oStrCtrLn(' |U3'+cmts[b]);
                     oDnLn(1);
                  end;
               end;
               oStr(strCode(mStr(strNuvVote),1,u.Username));
               repeat
                  c := upCase(iReadKey);
               until (Hangup) or (c in ['Y','N','A','I']);
               if Hangup then c := 'A';
               case c of
                  'I' : begin
                           oWriteLn('Info');
                           any := False;
                           for b := 1 to numInfo do if ifShowForm(b,n,True) then any := True;
                           if not any then
                           begin
                              oStringLn(strNuvNoInfoforms);
                              oDnLn(1);
                              oPromptKey;
                           end;
                        end;
                  'Y' : begin
                           oWriteLn('Yes');
                           Inc(u.voteYes);
                           if u.voteYes >= cfg^.nuvVotesYes then
                           begin
                              oStrLn(strCode(mStr(strNuvValidated),1,u.Username));
                              levelChange(u,cfg^.nuvUserLevel);
                              done := True;
                           end;
                           userSave(u);
                           vote := True;
                        end;
                  'N' : begin
                           oWriteLn('No');
                           Inc(u.voteNo);
                           if u.voteNo >= cfg^.nuvVotesNo then
                           begin
                              oStrLn(strCode(mStr(strNuvDeleted),1,u.Username));
                              u.acFlag := u.acFlag+[acDeleted];
                              done := True;
                           end;
                           userSave(u);
                           vote := True;
                        end;
                  'A' : begin
                           oWriteLn('Abstain');
                           vote := True;
                        end;
               end;
            until Hangup or vote;
            if not Hangup then
            begin
               cmt := '';
               if (nc <= 12) and (not done) and (c <> 'A') then
               begin
                  oString(strNuvAskComment);
                  if iYesNo(False) then
                  begin
                     oString(strNuvComment);
                     cmt := iReadString('',inNormal,chNormal,'',80);
                  end;
               end;
               Seek(fi,fileSize(fi));
               BlockWrite(fi,User^.Number,2);
               BlockWrite(fi,n,2);
               z := mInitials(User^.Username);
               BlockWrite(fi,z[1],2);
               BlockWrite(fi,cmt[0],1);
               if cmt[0] <> #0 then BlockWrite(fi,cmt[1],Ord(cmt[0]));
            end;
         end;
      end;
   end;
   Close(fu);
   Close(fi);
   if not some then
   begin
      oDnLn(1);
      oStringLn(strNuvNone);
   end;
   oDnLn(1);
end;

procedure nuvReset(rn : Word);
var fi, fo : file; un, vn : Word; tp, tf, s, ini : String;
begin
   Assign(fi,Cfg^.pathData+fileNuv);
   {$I-}
   Reset(fi,1);
   {$I+}
   if ioResult <> 0 then Exit;
   tf := 'NUVTEMP.DAT';
   tp := fTempPath('F');
   Assign(fo,tp+tf);
   {$I-}
   Rewrite(fo,1);
   {$I+}
   if ioResult <> 0 then begin Close(fi); Exit; end;

   while not Eof(fi) do
   begin
      BlockRead(fi,un,2);
      BlockRead(fi,vn,2);
      BlockRead(fi,ini,2);
      BlockRead(fi,s[0],1);
      if Ord(s[0]) > 0 then BlockRead(fi,s[1],Ord(s[0]));
      if (un <> rn) and (vn <> rn) then
      begin
         BlockWrite(fo,un,2);
         BlockWrite(fo,vn,2);
         BlockWrite(fo,ini,2);
         BlockWrite(fo,s,1+Ord(s[0]));
      end;
   end;

   {$I-}
   Close(fi);
   Close(fo);

   Erase(fi);
   Rename(fo,Cfg^.pathData+fileNuv);
   {$I+}
end;

end.

