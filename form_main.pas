unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Windows, SysUtils, Classes, Graphics,
  LCLType, LCLProc, LCLIntf,
  Forms, Controls, ExtCtrls, Dialogs, Menus,
  IniFiles, StrUtils,
  Clipbrd,
  EncConv,
  ATSynEdit,
  ATSynEdit_Carets,
  ATSynEdit_Adapter_EControl,
  ATSynEdit_Commands,
  ATSynEdit_Finder,
  ATSynEdit_Globals,
  ATSynEdit_CharSizer,
  ATSynEdit_Keymap,
  ATStrings,
  ATStringProc,
  ATStatusbar,
  ATScrollBar,
  ATFlatThemes,
  ec_SyntAnal,
  ec_proc_lexer,
  file_proc,
  proc_themes,
  form_options,
  FileUtil;

const
  cEditorIsReadOnly = false;

type
  { TfmMain }

  TfmMain = class(TForm)
    ed: TATSynEdit;
    mnuWrap: TMenuItem;
    mnuFind: TMenuItem;
    mnuTextSave: TMenuItem;
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
    TimerEmpty: TTimer;
    TimerStatusbar: TTimer;
    procedure edChangeCaretPos(Sender: TObject);
    procedure edClickLink(Sender: TObject; const ALink: string);
    procedure edCommand(Sender: TObject; ACommand: integer;
      const AText: string; var AHandled: boolean);
    procedure edKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mnuFindClick(Sender: TObject);
    procedure mnuOptionsClick(Sender: TObject);
    procedure mnuTextCopyClick(Sender: TObject);
    procedure mnuTextGotoClick(Sender: TObject);
    procedure mnuTextPasteClick(Sender: TObject);
    procedure mnuTextReadonlyClick(Sender: TObject);
    procedure mnuTextSaveClick(Sender: TObject);
    procedure mnuTextSelClick(Sender: TObject);
    procedure mnuWrapClick(Sender: TObject);
    procedure PopupTextPopup(Sender: TObject);
    procedure TimerEmptyTimer(Sender: TObject);
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
    FPrevNoCaret: boolean;
    Statusbar: TATStatus;
    Adapter: TATAdapterEControl;
    //
    procedure ApplyNoCaret;
    procedure ApplyThemes;
    procedure DoFindDialog;
    procedure FinderFound(Sender: TObject; APos1, APos2: TPoint);
    function GetEncodingName: string;
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
    class function PluginShow(AListerWin: HWND; AFileName: string): HWND;
    class function PluginHide(APluginWin: HWND): HWND;
    procedure MsgStatus(const AMsg: string);
    procedure FileOpen(const AFileName: string);
    procedure SetWrapMode(AValue: boolean);
    procedure SetEncodingName(const Str: string; EncId: TEncConvId);
    procedure ToggleWrapMode;
    procedure DoFind(AFindNext, ABack, ACaseSens, AWords: boolean; const AStrFind: Widestring);
    procedure ConfirmSave;
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

var
  AppManager: TecSyntaxManager;

function IsCheckedLexerForFilename(const fn: string): boolean;


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
    Sub: string;
    Name: string;
    Id: TEncConvId;
  end;

