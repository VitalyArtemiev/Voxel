unit Character;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Entities, Voxel, Economy;

type
  eGoalKind = (gDrink, gEat, gSleep, gBuy, gSell, gOwn, gEarn, gWork, gGetToPos);

  rGoal = record
    Kind: eGoalKind;
    Priority: longword;

  end;

  eCharProf = (Beggar, Oddjob, Farmer, Lumberjack, Blacksmith, WoodCrafter, Trader, Mercenary);

  { tSkillSet }

  tSkillSet = class
    Skills: array [0..integer(high(eCharProf))] of word;
    procedure Rust;
  end;

  rAsset = record
    Kind: eGoodKind;
    Location: rLocation;
    Amount: quantative;
  end;

  { tCharacter }

  tCharacter = class(tMovableEntity)
    Profession: eCharProf;
    MajorGoals, MinorGoals: array of rGoal;
    Assets: array of rAsset;
    Home: tStructure;
  private
    HomeHub: tEconomicHub;
    procedure ManageGoals;
  end;

implementation

{ tSkillSet }

procedure tSkillSet.Rust;
begin

end;

{ tCharacter }

procedure tCharacter.ManageGoals;
begin

end;

end.

