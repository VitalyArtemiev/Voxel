program vx;

{$mode objfpc}{$H+}
{$APPTYPE GUI}
uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, Voxel, ptrlist, entities, app, Window, Files, Utility, Economy,
Character, World
  { you can add units after this };

//int main( int argc, char* args[] )  SDL requires this type of main so it is compatible with multiple platforms.


begin
  GameApp:= tGameApp.Create;
  if GameApp.Initialize <> 0 then halt(-1);
  GameApp.MainLoop;//readln;
  GameApp.Finish;
  GameApp.Destroy;
  halt(0);//?
end.

