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

    #container_12 { body=[
	%% show dropbox with Rundates
	#grid_12 { body = #panel{body = [available_rundates()]}},

	%% show query box
	#grid_12 { body = #table{rows=[
	    #tablerow{class=row, cells=[
	%%	#tablecell{class=col, body=#label { text="Query", html_encode=true }},
	%%	#tablecell{class=col, body=#textbox { id=txt_query} },
		#tablecell{class=col, body=#button{id=btn_go, text="Go", postback=go}},
		#tablecell{class=col, body=#button{id=btn_graph, text="Graph", postback=graph}},
		#tablecell{class=col, body=#button{id=btn_logout, text="Logout", postback = logout}}
	    ]}
	    %%show tables with process control buttons
	    %% #tablerow{class=row, cells=[
	    %% 	%%#tablecell{class=col, body=  binary_to_list(image_data())}
	    %% 	%%#tablecell{class=col, body=#button{id=btn_redo,text="Redo"}},
	    %% 	%%#tablecell{class=col, body=#button{id=btn_cancel,text="Cancel"}}
	    %% ]}
	]}},
	%% %% put empty panel to output process names
	%% #grid_12 { body = #panel{id=pnl_processes,
	%%     class=mojorcontainer,
   	%%     body=[]}
	%% }
	%% put empty panel to output process names
	#grid_12 { body =
	    #tabs{
		id = tabs,
		tag = tabs1,
		options = [{selected, 0}],
		tabs = [
		    #tab{title="Tab 1", body=[#panel{id=pnl_processes, class=mojorcontainer, body=[
			#process_table{id=tbl_process, data = []}
		    ]}]},
		    #tab{title="Tab 2", body=["Tab two body..."]}
	]}}
    ]}.

%% actions() ->
%%     %%#p{},
%%     %%#label { id=lbl_rundate, text="Run Date", html_encode=true },
%%     %% rundate drop
%%     %% #dropdown { id=dropdown1, options=index_fns:get_schedule_rundates() },

%%     %% #button { id=button, text="Click me!", postback=click },
%%     %%#label { id = label, text="Some text.", html_encode=true },
%%     %% %% generate table with running jobs
%%     %%  %%#table { rows= index_fns:get_jobs() },

%%     %% #panel { body=[
%%     %% 		    #button { text="Clean", postback=clean }
%%     %% 		    %% #button { text="Redo", postback=redo },
%%     %% 		    %% #button { text="Kill", postback=kill }
%%     %% 		   ]}.
%% 	#p{}.

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
    %% wf:replace(pnl_processes, #panel{id=pnl_processes,
    %% 	body = [#process_table{id=tbl_process, data = Data}],
    %% 	actions=#effect { effect=highlight }});
    wf:replace(tbl_process, #process_table{id=tbl_process, data = ProcessData});

event(graph) ->
    RunDate = wf:q(dropdown1),
    wf:session(run_date, RunDate),
    URL = "/web_page1/" ++ RunDate,
    wf:redirect(URL);

event(logout) ->
    wf:logout(),
    wf:redirect("/");

event(clean) ->
    RunDate = wf:q(dropdown1),
    index_fns:clean("bb/A", list_to_atom(RunDate)).

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
