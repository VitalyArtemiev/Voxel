unit Utility;

{$mode objfpc}
{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils;

type
  tSeed = longword;

  generic rNode<T> = record { TODO -cCompiler bug : Update compiler to be able to get rid of tself and advancedrecords switch }
  public type
    TSelf = specialize rNode<T>;
    pNode = ^TSelf;
  public
    Value: T;
    Next: pNode;
  end;

  //generic sNode<T> = specialize rNode<T>;
  //generic pNode<T> = specialize ^rNode<T>;
  {generic rNode<T> = record
    data: T;
    next: ^specialize rNode<T>;
  end; }


const
  DefaultLogName = 'ProgramLog.txt';

{$I msgstrings.inc}

procedure WriteLog(s: string; Force: boolean = false);
//procedure WriteLog(p: pchar);

function srand(Range, Seed: tSeed): longword;

function strf(v: integer): string;
function strf(v: double): string;

function Toggle(var v: boolean): boolean;

function GetBit(b: byte; n: integer): boolean;

implementation

uses
  math, app;

var
  ProgramLog: TFileStream;

procedure WriteLog(s: string; Force: boolean = false);
begin
  s+= LineEnding;
  if Force or GameApp.Options.System.KeepLog then
  begin
    ProgramLog.Write(s[1], length(s));
    if GameApp.Options.System.PrintToConsole then
      writeln(s);
  end;
end;

{procedure WriteLog(p: pchar);
var
  s: string;
begin
  s:= string(p);
  s+= LineEnding;
  ProgramLog.Write(s[1], length(s));
end; }

function srand(Range, Seed: tSeed): longword;
begin
      RandSeed:= Seed;
      srand:= random(Range);
end;

function strf(v: integer): string;
begin
  str(v, Result);
end;

function strf(v: double): string;
begin
  str(v, Result);
end;

function Toggle(var v: boolean): boolean;
begin
  v:= not v;
  Result:= v;
end;

function GetBit(b: byte; n: integer): boolean;
var
  mask: byte;
begin  //intpower maybe
  case n of
    1: mask:= %00000001;
    2: mask:= %00000010;
    3: mask:= %00000100;
    4: mask:= %00001000;
    5: mask:= %00010000;
    6: mask:= %00100000;
    7: mask:= %01000000;
    8: mask:= %10000000;
  end;

  if b and mask > 0 then
    Result:= true
  else
    Result:= false;
end;

initialization
  ProgramLog:= TFileStream.Create(DefaultLogName, fmCreate);

finalization
  ProgramLog.Free;

end.
