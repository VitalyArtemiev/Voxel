unit Voxel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Schedule, BaseTypes;

const
  MaxVoxelFidelity = 10;
  DefaultBlockDepth = 3;

type
  eVoxelPos = (BNW, BSW, TNW, TSW, BNE, BSE, TNE, TSE);
  eVoxelDir = (dN = -%001, dS = %001, dB = -%010, dT = %010, dW = -%100, dE = %100);

  { tVoxel }  //This voxel fucking sucks, what was I thinking?

  tVoxel = class                //37b
    Order: byte;        //1b  //remove this
    Parent: tVoxel;     //4b/8b   //prolly don't need parent either, use stack
    Children: array [BNW..TSE] of tVoxel;    //neighbour[0..5]?   //32b / 64b
  private
    //NeedsUpdate: boolean;
    //fContent: byte;           //1b
    function GetContent: byte;
  public
    property Content: byte read GetContent;

    constructor Create(ParentVoxel: tVoxel);
    destructor Destroy; override;
  end;

  tVoxelAA = specialize tAutoArray<tVoxel>;
  tVoxelArray8 = array [BNW..TSE] of tVoxel;

  tVoxelArray = array of tVoxel;

  { tVoxelContainer }

  rVoxelDescriptor = packed record
    Children, Content: byte;
  end;

  eLoadOption = (lWhole, lManhattan, lLinear);

  rDescriptorArray = array of rVoxelDescriptor;

  tVoxelContainer = class
    //FileName: string;
    FileStream: tFileStream;
    BlockCount, FirstBlock: longword;
    BlockSizes: array of longword;   //in voxels

    RootVoxel: tVoxel;

    constructor Create;

    function Load(FileName: string; Option: eLoadOption): integer;

    procedure LoadWhole;

    procedure LoadOptimized(c: rVec3);

    function Save(FileName: string): integer;

    function LoadBlock(Number: longword;
                       Depth: longword = MaxVoxelFidelity): tVoxel; //returns most high-level voxel
    procedure LoadBlock(var ParentVoxel: tVoxel; Position: eVoxelPos;
                        Depth: longword = MaxVoxelFidelity);
    procedure SaveBlock(Voxel: tVoxel);

    destructor Destroy; override;
  end;

  rLocation = record
    x, y: single;
    Voxel: tVoxel;
  end;

  eMaterial = (emEarth, emGrass, emMud, emSand, emStone, emStillWater,
               emRunningWater, emOreIron, emOreSilver, emOreCopper, emOreTin,
               emBrick, emCobblestone);

const
  MinValidPointer = pointer(65536);
//Leaf voxel states
  NoVoxel = nil;
  StoredVoxel = pointer(1);
  NeedsStorage = pointer(2); //wtf is that????? how would you get to it???
  LeafVoxel = pointer(3);

//Materials
  MaterialOffset = %100000000;
  MaxMaterialValue = integer(high(eMaterial));

  mEarth        = pointer(integer(emEarth)        * MaterialOffset);
  mGrass        = pointer(integer(emGrass)        * MaterialOffset);
  mMud          = pointer(integer(emMud)          * MaterialOffset);
  mSand         = pointer(integer(emSand)         * MaterialOffset);
  mStone        = pointer(integer(emStone)        * MaterialOffset);
  mStillWater   = pointer(integer(emStillWater)   * MaterialOffset);
  mRunningWater = pointer(integer(emRunningWater) * MaterialOffset);
  mOreIron      = pointer(integer(emOreIron)      * MaterialOffset);
  mOreSilver    = pointer(integer(emOreSilver)    * MaterialOffset);
  mOreCopper    = pointer(integer(emOreCopper)    * MaterialOffset);
  mOreTin       = pointer(integer(emOreTin)       * MaterialOffset);
  mBrick        = pointer(integer(emBrick)        * MaterialOffset);
  mCobblestone  = pointer(integer(emCobblestone)  * MaterialOffset);
//\/invalid ptrs        //content //state
//0..65535  2 bytes     0000 0000 0000 0000  <<lowest bit

var
  VoxelFidelity: cardinal;
  StructureOrder: longword;
  MinVoxelDim: single = 0.25;//0.03125;

function GetVoxelCenter(ParentCenter: rVec3; ParentOrder: integer; Pos: eVoxelPos): rVec3;
function ValidPointerCount(a: tVoxelArray8): longword; inline;
function VoxelChildCount(v: rVoxelDescriptor): integer; inline;
function GetVoxelDescriptors(a: tVoxelArray): rDescriptorArray;

//pseudocode
//function GetAdjacentVoxel(c, d: rVec3): tVoxel;

//\pseudocode

implementation

uses
  math, Utility;

