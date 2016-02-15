unit ptrlist;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils;

type

  pPtrListElement = ^rPtrListElement;

  rPtrListElement = record
    Content: pointer;
    Next, Prev: pPtrListElement;
  end;

  { ListHelper }

  ListHelper = record helper for rPtrListElement
    procedure Delete;
  end;

  { tPtrList }

  tPtrList = class
    Root: pPtrListElement;
    Count: longword;
    constructor Create;
    destructor Destroy;
    procedure Clear;
    procedure AddNew(c: pointer);
  end;

implementation

{ ListHelper }

procedure ListHelper.Delete;
begin
  TObject(Content).Destroy;
  dispose(pPtrListElement(@self));
  Prev^.Next:= Next;
end;

{ tPtrList }

constructor tPtrList.Create;
begin
  Root:= nil;
  Count:= 0;
end;

destructor tPtrList.Destroy;
begin
  Clear;
end;

procedure tPtrList.Clear;
var
  p1, p2: pPtrListElement;
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

procedure tPtrList.AddNew(c: pointer);
var
  p: pPtrListElement;
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

