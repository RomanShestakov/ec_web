-module(get_graph_nodes).

%% -export([init/1, content_types_provided/2, to_json/2, generate_etag/2]).
-include_lib("ec_master/include/record_definitions.hrl").

-export([init/3, content_types_provided/2, to_json/2]).

init(_Transport, _Req, []) ->
    {upgrade, protocol, cowboy_rest}.

content_types_provided(Req, State) ->
    {[{<<"application/json">>, to_json}], Req, State}.

%% content_types_provided(ReqData, Context) ->
%%     {[{"application/json", to_json}], ReqData, Context}.
to_json(Req, State) ->

    io:format('INFO = ~p ~n', [Req]),

    {Date, Req1} = cowboy_req:qs_val(<<"date">>, Req),
%    io:format('pathinfo = ~p', [Date]),
    io:format("** Date ~p ~n", [Date]),
    Date2 = binary_to_list(Date),
    G = ec_db:get_node(list_to_atom(Date2)),
    %% get all vertixes
    Vs = mdigraph:vertices(G),
    VertexInfo = [mdigraph:vertex(G, V) || V <- Vs],
    P = ec_counter:start_counter(1),
    %% format rows
    Rows = [{struct, [{<<"id">>, ec_counter:next(P)},
		      {<<"cell">>, [make_link(N, Date2),
				    list_to_binary(Date2),
				    L#fsm_state.state,
				    list_to_binary(index_fns:format_time(L#fsm_state.start_time, L#fsm_state.date_offset)),
				    list_to_binary(index_fns:format_time(L#fsm_state.end_time, L#fsm_state.date_offset))]}]}
	    || {N, L} <- VertexInfo, L =/= [], L#fsm_state.type =/= timer],
    %% add row information
    Data = {struct, [{<<"total">>, 1},
    		     {<<"page">>, 1},
    		     {<<"records">>, length(Rows)},
		     {<<"rows">>, Rows}]},
    %% form json
    Data1 = iolist_to_binary(mochijson2:encode(Data)),
    {Data1, Req1, State}.

make_link(N, Date) ->
    N1 = binary_to_list(N),
    list_to_binary("<a href='/web_page3/" ++ Date ++ "/" ++ N1 ++ "'>" ++ N1 ++ "</a>").

%% generate_etag(ReqData, Context) -> {wrq:raw_path(ReqData), ReqData, Context}.
