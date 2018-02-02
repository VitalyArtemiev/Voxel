unit Options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CustomXML;

const
  KeyCount = 32;

type
  pBool= ^boolean;

  eGraphicsOptions = (grDrawFrame, grWireFrame);  { TODO 2 -cFeature : variant array with enumerators for every option   }

  ePlayerAction = (aEsc = -2, aNone = -1, aLeft, aRight, aForward, aBackward, aUpward, aDownward,
  aPitchDown, aPitchUp, aYawLeft, aYawRight, aRollLeft, aRollRight);

  {$INCLUDE keys.inc}

type

  rGraphicsOptions = record
    XRes, YRes: longword;
    //FOV
    DrawFrame, WireFrame: boolean;
  end;

  rGamePlayOptions = record

    MouseSensitivity: single;
  end;

  rSystemOptions = record
    KeepLog: boolean;
    PrintToConsole: boolean;
  end;

  {rControlScheme = record
    m: array[0..KeyCount - 1] of pBool;
  end; }

  { tOptions }

  tOptions = class
    CS: array[low(eScanCode)..high(eScanCode)] of ePlayerAction; // Control Scheme
    Graphics: rGraphicsOptions;
    GamePlay: rGamePlayOptions;
    System: rSystemOptions;

    function Load(FileName: string): integer;
    function Save(FileName: string): integer;
    function WriteDefault(FileName: string): integer;
  end;


implementation

uses
  SDL2, Utility;

{ tOptions }

function tOptions.Load(FileName: string): integer;
var
  F: tXMLFile;
  a: ePlayerAction;
  KeyCode: eScanCode;
  e: integer;
  s: string;
begin
  F:= tXMLFile.Open(FileName);

  if F = nil then
  begin
    WriteLog('Failed to load config');
    exit(-1);
  end;

  for KeyCode:= low(eScanCode) to high(eScanCode) do
  begin
    CS[KeyCode]:= aNone;
  end;

  F.FindNode('keybindings');

  while F.IterateNodesWithName('keyb') do
  begin
    s:= F.GetValue('action');
    WriteLog('Read string ' + s);
    val(s, a, e);
    if e <> 0 then
      continue;
    s:= F.GetValue('keyprim');  { TODO : make all these into enums }
    WriteLog('Read string ' + s);
    val(s, KeyCode, e);
    if e = 0 then
      CS[KeyCode]:= a;
  end;

  CS[scESCAPE]:= aEsc;

  F.BackToRoot;

  F.FindNode('graphicssettings');
  while F.IterateNodesWithName('grs') do
  begin
    s:= F.GetValue('name');
    case s of
      'xres': Graphics.XRes:= F.GetValue('value');
      'yres': Graphics.YRes:= F.GetValue('value');
      else Writelog('Warning: unrecognised setting name in ' + FileName + ': ' + s);
    end;
  end;
  F.BackToRoot;

  F.FindNode('gameplaysettings');
  while F.IterateNodesWithName('gms') do
  begin
    s:= F.GetValue('name');
    writelog(s);
    case s of
      'mousesens': GamePlay.MouseSensitivity:= F.GetValue('value');

      else Writelog('Warning: unrecognised setting name in ' + FileName + ': ' + s);
    end;
  end;

  F.Free;
end;

function tOptions.Save(FileName: string): integer;
var
  F: tXMLFile;
  a, v: string;
  KeyCode: eScanCode;
begin
  F:= tXMLFile.CreateNew(FileName, true);

  if F = nil then
  begin
    WriteLog('Failed to save config');
    exit(-1);
  end;

  F.AddNode('keybindings');
  for KeyCode:= low(eScanCode) to high(eScanCode) do
  begin
    if CS[KeyCode] <> aNone then
    begin
      str(CS[KeyCode], a);
      str(KeyCode, v);

      F.AddNode('keyb');
      F.SetValue('action', a);
      F.SetValue('keyprim', v);
      F.Back;
    end;
  end;
  F.Back;

  F.AddNode('graphicssettings');
    F.AddNode('grs');
    F.SetValue('name', 'xres');
    F.SetValue('value', Graphics.XRes);
    F.Back;

    F.AddNode('grs');
    F.SetValue('name', 'yres');
    F.SetValue('value', Graphics.YRes);
    F.Back;
  F.Back;

  F.AddNode('gameplaysettings');
    F.AddNode('gms');
    F.SetValue('name', 'mousesens');
    F.SetValue('value', GamePlay.MouseSensitivity);
    F.Back;
  F.Back;

  F.Free;

  Result:= 0;
end;

function tOptions.WriteDefault(FileName: string): integer;
var
  F: tXMLFile;
  i: ePlayerAction;
  a, v: string;
begin
  GamePlay.MouseSensitivity:= 0.8;
  Graphics.XRes:= 1000;
  Graphics.YRes:= 1000;
  System.KeepLog:= true;

  WriteLog('Writing default config to ' + Filename);

  F:= tXMLFile.CreateNew(FileName);

  if F = nil then
  begin
    WriteLog('Failed to create default config');
    exit(-1);
  end;

  F.AddNode('keybindings');
  for i:= aLeft to high(ePlayerAction) do //Has to start from aLeft, low(..) is -1!
    begin
      str(i, a);
      str(DefaultBinds[i], v);
      F.AddNode('keyb');
      F.SetValue('action', a);
      F.SetValue('keyprim', v);
      F.Back;
    end;
  F.Back;

  F.AddNode('graphicssettings');
    F.AddNode('grs');
    F.SetValue('name', 'xres');
    F.SetValue('value', Graphics.XRes);
    F.Back;

    F.AddNode('grs');
    F.SetValue('name', 'yres');
    F.SetValue('value', Graphics.YRes);
    F.Back;
  F.Back;

  F.AddNode('gameplaysettings');
    F.AddNode('gms');
    F.SetValue('name', 'mousesens');
    F.SetValue('value', GamePlay.MouseSensitivity);
    F.Back;
  F.Back;

  F.Free;

  Result:= 0;
end;

end.

