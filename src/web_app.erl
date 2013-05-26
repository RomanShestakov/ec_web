-module(web_app).
-behaviour(application).
-export([
	 start/0,
	 start/2,
	 stop/1
	]).

-include_lib("ec_web/include/ec_web.hrl").

%% required apps for ec_master
-define(APPS, [lager, nprocreg, crypto, ranch, cowboy, resource_discovery, ?WEBAPP]).

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
