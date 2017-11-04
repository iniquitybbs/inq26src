{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,N-,E+}
unit Nodes;

interface

{$IFDEF OS2}
uses
   Use32;
{$ENDIF}

const
   nd_msg      = 1;
   nd_chat     = 2;
   nd_chatjoin = 3;
   nd_chatpart = 4;

procedure nodeBroadcast;
procedure nodeChat;
procedure nodeDone;
procedure nodeList;
procedure nodeMsg;
procedure nodeProcess;
function  nodeRead(t : Byte; var f, n : byte; var s : String) : Boolean;
procedure nodeReset(ff : boolean);
procedure nodeUpdate(stat : String);
function  nodeUser(handle : String) : Word;
procedure nodeWrite(n, t : Byte; s : String);

implementation

uses
   Global, Output, Showfile, Misc, StrProc, DateTime, Files, Logs, Comm,
   Input;

var
   nodeinchat : boolean;

function nodeFn(n : Byte) : string;
begin
   nodeFn := Cfg^.pathData+strReplace(fileNodeData,'%%%',z3(n));
end;

procedure nodeReset(ff : boolean);
var ni : tNodeRec;
begin
   if not MultiNode then Exit;
   if ff then
   begin
      if not fopen(nodedf,1,ffnew+ffwait+fflock) then
      begin
         logWrite('xError initializing node '+st(node)+' data file');
         logWrite('xIsolated node '+st(node)+' ...');
         multinode := false;
         Exit;
      end;
      Close(nodedf);
   end;

   Fillchar(nodeptr^,sizeof(nodeptr^),0);
   Fillchar(nodein^,maxNodeBuf,0);
   Fillchar(nodeout^,maxNodeBuf,0);
   nodeinmore := 0;
   nodeoutmore := 0;

   nodeinfo^.data := 0;
   nodeUpdate('');

   Seek(nodefile,0);
   while not eof(nodefile) do
   begin
      BlockRead(nodefile,ni,1);
      if ni.nodenum <> 0 then nodeptr^[ni.nodenum] := ni.data;
   end;

   nodeready := True;
   nodeinchat := False;
end;

procedure nodeInit;
var xf : string; ni : tNodeRec;
begin
   xf := nodeFn(node);
   Assign(nodedf,xf);
   if not MultiNode then Exit;
   if not fopen(nodedf,1,ffnew+ffwait+fflock) then
   begin
      logWrite('xError initializing '+xf);
      logWrite('xMultinode not possible, node '+st(node)+' loaded in isolation');
      multinode := false;
      Exit;
   end;
   Close(nodedf);

   Assign(nodeFile,Cfg^.pathData+fileNode);
   if not fopen(nodeFile,SizeOf(tNodeRec),fffree+ffwait) then
      if not fopen(nodeFile,SizeOf(tNodeRec),ffnew+fffree+ffwait) then
   begin
      logWrite('xCould not access '+Cfg^.pathdata+filenode);
      logWrite('xMultinode not possible, node '+st(node)+' loaded in isolation');
      multinode := False;
      Exit;
   end;
   FillChar(nodeInfo^,SizeOf(nodeInfo^),0);
   if FileSize(nodeFile) < Node then
   begin
      Seek(nodeFile,FileSize(nodeFile));
      while FileSize(nodeFile) < Node do BlockWrite(nodeFile,nodeInfo^,1);
   end;

   New(nodeptr);
   New(nodein);
   New(nodeout);

   nodeReset(false);
end; { leaves nodeFile open ... }

procedure nodeUpdate(stat : String);
begin
   if not MultiNode then Exit;
   with nodeInfo^ do
   begin
      NodeNum  := Node;
      if UserOn then
      begin
         Username := User^.Username;
         Realname := User^.Realname;
         Usernum  := User^.Number;
         Sex      := User^.Sex;
         Baudrate := User^.Baudrate;
         Login    := TimeOn;
         Status   := stat;
         Bdate    := User^.Birthdate;
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
      end;
   end;
   Seek(nodeFile,Node-1);
   BlockWrite(nodeFile,nodeInfo^,1);
end;

procedure nodeDone;
begin
   if not MultiNode then Exit;
   FillChar(nodeInfo^,SizeOf(tNodeRec),0);
   {$I-}
   Seek(nodeFile,Node-1);
   BlockWrite(nodeFile,nodeInfo^,1);
   Close(nodeFile);
   {$I+}
   if not ferase(nodedf,ffwait) then
      logWrite('xError erasing node data file upon termination');
   Dispose(nodeptr);
   Dispose(nodein);
   Dispose(nodeout);
   nodeinmore := 0;
   nodeoutmore := 0;
