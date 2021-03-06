unit World;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BaseTypes, Voxel, Economy, GL, GLext, Entities, Character;

type
  spatial = longword;

  { tWorld }

  tWorld = class
    Voxels: tVoxelContainer;
    //RootVoxel: tVoxel; //absolute Voxels.RootVoxel;

    Hubs: array of tEconomicHub;
    Vicinity: tCharContainer;

    Vertices: array of rVec3;
    Indices: array of GLUInt;
    //IndexCount: array of GLsizei;   //for multidraw
   // IndexOffset: array of pointer;
    Counter: longword;
    VertexBuffer, IndexBuffer: GLUInt;
    VoxelCount: longword;
    Extent: single;

    WorldSeed: longword;
    Wireframe: boolean;
    Camera: tCamera;
    UI3DListID, WireFrameListID: longword;

  private
    procedure GenerateHubs;

  public
    constructor Load(FileName: string);
    constructor LoadHM(FileName: string);
    constructor CreateNew(Seed: longword);

    function GetVoxel(x, y, z: single; c1, c2: longword; MaxOrder: longword = 0): tVoxel;
    function Generate(Voxel: tVoxel): longint;
    procedure ListVoxel(Voxel: tVoxel; cx, cy, cz: single);
    procedure PassVoxels;

    procedure Render;

    procedure Save(FileName: string);
    destructor Destroy; override;
  end;

implementation

uses
  math, Utility;

const
  HubVoxelOrder = 3;
  HubCount = 2;

{ tWorld }

procedure tWorld.GenerateHubs;
var
   i, j: integer;
   cv: tVoxel;
begin
  for i:= 1 to HubCount do
  begin
    cv:= Voxels.RootVoxel;

    while cv.Order <> HubVoxelOrder do
    begin
      cv:= cv.Children[eVoxelPos(srand(integer(high(eVoxelPos)), WorldSeed + Counter))];
      if cv = nil then
        cv:= Voxels.RootVoxel;
      inc(Counter);
    end;
    setlength(Hubs, length(Hubs) + 1);
    Hubs[high(Hubs)]:= tEconomicHub.Create(cv);
  end;
end;

constructor tWorld.Load(FileName: string);
var
   Result: integer;
begin
  Voxels:= tVoxelContainer.Create;
  Result:= Voxels.Load(FileName, lWhole);
  if Result <> 0 then
    WriteLog(emNoF);
  {with Voxels do
  begin
    RootVoxel:= LoadBlock(0, DefaultBlockDepth);
  end; }
end;

constructor tWorld.LoadHM(FileName: string);
var
  fs: tFileStream;
  i, j, k, l: longword;
  hm: array of array of single;
  d: single;
begin
  Voxels:= tVoxelContainer.Create;

  VoxelFidelity:= 10;
  Extent:= MinVoxelDim * power(2, VoxelFidelity);
  l:= round(power(2, VoxelFidelity));
  VoxelCount:= l * l;
  setlength(hm, l, l);
  setlength(Vertices, l * l);
  setlength(Indices, (l - 1) * (l - 1) * 6);
  {setlength(IndexCount, l);
  setlength(IndexOffset, l);
  for i:= 0 to high(IndexCount) do
  begin
    IndexCount[i]:= l;
    IndexOffset[i]:= nil;
  end;  }

  Voxels.RootVoxel:= tVoxel.Create(nil);
  //writelog(strf(RootVoxel.InstanceSize));
  d:= power(2, VoxelFidelity - Voxels.RootVoxel.Order) / 2;

  FileName+= '.hm';
  fs:= TFileStream.Create(FileName, fmOpenRead);
  for i:= 0 to l - 1 do
    for j:= 0 to l - 1 do
    begin
      fs.Read(hm[i,j], sizeof(hm[i,j]));
      hm[i,j]/= 128;
      //GetVoxel((i - d) * MinVoxelDim, hm[i,j], (j - d) * MinVoxelDim);  //do in 1 loop
    end;
  fs.free;

  //  glPolygonMode(GL_FRONT, GL_FILL);

  k:= 0;

    for j:= 0 to l - 2 do
    begin
      for i:= 0 to l - 1 do
      begin
        GetVoxel((i - d) * MinVoxelDim, hm[i,j], (j - d) * MinVoxelDim, i + (j * l), k);
        inc(k);
        GetVoxel((i - d) * MinVoxelDim, hm[i,j + 1], (j + 1 - d) * MinVoxelDim, i + (j+1) * l, k);
        inc(k);
      end;
    end;

    WriteLog('Voxels loaded: ' + strf(VoxelCount));

    GenerateHubs;
    Camera:= tCamera.Create;
