unit Util;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

  procedure WriteProgramLog(Log: string; Force: boolean = false);
  procedure WriteProgramLog(i: longint; Force: boolean = false);
  procedure WriteProgramLog(i: int64; Force: boolean = false);
  procedure WriteProgramLog(d: double; Force: boolean = false);
  //procedure SeparateIndices(Source: string; sa: TStrings; var ia: tStringArray);

  function strf(x: double): string;
  function strf(x: longint): string;
  function strf(x: int64): string;
  function valf(s: string): integer;
  function vald(s: string): double;

  function CopyFromTo(Origin: string; Start, Stop: string): string;
  function CopyFromTo(Origin: string; SearchStart: integer; Start, Stop: string): string;

  function CopyDelFromTo(var Origin: string; Start, Stop: string): string;
 // function SubstrCount(const aString, aSubstring: string): Integer;

var
  ProgramLog: TFileStream;
  LogCS: TRTLCriticalSection;

implementation

  uses
     LConvEncoding, Math,  StrUtils;

  function strf(x: double): string; inline;
  begin
    str(x, Result);
  end;

  function strf(x: longint): string; inline;
  begin
    str(x, Result);
  end;

  function strf(x: int64): string;
  begin
    str(x, Result);
  end;

  function valf(s: string): integer; inline;
  begin
    val(s, Result);
  end;

  function vald(s: string): double; inline;
  begin
    val(s, Result);
  end;

  function CopyFromTo(Origin: string; Start, Stop: string): string;
  var
    p1, p2: integer;
  begin
    p1:= Pos(Start, Origin) + 1;
    p2:= Pos(Stop, Origin);
    Result:= Copy(Origin, p1, p2 - p1);
  end;

  function CopyFromTo(Origin: string; SearchStart: integer; Start, Stop: string
    ): string;
  var
    p1, p2, i, l: integer;
  begin
    Delete(Origin, 1, SearchStart - 1);
    l:= length(Start);
    {if l > 1 then
      inc(l); }

    p1:= Pos(Start, Origin) + l;
    //Delete(Origin, 1, p1 - 1);
    //p1:= Pos(Start, Origin) + l;
    p2:= Pos(Stop, Origin);

    i:= 2;
    while p2 < p1 do
    begin
      p2:= NPos(Stop, Origin, i);
      inc(i);
      if i > 100 then
        break;
    end;

    Result:= Copy(Origin, p1, p2 - p1);
  end;

  function CopyDelFromTo(var Origin: string; Start, Stop: string): string;
  var
    p1, p2: integer;
  begin
    p1:= Pos(Start, Origin) + 1;
    p2:= Pos(Stop, Origin);
    Result:= Copy(Origin, p1, p2 - p1);
    Delete(Origin, 1, p2 + length(Stop) - 1);
  end;

  {function SubstrCount(const aString, aSubstring: string): Integer;
  var
    lPosition: Integer;
  begin
    Result := 0;
    lPosition := PosEx(aSubstring, aString);
    while lPosition <> 0 do
    begin
      Inc(Result);
      lPosition := PosEx(aSubstring, aString, lPosition + Length(aSubstring));
    end;
  end; }

  procedure WriteProgramLog(Log: string; Force: boolean = false); inline;
  begin
    if true or Force then
    try
      EnterCriticalSection(LogCS);
        Log+= LineEnding;
        ProgramLog.Write(Log[1], length(Log));
    finally
      LeaveCriticalSection(LogCS);
    end;
  end;

  procedure WriteProgramLog(i: longint; Force: boolean = false); inline;
  begin
    WriteProgramLog(strf(i), Force);
  end;

  procedure WriteProgramLog(i: int64; Force: boolean = false); inline;
  begin
    WriteProgramLog(strf(i), Force);
  end;

  procedure WriteProgramLog(d: double; Force: boolean = false); inline;
  begin
    WriteProgramLog(strf(d), Force);
  end;

  initialization
  begin
    if FileExists('ProgramLog.txt') then
      DeleteFile('ProgramLog.txt');
    ProgramLog:= TFileStream.Create('ProgramLog.txt', fmCreate);
    InitCriticalSection(LogCS);
  end;

  finalization
  begin
    DoneCriticalSection(LogCS);
    ProgramLog.Free;
  end;

end.

