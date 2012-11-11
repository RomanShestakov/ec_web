%% -*- mode: nitrogen -*-
-module(web_sup).
-behaviour(supervisor).
-export([
	 start_link/0,
	 init/1
	]).

-include_lib("ec_web/include/ec_web.hrl").
-include_lib("webmachine/include/webmachine.hrl").
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
    {ok, BindAddress} = application:get_env(bind_address),
    {ok, Port} = application:get_env(port),
    {ok, ServerName} = application:get_env(server_name),
    {ok, MasterName} = application:get_env(master_name),

    %% init db replication
    case db_api:init_db(MasterName) of
	ok ->
	    io:format("succesfully replicated mnesia node ~p ~n", [MasterName]);
	{error, Reason} ->
	    io:format("faild for to replicate mnesia node: ~p ~n", [MasterName]),
	    exit(Reason)
    end,

    io:format("Starting Mochiweb (~s) on ~s:~p, master ~p~n", [ServerName, BindAddress, Port, MasterName]),

    % Start Mochiweb...
    Options = [
        {ip, BindAddress},
        {port, Port},
        {dispatch, dispatch()}
    ],
    webmachine_mochiweb:start(Options),
    {ok, { {one_for_one, 5, 10}, []} }.

dispatch() ->
    [
     %% Static content handlers...
     {["css", '*'], static_resource, [{root, "./priv/static/css"}]},
     {["images", '*'], static_resource, [{root, "./priv/static/images"}]},
     {["nitrogen", '*'], static_resource, [{root, "./priv/static/nitrogen"}]},

     %% Add routes to your modules here. The last entry makes the
     %% system use the dynamic_route_handler, which determines the
     %% module name based on the path. It's a good way to get
     %% started, but you'll likely want to remove it after you have
     %% added a few routes.
     %%
     %% p.s. - Remember that you will need to RESTART THE VM for
     %%        dispatch changes to take effect!!!
     %%
     %% {["path","to","module1",'*'], ?MODULE, module_name_1}
     %% {["path","to","module2",'*'], ?MODULE, module_name_2}
     %% {["path","to","module3",'*'], ?MODULE, module_name_3}
     {["/"], nitrogen_webmachine, index},
     {["/web_page1", "*"], nitrogen_webmachine, web_page1},
     {["/web_page3"], nitrogen_webmachine, web_page3},
     %% {["/web_samples_tabs1"], nitrogen_webmachine, web_samples_tabs1},
     {["/web_page4"], nitrogen_webmachine, web_page4},
     {["/login"], nitrogen_webmachine, web_users_login},
     {['*'], nitrogen_webmachine, dynamic_route_handler}
    ].

