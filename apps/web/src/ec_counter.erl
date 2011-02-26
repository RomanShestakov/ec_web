-module(ec_counter).
-export([start_counter/1, next/1]).

%% start counter
start_counter(StartValue) ->
    spawn(fun() -> loop(StartValue) end).

%% get next count
next(Counter) ->
    Counter ! {incr, self()},
    receive
	Count ->
	    Count
    end.

%% couner loop
loop(Count) ->
    receive
	{incr, From} ->

	    From ! Count,
	    loop(Count + 1)
    end.
