unit audio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2, SDL2_Mixer, BaseTypes, Utility;

type

  { tAudioEngine }

  rNote = record
    Pitch, Velocity: word;
    Duration, Position: single;
  end;

  rPattern = array of rNote;
  {tPattern = class
    A: array of ; default;
  end;}

  eEffect = (eNone, eUnderwater);

  rTone = record
    FS: tMemoryStream;  //has memory pointer and loadfromfile, but sdl mixer also has load from file
  end;

  rTrack = record
    Effect: eEffect;
    Volume: single;
    Patterns: array of rPattern;
    Tones: array of rTone;
    Sequence: array of integer;
  end;

  eToneKind = (tPercussion, tNormal);

  { tComposition }

  tComposition = class
    Seed: tSeed;
    PercussionTracks: integer;
    Tracks: array of rTrack;
    procedure SynthesizeTones(TrackNr: integer; TK: eToneKind);  //percussion in 0..n?
    procedure ComposePatterns(TrackNr: integer; TK: eToneKind);

    constructor Create(aSeed: tSeed);
    destructor Destroy; override;
  end;

  { tComposer }

  tComposer = class
    CurrentComp, NextComp: tComposition;
    {function CompileWAV: pointer; //compiles next }
  public
    function GetNext: pointer; //returns pointer to wav, switches next to cur

    constructor Create;
    destructor Destroy; override;
  end;

  tAudioEngine = class  //needs to be able to mix several simult as well as play in background

    {queue
    Files: array
    function LoadFile(Filename: string): integer;
    procedure PlayFile(Index: integer);
    procedure StopPlayback;
    procedure AddToQueue(index: integer); }
    Composer: tComposer;
    constructor Create;
    destructor Destroy; override;
  end;

var
  AudioEngine: tAudioEngine;

implementation

{ tComposer }

function tComposer.GetNext: pointer;
begin
  CurrentComp.Free;
  CurrentComp:= NextComp;
  NextComp:= tComposition.Create(random(high(tSeed)));

end;

constructor tComposer.Create;
begin
  GetNext;
end;

destructor tComposer.Destroy;
begin
  inherited Destroy;
  CurrentComp.Free;
  NextComp.Free;
end;

{ tComposition }

procedure tComposition.SynthesizeTones(TrackNr: integer; TK: eToneKind);
begin
  with Tracks[TrackNr] do
  begin

  end;
end;

procedure tComposition.ComposePatterns(TrackNr: integer; TK: eToneKind);
begin
  with Tracks[TrackNr] do
  begin

  end;
end;

constructor tComposition.Create(aSeed: tSeed);
var
  i: integer;
  TK: eToneKind;
begin
  Seed:= aSeed;
  setlength(Tracks, 2 + srand(4, Seed));

  PercussionTracks:= length(Tracks) div 3;

  TK:= tPercussion;
  for i:= 0 to high(Tracks) do
    begin
      if i >= PercussionTracks then
        TK:= tNormal;
      SynthesizeTones(i, TK);
      ComposePatterns(i, TK);
    end;
end;

destructor tComposition.Destroy;
begin
  inherited Destroy;
  setlength(Tracks, 0);
end;

{ tAudioEngine }

constructor tAudioEngine.Create;
begin
  Composer:= tComposer.Create;

end;

destructor tAudioEngine.Destroy;
begin
  inherited Destroy;
end;

end.