function GetVoxelCenter(ParentCenter: rVec3; ParentOrder: integer; Pos: eVoxelPos): rVec3;
  var
    d: single;
    v: rVec3;
  begin
    d:= MinVoxelDim * power(2, VoxelFidelity - ParentOrder) / 2;
    case Pos of
      BNW: begin
             v.x:= -d;
             v.y:= -d;
             v.z:= -d;
           end;
      BSW: begin
             v.x:= -d;
             v.y:= -d;
             v.z:= d;
           end;
      TNW: begin
             v.x:= -d;
             v.y:= d;
             v.z:= -d;
           end;
      TSW: begin
             v.x:= -d;
             v.y:= d;
             v.z:= d;
           end;
      BNE: begin
             v.x:= d;
             v.y:= -d;
             v.z:= -d;
           end;
      BSE: begin
             v.x:= d;
             v.y:= -d;
             v.z:= d;
           end;
      TNE: begin
             v.x:= d;
             v.y:= d;
             v.z:= -d;
           end;
      TSE: begin
             v.x:= d;
             v.y:= d;
             v.z:= d;
           end;
    end;
    Result:= ParentCenter + v;
  end;

function ValidPointerCount(a: tVoxelArray8): longword; inline;
var
  i: eVoxelPos;
begin
  Result:= 0;
  for i:= low(eVoxelPos) to high(eVoxelPos) do
    if pointer(a[i]) > LeafVoxel then //leaf voxels don't get their own descriptors... maybe 1b for material?
      inc(Result);
end;

function VoxelChildCount(v: rVoxelDescriptor): integer; inline;
begin
  Result:= popcnt(v.Children);
end;

function GetVoxelDescriptors(a: tVoxelArray): rDescriptorArray; //is result a new array or no?
var
  i: integer;
  j: eVoxelPos;
begin
  setlength(Result, length(a));
  for i:= 0 to high(a) do
    with Result[i] do
    begin
      Children:= 0;
      Content:= 0;
      for j:= low(eVoxelPos) to high(eVoxelPos) do
        if a[i].Children[j] <> nil then
        begin
          case j of
            BNW: Children+= %00000001;
            BSW: Children+= %00000010;
            TNW: Children+= %00000100;
            TSW: Children+= %00001000;
            BNE: Children+= %00010000;
            BSE: Children+= %00100000;
            TNE: Children+= %01000000;
            TSE: Children+= %10000000;
          end;
          if pointer(a[i].Children[j]) < MinValidPointer then
            Content:= longword(pointer(a[i].Children[j])) shr 8;   //tested
        end;
    end;
end;

{function GetAdjacentVoxel(c, d: rVec3): tVoxel;
var
  cv: tVoxel;
  pos: eVoxelPos;
  dir: eVoxelDir;
begin
  cv:= GetVoxel(c, VoxelCenter); //without extending the tree
  while not cv.IsLeaf do
  begin
    cv:= cv.Parent;
    case dir of
      dN: ;
      dS: ;
      dB: ;
      dT: ;
      dW: ;
      dE: ;
    end;
  end;
end;  }

{ tVoxelContainer }

constructor tVoxelContainer.Create;
begin
  //initialization
end;

procedure tVoxelContainer.LoadWhole;
var
  i: eVoxelPos;
  j: integer;
begin

  FirstBlock:= sizeof(BlockCount) + BlockCount * sizeof(BlockSizes[0]);
  FileStream.ReadBuffer(BlockSizes, BlockCount);

  RootVoxel:= LoadBlock(0);

  if assigned(RootVoxel) then
    RootVoxel.Destroy;

  for i:= BNW to TSE do
  begin

  end;
end;

