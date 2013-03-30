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
    {Date, Req1} = cowboy_req:qs_val(<<"date">>, Req),
    Date2 = list_to_atom(binary_to_list(Date)),
    try
	G = ec_db:get_node(Date2),
	%% get all vertixes
	Vs = mdigraph:vertices(G),
	VertexInfo = lists:sort(fun({N1, _}, {N2, _}) -> N1 < N2 end, [mdigraph:vertex(G, V) || V <- Vs]),
	P = ec_counter:start_counter(1),
	%% format rows
	Rows = [{struct, [{<<"id">>, ec_counter:next(P)},
			  {<<"cell">>, [make_link(N, Date),
					hd(binary:split(N, <<"~">>)),
					Date,
					L#fsm_state.state,
					list_to_binary(index_fns:format_time(L#fsm_state.start_time, L#fsm_state.date_offset)),
					list_to_binary(index_fns:format_time(L#fsm_state.end_time, L#fsm_state.date_offset)),
					get_parent_names(L, Date)
				       ]}]}
		|| {N, L} <- VertexInfo, L =/= [], L#fsm_state.type =/= timer],
	%% add row information
	Data = {struct, [{<<"total">>, 1},
			 {<<"page">>, 1},
			 {<<"records">>, length(Rows)},
			 {<<"rows">>, Rows}]},
	%% form json
	Data1 = iolist_to_binary(mochijson2:encode(Data)),
	{Data1, Req1, State}
    catch
	throw:{error, Reason} -> {<<>>, Req1, State}
    end.

make_link(N, Date) when is_binary(Date)-> make_link(N, binary_to_list(Date));
make_link(N, Date) ->
    N1 = binary_to_list(N),
    list_to_binary("<a href='/web_page3/" ++ Date ++ "/" ++ N1 ++ "'>" ++ N1 ++ "</a>").

get_parent_names(L, Date) when is_binary(Date)-> get_parent_names(L, binary_to_list(Date));
get_parent_names(L, Date) ->
    P = ["<a href='/web_page3/" ++ Date ++ "/" ++ binary_to_list(N) ++ "'>" ++ binary_to_list(N) ++ "</a>"
	 || {N, _D} <- dict:to_list(L#fsm_state.parents), N =/= ?DEFAULT_TIMER_NAME],
    list_to_binary(string:join(P, " ")).
