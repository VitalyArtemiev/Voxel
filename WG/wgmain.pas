unit WGMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Arrow, ComCtrls, Spin, StdCtrls, wgBase;

type

  { TForm1 }

  TForm1 = class(TForm)
    ALeft: TArrow;
    ARight: TArrow;
    AUp: TArrow;
    ADown: TArrow;
    Label1: TLabel;
    PaintBox: TPaintBox;
    SpinEdit1: TSpinEdit;
    TrackBar1: TTrackBar;
    procedure FormCreate(Sender: TObject);
    procedure PaintBoxClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.PaintBoxClick(Sender: TObject);
var
  t: tDateTime;
begin
  freeandnil(world);
  t:= now;
  World:= cWorld.Create(PaintBox.Width, PaintBox.Height, TrackBar1.Position + 1);
  t:= now - t;
  Label1.Caption:= TimeTOStr(t);
  World.Draw(PaintBox);
end;

end.