procedure tVoxelContainer.LoadOptimized(c: rVec3);
var
  i: eVoxelPos;
  j: longword = 0;
  vq: tVoxelAA;
  {procedure LOD(   }

begin
  if assigned(RootVoxel) then
    RootVoxel.Destroy;

  vq:= tVoxelAA.Create;

  RootVoxel:= LoadBlock(0);
  for i:= BNW to TSE do
    vq.Add(RootVoxel.Children[i]);

  for i:= BNW to TSE do
  begin
    //check distance

   // LoadBlock(vq.Values[j], i);//level from dist check);
    //vq.Add();
    inc(j);
  end;
end;

function tVoxelContainer.Load(FileName: string; Option: eLoadOption): integer;
begin
  Result:= 0;
  try
    Filestream:= TFileStream.Create(FileName, fmOpenReadWrite);
    VoxelFidelity:= FileStream.ReadDWord;
    setlength(BlockSizes, VoxelFidelity);
    FileStream.ReadBuffer(BlockSizes, length(BlockSizes) * sizeof(longword));
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
      Result:= -1; //does this exit?
    end;
  end;

  case Option of
    lWhole: ;
    lManhattan: ;
    lLinear: ;
  end;
end;

function tVoxelContainer.Save(FileName: string): integer;
var
  vq1, vq2: tVoxelAA;
  Descriptors: array of rVoxelDescriptor;
  i, j: integer;
  sum: longword;
begin
  Result:= 0;
  if FileStream.FileName <> FileName then
  begin
    WriteLog(msgFCr + ' ''' + FileName + '''');
    FileStream.Destroy;
    try
      FileStream:= TFileStream.Create(FileName, fmOpenReadWrite);
    except
      on E: EFOpenError do
      begin
        WriteLog(E.Message);
        Result:= -1;
      end;
    end;
  end;

  setlength(BlockSizes, VoxelFidelity);

  BlockSizes[0]:= 1;

  FileStream.Seek(VoxelFidelity + 1, soBeginning);

  vq1:= tVoxelAA.Create(1);
  vq1.Add(RootVoxel);

  for i:= 1 to VoxelFidelity do
  begin
    vq2:= tVoxelAA.Create(vq1.Count * 4); //estimate?
    sum:= 0;
    for j:= 0 to vq1.Count - 1 do
    begin
      vq2.Add(vq1[j].Children);
      Sum+= ValidPointerCount(vq1[j].Children);

      Descriptors:= GetVoxelDescriptors(vq1.fValues);
      FileStream.WriteBuffer(Descriptors, length(Descriptors) * sizeof(rVoxelDescriptor)); //still need a way to assign material to non-leaf voxels
    end;

    BlockSizes[i]:= Sum;

    vq1.Destroy;
    vq1:= vq2;
  end;

  FileStream.Seek(0, soBeginning);
  FileStream.WriteDWord(VoxelFidelity);
  FileStream.WriteBuffer(BlockSizes, length(BlockSizes) * sizeof(longword));
end;

function tVoxelContainer.LoadBlock(Number: longword;
                                   Depth: longword = MaxVoxelFidelity): tVoxel;
var
  Descriptors: array of rVoxelDescriptor;
  i, j, pos: longword;
  qc, qm: longint;     //queue counter
  //j: eVoxelPos;
  //cv: tVoxel;        //current voxel
  vq: array of tVoxel; //voxel queue
begin
  setlength(Descriptors, BlockSizes[Number]);
  setlength(vq, BlockSizes[Number]);

  pos:= FirstBlock;
  for i:= 0 to Number - 1 do //??
    pos+= BlockSizes[i]; //maybe keep this summed and find actual size by detracting??  //problematic to insert blocks

  FileStream.Seek(pos, soBeginning); //this has 2 variants 32 & 64
  FileStream.ReadBuffer(Descriptors, BlockSizes[Number] * sizeof(rVoxelDescriptor));
  Result:= tVoxel.Create(nil);
  i:= 0;
  qc:= -1; //???
  qm:= 0;
  vq[qm]:= Result;
  dec(Depth); //if depth = 3, 3rd level will have values 0..65535 as children
  with vq[qc] do
  begin
    for i:= 0 to high(Descriptors) do  //for each descriptor in block
    begin
      inc(qc);
      //cv:= vq[qc];                   //get next voxel from q
      for j:= 0 to integer(TSE) do     //decode children byte
      begin
        if GetBit(Descriptors[i].Children, j) then
        begin
          if Depth <> 0 then
          begin
            Children[eVoxelPos(j)]:= tVoxel.Create(vq[qc]); //allocate mem for voxels
            inc(qm);
            vq[qm]:= Children[eVoxelPos(j)]; //add to q for processing
          end
          else
          begin
            Children[eVoxelPos(j)]:= tVoxel(Descriptors[i].Content + StoredVoxel); //load state and content instead of valid pointer
          end;
        end;
        if j = integer(TSE) then
          dec(Depth);
      end;
    end;
  end;
end;

procedure tVoxelContainer.LoadBlock(var ParentVoxel: tVoxel; Position: eVoxelPos;
                                    Depth: longword = MaxVoxelFidelity);
var
  Number: longword;
begin
  Number:= 0;

  ParentVoxel.Children[Position]:= LoadBlock(Number, Depth);
  ParentVoxel.Children[Position].Parent:= ParentVoxel;
end;

procedure tVoxelContainer.SaveBlock(Voxel: tVoxel);
begin
  //called by save world, saves block size at first provided pos, then block at 2nd provided pos
end;

destructor tVoxelContainer.Destroy;
begin
  setlength(BlockSizes, 0);
  freeandnil(FileStream);
  freeandnil(RootVoxel);
end;

{ tVoxel }

constructor tVoxel.Create(ParentVoxel: tVoxel);
begin
  Parent:= ParentVoxel;
  if ParentVoxel <> nil then
  begin
    Order:= Parent.Order + 1;
    //Parent.Content:= Parent.Content + 1;
  end;
end;

destructor tVoxel.Destroy;
var
  i: eVoxelPos;
begin
  for i:= low(Children) to high(Children) do
    if pointer(Children[i]) > LeafVoxel then
      Children[i].Destroy;
end;

function tVoxel.GetContent: byte;
var
  i: eVoxelPos;
begin
  Result:= 0;
  for i:= BNW to TSE do
    if pointer(Children[i]) >= LeafVoxel then
      inc(Result);
end;

end.

