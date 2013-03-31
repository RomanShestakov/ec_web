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

-define(APP, ec_web).

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
    {ok, MasterName} = application:get_env(master_name),

    %% init db replication
    case db_api:init_db(MasterName) of
	ok ->
	    io:format("succesfully replicated mnesia node ~p ~n", [MasterName]);
	{error, Reason} ->
	    io:format("faild for to replicate mnesia node: ~p ~n", [MasterName]),
	    exit(Reason)
    end,

    io:format("Starting Cowboy Server ~p ~n", [Port]),
    {ok, _} = cowboy:start_http(http, 100,
				[{port, Port}],
				[{env, [{dispatch, dispatch_rules()}]}]),
    {ok, {{one_for_one, 5, 10}, []}}.

dispatch_rules() ->
    cowboy_router:compile(
	%% {Host, list({Path, Handler, Opts})}
	[{'_', [
	    {["/favicon.ico"], cowboy_static, [{directory, {priv_dir, ?APP, [<<"static">>]}}, {file, "images/favicon.ico"}]},
	    {["/content/[...]"], cowboy_static, [{directory, {priv_dir, ?APP, [<<"content">>]}},
		{mimetypes, {fun mimetypes:path_to_mimes/2, default}}]},
	    {["/static/[...]"], cowboy_static, [{directory, {priv_dir, ?APP, [<<"static">>]}},
		{mimetypes, {fun mimetypes:path_to_mimes/2, default}}]},
	    {["/[:page/:date/:job/]plugins/[...]"], cowboy_static, [{directory, {priv_dir, ?APP, [<<"plugins">>]}},
		{mimetypes, {fun mimetypes:path_to_mimes/2, default}}]},
	    {["/doc/[...]"], cowboy_static, [{directory, {priv_dir, ?APP, [<<"doc">>]}},
		{mimetypes, {fun mimetypes:path_to_mimes/2, default}}]},
	    {["/get_jqgrid_data/[...]"], get_jqgrid_data, []},
	    %% {["get_jqgrid_data", '*'], get_jqgrid_data, []},
	    {["/get_graph_nodes/[...]"], get_graph_nodes, []},
	    {["/websocket"], ws_handler, []},
	    {'_', nitrogen_cowboy, []}
    ]}]).
