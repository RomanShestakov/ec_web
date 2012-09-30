%% -*- mode: nitrogen -*-
-module(web_sup).
-behaviour(supervisor).
-export([
    start_link/0,
    init/1,
    loop/1
]).

-include_lib("ec_web/include/ec_web.hrl").

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

routes() ->
    [
        { "/page1", web_page1 },
	{ "/web_page3", web_page3 },
	{ "/web_page4", web_page4 },
	{ "/login", web_users_login },
        { "/", web_index },
        { "/nitrogen", static_file },
        { "/css", static_file },
        { "/images", static_file },
        { "/js", static_file }
    ].

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    {ok, BindAddress} = application:get_env(bind_address),
    {ok, Port} = application:get_env(port),
    {ok, ServerName} = application:get_env(server_name),
    {ok, MasterName} = application:get_env(master_name),
    DocRoot = web_common:docroot(),
    Templates = web_common:templates(),

    io:format("Starting Mochiweb Server (~s) on ~s:~p, root: '~s' templates: '~s' master ~p~n",
	[ServerName, BindAddress, Port, DocRoot, Templates, MasterName]),

    % Start Mochiweb...
    Options = [
        {name, ServerName},
        {ip, BindAddress},
        {port, Port},
        {loop, fun ?MODULE:loop/1}
    ],
    mochiweb_http:start(Options),

    %% init db replication
    case init_db(MasterName) of
	ok ->
	    io:format("succesfully replicated mnesia node ~p ~n", [MasterName]);
	{error, Reason} ->
	    io:format("faild for to replicate mnesia node: ~p ~n", [MasterName]),
	    exit(Reason)
    end,
    {ok, { {one_for_one, 5, 10}, []} }.

loop(Req) ->
    DocRoot = web_common:docroot(),
    RequestBridge = simple_bridge:make_request(mochiweb_request_bridge, {Req, DocRoot}),
    ResponseBridge = simple_bridge:make_response(mochiweb_response_bridge, {Req, DocRoot}),
    nitrogen:init_request(RequestBridge, ResponseBridge),

    %% Uncomment for basic authentication...
    %% nitrogen:handler(http_basic_auth_security_handler, basic_auth_callback_mod),

    %% Use a static handler for routing instead of the default dynamic handler.
    nitrogen:handler(named_route_handler, routes()),
    nitrogen:run().


init_db(MasterNode) ->
    mnesia:stop(),
    mnesia:delete_schema([node()]),
    mnesia:start(),
    dynamic_db_init(MasterNode).


dynamic_db_init(MasterNode) ->
    add_extra_node(MasterNode).

add_extra_node(MasterNode) ->
    io:format("Replicating mnesia node from(~s) ~n", [MasterNode]),
    case mnesia:change_config(extra_db_nodes, [MasterNode] ) of
	{ok, [_Node]} ->
	    mnesia:add_table_copy(schema, node(), ram_copies),
	    mnesia:add_table_copy(job, node(), ram_copies),
	    Tables = mnesia:system_info(tables),
	    mnesia:wait_for_tables(Tables, 5000),
	    ok;
	 Reason ->
	    {err, Reason}
    end.

