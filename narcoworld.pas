unit World;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Voxel, Economy, GL, Entities;

type
  spatial = longword;


  { tWorld }

  tWorld = class
    RootVoxel: tVoxel;
    VoxelCount: longword;
    Hubs: tEconomicHub;
    WorldSeed: longword;
    Wireframe: boolean;
    j: longword;
    CameraPosition, CameraDirection: rVec3;

    constructor Load(FileName: string);
    constructor CreateNew(Seed: longword);
    function Generate(Voxel: tVoxel): longint;
    procedure ListVoxel(Voxel: tVoxel; cx, cy, cz: single);
    procedure PassVoxels;
    procedure RenderVoxel(Voxel: tVoxel);
    procedure Render;
    procedure Save(FileName: string);
    destructor Destroy; override;
  end;

implementation

uses
  math, Utility;

{ tWorld }

constructor tWorld.Load(FileName: string);
begin

end;

constructor tWorld.CreateNew(Seed: longword);
begin
  j:= 0;
  WorldSeed:= Seed;
  VoxelFidelity:= 8;
  RootVoxel:= tVoxel.Create(nil);
  RootVoxel.Order:= 0;
  VoxelCount:= Generate(RootVoxel);
  WriteLog('Voxels Generated: ' + strf(VoxelCount));
end;

function tWorld.Generate(Voxel: tVoxel): longint;
var
  //ChildHeight: spatial;
  i: eVoxelPos;
begin
  //writeln('gen');
  with Voxel do
  begin
    //WriteLog('Order ' + strf(Order));
    if Order = VoxelFidelity then
    begin
      Result:= 1;
      exit;
    end;

    Result:= 0;
    for i:= BNW to BSW do           //change to iterative
    begin
      //WriteLog('i ' + strf(longint(i)));
      //ChildHeight:= power(2, VoxelFidelity - Voxel.Order);
      if srand(2, WorldSeed + j) = 0 then
        begin
          Child[longint(i)]:= tVoxel.Create(Voxel);
          Result+= Generate(Child[longint(i)]);
        end
      else
        begin
          Child[longint(i) + 4]:= tVoxel.Create(Voxel);
          Result+= Generate(Child[longint(i) + 4]);
        end;
        inc(j);
    end;
  end;
  Result+= j;
end;

procedure tWorld.ListVoxel(Voxel: tVoxel; cx, cy, cz: single);
var
  i: eVoxelPos;
  d: single;
  x, y, z: single;
begin
  with Voxel do
  begin
    d:= MinVoxelDim * power(2, VoxelFidelity - Order) / 2;
    for i:= BNW to TSW do
    begin
      x:= cx;
      y:= cy;
      z:= cz;
      if Child[integer(i)] <> nil then
      begin
        with Child[integer(i)] do
        begin
          case i of
            BNW:
              begin
                x+= 0;
                y+= 0;
                z+= 0;
                j:= integer(i);
              end;
            BNE:
              begin
                x+= d;
                j:= integer(i);
              end;
            BSE:
              begin
                x+= d;
                z-= d;
                j:= integer(i);
              end;
            BSW:
              begin
                z-= d;
                j:= integer(i);
              end;
            TNW:
              begin
                y+= d;
                j:= integer(i);
              end;
            TNE:
              begin
                x+= d;
                y+= d;
                j:= integer(i);
              end;
            TSE:
              begin
                x+= d;
                y+= d;
                z-= d;
                j:= integer(i);
              end;
            TSW:
              begin
                y+= d;
                z-= d;
                j:= integer(i);
              end;
          end;
          inc(j);

          ListID:= glGenLists(1);
          glNewList(ListID, GL_COMPILE);

          glBegin(GL_QUADS{_STRIP});
            glShadeModel(gl_Flat);
            glColor3f(Order * 1 / VoxelFidelity, random, j * 1 / VoxelCount);

            glVertex3f(x - d, y - d, z + d);    //n
            glVertex3f(x - d, y,     z + d);
            glVertex3f(x,     y,     z + d);
            glVertex3f(x,     y - d, z + d);

            glVertex3f(x,     y - d, z + d);    //e
            glVertex3f(x,     y,     z + d);
            glVertex3f(x,     y,     z    );
            glVertex3f(x,     y - d, z    );

            glVertex3f(x,     y - d, z    );    //s
            glVertex3f(x,     y,     z    );
            glVertex3f(x - d, y,     z    );
            glVertex3f(x - d, y - d, z    );

            glVertex3f(x - d, y - d, z    );    //w
            glVertex3f(x - d, y,     z    );
            glVertex3f(x - d, y,     z + d);
            glVertex3f(x - d, y - d, z + d);

            glVertex3f(x - d, y - d, z + d);    //b
            glVertex3f(x,     y - d, z + d);
            glVertex3f(x    , y - d, z    );
            glVertex3f(x - d, y - d, z    );

            glVertex3f(x - d, y,     z + d);    //t
            glVertex3f(x - d, y,     z    );
            glVertex3f(x    , y,     z    );
            glVertex3f(x    , y,     z + d);
          glEnd;
          glEndList;
        end;

        ListVoxel(Child[integer(i)], x - d / 2, y - d / 2, z + d / 2);
      end;
    end;
  end;