const
  AppEncodings: array[0..41] of TAppEncodingRecord = (
    (Sub: ''; Name: cEncNameUtf8_NoBom; Id: eidUTF8),
    (Sub: ''; Name: cEncNameUtf8_WithBom; Id: eidUTF8BOM),
    (Sub: ''; Name: cEncNameUtf16LE_NoBom; Id: eidUTF8),
    (Sub: ''; Name: cEncNameUtf16LE_WithBom; Id: eidUTF8),
    (Sub: ''; Name: cEncNameUtf16BE_NoBom; Id: eidUTF8),
    (Sub: ''; Name: cEncNameUtf16BE_WithBom; Id: eidUTF8),
    (Sub: ''; Name: cEncNameAnsi; Id: eidUTF8),
    (Sub: ''; Name: cEncNameOem; Id: eidUTF8),
    (Sub: ''; Name: '-'; Id: eidUTF8),
    (Sub: 'eu'; Name: 'CP1250'; Id: eidCP1250),
    (Sub: 'eu'; Name: 'CP1251'; Id: eidCP1251),
    (Sub: 'eu'; Name: 'CP1252'; Id: eidCP1252),
    (Sub: 'eu'; Name: 'CP1253'; Id: eidCP1253),
    (Sub: 'eu'; Name: 'CP1257'; Id: eidCP1257),
    (Sub: 'eu'; Name: '-'; Id: eidUTF8),
    (Sub: 'eu'; Name: 'CP437'; Id: eidCP437),
    (Sub: 'eu'; Name: 'CP850'; Id: eidCP850),
    (Sub: 'eu'; Name: 'CP852'; Id: eidCP852),
    (Sub: 'eu'; Name: 'CP866'; Id: eidCP866),
    (Sub: 'eu'; Name: '-'; Id: eidUTF8),
    (Sub: 'eu'; Name: 'ISO-8859-1'; Id: eidISO1),
    (Sub: 'eu'; Name: 'ISO-8859-2'; Id: eidISO2),
    (Sub: 'eu'; Name: 'ISO-8859-3'; Id: eidISO3),
    (Sub: 'eu'; Name: 'ISO-8859-4'; Id: eidISO4),
    (Sub: 'eu'; Name: 'ISO-8859-5'; Id: eidISO5),
    (Sub: 'eu'; Name: 'ISO-8859-7'; Id: eidISO7),
    (Sub: 'eu'; Name: 'ISO-8859-9'; Id: eidISO9),
    (Sub: 'eu'; Name: 'ISO-8859-10'; Id: eidISO10),
    (Sub: 'eu'; Name: 'ISO-8859-13'; Id: eidISO13),
    (Sub: 'eu'; Name: 'ISO-8859-14'; Id: eidISO14),
    (Sub: 'eu'; Name: 'ISO-8859-15'; Id: eidISO15),
    (Sub: 'eu'; Name: 'ISO-8859-16'; Id: eidISO16),
    (Sub: 'eu'; Name: 'Mac'; Id: eidCPMac),
    (Sub: 'mi'; Name: 'CP1254'; Id: eidCP1254),
    (Sub: 'mi'; Name: 'CP1255'; Id: eidCP1255),
    (Sub: 'mi'; Name: 'CP1256'; Id: eidCP1256),
    (Sub: 'as'; Name: 'CP874';  Id: eidCP874),
    (Sub: 'as'; Name: 'CP932';  Id: eidCP932),
    (Sub: 'as'; Name: 'CP936';  Id: eidCP936),
    (Sub: 'as'; Name: 'CP949';  Id: eidCP949),
    (Sub: 'as'; Name: 'CP950';  Id: eidCP950),
    (Sub: 'as'; Name: 'CP1258'; Id: eidCP1258)
  );


function MsgBox(const S: string; Flags: integer): integer;
begin
  Result:= MessageBox(0, PChar(S), 'CudaLister', Flags or MB_APPLMODAL);
end;

procedure LoadLexerLib;
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
end;

function IsCheckedLexerForFilename(const fn: string): boolean;
var
  op: boolean;
begin
  with TIniFile.Create(ListerIniFilename) do
  try
    op:= ReadBool(ListerIniSection, 'only_known_types', false);
  finally
    Free
  end;

  if op then
    Result:= Assigned(Lexer_FindForFilename(AppManager, fn))
  else
    Result:= true;
end;


{ TfmMain }

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
  //ignore OS keys: Alt+Space
  if (Key=VK_SPACE) and (Shift=[ssAlt]) then exit;

  //Lister's F2 must reload file
  if (Key=VK_F2) and (Shift=[]) then
  begin
    if ed.Modified then
      if MessageBox(Handle, 'File is modified. Are you sure you want to reload it from disk?', 'CudaLister',
        MB_OKCANCEL or MB_ICONWARNING)=ID_OK then
        ed.LoadFromFile(FFileName);
    Key:= 0;
    exit;
  end;

  //Shift+F10: context menu
  if (Key=VK_F10) and (Shift=[ssShift]) then
  begin
    ed.PopupText.PopUp;
    Key:= 0;
    exit;
  end;

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
    VK_INSERT,
    VK_RETURN,
    VK_PRIOR, VK_NEXT,
    VK_HOME, VK_END,
    VK_F1..VK_F12,
    VK_APPS
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
    DoFindDialog;
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
            ed.DoCommand(cCommand_ScrollPageUp, cInvokeHotkey)
          else
            ed.DoCommand(cCommand_ScrollPageDown, cInvokeHotkey);
          Key:= 0;
        end;
      VK_HOME:
        begin
          ed.DoCommand(cCommand_ScrollToBegin, cInvokeHotkey);
          Key:= 0;
        end;
      VK_END:
        begin
          ed.DoCommand(cCommand_GotoLineAbsBegin, cInvokeHotkey); //needed if too long line
          ed.DoCommand(cCommand_ScrollToEnd, cInvokeHotkey);
          Key:= 0;
        end;
      VK_UP:
        begin
          ed.DoCommand(cCommand_ScrollLineUp, cInvokeHotkey);
          Key:= 0;
        end;
      VK_DOWN:
        begin
          ed.DoCommand(cCommand_ScrollLineDown, cInvokeHotkey);
          Key:= 0;
        end;
      VK_LEFT:
        begin
          ed.DoCommand(cCommand_ScrollColumnLeft, cInvokeHotkey);
          Key:= 0;
        end;
      VK_RIGHT:
        begin
          ed.DoCommand(cCommand_ScrollColumnRight, cInvokeHotkey);
          Key:= 0;
        end;
    end;
