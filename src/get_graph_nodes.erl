-module(get_graph_nodes).

-export([init/1, content_types_provided/2, to_json/2, generate_etag/2]).

-include_lib("webmachine/include/webmachine.hrl").
-include_lib("ec_master/include/record_definitions.hrl").

init([]) -> {ok, undefined}.

content_types_provided(ReqData, Context) ->
    {[{"application/json", to_json}], ReqData, Context}.

to_json(ReqData, Context) ->
    Date = wrq:get_qs_value("date", ReqData),
    %% io:format('pathinfo = ~p', [Date]),
    %% io:format("Run Select ~p ~n", [Date]),
    G = ec_db:get_node(list_to_atom(Date)),
    %% get all vertixes
    Vs = mdigraph:vertices(G),
    VertexInfo = [mdigraph:vertex(G, V) || V <- Vs],
    P = ec_counter:start_counter(1),
    %% format rows
    Rows = [{struct, [{<<"id">>, ec_counter:next(P)},
		      {<<"cell">>, [make_link(N, Date),
				    list_to_binary(Date),
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
    {Data1, ReqData, Context}.

make_link(N, Date) ->
    N1 = binary_to_list(N),
    list_to_binary("<a href='/web_page3/" ++ Date ++ "/" ++ N1 ++ "'>" ++ N1 ++ "</a>").

generate_etag(ReqData, Context) -> {wrq:raw_path(ReqData), ReqData, Context}.
