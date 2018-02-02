program xmltest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils,
  { you can add units after this }
  customxml;

type
  { ta }

  ta = class
    //procedure NewXMLFile;
  end;

var
  F: tXMLFile;
  a: ta;
  i: integer;
  d: double;
  s: string;

begin
  a:= ta.create;
  //F:= tXMLFile.CreateNew('Keys.xml', true);
  F:= TXMLFile.Open('Keys.xml');

  while F.IterateNodesWithName('keyb') do
  begin
    F.SetValue('action', 'aRight');
    F.SetValue('keyprim', 'c');
  end;
  F.Back;
  while F.IterateNodesWithName('keyd') do
  begin
    F.SetValue('action', 'aLeft');
    F.SetValue('keyprim', 'd');
  end;
  {
  F.Back;
  F.AddNode('keyb');
  f.SetValue('action', 'aRight');
  F.SetValue('keyprim', 'a');
  F.SetValue('keysec', 'b');
  F.BackToRoot;
  F.SetValue('kek', 1.5);
  d:= F.GetValue('kek');
  F.SetValue('kek1', d);
  F.SetValue('keks', 500);
  i:= F.GEtvalue('keks');
  F.SetValue('keks1', i);
  F.SetValue('kreks', 'peks');
  s:= F.GetValue('kreks');
  F.SetValue('kreks1', s);}
  //F.GetValue();

  //F:= tXMLFile.Open('tree.dae');
  //F.FindNode('asset', lThisNode);
  //F.AddNode();
  //F.SetValue();
  //F.Back;
  //F.ToRoot;
  //F.FindNode('',nAll)
  //F.GetValue();
  readln;
  freeandnil(F);
end.


