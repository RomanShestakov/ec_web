-module(index_fns).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").
-include_lib("ec_master/include/record_definitions.hrl").

get_schedule_rundates() ->
    S = ec_cli:get_schedulers(),
    [#option { text = atom_to_list(Date), value = Date } || {Date, _} <- S].

select(RunDate, RegExpr) ->
    io:format("Run Select ~p ~p~n", [RunDate, RegExpr]),
    S = ec_db:select(list_to_atom(RunDate), RegExpr),
    P = ec_counter:start_counter(1),
    [[{data, ec_counter:next(P)}, R#job.name, atom_to_list(R#job.run_date), atom_to_list(R#job.state)] || R <- S ].

clean(RunDate, Name) ->
    io:format("Run Clean ~p ~p~n", [RunDate, Name]),
    ec_cli:clean_process(list_to_atom(RunDate), Name).

get_svg(RunDate) ->
    G = ec_cli:get_graph(list_to_atom(RunDate)),
    D = digraphdot:get_svg(G),
    %%io:format("Got SVG Data ~p ~p ~n", [RunDate, D]),
    %%file:write_file("graph55.svg", D),
    D.
