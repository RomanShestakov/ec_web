-module (index).
-compile(export_all).

-include_lib ("nitrogen_core/include/wf.hrl").
-include_lib("nitrogen_elements/include/nitrogen_elements.hrl").
-include_lib("ec_web/include/elements.hrl").

%% -define(DATA, <<"digraph G {subgraph cluster_0 {style=filled;color=lightgrey; node [style=filled,color=white]; a0 -> a1 -> a2 -> a3;label = \"process #1\";} subgraph cluster_1 {node [style=filled]; b0 -> b1 -> b2 -> b3; label = \"process #2\";color=blue} start -> a0; start -> b0; a1 -> b3; b2 -> a3; a3 -> a0; a3 -> end; b3 -> end; start [shape=Mdiamond]; end [shape=Msquare];}">>).


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
    Rundate = wf:q(rundates),

    G = case Rundate of
	    undefined -> undefined;
	    Other -> ec_db:get_node(list_to_atom(Other))
	end,

    DotData = case G of
		  undefined -> <<>>;
		  G1 -> ec_digraphdot:generate_dot(G1)
	      end,

    %% action triggered on layout resize event to dynamically resize grid to fill parent container
    wf:wire(wf:f("function resizeGrid(pane, $pane, paneState){
                    var $contentDiv = $pane.find('.ui-widget-header');
                    $(obj('~s')).jqGrid('setGridWidth', $contentDiv.innerWidth() - 30, 'true')};", [jqgrid])),

    [
	% Main layout...
	#layout {
	    %% add menubar for navigation
	    north=#panel{id = north, text = "North"},
	    north_options = [{size, 60}, {spacing_open, 0}, {spacing_closed, 0}],

	    %% west=#panel{id = west, text = "West"},
	    west=#panel{id = west, body = [
		control_panel(),
		#p{},
		#button{id = conn, text = "Connect", actions = [#event{type = click, postback = connect}]}
	    ]},
	    west_options=[{size, 200}, {spacing_open, 0}, {spacing_closed, 0}],

	    %% center panel of layout
		center=#panel{id=center, body=[
		    #tabs{
			id=tabs,
			options=[{selected, 0}],
			style="margin:0; padding: 0 0 0 0;",
			tabs=[
			    #tab{title="Jobs",
				style="margin:0; padding: 0 0 0 -1;",
				body=[grid(Rundate)]},
			    #tab{title="Graph",
				body=[#panel{id=graph_viz}]}
		    ]}
		]},

	    %% option to resize grid on layout size change
	    %%center_options=[{onresize, resizeGrid}, {triggerEventOnLoad, true}]
	    center_options=[{onresize, resizeGrid}]

	    %% east=#panel{id = east, text = "East"},
	    %% east_options=[{size, 300}]
	    %%east_options=[{size, 200}, {spacing_open, 0}, {spacing_closed, 0}]

	    %% south=#panel{id = south, text = "South"},
	    %% south_options=[{size, 30}, {spacing_open, 0}, {spacing_closed, 0}]
	}
    ].

control_panel() ->
    #panel{id=control_panel, body = [
	#dropdown { id=rundates, options=index_fns:get_schedule_rundates()},
	#button{id=run_btn, text="Run", actions=[#event{type=click, postback=go}]}
    ]}.

grid(Rundate) when is_atom(Rundate) -> grid(atom_to_list(Rundate));
grid(Rundate) ->
    Url = list_to_binary("get_graph_nodes/?date=" ++ Rundate),
    #jqgrid{
	id=jqgrid,
	options=[
	    {url, Url},
	    {datatype, <<"json">>},
	    {colNames, ['Name', 'Group', 'RunDate', 'State', 'Start Time', 'End Time', 'Dependency']},
	    {colModel, [
		[{name, 'name'}, {index, 'name'}, {width, 150}],
		[{name, 'group'}, {index, 'group'}, {width, 80}],
		[{name, 'date'}, {index, 'date'}, {width, 50}],
		[{name, 'state'}, {index, 'state'}, {width, 50}],
		[{name, 'start_time'}, {index, 'start_time'}, {width, 50}],
		[{name, 'end_time'}, {index, 'end_time'}, {width, 50}],
		[{name, 'dependency'}, {index, 'dependency'}, {width, 180}]
	    ]},
	    {rowNum, 30},
	    {rowList, [30, 50, 80]},
	    %% {sortname, 'name'},
	    {viewrecords, true},
	    {sortorder, <<"desc">>},
	    %%{caption, <<"Processes">>},
	    {multiselect, true},
	    %%{shrinkToFit, true},
	    {height, '100%'},
	    {scrollOffset, 0}, %% switch off scrollbar
	    {autowidth, true}, %% fill parent container on load
	    {sortname, 'group'},
	    {grouping, true},
	    {groupingView, {{groupField, ['group']}, {groupColumnShow, [false]}, {groupText, [<<"<b>{0} - {1} Item(s)</b>">>]}}}
    ]}.


