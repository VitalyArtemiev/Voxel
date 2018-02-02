unit entities;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BaseTypes;

type

  rProjectileProperties = record
    Mass, MuzzleVelocity, Drag, ArmorPiercing, Penetration: Single;
  end;

  tEntityID = longword;

  { tVectorContainer }

  tVectorContainer = class
  private
    fCapacity: longword;
    procedure SetCapacity(AValue: longword);
  public
    xs, ys, zs: array of single;
    Count: longword;
    property Capacity: longword read fCapacity write SetCapacity ;
    constructor Create(InitialCap: longword);
    destructor Destroy; override;
    function Add(v: rVec3): longword;
    function AddManual(v: rVec3): longword;
    procedure Clear;
  end;

  eEventKind = (eArrival, eActivityFinish);

  pEvent = ^rEvent;

  { tEntity }

  tEntity = class
    c,        //coordinates
    o: rVec3; //orientation
    procedure GenerateEvent(Event: pEvent; Owner: tEntity);
  end;

  rEvent = record
    Time: tDateTime;
    Owner: tEntity;
    Kind: eEventKind;
    Next: pEvent;
  end;

  tLocation = class
    //owner?//
    //Voxel: tVoxel;
    Coords: rVec3;
  end;

  tStructure = class(tEntity)
    Seed: longword;

  end;

  { tMovableEntity }

  tMovableEntity = class(tEntity)
    ID: tEntityID;
    v: rVec3;   //velocity
    procedure Kinemate;
  end;

  tProjectile = class(tMovableEntity)
    Properties: ^rProjectileProperties;
  end;

  tCamera = class(tMovableEntity)

  end;

  tGroup = class

  end;

implementation

{ tEntity }

procedure tEntity.GenerateEvent(Event: pEvent; Owner: tEntity);
begin

end;

{ tVectorContainer }

procedure tVectorContainer.SetCapacity(AValue: longword);
begin
  fCapacity:= AValue;
  Setlength(xs, fCapacity);
  Setlength(ys, fCapacity);
  Setlength(zs, fCapacity);
end;

constructor tVectorContainer.Create(InitialCap: longword);
begin
  Count:= 0;
  if InitialCap > 4 then
    Capacity:= InitialCap
  else
    Capacity:= 4;
end;

destructor tVectorContainer.Destroy;
begin
  inherited Destroy;
end;

function tVectorContainer.Add(v: rVec3): longword;
begin
  inc(Count);
  if Count > Capacity then Capacity := Capacity + Capacity shr 2;
  Result:= Count - 1;
  xs[Result]:= v.x;
  ys[Result]:= v.y;
  zs[Result]:= v.z;
end;

function tVectorContainer.AddManual(v: rVec3): longword;
begin
  inc(Count);
  xs[Count - 1]:= v.x;
  ys[Count - 1]:= v.y;
  zs[Count - 1]:= v.z;
end;

procedure tVectorContainer.Clear;
begin

end;

{ tMovableEntity }

procedure tMovableEntity.Kinemate;
begin
  //c+= v * TimeStep;
end;

end.