end;

procedure nodeList;
var ni : tNodeRec; ti, ton : tDateTimeRec; Ans : boolean;
begin
   if not MultiNode then
   begin
      oStringLn(strNodeNotMulti);
      Exit;
   end;
   PausePos := 1;
   PauseAbort := False;
   Ans := (sfGetTextFile(txNodeTop,ftTopLine) <> '') and
          (sfGetTextFile(txNodeMid,ftNodeList) <> '') and
          (sfGetTextFile(txNodeBot,ftNormal) <> '');
   if Ans then
   begin
      sfShowTextFile(txNodeTop,ftTopLine);
      oUpPause(ansiRows-1);
      sfGotoPos(1);
      sfLoadRepeat(txNodeMid);
   end else
   begin
      oDnLn(1);
      oSetCol(colInfo);
      oWriteLn(' '+Resize('Node',4)+
               ' '+Resize('Username',16)+
               ' '+Resize('Activity',39)+
               ' '+Resize('Baud',6)+
               ' Time on');
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(3);
      oSetCol(colText);
   end;
   Seek(nodefile,0);
   dtGetDateTime(ti);
   while (not HangUp) and (not Eof(nodeFile)) and (not PauseAbort) do
   begin
      BlockRead(nodeFile,ni,1);
      dtTimeDiff(ton,ni.Login,ti);
      sfStr[1] := st(ni.NodeNum);
      sfStr[2] := ni.Username;
      sfStr[3] := ni.Realname;
      if (ni.Realname = '---') and (ni.Username = '---') then
      begin
         sfStr[4] := '--';
         sfStr[5] := '---';
         sfStr[6] := '--:--';
         sfStr[9] := '--';
      end else
      begin
         sfStr[4] := st(ni.Usernum);
         sfStr[5] := mBaudString(ni.Baudrate);
         sfStr[6] := dtTimeRecLen(ton);
         sfStr[9] := st(dtAge(ni.Bdate));
      end;
      sfStr[7] := ni.Status;
      sfStr[8] := ni.Sex;
      if ni.NodeNum = 0 then begin { do nothing } end else
      if Ans then
      begin
         sfShowRepeat(ftNodeList);
         if oWhereX <> 1 then oDnLn(1);
         oUpPause(1);
      end else
      begin
         dtTimeDiff(ton,ni.Login,ti);
         oWriteLn(' '+Resize(sfStr[1],4)+
                  ' '+Resize(sfStr[2],16)+
                  ' '+Resize(sfStr[7],39)+
                  ' '+Resize(sfStr[5],6)+
                  ' '+sfStr[6]);
         oUpPause(1);
      end;
   end;
   sfKillRepeat;
   if Ans then
   begin
      sfShowTextFile(txNodeBot,ftNormal);
      oUpPause(ansiRows);
   end else
   begin
      oSetCol(colBorder);
      oWriteLn(sRepeat('Ä',79));
      oUpPause(1);
   end;
   PausePos := 0;
end;

function nodeUser(handle : String) : Word;
var ni : tNodeRec;
begin
   handle := upstr(handle);
   if not multinode then
   begin
      if handle = upstr(user^.username) then nodeUser := node else nodeUser := 0;
      Exit;
   end;
   Seek(nodefile,0);
   while (not Eof(nodefile)) and (upstr(ni.Username) <> handle) do BlockRead(nodefile,ni,1);
   if upstr(ni.Username) = handle then nodeUser := filePos(nodefile) else nodeUser := 0;
end;

procedure nodeProcess;
var ni : tNodeRec; x : Byte; nf : file; r : Integer;
begin
   if not multinode then Exit;
   if nodeoutmore > 0 then
   begin
      if not fopen(nodedf,1,ffwait+fflock) then
         logWrite('xError opening node data file') else
      begin
         Seek(nodedf,filesize(nodedf));
         BlockWrite(nodedf,nodeout^,nodeoutmore);
         nodeinfo^.data := filepos(nodedf);
         Close(nodedf);
         nodeptr^[node] := nodeinfo^.data;
         nodeoutmore := 0;
         Seek(nodefile,node-1);
         BlockWrite(nodefile,nodeinfo^,1);
      end;
   end;

   if nodeinmore > 0 then Exit;
   {$I-}
   Seek(nodefile,0);
   {$I+}
   if ioresult = 0 then
   while not eof(nodefile) do
   begin
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
               Seek(nf,nodeptr^[x]);
               BlockRead(nf,nodein^,maxNodeBuf,r);
               nodeptr^[x] := filepos(nf);
               Close(nf);
               if nodeready then nodeinmore := r;
            end;
         end;
      end;
   end;
