unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Windows, SysUtils, Classes, LCLType, LCLProc,
  Forms, Controls, StdCtrls, ExtCtrls, Dialogs, Menus,
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
    PopupLexers: TPopupMenu;
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
    procedure MenuLexerClick(Sender: TObject);
    procedure MsgStatus(const AMsg: string);
    procedure StatusPanelClick(Sender: TObject; AIndex: Integer);
    procedure UpdateMenuLexersTo(AMenu: TMenuItem);
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

const
  StatusbarIndex_Caret = 0;
  StatusbarIndex_LineEnds = 1;
  StatusbarIndex_Lexer = 2;
  StatusbarIndex_Wrap = 3;
  StatusbarIndex_Message = 4;

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

  UpdateMenuLexersTo(PopupLexers.Items);
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
  Statusbar.OnPanelClick:= @StatusPanelClick;

  Statusbar.AddPanel(150, saMiddle);
  Statusbar.AddPanel(50, saMiddle);
  Statusbar.AddPanel(150, saMiddle);
  Statusbar.AddPanel(50, saMiddle);
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
  StatusBar.Captions[StatusbarIndex_Message]:= AMsg;
  StatusBar.Invalidate;
end;

procedure TfmMain.UpdateStatusbar;
var
  Caret: TATCaretItem;
  S: string;
begin
  Caret:= ed.Carets[0];
  StatusBar.Captions[StatusbarIndex_Caret]:= Format('Line %d: Col %d', [Caret.PosY+1, Caret.PosX+1]);

  case ed.Strings.Endings of
    cEndWin: S:= 'Win';
    cEndUnix: S:= 'Unix';
    cEndMac: S:= 'MacOS9';
    else S:= '?';
  end;
  StatusBar.Captions[StatusbarIndex_LineEnds]:= S;

  if Assigned(Adapter.Lexer) then
    S:= Adapter.Lexer.LexerName
  else
    S:= '(no lexer)';
  StatusBar.Captions[StatusbarIndex_Lexer]:= S;

  case ed.OptWrapMode of
    cWrapOff: S:= 'no wrap';
    cWrapOn: S:= 'wrap';
    cWrapAtMargin: S:= 'wrap mrg';
  end;
  StatusBar.Captions[StatusbarIndex_Wrap]:= S;
end;


procedure TfmMain.UpdateMenuLexersTo(AMenu: TMenuItem);
var
  sl: TStringList;
  an: TecSyntAnalyzer;
  mi, mi0: TMenuItem;
  ch, ch0: char;
  i: integer;
begin
  if AMenu=nil then exit;
  AMenu.Clear;

  ch0:= '?';
  mi0:= nil;

  mi:= TMenuItem.Create(self);
  mi.caption:= '(no lexer)';
  mi.OnClick:= @MenuLexerClick;
  AMenu.Add(mi);

  sl:= TStringList.Create;
  try
    //make stringlist of all lexers
    for i:= 0 to AppManager.AnalyzerCount-1 do
    begin
      an:= AppManager.Analyzers[i];
      if not an.Internal then
        sl.AddObject(an.LexerName, an);
    end;
    sl.Sort;

    {
    if not UiOps.LexerMenuGrouped then
    begin
      for i:= 0 to sl.count-1 do
      begin
        if sl[i]='' then Continue;
        mi:= TMenuItem.create(self);
        mi.caption:= sl[i];
        mi.tag:= ptrint(sl.Objects[i]);
        mi.OnClick:= @MenuLexClick;
        AMenu.Add(mi);
      end;
    end
    else
    }
    //grouped view
    for i:= 0 to sl.Count-1 do
    begin
      if sl[i]='' then Continue;
      ch:= UpCase(sl[i][1]);
      if ch<>ch0 then
      begin
        ch0:= ch;
        mi0:= TMenuItem.create(self);
        mi0.Caption:= ch;
        AMenu.Add(mi0);
      end;

      mi:= TMenuItem.Create(self);
      mi.Caption:= sl[i];
      mi.Tag:= PtrInt(sl.Objects[i]);
      mi.OnClick:= @MenuLexerClick;
      if Assigned(mi0) then
        mi0.add(mi)
      else
        AMenu.Add(mi);
    end;
  finally
    sl.Free;
  end;
end;

procedure TfmMain.MenuLexerClick(Sender: TObject);
var
  an: TecSyntAnalyzer;
begin
  an:= TecSyntAnalyzer((Sender as TComponent).Tag);
  Adapter.Lexer:= an;
  UpdateStatusbar;
end;

procedure TfmMain.StatusPanelClick(Sender: TObject; AIndex: Integer);
begin
  if AIndex=StatusbarIndex_Lexer then
  begin
    PopupLexers.PopUp;
  end
  else
  if AIndex=StatusbarIndex_Wrap then
  begin
    if ed.OptWrapMode<>cWrapOff then
      ed.OptWrapMode:= cWrapOff
    else
      ed.OptWrapMode:= cWrapOn;
    UpdateStatusbar;
  end;
end;

end.