end;

procedure TfmMain.DoFindDialog;
begin
  PostMessage(FListerWindow, WM_KEYDOWN, VK_F7, 0);
  PostMessage(FListerWindow, WM_KEYUP, VK_F7, 0);
end;

procedure TfmMain.ConfirmSave;
begin
  if (FFileName<>'') and ed.Modified then
  begin
    ed.Modified:= false;
    if MsgBox('File was modified. Save it?', MB_OKCANCEL or MB_ICONQUESTION)=ID_OK then
      try
        ed.SaveToFile(FFileName);
      except
        MsgBox('Cannot save file', MB_OK or MB_ICONERROR);
      end;
  end;
end;

procedure TfmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ConfirmSave;
end;

procedure TfmMain.edChangeCaretPos(Sender: TObject);
begin
  UpdateStatusbar;
end;

procedure TfmMain.edClickLink(Sender: TObject; const ALink: string);
begin
  OpenURL(ALink);
end;

procedure TfmMain.edCommand(Sender: TObject; ACommand: integer;
  const AText: string; var AHandled: boolean);
begin
  //fix for clipboard pasting from other apps: call Clipboard.Clear as Ghisler suggested
  //- dont work
  case ACommand of
    cCommand_ClipboardPaste,
    cCommand_ClipboardPaste_Column:
      begin end; //Clipboard.Clear;
  end;
end;

procedure TfmMain.FormCreate(Sender: TObject);
var
  N: integer;
begin
  N:= ed.Keymap.IndexOf(cCommand_ToggleReadOnly);
  if N>=0 then
    ed.Keymap[N].Keys1.Data[0]:= Shortcut(VK_R, [ssCtrl]);

  ed.OptScrollbarsNew:= true;
  ed.OptScrollStyleHorz:= aessShow;
  ed.PopupText:= PopupText;

  ATFlatTheme.ScalePercents:= Screen.PixelsPerInch * 100 div 96;
  ATFlatTheme.ScaleFontPercents:= 100;
  ATScrollbarTheme.ScalePercents:= ATFlatTheme.ScalePercents;
  ATScrollbarTheme.ColorThumbFill:= clBtnFace;
  ATScrollbarTheme.ColorArrowFill:= clBtnFace;

  ATEditorOptions.UnprintedEndSymbol:= aeuePilcrow; //fix issue #66

  Statusbar:= TATStatus.Create(Self);
  Statusbar.Parent:= Self;
  Statusbar.Align:= alBottom;
  Statusbar.Padding:= 1;
  Statusbar.OnPanelClick:= @StatusPanelClick;
  Statusbar.ShowHint:= false;

  Statusbar.AddPanel(-1, 150, taCenter);
  Statusbar.AddPanel(-1, 110, taCenter);
  Statusbar.AddPanel(-1, 50, taCenter);
  Statusbar.AddPanel(-1, 150, taCenter);
  Statusbar.AddPanel(-1, 50, taCenter);
  Statusbar.AddPanel(-1, 1600, taLeftJustify);

  UpdateMenuLexersTo(PopupLexers.Items);

  Adapter:= TATAdapterEControl.Create(Self);
  Adapter.ImplementsDataReady:= false; //fix not initially colored c++ file
  Adapter.DynamicHiliteEnabled:= false;
  Adapter.DynamicHiliteMaxLines:= 5000;
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

