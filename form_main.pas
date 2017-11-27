unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Windows, SysUtils, Classes, LCLType, LCLProc,
  Forms, Controls, StdCtrls, ExtCtrls, Dialogs, Menus,
  IniFiles, StrUtils,
  ATSynEdit,
  ATSynEdit_Carets,
  ATSynEdit_Adapter_EControl,
  ATSynEdit_Commands,
  ATSynEdit_Finder,
  ATStrings,
  ATStringProc,
  ATStatusbar,
  ec_SyntAnal,
  ec_proc_lexer,
  file_proc,
  form_options,
  FileUtil;

type
  { TfmMain }

  TfmMain = class(TForm)
    ed: TATSynEdit;
    mnuTextPaste: TMenuItem;
    mnuTextReadonly: TMenuItem;
    mnuTextGoto: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    mnuOptions: TMenuItem;
    mnuTextCopy: TMenuItem;
    mnuTextSel: TMenuItem;
    PanelAll: TPanel;
    PopupLexers: TPopupMenu;
    PopupEnc: TPopupMenu;
    PopupText: TPopupMenu;
    TimerStatusbar: TTimer;
    procedure edChangeCaretPos(Sender: TObject);
    procedure edKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mnuOptionsClick(Sender: TObject);
    procedure mnuTextCopyClick(Sender: TObject);
    procedure mnuTextGotoClick(Sender: TObject);
    procedure mnuTextPasteClick(Sender: TObject);
    procedure mnuTextReadonlyClick(Sender: TObject);
    procedure mnuTextSelClick(Sender: TObject);
    procedure PopupTextPopup(Sender: TObject);
    procedure TimerStatusbarTimer(Sender: TObject);
  private
    { private declarations }
    FFileName: string;
    FTotalCmdWindow: HWND;
    FListerWindow: HWND;
    FListerQuickView: Boolean;
    FPrevKeyCode: word;
    FPrevKeyShift: TShiftState;
    FPrevKeyTick: Qword;
    Statusbar: TATStatus;
    AppManager: TecSyntaxManager;
    Adapter: TATAdapterEControl;
    //
    procedure ApplyNoCaret;
    procedure FinderFound(Sender: TObject; APos1, APos2: TPoint);
    function GetEncodingName: string;
    procedure LoadLexerLib;
    procedure LoadOptions;
    procedure MenuEncNoReloadClick(Sender: TObject);
    procedure MenuEncWithReloadClick(Sender: TObject);
    procedure MenuLexerClick(Sender: TObject);
    procedure SaveOptions;
    procedure StatusPanelClick(Sender: TObject; AIndex: Integer);
    procedure UpdateMenuEnc(AMenu: TMenuItem);
    procedure UpdateMenuLexersTo(AMenu: TMenuItem);
    procedure UpdateStatusbar;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { public declarations }
    Finder: TATEditorFinder;
    //
    constructor CreateParented(AParentWindow: HWND);
    class function PluginShow(AListerWin: HWND; AFileName: string; AWrapText: boolean): HWND;
    class function PluginHide(APluginWin: HWND): HWND;
    procedure MsgStatus(const AMsg: string);
    procedure FileOpen(const AFileName: string);
    procedure SetWrapMode(AValue: boolean);
    procedure SetEncodingName(const Str: string);
    procedure ToggleWrapMode;
    procedure DoFind(AFindNext, ABack, ACaseSens, AWords: boolean; const AStrFind: Widestring);
  end;

var
  ListerIniFilename: string = '';
  ListerIniSection: string = 'CudaLister';

