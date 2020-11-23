unit file_proc;

{$mode objfpc}{$H+}

interface

uses
  Windows,
  Classes, SysUtils, FileUtil,
  ATStrings,
  ATStringProc_UTF8Detect;

function IsFileTooBig(const fn: string): boolean;
function IsFileText(const fn: string): boolean;

function _GetDllFilename: string;

var
  OptMaxFileSizeMb: integer = 2;

implementation

function IsFileTooBig(const fn: string): boolean;
begin
  Result:= FileSize(fn) >= OptMaxFileSizeMb*(1024*1024);
end;

type
  TFreqTable = array[$80 .. $FF] of Integer;

function IsAsciiControlChar(n: integer): boolean; inline;
const
  cAllowedControlChars: set of byte = [
    7, //Bell
    9,
    10,
    13,
    12, //FormFeed
    26 //EOF
    ];
begin
  Result:= (n < 32) and not (byte(n) in cAllowedControlChars);
end;

function AppIsFileContentText(const fn: string; BufSizeKb: integer;
  BufSizeWords: integer;
  DetectOEM: boolean): Boolean;
const
  cBadBytesAtEndAllowed = 2;
var
  Buffer: PAnsiChar;
  BufSize, BytesRead, i: DWORD;
  n: Integer;
  Table: TFreqTable;
  TableSize: Integer;
  Str: TFileStream;
  IsLE: boolean;
  bReadAllFile: boolean;
begin
  Result:= False;
  //IsOEM:= False;
  Str:= nil;
  Buffer:= nil;

  if BufSizeKb<=0 then Exit;
  BufSize:= BufSizeKb*1024;

  //Init freq table
  TableSize:= 0;
  FillChar(Table, SizeOf(Table), 0);

  try
    try
      Str:= TFileStream.Create(fn, fmOpenRead or fmShareDenyNone);
    except
      exit(false);
    end;

    if Str.Size<=2 then exit(true);
    if DetectStreamUtf8NoBom(Str, BufSizeKb)=TBufferUTF8State.u8sYes then exit(true);
    if DetectStreamUtf16NoBom(Str, BufSizeWords, IsLE) then exit(true);
    Str.Position:= 0;

    GetMem(Buffer, BufSize);
    FillChar(Buffer^, BufSize, 0);

    BytesRead:= Str.Read(Buffer^, BufSize);
    if BytesRead > 0 then
      begin
        bReadAllFile:= BytesRead=Str.Size;

        //Test UTF16 signature
        if ((Buffer[0]=#$ff) and (Buffer[1]=#$fe)) or
          ((Buffer[0]=#$fe) and (Buffer[1]=#$ff)) then
         Exit(True);

        Result:= True;
        for i:= 0 to BytesRead - 1 do
        begin
          n:= Ord(Buffer[i]);

          //If control chars present, then non-text
          if IsAsciiControlChar(n) then
            //ignore bad bytes at the end, https://github.com/Alexey-T/CudaText/issues/2959
            if not (bReadAllFile and (i>=BytesRead-cBadBytesAtEndAllowed)) then
            begin
              Result:= False;
              Break
            end;

          //Calculate freq table
          if DetectOEM then
            if (n >= Low(Table)) and (n <= High(Table)) then
            begin
              Inc(TableSize);
              Inc(Table[n]);
            end;
        end;
      end;

    //Analize table
    if DetectOEM then
      if Result and (TableSize > 0) then
        for i:= Low(Table) to High(Table) do
        begin
          Table[i]:= Table[i] * 100 div TableSize;
          if ((i >= $B0) and (i <= $DF)) or (i = $FF) or (i = $A9) then
            if Table[i] >= 18 then
            begin
              //IsOEM:= True;
              Break
            end;
        end;

  finally
    if Assigned(Buffer) then
      FreeMem(Buffer);
    if Assigned(Str) then
      FreeAndNil(Str);
  end;
end;

function IsFileText(const fn: string): boolean;
var
  bOem: boolean;
begin
  Result:= AppIsFileContentText(fn, 64, 2*1024, bOem);
end;

function _GetDllFilename: string;
var
  S: WideString;
begin
  SetLength(S, MAX_PATH);
  SetLength(S, GetModuleFileNameW(HINSTANCE, PWChar(S), Length(S)));
  Result:= UTF8Encode(S);
end;


end.

