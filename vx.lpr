program vx;

{$mode objfpc}{$H+}
{$IFOPT D+}
  {$APPTYPE CONSOLE}
{$ELSE}
  {$APPTYPE GUI}
{$ENDIF}
uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, app, BaseTypes, GUI, Player, Options, customxml, audio;

//int main( int argc, char* args[] )  SDL requires this type of main so it is compatible with multiple platforms.

begin
  GameApp:= tGameApp.Create;
  if GameApp.Initialize <> 0 then
    halt(-1);

  GameApp.MainLoop;
  GameApp.Finish;
  GameApp.Destroy;
  halt(0);//?
end.

