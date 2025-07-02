include "globals.mzn";

% ----------------------
%      Parameters
% ----------------------

int: HEIGHT;
int: WIDTH;
int: AGENTS;
int: NODES = HEIGHT * WIDTH;

array[1..AGENTS, Marker] of Node: path;
array[1..NODES] of 0..AGENTS: starts = [sum (a in 1..AGENTS) (a * (path(a, Start) == n)) | n in 1..NODES];
array[1..NODES] of 0..AGENTS: ends = [sum (a in 1..AGENTS) (a * (path(a, End) == n)) | n in 1..NODES];

% ----------------------
%      Datatypes
% ----------------------

% Surface belt types.
enum SB = {
  SB_None,
  SB_N,
  SB_E,
  SB_S,
  SB_W,
  SB_TI_N,
  SB_TI_E,
  SB_TI_S,
  SB_TI_W,
  SB_TO_N,
  SB_TO_E,
  SB_TO_S,
  SB_TO_W
};

% A Start or End marker.
enum Marker = {
  Start,
  End
};

% Path node.
type Node = record (int: y, int: x, string: d);

% ----------------------
%   Decision Variables
% ----------------------

array[1..NODES] of var SB: sb;
array[1..NODES] of var 0..AGENTS: sba;
array[1..NODES] of var 1..NODES: next;

% ----------------------
%       Functions
% ----------------------

function bool: bounds(int: y, int: x) =
  y in 1..HEIGHT /\ x in 1..WIDTH;

function 0..NODES: index(int: y, int: x) =
  if bounds(y, x) then (y - 1) * WIDTH + x else 0 endif;

function var 1..WIDTH: x(var int: n) =
  (n - 1) mod WIDTH + 1;

function var 1..HEIGHT: y(var int: n) =
  (n - 1) div WIDTH + 1;

function var SB: sb(int: y, int: x) =
  if bounds(y, x) then sb[index(y, x)] else SB_None endif;

function var 0..AGENTS: sba(int: y, int: x) =
  if bounds(y, x) then sba[index(y, x)] else 0 endif;

function 1..NODES: path(int: a, Marker: m) =
  index(path[a, m].y, path[a, m].x);

function 0..AGENTS: starts(int: y, int: x) =
  starts[index(y, x)];

function 0..AGENTS: ends(int: y, int: x) =
  ends[index(y, x)];

function var 1..NODES: next(int: y, int: x) =
  next[index(y, x)];

% ----------------------
%   Global Constraints
% ----------------------

% There must be one path connecting all the starts and ends.
constraint subcircuit(next);

% Every node must point at a different node.
constraint alldifferent(next);

% ----------------------
%   Fixed Constraints
% ----------------------

% Fix all agent start and end directions.
constraint forall (a in 1..AGENTS, m in Marker) (
  if     path[a, m].d == "^" then sb[path(a, m)] == SB_N
  elseif path[a, m].d == "v" then sb[path(a, m)] == SB_S
  elseif path[a, m].d == "<" then sb[path(a, m)] == SB_W
  elseif path[a, m].d == ">" then sb[path(a, m)] == SB_E endif);

% ----------------------
% Channeling Constraints
% ----------------------

% Empty cells point at themselves.
constraint forall (n in 1..NODES) (sb[n] == SB_None <-> next[n] == n);

% Next agrees with surface belt placement.
constraint forall(y in 1..HEIGHT, x in 1..WIDTH where ends(y,x) = 0)
  (table(
    [enum2int(sb(y, x)), y(next(y, x)), x(next(y, x))],
    [|enum2int(SB_None), y            , x
     |enum2int(   SB_N), y - 1        , x
     |enum2int(   SB_S), y + 1        , x
     |enum2int(   SB_W), y            , x - 1
     |enum2int(   SB_E), y            , x + 1
     |enum2int(SB_TO_N), y - 1        , x
     |enum2int(SB_TO_S), y + 1        , x
     |enum2int(SB_TO_W), y            , x - 1
     |enum2int(SB_TO_E), y            , x + 1
     |enum2int(SB_TI_N), y - 2        , x
     |enum2int(SB_TI_N), y - 3        , x
     |enum2int(SB_TI_N), y - 4        , x
     |enum2int(SB_TI_N), y - 5        , x
     |enum2int(SB_TI_S), y + 2        , x
     |enum2int(SB_TI_S), y + 3        , x
     |enum2int(SB_TI_S), y + 4        , x
     |enum2int(SB_TI_S), y + 5        , x
     |enum2int(SB_TI_W), y            , x - 2
     |enum2int(SB_TI_W), y            , x - 3
     |enum2int(SB_TI_W), y            , x - 4
     |enum2int(SB_TI_W), y            , x - 5
     |enum2int(SB_TI_E), y            , x + 2
     |enum2int(SB_TI_E), y            , x + 3
     |enum2int(SB_TI_E), y            , x + 4
     |enum2int(SB_TI_E), y            , x + 5|]));