procedure TfmMain.mnuFindClick(Sender: TObject);
begin
  DoFindDialog;
end;

procedure TfmMain.mnuOptionsClick(Sender: TObject);
var
  F: TfmOptions;
begin
  F:= TfmOptions.Create(nil);
  try
    F.ed:= Self.ed;
    F.ShowModal;
    SaveOptions;
    UpdateStatusbar;
    ApplyNoCaret;
  finally
    FreeAndNil(F);
  end;
end;

procedure TfmMain.mnuTextCopyClick(Sender: TObject);
begin
  ed.DoCommand(cCommand_ClipboardCopy, cInvokeMenuContext);
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
  ed.DoCommand(cCommand_ClipboardPaste, cInvokeMenuContext);
end;

procedure TfmMain.mnuTextReadonlyClick(Sender: TObject);
begin
  if cEditorIsReadOnly then exit;

  ed.ModeReadOnly:= not ed.ModeReadOnly;
  ed.Update;

  if not ed.ModeReadOnly then
  begin
    FPrevNoCaret:= OptNoCaret;
    OptNoCaret:= false;
    ApplyNoCaret;
  end
  else
  begin
    OptNoCaret:= FPrevNoCaret;
    ApplyNoCaret;
  end;
end;

procedure TfmMain.mnuTextSaveClick(Sender: TObject);
begin
  if ed.Modified then
    try
      ed.SaveToFile(FFileName);
      ed.Modified:= false;
    except
      MsgBox('Cannot save file', MB_OK or MB_ICONERROR);
    end;
end;

procedure TfmMain.mnuTextSelClick(Sender: TObject);
begin
  ed.DoCommand(cCommand_SelectAll, cInvokeMenuContext);
end;

procedure TfmMain.mnuWrapClick(Sender: TObject);
begin
  if ed.OptWrapMode=cWrapOff then
    ed.OptWrapMode:= cWrapOn
  else
    ed.OptWrapMode:= cWrapOff;
  UpdateStatusbar;
end;

procedure TfmMain.PopupTextPopup(Sender: TObject);
begin
  mnuTextSave.Enabled:= ed.Modified;
  mnuTextPaste.Enabled:= not ed.ModeReadOnly;
  mnuWrap.Checked:= ed.OptWrapMode=cWrapOn;
  mnuTextReadonly.Checked:= ed.ModeReadOnly;
end;

procedure TfmMain.TimerEmptyTimer(Sender: TObject);
//this timer is just to call ProcessMessages,
//for thread events to work better
begin
  Application.ProcessMessages;
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

class function TfmMain.PluginShow(AListerWin: HWND; AFileName: string): HWND;
var
  fmMain: TfmMain;
begin
  fmMain := nil;
  try
    fmMain := TfmMain.CreateParented(AListerWin);
    fmMain.FileOpen(AFileName);
    fmMain.mnuTextReadonly.Enabled:= not cEditorIsReadOnly;
    fmMain.Show;
    SetWindowLongPTR(fmMain.Handle, GWL_USERDATA, PtrInt(fmMain));
    // set focus to our window
    if not fmMain.FListerQuickView then
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
var
  an: TecSyntAnalyzer;
begin
  FFileName:= AFileName;
  ed.ModeReadOnly:= false;
  ed.LoadFromFile(AFileName);
  ed.DoCaretSingle(0, 0);
  ed.ModeReadOnly:= true;

  an:= Lexer_FindForFilename(AppManager, AFileName);
  if Assigned(an) then
    DoApplyLexerStylesMap(an);

  while Adapter.IsParsingBusy or not Adapter.IsDataReady do
  begin
    Sleep(25);
    Application.ProcessMessages;
  end;
  Adapter.Lexer:= nil;
  Adapter.Lexer:= an;

  DoApplyEditorTheme(ed);
  ed.DoEventChange(0);

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
  DoApplyLexerStylesMap(an);
  Adapter.Lexer:= an;
  ed.DoEventChange(0);
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
  mnuTextReadonly.Enabled:= not cEditorIsReadOnly;
end;

procedure TfmMain.ApplyThemes;
var
  dir, fn: string;