end;

constructor tWorld.CreateNew(Seed: longword);
var
  l: longword;
begin
  WorldSeed:= Seed;
  VoxelFidelity:= 6;
  l:= round(power(2, VoxelFidelity));

  setlength(Vertices, l * l * l);
  setlength(Indices, l * l * l);

  Extent:= MinVoxelDim * power(2, VoxelFidelity);
  Voxels:= tVoxelContainer.Create;
  Voxels.RootVoxel:= tVoxel.Create(nil);
  Voxels.RootVoxel.Order:= 0;

  VoxelCount:= 0;
  Counter:= 0;
  Generate(Voxels.RootVoxel);

  WriteLog('Voxels generated: ' + strf(VoxelCount));
  Camera:= tCamera.Create;
end;

function tWorld.GetVoxel(x, y, z: single; c1, c2: longword; MaxOrder: longword = 0): tVoxel;
var
  Next: eVoxelPos;
  d, cx, cy, cz: single;
  i: integer;
begin
  Result:= Voxels.RootVoxel;
  cx:= 0; //center of current voxel
  cy:= 0;
  cz:= 0;

  with Result do
    for i:= 0 to VoxelFidelity - 1 do
    begin
      d:= MinVoxelDim * power(2, VoxelFidelity - Order - 2) {/ 4};
      if z < cz then
      begin
        cz-= d;
        if x < cx then
        begin
          cx-= d;
          if y < cy then
          begin
            Next:= BNW;
            cy-= d;
          end
          else
          begin
            Next:= TNW;
            cy+= d;
          end;
        end
        else
        begin
          cx+= d;
          if y < cy then
          begin
            Next:= BNE;
            cy-= d;
          end
          else
          begin
            Next:= TNE;
            cy+= d;
          end;
        end;
      end
      else
      begin
        cz+= d;
        if x < cx then
        begin
          cx-= d;
          if y < cy then
          begin
            Next:= BSW;
            cy-= d;
          end
          else
          begin
            Next:= TSW;
            cy+= d;
          end;
        end
        else
        begin
          cx+= d;
          if y < cy then
          begin
            Next:= BSE;
            cy-= d;
          end
          else
          begin
            Next:= TSE;
            cy+= d;
          end;
        end;
      end;

      if Children[Next] = nil then
        Children[Next]:= tVoxel.Create(Result);

      Result:= Children[Next];
    end;

  Vertices[c1].x:= x;    //excess
  Vertices[c1].y:= y;
  Vertices[c1].z:= z;

  Indices[c2]:= c1;
  //writelog('i' + strf(Child[Next].Index));
end;


function tWorld.Generate(Voxel: tVoxel): longint;
var
  //ChildHeight: spatial;
  i: eVoxelPos;
begin
  inc(VoxelCount);//writeln('gen');
  with Voxel do
  begin
    //WriteLog('Order ' + strf(Order));
    if Order = VoxelFidelity then
    begin
     { for i:= low(eVoxelPos) to high(eVoxelPos) do
        writelog(strf(longword(pointer(Children[i]))));  }
      Result:= 0;
      exit;
    end;

    Result:= 0;
    for i:= low(eVoxelPos) to TSW do           //change to iterative
    begin
      if srand(3, WorldSeed + Counter) = 0 then
        begin
          Children[i]:= tVoxel.Create(Voxel);
          {Result+=} Generate(Children[i]);
        end
      else
        begin
          Children[eVoxelPos(integer(i) + 4)]:= tVoxel.Create(Voxel);
          {Result+=} Generate(Children[eVoxelPos(integer(i) + 4)]);
        end;
        inc(Counter);
    end;
  end;
  {Result+= Counter; }
end;

procedure tWorld.ListVoxel(Voxel: tVoxel; cx, cy, cz: single);   //center of voxel
var
  i: eVoxelPos;
  d: single;                        //убрать рекурсию - self сравнить с адресами родителя
  x, y, z: single;
