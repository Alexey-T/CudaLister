unit form_listbox;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ATListbox;

type

  { TfmListbox }

  TfmListbox = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Listbox: TATListbox;
    Panel1: TPanel;
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  fmListbox: TfmListbox;

implementation

{$R *.lfm}

{ TfmListbox }

procedure TfmListbox.FormShow(Sender: TObject);
begin
  AutoAdjustLayout(lapAutoAdjustForDPI,
    96,
    Screen.PixelsPerInch,
    Width,
    Scale96ToScreen(Width)
    );

  Listbox.ItemHeight:= Scale96ToScreen(20);
  Listbox.Invalidate;
end;

end.

