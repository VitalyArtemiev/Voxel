{$MODESWITCH EXCEPTIONS+}
uses
  ptc, classes;
type
                grid = array of array of single;

        type_vel=record
                x,y,z:double;
        end;

        type_point=object
                x,y,z,rx,ry,rz:double;
                color:longword;
                {procedure relatify;
                procedure project(var ox,oy:longint); }
        end;

        type_poly=record
                p1,p2,p3:^type_point;
        end;

        type_model=object
                x,y,z,xangle,yangle,zangle:double;
                point:array of type_point;
                acc,racc,vel,rvel:type_vel;
                visible:boolean;
                {procedure calccenter;
                procedure move{(time:double)};
                procedure rotate(xa,ya,za:double);
                procedure draw;}
        end;
const
  ts = 20;
var
        ElMap: grid;
        DifCoef: single;
        HMName: string;
        i,j,xs,ys,Generation: integer;

        Console: IPTCConsole;
        Current, Previous: IPTCSurface;
        Format: IPTCFormat;
        Key: IPTCKeyEvent;
        Pixels: PDWord;
        terrain: type_model;

procedure Smooth(var origin: grid);
var
   Result: grid;
begin
     inc(Generation);
     setlength(Result, length(Origin), length(Origin[0]));
        i:=0; j:=0;
        Result[i,j]:=Origin[i,j]*DifCoef+Origin[i+1,j]+Origin[i+1,j+1]+Origin[i,j+1];
        Result[i,j]:=Result[i,j] / 4;
        if Result[i,j]>1000 then Result[i,j]:=1000-random(500);
        if Result[i,j]<-1000 then Result[i,j]:=-1000;
        i:=xs-1; j:=ys-1;
        Result[i,j]:=Origin[i,j]*DifCoef+Origin[i-1,j]+Origin[i-1,j-1]+Origin[i,j-1];
        Result[i,j]:=Result[i,j] / 4;
        if Result[i,j]>1000 then Result[i,j]:=1000-random(500);
        if Result[i,j]<-1000 then Result[i,j]:=-1000;
        i:=xs-1; j:=0;
        Result[i,j]:=Origin[i,j]*DifCoef+Origin[i-1,j]+Origin[i-1,j+1]+Origin[i,j+1];
        Result[i,j]:=Result[i,j] / 4;
        if Result[i,j]>1000 then Result[i,j]:=1000-random(500);
        if Result[i,j]<-1000 then Result[i,j]:=-1000;
        i:=0; j:=ys-1;
        Result[i,j]:=Origin[i,j]*DifCoef+Origin[i+1,j]+Origin[i+1,j-1]+Origin[i,j-1];
        Result[i,j]:=Result[i,j] / 4;
        if Result[i,j]>1000 then Result[i,j]:=1000-random(500);
        if Result[i,j]<-1000 then Result[i,j]:=-1000;

        for j:=1 to ys-2 do
        begin
             Result[0,j]:=Origin[0,j]*DifCoef+Origin[1,j]+Origin[0,j-1]+Origin[0,j+1]+Origin[1,j-1]+Origin[1,j+1];
             Result[0,j]:=Result[0,j] / 6;

             if Result[0,j]<-1000 then Result[0,j]:=-1000;
             Result[xs-1,j]:=Origin[xs-1,j]*DifCoef+Origin[ys-2,j]+Origin[ys-1,j-1]+Origin[ys-1,j+1]+Origin[ys-2,j-1]+Origin[ys-2,j+1];
             Result[xs-1,j]:=Result[xs-1,j] / 6;
             if odd(Generation) then
             begin
                  if Result[0,j]>1000 then Result[0,j]:=1000-random(500);
                  if Result[xs-1,j]>1000 then Result[xs-1,j]:=1000-random(500);
             end;
             if Result[xs-1,j]<-1000 then Result[xs-1,j]:=-1000;
        end;

        for i:=1 to xs-2 do
        begin
                Result[i,0]:=Origin[i,0]*DifCoef+Origin[i-1,0]+Origin[i-1,1]+Origin[i+1,0]+Origin[i+1,1]+Origin[i,1];
                Result[i,0]:=Result[i,0] / 6;

                if Result[i,0]<-1000 then Result[i,0]:=-1000;
                Result[i,ys-1]:=Origin[i,ys-1]*DifCoef+Origin[i-1,ys-1]+Origin[i-1,ys-2]+Origin[i+1,ys-1]+Origin[i+1,ys-2]+Origin[i,ys-2];
                Result[i,ys-1]:=Result[i,ys-1] / 6;
                if odd(Generation) then
                begin
                     if Result[i,0]>1000 then Result[i,0]:=1000-random(500);
                     if Result[i,ys-1]>1000 then Result[i,ys-1]:=1000-random(500);
                end;
                if Result[i,ys-1]<-1000 then Result[i,ys-1]:=-1000;
                for j:=1 to ys-2 do
                begin
                        Result[i,j]:=Origin[i,j]*DifCoef+Origin[i-1,j]+Origin[i-1,j-1]+Origin[i-1,j+1]+Origin[i+1,j]+Origin[i+1,j-1]+Origin[i+1,j+1]+Origin[i,j-1]+Origin[i,j+1];
                        Result[i,j]:=Result[i,j] / 9;
                        if odd(Generation) and (Result[i,j]>1000) then Result[i,j]:=1000-random(500);
                        if Result[i,j]<-1000 then Result[i,j]:=-1000;
                end;
        end;

        for i:=0 to xs-1 do
                for j:=0 to ys-1 do Origin[i,j]:=Result[i,j];

        Current.Copy(Previous);
        Pixels := Current.Lock;
        for i:=0 to xs-1 do
            for j:=0 to ys-1 do
            begin
                 if Result[i,j]<0 then
                    Pixels[i*Current.Width+j]:=round(((Result[i,j]+1000)/1000)*255)
                 else
                    pixels[i*Current.Width+j]:=round((Result[i,j]/1000)*255)*$10000
            end;
        Current.Unlock;
