-module (index).
-compile(export_all).

-include_lib ("nitrogen_core/include/wf.hrl").
-include_lib("nitrogen_elements/include/nitrogen_elements.hrl").
-include_lib("ec_web/include/elements.hrl").

-define(EVENT_TABSSHOW, 'tabsshow').

%% main() ->
%%     case wf:role(admin) of
%%     	true ->
%% 	    web_common:assert_path( "grid.html" );
%% 	false ->
%% 	    wf:redirect_to_login("login")
%%     end.

main() ->
    web_common:assert_path( "grid.html" ).

title() -> "Nitrogen Web Framework for Erlang".

layout() ->
    wf:wire(tabs, #tab_event_on{event = ?EVENT_TABSSHOW}),
    wf:wire(#api{name=history_back, tag=f1}),

    RunDate1 = "20121227",
%%wf:q(dropdown1),

    Data = case wf:q(date) of
	undefined -> [];
	RunDate -> index_fns:select(RunDate, "")
    end,

    SelectedTab = case wf:q(tab) of
	undefined -> 0;
	Tab -> Tab
    end,

    Url = list_to_binary("get_graph_nodes/?date=" ++ RunDate1),
    ?PRINT({run_date, Url}),

    #container_12 { body=[
	%% show dropbox with Rundates
	#grid_12 { body = #panel{body = [available_rundates()]}},

	%% show query box
	#grid_12 { body = #table{rows=[
	    #tablerow{class=row, cells=[
		#tablecell{class=col, body=#button{id=btn_go, text="Go", postback=go}},
		#tablecell{class=col, body=#button{id=btn_graph, text="Graph", postback=graph}},
		#tablecell{class=col, body=#button{id=btn_logout, text="Logout", postback = logout}}
	    ]}
	]}},
	%% put empty panel to output process names
	#grid_12 { body =
	    #tabs{
		id = tabs,
		options = [{selected, SelectedTab}],
		style="margin:0;padding: 0 0 0 0;",
		tabs = [
		    #tab{title="Tab 1", body=[#panel{id=pnl_processes, class=mojorcontainer, body=[
			#process_table{id=tbl_process, data = Data}]}]},
		    #tab{title="Tab 2",
			style="margin:0; padding: 0 0 0 0;",
			body=[
			    #jqgrid{
				id = jqgrid,
				options=[
				    {url, Url},
				    {datatype, <<"json">>},
				    {colNames, ['Name', 'RunDate', 'State', 'Start Time', 'End Time']},
				    {colModel, [
					[{name, 'name'}, {index, 'name'}, {width, 80}],
					[{name, 'date'}, {index, 'date'}, {width, 80}],
					[{name, 'state'}, {index, 'state'}, {width, 80}],
					[{name, 'start_time'}, {index, 'start_time'}, {width, 80}],
					[{name, 'end_time'}, {index, 'end_time'}, {width, 80}]
				    ]},
				    {rowNum, 30},
				    {rowList, [30, 50]},
				    {sortname, 'name'},
				    {viewrecords, true},
				    {sortorder, <<"desc">>},
				    %%{caption, <<"Processes">>},
				    {multiselect, true},
				    {autowidth, true},
				    %% {shrinkToFit, true},
				    {height, '100%'}
				    %% {width, 800},
				    %% {forceFit, true}
			    ]}
		    ]}
	]}}
    ]}.

tabs_event(?EVENT_TABSSHOW, _Tabs_Id, TabIndex) ->
    RunDate = wf:q(dropdown1),
    wf:wire(wf:f("pushState(\"State~s\", \"?date=~s&tab=~s\", {date:~s, tabindex:~s});",
	[TabIndex, RunDate, TabIndex, RunDate, TabIndex])).

api_event(history_back, _B, [[_,{data, Data}]]) ->
    ?PRINT({history_back_event, _B, Data}),
    RunDate = proplists:get_value(date, Data),
    Query = wf:q(txt_query),
    ?PRINT({run_date, RunDate}),
    TabIndex = proplists:get_value(tabindex, Data),
    ProcessData = index_fns:select(RunDate, Query),
    wf:wire(tabs, #tab_event_off{event = ?EVENT_TABSSHOW}),
    wf:wire(tabs, #tab_select{tab = TabIndex}),
    wf:replace(tbl_process, #process_table{id=tbl_process, data = ProcessData}),
    wf:wire(tabs, #tab_event_on{event = ?EVENT_TABSSHOW});
api_event(A, B, C) ->
    ?PRINT(A), ?PRINT(B), ?PRINT(C).

event(click) ->
    RunDate = wf:q(dropdown1),
    Data = index_fns:get_jobs(RunDate),
    wf:replace(button, #panel{
    		 body = wf:f("~p", [Data]),
    		 actions=#effect { effect=highlight }});

event(go) ->
    RunDate = wf:q(dropdown1),
    Query = wf:q(txt_query),
    ProcessData = index_fns:select(RunDate, Query),
    wf:replace(tbl_process, #process_table{id=tbl_process, data = ProcessData});

event(graph) ->
    RunDate = wf:q(dropdown1),
    wf:session(run_date, RunDate),
    URL = "/web_page1/" ++ RunDate,
    wf:redirect(URL).

%% event(logout) ->
%%     wf:logout(),
%%     wf:redirect("/");

%% event(clean) ->
%%     RunDate = wf:q(dropdown1),
%%     index_fns:clean("bb/A", list_to_atom(RunDate)).

collapsiblelist_event(Text) ->
    ?PRINT(Text).

available_rundates() ->
    #panel { class=menu, body=[
	#table{rows=[
	    #tablerow{class=row, cells=[
		#tablecell{class=col, body=[
		    #dropdown { id=dropdown1, options=index_fns:get_schedule_rundates()}]}
	    ]}
	]}
    ]}.
