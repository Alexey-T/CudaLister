library CudaLister;

{$mode objfpc}{$H+}

uses
  Windows, SysUtils, Forms, Interfaces,
  FileUtil,
  form_main, file_proc;

const
  cDetectString: string = '';

procedure ListGetDetectString(DetectString: PChar; MaxLen: integer); stdcall;
begin
  StrLCopy(DetectString, PChar(cDetectString), MaxLen);
end;

function ListLoadW(ListerWin: HWND; FileNamePtr: PWideChar; ShowFlags: integer): HWND; stdcall;
var
  fn: string;
  bOem: boolean;
begin
  Result:= 0;
  fn:= UTF8Encode(WideString(FileNamePtr));
  if not FileExists(fn) then exit;
  if FileSize(fn) >= 2*1024*1024 then exit;
  if not IsFileContentText(fn, 4*1024, false, bOem) then exit;

  Result := TfmMain.PluginShow(ListerWin, fn);
end;

function ListLoad(ListerWin: HWND; FileNamePtr: PChar; ShowFlags: integer): HWND; stdcall;
begin
  Result:= ListLoadW(ListerWin, PWideChar(WideString(string(FileNamePtr))), ShowFlags);
end;

procedure ListCloseWindow(PluginWin: HWND); stdcall;
begin
  TfmMain.PluginHide(PluginWin);
end;

type
  TListDefaultParamStruct = record
    size,
    PluginInterfaceVersionLow,
    PluginInterfaceVersionHi: DWORD;
    DefaultIniName: array[0..MAX_PATH-1] of AnsiChar;
  end;
  pListDefaultParamStruct = ^TListDefaultParamStruct;

procedure ListSetDefaultParams(dps: pListDefaultParamStruct); stdcall;
begin
  ListerIniFilename:= string(dps^.DefaultIniName);
end;

exports
  ListSetDefaultParams,
  ListGetDetectString,
  ListLoad,
  ListLoadW,
  ListCloseWindow;

begin
  Application.Initialize;
end.
   
