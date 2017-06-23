library CudaLister;

{$mode objfpc}{$H+}

uses
  Windows, SysUtils, Forms, Interfaces, form_main
  { you can add units after this };

const
  cDetectString: string = '';

procedure ListGetDetectString(DetectString: PChar; MaxLen: integer); stdcall;
begin
  StrLCopy(DetectString, PChar(cDetectString), MaxLen);
end;

function ListLoad(ListerWin: HWND; FileName: PChar; ShowFlags: integer): HWND; stdcall;
begin
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
   