% Enforce belt to belt transitions are valid.
constraint forall (y in 1..HEIGHT, x in 1..WIDTH where ends(y, x) == 0)
  (table(
    [enum2int(sb[index(y, x)]), enum2int(sb[next(y, x)])],
    [|enum2int(SB_TI_N), enum2int(SB_TO_N)
     |enum2int(SB_TI_S), enum2int(SB_TO_S)
     |enum2int(SB_TI_W), enum2int(SB_TO_W)
     |enum2int(SB_TI_E), enum2int(SB_TO_E)
     |enum2int(   SB_N), enum2int(   SB_N)
     |enum2int(   SB_N), enum2int(   SB_W)
     |enum2int(   SB_N), enum2int(   SB_E)
     |enum2int(   SB_N), enum2int(SB_TI_N)
     |enum2int(   SB_S), enum2int(   SB_S)
     |enum2int(   SB_S), enum2int(   SB_W)
     |enum2int(   SB_S), enum2int(   SB_E)
     |enum2int(   SB_S), enum2int(SB_TI_S)
     |enum2int(   SB_W), enum2int(   SB_N)
     |enum2int(   SB_W), enum2int(   SB_S)
     |enum2int(   SB_W), enum2int(   SB_W)
     |enum2int(   SB_W), enum2int(SB_TI_W)
     |enum2int(   SB_E), enum2int(   SB_N)
     |enum2int(   SB_E), enum2int(   SB_S)
     |enum2int(   SB_E), enum2int(   SB_E)
     |enum2int(   SB_E), enum2int(SB_TI_E)
     |enum2int(SB_TO_N), enum2int(   SB_N)
     |enum2int(SB_TO_N), enum2int(   SB_W)
     |enum2int(SB_TO_N), enum2int(   SB_E)
     |enum2int(SB_TO_N), enum2int(SB_TI_N)
     |enum2int(SB_TO_S), enum2int(   SB_S)
     |enum2int(SB_TO_S), enum2int(   SB_W)
     |enum2int(SB_TO_S), enum2int(   SB_E)
     |enum2int(SB_TO_S), enum2int(SB_TI_S)
     |enum2int(SB_TO_W), enum2int(   SB_N)
     |enum2int(SB_TO_W), enum2int(   SB_S)
     |enum2int(SB_TO_W), enum2int(   SB_W)
     |enum2int(SB_TO_W), enum2int(SB_TI_W)
     |enum2int(SB_TO_E), enum2int(   SB_N)
     |enum2int(SB_TO_E), enum2int(   SB_S)
     |enum2int(SB_TO_E), enum2int(   SB_E)
     |enum2int(SB_TO_E), enum2int(SB_TI_E)
     |enum2int(SB_None), enum2int(SB_None)|]));

% ----------------------
%   Agent Constraints
% ----------------------

% Empty cells have no agent.
constraint forall (n in 1..NODES) (sb[n] = SB_None <-> sba[n] = 0);

% The agent of a cell equals the agent of the cell it points at for all nodes except ends.
constraint forall (n in 1..NODES where ends[n] == 0) (sba[n] == sba[next[n]]);

% Agent starts must match.
constraint forall (n in 1..NODES where starts[n] != 0) (sba[n] == starts[n]);

% Agent ends must match.
constraint forall (n in 1..NODES where ends[n] != 0) (sba[n] == ends[n]);

