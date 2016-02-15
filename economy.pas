unit Economy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Entities{, Character,};

type
  monetary = longword;
  quantative = longword;
  temporal = qword;

  eGoodKind = (gWood, gStone, gCoal, gFood, gMetal, gWeapon, gAmmunition, Building); //...

  pGood = ^rGood;

  rGood = record
    Kind: eGoodKind;
    BaseCost: monetary;
  end;

  tCharacter = class(tMovableEntity);

  { rOffer }

  rOffer = record
    Good: pGood;
    Amount: quantative;
    PricePerUnit: monetary;
    Due: temporal;
    Customer: tCharacter;
  end;

  { tBillBoard }

  tBillBoard = class
    SellOffers, BuyOffers: array of rOffer;
    procedure PlaceOffer(o: rOffer);
    procedure RetractOffer(Index: longword);
  end;

  rGoodTrack = record
    Good: pGood;
    AmountLastPeriod: quantative;
    RevenueLastPeriod: monetary;
  end;

  { tEconomicHub }

  tEconomicHub = class
    GDP: longword;
    ExportGoods, ImportGoods, ProducedGoods: array of rGoodTrack;
    BillBoard: tBillBoard;
    procedure CalcSupplyDemand;
  end;

implementation

{ tEconomicHub }

procedure tEconomicHub.CalcSupplyDemand;
begin

end;

{ tBillBoard }

procedure tBillBoard.PlaceOffer(o: rOffer);
begin

end;

procedure tBillBoard.RetractOffer(Index: longword);
begin

end;

end.

