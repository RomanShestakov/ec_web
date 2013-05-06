-module (index).
-compile(export_all).

-include_lib ("nitrogen_core/include/wf.hrl").
-include_lib("nitrogen_elements/include/nitrogen_elements.hrl").
-include_lib("ec_web/include/elements.hrl").
-include_lib("ec_web/include/ec_web.hrl").

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
    Rundate = wf:q(date),

    ?PRINT({rundate, Rundate}),

    %% create event for history API
    wf:wire(#api{name=history_back, tag=f1}),
    %% action triggered on layout resize event to dynamically resize grid to fill parent container
    wf:wire(wf:f("function resizeGrid(pane, $pane, paneState){
                    var $contentDiv = $pane.find('.ui-widget-header');
                    $(obj('~s')).jqGrid('setGridWidth', $contentDiv.innerWidth() - 30, 'true')};", [jqgrid])),

    [
	% Main layout...
	#layout {
	    %% add menubar for navigation
	    north=#panel{id = north, text = ""},
	    north_options = [{size, 60}, {spacing_open, 0}, {spacing_closed, 0}],

	    %% west=#panel{id = west, text = "West"},
	    west=#panel{id = west, body = [
		control_panel(Rundate),
		#p{},
		#button{id = conn, text = "Connect", actions = [#event{type = click, postback = connect}]}
	    ]},
	    west_options=[{size, 200}, {spacing_open, 0}, {spacing_closed, 0}],

	    %% center panel of layout
	    center=#panel{id=center, body=[
		#tabs{
		    id=tabs,
		    options=[{selected, 0}, {closable, true}],
		    %% actions = [#tab_cache{target = tabs}],
		    style="margin:0; padding: 0 0 0 0;",
		    tabs=[
			#tab{title="Jobs",
			    style="margin:0; padding: 0 0 0 -1;",
			    closable=false,
			    body=[grid(Rundate)]},
			#tab{title="Graph", closable=false, body=[#panel{id=graph_viz}]}
		],
		    actions = [
			#tab_cache{target = tabs},
			#tab_event_on{trigger = tabs, type = ?EVENT_TABS_ACTIVATE, postback = {tabs, ?EVENT_TABS_ACTIVATE}}
		    ]
		}
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

control_panel([]) ->
    #panel{id = control_panel, body = [
	#dropdown{id = rundates, options = index_fns:get_schedule_rundates()},
	#button{id = run_btn, text = "Run", actions = [#event{type = click, postback = go}]}
    ]};
control_panel(RunDate) ->
    #panel{id = control_panel, body = [
	#dropdown{id = rundates, value = RunDate, options = index_fns:get_schedule_rundates()},
	#button{id = run_btn, text = "Run", actions = [#event{type = click, postback = go}]}
    ]}.

