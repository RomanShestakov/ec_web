-module(ws_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

%% -define(DATA, <<"digraph G {subgraph cluster_0 {style=filled;color=lightgrey; node [style=filled,color=yellow]; a0 -> a1 -> a2 -> a3;label = \"process #1\";} subgraph cluster_1 {node [style=filled]; b0 -> b1 -> b2 -> b3; label = \"process #2\";color=red} start -> a0; start -> b0; a1 -> b3; b2 -> a3; a3 -> a0; a3 -> end; b3 -> end; start [shape=Mdiamond]; end [shape=Msquare];}">>).

%% -define(DATA1, <<"digraph G {subgraph cluster_0 {style=filled;color=lightgrey; node [style=filled,color=blue]; a0 -> a1 -> a2 -> a3 -> a4;label = \"process #1\";} subgraph cluster_1 {node [style=filled]; b0 -> b1 -> b2 -> b3 -> b4; label = \"process #2\";color=red} start -> a0; start -> b0; a1 -> b3; b2 -> a3; a3 -> a0; a3 -> a4; a4 -> end; b3 -> end; start [shape=Mdiamond]; end [shape=Msquare];}">>).

%% -define(DATA2, <<"digraph G {subgraph cluster_0 {style=filled;color=lightgrey; node [style=filled,color=red]; a0 -> a1 -> a2 -> a3 -> a4;label = \"process #1\";} subgraph cluster_1 {node [style=filled]; b0 -> b1 -> b2 -> b3 -> b4; label = \"process #2\";color=red} start -> a0; start -> b0; a1 -> b3; b2 -> a3; a3 -> a0; a3 -> a4; a4 -> end; b3 -> end; start [shape=Mdiamond]; end [shape=Msquare];}">>).

%% -define(G, [?DATA, ?DATA1, ?DATA2]).
%% -define(DATE, "20121227").

-record(state, {rundate}).


init({tcp, http}, _Req, _Opts) ->
    {upgrade, protocol, cowboy_websocket}.

websocket_init(_TransportName, Req, _Opts) ->
    %% io:format(" rendate :~p ~n", [Req]),
    {Rundate, Req1} = cowboy_req:qs_val(<<"date">>, Req),
    %% io:format(" rendate :~p ~n", [Rundate]),
    %% io:format(" req :~p ~n", [Req]),
    Rundate1 = list_to_atom(binary_to_list(Rundate)),
    erlang:start_timer(1500, self(), ec_digraphdot:generate_dot(ec_db:get_node(Rundate1))),
    {ok, Req1, #state{rundate = Rundate1}}.

websocket_handle({text, Msg}, Req, State) ->
    {reply, {text, << "", Msg/binary >>}, Req, State};
websocket_handle(_Data, Req, State) ->
    {ok, Req, State}.

websocket_info({timeout, _Ref, Msg}, Req, #state{rundate = Rundate} = State) ->
    io:format(" rendate1 :~p ~n", [Rundate]),
    erlang:start_timer(1500, self(), ec_digraphdot:generate_dot(ec_db:get_node(Rundate))),
    {reply, {text, Msg}, Req, State};
websocket_info(_Info, Req, State) ->
    {ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
    ok.