end;

procedure nodeWrite(n, t : Byte; s : String);
var l : Word;
begin
   if (not nodeready) or (not multinode) then Exit;
   l := byte(s[0])+4;
   if l+nodeoutmore > maxNodeBuf then
   repeat
      cCheckUser;
   until nodeoutmore = 0;
   nodeout^[nodeoutmore+1] := node;
   nodeout^[nodeoutmore+2] := n;
   nodeout^[nodeoutmore+3] := t;
   Move(s,nodeout^[nodeoutmore+4],byte(s[0])+1);
   Inc(nodeoutmore,l);
end;

function nodeGet(n : byte; var ni : tNodeRec) : boolean;
begin
   fillchar(ni,sizeof(ni),0);
   nodeGet := false;
   if filesize(nodefile) < n then exit;
   Seek(nodefile,n-1);
   Blockread(nodefile,ni,1);
   nodeGet := ni.nodenum = n;
end;

function nodeRead(t : Byte; var f, n : byte; var s : String) : Boolean;
var tf, len : Byte; keep : boolean; si : Word; ni : tNodeRec;
begin
   nodeRead := False;
   if (not nodeready) or (nodeinmore = 0) then Exit;
   f := nodein^[1];
   n := nodein^[2];
   tf := nodein^[3];
   len := nodein^[4];
   Move(nodein^[5],s[1],len);
   s[0] := char(len);
   si := len+4;
   keep := false;
   if tf = t then
   begin
      nodeRead := True;
   end else
   if tf = nd_msg then
   begin
      if nodeGet(f,ni) then
      begin
         oDnLn(1);
         if n = 0 then oStr(strcode(strcode(mstr(strNodeBCreceived),1,ni.username),2,st(ni.nodenum))) else
                       oStr(strcode(strcode(mstr(strNodeMsgReceived),1,ni.username),2,st(ni.nodenum)));
         oStrCtrLn(s);
      end;
      keep := false;
   end else
   if (nodeinchat) and (tf in [2..4]) then keep := true;
   if not keep then
   begin
      Move(nodein^[si+1],nodein^[1],maxNodeBuf-si-1);
      Dec(nodeinmore,si);
   end;
end;

procedure nodeChat;
var done, ans : boolean; ix, iy, il, im : byte; is : string; ch : char;
    idt, idb, idp, idm : byte; ids : array[1..25] of string[255]; ni : tNodeRec;
    nf, nt : byte;
 procedure ncUpdate;
 var xx : byte;
 begin
    for xx := idt to idb do
    begin
       oGotoXY(1,xx);
       oCwrite(ids[xx-idt+1]);
       oClreol;
    end;
 end;
 procedure ncOut(s : string);
 var xx, sl : byte;
 begin
    s := cleanup(strSquish(s,79));
    sl := idb-idt+1;
    if s = '' then Exit;
    if idp > sl then
    begin
       Move(ids[idm+1],ids[1],256*(sl-idm));
       for xx := sl-idm+1 to sl do ids[xx] := '';
{      Fillchar(ids[idm+1],256*(sl-idm),0);}
(*       for xx := sl downto idm do if xx-idm >= 1 then
       begin
          ids[xx-idm] := ids[xx];
          ids[xx] := '';
       end else ids[xx] := '';
{      for xx := idm+idm+1 to sl do ids[xx] := '';} *)
       ncUpdate;
       idp := sl-idm+1;
    end;
    oGotoXY(1,idt+idp-1);
    ids[idp] := s;
    oCwrite(ids[idp]);
    Inc(idp);
 end;
 procedure ncOutWrap(s : string);
 var p : byte; ns : string;
 begin
    ns := '';
    if s = '' then Exit;
    while s[1] = ' ' do delete(s,1,1);
    if s = '' then Exit;
    while s <> '' do
    begin
       p := pos(' ',s);
       if p = 0 then p := length(nocolor(s));
       if p > 79 then p := 79;
       if length(nocolor(ns))+p > 79 then
       begin
          ncOut(ns);
          ns := '';
       end;
       ns := ns+copy(s,1,p);
       delete(s,1,p);
    end;
    if ns <> '' then ncOut(ns);
 end;
