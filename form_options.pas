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
    btnFont: TButton;
    btnColorFont: TButton;
    btnColorBack: TButton;
    btnClose: TButton;
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
    procedure btnFontClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure chkNums10Change(Sender: TObject);
    procedure chkNums5Change(Sender: TObject);
    procedure chkNumsAllChange(Sender: TObject);
    procedure chkNumsNoneChange(Sender: TObject);
    procedure chkTabSize2Change(Sender: TObject);
    procedure chkTabSize4Change(Sender: TObject);
    procedure chkTabSize8Change(Sender: TObject);
    procedure chkTabSpacesChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
  public
    ed: TATSynEdit;
    function DlgColor(AValue: TColor): TColor;
  end;

var
  fmOptions: TfmOptions;

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
    4: chkTabSize4.Checked:= true;
    8: chkTabSize8.Checked:= true;
  end;

  chkTabSpaces.Checked:= ed.OptTabSpaces;
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

procedure TfmOptions.btnColorBackClick(Sender: TObject);
begin
  ed.Colors.TextBG:= DlgColor(ed.Colors.TextBG);
  ed.Update;
end;

procedure TfmOptions.btnCloseClick(Sender: TObject);
begin
  Close;
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

procedure TfmOptions.chkTabSize2Change(Sender: TObject);
begin
  ed.OptTabSize:= 2;
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


end.

