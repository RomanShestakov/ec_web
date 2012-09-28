-module(index_fns).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").
-include_lib("ec_master/include/record_definitions.hrl").

get_schedule_rundates() ->
    S = ec_db:get_names(), %ec_cli:get_schedulers(),
    [#option { text = atom_to_list(Date), value = Date } || Date <- S].

select(RunDate, RegExpr) ->
    io:format("Run Select ~p ~p~n", [RunDate, RegExpr]),
    G = ec_db:get_node(list_to_atom(RunDate)),
    %% get all vertixes
    Vs = mdigraph:vertices(G),
    VertexInfo = [mdigraph:vertex(G, V) || V <- Vs],
    P = ec_counter:start_counter(1),
    [[{data, ec_counter:next(P)}, binary_to_list(N), "/web_page3/" ++ RunDate ++ "/" ++ binary_to_list(N),
      RunDate, atom_to_list(L#fsm_state.state),  
      format_time(L#fsm_state.start_time, L#fsm_state.date_offset),
      format_time(L#fsm_state.end_time, L#fsm_state.date_offset),
      get_parent_names(L, RunDate)
    ] || {N, L} <- VertexInfo, L =/= [], L#fsm_state.type =/= timer].


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
    %%io:format("Got SVG Data ~p ~p ~n", [RunDate, D]),
    %%file:write_file("graph55.svg", D),
    %%D.
