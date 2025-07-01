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

function int: index(int: y, int: x) =
  (y - 1) * WIDTH + x;

function var int: x(var int: n) =
  (n - 1) mod WIDTH + 1;

function var int: y(var int: n) =
  (n - 1) div WIDTH + 1;

function var SB: sb(int: y, int: x) =
  sb[index(y, x)];

function var 0..AGENTS: sba(int: y, int: x) =
  sba[index(y, x)];

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

constraint forall(y in 1..HEIGHT, x in 1..WIDTH where ends(y,x) = 0)
                 ( let { 0..NODES: tN = if y > 1 then index(y-1,x) else 0 endif;
                         0..NODES: tE = if x < WIDTH then index(y,x+1) else 0 endif;
                         0..NODES: tS = if y < HEIGHT then index(y+1,x) else 0 endif;
                         0..NODES: tW = if x > 1 then index(y,x-1) else 0 endif; } in
                               % SB_None,
                  next(y,x) = [index(y,x),
                               % SB_N,    SB_E,    SB_S,    SB_W
                               tN,        tE,      tS,      tW,
                               % SB_TI_N, SB_TI_E, SB_TI_S, SB_TI_W,
                               _,         _,       _,       _,
                               % SB_TO_N, SB_TO_E, SB_TO_S, SB_TO_W
                               tN,        tE,      tS,      tW]
                              [enum2int(sb(y,x))]);

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

array[int, int] of SB: TRANSITIONS =
  [|SB_TI_N, SB_TO_N
   |SB_TI_S, SB_TO_S
   |SB_TI_W, SB_TO_W
   |SB_TI_E, SB_TO_E
   |SB_N, SB_N
   |SB_N, SB_W
   |SB_N, SB_E
   |SB_N, SB_TI_N
   |SB_S, SB_S
   |SB_S, SB_W
   |SB_S, SB_E
   |SB_S, SB_TI_S
   |SB_W, SB_N
   |SB_W, SB_S
   |SB_W, SB_W
   |SB_W, SB_TI_W
   |SB_E, SB_N
   |SB_E, SB_S
   |SB_E, SB_E
   |SB_E, SB_TI_E
   |SB_TO_N, SB_N
   |SB_TO_N, SB_W
   |SB_TO_N, SB_E
   |SB_TO_N, SB_TI_N
   |SB_TO_S, SB_S
   |SB_TO_S, SB_W
   |SB_TO_S, SB_E
   |SB_TO_S, SB_TI_S
   |SB_TO_W, SB_N
   |SB_TO_W, SB_S
   |SB_TO_W, SB_W
   |SB_TO_W, SB_TI_W
   |SB_TO_E, SB_N
   |SB_TO_E, SB_S
   |SB_TO_E, SB_E
   |SB_TO_E, SB_TI_E
   |SB_None, SB_None|];

% Enforce belt to belt transitions are valid.
constraint forall (y in 1..HEIGHT, x in 1..WIDTH where ends(y, x) == 0)
  (table(
    [enum2int(s) | s in [sb[index(y, x)], sb[next(y, x)]]],
    array2d(index_set_1of2(TRANSITIONS), index_set_2of2(TRANSITIONS), [enum2int(s) | s in TRANSITIONS])));

% Enforce tunnel length is between 3 and 6.
constraint forall (y in 1..HEIGHT, x in 1..WIDTH) (
  if     sb(y, x) == SB_TI_N then
      x(next(y, x)) == x /\ y - 6 < y(next(y, x)) /\ y(next(y, x)) < y - 1
  elseif sb(y, x) == SB_TI_S then
      x(next(y, x)) == x /\ y + 1 < y(next(y, x)) /\ y(next(y, x)) < y + 6
  elseif sb(y, x) == SB_TI_W then
      y(next(y, x)) == y /\ x - 6 < x(next(y, x)) /\ x(next(y, x)) < x - 1
  elseif sb(y, x) == SB_TI_E then
      y(next(y, x)) == y /\ x + 1 < x(next(y, x)) /\ x(next(y, x)) < x + 6
  endif);

% Enforce tunnel entrances are preceded by a node facing into them.
constraint forall (y in 1..HEIGHT, x in 1..WIDTH) (
  if     sb(y, x) == SB_TI_S then 1 < y      /\ next(y - 1, x   ) == index(y, x)
  elseif sb(y, x) == SB_TI_N then y < HEIGHT /\ next(y + 1, x   ) == index(y, x)
  elseif sb(y, x) == SB_TI_E then 1 < x      /\ next(y   , x - 1) == index(y, x)
  elseif sb(y, x) == SB_TI_W then x < WIDTH  /\ next(y   , x + 1) == index(y, x) endif);

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
%         Goal
% ----------------------

solve minimize count (n in 1..NODES) (sb[n] != SB_None);

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
       [show(count (n in 1..NODES) (sb[n] != SB_None))];