event(connect) ->
    Rundate = wf:q(rundates),
    %% need to be a valid address of the web host
    Server = "ws://rs.home:8000/websocket/?date=" ++ Rundate,
    %% ?PRINT({viz_server, Server}),
    wf:wire(#ws_open{server = Server, func = "function(event){console.log('open')};"}),
    wf:wire(#ws_message{func = wf:f("function(event){var g = jQuery(obj('~s'));
                                               g.html(Viz(event.data, \"svg\"));
	                                       g.find(\"svg\").width('100%');
	                                       g.find(\"svg\").graphviz({status: true});};", [graph_viz])}),
    wf:wire(#ws_error{func = "function(event){console.log('error')};"}),
    wf:replace(conn, #button{id = conn, text = "Disconnect", actions = [#event{type = click, postback = disconnect}]});
event(disconnect) ->
    wf:wire(#ws_close{}),
    wf:replace(conn, #button{id = conn, text = "Connect", actions = [#event{type = click, postback = connect}]});

%% layout1() ->
%%     wf:wire(tabs, #tab_event_on{type = ?EVENT_TABS_ACTIVATE}),
%%     wf:wire(#api{name=history_back, tag=f1}),
%%     RunDate1 = "20121227",
%%     Url = list_to_binary("get_graph_nodes/?date=" ++ RunDate1),
%%     ?PRINT({run_date, Url}),

%%     #container_12 { body=[
%%     	%% show dropbox with Rundates
%%     	#grid_12 { body = #panel{body = [available_rundates()]}},

%%     	%% show query box
%%     	#grid_12 { body = #table{rows=[
%%     	    #tablerow{class=row, cells=[
%%     		#tablecell{class=col, body=#button{id=btn_go, text="Go", postback=go}},
%%     		#tablecell{class=col, body=#button{id=btn_graph, text="Graph", postback=graph}},
%%     		#tablecell{class=col, body=#button{id=btn_logout, text="Logout", postback = logout}}
%%     	    ]}
%%     	]}},
%%     	%% put empty panel to output process names
%%     	#grid_12 { body =
%%     	    #tabs{
%%     		id = tabs,
%%     		options = [{selected, 0}],
%%     		style="margin:0;padding: 0 0 0 0;",
%%     		tabs = [
%%     		    %% #tab{title="Tab 1", body=[#panel{id=pnl_processes, class=mojorcontainer, body=[
%%     		    %% 	#process_table{id=tbl_process, data = Data}]}]},
%%     		    #tab{title="Jobs",
%%     			style="margin:0; padding: 0 0 0 0;",
%%     			body=[
%%     			    #jqgrid{
%%     				id = jqgrid,
%%     				options=[
%%     				    {url, Url},
%%     				    {datatype, <<"json">>},
%%     				    {colNames, ['Name', 'RunDate', 'State', 'Start Time', 'End Time']},
%%     				    {colModel, [
%%     					[{name, 'name'}, {index, 'name'}, {width, 80}],
%%     					[{name, 'date'}, {index, 'date'}, {width, 80}],
%%     					[{name, 'state'}, {index, 'state'}, {width, 80}],
%%     					[{name, 'start_time'}, {index, 'start_time'}, {width, 80}],
%%     					[{name, 'end_time'}, {index, 'end_time'}, {width, 80}]
%%     				    ]},
%%     				    {rowNum, 50},
%%     				    {rowList, [30, 50, 80]},
%%     				    {sortname, 'name'},
%%     				    {viewrecords, true},
%%     				    {sortorder, <<"desc">>},
%%     				    %%{caption, <<"Processes">>},
%%     				    {multiselect, true},
%%     				    {autowidth, true},
%%     				    %% {shrinkToFit, true},
%%     				    {height, '100%'}
%%     				    %% {width, 800},
%%     				    %% {forceFit, true}
%%     			    ]}
%%     		    ]}
%% 	    ]}
%% 	}
%%     ]}.

%    #label{text = "test"}.

