unit Utility;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  DefaultLogName = 'ProgramLog.txt';

  {$I msgstrings.inc}

procedure WriteLog(s: string);
//procedure WriteLog(p: pchar);

function srand(Range, Seed: longword): longword;

function strf(v: integer): string;
function strf(v: double): string;

function Toggle(var v: boolean): boolean;

implementation

var
  ProgramLog: TFileStream;

procedure WriteLog(s: string);
begin
  s+= LineEnding;
  ProgramLog.Write(s[1], length(s));
end;

{procedure WriteLog(p: pchar);
var
  s: string;
begin
  s:= string(p);
  s+= LineEnding;
  ProgramLog.Write(s[1], length(s));
end; }

function srand(Range, Seed: longword): longword;
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


initialization
  ProgramLog:= TFileStream.Create(DefaultLogName, fmCreate);

finalization
  ProgramLog.Free;

end.
