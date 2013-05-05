%% -*- mode: nitrogen -*-
-module(web_sup).
-behaviour(supervisor).
-export([
	 start_link/0,
	 init/1
	]).

-include_lib("ec_web/include/ec_web.hrl").
-include_lib ("nitrogen_core/include/wf.hrl").

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    {ok, Port} = application:get_env(port),

    %% start a process to replicate mnesia from master
    db_sync:start_link(),

    io:format("Starting Cowboy Server ~p ~n", [Port]),
    {ok, _} = cowboy:start_http(http, 100,
				[{port, Port}],
				[{env, [{dispatch, dispatch_rules()}]}]),
    {ok, {{one_for_one, 5, 10}, []}}.

dispatch_rules() ->
    cowboy_router:compile(
	%% {Host, list({Path, Handler, Opts})}
	[{'_', [
	    {["/favicon.ico"], cowboy_static, [{directory, {priv_dir, ?WEBAPP, [<<"static">>]}}, {file, "images/favicon.ico"}]},
	    {["/content/[...]"], cowboy_static, [{directory, {priv_dir, ?WEBAPP, [<<"content">>]}},
		{mimetypes, {fun mimetypes:path_to_mimes/2, default}}]},
	    {["/static/[...]"], cowboy_static, [{directory, {priv_dir, ?WEBAPP, [<<"static">>]}},
		{mimetypes, {fun mimetypes:path_to_mimes/2, default}}]},
	    {["/[:page/:date/:job/]plugins/[...]"], cowboy_static, [{directory, {priv_dir, ?WEBAPP, [<<"plugins">>]}},
		{mimetypes, {fun mimetypes:path_to_mimes/2, default}}]},
	    {["/doc/[...]"], cowboy_static, [{directory, {priv_dir, ?WEBAPP, [<<"doc">>]}},
		{mimetypes, {fun mimetypes:path_to_mimes/2, default}}]},
	    {["/get_jqgrid_data/[...]"], get_jqgrid_data, []},
	    %% {["get_jqgrid_data", '*'], get_jqgrid_data, []},
	    {["/get_graph_nodes/[...]"], get_graph_nodes, []},
	    {["/websocket"], ws_handler, []},
	    {'_', nitrogen_cowboy, []}
    ]}]).
