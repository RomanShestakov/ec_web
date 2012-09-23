%% -*- mode: nitrogen -*-
-module(web_sup).
-behaviour(supervisor).
-export([
    start_link/0,
    init/1,
    loop/1
]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

routes() ->
    [
        { "/page1", web_page1 },
	{ "/web_page3", web_page3 },
	{ "/web_page4", web_page4 },
	{ "/login", web_users_login },
        { "/", web_index },
	%%{ "/page2", web_page2 },
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
    %% Start the Process Registry...
    application:start(nprocreg),

    %% Start Mochiweb...
    application:load(mochiweb),
    {ok, BindAddress} = application:get_env(bind_address),
    {ok, Port} = application:get_env(port),
    {ok, ServerName} = application:get_env(server_name),
    {ok, MasterName} = application:get_env(master_name),
    DocRoot = docroot(),

    io:format("Starting Mochiweb Server (~s) on ~s:~p, root: '~s'~n", [ServerName, BindAddress, Port, DocRoot]),

    % Start Mochiweb...
    Options = [
        {name, ServerName},
        {ip, BindAddress},
        {port, Port},
        {loop, fun ?MODULE:loop/1}
    ],
    mochiweb_http:start(Options),

    %% start ec_cli
    application:start(ec_cli),

    %{ok, LL}=ec_cli:config(MasterName),

    %io:format("configure ec_cli for master: ~p, config ~p~n", [MasterName, LL]),
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
    DocRoot = docroot(),
    RequestBridge = simple_bridge:make_request(mochiweb_request_bridge, {Req, DocRoot}),
    ResponseBridge = simple_bridge:make_response(mochiweb_response_bridge, {Req, DocRoot}),
    nitrogen:init_request(RequestBridge, ResponseBridge),

    %% Uncomment for basic authentication...
    %% nitrogen:handler(http_basic_auth_security_handler, basic_auth_callback_mod),

    %% Use a static handler for routing instead of the default dynamic handler.
    nitrogen:handler(named_route_handler, routes()),

    nitrogen:run().

docroot() ->
    code:priv_dir(view) ++ "/static".

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