const
  cEncNameUtf8_WithBom = 'UTF-8 with BOM';
  cEncNameUtf8_NoBom = 'UTF-8';
  cEncNameUtf16LE_WithBom = 'UTF-16 LE with BOM';
  cEncNameUtf16LE_NoBom = 'UTF-16 LE';
  cEncNameUtf16BE_WithBom = 'UTF-16 BE with BOM';
  cEncNameUtf16BE_NoBom = 'UTF-16 BE';
  cEncNameAnsi = 'ANSI';
  cEncNameOem = 'OEM';

  cEncNameCP1250 = 'CP1250';
  cEncNameCP1251 = 'CP1251';
  cEncNameCP1252 = 'CP1252';
  cEncNameCP1253 = 'CP1253';
  cEncNameCP1254 = 'CP1254';
  cEncNameCP1255 = 'CP1255';
  cEncNameCP1256 = 'CP1256';
  cEncNameCP1257 = 'CP1257';
  cEncNameCP1258 = 'CP1258';
  cEncNameCP437 = 'CP437';
  cEncNameCP850 = 'CP850';
  cEncNameCP852 = 'CP852';
  cEncNameCP866 = 'CP866';
  cEncNameCP874 = 'CP874';
  cEncNameISO1 = 'ISO-8859-1';
  cEncNameISO2 = 'ISO-8859-2';
  cEncNameMac = 'Macintosh';
  cEncNameCP932 = 'CP932';
  cEncNameCP936 = 'CP936';
  cEncNameCP949 = 'CP949';
  cEncNameCP950 = 'CP950';

implementation

{$R *.lfm}

const
  StatusbarIndex_Caret = 0;
  StatusbarIndex_Enc = 1;
  StatusbarIndex_LineEnds = 2;
  StatusbarIndex_Lexer = 3;
  StatusbarIndex_Wrap = 4;
  StatusbarIndex_Message = 5;

type
  TAppEncodingRecord = record
    Sub,
    Name,
    ShortName: string;
  end;

const
  AppEncodings: array[0..31] of TAppEncodingRecord = (
    (Sub: ''; Name: cEncNameUtf8_NoBom; ShortName: 'utf8'),
    (Sub: ''; Name: cEncNameUtf8_WithBom; ShortName: 'utf8_bom'),
    (Sub: ''; Name: cEncNameUtf16LE_NoBom; ShortName: 'utf16le'),
    (Sub: ''; Name: cEncNameUtf16LE_WithBom; ShortName: 'utf16le_bom'),
    (Sub: ''; Name: cEncNameUtf16BE_NoBom; ShortName: 'utf16be'),
    (Sub: ''; Name: cEncNameUtf16BE_WithBom; ShortName: 'utf16be_bom'),
    (Sub: ''; Name: cEncNameAnsi; ShortName: 'ansi'),
    (Sub: ''; Name: cEncNameOem; ShortName: 'oem'),
    (Sub: ''; Name: '-'; ShortName: ''),
    (Sub: 'eu'; Name: cEncNameCP1250; ShortName: cEncNameCP1250),
    (Sub: 'eu'; Name: cEncNameCP1251; ShortName: cEncNameCP1251),
    (Sub: 'eu'; Name: cEncNameCP1252; ShortName: cEncNameCP1252),
    (Sub: 'eu'; Name: cEncNameCP1253; ShortName: cEncNameCP1253),
    (Sub: 'eu'; Name: cEncNameCP1257; ShortName: cEncNameCP1257),
    (Sub: 'eu'; Name: '-'; ShortName: ''),
    (Sub: 'eu'; Name: cEncNameCP437; ShortName: cEncNameCP437),
    (Sub: 'eu'; Name: cEncNameCP850; ShortName: cEncNameCP850),
    (Sub: 'eu'; Name: cEncNameCP852; ShortName: cEncNameCP852),
    (Sub: 'eu'; Name: cEncNameCP866; ShortName: cEncNameCP866),
    (Sub: 'eu'; Name: '-'; ShortName: ''),
    (Sub: 'eu'; Name: cEncNameISO1; ShortName: cEncNameISO1),
    (Sub: 'eu'; Name: cEncNameISO2; ShortName: cEncNameISO2),
    (Sub: 'eu'; Name: cEncNameMac; ShortName: 'mac'),
    (Sub: 'mi'; Name: cEncNameCP1254; ShortName: cEncNameCP1254),
    (Sub: 'mi'; Name: cEncNameCP1255; ShortName: cEncNameCP1255),
    (Sub: 'mi'; Name: cEncNameCP1256; ShortName: cEncNameCP1256),
    (Sub: 'as'; Name: cEncNameCP874; ShortName: cEncNameCP874),
    (Sub: 'as'; Name: cEncNameCP932; ShortName: cEncNameCP932),
    (Sub: 'as'; Name: cEncNameCP936; ShortName: cEncNameCP936),
    (Sub: 'as'; Name: cEncNameCP949; ShortName: cEncNameCP949),
    (Sub: 'as'; Name: cEncNameCP950; ShortName: cEncNameCP950),
    (Sub: 'as'; Name: cEncNameCP1258; ShortName: cEncNameCP1258)
  );

