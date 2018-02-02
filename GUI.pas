unit GUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2, BaseTypes, Utility, Options;

type

{ tUIElement }

tUIElement = class
   Top, Left,
   Height, Width: integer;

   Enabled: boolean;

   procedure Draw; virtual;
end;

tUIEvent = procedure(Sender: tUIElement) of object;

{ tButton }

tButton = class(tUIElement)
private
  FOnPress: tUIEvent;
  procedure SetOnPress(AValue: tUIEvent);
published
  property OnPress: tUIEvent read FOnPress write SetOnPress;
end;

{ tPanel }

tPanel = class(tUIElement)
  Elements: array of tUIElement;
  Caption: string;

  destructor Destroy; override;
  function GetControlAtPos(p: rInt2): tUIElement;
  procedure Draw; override;
end;

{ tUIScreen }

tUIScreen = class
  Panels: array of tPanel;
  Level: integer;

  constructor Create;
  destructor Destroy; override;
  function LoadContents(FileName: string): integer;
  function GetControlAtPos(p: rInt2): tUIElement;
  procedure Draw;
end;

rUIMouse = record
  c: rInt2;
  PressedOver: tUIElement;

  LMB, RMB, MMB, MB1, MB2: boolean;
end;

{ tGUI }



tGUI = class
private
  Event: tSDL_Event;
public
  Screens: array of tUIScreen;
  ActiveScreen: integer;
  Options: tOptions;
  Mouse: rUIMouse;
  Transparent: boolean;
  Back: boolean;

  constructor Create;
  destructor Destroy; override;
  function LoadContents(FileName: string): integer;

  procedure ProcessInput;
  procedure Render;
end;


implementation

uses
  app;

{ tGUI }

constructor tGUI.Create;
begin

end;

destructor tGUI.Destroy;
var
  i: integer;
begin
  for i:= 0 to high(Screens) do
    Screens[i].Destroy;

  setlength(Screens, 0);

  inherited Destroy;
end;

function tGUI.LoadContents(FileName: string): integer;
begin
  Result:= 0;           { TODO : implement menu load }
  setlength(Screens, 1);
  Screens[0]:= tUIScreen.Create;
end;

procedure tGUI.ProcessInput;
var
  Element: tUIElement;
begin
  with Mouse, Options.Graphics do
  begin
    Back:= false;
    while SDL_PollEvent(@Event) = 1 do
      with Event do
      begin
        case type_ of
          SDL_MOUSEBUTTONDOWN: LMB:= true;  // Mouse button pressed
          SDL_MOUSEBUTTONUP:   LMB:= false;

          SDL_MouseMotion:
          begin
            c.x:= motion.x;
            c.y:= motion.y;
          end;
          SDL_KeyDown:
          begin
            case key.keysym.scancode of
              SDL_SCANCODE_P: Toggle(Wireframe);
              SDL_SCANCODE_N: DrawFrame:= true;
              SDL_SCANCODE_1: GameApp.State:= sGameLoop;
              SDL_SCANCODE_2: GameApp.State:= sShutDown;

              SDL_SCANCODE_ESCAPE: Back:= true;
            end;

            {if Paused then
              State:= sPaused; }
          end;
          SDL_KeyUp:
          begin

          end;

          SDL_QuitEv: GameApp.State:= sShutDown;
        end;
      end;

    if Back then
      if ActiveScreen = 0 then
      begin
        GameApp.Player.Action.Paused:= false;

      end
      else
      begin
        ActiveScreen:= 0;
      end;

    if LMB and (PressedOver = nil) then
    begin
      Element:= Screens[ActiveScreen].GetControlAtPos(c);
      if Element is tButton then
        PressedOver:= Element;
    end;

    if not LMB and (PressedOver <> nil) then
    begin
      Element:= Screens[ActiveScreen].GetControlAtPos(c);
      if PressedOver = Element then
        with tButton(Element) do
          if Assigned(OnPress) then
            OnPress(Element);

      PressedOver:= nil;
    end;
  end;
end;

procedure tGUI.Render;
begin
  Screens[ActiveScreen].Draw;
end;

{ tUIElement }

procedure tUIElement.Draw;
begin

end;

{ tButton }

procedure tButton.SetOnPress(AValue: tUIEvent);
begin
  if FOnPress=AValue then Exit;
  FOnPress:=AValue;
end;

{ tUIScreen }

constructor tUIScreen.Create;
begin

end;

destructor tUIScreen.Destroy;
var
  i: integer;
begin
  for i:= 0 to high(Panels) do
    Panels[i].Destroy;
  setlength(Panels, 0);
  inherited Destroy;
end;

function tUIScreen.LoadContents(FileName: string): integer;
begin
  Result:= 0;

end;

function tUIScreen.GetControlAtPos(p: rInt2): tUIElement;
var
  i: integer;
  Found: boolean = false;
begin
  for i:= 0 to high(Panels) do
    with Panels[i] do
      if (p.x >= Left) and (p.y >= Top) and
         (p.x  <= Left + Width) and (p.y <= Top + Height) then
        begin
          Found:= true;
          break
        end;
  if Found then
    Result:= Panels[i].GetControlAtPos(p)
  else
    Result:= nil;
end;

procedure tUIScreen.Draw;
var
  i: integer;
begin
  for i:= 0 to high(Panels) do
    Panels[i].Draw;
end;

{ tPanel }

destructor tPanel.Destroy;
var
  i: integer;
begin
  for i:= 0 to high(Elements) do
    Elements[i].Destroy;
  setlength(Elements, 0);
  inherited Destroy;
end;

function tPanel.GetControlAtPos(p: rInt2): tUIElement;
var
  i: integer;
  Found: boolean;
begin
  for i:= 0 to high(Elements) do
    with Elements[i] do
      if (p.x >= Left) and (p.y >= Top) and
         (p.x  <= Left + Width) and (p.y <= Top + Height) then
        begin
          Found:= true;
          break
        end;

  if Found then
  begin
    if Elements[i] is tPanel then
      Result:= tPanel(Elements[i]).GetControlAtPos(p)
    else
      Result:= Elements[i];
  end
  else
    Result:= nil;
end;

procedure tPanel.Draw;
var
  i: integer;
begin
  for i:= 0 to high(Elements) do
    Elements[i].Draw;
  inherited Draw;
end;

end.