grid(Rundate) when is_atom(Rundate) -> grid(atom_to_list(Rundate));
grid(Rundate) ->
    Url = list_to_binary("get_graph_nodes/?date=" ++ Rundate),
    #jqgrid{
	id=jqgrid,
	actions = [#jqgrid_event{trigger = jqgrid, target = jqgrid, type = ?ONLOADCOMPLETE, postback = ?ONLOADCOMPLETE}],
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
    case index_fns:get_websocket_name(Rundate) of
	{error, _} -> io:format("can't find node for resource ~p~n", [ec_master]);
	{ok, Server} ->
	    io:format("connecting to websocket at address: ~p~n", [Server]),
	    wf:wire(#ws_open{server = Server, func = "function(event){console.log('open')};"}),
	    wf:wire(#ws_message{func = wf:f("function(event){var g = jQuery(obj('~s'));
		g.html(Viz(event.data, \"svg\"));
		g.find(\"svg\").width('100%');
		g.find(\"svg\").graphviz({status: true});};", [graph_viz])}),
	    wf:wire(#ws_error{func = "function(event){console.log('error')};"}),
	    wf:replace(conn, #button{id = conn, text = "Disconnect", actions = [#event{type = click, postback = disconnect}]})
    end;
event(disconnect) ->
    io:format("disconnecting from websocket ~n", []),
    wf:wire(#ws_close{}),
    wf:replace(conn, #button{id = conn, text = "Connect", actions = [#event{type = click, postback = connect}]});
event({ID, ?EVENT_TABS_ACTIVATE}) ->
    RunDate = wf:q(rundates),
    ?PRINT({tabs_event, ?EVENT_TABS_ACTIVATE, RunDate}),
    wf:wire(wf:f("(function(){var index = jQuery(obj('~s')).tabs(\"option\", \"active\");
    	pushState(\"Date=~s&\"+index, \"?date=~s&\"+index, {date:~s, tabindex:index});})();", [ID, RunDate, RunDate, RunDate]));
event(go) ->
    Rundate = wf:q(rundates),
    Url = list_to_binary("get_graph_nodes/?date=" ++ Rundate),
    G = case Rundate of
    	undefined -> undefined;
    	Other -> ec_db:get_node(list_to_atom(Other))
    end,
    DotData = case G of
    	undefined -> <<>>;
    	G1 -> ec_digraphdot:generate_dot(G1)
    end,
    wf:wire(wf:f("(function(){var index = jQuery(obj('~s')).tabs(\"option\", \"active\");
    	pushState(\"Date=~s&\"+index, \"?date=~s&\"+index, {date:~s, tabindex:index});})();", [tabs, Rundate, Rundate, Rundate])),
    wf:wire(wf:f("$(obj('~s')).jqGrid('setGridParam', {url: '~s'}).trigger(\"reloadGrid\");", [jqgrid, Url])),
    wf:replace(graph_viz, #viz{id = graph_viz, data = DotData});
event(Event) ->
    ?PRINT({Event}).

%% this overrides click event on the links
%% so instead opening the link in the new page, we open a new tab
jqgrid_event({?ONLOADCOMPLETE, _}) ->
    wf:wire(wf:f("$(objs('~s')).click(function(event){event.preventDefault();
	var linkTo = $(this).attr(\"href\");
	$(\"<li><a href = \" + linkTo + \">\" + linkTo.split(\"/\").slice(-1)[0] + \"</a></li>\").appendTo($(obj(\"\#\#~s .ui-tabs-nav\")));
	$(obj('~s')).tabs(\"refresh\");
    })", [deps_link, tabs, tabs]));
jqgrid_event(Event) ->
    ?PRINT({jqgrid_event, Event}).

api_event(history_back, _B, [[_,{data, Data}]]) ->
    ?PRINT({history_back_event, _B, Data}),
    %% RunDate = proplists:get_value(date, Data),
    %% Query = wf:q(txt_query),
    %% ?PRINT({run_date, RunDate}),
    TabIndex = proplists:get_value(tabindex, Data),
    %% ProcessData = index_fns:select(RunDate, Query),
    wf:wire(tabs, #tab_event_off{type = ?EVENT_TABS_ACTIVATE}),
    wf:wire(tabs, #tab_select{tab = TabIndex}),
    %% wf:replace(tbl_process, #process_table{id=tbl_process, data = ProcessData}),
    wf:wire(tabs, #tab_event_on{trigger = tabs, type = ?EVENT_TABS_ACTIVATE, postback = {tabs, ?EVENT_TABS_ACTIVATE}});
api_event(A, B, C) ->
    ?PRINT(A), ?PRINT(B), ?PRINT(C).


%% jqgrid_event(Event) ->
%%     wf:wire(wf:f("$(objs('~s')).click(function(event){event.preventDefault();
%% 	var linkTo = $(this).attr(\"href\");
%% 	$(\"<li><a href = /content/tabs2.htm > Tes </a></li>\").appendTo($(obj(\"\#\#~s .ui-tabs-nav\")));
%% 	$(obj('~s')).tabs(\"refresh\");
%%     })", [deps_link, tabs, tabs])).


%% jqgrid_event(Event) ->
%%     wf:wire(wf:f("$(objs('~s')).click(function(event){event.preventDefault();
%% 	var linkTo = $(this).attr(\"href\");
%% 	$(\"<li><a href = \" + linkTo + \">\" + linkTo.split(\"/\").slice(-1)[0] + \"</a></li>\").appendTo($(obj(\"\#\#~s > .ui-tabs-nav\")));
%% 	$(obj('~s')).tabs( \"refresh\");})", [deps_link, tabs, tabs])).

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
