unit Player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2, Utility, Options;

type

  rPlayerAction = record
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

  { tPlayer }

  tPlayer = class
  private
    Event: tSDL_Event;
  public
    Options: tOptions;
    Name: string;
    Action: rPlayerAction;

    constructor Create(Opts: tOptions);
    destructor Destroy; override;
    procedure LoadProfile(FileName: string);
    //character?
    procedure ProcessInput;
  end;

const
  DefaultProfileName = 'DefaultProfile';
  ProfileExt  = '.xml';

implementation

uses
  app;

{ tPlayer }

constructor tPlayer.Create(Opts: tOptions);
begin
  Options:= Opts; //this could create problems; is in todo
end;

destructor tPlayer.Destroy;
begin
  Options.Free;
  inherited Destroy;
end;

procedure tPlayer.LoadProfile(FileName: string); { TODO 1 -cimprovement : change into a func }
begin
  if FileExists(FileName) then
  begin
    //Options.Free;      { TODO : Possible overlap from different profiles: needs reset }
    //Options:= tOptions.Create;
    WriteLog('Loading player profile ' + FileName);
    Options.Load(FileName);    //Secondary, overriding primary
   end
  else
  begin   { TODO : warn about missing profile }
    WriteLog('Player profile is missing');
    Options.WriteDefault(FileName);
  end;
end;

procedure tPlayer.ProcessInput;
begin
  with Action do
  begin
    mx:= 0;
    my:= 0;
    while SDL_PollEvent(@Event) = 1 do
      with Event do
      begin
        case type_ of
          SDL_MOUSEBUTTONDOWN: MousePressed:= true;  // Mouse button pressed
          SDL_MOUSEBUTTONUP:   MousePressed:= false;

          SDL_MouseMotion:
          begin
            mx:= motion.xrel;
            my:= motion.yrel;
          end;

          SDL_KeyDown:
          case Options.cs[eScanCode(key.keysym.scancode)] of
            aLeft:      Left:= true;
            aRight:     Right:= true;
            aForward:   Forwards:= true;
            aBackward:  Backwards:= true;
            aUpward:    Up:= true;
            aDownward:  Down:= true;
            aPitchDown: PitchDown:= true;
            aPitchUp:   PitchUp:= true;
            aYawLeft:   YawLeft:= true;
            aYawRight:  YawRight:= true;
            aRollLeft:  RollLeft:= true;
            aRollRight: RollRight:= true;
            aEsc: Paused:= true;
          end;

          SDL_KeyUp:
          case Options.cs[eScanCode(key.keysym.scancode)] of
            aLeft:      Left:= false;
            aRight:     Right:= false;
            aForward:   Forwards:= false;
            aBackward:  Backwards:= false;
            aUpward:    Up:= false;
            aDownward:  Down:= false;
            aPitchDown: PitchDown:= false;
            aPitchUp:   PitchUp:= false;
            aYawLeft:   YawLeft:= false;
            aYawRight:  YawRight:= false;
            aRollLeft:  RollLeft:= false;
            aRollRight: RollRight:= false;
          end;

          SDL_QuitEv: GameApp.State:= sShutDown;
          else WriteLog(strf(Event.key.keysym.scancode));
        end;
      end;
  end;
end;

end.

