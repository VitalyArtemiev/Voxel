unit Economy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CustomTypes, Entities, Goods, Character, Voxel;

type

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
    Location: tLocation;
    BillBoard: tBillBoard;
    Characters: tCharContainer;

    GDP: longword;
    ExportGoods, ImportGoods, ProducedGoods: array of rGoodTrack;

    constructor Create(Voxel: tVoxel);
    destructor Destroy; override;
    procedure CalcSupplyDemand;
  end;

  tEconomicRoute = class
    Hub1, Hub2: tEconomicHub;
    Length: longword;
  end;

implementation

{ tEconomicHub }

constructor tEconomicHub.Create(Voxel: tVoxel);
begin
  Location:= tLocation.Create;
  //Location.Voxel:= Voxel;
  BillBoard:= tBillBoard.Create;
 // Location.Coords:=;
end;

destructor tEconomicHub.Destroy;
begin
  Location.Destroy;
  BillBoard.Destroy;
end;

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

