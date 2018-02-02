unit app;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2, Window, Utility, Files, Options, World, Audio, GL,
  GUI, Player;

type

  //write own exception class

  rAction = record
    MousePressed,
    Left, Right, Forwards, Backwards, Up, Down,
    PitchDown, PitchUp,
    YawLeft, YawRight,
    RollLeft, RollRight,
    WireFrame,
    DrawFrame,
    Paused: Boolean;
    mx, my: single;
  end;
                                     //messes with gameloop
  eGAState = (sMainMenu, sGameLoop, {sPauseLoop,} sShutDown);

  eAppAction = (aHalt, aExitSublevel, aStartGame, aPauseGame);

  { tGameApp }

  tGameApp = class
  private
    //Event: tSDL_Event;
    Image: pSDL_Surface;
    World: tWorld;

    function LoadConfig: integer;

    //procedure ProcessInput;
    procedure ProcessAI;
    procedure ProcessEconomy;
    procedure ProcessGameLogic;
    procedure ProcessPhysics;
    procedure Render;
    procedure RenderUI;

  public//shed
    {Done,} //ExitRequest: boolean;
    Options: tOptions;
    State: eGAState;
    GameWindow: tGameWindow;
    Menu: tGUI;
    Player: tPlayer;

    constructor Create;
    function Initialize: integer;
    procedure MainLoop;
    procedure MenuLoop;
    procedure GameLoop;
    procedure PauseLoop;
    procedure Finish;
    destructor Destroy; override;
  end;

const
  MovRate = 0.02;
  RotRate = 1;

  ConfigName = 'init.cfg';
  MainMenuFile = 'mm.uid'; //ui desc
  PauseMenuFile = 'pm.uid';

var
  GameApp: tGameApp;

implementation

{ tGameApp }

function tGameApp.LoadConfig: integer;
var
  FS: tFileStream;
  PrFN: string;  //profile filename
begin
  Result:= 0;
  try
    if FileExists(ConfigName) then
    begin
      WriteLog('Opening file ' + ConfigName);
      try
        FS:= tFileStream.Create(ConfigName, fmOpenRead);
        PrFN:= FS.ReadAnsiString;
        //WriteLog('Read filename ' + PrFN);
      except
        on E: Exception do
        begin
          Result:= -1;
          WriteLog(emNoF + ConfigName + ': ' + E.Message);
          //repair file
          FS.Free;
          FS:= tFileStream.Create(ConfigName, fmOpenWrite);
          PrFN:= DefaultProfileName + ProfileExt;
          FS.WriteAnsiString(PrFN);
          //Options.WriteDefault(FS);
          { TODO : repair config? } //extensive check for compat?
        end
      end;
    end
    else //New File
    begin
      WriteLog('Creating file ' + ConfigName);
      try
        FS:= tFileStream.Create(ConfigName, fmCreate);
        PrFN:= DefaultProfileName + ProfileExt;
        FS.WriteAnsiString(PrFN);
        //Options.WriteDefault(FS);
      except
        on E: Exception do
        begin
          Result:= -2;
          WriteLog(emCrF + ConfigName + ': ' + E.Message);
        end
      end;
    end;
  finally
    FS.Free;
    Player:= tPlayer.Create(Options);  //currently does nothing
    Player.LoadProfile(PrFN);
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
  with Player.Action, Options.GamePlay do
  begin
    with World.Camera.c do
    begin
      if left then x+= movrate;
      if right then x-= movrate;
      if forwards then z+= movrate;
      if backwards then z-= movrate;
      if up then y-= movrate;
      if down then y+= movrate;
    end;

    with World.Camera.o, Options do
    begin
      if pitchup then x-= rotrate;
      if pitchdown then x+= rotrate;
      if yawright then y+= rotrate;
      if yawleft then y-= rotrate;
      if rollright then z+= rotrate;
      if rollleft then z-= rotrate;

      x+= my * MouseSensitivity;
      y+= mx * MouseSensitivity;
    end;
  end;
end;

procedure tGameApp.Render;
begin
  //World.Wireframe:= PlayerAction.WireFrame;
  World.Render;
  GameWindow.Update;
end;

procedure tGameApp.RenderUI;
begin
  glClear(GL_COLOR_BUFFER_BIT {or GL_DEPTH_BUFFER_BIT});
  {SDL_BlitSurface(Image, nil, GameWindow.Surface, nil);
  SDL_UpdateWindowSurface(GameWindow.WindowHandle);  }
  Menu.Render;
  GameWindow.Update;
end;

