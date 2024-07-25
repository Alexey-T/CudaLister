unit form_find;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  StdCtrls, ExtCtrls;

type

  { TfmFind }

  TfmFind = class(TForm)
    bCount: TButton;
    bMarkAll: TButton;
    bFind: TButton;
    bCancel: TButton;
    bRep: TButton;
    bRepAll: TButton;
    chkInSel: TCheckBox;
    chkFromCaret: TCheckBox;
    chkConfirm: TCheckBox;
    chkRep: TCheckBox;
    chkRegex: TCheckBox;
    chkBack: TCheckBox;
    chkCase: TCheckBox;
    chkWords: TCheckBox;
    edFind: TEdit;
    edRep: TEdit;
    Label1: TLabel;
    lblStatus: TLabel;
    Timer1: TTimer;
    procedure chkRegexChange(Sender: TObject);
    procedure chkRepChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FTimerTime:integer;
    procedure Update; reintroduce;
    { private declarations }
  public
    { public declarations }
  end;

var
  fmFind: TfmFind;

implementation

{$R *.lfm}

{ TfmFind }

procedure TfmFind.chkRegexChange(Sender: TObject);
begin
  Update;
end;

procedure TfmFind.chkRepChange(Sender: TObject);
begin
  Update;
end;

procedure TfmFind.FormShow(Sender: TObject);
begin
  if lblStatus.Caption<>'' then
    begin
    Timer1.Enabled:=false;
    FTimerTime:=0;
    Timer1.Enabled:=true;
    end;
  Update;
end;

procedure TfmFind.Timer1Timer(Sender: TObject);
begin
  if (FTimerTime mod 2=0) then lblStatus.Font.Color:=clRed else lblStatus.Font.Color:=clDefault;
  FTimerTime:=FTimerTime+1;
  if FTimerTime>10 then
    begin
    lblStatus.Font.Color:=clDefault;
    //lblStatus.Caption:='';
    FTimerTime:=0;
    Timer1.Enabled:=false;
    end;
end;

procedure TfmFind.Update;
var
  rep: boolean;
begin
  rep:= chkRep.Checked;

  chkWords.Enabled:= not chkRegex.Checked;
  chkBack.Enabled:= not chkRegex.Checked;
  chkConfirm.Enabled:= rep;
  edRep.Enabled:= rep;
  bFind.Visible:= not rep;
  bRep.Visible:= rep;
  bRepAll.Visible:= rep;

  if rep then
    Caption:= 'Replace'
  else
    Caption:= 'Find';

  if rep then
    bRep.Default:= true
  else
    bFind.Default:= true;
end;

end.