% ----------------------
%   Tunnel Constraints
% ----------------------

% Disallow nested tunnels in the same axis.
constraint forall (y in 1..HEIGHT, x in 1..WIDTH) (
  let {
    set of SB: notNS = SB diff {SB_TI_N, SB_TO_N, SB_TI_S, SB_TO_S};
    set of SB: notWE = SB diff {SB_TI_E, SB_TO_E, SB_TI_W, SB_TO_W};
  } in
  if     sb(y, x) == SB_TI_N then forall (yy in y(next(y, x)) + 1..y - 1) (sb(yy,  x) in notNS)
  elseif sb(y, x) == SB_TI_S then forall (yy in y + 1..y(next(y, x)) - 1) (sb(yy,  x) in notNS)
  elseif sb(y, x) == SB_TI_W then forall (xx in x(next(y, x)) + 1..x - 1) (sb( y, xx) in notWE)
  elseif sb(y, x) == SB_TI_E then forall (xx in x + 1..x(next(y, x)) - 1) (sb( y, xx) in notWE) endif);

% Tunnel entrances are followed by a non-empty tile.
constraint forall (y in 1..HEIGHT, x in 1..WIDTH) (
  if     sb(y, x) == SB_TI_N then 1 < y      /\ sb(y - 1, x    ) in SB diff {SB_None, SB_TI_N, SB_TO_N, SB_TI_S, SB_TO_S}
  elseif sb(y, x) == SB_TI_S then y < HEIGHT /\ sb(y + 1, x    ) in SB diff {SB_None, SB_TI_N, SB_TO_N, SB_TI_S, SB_TO_S}
  elseif sb(y, x) == SB_TI_W then 1 < x      /\ sb(y    , x - 1) in SB diff {SB_None, SB_TI_E, SB_TO_E, SB_TI_W, SB_TO_W}
  elseif sb(y, x) == SB_TI_E then x < WIDTH  /\ sb(y    , x + 1) in SB diff {SB_None, SB_TI_E, SB_TO_E, SB_TI_W, SB_TO_W} endif);

% Tunnel exits are preceded by a non-empty tile.
constraint forall (y in 1..HEIGHT, x in 1..WIDTH) (
  if     sb(y, x) == SB_TO_S then 1 < y      /\ sb(y - 1, x    ) in SB diff {SB_None, SB_TI_N, SB_TO_N, SB_TI_S, SB_TO_S}
  elseif sb(y, x) == SB_TO_N then y < HEIGHT /\ sb(y + 1, x    ) in SB diff {SB_None, SB_TI_N, SB_TO_N, SB_TI_S, SB_TO_S}
  elseif sb(y, x) == SB_TO_E then 1 < x      /\ sb(y    , x - 1) in SB diff {SB_None, SB_TI_E, SB_TO_E, SB_TI_W, SB_TO_W}
  elseif sb(y, x) == SB_TO_W then x < WIDTH  /\ sb(y    , x + 1) in SB diff {SB_None, SB_TI_E, SB_TO_E, SB_TI_W, SB_TO_W} endif);

% ----------------------
% Subcircuit Constraints
% ----------------------

% All starts are path of the subcircuit.
constraint forall (a in 1..AGENTS) (next[path(a, Start)] != path(a, Start));

% All ends connect to the start of the next agent.
constraint forall (a in 1..AGENTS) (next[path(a, End)] == path(a mod AGENTS + 1, Start));

% ----------------------
% No shortcut Constraints
% ----------------------

array[1..16, 1..4] of SB: pattern =
 [| SB_S, SB_E, SB_E, SB_N
  | SB_N, SB_S, SB_N, SB_W
  | SB_S, SB_N, SB_E, SB_N
  | SB_W, SB_S, SB_N, SB_W
  | SB_S, SB_W, SB_W, SB_N
  | SB_E, SB_S, SB_N, SB_S
  | SB_S, SB_W, SB_S, SB_N
  | SB_E, SB_S, SB_N, SB_E
  | SB_S, SB_W, SB_E, SB_S
  | SB_E, SB_E, SB_N, SB_W
  | SB_S, SB_W, SB_E, SB_E
  | SB_E, SB_N, SB_N, SB_W
  | SB_N, SB_W, SB_E, SB_N
  | SB_E, SB_S, SB_W, SB_W
  | SB_W, SB_W, SB_E, SB_N
  | SB_E, SB_S, SB_S, SB_W
  |];

