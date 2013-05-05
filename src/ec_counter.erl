-module(ec_counter).
-export([start/1, stop/1, next/1]).

%% start counter
start(StartValue) ->
    spawn(fun() -> loop(StartValue) end).

stop(CounterPid) -> CounterPid ! {stop, self()}.

%% get next count
next(CounterPid) ->
    CounterPid ! {incr, self()},
    receive
	Count -> Count
    end.

%% couner loop
loop(Count) ->
    receive
	{incr, From} ->
	    From ! Count,
	    loop(Count + 1);
	stop -> void
    end.
