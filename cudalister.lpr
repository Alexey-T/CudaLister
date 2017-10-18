library CudaLister;

{$mode objfpc}{$H+}

uses
  Windows, SysUtils, Forms, Interfaces,
  Form_Main, FileUtil, file_proc;

const
  cDetectString: string = '';

procedure ListGetDetectString(DetectString: PChar; MaxLen: integer); stdcall;
begin
  StrLCopy(DetectString, PChar(cDetectString), MaxLen);
end;

function ListLoad(ListerWin: HWND; FileName: PChar; ShowFlags: integer): HWND; stdcall;
var
  bOem: boolean;
begin
  Result:= 0;
  if not FileExists(FileName) then exit;
  if FileSize(FileName) >= 2*1024*1024 then exit;
  if not IsFileContentText(FileName, 4*1024, false, bOem) then exit;

  Result := TfmMain.PluginShow(ListerWin, FileName);
end;

procedure ListCloseWindow(PluginWin: HWND); stdcall;
begin
  TfmMain.PluginHide(PluginWin);
end;

exports
  ListGetDetectString,
  ListLoad,
  ListCloseWindow;

begin
  Application.Initialize;
end.
   