constraint forall(y in 1..HEIGHT-1, x in 1..WIDTH-1)
                 (let { array[1..4] of var SB: block =
                        [ sb(y,x), sb(y,x+1), sb(y+1,x), sb(y+1,x+1) ]; } in
                  forall(p in 1..16)
                        (exists(i in 1..4)(block[i] != pattern[p,i])));

% ----------------------
% Redundant Constraints
% ----------------------

constraint forall (y in 1..HEIGHT, x in 1..WIDTH where ends(y, x) == 0) (
  if     y == 1      then sb(y, x) in SB diff {SB_N, SB_TO_N, SB_TI_N}
  elseif y == HEIGHT then sb(y, x) in SB diff {SB_S, SB_TO_S, SB_TI_S}
  elseif x == 1      then sb(y, x) in SB diff {SB_W, SB_TO_W, SB_TI_W}
  elseif x == WIDTH  then sb(y, x) in SB diff {SB_E, SB_TO_E, SB_TI_E} endif);

% ----------------------
%         Goal
% ----------------------

var 0..HEIGHT * WIDTH: goal = count (n in 1..NODES) (sb[n] != SB_None);

solve minimize goal;

% ----------------------
%       Output
% ----------------------

function string: show_sb(int: y, int: x) =
  let {
    bool: ON = fix(sb[index(y, x)]) == SB_N;
    bool: OS = fix(sb[index(y, x)]) == SB_S;
    bool: OW = fix(sb[index(y, x)]) == SB_W;
    bool: OE = fix(sb[index(y, x)]) == SB_E;
    bool: IN = 1 < y      /\ (fix(sb[index(y - 1, x    )]) == SB_S \/ fix(sb[index(y - 1, x    )]) == SB_TO_S);
    bool: IS = y < HEIGHT /\ (fix(sb[index(y + 1, x    )]) == SB_N \/ fix(sb[index(y + 1, x    )]) == SB_TO_N);
    bool: IW = 1 < x      /\ (fix(sb[index(y    , x - 1)]) == SB_E \/ fix(sb[index(y    , x - 1)]) == SB_TO_E);
    bool: IE = x < WIDTH  /\ (fix(sb[index(y    , x + 1)]) == SB_W \/ fix(sb[index(y    , x + 1)]) == SB_TO_W);
  } in
  if IN /\ ON then "?"
  elseif IN /\ OS then "│"
  elseif IN /\ OW then "┘"
  elseif IN /\ OE then "└"

  elseif IS /\ ON then "│"
  elseif IS /\ OS then "?"
  elseif IS /\ OW then "┐"
  elseif IS /\ OE then "┌"

  elseif IW /\ ON then "┘"
  elseif IW /\ OS then "┐"
  elseif IW /\ OW then "?"
  elseif IW /\ OE then "─"

  elseif IE /\ ON then "└"
  elseif IE /\ OS then "┌"
  elseif IE /\ OW then "─"
  elseif IE /\ OE then "?"

  elseif ON then "│"
  elseif OS then "│"
  elseif OW then "─"
  elseif OE then "─"

  elseif fix(sb[index(y, x)]) == SB_TO_N then "║"
  elseif fix(sb[index(y, x)]) == SB_TO_S then "║"
  elseif fix(sb[index(y, x)]) == SB_TO_W then "═"
  elseif fix(sb[index(y, x)]) == SB_TO_E then "═"

  elseif fix(sb[index(y, x)]) == SB_TI_N then "║"
  elseif fix(sb[index(y, x)]) == SB_TI_S then "║"
  elseif fix(sb[index(y, x)]) == SB_TI_W then "═"
  elseif fix(sb[index(y, x)]) == SB_TI_E then "═"

  elseif fix(sb[index(y, x)]) != SB_None then "?"

  else " "
  endif;

output [show_sb(y, x) ++ if x == WIDTH then "\n" else "" endif | y in 1..HEIGHT, x in 1..WIDTH] ++
       [show(goal)];
