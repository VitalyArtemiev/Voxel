unit Window;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2, Utility, gl, GLext, glu;

type
  { tGameWindow }

  tGameWindow = class
    {property} WindowHandle: pSDL_Window;
    Surface: pSDL_Surface;
    GLContext: tSDL_GLContext;

    XRes: integer;
    YRes: integer;
    FOV: integer;
    VisibleRange: longword;

    constructor Create;
    function Open(Title: ansistring; FullScreen: boolean = true;
      x: integer = 0; y: integer = 0; width: integer = 0; height: integer = 0): integer;
    function InitGL: integer;
    procedure Update;
    destructor Destroy; override;
  end;

implementation

{ tGameWindow }

constructor tGameWindow.Create;
begin

end;

function tGameWindow.Open(Title: ansistring; FullScreen: boolean = true; x: integer = 0;
  y: integer = 0; width: integer = 0; height: integer = 0): integer;
var
  flags: longword;
  pc: pchar;
begin
  XRes:= width;
  YRes:= height;
  FOV:= 100;

  pc:= pchar(Title);
  flags:= SDL_WINDOW_OPENGL or SDL_WINDOW_SHOWN;
  if Fullscreen then flags:= flags or SDL_WINDOW_FULLSCREEN;

  WindowHandle:= SDL_CreateWindow(pc, x, y, XRes, YRes, flags);

  if WindowHandle = nil then
  begin
    Result:= -1;   //error mngmnt to property?
    WriteLog(emWnd);
    WriteLog(SDL_GetError);
  end
  else
  begin
    Result:= 0;
    Surface:= SDL_GetWindowSurface(WindowHandle);
    if Surface = nil then
    begin
      WriteLog(emSrf);
      WriteLog(SDL_GetError);
      SDL_DestroyWindow(WindowHandle);
      exit(-1);
    end
    else
    GLContext:= SDL_GL_CreateContext(WindowHandle);
    if GLContext = nil then
    begin
      WriteLog(emCtx);
      WriteLog(SDL_GetError);
      SDL_DestroyWindow(WindowHandle);
      exit(-1);
    end;
    if InitGl <> 0 then
    begin
      WriteLog(emIgl);
      SDL_DestroyWindow(WindowHandle);
      exit(-1);
    end;

    SDL_UpdateWindowSurface(WindowHandle);
  end;
  //sdl_setwindowtitle
end;

function tGameWindow.InitGL: integer;
begin
  VisibleRange:= 1000;
  Load_gl_version_2_1;
  glClearColor(0.0, 0.0, 0.0, 1);
  glViewport( 0, 0, XRes, YRes);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(FOV, XRes/YRes, 0.01, VisibleRange);
  //glFrustum(left, right, -1, 1, 0.1, VisibleRange: GLdouble);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  {glTranslatef(0,0,0);
  glRotatef(0,1,0,0);
  glRotatef(0,0,1,0);
  glRotatef(0,0,0,1);  }
  glPolygonMode(GL_FRONT, GL_FILL);
  glClearDepth(VisibleRange);
  //glEnable(GL_BLEND);
  //glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );

  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);
 { if Culling then          glFrontFace(GL_CCW/cw)  перед по/против час. стрелки
  begin}
    glFrontFace(GL_CCW);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
  {end;}
  Result:= glGetError();
end;

procedure tGameWindow.Update;
begin
  SDL_GL_SwapWindow(WindowHandle);
  //SDL_UpdateWindowSurface(WindowHandle);
end;

destructor tGameWindow.Destroy;
begin
  SDL_DestroyWindow(WindowHandle);
end;

end.

