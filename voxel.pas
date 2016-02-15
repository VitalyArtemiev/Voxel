unit Voxel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  eVoxelPos = (BNW, BSW, TNW, TSW, BNE, BSE, TNE, TSE);

  { tVoxel }

  tVoxel = class                //43b
    Order: byte;        //1b
    Parent: tVoxel;     //4b
    Child: array [BNW..TSE] of tVoxel;    //neighbour[0..5]?   //32b
  private
    //NeedsUpdate: boolean;
    fContent: byte;           //1b
    procedure SetContent(CN: byte);
    //function GetContent: word;
  public
    property Content: byte read fContent write SetContent;

    constructor Create(ParentVoxel: tVoxel);
    destructor Destroy; override;
    destructor DestroyRoot;
  end;

  rLocation = record
    x, y: single;
    Voxel: tVoxel;
  end;

var
  VoxelFidelity: longword;
  StructureOrder: longword;
  MinVoxelDim: single = 0.25;//0.03125;

implementation

uses
  math;

function LoadVoxels(FileName: string): word;
var
  p: pointer;
begin

end;

function SaveVoxels: word;
begin

end;

{ tVoxel }

constructor tVoxel.Create(ParentVoxel: tVoxel);
begin
  Parent:= ParentVoxel;
  if ParentVoxel <> nil then
    begin
      Order:= Parent.Order + 1;
      Parent.Content:= Parent.Content + 1;
    end;

  fContent:= 0;
end;

destructor tVoxel.Destroy;
var
  i: eVoxelPos;
begin
  if Parent <> nil then
    Parent.Content:= Parent.Content - 1;
  for i:= BNW to high(Child) do
    if Child[i] <> nil then freeandnil(Child[i]);
end;

destructor tVoxel.DestroyRoot;
var
  i: eVoxelPos;
begin
  for i:= BNW to high(Child) do
    if Child[i] <> nil then Child[i].DestroyRoot;
end;

procedure tVoxel.SetContent(CN: byte);
begin
  fContent:= CN;
  if fContent = 0 then freeandnil(self);//better add to queue?
end;

{function tVoxel.GetContent: word;
begin

end;  }


end.

