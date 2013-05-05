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
    %% get params from the query string
    {Vals, Req1} = cowboy_req:qs_vals(Req),
    Page = list_to_integer(binary_to_list(proplists:get_value(<<"page">>, Vals))),
    RowsPerPage = list_to_integer(binary_to_list(proplists:get_value(<<"rows">>, Vals))),
    Date = proplists:get_value(<<"date">>, Vals),

    try
	G = ec_db:get_node(Date),
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
	%% how many pages?
	Total = case length(Rows) > 0 of
	    true -> ec_util:ceiling(length(Rows) / RowsPerPage);
	    false -> 0
	end,

	%% add row information
	Data = {struct, [
	    {<<"page">>, Page},
	    {<<"total">>, Total},
	    {<<"records">>, length(Rows)},
	    {<<"rows">>, lists:nthtail(Page * RowsPerPage - RowsPerPage, Rows)}]},
	%% form json
	{iolist_to_binary(mochijson2:encode(Data)), Req1, State}
    catch
	throw:{error, Reason} -> {<<>>, Req1, State}
    end.

make_link(N, Date) when is_binary(Date)-> make_link(N, binary_to_list(Date));
make_link(N, Date) ->
    N1 = binary_to_list(N),
    list_to_binary("<a href='/web_page3/" ++ Date ++ "/" ++ N1 ++ "'" ++ "class=wfid_deps_link" ++ ">" ++ N1 ++ "</a>").

get_parent_names(L, Date) when is_binary(Date)-> get_parent_names(L, binary_to_list(Date));
get_parent_names(L, Date) ->
    P = ["<a href='/web_page3/" ++ Date ++ "/" ++ binary_to_list(N) ++ "'" ++ "class=wfid_deps_link" ++ ">"
	 ++ binary_to_list(N) ++ "</a>"
	 || {N, _D} <- dict:to_list(L#fsm_state.parents), N =/= ?DEFAULT_TIMER_NAME],
    list_to_binary(string:join(P, " ")).
