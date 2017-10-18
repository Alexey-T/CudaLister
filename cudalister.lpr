library CudaLister;

{$mode objfpc}{$H+}

uses
  Windows, SysUtils, Forms, Interfaces,
  Form_Main, FileUtil;

const
  cDetectString: string = '';

procedure ListGetDetectString(DetectString: PChar; MaxLen: integer); stdcall;
begin
  StrLCopy(DetectString, PChar(cDetectString), MaxLen);
end;

function ListLoad(ListerWin: HWND; FileName: PChar; ShowFlags: integer): HWND; stdcall;
begin
  if not FileExists(FileName) then exit(0);
  if FileSize(FileName) >= 2*1024*1024 then exit(0);

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
   