begin
  with Voxel do
  begin
    d:= MinVoxelDim * power(2, VoxelFidelity - Order) / 2;
    for i:= BNW to TSE do
    begin
      x:= cx;
      y:= cy;
      z:= cz;
      if Children[i] <> nil then
      begin
        with Children[i] do
        begin
          case i of
            BNW:
              begin
                x+= 0;
                y+= 0;
                z+= 0;
               // Counter:= integer(i);
              end;
            BNE:
              begin
                x+= d;
               // Counter:= integer(i);
              end;
            BSE:
              begin
                x+= d;
                z+= d;
               // Counter:= integer(i);
              end;
            BSW:
              begin
                z+= d;
               // Counter:= integer(i);
              end;
            TNW:
              begin
                y+= d;
               // Counter:= integer(i);
              end;
            TNE:
              begin
                x+= d;
                y+= d;
               // Counter:= integer(i);
              end;
            TSE:
              begin
                x+= d;
                y+= d;
                z+= d;
               // Counter:= integer(i);
              end;
            TSW:
              begin
                y+= d;
                z+= d;
               // Counter:= integer(i);
              end;
          end;
          //inc(Counter);

          if Order = VoxelFidelity then
          begin
            Vertices[counter].x:= x;    //excess
            Vertices[counter].y:= y;
            Vertices[counter].z:= z;

            Indices[counter]:= counter;
            inc(counter);
          end;

          {//if ListID = 0 then ListID:= Counter;
          //glNewList(ListID, GL_COMPILE_and_execute);
          {if Order < VoxelFidelity then
          begin}
                {glPolygonMode(GL_FRONT, GL_LINE)
              else
                glPolygonMode(GL_FRONT, GL_FILL);  }

            //glBegin(GL_quads{_STRIP});

              glColor3f(Order * 1 / VoxelFidelity, random, Counter  / VoxelCount);

              glVertex3f(x - d, y - d, z - d);    //n
              glVertex3f(x - d, y,     z - d);
              glVertex3f(x,     y,     z - d);
              glVertex3f(x,     y - d, z - d);

              glVertex3f(x,     y - d, z - d);    //e
              glVertex3f(x,     y,     z - d);
              glVertex3f(x,     y,     z    );
              glVertex3f(x,     y - d, z    );

              {glVertex3f(x,     y - d, z    );    //s
              glVertex3f(x,     y,     z    );
              glVertex3f(x - d, y,     z    );
              glVertex3f(x - d, y - d, z    );           }

              {glVertex3f(x - d, y - d, z    );    //w
              glVertex3f(x - d, y,     z    );
              glVertex3f(x - d, y,     z - d);
              glVertex3f(x - d, y - d, z - d);   }

              glVertex3f(x - d, y - d, z - d);    //b
              glVertex3f(x,     y - d, z - d);
              glVertex3f(x    , y - d, z    );
              glVertex3f(x - d, y - d, z    );

             { glVertex3f(x - d, y,     z - d);    //t
              glVertex3f(x - d, y,     z    );
              glVertex3f(x    , y,     z    );
              glVertex3f(x    , y,     z - d);      }
            //glEnd;
          //glEndList;

          {end;}   }
        end;

        ListVoxel(Children[i], x - d / 2, y - d / 2, z - d / 2);
      end;
    end;
  end;
end;

