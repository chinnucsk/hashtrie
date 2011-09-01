%% Copyright (C) 2011 Björn-Egil Dahlberg
%%
%% File:    tarray.erl
%% Author:  Björn-Egil Dahlberg
%% Created: 2011-08-31

-module(tarray).

-export([
	set/3,
	get/2,
	fullness/1,
	new/0
    ]).

-define(power_of_eight, 1).

-define(node4, {_,_,_,_}).
-define(node8, {_,_,_,_, _,_,_,_}).
-define(node16, { _,_,_,_,_,_,_,_, _,_,_,_,_,_,_,_ }).

% power of two
-ifdef(power_of_four).
-define(node, { nil,nil,nil,nil }). 
-define(mask(X), ((X band 3) + 1)).
-define(shift(X), (X bsr 2)).
-define(rshift(X,I), (X bsr (2*I))).
-endif.

-ifdef(power_of_eight).
-define(node, { nil,nil,nil,nil, nil,nil,nil,nil }).
-define(mask(X), ((X band 7) + 1)).
-define(smask(X), ((X band 3) + 1)).
-define(bmask(X), ((X band 7) + 1)).

-define(shift(X), (X bsr 3)).
-define(sshift(X), (X bsr 2)).
-define(bshift(X), (X bsr 3)).
-define(rshift(X,I), (X bsr (3*I))).
-endif.

-ifdef(power_of_sixteen).
-define(node, { 
	nil,nil,nil,nil, 
	nil,nil,nil,nil, 
	nil,nil,nil,nil, 
	nil,nil,nil,nil 
    }).
-define(mask(X), ((X band 15) + 1)).
-define(shift(X), (X bsr 4)).
-define(rshift(X,I), (X bsr (4*I))).
-endif.


new() -> ?node.

set(I,V,A) when is_integer(I), I >= 0 -> do_set(I,V,A,I,1).
get(I,A)   when is_integer(I), I >= 0 -> do_get(I,A,I).

do_set(I,V,?node8 = A,Hx,L) ->
    Ix = ?mask(Hx),
    case element(Ix, A) of
	{I, _ ,_} = E         -> setelement(Ix, A, setelement(2, E, V));
	{I0,V0,S} when I0 > I -> setelement(Ix, A, {I,V,   do_set(I0,V0,S,?rshift(I0,L), L + 1)});
	{_ , _,S} = E         -> setelement(Ix, A, setelement(3, E, do_set(I, V, S,?shift(Hx), L + 1)));

	nil                   -> setelement(Ix, A, [I|V]);
	[I | _]               -> setelement(Ix, A, [I|V]);

	[I0|V0] when I0 > I   -> setelement(Ix, A, {I,V,   do_set(I0,V0,?node,?rshift(I0,L), L + 1)});
	[I0|V0]               -> setelement(Ix, A, {I0,V0, do_set(I, V, ?node,?shift(Hx), L + 1)})
	
    end.

do_get(I,?node8 = A,Hx) ->
    Ix = ?mask(Hx),
    case element(Ix, A) of
	[I|V]   -> V;
	{I,V,_} -> V;
	{_,_,S} -> do_get(I, S, ?shift(Hx));
	nil     -> undefined
    end.

%do_update(K,F,I,H,Hx) ->
%    Ix = ?mask(Hx),
%    case element(Ix, H) of
%	nil       -> setelement(Ix, H, [K|I]);
%	[K|V]     -> setelement(Ix, H, [K|F(V)]);
%	[K0|V0]   -> setelement(Ix, H, {K0,V0, do_put(K,I,?node, ?shift(Hx))});
%	{K,V,T}   -> setelement(Ix, H, {K,F(V),T});
%	{K0,V0,T} -> setelement(Ix, H, {K0,V0, do_update(K, F, I, T, ?shift(Hx))})
%    end.
%

fullness(H) -> 
    {A, I} = fullness(H, 1, 0, 0),
    1 - I/(A+I).

fullness(H, Ix, A, I) when Ix < 9 ->
    {A1, I1} = case element(Ix, H) of
	nil      -> {0, 1};
	{_,_,H1} -> fullness(H1, 1, 1, 0);
	_        -> {1, 0}
    end,
    fullness(H, Ix + 1, A + A1, I + I1);
fullness(_, _, A, I) -> {A, I}.


% end impl.

