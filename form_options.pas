unit form_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls,
  ATSynEdit;

type
  { TfmOptions }

  TfmOptions = class(TForm)
    btnFont: TButton;
    btnColorFont: TButton;
    btnColorBack: TButton;
    btnClose: TButton;
    ColorDialog1: TColorDialog;
    FontDialog1: TFontDialog;
    Label1: TLabel;
    labelFont: TLabel;
    chkNumsAll: TRadioButton;
    chkNumsNone: TRadioButton;
    chkNums10: TRadioButton;
    chkNums5: TRadioButton;
    procedure btnColorBackClick(Sender: TObject);
    procedure btnColorFontClick(Sender: TObject);
    procedure btnFontClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure chkNums10Change(Sender: TObject);
    procedure chkNums5Change(Sender: TObject);
    procedure chkNumsAllChange(Sender: TObject);
    procedure chkNumsNoneChange(Sender: TObject);
    procedure comboNumsChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
  public
    ed: TATSynEdit;
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
  ColorDialog1.Color:= ed.Colors.TextFont;
  if ColorDialog1.Execute then
  begin
    ed.Colors.TextFont:= ColorDialog1.Color;
    ed.Update;
  end;
end;

procedure TfmOptions.btnColorBackClick(Sender: TObject);
begin
  ColorDialog1.Color:= ed.Colors.TextBG;
  if ColorDialog1.Execute then
  begin
    ed.Colors.TextBG:= ColorDialog1.Color;
    ed.Update;
  end;
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

procedure TfmOptions.comboNumsChange(Sender: TObject);
begin

end;


end.

