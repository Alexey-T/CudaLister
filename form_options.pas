unit form_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,
  LclType,
  file_proc,
  form_listbox,
  math,
  ATSynEdit;

type
  { TfmOptions }

  TfmOptions = class(TForm)
    btnFont: TButton;
    btnClose: TButton;
    btnThemeUi: TButton;
    btnThemeSyntax: TButton;
    chkCaretVirtual: TCheckBox;
    chkGutterNums: TCheckBox;
    chkLastOnTop: TCheckBox;
    chkCopyLine: TCheckBox;
    chkEncUtf8: TCheckBox;
    chkGutterFold: TCheckBox;
    chkMinimapTooltip: TCheckBox;
    chkClickLink: TCheckBox;
    chkOnlyKnown: TCheckBox;
    chkNoCaret: TCheckBox;
    chkTabSize2: TRadioButton;
    chkTabSize3: TRadioButton;
    chkTabSize4: TRadioButton;
    chkTabSize8: TRadioButton;
    chkUnprintedSpace: TCheckBox;
    chkUnprintedEnds: TCheckBox;
    chkMinimap: TCheckBox;
    chkTabSpaces: TCheckBox;
    chkNums10: TRadioButton;
    chkNums5: TRadioButton;
    chkNumsAll: TRadioButton;
    chkNumsNone: TRadioButton;
    edMaxSize: TEdit;
    FontDialog1: TFontDialog;
    groupTabSize: TGroupBox;
    Label3: TLabel;
    LabelMaxSize: TLabel;
    labelFont: TLabel;
    groupNums: TGroupBox;
    procedure btnFontClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnThemeSyntaxClick(Sender: TObject);
    procedure btnThemeUiClick(Sender: TObject);
    procedure chkCaretVirtualChange(Sender: TObject);
    procedure chkClickLinkChange(Sender: TObject);
    procedure chkCopyLineChange(Sender: TObject);
    procedure chkEncUtf8Change(Sender: TObject);
    procedure chkGutterFoldChange(Sender: TObject);
    procedure chkGutterNumsChange(Sender: TObject);
    procedure chkLastOnTopChange(Sender: TObject);
    procedure chkMinimapChange(Sender: TObject);
    procedure chkMinimapTooltipChange(Sender: TObject);
    procedure chkNoCaretChange(Sender: TObject);
    procedure chkNums10Change(Sender: TObject);
    procedure chkNums5Change(Sender: TObject);
    procedure chkNumsAllChange(Sender: TObject);
    procedure chkNumsNoneChange(Sender: TObject);
    procedure chkOnlyKnownChange(Sender: TObject);
    procedure chkTabSize2Change(Sender: TObject);
    procedure chkTabSize3Change(Sender: TObject);
    procedure chkTabSize4Change(Sender: TObject);
    procedure chkTabSize8Change(Sender: TObject);
    procedure chkTabSpacesChange(Sender: TObject);
    procedure chkUnprintedEndsChange(Sender: TObject);
    procedure chkUnprintedSpaceChange(Sender: TObject);
    procedure edMaxSizeChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    DirThemes: string;
  public
    ed: TATSynEdit;
    function DlgColor(AValue: TColor): TColor;
  end;

var
  fmOptions: TfmOptions;

var
  OptNoCaret: boolean;
  OptOnlyKnownTypes: boolean;
  OptThemeUi: string;
  OptThemeSyntax: string;


implementation

{$R *.lfm}

{ TfmOptions }

procedure TfmOptions.FormShow(Sender: TObject);
var
  L: TStringList;
  i: integer;
