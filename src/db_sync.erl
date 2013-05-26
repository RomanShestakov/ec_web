%%%-------------------------------------------------------------------
%%% @author Roman Shestakov <>
%%% @copyright (C) 2013, Roman Shestakov
%%% @doc
%%%
%%% @end
%%% Created :  4 May 2013 by Roman Shestakov <>
%%%-------------------------------------------------------------------
-module(db_sync).

-behaviour(gen_fsm).

%% API
-export([start_link/0]).

%% gen_fsm callbacks
-export([init/1, state_name/2, state_name/3, handle_event/3,
	 handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).

-export([find_resource/2,
	 sync_resource/2,
	 keepalive_resource/2]).

-define(SERVER, ?MODULE).
-define(MASTER, ec_master).

-include_lib("ec_master/include/record_definitions.hrl").

-record(state, {live_master}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Creates a gen_fsm process which calls Module:init/1 to
%% initialize. To ensure a synchronized start-up procedure, this
%% function does not return until Module:init/1 has returned.
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_fsm:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_fsm callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a gen_fsm is started using gen_fsm:start/[3,4] or
%% gen_fsm:start_link/[3,4], this function is called by the new
%% process to initialize.
%%
%% @spec init(Args) -> {ok, StateName, State} |
%%                     {ok, StateName, State, Timeout} |
%%                     ignore |
%%                     {stop, StopReason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    process_flag(trap_exit, true),
    lager:info("Starting db_sync to replicate resource ~p ~n", [?MASTER]),
    %% start fresh mnesia
    init_db(),
    %% announce that we want to know about ec_master resource
    resource_discovery:add_target_resource_types([?MASTER]),
    %% scale time to milliseconds
    gen_fsm:send_event_after(10 * 1000, ?EVENT_TIME_IS_UP),
    {ok, find_resource, #state{}}.

find_resource(?EVENT_TIME_IS_UP, State) ->
    %% check if we have a resource of the given type somewhere in the claster
    MasterNode = resource_discovery:get_resources(?MASTER),
    %% lager:info("db_sync checking resource: ~p, found: ~p", [?MASTER, MasterNode]),
    case MasterNode of
	[] ->
	    %% no resources found, so go back to waiting
	    gen_fsm:send_event_after(10 * 1000, ?EVENT_TIME_IS_UP),
	    {next_state, find_resource, State};
	Node ->
	    gen_fsm:send_event(?SERVER, {sync, hd(Node)}),
	    {next_state, sync_resource, State}
    end.

sync_resource({sync, Node}, State) ->
    lager:info("db_sync: replicating mnesia from node: ~p", [Node]),
    %% init db replication
    case add_node(Node) of
    	ok ->
    	    lager:info("succesfully replicated mnesia node ~p ~n", [Node]),
	    gen_fsm:send_event_after(30 * 1000, ?EVENT_TIME_IS_UP),
	    {next_state, keepalive_resource, State};
    	{error, Reason} ->
    	    lager:error("failed for to replicate mnesia node: ~p ~n", [Node]),
	    gen_fsm:send_event_after(10 * 1000, ?EVENT_TIME_IS_UP),
	    {next_state, find_resource, State}
    end.

keepalive_resource(?EVENT_TIME_IS_UP, State) ->
    lager:info("db_sync keepalive"),
    NofResource = resource_discovery:get_num_resource(?MASTER),
    case NofResource of
    	0 ->
    	    lager:error("db_sync: master node is lost, cleaning schema ~n"),
	    init_db(),
	    gen_fsm:send_event_after(10 * 1000, ?EVENT_TIME_IS_UP),
	    {next_state, find_resource, State};
	Other ->
	    lager:info("db_sync: master is alive ~n"),
	    gen_fsm:send_event_after(30 * 1000, ?EVENT_TIME_IS_UP),
	    {next_state, keepalive_resource, State}
    end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% There should be one instance of this function for each possible
%% state name. Whenever a gen_fsm receives an event sent using
%% gen_fsm:send_event/2, the instance of this function with the same
%% name as the current state name StateName is called to handle
%% the event. It is also called if a timeout occurs.
%%
%% @spec state_name(Event, State) ->
%%                   {next_state, NextStateName, NextState} |
%%                   {next_state, NextStateName, NextState, Timeout} |
%%                   {stop, Reason, NewState}
%% @end
%%--------------------------------------------------------------------
state_name(_Event, State) ->
    {next_state, state_name, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% There should be one instance of this function for each possible
%% state name. Whenever a gen_fsm receives an event sent using
%% gen_fsm:sync_send_event/[2,3], the instance of this function with
%% the same name as the current state name StateName is called to
%% handle the event.
%%
%% @spec state_name(Event, From, State) ->
%%                   {next_state, NextStateName, NextState} |
%%                   {next_state, NextStateName, NextState, Timeout} |
%%                   {reply, Reply, NextStateName, NextState} |
%%                   {reply, Reply, NextStateName, NextState, Timeout} |
%%                   {stop, Reason, NewState} |
%%                   {stop, Reason, Reply, NewState}
%% @end
%%--------------------------------------------------------------------
state_name(_Event, _From, State) ->
    Reply = ok,
    {reply, Reply, state_name, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a gen_fsm receives an event sent using
%% gen_fsm:send_all_state_event/2, this function is called to handle
%% the event.
%%
%% @spec handle_event(Event, StateName, State) ->
%%                   {next_state, NextStateName, NextState} |
%%                   {next_state, NextStateName, NextState, Timeout} |
%%                   {stop, Reason, NewState}
%% @end
%%--------------------------------------------------------------------
handle_event(_Event, StateName, State) ->
    {next_state, StateName, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a gen_fsm receives an event sent using
%% gen_fsm:sync_send_all_state_event/[2,3], this function is called
%% to handle the event.
%%
%% @spec handle_sync_event(Event, From, StateName, State) ->
%%                   {next_state, NextStateName, NextState} |
%%                   {next_state, NextStateName, NextState, Timeout} |
%%                   {reply, Reply, NextStateName, NextState} |
%%                   {reply, Reply, NextStateName, NextState, Timeout} |
%%                   {stop, Reason, NewState} |
%%                   {stop, Reason, Reply, NewState}
%% @end
%%--------------------------------------------------------------------
handle_sync_event(_Event, _From, StateName, State) ->
    Reply = ok,
    {reply, Reply, StateName, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_fsm when it receives any
%% message other than a synchronous or asynchronous event
%% (or a system message).
%%
%% @spec handle_info(Info,StateName,State)->
%%                   {next_state, NextStateName, NextState} |
%%                   {next_state, NextStateName, NextState, Timeout} |
%%                   {stop, Reason, NewState}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, StateName, State) ->
    {next_state, StateName, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_fsm when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_fsm terminates with
%% Reason. The return value is ignored.
%%
%% @spec terminate(Reason, StateName, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _StateName, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, StateName, State, Extra) ->
%%                   {ok, StateName, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.


%%%===================================================================
%%% Internal functions
%%%===================================================================

init_db() ->
    mnesia:stop(),
    mnesia:delete_schema([node()]),
    mnesia:start().

add_node(Node) ->
    lager:info("Replicating mnesia node from(~s) ~n", [Node]),
    case mnesia:change_config(extra_db_nodes, [Node] ) of
	{ok, [_Node]} ->
	    mnesia:add_table_copy(schema, node(), ram_copies),
	    mnesia:add_table_copy(job, node(), ram_copies),
	    Tables = mnesia:system_info(tables),
	    mnesia:wait_for_tables(Tables, 5000),
	    ok;
	 Reason ->
	    {err, Reason}
    end.