begin
   if not MultiNode then
   begin
      oStringLn(strNodeNotMulti);
      Exit;
   end;
   nodeUpdate('Multinode chat');
   nodeinchat := True;

   im := 255;
   is := '';

   sfstr[1] := st(node);
   sfstr[2] := user^.username;
   ans := sfShowTextfile(txNodeChat,ftNodeChat);
   if ans then
   begin
      idt := sfpos[5].y;
      idb := sfpos[6].y;
      ix := sfpos[3].x;
      il := sfpos[4].x-ix+1;
      iy := sfpos[3].y;
   end else
   begin
      ix := 1;
      iy := 24;
      il := 79;
      idt := 1;
      idb := 22;
      oClrscr;
      oGotoXY(1,23);
      oWrite(sRepeat('Ä',79));
   end;

   idp := 1;
   idm := (idb-idt+1) div 2 + 1;

   fillchar(ids,sizeof(ids),0);

   nodeWrite(0,nd_chatjoin,user^.username);
   ncOutWrap(strCode(mStr(strMNCenterchat),1,user^.username));

   done := false;
   iESinit('',ix,iy,il,im);
   repeat
      while (not hangup) and (iKeypressed) do
      begin
         if ans then oSetColRec(sfpos[4].c) else oSetCol(colInfo);
         ignoreLF:=false;
         is := iESinput(ch);
         if ch = #13 then
         begin
            if is <> '' then
            begin
               if is[1] = '/' then
               begin
                  delete(is,1,1);
                  is := strLow(is);
                  if (is = 'quit') or (is = 'exit') or (is = 'bye') then done := true;
               end else
               begin
                  ncOutWrap(strCode(strCode(mStr(strMNCyouspeak),1,user^.username),2,is));
                  nodeWrite(0,nd_chat,is);
               end;
            end;
            iESclear;
            iESinit('',ix,iy,il,im);
         end else
         if ch = #27 then done := true;
      end;
      cCheckUser;
      if nodeRead(nd_chat,nf,nt,is) then
      begin
         if nt in [0,node] then
         begin
            nodeGet(nf,ni);
            ncOutWrap(strCode(strCode(mStr(strMNCtheyspeak),1,ni.username),2,is));
         end;
      end else
      if nodeRead(nd_chatjoin,nf,nt,is) then
         ncOutWrap(strCode(mStr(strMNCenterchat),1,is)) else
      if nodeRead(nd_chatpart,nf,nt,is) then
         ncOutWrap(strCode(mStr(strMNCquitchat),1,is));
   until hangup or done;
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';

   nodeWrite(0,nd_chatpart,user^.username);
   ncOutWrap(strCode(mStr(strMNCquitchat),1,user^.username));

   if ans then sfgotopos(maxpos);

   nodeinchat := False;
end;

procedure nodeMsg;
var i : string; n : word; ni : tNodeRec;
begin
   if not MultiNode then
   begin
      oStringLn(strNodeNotMulti);
      Exit;
   end;
   repeat
      oString(strNodeAskNode);
      i := iReadString('',inNormal,chNormal,'',36);
      if i = '?' then nodeList;
   until hangup or (i <> '?');
   n := strtoint(i);
   if n = 0 then
   begin
      n := nodeUser(i);
      if (n = 0) or (not nodeGet(n,ni)) then Exit;
   end else
   if not nodeGet(n,ni) then exit;
   if (ni.nodenum = node) or (ni.usernum = 0) then exit;
   oStrLn(strcode(strcode(strcode(mstr(strNodeUserOn),1,st(ni.nodenum)),2,ni.username),3,stc(ni.baudrate)));
   oString(strNodeMsgAskText);
   i := iReadString('',inNormal,chNormal,'',255);
   if i = '' then exit;
   nodeWrite(n,nd_msg,i);
   oStrLn(strcode(strcode(mstr(strNodeMsgSent),1,ni.username),2,st(ni.nodenum)));
end;

procedure nodeBroadcast;
var i : string; n : word;
begin
   if not MultiNode then
   begin
      oStringLn(strNodeNotMulti);
      Exit;
   end;
   oString(strNodeBCaskText);
   i := iReadString('',inNormal,chNormal,'',255);
   if i = '' then exit;
   nodeWrite(0,nd_msg,i);
   oStringLn(strNodeBCsent);
end;

end.
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
      end else
      begin
         Username := '---';
         Realname := '---';
         Usernum  := 0;
         Sex      := '-';
         Baudrate := 0;
         Login    := TimeOn;
         Status   := 'Waiting for call';
         Bdate    := '01/01/01';