begin
  labelFont.Caption:= Format('%s, %d', [ed.Font.Name, ed.Font.Size]);
  DirThemes:= ExtractFilePath(GetModuleName(HInstance))+'themes';

  L:= TStringList.Create;
  try
    {
    L.Clear;
    FindAllFiles(L, DirThemes, '*.cuda-theme-ui');
    L.Sort;
    L.Insert(0, '-');

    comboThemeUi.Items.Add('-');
    for i:= 0 to L.Count-1 do
      comboThemeUi.Items.Add(LowerCase(ChangeFileExt(ExtractFileName(L[i]), '')));

    L.Clear;
    FindAllFiles(L, dir, '*.cuda-theme-syntax');
    L.Sort;

    comboThemeSyntax.Items.Add('-');
    for i:= 0 to L.Count-1 do
      comboThemeSyntax.Items.Add(LowerCase(ChangeFileExt(ExtractFileName(L[i]), '')));

      comboThemeUi.ItemIndex:= comboThemeUi.Items.IndexOf(OptThemeUi);
      comboThemeSyntax.ItemIndex:= comboThemeSyntax.Items.IndexOf(OptThemeSyntax);

      }
  finally
    FreeAndNil(L);
  end;

  case ed.OptNumbersStyle of
    cNumbersAll: chkNumsAll.Checked:= true;
    cNumbersNone: chkNumsNone.Checked:= true;
    cNumbersEach10th: chkNums10.Checked:= true;
    cNumbersEach5th: chkNums5.Checked:= true;
  end;

  case ed.OptTabSize of
    2: chkTabSize2.Checked:= true;
    3: chkTabSize3.Checked:= true;
    4: chkTabSize4.Checked:= true;
    8: chkTabSize8.Checked:= true;
  end;

  chkEncUtf8.Checked:= ed.Strings.EncodingDetectDefaultUtf8;
  chkTabSpaces.Checked:= ed.OptTabSpaces;
  chkUnprintedSpace.Checked:= ed.OptUnprintedSpaces;
  chkUnprintedEnds.Checked:= ed.OptUnprintedEnds;
  chkGutterNums.Checked:= ed.Gutter[ed.GutterBandNumbers].Visible;
  chkGutterFold.Checked:= ed.Gutter[ed.GutterBandFolding].Visible;
  chkMinimap.Checked:= ed.OptMinimapVisible;
  chkMinimapTooltip.Checked:= ed.OptMinimapTooltipVisible;
  chkNoCaret.Checked:= OptNoCaret;
  chkOnlyKnown.Checked:= OptOnlyKnownTypes;
  chkClickLink.Checked:= ed.OptMouseClickOpensURL;
  chkCopyLine.Checked:= ed.OptCopyLinesIfNoSel;
  chkLastOnTop.Checked:= ed.OptLastLineOnTop;
  chkCaretVirtual.Checked:= ed.OptCaretVirtual;

  edMaxSize.Text:= IntToStr(OptMaxFileSizeMb);
end;

function TfmOptions.DlgColor(AValue: TColor): TColor;
begin
  Result:= AValue;
  with TColorDialog.Create(nil) do
  try
    Color:= AValue;
    if Execute then
      Result:= Color;
  finally
    Free
  end;
end;

procedure TfmOptions.btnFontClick(Sender: TObject);
begin
  FontDialog1.Font.Assign(ed.Font);
  if FontDialog1.Execute then
  begin
    ed.Font.Assign(FontDialog1.Font);
    ed.Update;
    FormShow(nil);
  end;
end;

procedure TfmOptions.btnCloseClick(Sender: TObject);
begin
  Close;
end;

function DoListboxChoice(const SDir, SMask: string; var Opt: string): boolean;
var
  fm: TfmListbox;
  L: TStringList;
  i: integer;
begin
  L:= TStringList.Create;
  fm:= TfmListbox.Create(nil);
  try
    FindAllFiles(L, SDir, SMask);
    L.Sort;
    L.Insert(0, '-');

    for i:= 0 to L.Count-1 do
      fm.Listbox.Items.Add(LowerCase(ChangeFileExt(ExtractFileName(L[i]), '')));
    fm.Listbox.ItemIndex:= fm.Listbox.Items.IndexOf(Opt);

    Result:= fm.ShowModal=mrOk;
    if Result then
      Opt:= fm.Listbox.Items[fm.Listbox.ItemIndex];
  finally
    FreeAndNil(fm);
    FreeAndNil(L);
  end;
end;


procedure TfmOptions.btnThemeSyntaxClick(Sender: TObject);
begin
  DoListboxChoice(DirThemes, '*.cuda-theme-syntax', OptThemeSyntax);
end;

procedure TfmOptions.btnThemeUiClick(Sender: TObject);
var
  fn: string;
begin
  if DoListboxChoice(DirThemes, '*.cuda-theme-ui', OptThemeUi) then
  begin
    fn:= DirThemes+DirectorySeparator+OptThemeUi+'.cuda-theme-syntax';
    if FileExists(fn) then
      if Application.Messagebox('Syntax theme with the same name exists. Apply it too?', 'Options',
        MB_OKCANCEL or MB_ICONQUESTION)=ID_OK then
        OptThemeSyntax:= OptThemeUi;
  end;