function AppEncodingOem: string;
begin
  {$ifdef windows}
  case Windows.GetOEMCP of
    437: Result:= 'CP437';
    850: Result:= 'CP850';
    852: Result:= 'CP852';
    866: Result:= 'CP866';
    874: Result:= 'CP874';
    932: Result:= 'CP932';
    936: Result:= 'CP936';
    949: Result:= 'CP949';
    950: Result:= 'CP950';
    else Result:= 'CP437';
  end;
  {$else}
  Result:= 'CP437';
  {$endif}
end;


{ TfmMain }

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
  dir:= ExtractFileDir(_GetDllFilename)+'\lexers';
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


procedure TfmMain.edKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//
//note: to add reaction to keys, add code after comment "after checking dups",
//otherwise new keys may be duplicated
//
const
  cMaxDupTime = 20;
var
  MaybeDups: boolean;
begin
  //close by Esc
  if (Key=VK_ESCAPE) and (Shift=[]) then
    if not FListerQuickView then
    begin
      PostMessage(FListerWindow, WM_CLOSE, 0, 0);
      Key:= 0;
      exit
    end;

  //to ignore duplicate keys (some Lazarus bug)
  MaybeDups:= (Key in [
    VK_LEFT, VK_RIGHT, VK_DOWN, VK_UP,
    VK_BACK, VK_DELETE,
    VK_RETURN,
    VK_PRIOR, VK_NEXT,
    VK_F1..VK_F12
    ]) or
    (ssCtrl in Shift) or
    (ssAlt in Shift);

  //fix for non working W
  if ed.ModeReadOnly then
    if Key in [VK_A..VK_Z] then
      MaybeDups:= true;

  //for space it's weird, it must work in NoCaret mode
  if (Key in [VK_SPACE]) and OptNoCaret then
    MaybeDups:= true;

  if MaybeDups then
    if (Key=FPrevKeyCode) and
      (Shift=FPrevKeyShift) and
      (GetTickCount64-FPrevKeyTick<=cMaxDupTime) then
      begin Key:= 0; exit; end;

  FPrevKeyCode:= Key;
  FPrevKeyShift:= Shift;
  FPrevKeyTick:= GetTickCount64;

  //--------------------------------------
  //after checking dups
  if (Shift=[]) then
  if (Key in [VK_F1..VK_F12]) or
    ((Key in [Ord('1')..Ord('7'), Ord('A')..Ord('W')]) and ed.ModeReadOnly) then
  begin
    PostMessage(FListerWindow, WM_KEYDOWN, Key, 0);
    Key:= 0;
    exit
  end;

  //support Ctrl+F
  if (Key=VK_F) and (Shift=[ssCtrl]) then
  begin
    PostMessage(FListerWindow, WM_KEYDOWN, VK_F7, 0);
    Key:= 0;
    exit
  end;

  //support Shift+F3, find back
  if (Key=VK_F3) and (Shift=[ssShift]) then
  begin
    DoFind(true, true, Finder.OptCase, Finder.OptWords, '');
    Key:= 0;
    exit
  end;

  if OptNoCaret then
    case Key of
      VK_SPACE:
        begin
          if ssShift in Shift then
            ed.DoCommand(cCommand_KeyPageUp)
          else
            ed.DoCommand(cCommand_KeyPageDown);
          Key:= 0;
        end;
      VK_HOME:
        begin
          ed.DoCommand(cCommand_GotoTextBegin);
          Key:= 0;
        end;
      VK_END:
        begin
          ed.DoCommand(cCommand_GotoTextEnd);
          Key:= 0;
        end;
      VK_UP:
        begin
          ed.DoCommand(cCommand_ScrollLineUp);
          Key:= 0;
        end;
      VK_LEFT:
        begin
          ed.ColumnLeft:= Max(0, ed.ColumnLeft-1);
          ed.Update;
          Key:= 0;
        end;
      VK_RIGHT:
        begin
          ed.ColumnLeft:= ed.ColumnLeft+1;
          ed.Update;
          Key:= 0;
        end;
      VK_DOWN:
        begin
          ed.DoCommand(cCommand_ScrollLineDown);
          Key:= 0;
        end;
    end;