%% api_event(history_back, _B, [[_,{data, Data}]]) ->
%%     ?PRINT({history_back_event, _B, Data}),
%%     RunDate = proplists:get_value(date, Data),
%%     Query = wf:q(txt_query),
%%     ?PRINT({run_date, RunDate}),
%%     TabIndex = proplists:get_value(tabindex, Data),
%%     ProcessData = index_fns:select(RunDate, Query),
%%     wf:wire(tabs, #tab_event_off{type = ?EVENT_TABS_ACTIVATE}),
%%     wf:wire(tabs, #tab_select{tab = TabIndex}),
%%     wf:replace(tbl_process, #process_table{id=tbl_process, data = ProcessData}),
%%     wf:wire(tabs, #tab_event_on{type = ?EVENT_TABS_ACTIVATE});
%% api_event(A, B, C) ->
%%     ?PRINT(A), ?PRINT(B), ?PRINT(C).

%% event(?EVENT_TABS_ACTIVATE, _Tabs_Id, TabIndex) ->
%%     RunDate = wf:q(dropdown1),
%%     wf:wire(wf:f("pushState(\"State~s\", \"?date=~s&tab=~s\", {date:~s, tabindex:~s});",
%% 	[TabIndex, RunDate, TabIndex, RunDate, TabIndex])).

%% event(click) ->
%%     RunDate = wf:q(dropdown1),
%%     Data = index_fns:get_jobs(RunDate),
%%     wf:replace(button, #panel{
%%     		 body = wf:f("~p", [Data]),
%%     		 actions=#effect { effect=highlight }});

event(go) ->
    Rundate = wf:q(rundates),
    ?PRINT({run_go, Rundate}),
    %% Query = wf:q(txt_query),
    %% ProcessData = index_fns:select(RunDate, Query),
    %% wf:replace(tbl_process, #process_table{id=tbl_process, data = ProcessData}).
    %% wf:replace(jqgrid, grid(Rundate)).
    Url = list_to_binary("get_graph_nodes/?date=" ++ Rundate),
    G = case Rundate of
    	undefined -> undefined;
    	Other -> ec_db:get_node(list_to_atom(Other))
    end,

    DotData = case G of
    	undefined -> <<>>;
    	G1 -> ec_digraphdot:generate_dot(G1)
    end,

    %% ?PRINT({run_go, DotData}),

    wf:wire(wf:f("$(obj('~s')).jqGrid('setGridParam', {url : '~s'}).trigger(\"reloadGrid\");", [jqgrid, Url])),
    wf:replace(graph_viz, #viz{id = graph_viz, data = DotData}).

%%jQuery("#list").jqGrid().setGridParam({url : 'newUrl'}).trigger("reloadGrid")

%%    wf:replace(jqgrid, #label{text="testjhfjhjh"}).
    %% #jqgrid{
    %% 	id=jqgrid,
    %% 	options=[
    %% 	    {url, Url},
    %% 	    {datatype, <<"json">>},
    %% 	    {colNames, ['Name', 'RunDate', 'State', 'Start Time', 'End Time']},
    %% 	    {colModel, [
    %% 		[{name, 'name'}, {index, 'name'}, {width, 150}],
    %% 		[{name, 'date'}, {index, 'date'}, {width, 80}],
    %% 		[{name, 'state'}, {index, 'state'}, {width, 80}],
    %% 		[{name, 'start_time'}, {index, 'start_time'}, {width, 80}],
    %% 		[{name, 'end_time'}, {index, 'end_time'}, {width, 80}]
    %% 	    ]},
    %% 	    {rowNum, 30},
    %% 	    {rowList, [30, 50, 80]},
    %% 	    {sortname, 'name'},
    %% 	    {viewrecords, true},
    %% 	    {sortorder, <<"desc">>},
    %% 	    %%{caption, <<"Processes">>},
    %% 	    {multiselect, true},
    %% 	    %%{shrinkToFit, true},
    %% 	    {height, '100%'},
    %% 	    {scrollOffset, 0}, %% switch off scrollbar
    %% 	    {autowidth, true} %% fill parent container on load
    %% ]}).


%% event(graph) ->
%%     RunDate = wf:q(dropdown1),
%%     wf:session(run_date, RunDate),
%%     URL = "/web_page1/" ++ RunDate,
%%     wf:redirect(URL).

%% %% event(logout) ->
%% %%     wf:logout(),
%% %%     wf:redirect("/");

%% %% event(clean) ->
%% %%     RunDate = wf:q(dropdown1),
%% %%     index_fns:clean("bb/A", list_to_atom(RunDate)).

%% collapsiblelist_event(Text) ->
%%     ?PRINT(Text).

%% available_rundates() ->
%%     #panel { class=menu, body=[
%% 	#table{rows=[
%% 	    #tablerow{class=row, cells=[
%% 		#tablecell{class=col, body=[
%% 		    #dropdown { id=dropdown1, options=index_fns:get_schedule_rundates()}]}
%% 	    ]}
%% 	]}
%%     ]}.