end;

function pot(c:longword):longword;
begin
        pot:=round((ts*(ts* (c div xs) + c mod xs))/xs);
end;
                procedure modelterrain;
                                var
                                     pf:file of type_point;
                                     pp:file of longint;
                                     ct: file of longword; //coord texture?
                                     a,os, b, c:integer;
                                begin
                                        with terrain do
                                        begin
                                                setlength(point,length(elmap)*ys);
                                                for i:=0 to high(elmap) do
                                                        for j:=0 to ys-1 do
                                                        with point[i*ys+j] do
                                                        begin
                                                                x:=(i-high(elmap) div 2)*10;
                                                                z:=(j-ys div 2)*10;
                                                                y:=elmap[i,j] / 20
                                                        end
                                        end;
                                        assign(pf,'trn1.m');
                                        {$I-}
                                        rewrite(pf);
                                        {$I+}
                                        with terrain do
                                        for i:= 0 to high(point) do write(pf, point[i]);
                                        close(pf);
                                        assign(pp,'trn1.p');
                                        assign(ct,'trn1.c');
                                        {$I-}
                                        rewrite(pp);
                                        rewrite(ct);

                                        a:=-1;
                                        os:=0;
                                        for i:=0 to (xs-1)*(ys-1)*2 - 1  do
                                        begin
                                             if (not odd(i)) and (i mod ((xs-1)*2)<>0) then inc(os);
                                             a:=i-os;
                                             write(pp,a);
                                             if odd(i) then
                                             begin
                                               b:=a+xs-1;
                                               c:=a+xs;
                                               write(pp,b,c);
                                               write(ct, pot(b), pot(c));
                                             end
                                             else
                                             begin
                                                  b:=a+1;
                                                  c:=a+xs;
                                                  write(pp,b,c);
                                                  write(ct, pot(b), pot(c));
                                             end
                                        end;
                                        if IOResult = 0 then writeln('Successfully saved');
                                        close(pp);
                                        {$I+}
                                end;
{Procedure SaveTerrain;
var
   pf: file of type_point;
   pp: file of type_poly;
   a:longword;
begin
        assign(pf,'terrain1.m');
        {$I-}
        rewrite(pf);
        {$I+}
        for i:= 0 to xs-1 do
            for j:= 0 to ys-1 do
                 write(pf, (i - xs div 2)*10, (j - ys div 2)*10, Elmap[i,j] div 20);
        close(pf);
        assign(pf,'terrain1.p');
        {$I-}
        rewrite(pp);
        {$I+}
        for i:=0 to (xs-1)*(ys-1)*2 do
        begin
             if (not odd(i)) and (i mod ((xs-1)*2)<>0) then inc(os);
             a:=i-os;
             write(pp,a);
             if odd(i) then write(pp,a+xs,a+xs+1) else write(pp,a+1,a+xs);
        end;


end;  }

procedure HeightMap(FileName: string);
var
  fs: tFileStream;
  i, j: longword;
begin
  FileName+= '.hm';
  fs:= TFileStream.Create(FileName, fmCreate);
  for i:= 0 to xs - 1 do
    for j:= 0 to ys - 1 do
    fs.Write(elmap[i][j], sizeof(elmap[i][j]));
  fs.free;
end;

procedure ShowPrevious;
begin
     Previous.Copy(Console);
     Console.Update;
end;

procedure ShowCurrent;
begin
     Current.Copy(Console);
     Console.Update;
end;

begin
  randomize;
  repeat
        writeln('Vvedite razmery polya');
        readln(xs,ys);
  until (xs>0) and (ys>0);

  repeat
        writeln('Vvedite Koefficient differenciacii');
        readln(DifCoef);
  until difcoef>0;

        writeln('filename');
        readln(HMName);

  setlength(ElMap,xs,ys);

  for i:=0 to xs-1 do
      for j:=0 to ys-1 do
          ElMap[i,j]:=random(2000)-1000;

  try
    try
      Console := TPTCConsoleFactory.CreateNew;
      Format := TPTCFormatFactory.CreateNew(32, $00FF0000, $0000FF00, $000000FF);
      Console.Open('Terraformation Device',1280,1024, Format);

      Current := TPTCSurfaceFactory.CreateNew(Console.Width, Console.Height, Format);
      Previous := TPTCSurfaceFactory.CreateNew(Console.Width, Console.Height, Format);

      Pixels := Current.Lock;
        for i:=0 to xs-1 do
            for j:=0 to ys-1 do
            begin
                 if ElMap[i,j]<0 then
                    Pixels[i*Current.Width+j]:=round(((Elmap[i,j]+32768)/1000)*255)
                 else
                    Pixels[i*Current.Width+j]:=round((Elmap[i,j]/1000)*255)*$10000
            end;
        Current.Unlock;
        Current.Copy(Console);
        Console.Update;
      repeat
        if Console.KeyPressed then
        begin
          Console.ReadKey(key);

          case key.code of
            PTCKEY_LEFT: ShowPrevious;
            PTCKEY_RIGHT: ShowCurrent;
            PTCKEY_SPACE: Smooth(ElMap);
            PTCKEY_ENTER: HeightMap(HMName);//ModelTerrain;
            PTCKEY_ESCAPE: break;
          end;
        end;

      until False;
    finally
      if Assigned(Console) then
        Console.close;
    end;
  except
    on error: TPTCError do
      error.report;
  end;
  readln
end.
