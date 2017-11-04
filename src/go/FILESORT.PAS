{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit FileSort;

interface

procedure fsSortFileAreas(Par : String);
procedure fsSortTetrisScores;

implementation

uses Dos,
     Global, FileArea, Strings, DateTime, Output, Input, Misc;


procedure fsSortFileAreas(Par : String);
var fD : file of tFileRec;
    bubblesortend : Integer;
    Temp : tfileRec;
    I : LongInt;

function Precedes (A, B : tFileRec) : boolean;
var big : Boolean;
begin
   big := True;
   case fArea^.SortType of
  sortFilename : big := a.Filename <= b.Filename;
 sortExtension : big := strFileExt(a.Filename) <= strFileExt(b.Filename);
      sortSize : big := a.Size <= b.Size;
      sortDate : big := dtDatetoJulian(a.Date) <= dtDatetoJulian(b.Date);
    sortULDate : big := dtDatetoJulian(a.ulDate) <= dtDatetoJulian(b.ulDate);
  sortUploader : big := a.Uploader <= b.Uploader;
 sortDownloads : big := a.Downloads <= b.Downloads;
   end;
   if not fArea^.SortAcen then big := not big;
   Precedes := big;
end;

procedure Swap (Index1, Index2 : Integer; Temp1, Temp2 : tFileRec);
    begin {Swap}
        Seek (fD, Index1);
        Write (fD, Temp2);
        Seek (fD, Index2);
        Write (fD, Temp1);
    end; {Swap}
procedure ShellSortInsertion (NumVals : Integer);
var
    EleDist : Integer;
    Temp1, Temp2 : tFileRec;
    procedure SegmentedInsertion (N, K : Integer);
    var
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
begin {ShellSortInsertion}
    EleDist :=  NumVals div 2;
    while EleDist > 0 do
        begin
            SegmentedInsertion (NumVals, EleDist);
            EleDist := EleDist div 2;
        end;
end; {ShellSortInsertion}

procedure fsSortFileArea;
begin
   Assign(fD,Cfg^.pathData+fArea^.Filename+extFileDir);
   {$I-}
   Reset(fD);
   {$I+}
   if ioResult <> 0 then Exit;
   oStr(strCode(strCode(mStr(strFaSortStart),1,fArea^.Name),2,St(fArea^.Files)));
   ShellSortInsertion(FileSize(fD));
   Close(fD);
   oStrLn(strCode(strCode(mStr(strFaSortEnd),1,fArea^.Name),2,St(fArea^.Files)));
end;

{procedure fsSortfileAreas(Par : String);}
var F : tFileRec;
    All : Boolean; Num : Word; oldArea : Word;

begin
   oDnLn(1);
   oldArea := User^.curFileArea;
   All := False;
   Num := 0;
   if Par <> '' then
   begin
      Par := UpStr(Par);
      All := (Par[1] = 'A');
      if not All then Num := StrToInt(Par);
   end;
   if (not All) and (Num = 0) then
   begin
      oString(strFaSortAskAll);
      All := iYesNo(True);
      if not All then Num := User^.curFileArea;
      oDnLn(1);
   end;

   if (not All) then
   begin
      User^.curFileArea := Num;
      faLoad;
      fsSortFileArea;
   end else
   for Num := 1 to numFileArea do
   begin
      User^.curFileArea := Num;
      faLoad;
      if ((faIsSponsor) or (acsOk(Cfg^.acsCoSysOp))) and
         (fArea^.SortType <> sortNone) then fsSortFileArea;
   end;

   User^.curFileArea := oldArea;
   faLoad;
end;



procedure fsSortTetrisScores;
var fD : file of tTetrisHiRec;
    bubblesortend : Integer;
    Temp : tTetrisHiRec;
    I : LongInt;

function Precedes (A, B : tTetrisHiRec) : boolean;
begin
   Precedes := (a.Score >= b.Score) and (a.Level <> 0);
end;

procedure Swap (Index1, Index2 : Integer; Temp1, Temp2 : tTetrisHiRec);
    begin {Swap}
        Seek (fD, Index1);
        Write (fD, Temp2);
        Seek (fD, Index2);
        Write (fD, Temp1);
    end; {Swap}
procedure ShellSortInsertion (NumVals : Integer);
var
    EleDist : Integer;
    Temp1, Temp2 : tTetrisHiRec;
    procedure SegmentedInsertion (N, K : Integer);
    var
        J, L : Integer;
    begin {SegmentedInsertion}
        for L := K + 1 to N do
            begin
                J := L - K;
                while J > 0 do
                    begin
                        Seek (fD, J+K-1);
                        Read (fD, Temp1);
                        Seek (fD, J-1);
                        Read (fD, Temp2);
                        if Precedes (Temp1, Temp2) then
                            begin
                                Swap (J+K-1, J-1, Temp1, Temp2);
                                J := J - K;
                            end
                        else
                            J := 0;
                    end;
            end;
    end; {SegmentedInsertion}
begin {ShellSortInsertion}
    EleDist :=  NumVals div 2;
    while EleDist > 0 do
        begin
            SegmentedInsertion (NumVals, EleDist);
            EleDist := EleDist div 2;
        end;
end; {ShellSortInsertion}

begin
   Assign(fD,Cfg^.pathData+fileTetris);
   {$I-}
   Reset(fD);
   {$I+}
   if ioResult <> 0 then Exit;
   ShellSortInsertion(FileSize(fD));
   Close(fD);
end;

end.
