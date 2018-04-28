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
  private

  public

  end;

var
  fmListbox: TfmListbox;

implementation

{$R *.lfm}

end.

