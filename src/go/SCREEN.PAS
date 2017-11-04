{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Screen;

Interface

Procedure scrInitPages(Pages : Byte);
Procedure scrDeInitPages;
Procedure scrStoreScreen(Page : Byte);
Procedure scrRestoreScreen(Page : Byte);

Implementation

uses Strings, Global;

Const
  MaxPages  = 20;
Type
  PageType  = Array [1..50,1..80] Of Word;
  PageArray = Array [1..MaxPages] Of ^PageType;
Var
  ScrPtr    : ^PageType;
  ScrPages  : PageArray;
  PageInMem : Array [1..MaxPages] Of Boolean;
  VideoMode : ^Byte;
  UseDisk   : Boolean;

Var
  MPages       : Byte;
  SaveExitProc : Pointer;

Procedure scrInitPages(Pages : Byte);
Var
  Loop : Byte;
begin
  If Pages>MaxPages Then
    Pages := MaxPages;
  For Loop:=1 To Pages Do
  If (MaxAvail>=SizeOf(PageType)) And (Not UseDisk) Then
  begin
    PageInMem[Loop] := True;
    GetMem(ScrPages[Loop],SizeOf(PageType));
  end
  Else
  begin
    PageInMem[Loop] := False;
    ScrPages[Loop]  := NIL;
  end;
  MPages := Pages;
end;

Procedure scrDeInitPages;
Var Loop : Byte;
begin
  If MPages>0 Then
    For Loop:=MPages DownTo 1 Do
      If PageInMem[Loop] Then
      begin
        Release(ScrPages[Loop]);
        PageInMem[Loop] := False;
      end;
  MPages := 0;
end;

Procedure scrStoreScreen(Page : Byte);
Var
  F : File Of PageType;
begin
  If Page<=MPages Then
  begin
    If PageInMem[Page] Then
      Move(ScrPtr^,ScrPages[Page]^,SizeOf(PageType))
    Else
    begin
      Assign(F,Cfg^.pathData+'INISCREEN.S'+St(Page));
      {$I-}
      ReWrite(F);
      {$I+}
      If IOResult=0 Then
      begin
        Write(F,ScrPtr^);
        Close(F);
      end;
    end;
  end;
end;

Procedure scrRestoreScreen(Page : Byte);
Var
  F : File Of PageType;
begin
  If Page<=MPages Then
  begin
    If PageInMem[Page] Then
      Move(ScrPages[Page]^,ScrPtr^,SizeOf(PageType))
    Else
    begin
      Assign(F,Cfg^.pathData+'INISCREEN.S'+St(Page));
      {$I-}
      Reset(F);
      {$I+}
      If IOResult=0 Then
      begin
        Read(F,ScrPtr^);
        Close(F);
      end;
    end;
  end;
end;

{$F+}
Procedure ScreenExitProc;
Var
  Loop : Byte;
  F    : File;
begin
  ExitProc := SaveExitProc;
  If MPages>0 Then
    For Loop:=1 To MPages Do
    begin
      Assign(F,'INISCREEN.S'+St(Loop));
      {$I-} Erase(F); {$I+}
      If IOResult <> 0 Then;
    end;
end;
{$F-}

begin
  VideoMode := Ptr(Seg0040,$0049);
  If VideoMode^=7 Then
    ScrPtr := Ptr(SegB000,$0000)
  Else
    ScrPtr := Ptr(SegB800,$0000);
  MPages := 0;
  UseDisk := False;
  SaveExitProc := ExitProc;
  ExitProc := @ScreenExitProc;
end.

(*
This simple Unit is able to store up to 20 screens. If there is enough free
heap all screens are stored to heap which is Really fast. If there is not
enough free heap or UseDisk=True all screens are stored virtually to disk. This
method isn't very fast, of course, but it helps you to save heap.

Use this Unit as follows:

Program ThisIsMyProgram;
Uses Screen;
begin
  InitPages(5);        { initialize 5 pages }
  {...}                { this is on you }
end.
*)
