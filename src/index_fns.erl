-module(index_fns).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").
-include_lib("ec_master/include/record_definitions.hrl").
-include_lib("ec_web/include/ec_web.hrl").

-export([get_websocket_name/1]).

get_schedule_rundates() ->
    try
	S = lists:sort(ec_db:get_names()),
	[#option{text = atom_to_list(Date), value = atom_to_list(Date)} || Date <- S]
    catch
	throw:_Reason -> [#option { text = "", value = "" }]
    end.

select(RunDate, RegExpr) when is_integer(RunDate) ->
    select(integer_to_list(RunDate), RegExpr);
select(RunDate, RegExpr) when is_atom(RunDate) ->
    select(atom_to_list(RunDate), RegExpr);
select(RunDate, RegExpr) ->
    io:format("Run Select ~p ~p~n", [RunDate, RegExpr]),
    G = ec_db:get_node(list_to_atom(RunDate)),
    %% get all vertixes
    Vs = mdigraph:vertices(G),
    VertexInfo = [mdigraph:vertex(G, V) || V <- Vs],
    P = ec_counter:start(1),
    Data = [[{data, ec_counter:next(P)}, binary_to_list(N), "/web_page3/" ++ RunDate ++ "/" ++ binary_to_list(N),
	     RunDate, atom_to_list(L#fsm_state.state),
	     format_time(L#fsm_state.start_time, L#fsm_state.date_offset),
	     format_time(L#fsm_state.end_time, L#fsm_state.date_offset),
	     get_parent_names(L, RunDate)
	    ] || {N, L} <- VertexInfo, L =/= [], L#fsm_state.type =/= timer],
    ec_counter:stop(P),
    Data.


format_time(Time, Offset) ->
    case ec_time_fns:time_to_string(Time, Offset) of
	{error, incorrect_time_of_offset} -> "";
	TimeStr -> TimeStr
    end.


get_parent_names(P, RunDate) ->
    [[binary_to_list(N), "/web_page3/" ++ RunDate ++ "/" ++ binary_to_list(N)] || {N, _D} <- dict:to_list(P#fsm_state.parents), N =/= ?DEFAULT_TIMER_NAME].

select_node({Name, RunDate}) ->
    io:format("Run Select ~p ~p~n", [RunDate, Name]),
    G = ec_db:get_node(list_to_atom(RunDate)),
    mdigraph:vertex(G, list_to_binary(Name)).

clean(RunDate, Name) ->
    io:format("Run Clean ~p ~p~n", [RunDate, Name]),
    ec_cli:clean_process(list_to_atom(RunDate), Name).

get_svg(RunDate) ->
    G = ec_db:get_node(list_to_atom(RunDate)),
    ec_digraphdot:get_svg(G).


%%--------------------------------------------------------------------
%% @doc
%%  returns a domain name for a master host
%% @end
%%--------------------------------------------------------------------
-spec get_master_node_name(atom()) -> {error, name_unknown} | string().
get_master_node_name(MasterResourceName) ->
    case resource_discovery:get_resources(MasterResourceName) of
	[] -> {error, name_unknown};
	Other ->
	    NodeName = hd(Other),
	    string:join(tl(string:tokens(atom_to_list(NodeName), "@")),"")
    end.

%%--------------------------------------------------------------------
%% @doc
%% get websocket address name of the master node
%% @end
%%--------------------------------------------------------------------
-spec get_websocket_name(string()) -> {error, cant_find_node_for_resource} | string().
get_websocket_name(Date) ->
    case get_master_node_name(ec_master) of
	{error, _} -> {error, cant_find_node_for_resource};
	Name ->
	    {ok, Port} = application:get_env(?WEBAPP, port),
	    {ok, "ws://" ++ Name ++ ":" ++ integer_to_list(Port) ++ "/websocket/?date=" ++ Date}
    end.