begin
  //DoInitTheme(AppTheme); //already inited
  dir:= ExtractFilePath(_GetDllFilename)+'themes';

  fn:= dir+'\'+OptThemeUi+'.cuda-theme-ui';
  if FileExists(fn) then
    DoLoadTheme(fn, AppTheme, true);

  //showmessage('1:'+ ColorToString(GetAppStyleFromName('Symbol').Font.Color) );

  fn:= dir+'\'+OptThemeSyntax+'.cuda-theme-syntax';
  if FileExists(fn) then
    DoLoadTheme(fn, AppTheme, false);

  //showmessage('2:'+ ColorToString(GetAppStyleFromName('Symbol').Font.Color) );

  ATFlatTheme.ColorFont:= GetAppColor('TabFont');
  ATFlatTheme.ColorBgPassive:= GetAppColor('TabBg');
  ATFlatTheme.ColorBorderPassive:= GetAppColor('TabBorderPassive');
  Statusbar.Color:= ATFlatTheme.ColorBgPassive;
  Statusbar.ColorBorderL:= ATFlatTheme.ColorBorderPassive;
  Statusbar.ColorBorderR:= ATFlatTheme.ColorBorderPassive;
  Statusbar.Update;

  with ATScrollbarTheme do
  begin
    ColorBG:= GetAppColor('ScrollBack');
    ColorBorder:= ColorBG;
    ColorThumbBorder:= GetAppColor('ScrollRect');
    ColorThumbFill:= GetAppColor('ScrollFill');
    ColorThumbFillOver:= ColorThumbFill;
    ColorThumbFillPressed:= ColorThumbFill;
    ColorThumbDecor:= ColorThumbBorder;
    ColorArrowBorder:= ColorBG;
    ColorArrowFill:= ColorBG;
    ColorArrowFillOver:= ColorArrowFill;
    ColorArrowFillPressed:= ColorArrowFill;
    ColorArrowSign:= GetAppColor('ScrollArrow');
    ColorScrolled:= GetAppColor('ScrollScrolled');
  end;
end;

procedure TfmMain.LoadOptions;
begin
  with TIniFile.Create(ListerIniFilename) do
  try
    ed.Strings.EncodingDetectDefaultUtf8:= ReadBool(ListerIniSection, 'def_utf8', false);
    ed.Font.Name:= ReadString(ListerIniSection, 'font_name', 'Consolas');
    ed.Font.Size:= ReadInteger(ListerIniSection, 'font_size', 9);
    ed.Colors.TextFont:= ReadInteger(ListerIniSection, 'color_font', ed.Colors.TextFont);
    ed.Colors.TextBG:= ReadInteger(ListerIniSection, 'color_bg', ed.Colors.TextBG);
    ed.Colors.UnprintedFont:= ReadInteger(ListerIniSection, 'color_unpri', ed.Colors.UnprintedFont);
    ed.OptNumbersStyle:= TATEditorNumbersStyle(ReadInteger(ListerIniSection, 'num_style', 0));
    ed.OptTabSize:= ReadInteger(ListerIniSection, 'tab_size', 4);
    ed.OptTabSpaces:= ReadBool(ListerIniSection, 'tab_spaces', false);
    ed.OptUnprintedSpaces:= ReadBool(ListerIniSection, 'unpri_spaces', false);
    ed.OptUnprintedEnds:= ReadBool(ListerIniSection, 'unpri_ends', false);
    ed.Gutter[ed.Gutter.FindIndexByTag(ATEditorOptions.GutterTagBookmarks)].Visible:= false;
    ed.Gutter[ed.Gutter.FindIndexByTag(ATEditorOptions.GutterTagNumbers)].Visible:= ReadBool(ListerIniSection, 'gutter_nums', true);
    ed.Gutter[ed.Gutter.FindIndexByTag(ATEditorOptions.GutterTagFolding)].Visible:= ReadBool(ListerIniSection, 'gutter_fold', true);
    ed.OptMinimapVisible:= ReadBool(ListerIniSection, 'minimap', false);
    ed.OptMinimapTooltipVisible:= ReadBool(ListerIniSection, 'minimap_tooltip', true);
    ed.OptMouseClickOpensURL:= ReadBool(ListerIniSection, 'click_link', false);
    ed.OptCopyLinesIfNoSel:= ReadBool(ListerIniSection, 'copy_line', false);
    ed.OptLastLineOnTop:= ReadBool(ListerIniSection, 'last_line_on_top', true);
    ed.OptCaretVirtual:= ReadBool(ListerIniSection, 'caret_virtual', false);
    ed.OptCaretProximityVert:= ReadInteger(ListerIniSection, 'caret_proximity', 0);

    if ReadBool(ListerIniSection, 'word_wrap', false) then
      ed.OptWrapMode:= cWrapOn
    else
      ed.OptWrapMode:= cWrapOff;

    ed.OptScrollbarsNew:= ReadBool(ListerIniSection, 'scrollbars_new', true);

    ApplyNoCaret;
    ApplyThemes;
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
var
  mi: TMenuItem;