end;

procedure tWorld.PassVoxels;
var
  d: single;
  x, y, z: single;
begin
  d:= MinVoxelDim * power(2, VoxelFidelity);
  x:= d/2;
  y:= d/2;
  z:= - d/2;
  RootVoxel.ListID:= glGenLists(1);
          glNewList(RootVoxel.ListID, GL_COMPILE);

          glBegin(GL_QUADS{_STRIP});
            glShadeModel(gl_Smooth);
            glColor3f(1, 1, 1);

            glVertex3f(x - d, y - d, z + d);    //n
            glVertex3f(x - d, y,     z + d);
            glVertex3f(x,     y,     z + d);
            glVertex3f(x,     y - d, z + d);

            glVertex3f(x,     y - d, z + d);    //e
            glVertex3f(x,     y,     z + d);
            glVertex3f(x,     y,     z    );
            glVertex3f(x,     y - d, z    );

            glVertex3f(x,     y - d, z    );    //s
            glVertex3f(x,     y,     z    );
            glVertex3f(x - d, y,     z    );
            glVertex3f(x - d, y - d, z    );

            glVertex3f(x - d, y - d, z    );    //w
            glVertex3f(x - d, y,     z    );
            glVertex3f(x - d, y,     z + d);
            glVertex3f(x - d, y - d, z + d);

            glVertex3f(x - d, y - d, z + d);    //b
            glVertex3f(x,     y - d, z + d);
            glVertex3f(x    , y - d, z    );
            glVertex3f(x - d, y - d, z    );

            glVertex3f(x - d, y,     z + d);    //t
            glVertex3f(x - d, y,     z    );
            glVertex3f(x    , y,     z    );
            glVertex3f(x    , y,     z + d);
          glEnd;
          glEndList;
  ListVoxel(RootVoxel, 0, 0, 0);
end;

procedure tWorld.RenderVoxel(Voxel: tVoxel);
var
   i: eVoxelPos;
begin
  with Voxel do
  begin
    if Wireframe then
    begin
      if order  <> VoxelFidelity then
        glPolygonMode( GL_FRONT_AND_BACK, GL_LINE )
      else
        glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
      glCallList(ListID);
    end
    else
      if order = VoxelFidelity then glCallList(ListID);
    for i:= BNW to TSW do
      if Child[integer(i)] <> nil then RenderVoxel(Child[integer(i)])
  end;
end;

procedure tWorld.Render;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;


  with CameraDirection do
  begin
    glRotatef(x,1,0,0);
    glRotatef(y,0,1,0);
    glRotatef(z,0,0,1);
  end;

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;

  with CameraPosition do
    glTranslatef(x, y, z);
  RenderVoxel(RootVoxel);
  {with Voxel do
  begin
    for i:= BNW to TSW do
      if Child[integer(i)] <> nil then
        with Child[integer(i)], CameraPosition do
        begin
          glLoadIdentity;
          glTranslatef(x, y, z);
          glCallList(ListID);
          WriteLog('LID ' + strf(ListID));
         // glLoadIdentity;
        end;  }


  {
  glBegin( GL_QUADS );
            glVertex2f( -0.5, -0.5 );
            glVertex2f( 0.5, -0.5 );
            glVertex2f( 0.5, 0.5 );
            glVertex2f( -0.5, 0.5 );
        glEnd();}
  glFlush;
end;

procedure tWorld.Save(FileName: string);
begin

end;

destructor tWorld.Destroy;
begin
  if RootVoxel <> nil then
    RootVoxel.DestroyRoot;
  Hubs.Free;
end;

end.

