unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Windows, SysUtils, Classes, LCLType, LCLProc,
  Forms, Controls, StdCtrls, ExtCtrls, Dialogs,
  ATSynEdit;

type
  { TfmMain }

  TfmMain = class(TForm)
    ed: TATSynEdit;
    PanelAll: TPanel;
    procedure edKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { private declarations }
    FTotCmdWin: HWND;    // handle of TotalCommander window
    FParentWin: HWND;    // handle of Lister window
    FQuickView: Boolean; // Ctrl+Q panel
    FPrevKeyCode: word;
    FPrevKeyShift: TShiftState;
    FPrevKeyTick: Qword;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { public declarations }
    constructor CreateParented(AParentWindow: HWND);
    class function PluginShow(ListerWin: HWND; FileName: string): HWND;
    class function PluginHide(PluginWin: HWND): HWND;
    procedure FileOpen(const FileName: string);
  end;

implementation

{$R *.lfm}

{ TfmMain }

procedure TfmMain.edKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
const
  cMaxDupTime = 100;
var
  MaybeDups: boolean;
begin
  //to ignore duplicate keys (some Lazarus bug)
  MaybeDups:= (Key in [
    VK_LEFT, VK_RIGHT, VK_DOWN, VK_UP,
    VK_BACK, VK_DELETE,
    VK_RETURN,
    VK_PRIOR, VK_NEXT
    ]) or
    (ssCtrl in Shift) or
    (ssAlt in Shift);

  if MaybeDups then
    if (Key=FPrevKeyCode) and
      (Shift=FPrevKeyShift) and
      (GetTickCount64-FPrevKeyTick<=cMaxDupTime) then
      begin Key:= 0; exit; end;

  FPrevKeyCode:= Key;
  FPrevKeyShift:= Shift;
  FPrevKeyTick:= GetTickCount64;
end;

procedure TfmMain.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := (WS_CHILD or WS_MAXIMIZE) and not WS_CAPTION and not WS_BORDER;
  Params.WindowClass.cbWndExtra := SizeOf(PtrInt);
end;

constructor TfmMain.CreateParented(AParentWindow: HWND);
begin
  inherited CreateParented(AParentWindow);
  FTotCmdWin  := FindWindow('TTOTAL_CMD', nil);
  FParentWin  := AParentWindow;
  FQuickView  := Windows.GetParent(FParentWin) <> 0;
end;

class function TfmMain.PluginShow(ListerWin: HWND; FileName: string): HWND;
var
  fmMain: TfmMain;
begin
  fmMain := nil;
  try
    fmMain := TfmMain.CreateParented(ListerWin);
    fmMain.FileOpen(FileName);
    fmMain.Show;
    SetWindowLongPTR(fmMain.Handle, GWL_USERDATA, PtrInt(fmMain));
    // set focus to our window
    if not fmMain.FQuickView then
    begin
      PostMessage(fmMain.Handle, WM_SETFOCUS, 0, 0);
      fmMain.ed.SetFocus;
    end;
    Result := fmMain.Handle;
  except
    if Assigned(fmMain) then
      fmMain.Free;
    Result := 0;
  end;
end;

class function TfmMain.PluginHide(PluginWin: HWND): HWND;
var
  fmMain: TfmMain;
begin
  Result := 0;
  fmMain := TfmMain(GetWindowLongPTR(PluginWin, GWL_USERDATA));
  try
    fmMain.Close;
    fmMain.Free;
  except
  end;
end;

procedure TfmMain.FileOpen(const FileName: string);
begin
  ed.LoadFromFile(FileName);
  ed.DoCaretSingle(0, 0);
end;


end.
