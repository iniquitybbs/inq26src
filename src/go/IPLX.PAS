unit IPLX; { Iniquity Programming Language - Code Parser }

interface

procedure iplExecute(fn, par : String);

implementation

uses
   Crt, Global, Strings, StatBar, Logs, Files, Output, Input, Misc, Users,
   ShowFile;

{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
   case error of
     xrrUeEndOfFile     : s := 'Unexpected end-of-file';
     xrrFileNotFound    : s := 'File not found, "'+errStr+'"';
     xrrInvalidFile     : s := 'File is not executable, "'+errStr+'"';
     xrrVerMismatch     : s := 'File version mismatch (script: '+errStr+', parser: '+cVersion+')';
     xrrUnknownOp       : s := 'Unknown script command, "'+errStr+'"';
     xrrTooManyVars     : s := 'Too many variables initialized at once (max '+st(maxVar)+')';
     xrrMultiInit       : s := 'Variable initialized recursively';
     xrrDivisionByZero  : s := 'Division by zero';
     xrrMathematical    : s := 'Mathematical parsing error';
                     else s := '';
   end;
   xErrorMsg := s;
end;

function xExecute(fn : String) : LongInt;

var
   f      : file;
   xVars  : Word;
   xVar   : tVars;
   xpos   : LongInt;
   xid    : String[idVersion];
   xver   : String[idLength-idVersion];
   c      : Char;
   w      : Word;

 function xProcExec(dp : Pointer) : tIqVar; forward;
 procedure xParse(svar : Word); forward;
 function xEvalNumber : Real; forward;

 procedure xInit;
 begin
    error := 0;
    errStr := '';
    xVars := 0;
    xpos := 0;
    FillChar(xVar,SizeOf(xVar),0);
 end;

 procedure xError(err : Byte; par : String);
 begin
    if error > 0 then Exit;
    error := err;
    xExecute := xpos;
    errStr := par;
 end;

 procedure xToPos(p : LongInt);
 begin
    Seek(f,p+idLength);
    xPos := p+1;
 end;

 function xFilePos : LongInt;
 begin
    xFilePos := filePos(f)-idLength;
 end;

 procedure xGetChar;
 begin
    if (not Eof(f)) and (error = 0) then
    begin
       BlockRead(f,c,1);
       Inc(xpos);
    end else
    begin
       c := #0;
       xError(xrrUeEndOfFile,'');
    end;
{   sbInfo('(IPL) Executing "'+fn+'" ... [pos '+st(xpos)+']',True);}
 end;

 procedure xGetWord;
 begin
    if (not Eof(f)) and (error = 0) then
    begin
       BlockRead(f,w,2);
       Inc(xpos,2);
    end else
    begin
       w := 0;
       xError(xrrUeEndOfFile,'');
    end;
 end;

 procedure xGoBack;
 begin
    if (xpos = 0) or (error <> 0) then Exit;
    xToPos(xFilePos-1);
 end;

 function xFindVar(i : Word) : Word;
 var x, z : Byte;
 begin
    xFindVar := 0;
    if xVars = 0 then Exit;
    z := 0;
    x := 1;
    repeat
       if xVar[x]^.id = i then z := x;
       Inc(x);
    until (x > xVars) or (z > 0);
    xFindVar := z;
 end;

 function xDataPtr(vn : Word; var a : tArray) : Pointer;
 begin
    with xVar[vn]^ do
    begin
       if arr = 0 then xDataPtr := data else
       begin
          if arr = 1 then xDataPtr := @data^[size*(a[1]-1)+1] else
          if arr = 2 then xDataPtr := @data^[size*((a[1]-1)*arrdim[2]+a[2])] else
          if arr = 3 then xDataPtr := @data^[size*((a[1]-1)*(arrdim[2]*arrdim[3])+(a[2]-1)*arrdim[3]+a[3])];
       end;
    end;
 end;

 procedure xCheckArray(vn : Word; var a : tArray);
 var z : Byte;
 begin
    for z := 1 to maxArray do a[z] := 1;
    if xVar[vn]^.arr = 0 then Exit;
    for z := 1 to xVar[vn]^.arr do a[z] := Round(xEvalNumber);
 end;

 function xVarNumReal(vn : Word; var a : tArray) : Real;
 begin
    case xVar[vn]^.vtype of
       vByte   : xVarNumReal := Byte(xDataPtr(vn,a)^);
       vShort  : xVarNumReal := ShortInt(xDataPtr(vn,a)^);
       vWord   : xVarNumReal := Word(xDataPtr(vn,a)^);
       vInt    : xVarNumReal := Integer(xDataPtr(vn,a)^);
       vLong   : xVarNumReal := LongInt(xDataPtr(vn,a)^);
       vReal   : xVarNumReal := Real(xDataPtr(vn,a)^);
    end;
 end;

 function xNumReal(var num; t : tIqVar) : Real;
 begin
    case t of
       vByte   : xNumReal := Byte(num);
       vShort  : xNumReal := ShortInt(num);
       vWord   : xNumReal := Word(num);
       vInt    : xNumReal := Integer(num);
       vLong   : xNumReal := LongInt(num);
       vReal   : xNumReal := Real(num);
    end;
 end;

 function xEvalNumber : Real;
 var cc : Char; vn : Word; me : Boolean; pr : Real;

  procedure ParseNext;
  begin
     xGetChar;
     if c = iqo[oCloseNum] then cc := ^M else cc := c;
  end;

  function add_subt : Real;
  var E : Real; Opr : Char;

   function mult_DIV : Real;
   var S : Real; Opr : Char;

    function Power : Real;
    var T : Real;

     function SignedOp : Real;

      function UnsignedOp : Real;
{     type stdFunc = (fabs, fsqrt, fsqr, fsin, fcos, farctan, fln, flog, fexp, ffact);
           stdFuncList = array[stdFunc] of String[6];
      const StdFuncName : stdFuncList = ('ABS','SQRT','SQR','SIN','COS','ARCTAN','LN','LOG','EXP','FACT');}
      var E, L, Start : Integer; F : Real; {Sf : stdFunc;} ad : tArray;
          ns : String;

       function Fact(I : Integer) : Real;
       begin
          if I > 0 then Fact := I*Fact(I-1) else Fact := 1;
       end;

      begin
         if cc = iqo[oVariable] then
         begin
            xGetWord;
            vn := xFindVar(w);
            xCheckArray(vn,ad);
            F := xVarNumReal(vn,ad);
            ParseNext;
         end else
         if cc = iqo[oProcExec] then
         begin
            F := 0;
            F := xNumReal(F,xProcExec(@F));
            ParseNext;
         end else
         if cc in chDigit then
         begin
            ns := '';
            repeat ns := ns+cc; ParseNext; until not (cc in chDigit);
            if cc = '.' then repeat ns := ns+cc; ParseNext until not (cc in chDigit);
            if cc = 'E' then
            begin
               ns := ns+cc;
               ParseNext;
               repeat ns := ns+cc; ParseNext; until not (cc in chDigit);
            end;
            Val(ns,F,start);
            if start <> 0 then me := True;
         end else
         if cc = '(' then
         begin
            ParseNext;
            F := add_subt;
            if cc = ')' then ParseNext else me := True;
         end else
         begin
            me := True;
            f := 0;
         end;
         UnsignedOp := F;
      end;

     begin
        if cc = '-' then
        begin
           ParseNext;
           SignedOp := -UnsignedOp;
        end else SignedOp := UnsignedOp;
     end;

    begin
       T := SignedOp;
       while cc = '^' do
       begin
          ParseNext;
          if t <> 0 then t := Exp(Ln(abs(t))*SignedOp) else t := 0;
       end;
       Power:=t;
    end;

   begin
      s := Power;
      while cc in ['*','/'] do
      begin
         Opr := cc;
         ParseNext;
         case Opr of
           '*' : s := s*Power;
           '/' : begin pr := Power;
                       if pr = 0 then xError(xrrDivisionByZero,'') else s := s/pr;
                 end;
         end;
      end;
      mult_DIV := s;
   end;

  begin
     E := mult_DIV;
     while cc in ['+','-'] do
     begin
        Opr := cc;
        ParseNext;
        case Opr of
          '+' : e := e+mult_DIV;
          '-' : e := e-mult_DIV;
        end;
     end;
     add_subt := E;
  end;
 begin
    xGetChar; { open num }
{   while Pos(' ',Formula) > 0 do Delete(Formula,Pos(' ',Formula),1);}
{   if Formula[1] = '.' then Formula := '0'+Formula;}
{   if Formula[1] = '+' then Delete(Formula,1,1);}
{   for curPos := 1 to Ord(Formula[0]) do Formula[curPos] := UpCase(Formula[curPos]);}
    me := False;
    ParseNext;
    xEvalNumber := add_subt;
    if cc <> ^M then me := True;
    if me then xError(xrrMathematical,'');
 end;

 function xEvalString : String;
 var rn : Word; x : String; ps : Byte; ad : tArray;
  function esString : String;
  var z : String; ok : Boolean;
  begin
     z := '';
     esString := '';
     ok := False;
     xGetChar; { open " string }

     repeat
        xGetChar;
        if c = iqo[oCloseString] then
        begin
           xGetChar;
           if c = iqo[oCloseString] then z := z+c else
           begin
              xGoBack;
              ok := True;
           end;
        end else z := z+c;
     until (error <> 0) or (ok);
     if error <> 0 then Exit;

     esString := z;
  end;
 begin
    xGetChar; { check first char of string }
    x := '';
    if c = iqo[oOpenString] then
    begin
       xGoBack;
       x := esString;
    end else
    if c = iqo[oVariable] then
    begin
       xGetWord;
       rn := xFindVar(w);
       xCheckArray(rn,ad);
       x := String(xDataPtr(rn,ad)^);
    end else
    if c = iqo[oProcExec] then
    begin
       xProcExec(@x);
    end;
    if error <> 0 then Exit;
    xGetChar;
    if c = iqo[oStrCh] then
    begin
       ps := Round(xEvalNumber);
       x := x[ps];
       xGetChar;
    end;
    if c = iqo[oStrAdd] then x := x+xEvalString else xGoBack;
    xEvalString := x;
 end;

 function xEvalBool : Boolean;
 type tOp = (opNone,opEqual,opNotEqual,opGreater,opLess,opEqGreat,opEqLess);
 var ga, gb, final : Boolean; ta, tb : tIqVar; o : tOp; rn : Word;
     ab, bb, inot : Boolean; ar, br : Real; as, bs : String; ad : tArray;
 begin
    ta := vNone; tb := vNone;
    ga := False; gb := False;
    o := opNone; inot := False;

    { get the first identifier .. }
    repeat
       xGetChar;
       if c = iqo[oOpenBrack] then
       begin
          ab := xEvalBool;
          ta := vBool;
          xGetChar; { close bracket }
          ga := True;
       end else
       if c = iqo[oNot] then
       begin
          inot := not inot;
       end else
       if c = iqo[oTrue] then
       begin
          ab := True;
          ta := vBool;
          ga := True;
       end else
       if c = iqo[oFalse] then
       begin
          ab := False;
          ta := vBool;
          ga := True;
       end else
       if c = iqo[oVariable] then
       begin
          xGetWord; { variable id }
          rn := xFindVar(w);
          xCheckArray(rn,ad);
          ta := xVar[rn]^.vType;
          if ta = vBool then ab := ByteBool(xDataPtr(rn,ad)^) else
          if ta = vStr then as := String(xDataPtr(rn,ad)^) else
          if ta in vnums then ar := xVarNumReal(rn,ad);
          ga := True;
       end else
       if c = iqo[oProcExec] then
       begin
          ta := xProcExec(@as);
          if ta = vBool then ab := ByteBool(as[0]) else
{         if ta = vStr then as := String(xVar[rn]^.data^) else}
          if ta in vnums then Move(as,ar,6);
          ga := True;
       end else
       if c = iqo[oOpenNum] then
       begin
          xGoBack;
          ar := xEvalNumber;
          ta := vReal;
          ga := True;
       end else
       if c in ['#','"'] then
       begin
          xGoBack;
          as := xEvalString;
          ta := vStr;
          ga := True;
       end;
    until (error <> 0) or (ga);
    if error <> 0 then Exit;

    xGetChar; { get the operator .. }
    if c = iqo[oOpEqual] then o := opEqual else
    if c = iqo[oOpNotEqual] then o := opNotEqual else
    if c = iqo[oOpGreater] then o := opGreater else
    if c = iqo[oOpLess] then o := opLess else
    if c = iqo[oOpEqGreat] then o := opEqGreat else
    if c = iqo[oOpEqLess] then o := opEqLess else
    begin
       final := ab;
       xGoBack;
    end;

    if o <> opNone then
    begin

    { get the second identifier if necessary .. }
    repeat
       xGetChar;
       if c = iqo[oOpenBrack] then
       begin
          bb := xEvalBool;
          tb := vBool;
          xGetChar; { close bracket }
          gb := True;
       end else
       if c = iqo[oTrue] then
       begin
          bb := True;
          tb := vBool;
          gb := True;
       end else
       if c = iqo[oFalse] then
       begin
          bb := False;
          tb := vBool;
          gb := True;
       end else
       if c = iqo[oVariable] then
       begin
          xGetWord; { variable id }
          rn := xFindVar(w);
          xCheckArray(rn,ad);
          tb := xVar[rn]^.vType;
          if tb = vBool then bb := ByteBool(xDataPtr(rn,ad)^) else
          if tb = vStr then bs := String(xDataPtr(rn,ad)^) else
          if tb in vnums then br := xVarNumReal(rn,ad);
          gb := True;

       end else
       if c = iqo[oProcExec] then
       begin
          tb := xProcExec(@bs);
          if tb = vBool then bb := ByteBool(bs[0]) else
          if tb in vnums then Move(bs,br,6);
          gb := True;
       end else
       if c = iqo[oOpenNum] then
       begin
          xGoBack;
          br := xEvalNumber;
          tb := vReal;
          gb := True;
       end else
       if c in ['#','"'] then
       begin
          xGoBack;
          bs := xEvalString;
          tb := vStr;
          gb := True;
       end;
    until (error <> 0) or (gb);
    if error <> 0 then Exit;
    final := False;

    case o of
      opEqual    : if ta = vStr then  final := as = bs else
                   if ta = vBool then final := ab = bb else
                                      final := ar = br;
      opNotEqual : if ta = vStr then  final := as <> bs else
                   if ta = vBool then final := ab <> bb else
                                      final := ar <> br;
      opGreater  : if ta = vStr then  final := as > bs else
                   if ta = vBool then final := ab > bb else
                                      final := ar > br;
      opLess     : if ta = vStr then  final := as < bs else
                   if ta = vBool then final := ab < bb else
                                      final := ar < br;
      opEqGreat  : if ta = vStr then  final := as >= bs else
                   if ta = vBool then final := ab >= bb else
                                      final := ar >= br;
      opEqLess   : if ta = vStr  then final := as <= bs else
                   if ta = vBool then final := ab <= bb else
                                      final := ar <= br;
    end;

    end;

    if inot then final := not final;
    xGetChar;
    if c = iqo[oAnd] then final := xEvalBool and final else
    if c = iqo[oOr]  then final := xEvalBool or final else
           xGoBack;

    xEvalBool := final;
 end;

 procedure xSetString(vn : Word; var a : tArray; s : String);
 begin
    if Ord(s[0]) >= xVar[vn]^.size then s[0] := Chr(xVar[vn]^.size-1);
    Move(s,xDataPtr(vn,a)^,xVar[vn]^.size);
 end;

 procedure xSetVariable(vn : Word);
 var ad : tArray;
 begin
    xCheckArray(vn,ad);
    case xVar[vn]^.vtype of
       vStr    : xSetString(vn,ad,xEvalString);
       vByte   : Byte(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vShort  : ShortInt(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vWord   : Word(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vInt    : Integer(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vLong   : LongInt(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vReal   : Real(xDataPtr(vn,ad)^) := xEvalNumber;
       vBool   : ByteBool(xDataPtr(vn,ad)^) := xEvalBool;
    end;
 end;

 procedure xSetNumber(vn : Word; r : Real; var a : tArray);
 begin
    case xVar[vn]^.vtype of
       vByte   : Byte(xDataPtr(vn,a)^) := Round(r);
       vShort  : ShortInt(xDataPtr(vn,a)^) := Round(r);
       vWord   : Word(xDataPtr(vn,a)^) := Round(r);
       vInt    : Integer(xDataPtr(vn,a)^) := Round(r);
       vLong   : LongInt(xDataPtr(vn,a)^) := Round(r);
       vReal   : Real(xDataPtr(vn,a)^) := r;
    end;
 end;

 function xDataSize(vn : Word) : Word;
 var sz, z : Word;
 begin
    with xVar[vn]^ do
    begin
       sz := size;
       for z := 1 to arr do sz := sz*arrdim[z];
       xDataSize := sz;
    end;
 end;

 procedure xCreateVar;
 var t : tIqVar; ci, ni, fi, slen : Word; cn, ar : Byte; ard : tArray;
 begin
    xGetChar; { variable type }
    t := cVarType(c);
    xGetChar; { check for array/strlen }
    slen := 256;
    ar := 0;
    for cn := 1 to maxArray do ard[cn] := 1;
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
    if c = iqo[oStrLen] then
    begin
       slen := Round(xEvalNumber)+1;
       xGetChar; { now check for array }
    end;
    if c = iqo[oArrDef] then
    begin
       xGetWord;
       ar := w;
       for cn := 1 to ar do ard[cn] := Round(xEvalNumber);
    end; {  else xGoBack;  -- must be a normal string }
    xGetWord; { number of vars }
    ni := w;
    fi := xVars+1;
    for ci := 1 to ni do if error = 0 then
    begin
       if xVars >= maxVar then xError(xrrTooManyVars,'') else
       begin
          xGetWord; { variable id }
          if xFindVar(w) > 0 then
          begin
             xError(xrrMultiInit,'');
             Exit;
          end;
          Inc(xVars);
          New(xVar[xVars]);
          with xVar[xVars]^ do
          begin
             id := w;
             vtype := t;
           { param }
             numPar := 0;
             proc := False;
             ppos := 0;
             if t = vStr then size := slen else size := xVarSize(t);
             kill := True;
             arr := ar;
             arrdim := ard;

             dsize := xDataSize(xVars);
             GetMem(data,dsize);
             FillChar(data^,dsize,0);
          end;
       end;
    end;

    if error <> 0 then Exit;
    xGetChar; { check for setvar }
    if c = iqo[oVarDef] then
    begin
       xSetVariable(fi);
       for ci := fi+1 to xVars do Move(xVar[fi]^.data^,xVar[ci]^.data^,xVar[fi]^.dsize);
    end else xGoBack;
 end;

 procedure xGetUser;
 var x : Word; ss : String[1];
 begin
    x := xUstart-1;
    Move(User^.Number         ,xVar[x+01]^.data^,SizeOf(User^.Number       ));
    Move(User^.UserName       ,xVar[x+02]^.data^,SizeOf(User^.UserName     ));
    Move(User^.RealName       ,xVar[x+03]^.data^,SizeOf(User^.RealName     ));
    Move(User^.Password       ,xVar[x+04]^.data^,SizeOf(User^.Password     ));
    Move(User^.PhoneNum       ,xVar[x+05]^.data^,SizeOf(User^.PhoneNum     ));
    Move(User^.BirthDate      ,xVar[x+06]^.data^,SizeOf(User^.BirthDate    ));
    Move(User^.Location       ,xVar[x+07]^.data^,SizeOf(User^.Location     ));
    Move(User^.Address        ,xVar[x+08]^.data^,SizeOf(User^.Address      ));
    Move(User^.UserNote       ,xVar[x+09]^.data^,SizeOf(User^.UserNote     ));
    ss := User^.Sex;
    Move(ss                   ,xVar[x+10]^.data^,SizeOf(ss                 ));
    Move(User^.SL             ,xVar[x+11]^.data^,SizeOf(User^.SL           ));
    Move(User^.DSL            ,xVar[x+12]^.data^,SizeOf(User^.DSL          ));
    Move(User^.BaudRate       ,xVar[x+13]^.data^,SizeOf(User^.BaudRate     ));
    Move(User^.TotalCalls     ,xVar[x+14]^.data^,SizeOf(User^.TotalCalls   ));
    Move(User^.curMsgArea     ,xVar[x+15]^.data^,SizeOf(User^.curMsgArea   ));
    Move(User^.curFileArea    ,xVar[x+16]^.data^,SizeOf(User^.curFileArea  ));
    Move(User^.LastCall       ,xVar[x+17]^.data^,SizeOf(User^.LastCall     ));
    Move(User^.PageLength     ,xVar[x+18]^.data^,SizeOf(User^.PageLength   ));
    Move(User^.EmailWaiting   ,xVar[x+19]^.data^,SizeOf(User^.EmailWaiting ));
    ss := User^.Level;
    Move(ss                   ,xVar[x+20]^.data^,SizeOf(ss                 ));
    Move(User^.AutoSigLns     ,xVar[x+21]^.data^,SizeOf(User^.AutoSigLns   ));
    Move(User^.AutoSig        ,xVar[x+22]^.data^,SizeOf(User^.AutoSig      ));
    Move(User^.confMsg        ,xVar[x+23]^.data^,SizeOf(User^.confMsg      ));
    Move(User^.confFile       ,xVar[x+24]^.data^,SizeOf(User^.confFile     ));
    Move(User^.FirstCall      ,xVar[x+25]^.data^,SizeOf(User^.FirstCall    ));
    Move(User^.StartMenu      ,xVar[x+26]^.data^,SizeOf(User^.StartMenu    ));
    Move(User^.SysOpNote      ,xVar[x+27]^.data^,SizeOf(User^.SysOpNote    ));
    Move(User^.Posts          ,xVar[x+28]^.data^,SizeOf(User^.Posts        ));
    Move(User^.Email          ,xVar[x+29]^.data^,SizeOf(User^.Email        ));
    Move(User^.Uploads        ,xVar[x+30]^.data^,SizeOf(User^.Uploads      ));
    Move(User^.Downloads      ,xVar[x+31]^.data^,SizeOf(User^.Downloads    ));
    Move(User^.UploadKb       ,xVar[x+32]^.data^,SizeOf(User^.UploadKb     ));
    Move(User^.DownloadKb     ,xVar[x+33]^.data^,SizeOf(User^.DownloadKb   ));
    Move(User^.CallsToday     ,xVar[x+34]^.data^,SizeOf(User^.CallsToday   ));
    Move(User^.filePts        ,xVar[x+35]^.data^,SizeOf(User^.filePts      ));
    Move(User^.todayDL        ,xVar[x+36]^.data^,SizeOf(User^.todayDL      ));
    Move(User^.todayDLkb      ,xVar[x+37]^.data^,SizeOf(User^.todayDLkb    ));
    Move(User^.textLib        ,xVar[x+38]^.data^,SizeOf(User^.textLib      ));
    Move(User^.zipCode        ,xVar[x+39]^.data^,SizeOf(User^.zipCode      ));
    Move(User^.voteYes        ,xVar[x+40]^.data^,SizeOf(User^.voteYes      ));
    Move(User^.voteNo         ,xVar[x+41]^.data^,SizeOf(User^.voteNo       ));
 end;

 procedure xPutUser;
 var x : Word; ss : String[1];
 begin
    x := xUstart-1;
    Move(xVar[x+01]^.data^,User^.Number         ,SizeOf(User^.Number       ));
    Move(xVar[x+02]^.data^,User^.UserName       ,SizeOf(User^.UserName     ));
    Move(xVar[x+03]^.data^,User^.RealName       ,SizeOf(User^.RealName     ));
    Move(xVar[x+04]^.data^,User^.Password       ,SizeOf(User^.Password     ));
    Move(xVar[x+05]^.data^,User^.PhoneNum       ,SizeOf(User^.PhoneNum     ));
    Move(xVar[x+06]^.data^,User^.BirthDate      ,SizeOf(User^.BirthDate    ));
    Move(xVar[x+07]^.data^,User^.Location       ,SizeOf(User^.Location     ));
    Move(xVar[x+08]^.data^,User^.Address        ,SizeOf(User^.Address      ));
    Move(xVar[x+09]^.data^,User^.UserNote       ,SizeOf(User^.UserNote     ));
    Move(xVar[x+10]^.data^,ss                   ,SizeOf(ss                 ));
    User^.Sex := ss[1];
    Move(xVar[x+11]^.data^,User^.SL             ,SizeOf(User^.SL           ));
    Move(xVar[x+12]^.data^,User^.DSL            ,SizeOf(User^.DSL          ));
    Move(xVar[x+13]^.data^,User^.BaudRate       ,SizeOf(User^.BaudRate     ));
    Move(xVar[x+14]^.data^,User^.TotalCalls     ,SizeOf(User^.TotalCalls   ));
    Move(xVar[x+15]^.data^,User^.curMsgArea     ,SizeOf(User^.curMsgArea   ));
    Move(xVar[x+16]^.data^,User^.curFileArea    ,SizeOf(User^.curFileArea  ));
    Move(xVar[x+17]^.data^,User^.LastCall       ,SizeOf(User^.LastCall     ));
    Move(xVar[x+18]^.data^,User^.PageLength     ,SizeOf(User^.PageLength   ));
    Move(xVar[x+19]^.data^,User^.EmailWaiting   ,SizeOf(User^.EmailWaiting ));
    Move(xVar[x+20]^.data^,ss                   ,SizeOf(ss                 ));
    User^.Level := ss[1];
    Move(xVar[x+21]^.data^,User^.AutoSigLns     ,SizeOf(User^.AutoSigLns   ));
    Move(xVar[x+22]^.data^,User^.AutoSig        ,SizeOf(User^.AutoSig      ));
    Move(xVar[x+23]^.data^,User^.confMsg        ,SizeOf(User^.confMsg      ));
    Move(xVar[x+24]^.data^,User^.confFile       ,SizeOf(User^.confFile     ));
    Move(xVar[x+25]^.data^,User^.FirstCall      ,SizeOf(User^.FirstCall    ));
    Move(xVar[x+26]^.data^,User^.StartMenu      ,SizeOf(User^.StartMenu    ));
    Move(xVar[x+27]^.data^,User^.SysOpNote      ,SizeOf(User^.SysOpNote    ));
    Move(xVar[x+28]^.data^,User^.Posts          ,SizeOf(User^.Posts        ));
    Move(xVar[x+29]^.data^,User^.Email          ,SizeOf(User^.Email        ));
    Move(xVar[x+30]^.data^,User^.Uploads        ,SizeOf(User^.Uploads      ));
    Move(xVar[x+31]^.data^,User^.Downloads      ,SizeOf(User^.Downloads    ));
    Move(xVar[x+32]^.data^,User^.UploadKb       ,SizeOf(User^.UploadKb     ));
    Move(xVar[x+33]^.data^,User^.DownloadKb     ,SizeOf(User^.DownloadKb   ));
    Move(xVar[x+34]^.data^,User^.CallsToday     ,SizeOf(User^.CallsToday   ));
    Move(xVar[x+35]^.data^,User^.filePts        ,SizeOf(User^.filePts      ));
    Move(xVar[x+36]^.data^,User^.todayDL        ,SizeOf(User^.todayDL      ));
    Move(xVar[x+37]^.data^,User^.todayDLkb      ,SizeOf(User^.todayDLkb    ));
    Move(xVar[x+38]^.data^,User^.textLib        ,SizeOf(User^.textLib      ));
    Move(xVar[x+39]^.data^,User^.zipCode        ,SizeOf(User^.zipCode      ));
    Move(xVar[x+40]^.data^,User^.voteYes        ,SizeOf(User^.voteYes      ));
    Move(xVar[x+41]^.data^,User^.voteNo         ,SizeOf(User^.voteNo       ));
 end;

 function xProcExec(dp : Pointer) : tIqVar;
 type
    tParam = record
       s : array[1..maxParam] of String;
       b : array[1..maxParam] of Byte;
       h : array[1..maxParam] of ShortInt;
       w : array[1..maxParam] of Word;
       i : array[1..maxParam] of Integer;
       l : array[1..maxParam] of LongInt;
       r : array[1..maxParam] of Real;
       o : array[1..maxParam] of Boolean;
       v : array[1..maxParam] of Word;
    end;
 var vn, x, pid, sv : Word; p : tParam; ts : String; tb : ByteBool; ty : Byte;
     sub : LongInt;
  procedure par(var dat; siz : Word);
  begin
     if dp <> nil then Move(dat,dp^,siz);
  end;
 begin
    xGetWord; { proc id # }
    pid := w;
    vn := xFindVar(pid);
    for x := 1 to xVar[vn]^.numPar do with xVar[vn]^ do
    begin
       if param[x] = UpCase(param[x]) then
       begin
          xGetChar; { variable }
          xGetWord; { var id }
          p.v[x] := xFindVar(w);
       end else
       case param[x] of
          's' : p.s[x] := xEvalString;
          'b' : p.b[x] := Round(xEvalNumber);
          'h' : p.h[x] := Round(xEvalNumber);
          'w' : p.w[x] := Round(xEvalNumber);
          'i' : p.i[x] := Round(xEvalNumber);
          'l' : p.l[x] := Round(xEvalNumber);
          'r' : p.r[x] := xEvalNumber;
          'o' : p.o[x] := xEvalBool;
       end;
       xGetChar; { / var separator }
    end;

    xProcExec := xVar[vn]^.vtype;

    if xVar[vn]^.ppos > 0 then
    begin
       sub := xFilePos;

       xToPos(xVar[vn]^.ppos);
{      xPos := xVar[vn]^.ppos;}

       sv := xVars;

       for x := 1 to xVar[vn]^.numPar do
       begin
          if xVars >= maxVar then xError(errTooManyVars,'');
          Inc(xVars);
          New(xVar[xVars]);
          with xVar[xVars]^ do
          begin
             id := xVar[vn]^.pid[x];
             vtype := cVarType(xVar[vn]^.param[x]);
             numPar := 0;
             proc := False;
             ppos := 0;
             size := xVarSize(vtype);
             arr := 0;
             {arrdim}
             dsize := xDataSize(xVars);

             if xVar[vn]^.param[x] = upCase(xVar[vn]^.param[x]) then
             begin
                data := xVar[p.v[x]]^.data;
                kill := False;
             end else
             begin
                GetMem(data,dsize);
                case xVar[vn]^.param[x] of
                   's' : begin
                            if Ord(p.s[x,0]) >= size then p.s[x,0] := Chr(size-1);
                            Move(p.s[x],data^,size);
                         end;
                   'b' : Byte(Pointer(data)^) := p.b[x];
                   'h' : ShortInt(Pointer(data)^) := p.h[x];
                   'w' : Word(Pointer(data)^) := p.w[x];
                   'i' : Integer(Pointer(data)^) := p.i[x];
                   'l' : LongInt(Pointer(data)^) := p.l[x];
                   'r' : Real(Pointer(data)^) := p.r[x];
                   'o' : Boolean(Pointer(data)^) := p.o[x];
                end;
                kill := True;
             end;
          end;
       end;

       if xVar[vn]^.vtype <> vNone then
       begin
{         xVar[vn]^.size := xVarSize(xVar[vn]^.vtype);}
          xVar[vn]^.dsize := xDataSize(vn);
          GetMem(xVar[vn]^.data,xVar[vn]^.dsize);
          FillChar(xVar[vn]^.data^,xVar[vn]^.dsize,0);
       end;

       xParse(sv);

       if xVar[vn]^.vtype <> vNone then
       begin
          if dp <> nil then Move(xVar[vn]^.data^,dp^,xVar[vn]^.dsize);
          FreeMem(xVar[vn]^.data,xVar[vn]^.dsize);
          xVar[vn]^.dsize := 0;
       end;

       xToPos(sub);

       Exit;
    end;

 { %%%%% internal procedures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% }

    case pid of
     { output routines }
       0   : oWrite(p.s[1]);
       1   : oWriteLn(p.s[1]);
       2   : oClrScr;
       3   : oClrEol;
       4   : oBeep;
       5   : oCwrite(p.s[1]);
       6   : oCwriteLn(p.s[1]);
       7   : oDnLn(p.b[1]);
       8   : oGotoXY(p.b[1],p.b[2]);
       9   : oMoveUp(p.b[1]);
       10  : oMoveDown(p.b[1]);
       11  : oMoveLeft(p.b[1]);
       12  : oMoveRight(p.b[1]);
       13  : oPosX(p.b[1]);
       14  : oPosY(p.b[1]);
       15  : oSetBack(p.b[1]);
       16  : oSetFore(p.b[1]);
       17  : oSetBlink(p.o[1]);
       18  : oSetColor(p.b[1],p.b[2]);
       19  : output.oStr(p.s[1]);
       20  : oStrLn(p.s[1]);
       21  : oString(p.b[1]);
       22  : oStringLn(p.b[1]);
       23  : oStrCtr(p.s[1]);
       24  : oStrCtrLn(p.s[1]);
       25  : oWriteAnsi(p.s[1]);
       26  : begin tb := sfShowTextFile(p.s[1],ftNormal); par(tb,1); end;
       27  : begin tb := sfShowFile(p.s[1],ftNormal); par(tb,1); end;
       28  : if oWhereX <> 1 then oDnLn(1);
       29  : begin ty := oWhereX; par(ty,1); end;
       30  : begin ty := oWhereY; par(ty,1); end;

     { input routines }
       40  : begin ts[0] := #1; ts[1] := iReadKey; par(ts,256); end;
       41  : begin ts := iGetString(p.s[2],p.s[3],p.s[4],st(p.b[5]),p.s[1],''); par(ts,256); end;
       42  : begin ts := iGetString(p.s[2],p.s[3],p.s[4],st(p.b[5]),p.s[1],st(p.b[6])); par(ts,256); end;
       43  : begin tb := iKeypressed; par(tb,1); end;
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
       44  : begin ts := iReadDate(p.s[1]); par(ts,256); end;
       45  : begin ts := iReadTime(p.s[1]); par(ts,256); end;
       46  : begin ts := iReadPhone(p.s[1]); par(ts,256); end;
       44  : begin ts := iReadPostalCode; par(ts,256); end;
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
       44  : begin ts := iReadZipCode; par(ts,256); end;
       45  : begin tb := iYesNo(p.o[1]); par(tb,1); end;

     { string functions }
       60  : begin ts := upStr(p.s[1]); par(ts,256); end;
       61  : begin ts := strLow(p.s[1]); par(ts,256); end;
       62  : begin ts := b2st(p.o[1]); par(ts,256); end;
       63  : begin ty := Pos(p.s[1],p.s[2]); par(ty,1); end;
       64  : begin ts := cleanUp(p.s[1]); par(ts,256); end;
       65  : begin ts := strMixed(p.s[1]); par(ts,256); end;
       66  : begin ts := noColor(p.s[1]); par(ts,256); end;
       67  : begin ts := Resize(p.s[1],p.b[1]); par(ts,256); end;
       68  : begin ts := strResizeNc(p.s[1],p.b[1]); par(ts,256); end;
       69  : begin ts := ResizeRt(p.s[1],p.b[1]); par(ts,256); end;
       70  : begin ts := st(p.l[1]); par(ts,256); end;
       71  : begin ts := strReal(p.r[1],p.b[2],p.b[3]); par(ts,256); end;
       72  : begin ts := stc(p.l[1]); par(ts,256); end;
       73  : begin ts := strSquish(p.s[1],p.b[1]); par(ts,256); end;
       74  : begin ts := strReplace(p.s[1],p.s[2],p.s[3]); par(ts,256); end;
       75  : begin ts := Copy(p.s[1],p.b[2],p.b[3]); par(ts,256); end;
       76  : begin ts := p.s[1]; Delete(ts,p.b[2],p.b[3]); par(ts,256); end;
       77  : begin ts := sRepeat(p.s[1,1],p.b[2]); par(ts,256); end;

     { ipl-related routines }
       80  : begin ts := cVersion; par(ts,256); end;
       81  : begin ts := cTitle; par(ts,256); end;
       82  : begin ts := mStrParam(xPar,p.b[1]); par(ts,256); end;
       83  : begin ty := mStrParCnt(xPar); par(ty,1); end;

     { user manipulation }
       90  : xGetUser;
       91  : xPutUser;
       92  : begin User^.Number := p.w[1]; userLoad(User^); end;
       93  : userSave(User^);
     end;

 { %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% }
 end;

 procedure xSkip;
 begin
    xGetChar; { open block }
    xGetWord; { size of block }
    xToPos(xFilePos+w);
 end;

 procedure xProcDef;
 var k, pi, ni : Word; t : Char;
 begin
    if xVars >= maxVar then
    begin
       xError(xrrTooManyVars,'');
       Exit;
    end;
    xGetWord; { procedure var id }
    if xFindVar(w) > 0 then
    begin
       xError(xrrMultiInit,'');
       Exit;
    end;
    Inc(xVars);
    New(xVar[xVars]);
    with xVar[xVars]^ do
    begin
       id := w;
       vtype := vNone;
       numPar := 0;
       proc := False;
       ppos := 0;
       size := 0;
       dsize := 0;
       arr := 0;
       {arrdim}
    end;
    xGetChar;
    pi := 0;
    while (error = 0) and (not (c in [iqo[oProcType],iqo[oOpenBlock]])) do
    begin
       t := c;
       xGetWord;
       ni := w;
       for k := 1 to ni do
       begin
          Inc(pi);
          xVar[xVars]^.param[pi] := t;
          xGetWord;
          xVar[xVars]^.pid[pi] := w;
       end;
       xGetChar;
    end;
    if c = iqo[oProcType] then
    begin
       xGetChar;
       xVar[xVars]^.vtype := cVarType(c);
       xVar[xVars]^.size := xVarSize(xVar[xVars]^.vtype);
    end else xGoBack;
    xVar[xVars]^.numpar := pi;
    xVar[xVars]^.ppos := xFilePos;

    xSkip; {ToPos(xFilePos+pSize);}
 end;

 procedure xLoopFor;
 var vc : Word; nstart, nend, count : Real; up : Boolean; spos : LongInt;
     ad : tArray;
 begin
    xGetWord; { counter variable }
    vc := xFindVar(w);
    xCheckArray(vc,ad);
    nstart := xEvalNumber; { start num }
    xGetChar; { direction (to/downto) }
    up := c = iqo[oTo];
    nend := xEvalNumber; { ending num }
    count := nstart;

    spos := xFilePos; { save pos }

    if (up and (nstart > nend)) or ((not up) and (nstart < nend)) then xSkip else
    if up then
    while count <= nend do
    begin
       xSetNumber(vc,count,ad);
       xToPos(spos);
       xParse(xVars);
       count := count+1;
    end else
    while count >= nend do
    begin
       xSetNumber(vc,count,ad);
       xToPos(spos);
       xParse(xVars);
       count := count-1;
    end;
 end;

 procedure xWhileDo;
 var ok : Boolean; spos : LongInt;
 begin
    spos := xFilePos;
    ok := True;
    while (error = 0) and (ok) do
    begin
       ok := xEvalBool;
       if ok then
       begin
          xParse(xVars);
          xToPos(spos);
       end else xSkip;
    end;
 end;

 procedure xRepeatUntil;
 var ok : Boolean; spos : LongInt;
 begin
    spos := xFilePos;
    ok := True;
    repeat
       xToPos(spos);
       xParse(xVars);
    until (error <> 0) or (xEvalBool);
 end;

 procedure xIfThenElse;
 var ok : Boolean;
 begin
    ok := xEvalBool;

    if ok then xParse(xVars) else xSkip;

    xGetChar; { check for else }
    if c = iqo[oElse] then
    begin
       if not ok then xParse(xVars) else xSkip;
    end else xGoBack;
 end;

 procedure xGotoPos;
 var p : LongInt;
 begin
    xGetWord;
    p := w;
    xToPos(p);
 end;

 procedure xParse(svar : Word);
 var done : Boolean; z : Word;
 begin
    xGetChar; { open block }
    xGetWord; { size of block }
    done := False;

{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
    repeat
       xGetChar;
       if c = iqo[oCloseBlock] then done := True else
       if c = iqo[oOpenBlock] then
       begin
          xGoBack;
          xParse(xVars);
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
       end else
       if c = iqo[oVarDeclare] then xCreateVar else
       if c = iqo[oSetVar] then
       begin
          xGetWord;
          xSetVariable(xFindVar(w));
       end else
       if c = iqo[oProcExec] then xProcExec(nil) else
       if c = iqo[oProcDef] then xProcDef else
       if c = iqo[oFor] then xLoopFor else
       if c = iqo[oIf] then xIfThenElse else
       if c = iqo[oWhile] then xWhileDo else
       if c = iqo[oRepeat] then xRepeatUntil else
       if c = iqo[oGoto] then xGotoPos else
          xError(xrrUnknownOp,c);
    until (error <> 0) or (done);

   {xGetChar; { close block }

    for z := xVars downto svar+1 do
    begin
       if (xVar[z]^.kill) and (xVar[z]^.data <> nil) then
          FreeMem(xVar[z]^.data,xVar[z]^.dsize);
       Dispose(xVar[z]);
    end;
    xVars := svar;
 end;

 procedure xTerminate;
 var z : Word;
 begin
    for z := 1 to xVars do
    begin
       if (xVar[z]^.kill) and (xVar[z]^.data <> nil) then FreeMem(xVar[z]^.data,xVar[z]^.dsize);
       Dispose(xVar[z]);
    end;
    xVars := 0;
 end;

begin
   xExecute := 0;
   xInit;
   w := 0;
   Assign(f,fn);
   {$I-}
   Reset(f,1);
   {$I+}
   if ioResult <> 0 then
   begin
      xError(xrrFileNotFound,fn);
      Exit;
   end;

   if FileSize(f) < idLength then
   begin
      Close(f);
      xError(xrrInvalidFile,fn);
      Exit;
   end;

   FillChar(xid,SizeOf(xid),32);
   FillChar(xver,SizeOf(xver),32);
   xid[0] := chr(idVersion);
   xver[0] := chr(idLength-idVersion);
   BlockRead(f,xid[1],idVersion);
   BlockRead(f,xver[1],idLength-idVersion);
   while not (xver[Ord(xver[0])] in ['0'..'9','a'..'z']) do Dec(xver[0]);

   if cleanUp(xid) <> cProgram then
   begin
      Close(f);
      xError(xrrInvalidFile,fn);
      Exit;
   end;

   if cleanUp(xver) <> cVersion then
   begin
      Close(f);
      xError(xrrVerMismatch,cleanUp(xver));
      Exit;
   end;

   cInitProcs(xVar,xVars,w);

   xParse(xVars);

   xTerminate;

   Close(f);

   xExecute := xpos;
end;

procedure iplExecute(fn, par : String);
var z, m1, m2 : LongInt; x : String;
begin
   m1 := maxavail;
   xPar := par;

   fn := upStr(fn);
   if not fExists(fn) then
   begin
      x := fn+extIPLexe;
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin

function xErrorMsg : String;
var s : String;
begin
      if not fExists(fn) then
      begin
         logWrite('xIPL: Error opening "'+fn+'"; file not found');
         Exit;
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
      end else fn := x;
   end;

   sbInfo('(IPL) Executing "'+fn+'" ...',True);
   logWrite('IPL: Executed "'+fn+'"');
   z := xExecute(fn);
   m2 := maxavail;
   if error = 0 then sbInfo('(IPL) Execution successful. ['+st(z)+' bytes]    memdiff: '+st(m1-m2),False)
{$DEFINE ipx}
   errStr : String;
   error  : Byte;
   xPar   : String;

function xErrorMsg : String;
var s : String;
begin
                else sbInfo('(IPL) Error: '+xErrorMsg+' [pos '+st(z)+']    memdiff: '+st(m1-m2),False);
end;

end.