end;

procedure TfmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if ed.Modified then
    if Application.MessageBox('File was modified. Save it?', 'CudaLister', MB_OKCANCEL or MB_ICONWARNING) = ID_OK then
      ed.SaveToFile(FFileName);
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
  Statusbar.ShowHint:= false;

  Statusbar.AddPanel(150, saMiddle);
  Statusbar.AddPanel(110, saMiddle);
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

  Finder:= TATEditorFinder.Create;
  Finder.OnFound:= @FinderFound;
  Finder.Editor:= ed;

  LoadOptions;
  UpdateMenuEnc(PopupEnc.Items);
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(Finder);
end;

procedure TfmMain.mnuOptionsClick(Sender: TObject);
begin
  with TfmOptions.Create(nil) do
  try
    ed:= Self.ed;
    ShowModal;
    SaveOptions;
    ApplyNoCaret;
  finally
    Free
  end;
end;

procedure TfmMain.mnuTextCopyClick(Sender: TObject);
begin
  ed.DoCommand(cCommand_ClipboardCopy);
end;

procedure TfmMain.mnuTextGotoClick(Sender: TObject);
var
  S: string;
  N: integer;
begin
  S:= InputBox('Go to', 'Line number:', '');
  if S='' then exit;
  N:= StrToIntDef(S, 0);
  if (N>0) and (N<=ed.Strings.Count) then
  begin
    ed.DoGotoPos(
      Point(0, N-1),
      Point(-1, -1),
      10,
      3,
      true,
      true
      );
    MsgStatus('Go to line '+IntToStr(N));
  end
  else
    MsgStatus('Incorrect line number: '+S);
end;

procedure TfmMain.mnuTextPasteClick(Sender: TObject);
begin
  ed.DoCommand(cCommand_ClipboardPaste);
end;

procedure TfmMain.mnuTextReadonlyClick(Sender: TObject);
begin
  ed.ModeReadOnly:= not ed.ModeReadOnly;
  ed.Update;
  mnuTextReadonly.Checked:= ed.ModeReadOnly;
end;

procedure TfmMain.mnuTextSelClick(Sender: TObject);
begin
  ed.DoCommand(cCommand_SelectAll);
end;

procedure TfmMain.PopupTextPopup(Sender: TObject);
begin
  mnuTextPaste.Enabled:= not ed.ModeReadOnly;
end;

procedure TfmMain.TimerStatusbarTimer(Sender: TObject);
begin
  TimerStatusbar.Enabled:= false;
  StatusBar.Captions[StatusbarIndex_Message]:= '';
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
  FTotalCmdWindow  := FindWindow('TTOTAL_CMD', nil);
  FListerWindow  := AParentWindow;
  FListerQuickView  := Windows.GetParent(FListerWindow) <> 0;
end;

class function TfmMain.PluginShow(AListerWin: HWND; AFileName: string;
  AWrapText: boolean): HWND;
var
  fmMain: TfmMain;
