program Dungeon;

{$APPTYPE CONSOLE}
{$R *.res}

uses
   System.SysUtils, TypInfo, System.Types, Generics.Collections, Windows;

type
   CellType = (Floor, Wall, None, Exit, Entrance, User, Highlite);
   TColor = (Blue, Green, Cyan, Red, Pink, Yellow, White, Gray);

   LEVEL = record
      depth, color: Integer;
      W, H: Integer;
      MAP: array of array of CellType;
   end;

   Building = record
      Floors: array of LEVEL;
   end;

var
   unvisited, i, track: Integer;
   House: Building;
   start: TPoint;
   UserPos: TPoint;
   UserLevel: Integer;
   d: array of array of Integer;

const
   FLOORS_AMT = 8;
   WIDTH = 51;
   HEIGHT = 51;
   INF = 100000;

const
   dx: array [0 .. 3] of Integer = (0, -1, 0, 1);
   dy: array [0 .. 3] of Integer = (-1, 0, 1, 0);

procedure setConsoleColor(color: Integer);
begin
   SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),
     color or FOREGROUND_INTENSITY);
end;

procedure InitializeMap(var lvl: LEVEL);
var
   i, j: Integer;
begin
   unvisited := 0;
   with lvl do
   begin
      SetLength(MAP, H, W);
      for i := 0 to H - 1 do
         for j := 0 to W - 1 do
            if ((i mod 2 <> 0) AND (j mod 2 <> 0) AND (i < H - 1) AND
              (j < W - 1)) then
            begin
               MAP[i][j] := None;
               Inc(unvisited);
            end
            else
               MAP[i][j] := Wall;
   end;

end;

procedure PrintLevel(lvl: LEVEL);
var
   i, j: Integer;
begin
   with lvl do
   begin
      Writeln('The ', depth + 1, 'th ', GetEnumName(TypeInfo(TColor), Ord(depth)
        ), ' floor...');
      for i := 0 to H - 1 do
      begin
         for j := 0 to W - 1 do
         begin
            case MAP[i][j] of
               Wall, None:
                  Write('█');
               Floor:
                  Write(' ');
               Exit:
                  begin
                     setConsoleColor((lvl.color + 3) mod 8);
                     Write('X');
                  end;
               Entrance:
                  begin
                     setConsoleColor((lvl.color + 3) mod 8);
                     Write('O');
                  end;
               User:
                  BEGIN
                     setConsoleColor((lvl.color + 4) mod 8);
                     Write('&');
                  END;
               Highlite:
                  BEGIN
                     setConsoleColor((lvl.color + 2) mod 8);
                     Write('█');
                  END;
            end;
            setConsoleColor(lvl.color);
         end;
         Writeln;
      end;
   end;
   Writeln;
end;

procedure GenerateMaze(var lvl: LEVEL; x, y: Integer);
var
   q: TStack<TPoint>;
   i, j, tox, toy, size, dir: Integer;
   pnt: TPoint;
   neigh: array [0 .. 4] of TPoint;
begin
   q := TStack<TPoint>.Create;
   with lvl do
   begin
      pnt := Point(x, y);
      MAP[x][y] := Entrance;
      while (unvisited <> 1) do
      begin
         size := 0;
         for i := 0 to 3 do
         begin
            tox := pnt.x + dx[i] * 2;
            toy := pnt.y + dy[i] * 2;
            if ((tox < H) AND (toy < W) AND (tox >= 0) AND (toy >= 0) AND
              (MAP[tox][toy] = None)) then
            begin
               neigh[size] := Point(tox, toy);
               Inc(size);
            end;
         end;
         if (size <> 0) then
         begin
            dir := Random(size);
            tox := neigh[dir].x;
            toy := neigh[dir].y;
            q.Push(pnt);
            MAP[(pnt.x + tox) div 2][(pnt.y + toy) div 2] := Floor;
            Dec(unvisited);
            if (unvisited = 1) then
            begin
               MAP[tox][toy] := Exit;
               start := Point(tox, toy);
            end
            else
               MAP[tox][toy] := Floor;
            pnt := Point(tox, toy);
         end
         else if (q.Count > 0) then
         begin
            pnt := q.Pop();
         end;
      end;
   end;
end;

