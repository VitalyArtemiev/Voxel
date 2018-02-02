unit BaseTypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Utility;

type

  rVec2 = record
    x, y: single;
  end;

  rVec3 = record
    x, y, z: single;
  end;

  rInt2 = record
    x, y: longint;
  end;

  rInt3 = record
    x, y, z: longint;
  end;

  { tAutoArray }

  generic tAutoArray<_T> = class
  private
    fCapacity: longword;

    procedure SetCapacity(AValue: longword); inline;
    function GetValues(i: longword): _T; inline;
    procedure SetValues(i: longword; AValue: _T); inline; //get rid of?
  public
    Count: longword;
    fValues: array of _T;
    property Values[i: longword]: _T read GetValues write SetValues; default;
    property Capacity: longword read fCapacity write SetCapacity;

    constructor Create(InitialCap: longword = 4);
    destructor Destroy; override;


    procedure Add(b: array of _T);
    procedure Add(v: _T); inline;
    procedure Clear;
  end;

  // pPtrListElement = ^rListElement;

  generic rListElement<_T> = record
    Content: _T;
    Next, Prev: ^rListElement;
  end;

  { tList }

  generic tList<_E> = class
  type
    rLE = specialize rListElement<_E>;
    pListElement = ^rLe;
  var
    Root: pListElement;
    Count: longword;

    class procedure Delete(pElement: pListElement);
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure AddNew(c: pointer);
  end;

  //Manhattan distance
  function MHD(c1, c2: rVec3): single;
  function MHD(c1, c2: rInt3): longword;

  operator + (a, b: rVec3) r: rVec3;

implementation

uses
  math;

function MHD(c1, c2: rVec3): single;
begin
  Result:= abs(c1.x - c2.x) + abs(c1.y - c2.y) + abs(c1.z - c2.z);
end;

function MHD(c1, c2: rInt3): longword;
begin
  Result:= abs(c1.x - c2.x) + abs(c1.y - c2.y) + abs(c1.z - c2.z);
end;

operator + (a, b: rVec3) r: rVec3;
begin
  r.x:= a.x + b.x;
  r.y:= a.y + b.y;
  r.z:= a.z + b.z;
end;

{ tAutoArray }

procedure tAutoArray.SetCapacity(AValue: longword);
begin
  if fCapacity = AValue then
    Exit;
  fCapacity:= AValue;
  setlength(fValues, fCapacity);
end;

function tAutoArray.GetValues(i: longword): _T;
begin
  Result:= fValues[i];
end;

procedure tAutoArray.SetValues(i: longword; AValue: _T);
begin
  fValues[i]:= AValue;
end;

constructor tAutoArray.Create(InitialCap: longword = 4);
begin
  Count:= 0;
  if InitialCap > 4 then
    Capacity:= InitialCap
  else
    Capacity:= 4;
end;

destructor tAutoArray.Destroy;
begin
  setlength(fValues, 0);
end;

procedure tAutoArray.Add(b: array of _T);
var
  i, c: integer;
begin
  c:= Count;
  Count+= length(b);
  if Count > Capacity then
    Capacity:= Capacity + max(Capacity shr 2, length(b));
  for i:= 0 to high(b) do
    Values[c + i]:= b[i];
end;

procedure tAutoArray.Add(v: _T);
begin
  inc(Count);
  if Count > Capacity then
    Capacity:= Capacity + Capacity shr 2;
  Values[Count - 1]:= v;
end;

procedure tAutoArray.Clear;
begin
  Count:= 0;
  Capacity:= 4;
end;

{ tList }

class procedure tList.Delete(pElement: pListElement);
begin
  with pElement^ do
  begin
    freeandnil(Content); { TODO : dispose?? possible on objects}
    //TObject(Content).Destroy;
    Prev^.Next:= Next;
    dispose(pListElement(@self));
  end;
end;

constructor tList.Create;
begin
  Root:= nil;
  Count:= 0;
end;

destructor tList.Destroy;
begin
  Clear;
end;

procedure tList.Clear;
var
  p1, p2: pListElement;
begin
  p1:= Root;
  while p1 <> nil do
  begin
    p2:= p1^.Next;
    dispose(p1);
    p1:= p2;
  end;
  Count:= 0;
end;

procedure tList.AddNew(c: pointer);
var
  p: pListElement;
begin
  inc(Count);
  new(p);
  with p^ do
  begin
    Content:= c;
    Next:= Root;
    Prev:= nil;
  end;
  Root:= p;
end;

end.

