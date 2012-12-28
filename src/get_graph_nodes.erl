-module(get_graph_nodes).

-export([init/1, content_types_provided/2, to_json/2, generate_etag/2]).

-include_lib("webmachine/include/webmachine.hrl").
-include_lib("ec_master/include/record_definitions.hrl").

init([]) -> {ok, undefined}.

content_types_provided(ReqData, Context) ->
    {[{"application/json", to_json}], ReqData, Context}.

to_json(ReqData, Context) ->
    %% PathInfo = wrq:path_info(ReqData),
    Date = wrq:get_qs_value("date", ReqData),
    io:format('pathinfo = ~p', [Date]),
    %% {ok, Date} = dict:find(date, PathInfo),
    io:format("Run Select ~p ~n", [Date]),
    G = ec_db:get_node(list_to_atom(Date)),
    %% get all vertixes
    Vs = mdigraph:vertices(G),
    VertexInfo = [mdigraph:vertex(G, V) || V <- Vs],
    P = ec_counter:start_counter(1),
    %% [[{data, ec_counter:next(P)}, binary_to_list(N), "/web_page3/" ++ RunDate ++ "/" ++ binary_to_list(N),
    %%   RunDate, atom_to_list(L#fsm_state.state),
    %%   format_time(L#fsm_state.start_time, L#fsm_state.date_offset),
    %%   format_time(L#fsm_state.end_time, L#fsm_state.date_offset),
    %%   get_parent_names(L, RunDate)
    %% ] || {N, L} <- VertexInfo, L =/= [], L#fsm_state.type =/= timer].

    Rows = [{struct, [{<<"id">>, ec_counter:next(P)}, {<<"cell">>, [make_link(N, Date), list_to_binary(Date),
            L#fsm_state.state,
	    list_to_binary(index_fns:format_time(L#fsm_state.start_time, L#fsm_state.date_offset)),
	    list_to_binary(index_fns:format_time(L#fsm_state.end_time, L#fsm_state.date_offset))]}]}
	    || {N, L} <- VertexInfo, L =/= [], L#fsm_state.type =/= timer],

    Data = {struct, [{<<"total">>, 1},
    		     {<<"page">>, 1},
    		     {<<"records">>, length(Rows)},
		     {<<"rows">>, Rows}]},

    %% Data = {struct, [{<<"total">>, 1},
    %% 		     {<<"page">>, 1},
    %% 		     {<<"records">>, 2},
    %% 		     {<<"rows">>, [{struct, [{<<"id">>, 1}, {<<"cell">>, [<<"1">>, <<"cell11">>, <<"values11">>]}]},
    %% 				   {struct, [{<<"id">>, 2}, {<<"cell">>, [<<"2">>, <<"cell15">>, <<"values22">>]}]}
    %% 				  ]}
    %% 		    ]},
    Data1 = iolist_to_binary(mochijson2:encode(Data)),
    {Data1, ReqData, Context}.

make_link(N, Date) ->
    N1 = binary_to_list(N),
    list_to_binary("<a href='/web_page3/" ++ Date ++ "/" ++ N1 ++ "'>" ++ N1 ++ "</a>").

generate_etag(ReqData, Context) -> {wrq:raw_path(ReqData), ReqData, Context}.