function OK(pnt: TPoint): Boolean;
begin
   with pnt do
      Result := (x < HEIGHT) AND (y < WIDTH) AND (x >= 0) AND (y >= 0);
end;

procedure MarkPath(var lvl: LEVEL; start: TPoint);
var
   q: TQueue<TPoint>;
   used: array of array of Boolean;
   curLvl: Integer;
   i, j, tox, toy: Integer;
   pnt: TPoint;
   found: Boolean;
begin
   with lvl do
   begin
      pnt := start;
      found := False;
      while (not found) do
      begin
         for i := 0 to 3 do
         begin
            tox := pnt.x + dx[i];
            toy := pnt.y + dy[i];
            if (OK(Point(tox, toy)) AND (d[tox][toy] = d[pnt.x, pnt.y] - 1) AND
              (MAP[tox][toy] <> Wall)) then
            begin
               pnt := Point(tox, toy);
               if (MAP[pnt.x][pnt.y] = User) then
                  found := true
               else
                  MAP[tox][toy] := Highlite;
            end;
         end;
      end;
   end;
end;

procedure FindPath(lvl: LEVEL; start: TPoint);
VAR
   q: TQueue<TPoint>;
   curLvl: Integer;
   i, j, tox, toy: Integer;
   pnt: TPoint;
   found: Boolean;
begin
   curLvl := lvl.depth;
   q := TQueue<TPoint>.Create;
   SetLength(d, lvl.H, lvl.W);
   while (curLvl <> -1) do
   begin
      with lvl do
      begin
         for i := 0 to H - 1 do
            for j := 0 to W - 1 do
            begin
               d[i][j] := INF;
            end;
         q.Clear();
         d[start.x, start.y] := 0;
         q.Enqueue(start);
         found := False;
         while (q.Count <> 0) do
         begin
            pnt := q.Dequeue();
            for i := 0 to 3 do
            begin
               tox := pnt.x + dx[i];
               toy := pnt.y + dy[i];
               if (OK(Point(tox, toy)) AND (d[tox][toy] > d[pnt.x, pnt.y] + 1)
                 AND (MAP[tox][toy] <> Wall)) then
               begin
                  d[tox, toy] := d[pnt.x, pnt.y] + 1;
                  if (MAP[tox][toy] = Entrance) then
                  begin
                     MarkPath(lvl, Point(tox, toy));
                     setConsoleColor(lvl.color);
                     PrintLevel(lvl);
                     start := Point(tox, toy);
                     Dec(curLvl);
                     if (curLvl >= 0) then
                     begin
                        lvl := House.Floors[curLvl];
                        MAP[tox, toy] := User;
                     end;
                     found := true;
                     break;
                  end;
                  q.Enqueue(Point(tox, toy));
               end;
            end;
            if (found) then
            begin
               break;
            end;
         end;
      end;
   end;
end;

begin
   Randomize;
   start := Point(1, 1);
   SetLength(House.Floors, FLOORS_AMT);
   track := 1;
   for i := 0 to FLOORS_AMT - 1 do
   begin
      House.Floors[i].W := WIDTH;
      House.Floors[i].H := HEIGHT;
      House.Floors[i].depth := i;
      House.Floors[i].color := track;
      InitializeMap(House.Floors[i]);
      GenerateMaze(House.Floors[i], start.x, start.y);
      track := track + 1;
   end;
   UserLevel := Random(FLOORS_AMT);
   UserPos := Point(Random(HEIGHT - 2) + 2, Random(WIDTH - 2) + 2);
   with UserPos do
   begin
      if (x mod 2 = 0) then
         Dec(x);
      if (y mod 2 = 0) then
         Dec(y);
   end;
   House.Floors[UserLevel].MAP[UserPos.x][UserPos.y] := User;
   for i := 0 to FLOORS_AMT - 1 do
   begin
      setConsoleColor(House.Floors[i].color);
      PrintLevel(House.Floors[i]);
   end;

   Writeln('You are at the ', GetEnumName(TypeInfo(TColor), Ord(UserLevel)),
     ' floor...');
   Readln;
   FindPath(House.Floors[UserLevel], UserPos);
   setConsoleColor(FOREGROUND_RED);
   Writeln('FREEDOM FREEDOM FREEDOM !!!');
   Readln;

end.