begin
  fmMain := nil;
  try
    fmMain := TfmMain.CreateParented(AListerWin);
    fmMain.FileOpen(AFileName);
    fmMain.Show;
    SetWindowLongPTR(fmMain.Handle, GWL_USERDATA, PtrInt(fmMain));
    // set focus to our window
    if not fmMain.FListerQuickView then
    begin
      PostMessage(fmMain.Handle, WM_SETFOCUS, 0, 0);
      fmMain.ed.SetFocus;
      fmMain.SetWrapMode(AWrapText);
    end;
    Result := fmMain.Handle;
  except
    if Assigned(fmMain) then
      fmMain.Free;
    Result := 0;
  end;
end;

class function TfmMain.PluginHide(APluginWin: HWND): HWND;
var
  fmMain: TfmMain;
begin
  Result := 0;
  fmMain := TfmMain(GetWindowLongPTR(APluginWin, GWL_USERDATA));
  try
    fmMain.Close;
    fmMain.Free;
  except
  end;
end;

procedure TfmMain.FileOpen(const AFileName: string);
begin
  FFileName:= AFileName;
  ed.LoadFromFile(AFileName);
  ed.DoCaretSingle(0, 0);
  ed.ModeReadOnly:= true;

  Adapter.Lexer:= DoFindLexerForFilename(AppManager, AFileName);
  UpdateStatusbar;
end;

procedure TfmMain.MsgStatus(const AMsg: string);
begin
  StatusBar.Captions[StatusbarIndex_Message]:= AMsg;
  TimerStatusbar.Enabled:= false;
  TimerStatusbar.Enabled:= true;
end;

procedure TfmMain.UpdateStatusbar;
var
  Caret: TATCaretItem;
  S: string;
begin
  if ed.Carets.Count>0 then
  begin
    Caret:= ed.Carets[0];
    StatusBar.Captions[StatusbarIndex_Caret]:=
      Format('Line %d, Col %d', [Caret.PosY+1, Caret.PosX+1]);
  end;

  StatusBar.Captions[StatusbarIndex_Enc]:= GetEncodingName;

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
    else S:= 'wrap';
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
  ed.Update;
  UpdateStatusbar;
end;

procedure TfmMain.SetWrapMode(AValue: boolean);
begin
  if AValue then
    ed.OptWrapMode:= cWrapOn
  else
    ed.OptWrapMode:= cWrapOff;
  ed.Update(true);
  UpdateStatusbar;
end;

procedure TfmMain.ToggleWrapMode;
begin
  if ed.OptWrapMode=cWrapOff then
    ed.OptWrapMode:= cWrapOn
  else
    ed.OptWrapMode:= cWrapOff;
  ed.Update(true);
  UpdateStatusbar;
end;

procedure TfmMain.StatusPanelClick(Sender: TObject; AIndex: Integer);
begin
  if AIndex=StatusbarIndex_Enc then
    PopupEnc.PopUp
  else
  if AIndex=StatusbarIndex_Lexer then
    PopupLexers.PopUp
  else
  if AIndex=StatusbarIndex_Wrap then
    ToggleWrapMode;
end;

procedure TfmMain.ApplyNoCaret;
begin
  ed.OptCaretBlinkEnabled:= not OptNoCaret;
  ed.OptScrollLineCommandsKeepCaretOnScreen:= not OptNoCaret;
  ed.OptShowGutterCaretBG:= not OptNoCaret;
  if OptNoCaret then
    ed.ModeReadOnly:= true;
  mnuTextReadonly.Enabled:= not OptNoCaret;
end;

