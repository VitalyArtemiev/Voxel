unit WGBase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls;

type
  rVec2 = record
    x, y: double;
  end;

  pVoxel = ^rVoxel;

  rVoxel = record
    Child: array [0..3] of pVoxel;
  end;

  tGrid = array of array of double;

  tVectorArray = array[0..7] of rVec2;

  { cVectorGrid }

  cVectorGrid = class
  private
    GridDim: longword;
    fGrid: array of rVec2;
    function GetVec(i, j: integer): rVec2;
    procedure SetVec(i, j: integer; AValue: rVec2);
  public
    seed: longword;
    //property Grid[i, j: integer]: rVec2 read GetVec write SetVec;
    Grid: array[-20..+20, -20..+20] of rVec2;
    procedure GenVectors;
    function GetIDP(v: rVec2; GridSize: double): double;
  end;


  { cWorld }

  cWorld = class
    Pos: rVec2;
    Grid: tGrid;
    VectorGrid: cVectorGrid;
    TerSeed: longword;
    RootVoxel: pVoxel;
    constructor Create(Sx, Sy, Seed: longword);
    destructor Destroy;
    procedure GetTerrain(p1,p2: rVec2; VoxLvl: word);
    procedure Draw(pb: tPaintBox);
  end;

const
  MinVoxelDim = 1;

var
  World: cWorld;

implementation

uses
  Dialogs, Noises, Util;

function max(a,b:integer): integer;
begin
  if a>=b then
    Result:= a
  else
    Result:= b;
end;

function srand(seed: longword): double; //inline;
begin
  randseed:= seed;
  Result:= random;
end;

operator + (a,b: rVec2): rVec2;
begin
  Result.x:= a.x + b.x;
  Result.y:= a.y + b.y;
end;

operator - (a,b: rVec2): rVec2;
begin
  Result.x:= a.x - b.x;
  Result.y:= a.y - b.y;
end;

function Vec2(x, y: single): rVec2; inline;
begin
  Result.x:= x;
  Result.y:= y;
end;

{ cVectorGrid }

function cVectorGrid.GetVec(i, j: integer): rVec2;
begin
  if (abs(i) > GridDim) or (abs(j) > GridDim) then
  begin
    setlength(fGrid, sqr(max(i,j)*2 +1));
  end;
end;

procedure cVectorGrid.SetVec(i, j: integer; AValue: rVec2);
begin

end;

procedure cVectorGrid.GenVectors;
var
  i, j: Integer;
begin

  for i:= low(Grid) to high(Grid) do
    for j:= low(Grid) to high(Grid) do
    begin
      Grid[i, j].x:= random - 0.5;
      Grid[i, j].y:= random - 0.5;
      normalize(Grid[i, j]);
    end;


end;

function cVectorGrid.GetIDP(v: rVec2; GridSize: double): double; //interpolated dot prod
var
  i, gx, gy, dx, dy: integer;
  l: rVec2;
  GridVectors: tVectorArray;

  p: array [0..3] of double;
begin
  gx:= round(v.x / GridSize);
  if gx >= 0 then
    dx:= 1
  else
    dx:= -1;
  gy:= round(v.y / GridSize);
   if gy >= 0 then
     dy:= 1
   else
     dy:= -1;

  GridVectors[4]:= Vec2(gx, gy) - v;   //wrong square
  GridVectors[5]:= Vec2(gx + GridSize*dx, gy) - v;
  GridVectors[6]:= Vec2(gx + GridSize*dx, gy + GridSize*dy) - v;
  GridVectors[7]:= Vec2(gx, gy + GridSize*dy) - v;

  GridVectors[0]:= Grid[gx,gy];
  GridVectors[1]:= Grid[gx + dx,gy];
  GridVectors[2]:= Grid[gx + dx, gy + dy];
  GridVectors[3]:= Grid[gx,gy + dy];

  for i:= 0 to 7 do
  begin
    //GridVectors[i]:= Vec2(gx, gy) - v;
    Normalize(GridVectors[i]);
  end;

  {for i:= 0 to 3 do
  begin
    GridVectors[i].x:= srand(arg + i) - 0.5;
    GridVectors[i].y:= srand(arg + 4 + i) - 0.5;
    Normalize(GridVectors[i]);
  end; }

  l.x:= abs(v.x - gx * GridSize);
  l.y:= abs(v.y - gy * GridSize);

  if l.x > 1 then showmessage('PIZDOS');

  for i:= 0 to 3 do
  begin
    p[i]:= DotProd(GridVectors[i], GridVectors[i + 4]);
    if p[i] > 1 then p[i]:= 1;
    //showmessage('PIZDOS');
  end;

  p[0]:= SmoothStep(p[0], p[1], l.x);
  if abs(p[0]) > 1 then{ p[i]:= 1; }
    //showmessage('PIZDOS1');
  p[1]:= SmoothStep(p[2], p[3], l.x);
  if abs(p[1]) > 1 then{ p[i]:= 1; }
    //showmessage('PIZDOS2');
  Result:= SmoothStep(p[0], p[1], l.y);
  if abs(Result) > 1 then{ p[i]:= 1; }
    //showmessage('PIZDOS3');
end;

{ cWorld }

constructor cWorld.Create(Sx, Sy, Seed: longword);
var
  i, j: integer;
  v: rVec2;
begin
  TerSeed:= Seed;
  //randomize;
  VectorGrid.Free;
  VectorGrid:= cVectorGrid.Create;
  VectorGrid.seed:= Seed;

  setlength(Grid, Sx, Sy);

  VectorGrid.GenVectors;

  for i:= 0 to Sx - 1 do
    for j:= 0 to Sy - 1 do
    begin
      v.x:= i / Sx - 0.5;
      v.y:= j / Sy - 0.5;

      {if p1 > p2 then     //do u even need this
      begin
        p1:= p1 + p2;
        p2:= p1 - p2;
        p1:= p1 - p2;
      end;   }

     { if p3 > p4 then
      begin
        p3:= p3 + p4;
        p4:= p3 - p4;
        p3:= p3 - p4;
      end; }

     { p1:= smoothstep(p1, p2, (v.x - cx)/seed);
      p2:= smoothstep(p3, p4, (v.y - cy)/seed);}

     { p1:= 2*(v.x - cx)*(p2-p1)/sx;
      p2:= 2*(v.y - cy)*(p4-p3)/sy;}

      Grid[i, j]:= VectorGrid.GetIDP(v, 0.025);
    end;
end;

destructor cWorld.Destroy;
begin
  VectorGrid.Destroy;
end;

procedure cWorld.GetTerrain(p1, p2: rVec2; VoxLvl: word);
begin

end;

procedure cWorld.Draw(pb: tPaintBox);
var
  i, j: integer;
  r: int64;
begin
  with pb, pb.Canvas do
  begin
    for i:= 0 to ClientWidth - 1 do
    begin
        for j:= 0 to ClientHeight - 1 do
          try
             r:= trunc(Grid[i,j]) mod $7FFFFFF ;
             Pixels[i, j]:= r;

          except
            on e: exception do
            begin
              e.Free;
            end;
          end;
    end;
  end;
end;

end.

