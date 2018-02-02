unit Schedule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Entities, BaseTypes;

type
  { tSchedule }

  tSchedule = class
    RootEvent: pEvent;
    constructor Create;
    destructor Destroy; override;
    procedure CheckTime;
    //findevent
  end;


implementation

{ tSchedule }

constructor tSchedule.Create;
begin
  new(RootEvent);
end;

destructor tSchedule.Destroy;
begin

end;

procedure tSchedule.CheckTime;
begin

end;

end.

