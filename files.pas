unit Files;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2, Utility;

function LoadImage(FileName: string): pSDL_Surface;

implementation

function LoadImage(FileName: string): pSDL_Surface;
begin
  Result:= SDL_LoadBMP(PChar(FileName));
//  Result:= SDL_ConvertSurface(Result, nil, 0);
  if Result = nil then WriteLog(emImg);
end;

end.

