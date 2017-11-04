program FixUsers;

uses Dos,
     Global;

type
   tOldUserACflag = (
      acANSi,
      acAVATAR,
      acRIP,
      acYesNoBar,
      acDeleted,
      acExpert,
      acHotKey
   );

   tOldUserRec = record
      Number             : Integer;
      UserName           : String[36];
      RealName           : String[36];
      Password           : String[20];
      PhoneNum           : String[13];
      BirthDate          : String[8];
      Location           : String[40];
      Address            : String[36];
      UserNote           : String[40];
      Sex                : Char;
      SL                 : Byte;
      DSL                : Byte;
      BaudRate           : LongInt;
      TotalCalls         : Word;
      curMsgArea         : Word;
      acFlag             : set of tOldUserACflag;
      Color              : tColor;
      LastCall           : String[8];
      PageLength         : Word;
      EmailWaiting       : Word;
      Level              : Char;

      curFileArea        : Word;
      timeToday          : Word;
      timePerDay         : Word;

      AutoSigLns         : Byte;
      AutoSig            : tAutoSig;

      confMsg            : Byte;
      confFile           : Byte;

      Reserved           : array[1..1553] of Byte;
   end;

var F : file of tOldUserRec;
    nF : file of tUserRec;
    U : tUserRec; O : tOldUserRec; Z : Word;

begin
   Assign(F,'C:\INIQ\DATA\USERS.DAT');
   Assign(nF,'C:\INIQ\DATA\NEWUSERS.DAT');
   Reset(F);
   Rewrite(nF);

   Z := 0;
   while not Eof(F) do
   begin
      Inc(Z,1);
      Read(F,O);
      FillChar(U,SizeOf(U),0);
      with U do
      begin
         Number             := o.Number;
         UserName           := o.UserName;
         RealName           := o.RealName;
         Password           := o.Password;
         PhoneNum           := o.PhoneNum;
         BirthDate          := o.BirthDate;
         Location           := o.Location;
         Address            := o.Address;
         UserNote           := o.UserNote;
         Sex                := o.Sex;
         SL                 := o.SL;
         DSL                := o.DSL;
         BaudRate           := o.Baudrate;
         TotalCalls         := o.TotalCalls;
         curMsgArea         := o.curMsgArea;
         curFileArea        := o.curFileArea;
         acFlag             := [];
         if acANSI in o.acFlag then acFlag := acFlag+[Global.acANSI];
         if acAVATAR in o.acFlag then acFlag := acFlag+[Global.acAVATAR];
         if acRIP in o.acFlag then acFlag := acFlag+[Global.acRIP];
         if acYesNoBar in o.acFlag then acFlag := acFlag+[Global.acYesNoBar];
         if acDeleted in o.acFlag then acFlag := acFlag+[Global.acDeleted];
         if acExpert in o.acFlag then acFlag := acFlag+[Global.acExpert];
         if acHotKey in o.acFlag then acFlag := acFlag+[Global.acHotKey];
         acFlag := acFlag+[acPause,acQuote];
         Color              := o.Color;
         LastCall           := o.LastCall;
         PageLength         := o.PageLength;
         EmailWaiting       := o.EmailWaiting;
         Level              := o.Level;
         timeToday          := o.TimeToday;
         timePerDay         := o.TimePerDay;
         AutoSigLns         := o.AutoSigLns;
         AutoSig            := o.AutoSig;
         confMsg            := o.confMsg;
         confFile           := o.confFile;

         FillChar(Reserved,SizeOf(Reserved),0);
      end;
      Write(nF,U);
   end;
   Close(F);
   Close(nF);
end.
