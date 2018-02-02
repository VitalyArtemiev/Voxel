unit customxml;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Utility, Variants,
  laz2_DOM, laz2_XMLRead, laz2_XMLWrite, laz2_XMLCfg, laz2_XMLUtils{, laz2_XMLStreaming};

type

  tNewFileProc = procedure of object;

  rStackNode = specialize rNode<TDOMNode>;
  pStackNode = ^rStackNode;

  eNodeLocation = (lAll, lChildNodes, lThisNode);
  { tXMLFile }

  tXMLFile = class
    //OnNewFile: tNewFileProc;
    Doc: TXMLDocument;
    RootNode: TDOMElement;
    Stack: pStackNode;
    {function GetIntValue(Criteria: string): longint;
    function GetRealValue(Criteria: string): longint;
    function GetStringValue(Criteria: string): longint;}
    //property OnCreateNew: tNewFileProc read fNew write fNew;
  private
    FCurrentNode: TDOMNode;
    Modified: boolean;
    FileName: string;

    procedure Push(n: TDomNode);
    function Pop: TDomNode;
    function GetCurrentNode: TDOMNode;

  public
    constructor CreateNew(fn: string; Overwrite: boolean = false; RootNodeName: string = '');
    constructor Open(fn: string);

    property CurrentNode: TDOMNode read GetCurrentNode;

    procedure AddNode(Name: string);
    function GetValue(Name: string): variant;
    procedure SetValue(Name: string; Value: variant);

    function FindNode(Name: string; Location: eNodeLocation = lThisNode): boolean;
    function Next: boolean;
    function Prev: boolean;
    function Back: boolean;
    procedure BackToRoot;

    function IterateNodesWithName(Name: string): boolean;

    function Save: integer;
    destructor Destroy; override;
  end;

implementation

{ tXMLFile }

function tXMLFile.GetValue(Name: string): variant;
var
  PassNode: TDOMNode;
  e, a: longint;
  d: double;
  s: string;
begin
  s:= TDOMElement(Stack^.Value).GetAttribute(Name);
  val(s, a, e);

  if e = 0 then
    Result:= a
  else
  begin
    val(s, d, e);
    if e = 0 then
      Result:= d
    else
      Result:= s;
  end;
end;

procedure tXMLFile.SetValue(Name: string; Value: variant);
begin
  try
    TDOMElement(Stack^.Value).SetAttribute(Name, VarToStr(Value));
    Modified:= true;
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
      //Result:= -1;
    end;
  end;
end;

procedure tXMLFile.AddNode(Name: string);
var
  DNode: TDOMNode;

begin
  DNode := Doc.CreateElement(Name);
  Stack^.Value.AppendChild(DNode);
  Push(DNode);
  Modified:= true;
end;

function tXMLFile.FindNode(Name: string; Location: eNodeLocation): boolean;
var
  p: pStackNode;
  DNode: TDOMNode;
begin
  case Location of
    lAll: DNode:= nil;
    lChildNodes:
    begin
      {
      s:= Copy2SymbDel(Name, '.');
    PassNode:= RootNode.FindNode(s);
    if PassNode = nil then
    begin
      PassNode:= Doc.CreateElement(s);
      s:= VarToStr(Value);
      TDOMElement(PassNode).SetAttribute(Name, s);  //wrong
      Node.AppendChild(PassNode);
    end
    else
    begin
     // PassNode.
    end;




    PassNode:= Doc.DocumentElement;

    while pos('.', Name) <> 0 do
    begin
      s:= Copy2SymbDel(Name, '.');
      // Retrieve the specified node
      Node:= PassNode;
      PassNode:= PassNode.FindNode(s);

      if PassNode = nil then
      begin
        PassNode:= Doc.CreateElement(s);
        Node.AppendChild(PassNode);
      end;
    end; }
      DNode:= nil;
    end;
    lThisNode: DNode:= Stack^.Value.FindNode(Name);
  end;

  //writeln(Doc.TextContent);
  if DNode <> nil then
  begin
    Push(DNode);
    writeln(Stack^.Value.TextContent);
    Result:= true;
  end
  else
    Result:= false;

end;

function tXMLFile.Next: boolean;
var
  NNode: TDOMNode;
begin
  NNode:= CurrentNode.NextSibling;
  if NNode <> nil then
  begin
    Result:= true;
    Pop;
    Push(NNode);
  end
  else
    Result:= false;
end;

function tXMLFile.Prev: boolean;
var
  NNode: TDOMNode;
begin
  NNode:= CurrentNode.PreviousSibling;
  if NNode <> nil then
  begin
    Result:= true;
    Pop;
    Push(NNode);
  end
  else
    Result:= false;
end;

function tXMLFile.Back: boolean;
begin
  if Stack^.Next <> nil then
  begin
    Result:= true;
    Pop
  end
  else
    Result:= false;
end;

procedure tXMLFile.BackToRoot;
begin
  while Stack^.Next <> nil do
    Pop   // to free memory
end;

function tXMLFile.IterateNodesWithName(Name: string): boolean;
begin
  {while IterateNodesWithName('Name') do
   begin
    ...
   end;
   Back;
   while IterateNodesWithName('NextName') do
   begin
    ...
   end;
  }
  if CurrentNode.NodeName = Name then
  begin
    Result:= Next;
    if CurrentNode.NodeName <> Name then
    begin
      Result:= false;
      Prev;
    end
  end
  else
    Result:= FindNode(Name);
  //writeln(CurrentNode.NodeName);
end;

procedure tXMLFile.Push(n: TDomNode);
var
  p: pStackNode;
begin
  new(p);
  with p^ do
  begin
    Value:= n;
    Next:= Stack;
  end;

  Stack:= p;
end;

function tXMLFile.Pop: TDomNode;
var
  p: pStackNode;
begin
  Result:= Stack^.Value;
  p:= Stack;
  Stack:= Stack^.Next;
  dispose(p);
end;

function tXMLFile.GetCurrentNode: TDOMNode;
begin
  Result:= Stack^.Value;
end;

constructor tXMLFile.CreateNew(fn: string; Overwrite: boolean = false; RootNodeName: string = '');
begin
  FileName:= fn;

  try
    if not Overwrite then
       if FileExists(fn) then
          raise Exception.Create('File already exists, overwrite not permitted');

    Modified:= true;

    if RootNodeName = '' then
      RootNodeName:= fn;

    Doc:= tXMLDocument.Create;

    RootNode:= Doc.CreateElement(RootNodeName);
    new(Stack);
    Stack^.Next:= nil;
    Stack^.Value:= RootNode;
    Doc.AppendChild(RootNode);
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
      //E.Free;
      Free;
      //Result:= -1;
    end;
  end;
end;

constructor tXMLFile.Open(fn: string);
begin
  Modified:= false;
  FileName:= fn;
  try
    if not FileExists(fn) then
      raise Exception.Create('File does not exist');

    ReadXMLFile(Doc, FileName);
    RootNode:= Doc.DocumentElement;
    new(Stack);
    Stack^.Next:= nil;
    Stack^.Value:= RootNode;
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
      //E.Free;
      Free;
    end;
  end;
end;

function tXMLFile.Save: integer;
begin
  WriteXMLFile(Doc, FileName);
  Result:= 1;
end;


destructor tXMLFile.Destroy;
begin
  if Modified then
     Save;
  freeandnil(Doc);
  inherited Destroy;
end;

end.

