unit app;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2, Window, Utility, Files, World, GL;

type

  //write own exception class

  rAction = record
    Left, Right, Forwards, Backwards, Up, Down,
    PitchDown, PitchUp,
    YawLeft, YawRight,
    RollLeft, RollRight,
    WireFrame,
    DrawFrame: Boolean;
  end;

  rOptions = record
    MouseSensitivity: single;
  end;

  { tGameApp }

  tGameApp = class
  private
    Event: tSDL_Event;
    Image: pSDL_Surface;
    World: tWorld;
    PlayerAction: rAction;
    Options: rOptions;

    procedure LoadOptions;

    procedure ProcessInput;
    procedure ProcessAI;
    procedure ProcessEconomy;
    procedure ProcessGameLogic;
    procedure ProcessPhysics;
    procedure Render;

  public//shed
    Done: boolean;
    GameWindow: tGameWindow;
    constructor Create;
    function Initialize: integer;
    procedure MainLoop;
    procedure Finish;
    destructor Destroy; override;
  end;

const
  MovRate = 0.2;
  RotRate = 1;

var
  GameApp: tGameApp;

implementation

{ tGameApp }

procedure tGameApp.LoadOptions;
begin
  Options.MouseSensitivity:= 0.8;
end;

procedure tGameApp.ProcessInput;
var
  mx: single = 0;
  my: single = 0;
  z: single = 0;
begin
  with PlayerAction do
  begin
    while SDL_PollEvent(@Event) = 1 do
      with Event do
      begin
        case type_ of
          SDL_MouseMotion:
            begin
              mx:= motion.xrel;
              my:= motion.yrel;
            end;
          SDL_KeyDown:
            begin
              case key.keysym.scancode of
                SDL_SCANCODE_A: Left:= true;
                SDL_SCANCODE_D: Right:= true;
                SDL_SCANCODE_W: Forwards:= true;
                SDL_SCANCODE_S: Backwards:= true;
                SDL_SCANCODE_SPACE: Up:= true;
                SDL_SCANCODE_LCTRL: Down:= true;

                SDL_SCANCODE_F: PitchUp:= true;
                SDL_SCANCODE_R: PitchDown:= true;
                SDL_SCANCODE_Q: YawLeft:=   true;
                SDL_SCANCODE_E: YawRight:=  true;
                SDL_SCANCODE_Z: RollLeft:=  true;
                SDL_SCANCODE_X: RollRight:= true;
                SDL_SCANCODE_P: Toggle(Wireframe);
                SDL_SCANCODE_N: DrawFrame:= true;

                SDL_SCANCODE_ESCAPE: Done:= true;
              end;
            end;
          SDL_KeyUp:
            begin
              case key.keysym.scancode of
                SDL_SCANCODE_A: Left:= false;
                SDL_SCANCODE_D: Right:= false;
                SDL_SCANCODE_W: Forwards:= false;
                SDL_SCANCODE_S: Backwards:= false;
                SDL_SCANCODE_SPACE: Up:= false;
                SDL_SCANCODE_LCTRL: Down:= false;

                SDL_SCANCODE_F: PitchUp:= false;
                SDL_SCANCODE_R: PitchDown:= false;
                SDL_SCANCODE_Q: YawLeft:=   false;
                SDL_SCANCODE_E: YawRight:=  false;
                SDL_SCANCODE_Z: RollLeft:=  false;
                SDL_SCANCODE_X: RollRight:= false;
              end;
            end;

          SDL_QuitEv: Done:= true;
        end;
      end;
    with World.CameraPosition do
    begin
      if left then x+= movrate;
      if right then x-= movrate;
      if forwards then z+= movrate;
      if backwards then z-= movrate;
      if up then y-= movrate;
      if down then y+= movrate;
    end;

    with World.CameraDirection, Options do
    begin
      if pitchup then x-= rotrate;
      if pitchdown then x+= rotrate;
      if yawright then y+= rotrate;
      if yawleft then y-= rotrate;
      if rollright then z+= rotrate;
      if rollleft then z-= rotrate;

      {writelog(strf(mx));
      writelog(strf(my)); }
      x+= my * MouseSensitivity;
      y+= mx * MouseSensitivity;
    end;
  end;
end;

procedure tGameApp.ProcessAI;
begin

end;

procedure tGameApp.ProcessEconomy;
begin

end;

procedure tGameApp.ProcessGameLogic;
begin

end;

procedure tGameApp.ProcessPhysics;
begin

end;

procedure tGameApp.Render;
begin
  World.Wireframe:= PlayerAction.WireFrame;
  World.Render;
  GameWindow.Update;
end;

constructor tGameApp.Create;
begin
  GameWindow:= tGameWindow.Create;
end;

function tGameApp.Initialize: integer;
begin
  LoadOptions;

  randomize;
  try
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

    Result:= SDL_Init(SDL_INIT_TIMER or SDL_INIT_AUDIO or SDL_INIT_VIDEO);
    if Result < 0 then
      WriteLog(SDL_GetError)
    else
    begin
      Result:= GameWindow.Open('vx', false, 0, 0, 1280, 1024);
      SDL_GL_SetSwapInterval(0);
      SDL_SetRelativeMouseMode(SDL_TRUE);

      if Result = 0 then
      begin
        //sdl_videoinit ??
        //Image:= LoadImage('Logo.bmp');
        //SDL_BlitSurface(Image, nil, GameWindow.Surface, nil);
        World:=
        tWorld.Load('map2048');
        //tWorld.CreateNew(random(100));
        //World.PassVoxels;
                                                    //2ND CALL LIST FOR BIG VOX
        World.CameraPosition.x:= 0;
        World.CameraPosition.y:= 0;
        World.CameraPosition.z:= 0;

        World.CameraDirection.x:= 0;
        World.CameraDirection.y:= 0;
        World.CameraDirection.z:= 0;

        PlayerAction.PitchDown:= false;
        PlayerAction.PitchUp:= false;
        PlayerAction.RollLeft:= false;
        PlayerAction.RollRight:= false;
        PlayerAction.YawLeft:= false;
        PlayerAction.YawRight:= false;

        GameWindow.Update;
        Done:= false;
      end;
    end;
  except
    on e: exception do writelog(e.message);
  end;
end;

procedure tGameApp.MainLoop;
begin
  repeat
    ProcessAI;
    ProcessEconomy;
    ProcessInput;
    ProcessPhysics;
    ProcessGameLogic;
    //if PlayerAction.DrawFrame then
    Render;
    //PlayerAction.DrawFrame:= false;
  until Done;
end;

procedure tGameApp.Finish;
begin
  SDL_Quit;
  World.Free;
end;

destructor tGameApp.Destroy;
begin
  GameWindow.Free;
end;

end.
