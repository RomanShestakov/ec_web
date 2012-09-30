-module(web_app).
-behaviour(application).
-export([
	 start/0,
	 start/2,
	 stop/1
	]).

%% required apps for ec_master
-define(APPS, [nprocreg, mochiweb, ec_cli, sync, ec_web]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

%% to start manually from console with start.sh
start() ->
    [begin application:start(A), io:format("~p~n", [A]) end || A <- ?APPS].

start(_StartType, _StartArgs) ->
    web_sup:start_link().

stop(_State) ->
    ok.