begin
  mi:= Sender as TMenuItem;
  SetEncodingName(mi.Caption, TEncConvId(mi.Tag));
  UpdateStatusbar;
end;

procedure TfmMain.SaveOptions;
begin
  with TIniFile.Create(ListerIniFilename) do
  try
    WriteBool(ListerIniSection, 'def_utf8', ed.Strings.EncodingDetectDefaultUtf8);
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
    WriteBool(ListerIniSection, 'gutter_nums', ed.Gutter[ed.Gutter.FindIndexByTag(ATEditorOptions.GutterTagNumbers)].Visible);
    WriteBool(ListerIniSection, 'gutter_fold', ed.Gutter[ed.Gutter.FindIndexByTag(ATEditorOptions.GutterTagFolding)].Visible);
    WriteBool(ListerIniSection, 'minimap', ed.OptMinimapVisible);
    WriteBool(ListerIniSection, 'minimap_tooltip', ed.OptMinimapTooltipVisible);
    WriteBool(ListerIniSection, 'click_link', ed.OptMouseClickOpensURL);
    WriteBool(ListerIniSection, 'copy_line', ed.OptCopyLinesIfNoSel);
    WriteBool(ListerIniSection, 'last_line_on_top', ed.OptLastLineOnTop);
    WriteBool(ListerIniSection, 'caret_virtual', ed.OptCaretVirtual);
    WriteInteger(ListerIniSection, 'caret_proximity', ed.OptCaretProximityVert);
    WriteBool(ListerIniSection, 'word_wrap', ed.OptWrapMode<>cWrapOff);
    WriteBool(ListerIniSection, 'scrollbars_new', ed.OptScrollbarsNew);

    WriteBool(ListerIniSection, 'no_caret', OptNoCaret);
    WriteBool(ListerIniSection, 'only_known_types', OptOnlyKnownTypes);
    WriteInteger(ListerIniSection, 'max_size', OptMaxFileSizeMb);
    WriteString(ListerIniSection, 'theme_ui', OptThemeUi);
    WriteString(ListerIniSection, 'theme_syntax', OptThemeSyntax);
  finally
    Free
  end;
end;

function TfmMain.GetEncodingName: string;
begin
  case ed.Strings.Encoding of
    cEncAnsi:
      begin
        Result:= cEncConvNames[ed.Strings.EncodingCodepage];
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

procedure TfmMain.SetEncodingName(const Str: string; EncId: TEncConvId);
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
        if SameText(Str, cEncNameAnsi) then begin ed.Strings.Encoding:= cEncAnsi; ed.Strings.EncodingCodepage:= EncConvGetANSI; end else
         if SameText(Str, cEncNameOem) then begin ed.Strings.Encoding:= cEncAnsi; ed.Strings.EncodingCodepage:= EncConvGetOEM; end else
         begin
           ed.Strings.Encoding:= cEncAnsi;
           ed.Strings.EncodingCodepage:= EncId;
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
  procedure DoAdd(AMenu: TMenuItem; Sub, SName: string; EncId: TEncConvId; AReloadFile: boolean);
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
    mi.Tag:= Ord(EncId);

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
    DoAdd(AMenu,
      AppEncodings[i].Sub,
      AppEncodings[i].Name,
      AppEncodings[i].Id,
      true);
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
  if Finder.StrFind='' then exit;

  if Finder.DoAction_FindOrReplace(false, false, bChanged, true) then
    Msg:= IfThen(AFindNext, 'Found next', 'Found first')
  else
    Msg:= 'Not found';
  MsgStatus(Msg+': "'+UTF8Encode(Finder.StrFind)+'"');
end;



initialization
  AppManager:= TecSyntaxManager.Create(nil);
  LoadLexerLib;
  ATEditorOptions.UseGlobalCharSizer:= false; //must be False in DLL to avoid crash with N CudaLister windows
  ATEditorOptions.FlickerReducingPause:= 1000;

finalization
  FreeAndNil(AppManager);

end.
