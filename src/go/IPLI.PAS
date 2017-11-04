{ Iniquity Programming Language - Global Constants }

const
   cTitle             = 'Iniquity Programming Language';
   cProgram           = 'Iniquity/PL [executable file]';
   cVersion           = 'v1.00a';

   idLength           = 40;
   idVersion          = 30;

   extSource          = '.ips';
   extExecute         = '.ipx';

   maxFile            = 20;
   maxVar             = 500;
   maxIdentLen        = 30;
   maxVarDeclare      = 30;
   maxParam           = 40;
   maxProc            = 2;
   maxArray           = 3;
   maxGoto            = 100;

   chDigit            = ['0'..'9'];
   chNumber           = ['0'..'9','.'];
   chAny              = [#0..#255];
   chIdent1           = ['a'..'z','A'..'Z','_'];
   chIdent2           = ['a'..'z','A'..'Z','0'..'9','_'];

   errUeEndOfFile     = 1;
   errFileNotfound    = 2;
   errFileRecurse     = 3;
   errOutputFile      = 4;
   errExpected        = 5;
   errUnknownIdent    = 6;
   errInStatement     = 7;
   errIdentTooLong    = 8;
   errExpIdentifier   = 9;
   errTooManyVars     = 10;
   errDupIdent        = 11;
   errOverMaxDec      = 12;
   errTypeMismatch    = 13;
   errSyntaxError     = 14;
   errStringNotClosed = 15;
   errStringTooLong   = 16;
   errTooManyParams   = 17;
   errBadProcRef      = 18;
   errNumExpected     = 19;
   errToOrDowntoExp   = 20;
   errExpOperator     = 21;
   errOverArrayDim    = 22;
   errNoInitArray     = 23;
   errTooManyGotos    = 24;
   errDupLabel        = 25;
   errLabelNotFound   = 26;

   xrrUeEndOfFile     = 1;
   xrrFileNotFound    = 2;
   xrrInvalidFile     = 3;
   xrrVerMismatch     = 4;
   xrrUnknownOp       = 5;
   xrrTooManyVars     = 6;
   xrrMultiInit       = 7;
   xrrDivisionByZero  = 8;
   xrrMathematical    = 9;

type
   tIqVar     = (vNone,vStr,vByte,vShort,vWord,vInt,vLong,vReal,vBool);
   tIqWord    = (wOpenBlock,wCloseBlock,wCmtStartBlock,wCmtEndBlock,
                 wCommentLine,wCmtNumberSign,wVarDeclare,wVarSep,wSetVar,
                 wOpenBrack,wCloseBrack,wOpenString,wCloseString,wStrAdd,
                 wCharPrefix,wProcDef,wOpenParam,wCloseParam,wParamVar,
                 wParamSpec,wFuncSpec,wParamSep,wFor,wTo,wDownto,wDo,wTrue,
                 wFalse,wOpEqual,wOpNotEqual,wOpGreater,wOpLess,wOpEqGreat,
                 wOpEqLess,wIf,wThen,wElse,wWhile,wRepeat,wUntil,wNot,wAnd,
                 wOr,wStrCh,wOpenArr,wCloseArr,wArrSep,wVarDef,wOpenStrLen,
                 wCloseStrLen,wGoto,wLabel);
   tIqOp      = (oOpenBlock,oCloseBlock,oVarDeclare,oStr,oByte,oShort,oWord,
                 oInt,oLong,oReal,oBool,oSetVar,oOpenBrack,oCloseBrack,
                 oVariable,oOpenString,oCloseString,oProcDef,oProcExec,
                 oParamSep,oFor,oTo,oDownto,oTrue,oFalse,oOpEqual,
                 oOpNotEqual,oOpGreater,oOpLess,oOpEqGreat,oOpEqLess,
                 oStrAdd,oProcType,oIf,oElse,oWhile,oOpenNum,oCloseNum,
                 oRepeat,oNot,oAnd,oOr,oStrCh,oArrDef,oVarDef,oStrLen,
                 oVarNormal,oGoto);

const
   iqv : array[tIqVar] of String[maxIdentLen] =
       ('none','str','byte','short','word','int','long','real','bool');
   iqw : array[tIqWord] of String[maxIdentLen] =
       ('{','}','|','|','%','#','@',',','=','(',')','"','"','+','#','proc',
        '[',']','+',';',':',',','for','to','downto','do','true','false','=',
        '<>','>','<','>=','<=','if','then','else','while','repeat','until',
        'not','and','or','.','(',')',',','=','<','>','goto',':');
   iqo : array[tIqOp] of Char =
       ('[',']','+','s','b','h','w','i','l','r','o','-','(',')','v','"','"',
        '%','ø','/','#','Ü','ß','t','f','=','!','>','<','}','{','&',':','?',
        '*','|','`','''','é','ï','î','þ','~',#0,'ä','\','í','Û');
   vnums : set of tIqVar = [vByte,vShort,vWord,vInt,vLong,vReal];

{$IFDEF ipx}
type
   pData = ^tData;
   tData = array[1..65535] of Byte;

   tArray = array[1..maxArray] of Word;

   pVar = ^tVar;
   tVar = record
      id     : Word;
      vtype  : tIqVar;
      param  : array[1..maxParam] of Char;
      numPar : Byte;
      proc   : Boolean;
      pid    : array[1..maxParam] of Word;
      ppos   : LongInt;
      dsize  : Word;
      size   : Word;
      data   : pData;
      kill   : Boolean;
      arr    : Byte;
      arrdim : tArray;
   end;
   tVars = array[1..maxVar] of pVar;

{$ELSE}
type
   pVar = ^tVar;
   tVar = record
      id     : Word;
      ident  : String[maxIdentLen];
      vtype  : tIqVar;
      param  : array[1..maxParam] of Char;
      numPar : Byte;
      proc   : Boolean;
      inproc : Boolean;
      arr    : Byte;
   end;
   tVars = array[1..maxVar] of pVar;

   pGoto = ^tGoto;
   tGoto = record
      ident  : String[maxIdentLen];
      xPos   : LongInt;
      stat   : Byte;
   end;

var
   cVar   : tVars;
   cVars  : Word;
   cID    : Word;
   cGoto  : array[1..maxGoto] of pGoto;
   cGotos : Word;
{$ENDIF}

var
   xUstart : Word;


function cVarType(c : Char) : tIqVar;
begin
   c := upCase(c);
   case c of
     'S' : cVarType := vStr;
     'B' : cVarType := vByte;
     'H' : cVarType := vShort;
     'W' : cVarType := vWord;
     'I' : cVarType := vInt;
     'L' : cVarType := vLong;
     'R' : cVarType := vReal;
     'O' : cVarType := vBool;
      else cVarType := vNone;
   end;
end;

function xVarSize(t : tIqVar) : Word;
begin
   case t of
      vNone  : xVarSize := 0;
      vStr   : xVarSize := 256;
      vByte  : xVarSize := 1;
      vShort : xVarSize := 1;
      vWord  : xVarSize := 2;
      vInt   : xVarSize := 2;
      vLong  : xVarSize := 4;
      vReal  : xVarSize := 6;
      vBool  : xVarSize := 1;
   end;
end;

procedure cInitProcs(var cV : tVars; var x : Word; var iw : Word);
 procedure ip(i : String; p : String; t : tIqVar);
 begin
    Inc(x);
    New(cV[x]);
    with cV[x]^ do
    begin
       id := iw;
       Inc(iw);
       vtype := t;
       Move(p[1],param,Ord(p[0]));
       numPar := Ord(p[0]);
       proc := True;
{$IFDEF ipx}
       size := 0;
       dsize := 0;
       data := nil;
       FillChar(pid,SizeOf(pid),0);
       ppos := 0;
       kill := True;
{$ELSE}
       ident := i;
       inproc := False;
{$ENDIF}
       arr := 0;
       {arrdim}
    end;
 end;
 procedure is(i : String; t : tIqVar; si : Word);
 begin
    Inc(x);
    New(cV[x]);
    with cV[x]^ do
    begin
       id := iw;
       Inc(iw);
       vtype := t;
      {param}
       numPar := 0;
       proc := False;
{$IFDEF ipx}
       size := si+1;
       dsize := size;
       GetMem(data,dsize);
       FillChar(data^,dsize,0);
       FillChar(pid,SizeOf(pid),0);
       ppos := 0;
       kill := True;
{$ELSE}
       ident := i;
       inproc := False;
{$ENDIF}
       arr := 0;
       {arrdim}
    end;
 end;
 procedure iv(i : String; t : tIqVar);
 begin
    is(i,t,xVarSize(t)-1);
 end;
 procedure ivp(i : String; t : tIqVar; si : Word; pd : Pointer);
 begin
    Inc(x);
    New(cV[x]);
    with cV[x]^ do
    begin
       id := iw;
       Inc(iw);
       vtype := t;
      {param}
       numPar := 0;
       proc := False;
{$IFDEF ipx}
       if t = vStr then size := si+1 else size := si;
       dsize := size;
       data := pd;
{      GetMem(data,dsize);
       FillChar(data^,dsize,0);}
       FillChar(pid,SizeOf(pid),0);
       ppos := 0;
       kill := False;
{$ELSE}
       ident := i;
       inproc := False;
{$ENDIF}
       arr := 0;
       {arrdim}
    end;
 end;
begin
   iw := 0; { output routines }
   ip('out',         's',       vNone);
   ip('outln',       's',       vNone);
   ip('clrscr',      '',        vNone);
   ip('clreol',      '',        vNone);
   ip('beep',        '',        vNone);
   ip('cout',        's',       vNone);
   ip('coutln',      's',       vNone);
   ip('dnln',        'b',       vNone);
   ip('gotoxy',      'bb',      vNone);
   ip('posup',       'b',       vNone);
   ip('posdown',     'b',       vNone);
   ip('posleft',     'b',       vNone);
   ip('posright',    'b',       vNone);
   ip('posx',        'b',       vNone);
   ip('posy',        'b',       vNone);
   ip('setback',     'b',       vNone);
   ip('setfore',     'b',       vNone);
   ip('setblink',    'o',       vNone);
   ip('setcolor',    'bb',      vNone);
   ip('sout',        's',       vNone);
   ip('soutln',      's',       vNone);
   ip('strout',      'w',       vNone);
   ip('stroutln',    'w',       vNone);
   ip('xout',        's',       vNone);
   ip('xoutln',      's',       vNone);
   ip('aout',        's',       vNone);
   ip('showtext',    's',       vBool);
   ip('showfile',    's',       vBool);
   ip('fline',       '',        vNone);
   ip('wherex',      '',        vByte);
   ip('wherey',      '',        vByte);

   iw := 40; { input routines }
   ip('inkey',       '',        vStr);
   ip('instr',       'ssssb',   vStr);
   ip('instrf',      'ssssbb',  vStr);
   ip('keypressed',  '',        vBool);
   ip('indate',      's',       vStr);
   ip('intime',      's',       vStr);
   ip('inphone',     's',       vStr);
   ip('inpostal',    '',        vStr);
   ip('inzipcode',   '',        vStr);
   ip('inyesno',     'o',       vBool);

   iw := 60; { string funtions }
   ip('strup',       's',       vStr);
   ip('strlow',      's',       vStr);
   ip('stryesno',    'o',       vStr);
   ip('strpos',      'ss',      vByte);
   ip('strtrim',     's',       vStr);
   ip('strmixed',    's',       vStr);
   ip('strnocol',    's',       vStr);
   ip('strsize',     'sb',      vStr);
   ip('strsizenc',   'sb',      vStr);
   ip('strsizer',    'sb',      vStr);
   ip('strint',      'l',       vStr);
   ip('strreal',     'rbb',     vStr);
   ip('strintc',     'l',       vStr);
   ip('strsquish',   'sb',      vStr);
   ip('strreplace',  'sss',     vStr);
   ip('strcopy',     'sbb',     vStr);
   ip('strdel',      'sbb',     vStr);
   ip('strrepeat',   'sb',      vStr);

   iw := 80; { ipl-related routines }
   ip('iplver',      '',        vStr);
   ip('iplname',     '',        vStr);
   ip('iplpar',      'b',       vStr);
   ip('iplnumpar',   '',        vByte);

   { user manipulation }
   iw := 90;
   ip('userget',     '',        vNone);
   ip('userput',     '',        vNone);
   ip('userload',    'w',       vNone);
   ip('usersave',    '',        vNone);

   iw := 200; { user-record variables }
   xUstart := x+1;
   iv('unumber',     vInt);
   is('uhandle',     vStr,    36);
   is('urealname',   vStr,    36);
   is('upassword',   vStr,    20);
   is('uphone',      vStr,    13);
   is('ubdate',      vStr,    8);
   is('ulocation',   vStr,    40);
   is('uaddress',    vStr,    36);
   is('unote',       vStr,    40);
   is('usex',        vStr,    1);
   iv('usl',         vByte);
   iv('udsl',        vByte);
   iv('ubaud',       vLong);
   iv('ucalls',      vWord);
   iv('umsgarea',    vWord);
   iv('ufilearea',   vWord);
{ acflag !! } { colors!! }
   is('ulastcall',   vStr,    8);
   iv('upagelen',    vWord);
   iv('uemail',      vWord);
   is('ulevel',      vStr,    1);
   iv('usiglines',   vByte);
   is('uautosig',    vStr,    maxSigLines*81-1); cV[x]^.arr := 1;
   {$IFDEF ipx} cV[x]^.size := 81; cV[x]^.arrdim[1] := maxSigLines; {$ENDIF}
   iv('umsgconf',    vByte);
   iv('ufileconf',   vByte);
   is('ufirstcall',  vStr,    8);
   is('ustartmenu',  vStr,    8);
   is('usysopnote',  vStr,    40);
   iv('uposts',      vWord);
   iv('uemail',      vWord);
   iv('uuploads',    vWord);
   iv('udownloads',  vWord);
   iv('uuploadkb',   vWord);
   iv('udownloadkb', vWord);
   iv('ucallst',     vWord);
  { flags!! }
   iv('ufilepts',    vWord);
   iv('udownloadt',  vWord);
   iv('udlkbt',      vWord);
   iv('utextlib',    vByte);
   is('uzipcode',    vStr,    10);
   iv('uvoteyes',    vByte);
   iv('uvoteno',     vByte);

   iw := 250; { internal variables - non-killable }
   ivp('remoteout',  vBool,   1,   @RemoteOut);
   ivp('remotein',   vBool,   1,   @RemoteIn);
   ivp('localio',    vBool,   1,   @LocalIO);
   ivp('modemio',    vBool,   1,   @ModemIO);
   ivp('useron',     vBool,   1,   @UserOn);
   ivp('loggedin',   vBool,   1,   @LoggedIn);
   ivp('screenoff',  vBool,   1,   @ScreenOff);
   ivp('tempsysop',  vBool,   1,   @TempSysOp);
   ivp('quitafter',  vBool,   1,   @QuitAfter);
   ivp('keylocal',   vBool,   1,   @LocKey);
   ivp('usetag',     vBool,   1,   @useTag);
   ivp('timecheck',  vBool,   1,   @timeCheck);
   ivp('asdoor',     vBool,   1,   @asDoor);
   ivp('mconfall',   vBool,   1,   @mandMsg);
   ivp('fconfall',   vBool,   1,   @fConfAll);

   ivp('node',       vByte,   1,   @Node);
   ivp('numbatch',   vByte,   1,   @numBatch);

   ivp('chatreason', vStr,    255, @ChatReason);
   ivp('inputstring',vStr,    255, @inputString);

   ivp('numevent',   vWord,   2,   @numEvent);
   ivp('nummarea',   vWord,   2,   @numMsgArea);
   ivp('numfarea',   vWord,   2,   @numFileArea);
   ivp('numusers',   vWord,   2,   @numUsers);
   ivp('nummconf',   vWord,   2,   @numMsgConf);
   ivp('numfconf',   vWord,   2,   @numFileConf);
   ivp('numtlib',    vWord,   2,   @numLib);
   ivp('numiform',   vWord,   2,   @numInfo);

   ivp('emailtag',   vWord,   2,   @emailTag);
   ivp('readtag',    vWord,   2,   @readTag);
   iw := 300;
end;