procedure TfmMain.LoadOptions;
begin
  with TIniFile.Create(ListerIniFilename) do
  try
    ed.Font.Name:= ReadString(ListerIniSection, 'font_name', 'Consolas');
    ed.Font.Size:= ReadInteger(ListerIniSection, 'font_size', 9);
    ed.Colors.TextFont:= ReadInteger(ListerIniSection, 'color_font', ed.Colors.TextFont);
    ed.Colors.TextBG:= ReadInteger(ListerIniSection, 'color_bg', ed.Colors.TextBG);
    ed.Colors.UnprintedFont:= ReadInteger(ListerIniSection, 'color_unpri', ed.Colors.UnprintedFont);
    ed.OptNumbersStyle:= TATSynNumbersStyle(ReadInteger(ListerIniSection, 'num_style', 0));
    ed.OptTabSize:= ReadInteger(ListerIniSection, 'tab_size', 4);
    ed.OptTabSpaces:= ReadBool(ListerIniSection, 'tab_spaces', false);
    ed.OptUnprintedSpaces:= ReadBool(ListerIniSection, 'unpri_spaces', false);
    ed.OptUnprintedEnds:= ReadBool(ListerIniSection, 'unpri_ends', false);
    ed.OptMinimapVisible:= ReadBool(ListerIniSection, 'minimap', false);
    OptNoCaret:= ReadBool(ListerIniSection, 'no_caret', false);
    ApplyNoCaret;
  finally
    Free
  end;

  {$ifdef win64}
  //Totalcmd x64 crashes on mouse actions:
  //- drag selection to bottom
  //- mouse closing of FontDialog/ColorDialog
  //lets prevent it
  {$endif}
end;

procedure TfmMain.MenuEncNoReloadClick(Sender: TObject);
begin
  //not used
end;

procedure TfmMain.MenuEncWithReloadClick(Sender: TObject);
begin
  SetEncodingName((Sender as TMenuItem).Caption);
  UpdateStatusbar;
end;

procedure TfmMain.SaveOptions;
begin
  with TIniFile.Create(ListerIniFilename) do
  try
    WriteString(ListerIniSection, 'font_name', ed.Font.Name);
    WriteInteger(ListerIniSection, 'font_size', ed.Font.Size);
    WriteInteger(ListerIniSection, 'color_font', ed.Colors.TextFont);
    WriteInteger(ListerIniSection, 'color_bg', ed.Colors.TextBG);
    WriteInteger(ListerIniSection, 'color_unpri', ed.Colors.UnprintedFont);
    WriteInteger(ListerIniSection, 'num_style', Ord(ed.OptNumbersStyle));
    WriteInteger(ListerIniSection, 'tab_size', ed.OptTabSize);
    WriteBool(ListerIniSection, 'tab_spaces', ed.OptTabSpaces);
    WriteBool(ListerIniSection, 'unpri_spaces', ed.OptUnprintedSpaces);
    WriteBool(ListerIniSection, 'unpri_ends', ed.OptUnprintedEnds);
    WriteBool(ListerIniSection, 'minimap', ed.OptMinimapVisible);
    WriteBool(ListerIniSection, 'no_caret', OptNoCaret);
  finally
    Free
  end;
end;

function TfmMain.GetEncodingName: string;
begin
  case ed.Strings.Encoding of
    cEncAnsi:
      begin
        Result:= ed.Strings.EncodingCodepage;
        if Result='' then Result:= cEncNameAnsi;
      end;
    cEncUTF8:
      begin
        if ed.Strings.SaveSignUtf8 then
          Result:= cEncNameUtf8_WithBom
        else
          Result:= cEncNameUtf8_NoBom;
      end;
    cEncWideLE:
      begin
        if ed.Strings.SaveSignWide then
          Result:= cEncNameUtf16LE_WithBom
        else
          Result:= cEncNameUtf16LE_NoBom;
      end;
    cEncWideBE:
      begin
        if ed.Strings.SaveSignWide then
          Result:= cEncNameUtf16BE_WithBom
        else
          Result:= cEncNameUtf16BE_NoBom;
      end;
    else
      Result:= '?';
  end;
end;

procedure TfmMain.SetEncodingName(const Str: string);
var
  NTop: integer;