procedure tWorld.PassVoxels;
begin
{UI3DListID:= glGenLists(1);
  glNewList(UI3DListID, GL_COMPILE);
    glBegin(GL_LINES);
      glColor3f(0,0,1);
      glVertex3f(0,0,0);
      glVertex3f(0,0,1);
      glVertex3f(0.005,0,0);
      glVertex3f(0.005,0,1);
      glVertex3f(-0.005,0,0);
      glVertex3f(-0.005,0,1);

      glColor3f(1,0,0);
      glVertex3f(0,0,0);
      glVertex3f(1,0,0);
      glVertex3f(0,0.005,0);
      glVertex3f(1,0.005,0);
      glVertex3f(0,-0.005,0);
      glVertex3f(1,-0.005,0);

      glColor3f(0,1,0);
      glVertex3f(0,0,0);
      glVertex3f(0,1,0);
      glVertex3f(0,0,0.005);
      glVertex3f(0,1,0.005);
      glVertex3f(0,0,-0.005);
      glVertex3f(0,1,-0.005);
    glEnd;
  glEndList;

  d:= MinVoxelDim * power(2, VoxelFidelity);
  x:= d/2;            //tse corner
  y:= d/2;
  z:= d/2;
  {RootVoxel.ListID:= glGenLists(1);
  glNewList(RootVoxel.ListID, GL_COMPILE); }
  WireFrameListID:= glGenLists(1);
  glNewList(WireFrameListID, GL_COMPILE);
    glPolygonMode(GL_FRONT, GL_fill);

    glBegin(GL_QUADS{_STRIP});
      glShadeModel(gl_Smooth);
      glColor3f(1, 1, 1);

      glVertex3f(x - d, y - d, z - d);    //n
      glVertex3f(x - d, y,     z - d);
      glVertex3f(x,     y,     z - d);
      glVertex3f(x,     y - d, z - d);

      glVertex3f(x,     y - d, z - d);    //e
      glVertex3f(x,     y,     z - d);
      glVertex3f(x,     y,     z    );
      glVertex3f(x,     y - d, z    );

      glVertex3f(x,     y - d, z    );    //s
      glVertex3f(x,     y,     z    );
      glVertex3f(x - d, y,     z    );
      glVertex3f(x - d, y - d, z    );

      glVertex3f(x - d, y - d, z    );    //w
      glVertex3f(x - d, y,     z    );
      glVertex3f(x - d, y,     z - d);
      glVertex3f(x - d, y - d, z - d);

      glVertex3f(x - d, y - d, z - d);    //b
      glVertex3f(x,     y - d, z - d);
      glVertex3f(x    , y - d, z    );
      glVertex3f(x - d, y - d, z    );

      glVertex3f(x - d, y,     z - d);    //t
      glVertex3f(x - d, y,     z    );
      glVertex3f(x    , y,     z    );
      glVertex3f(x    , y,     z - d);

      Counter:= 1;
      ListVoxel(Voxels.RootVoxel, 0, 0, 0);
    glEnd;
  glEndList;  }


  {glBegin(gl_quads);

  glEnd;  }

  //glEnableClientState(GL_VERTEX_ARRAY);
    Counter:= 0;
    ListVoxel(Voxels.RootVoxel, 0, 0, 0);

    glGenBuffers(1, @VertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, VertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, length(Vertices) * sizeof(rVec3), PGLVoid(Vertices), GL_STATIC_DRAW);

    glGenBuffers(1, @IndexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, IndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, length(Indices) * sizeof(GLuint), PGLVoid(Indices), GL_STATIC_DRAW);

    glEnableClientState(GL_VERTEX_ARRAY);
    //glDisableClientState(GL_VERTEX_ARRAY);
end;

procedure tWorld.Render;
var
   p: rVec3;    //move on cam vec
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  //glLoadIdentity;
  glPopMatrix;
  glPushMatrix;

             //to separate proc

  with Camera.o do
  begin
    glRotatef(x,1,0,0);
    glRotatef(y,0,1,0);
    glRotatef(z,0,0,1);
  end;

  with Camera.c do
    glTranslatef(x, y, z);

  //glEnableClientState(GL_VERTEX_ARRAY);

  //glBindBuffer(GL_ARRAY_BUFFER, VertexBuffer);
  glVertexPointer(3, GL_FLOAT, 0, nil);

  //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, IndexBuffer);
  glDrawElements(GL_TRIANGLE_STRIP, length(Indices), GL_UNSIGNED_INT, nil);
 // glMultiDrawElements(GL_TRIANGLE_STRIP, PGLSizei(IndexCount), GL_UNSIGNED_INT, PGLVoid(IndexOffset), length(Indexcount)*length(Indexcount)*sizeof(gluint));

  //glDisableClientState(GL_VERTEX_ARRAY);


  {glMatrixMode(GL_Projection);
  glLoadIdentity;    }


  //glCallList(UI3DListID);
  //if WireFrame then glCallList(WireFrameListID);

  //glFlush;
end;

procedure tWorld.Save(FileName: string);
begin


  {if FileExists(FileName) then
  begin
    Filestream:= TFileStream.Create(FileName, fmOpenReadWrite);
    BlockCount:= FileStream.ReadDWord;
    setlength(BlockSizes, BlockCount);
    FirstBlock:= sizeof(BlockCount) + BlockCount * sizeof(BlockSizes[0]);
    FileStream.ReadBuffer(BlockSizes, BlockCount);

    RootVoxel:= LoadBlock(0);
  end
  else
  begin
    Filestream:= TFileStream.Create(FileName, fmCreate);
    //Gen new
  end;}
end;

destructor tWorld.Destroy;
var
  i: integer;
begin
  WriteLog('Freeing world');
  Voxels.Destroy;
  for i:= 0 to high(Hubs) do
    Hubs[i].Destroy;
  Camera.Destroy;
end;

end.

