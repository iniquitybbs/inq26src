{$F-,A+,O+,G+,R-,S+,I+,Q-,V-,B-,X+,T-,P-,N-,E+}
unit Errors;

interface

function errorMessage(code : integer) : string;

implementation

function errorMessage(code : integer) : string;
var msg : string;
begin
   case code of
      $00 : msg := 'No error';
      $01 : msg := 'Invalid DOS function number';
      $02 : msg := 'File not found';
      $03 : msg := 'Path not found';
      $04 : msg := 'Too many open files';
      $05 : msg := 'File access denied';
      $06 : msg := 'Invalid file handle';
      $07 : msg := 'Memory control block destroyed';
      $08 : msg := 'Not enough memory';
      $09 : msg := 'Invalid memory block address';
      $0A : msg := 'Environment scrambled';
      $0B : msg := 'Bad program EXE file';
      $0C : msg := 'Invalid file access mode';
      $0D : msg := 'Invalid data';
      $0E : msg := 'Unknown unit';
      $0F : msg := 'Invalid drive number';
      $10 : msg := 'Cannot remove current directory';
      $11 : msg := 'Cannot rename across drives';
      $12 : msg := 'Disk read/write error';
      $13 : msg := 'Disk write-protected';
      $14 : msg := 'Unknown unit';
      $15 : msg := 'Drive not ready';
      $16 : msg := 'Unknown command';
      $17 : msg := 'Data CRC error';
      $18 : msg := 'Bad request structure length';
      $19 : msg := 'Seek error';
      $1A : msg := 'Unknown media type';
      $1B : msg := 'Sector not found';
      $1C : msg := 'Printer out of paper';
      $1D : msg := 'Disk write error';
      $1E : msg := 'Disk read error';
      $1F : msg := 'General failure';
      $20 : msg := 'Sharing violation';
      $21 : msg := 'Lock violation';
      $22 : msg := 'Invalid disk change';
      $23 : msg := 'File control block gone';
      $24 : msg := 'Sharing buffer exceeded';
      $32 : msg := 'Unsupported network request';
      $33 : msg := 'Remote machine not listening';
      $34 : msg := 'Duplicate network name';
      $35 : msg := 'Network name not found';
      $36 : msg := 'Network busy';
      $37 : msg := 'Device no longer exists on network';
      $38 : msg := 'NetBIOS command limit exceeded';
      $39 : msg := 'Adapter hardware error';
      $3A : msg := 'Incorrect response from network';
      $3B : msg := 'Unexpected network error';
      $3C : msg := 'Remote adapter incompatible';
      $3D : msg := 'Print queue full';
      $3E : msg := 'No space for print file';
      $3F : msg := 'Print file cancelled';
      $40 : msg := 'Network name deleted';
      $41 : msg := 'Network access denied';
      $42 : msg := 'Incorrect network device type';
      $43 : msg := 'Network name not found';
      $44 : msg := 'Network name limit exceeded';
      $45 : msg := 'NetBIOS session limit exceeded';
      $46 : msg := 'Filer sharing temporarily paused';
      $47 : msg := 'Network request not accepted';
      $48 : msg := 'Print or disk file paused';
      $50 : msg := 'File already exists';
      $52 : msg := 'Cannot make directory';
      $53 : msg := 'Fail on critical error';
      $54 : msg := 'Too many redirections';
      $55 : msg := 'Duplicate redirection';
      $56 : msg := 'Invalid password';
      $57 : msg := 'Invalid parameter';
      $58 : msg := 'Network device fault';
      $59 : msg := 'Function not supported by network';
      $5A : msg := 'Required component not installed';

       94 : msg := 'EMS memory swap error';
       98 : msg := 'Disk full';
      100 : msg := 'Disk read error';
      101 : msg := 'Disk write error';
      102 : msg := 'File not assigned';
      103 : msg := 'File not open';
      104 : msg := 'File not open for input';
      105 : msg := 'File not open for output';
      106 : msg := 'Invalid numeric format';
      150 : msg := 'Disk is write protected';
      151 : msg := 'Unknown unit';
      152 : msg := 'Drive not ready';
      153 : msg := 'Unknown command';
      154 : msg := 'CRC error in data';
      155 : msg := 'Bad drive request structure length';
      156 : msg := 'Disk seek error';
      157 : msg := 'Unknown media type';
      158 : msg := 'Sector not found';
      159 : msg := 'Printer out of paper';
      160 : msg := 'Device write fault';
      161 : msg := 'Device read fault';
      162 : msg := 'Hardware failure';
      163 : msg := 'Sharing confilct';
      200 : msg := 'Division by zero';
      201 : msg := 'Range check error';
      202 : msg := 'Stack overflow error';
      203 : msg := 'Heap overflow error';
      204 : msg := 'Invalid pointer operation';
      205 : msg := 'Floating point overflow';
      206 : msg := 'Floating point underflow';
      207 : msg := 'Invalid floating point operation';
      390 : msg := 'Serial port timeout';
      399 : msg := 'Serial port not responding';
     1008 : msg := 'EMS memory swap error'
       else msg := 'Unknown error';
   end;
   errorMessage := msg;
end;

end.
