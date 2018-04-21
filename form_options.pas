unit form_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,
  ATSynEdit;

type
  { TfmOptions }

  TfmOptions = class(TForm)
    btnColorUnpri: TButton;
    btnFont: TButton;
    btnColorFont: TButton;
    btnColorBack: TButton;
    btnClose: TButton;
    chkCopyLine: TCheckBox;
    chkEncUtf8: TCheckBox;
    chkGutter: TCheckBox;
    chkMinimapTooltip: TCheckBox;
    chkClickLink: TCheckBox;
    chkOnlyKnown: TCheckBox;
    chkNoCaret: TCheckBox;
    chkTabSize3: TRadioButton;
    chkUnprintedSpace: TCheckBox;
    chkUnprintedEnds: TCheckBox;
    chkMinimap: TCheckBox;
    chkTabSpaces: TCheckBox;
    chkNums10: TRadioButton;
    chkNums5: TRadioButton;
    chkNumsAll: TRadioButton;
    chkNumsNone: TRadioButton;
    chkTabSize2: TRadioButton;
    chkTabSize4: TRadioButton;
    chkTabSize8: TRadioButton;
    FontDialog1: TFontDialog;
    labelFont: TLabel;
    groupTabSize: TGroupBox;
    groupNums: TGroupBox;
    procedure btnColorBackClick(Sender: TObject);
    procedure btnColorFontClick(Sender: TObject);
    procedure btnColorUnpriClick(Sender: TObject);
    procedure btnFontClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure chkClickLinkChange(Sender: TObject);
    procedure chkCopyLineChange(Sender: TObject);
    procedure chkEncUtf8Change(Sender: TObject);
    procedure chkGutterChange(Sender: TObject);
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
    procedure FormShow(Sender: TObject);
  private
  public
    ed: TATSynEdit;
    function DlgColor(AValue: TColor): TColor;
  end;

var
  fmOptions: TfmOptions;

var
  OptNoCaret: boolean;
  OptOnlyKnownTypes: boolean;


implementation

{$R *.lfm}

{ TfmOptions }

procedure TfmOptions.FormShow(Sender: TObject);
begin
  labelFont.Caption:= Format('%s, %d', [ed.Font.Name, ed.Font.Size]);

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
  chkGutter.Checked:= ed.OptGutterVisible;
  chkMinimap.Checked:= ed.OptMinimapVisible;
  chkMinimapTooltip.Checked:= ed.OptMinimapTooltipVisible;
  chkNoCaret.Checked:= OptNoCaret;
  chkOnlyKnown.Checked:= OptOnlyKnownTypes;
  chkClickLink.Checked:= ed.OptMouseClickOpensURL;
  chkCopyLine.Checked:= ed.OptCopyLinesIfNoSel;
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

procedure TfmOptions.btnColorFontClick(Sender: TObject);
begin
  ed.Colors.TextFont:= DlgColor(ed.Colors.TextFont);
  ed.Update;
end;

procedure TfmOptions.btnColorUnpriClick(Sender: TObject);
begin
  ed.Colors.UnprintedFont:= DlgColor(ed.Colors.UnprintedFont);
  ed.Update;
end;

procedure TfmOptions.btnColorBackClick(Sender: TObject);
begin
  ed.Colors.TextBG:= DlgColor(ed.Colors.TextBG);
  ed.Update;
end;

procedure TfmOptions.btnCloseClick(Sender: TObject);
begin
  Close;
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

procedure TfmOptions.chkGutterChange(Sender: TObject);
begin
  ed.OptGutterVisible:= chkGutter.Checked;
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


end.

