unit Noises;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, WGBase;

function SmoothStep(E1, E2, x: double): double; inline;
function DotProd(v1, v2: rVec2): double; inline;
procedure Normalize(var v: rVec2); inline;

implementation

uses
  Util;

function SmoothStep(E1, E2, x: double): double; inline;
begin
  x:= (x - e1) * (e2 - e1);
  Result:= x*x*(3 - 2*x);
  {if x> $ffffff then
  begin
    showmessage('IM BAD AT MATH');
    x:= $ffffff;
  end;}
end;

function DotProd(v1, v2: rVec2): double; inline;
begin
  Result:= v1.x*v2.x + v1.y*v2.y;
end;

procedure Normalize(var v: rVec2); inline;
var
  d: double;
begin
  d:= sqrt(sqr(v.x)+sqr(v.y));
  if d = 0 then
    exit;
  v.x/=d;
  v.y/=d;
end;

{
// Function to linearly interpolate between a0 and a1
 // Weight w should be in the range [0.0, 1.0]
 function lerp(float a0, float a1, float w) {
     return (1.0 - w)*a0 + w*a1;
 }    }



end.

