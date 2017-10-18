unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Windows, SysUtils, Classes, LCLType, LCLProc,
  Forms, Controls, StdCtrls, ExtCtrls, Dialogs, ComCtrls,
  ATSynEdit,
  ATSynEdit_Carets,
  ATSynEdit_Adapter_EControl,
  ATStrings,
  ATStringProc,
  ATStatusbar,
  ecSyntAnal,
  proc_lexer,
  IniFiles, FileUtil;

type
  { TfmMain }

  TfmMain = class(TForm)
    ed: TATSynEdit;
    PanelAll: TPanel;
    procedure edChangeCaretPos(Sender: TObject);
    procedure edKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
    FTotCmdWin: HWND;    // handle of TotalCommander window
    FParentWin: HWND;    // handle of Lister window
    FQuickView: Boolean; // Ctrl+Q panel
    FPrevKeyCode: word;
    FPrevKeyShift: TShiftState;
    FPrevKeyTick: Qword;
    Statusbar: TATStatus;
    AppManager: TecSyntaxManager;
    Adapter: TATAdapterEControl;
    procedure LoadLexerLib;
    procedure MsgStatus(const AMsg: string);
    procedure UpdateStatusbar;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { public declarations }
    constructor CreateParented(AParentWindow: HWND);
    class function PluginShow(ListerWin: HWND; FileName: string): HWND;
    class function PluginHide(PluginWin: HWND): HWND;
    procedure FileOpen(const AFileName: string);
  end;

implementation

{$R *.lfm}

procedure TfmMain.LoadLexerLib;
var
  dir, fn, lexname: string;
  L: TStringlist;
  an: TecSyntAnalyzer;
  ini: TIniFile;
  i, j: integer;
begin
  AppManager.Clear;

  //load .lcf files to lib
  dir:= ExtractFileDir(GetModuleName(HINSTANCE))+'\lexers';
  L:= TStringlist.Create;
  try
    FindAllFiles(L, dir, '*.lcf', false);
    L.Sort;

    if L.Count=0 then
    begin
      //MsgStatusAlt('Cannot find lexer files: data/lexlib/*.lcf', 3);
      exit
    end;

    for i:= 0 to L.Count-1 do
    begin
      an:= AppManager.AddAnalyzer;
      an.LoadFromFile(L[i]);
    end;
  finally
    FreeAndNil(L);
  end;

  //correct sublexer links
  for i:= 0 to AppManager.AnalyzerCount-1 do
  begin
    an:= AppManager.Analyzers[i];
    fn:= dir+'\'+an.LexerName+'.cuda-lexmap';
    if FileExists(fn) then
    begin
      ini:= TIniFile.Create(fn);
      try
        for j:= 0 to an.SubAnalyzers.Count-1 do
        begin
          lexname:= ini.ReadString('ref', IntToStr(j), '');
          if lexname<>'' then
            an.SubAnalyzers[j].SyntAnalyzer:= AppManager.FindAnalyzer(lexname);
        end;
      finally
        FreeAndNil(ini);
      end;
    end;
  end;
end;


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

procedure TfmMain.edChangeCaretPos(Sender: TObject);
begin
  UpdateStatusbar;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  Statusbar:= TATStatus.Create(Self);
  Statusbar.Parent:= Self;
  Statusbar.Align:= alBottom;
  Statusbar.IndentLeft:= 1;

  Statusbar.AddPanel(150, saMiddle);
  Statusbar.AddPanel(50, saMiddle);
  Statusbar.AddPanel(150, saMiddle);
  Statusbar.AddPanel(1600, saLeft);

  AppManager:= TecSyntaxManager.Create(Self);
  LoadLexerLib;

  Adapter:= TATAdapterEControl.Create(Self);
  Adapter.DynamicHiliteEnabled:= false;
  Adapter.DynamicHiliteMaxLines:= 5000;
  Adapter.EnabledLineSeparators:= false;
  Adapter.AddEditor(ed);
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

procedure TfmMain.FileOpen(const AFileName: string);
begin
  ed.LoadFromFile(AFileName);
  ed.DoCaretSingle(0, 0);
  ed.ModeReadOnly:= true;

  Adapter.Lexer:= DoFindLexerForFilename(AppManager, AFileName);
  UpdateStatusbar;
end;

procedure TfmMain.MsgStatus(const AMsg: string);
begin
  StatusBar.GetPanelData(StatusBar.PanelCount-1).ItemCaption:= AMsg;
  StatusBar.Invalidate;
end;

procedure TfmMain.UpdateStatusbar;
var
  Caret: TATCaretItem;
  Ends: TATLineEnds;
  S: string;
begin
  Caret:= ed.Carets[0];
  Ends:= ed.Strings.Endings;

  StatusBar.GetPanelData(0).ItemCaption:= Format('Line %d: Col %d', [Caret.PosY+1, Caret.PosX+1]);

  case Ends of
    cEndWin: S:= 'Win';
    cEndUnix: S:= 'Unix';
    cEndMac: S:= 'MacOS9';
    else S:= '?';
  end;
  StatusBar.GetPanelData(1).ItemCaption:= S;

  if Assigned(Adapter.Lexer) then
    S:= Adapter.Lexer.LexerName
  else
    S:= '(no lexer)';
  StatusBar.GetPanelData(2).ItemCaption:= S;

  StatusBar.Invalidate;
end;


end.