constructor tGameApp.Create;
begin
  GameWindow:= tGameWindow.Create;
end;

function tGameApp.Initialize: integer;
begin
  Options:= tOptions.Create;

  {$IFOPT D+}
  Options.System.KeepLog:= true;
  Options.System.PrintToConsole:= true;
  {$ENDIF}

  Result:= LoadConfig;
  if Result <> 0 then
    exit;
  //Options:= Player.Options;

  {Menu:= tGUI.Create;
  Result:= Menu.LoadContents(MainMenuFile);
  if Result <> 0 then
    exit;
  Menu.Options:= Player.Options; }

  State:= sMainMenu;

  randomize;
  try
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

    Result:= SDL_Init(SDL_INIT_TIMER or SDL_INIT_AUDIO or SDL_INIT_VIDEO);
    if Result < 0 then
      WriteLog(SDL_GetError)
    else
    begin
      Result:= GameWindow.Open('vx', false, 0, 0, Options.Graphics.XRes, Options.Graphics.XRes);
      SDL_GL_SetSwapInterval(0);

      if Result = 2 then
      begin
        //sdl_videoinit ??
        Image:= LoadImage('Logo.bmp');
      end;
    end;
  except
    on e: exception do
      writelog(e.message);
  end;

  AudioEngine.Create;
end;

procedure tGameApp.MainLoop;
begin
  WriteLog('Entered Main Loop');
  repeat
    case State of
      sMainMenu:
      begin
        MenuLoop;
      end;
      sGameLoop:
      begin
        GameLoop;
      end;
    end;
  until State = sShutDown;
  WriteLog('Left Main Loop');
end;

procedure tGameApp.MenuLoop;
var
  Result: integer;
begin
  SDL_SetRelativeMouseMode(SDL_FALSE);
  with GameWindow do
  begin
    SDL_BlitSurface(Image, nil, Surface, nil);
    SDL_UpdateWindowSurface(GameWindow.WindowHandle);
  end;
  Menu:= tGUI.Create;
  Result:= Menu.LoadContents('');
  //Menu.EscExits:= true;
  Menu.Options:= Player.Options;
  if Result <> 0 then
    WriteLog(emNoF + '');
  Menu.Render;

  GameWindow.Update;

  WriteLog('Entered Menu');
  repeat
    Menu.ProcessInput;
    Menu.Render;
    RenderUI;
  until State <> sMainMenu;

  WriteLog('Left Menu');

  freeandnil(Menu);
end;

procedure tGameApp.GameLoop;
var
  Result: integer;
begin
  SDL_SetRelativeMouseMode(SDL_TRUE);
  Menu:= tGUI.Create;
  Result:= Menu.LoadContents(''); //this is the actual pause menu
 // Menu.EscExits:= false;
  if Result <> 0 then
    WriteLog(emNoF + '');
  //Menu.Render;

  WriteLog('Setting up world');
  //loading screen
  World:=
        //tWorld.LoadHM('map1024');
  tWorld.CreateNew(random(100));
  //writeln('done');
  World.PassVoxels;

  World.Camera.c.x:= 0;
  World.Camera.c.y:= 0;
  World.Camera.c.z:= 0;

  World.Camera.o.x:= 0;
  World.Camera.o.y:= 0;
  World.Camera.o.z:= 0;

  with Player, Player.Action do
  begin
    PitchDown:= false;
    PitchUp:= false;
    RollLeft:= false;
    RollRight:= false;
    YawLeft:= false;
    YawRight:= false;

    repeat
      if Paused then
        PauseLoop;

      ProcessAI;
      ProcessEconomy;
      ProcessInput;
      ProcessPhysics;
      ProcessGameLogic;
      //if PlayerAction.DrawFrame then
      Render;
      //PlayerAction.DrawFrame:= false;
    until State <> sGameLoop;

    Paused:= false;
  end;
  WriteLog('Destroying world');
  freeandnil(World);
  freeandnil(Menu);
end;

procedure tGameApp.PauseLoop;
begin
  SDL_SetRelativeMouseMode(SDL_FALSE);

  WriteLog('Paused');
  repeat
    Menu.ProcessInput;
    RenderUI;
  until not Player.Action.Paused;
  WriteLog('Unpaused');

  SDL_SetRelativeMouseMode(SDL_TRUE);
end;

procedure tGameApp.Finish;
begin
  SDL_Quit;
  World.Free;
  Player.Free;
  Menu.Free;
end;

destructor tGameApp.Destroy;
begin
  GameWindow.Free;
  AudioEngine.Free;
end;

end.