end;

procedure TfmOptions.chkCaretVirtualChange(Sender: TObject);
begin
  ed.OptCaretVirtual:= chkCaretVirtual.Checked;
  ed.Update;
end;

procedure TfmOptions.chkClickLinkChange(Sender: TObject);
begin
  ed.OptMouseClickOpensURL:= chkClickLink.Checked;
end;

procedure TfmOptions.chkCopyLineChange(Sender: TObject);
begin
  ed.OptCopyLinesIfNoSel:= chkCopyLine.Checked;
end;

procedure TfmOptions.chkEncUtf8Change(Sender: TObject);
begin
  ed.Strings.EncodingDetectDefaultUtf8:= chkEncUtf8.Checked;
end;

procedure TfmOptions.chkGutterFoldChange(Sender: TObject);
begin
  ed.Gutter[ed.GutterBandFolding].Visible:= chkGutterFold.Checked;
  ed.Update;
end;

procedure TfmOptions.chkGutterNumsChange(Sender: TObject);
begin
  ed.Gutter[ed.GutterBandNumbers].Visible:= chkGutterNums.Checked;
  ed.Update;
end;

procedure TfmOptions.chkLastOnTopChange(Sender: TObject);
begin
  ed.OptLastLineOnTop:= chkLastOnTop.Checked;
  ed.Update;
end;

procedure TfmOptions.chkMinimapChange(Sender: TObject);
begin
  ed.OptMinimapVisible:= chkMinimap.Checked;
  ed.Update;
end;

procedure TfmOptions.chkMinimapTooltipChange(Sender: TObject);
begin
  ed.OptMinimapTooltipVisible:= chkMinimapTooltip.Checked;
  ed.Update;
end;

procedure TfmOptions.chkNoCaretChange(Sender: TObject);
begin
  OptNoCaret:= chkNoCaret.Checked;
end;

procedure TfmOptions.chkNums10Change(Sender: TObject);
begin
  ed.OptNumbersStyle:= cNumbersEach10th;
  ed.Update;
end;

procedure TfmOptions.chkNums5Change(Sender: TObject);
begin
  ed.OptNumbersStyle:= cNumbersEach5th;
  ed.Update;
end;

procedure TfmOptions.chkNumsAllChange(Sender: TObject);
begin
  ed.OptNumbersStyle:= cNumbersAll;
  ed.Update;
end;

procedure TfmOptions.chkNumsNoneChange(Sender: TObject);
begin
  ed.OptNumbersStyle:= cNumbersNone;
  ed.Update;
end;

procedure TfmOptions.chkOnlyKnownChange(Sender: TObject);
begin
  OptOnlyKnownTypes:= chkOnlyKnown.Checked;
end;

procedure TfmOptions.chkTabSize2Change(Sender: TObject);
begin
  ed.OptTabSize:= 2;
  ed.Update;
end;

procedure TfmOptions.chkTabSize3Change(Sender: TObject);
begin
  ed.OptTabSize:= 3;
  ed.Update;
end;

procedure TfmOptions.chkTabSize4Change(Sender: TObject);
begin
  ed.OptTabSize:= 4;
  ed.Update;
end;

procedure TfmOptions.chkTabSize8Change(Sender: TObject);
begin
  ed.OptTabSize:= 8;
  ed.Update;
end;

procedure TfmOptions.chkTabSpacesChange(Sender: TObject);
begin
  ed.OptTabSpaces:= chkTabSpaces.Checked;
  ed.Update;
end;

procedure TfmOptions.chkUnprintedEndsChange(Sender: TObject);
begin
  ed.OptUnprintedEnds:= chkUnprintedEnds.Checked;
  ed.Update;
end;

procedure TfmOptions.chkUnprintedSpaceChange(Sender: TObject);
begin
  ed.OptUnprintedSpaces:= chkUnprintedSpace.Checked;
  ed.Update;
end;

procedure TfmOptions.edMaxSizeChange(Sender: TObject);
begin
  OptMaxFileSizeMb:= Max(1, StrToIntDef(edMaxSize.Text, 2));
end;


end.