begin
  if Str='' then exit;
  if SameText(Str, GetEncodingName) then exit;

  if SameText(Str, cEncNameUtf8_WithBom) then begin ed.Strings.Encoding:= cEncUTF8; ed.Strings.SaveSignUtf8:= true; end else
   if SameText(Str, cEncNameUtf8_NoBom) then begin ed.Strings.Encoding:= cEncUTF8; ed.Strings.SaveSignUtf8:= false; end else
    if SameText(Str, cEncNameUtf16LE_WithBom) then begin ed.Strings.Encoding:= cEncWideLE; ed.Strings.SaveSignWide:= true; end else
     if SameText(Str, cEncNameUtf16LE_NoBom) then begin ed.Strings.Encoding:= cEncWideLE; ed.Strings.SaveSignWide:= false; end else
      if SameText(Str, cEncNameUtf16BE_WithBom) then begin ed.Strings.Encoding:= cEncWideBE; ed.Strings.SaveSignWide:= true; end else
       if SameText(Str, cEncNameUtf16BE_NoBom) then begin ed.Strings.Encoding:= cEncWideBE; ed.Strings.SaveSignWide:= false; end else
        if SameText(Str, cEncNameAnsi) then begin ed.Strings.Encoding:= cEncAnsi; ed.Strings.EncodingCodepage:= ''; end else
         if SameText(Str, cEncNameOem) then begin ed.Strings.Encoding:= cEncAnsi; ed.Strings.EncodingCodepage:= AppEncodingOem; end else
         begin
           ed.Strings.Encoding:= cEncAnsi;
           ed.Strings.EncodingCodepage:= Str;
         end;

  NTop:= ed.LineTop;
  ed.ModeReadOnly:= false;
  ed.Strings.EncodingDetect:= false;
  ed.LoadFromFile(FFileName);
  ed.ModeReadOnly:= true;
  ed.LineTop:= NTop;
  ed.Update;
end;

procedure TfmMain.UpdateMenuEnc(AMenu: TMenuItem);
  //
  procedure DoAdd(AMenu: TMenuItem; Sub, SName: string; AReloadFile: boolean);
  var
    mi, miSub: TMenuItem;
    n: integer;
  begin
    miSub:= nil;
    if Sub='eu' then Sub:= 'European' else
     if Sub='as' then Sub:= 'Asian' else
      if Sub='mi' then Sub:= 'Misc';

    if Sub<>'' then
    begin
      n:= AMenu.IndexOfCaption(Sub);
      if n<0 then
      begin
        mi:= TMenuItem.Create(Self);
        mi.Caption:= Sub;
        AMenu.Add(mi);
        n:= AMenu.IndexOfCaption(Sub);
      end;
      miSub:= AMenu.Items[n]
    end;

    if miSub=nil then miSub:= AMenu;
    mi:= TMenuItem.Create(Self);
    mi.Caption:= SName;

    if AReloadFile then
      mi.OnClick:=@MenuEncWithReloadClick
    else
      mi.OnClick:=@MenuEncNoReloadClick;

    miSub.Add(mi);
  end;
  //
var
  i: integer;
begin
  if AMenu=nil then exit;
  AMenu.Clear;

  for i:= Low(AppEncodings) to High(AppEncodings) do
  begin
    DoAdd(AMenu, AppEncodings[i].Sub, AppEncodings[i].Name, true);
  end;
end;


procedure TfmMain.FinderFound(Sender: TObject; APos1, APos2: TPoint);
begin
  ed.DoGotoPos(APos1, APos2,
    10, 3,
    true,
    true
    );
end;

procedure TfmMain.DoFind(AFindNext, ABack, ACaseSens, AWords: boolean; const AStrFind: Widestring);
var
  Msg: string;
  bChanged: boolean;
begin
  Finder.OptBack:= ABack;
  Finder.OptCase:= ACaseSens;
  Finder.OptFromCaret:= AFindNext;
  Finder.OptWords:= AWords;
  if AStrFind<>'' then
    Finder.StrFind:= AStrFind;

  if Finder.DoAction_FindOrReplace(false, false, false, bChanged) then
    Msg:= IfThen(AFindNext, 'Found next', 'Found first')
  else
    Msg:= 'Not found';
  MsgStatus(Msg+': "'+UTF8Encode(Finder.StrFind)+'"');
end;

end.
