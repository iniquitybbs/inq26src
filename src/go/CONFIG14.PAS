{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,D-,L-,N-,E+}
unit Config14;

interface

procedure cfgStatEditor;

implementation

uses Dos,
     Global, Strings, Config, Output, Input, Menus, Files, Misc, Logs, Stats;

procedure cfgStatEditor;
var Sta : tStatRec;
begin
   logWrite('*Statistics edit');
   statLoad;
   Sta := Stat^;
   cfgOver := False;
   cfgDraw := True;
   repeat
      cfgInit(bbsTitle+' System Statistics Editor');
      cfgCol := 25;
      cfgItem('A First Day',12,Sta.FirstDay,
              'Date [mm/dd/yy] of the first day the BBS was on online');
      cfgItem('B Calls',6,St(Sta.Calls),
              'Total number of calls to the board');
      cfgItem('C Posts',6,St(Sta.Posts),
              'System''s total number of public posts');
      cfgItem('D Email',6,St(Sta.Email),
              'Total number of email sent');
      cfgItem('E Uploads',6,St(Sta.Uploads),
              'Total number of uploads');
      cfgItem('F Downloads',6,St(Sta.Downloads),
              'Total number of downloads');
      cfgItem('G Uploaded Kb',6,St(Sta.UploadKb),
              'Total number of uploaded kilobytes');
      cfgItem('H Downloaded Kb',6,St(Sta.DownloadKb),
              'Total number of downloaded kilobytes');
      cfgBar;
      cfgDrawAllItems;
      cfgPromptCommand;
      case cfgKey of
        'A' : begin
                 cfgReadDate;
                 Sta.FirstDay := cfgRead;
                 cfgSetItem(Sta.FirstDay);
              end;
        'B' : begin
                 cfgReadInfo(St(Sta.Calls),inUpper,chNumeric,'',True);
                 Sta.Calls := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Sta.Calls));
              end;
        'C' : begin
                 cfgReadInfo(St(Sta.Posts),inUpper,chNumeric,'',True);
                 Sta.Posts := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Sta.Posts));
              end;
        'D' : begin
                 cfgReadInfo(St(Sta.Email),inUpper,chNumeric,'',True);
                 Sta.Email := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Sta.Email));
              end;
        'E' : begin
                 cfgReadInfo(St(Sta.Uploads),inUpper,chNumeric,'',True);
                 Sta.Uploads := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Sta.Uploads));
              end;
        'F' : begin
                 cfgReadInfo(St(Sta.Downloads),inUpper,chNumeric,'',True);
                 Sta.Downloads := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Sta.Downloads));
              end;
        'G' : begin
                 cfgReadInfo(St(Sta.UploadKb),inUpper,chNumeric,'',True);
                 Sta.UploadKb := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Sta.UploadKb));
              end;
        'H' : begin
                 cfgReadInfo(St(Sta.DownloadKb),inUpper,chNumeric,'',True);
                 Sta.DownloadKb := mClip(StrToInt(cfgRead),0,64000);
                 cfgSetItem(St(Sta.DownloadKb));
              end;
      end;
   until (HangUp) or (cfgDone);
   cfgInfo('Save system statistics? ');
   if iYesNo(True) then
   begin
      Stat^ := Sta;
      statSave;
   end;
   cfgDone := False;
end;

end.