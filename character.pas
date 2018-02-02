unit Character;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CustomTypes, Entities, Voxel, Goods, Schedule;

type
  eGoalKind = (gDrink, gEat, gSleep, gBuy, gSell, gOwn, gEarn, gWork, gGetToPos);

  rGoal = record
    Kind: eGoalKind;
    Priority: longword;
  end;

  eCharProf = (Beggar, Oddjob, Farmer, Lumberjack, Miner,
               Blacksmith, WoodCrafter, Trader, Mercenary);

  { tSkillSet }

  tSkillSet = class
    Skills: array [0..integer(high(eCharProf))] of word;
    procedure Rust;
  end;

  { tCondition }

  tCondition = class
    Blood, Energy: quantative;

    procedure Consume(Food: quantative); //make universal for dif types
  end;

  tBaseCharacter = class(tMovableEntity)
    Profession: eCharProf;
    Wealth: monetary;

  end;

  { tCharacter }

  tCharacter = class(tMovableEntity)
    //Profession: eCharProf;  managed by skills?
    SkillSet: tSkillSet;
    Condition: tCondition;
    MajorGoals, MinorGoals: array of rGoal;   //long-term/short-term
    Assets: array of rAsset;
    Home: tStructure;
  private
    //HomeHub: tEconomicHub;
    procedure ManageGoals;
  end;

  tCharContainer = class
    Characters: array of tCharacter;
    Schedule: tSchedule;
  end;

  { tCharIDContainer }

  tCharIDContainer = class
    IDs: array of tEntityID;
    function LoadExplicit: tCharContainer; //uses major goals to figure out wha happened
  end;

implementation

const
  EnergyThreshold = 10000;

{ tCondition }

procedure tCondition.Consume(Food: quantative);
begin
  Energy+= Food;
end;

{ tCharIDContainer }

function tCharIDContainer.LoadExplicit: tCharContainer;
begin
  Result:= nil;
end;

{ tSkillSet }

procedure tSkillSet.Rust;
begin

end;

{ tCharacter }

procedure tCharacter.ManageGoals;
begin
  if Condition.Energy < EnergyThreshold then
  begin

  end;
end;

end.

