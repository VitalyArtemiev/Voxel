unit Goods;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CustomTypes, Entities;

type

  eGoodKind = (gWood, gStone, gCoal, gFood, gMetal, gWeapon, gAmmunition, Building); //...

  pGood = ^rGood;

  rGood = record
    Kind: eGoodKind;
    BaseCost: monetary;
  end;

  rAsset = record
    Kind: eGoodKind;
    Location: tLocation;
    Amount: quantative;
  end;

implementation

end.

