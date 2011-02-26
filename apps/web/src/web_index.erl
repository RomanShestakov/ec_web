-module (web_index).
-include_lib ("nitrogen_core/include/wf.hrl").
-compile(export_all).
            
main() ->
       web_common:assert_path( "grid.html" ).

title() -> "Nitrogen Web Framework for Erlang".

layout() ->
    #container_12 { body=[
        #grid_12 { body="Welcome to Nitrogen" }
	
	%% show dropbox with Rundates
	#grid_12 { body = web_common:available_rundates()},

	%% show query box 
	#grid_12 { body = #table{rows=[
	    #tablerow{class=row, cells=[
		#tablecell{class=col, body=#label { text="Query", html_encode=true }},
		#tablecell{class=col, body=#textbox { id=txt_query} },
		#tablecell{class=col, body=#button{id=btn_go, text="Go", postback=go}}
	    ]},
	    %% show tables with process control buttons
	    #tablerow{class=row, cells=[
		#tablecell{class=col, body=#button{id=btn_clean,text="Clean",postback=clean}},
		#tablecell{class=col, body=#button{id=btn_redo,text="Redo"}},
		#tablecell{class=col, body=#button{id=btn_cancel,text="Cancel"}}
	    ]}	    
	]}},
	%% put empty panel to output process names
	#grid_12 { body = #panel{id=pnl_processes,
	    class=mojorcontainer,
   	    body=[]}
	}
    ]}.

%% build table with process details
build_process_table(Data,Map) ->
    [
	#table{id=tbl_processes, rows=[
	    #tablerow{cells=[
		#tableheader { },
		#tableheader { class = col, text="Name" },
		#tableheader { class = col, text="RunDate" },
		#tableheader { class = col, text="State" }
	    ]},
	    #bind{id=tableBinding, data=Data, map=Map, transform=fun alternate_color/2, body=
		#tablerow { id=top, cells= [
		    #tablecell { class = col, body=#checkbox{}},
		    #tablecell { class = col, id=name },
		    #tablecell { class = col, id=rundate },
		    #tablecell { class = col, id=state }
		]}
	    }
	]}
    ].

actions() ->
    %%#p{},
    %%#label { id=lbl_rundate, text="Run Date", html_encode=true },
    %% rundate drop
    %% #dropdown { id=dropdown1, options=index_fns:get_schedule_rundates() },
    
    %% #button { id=button, text="Click me!", postback=click },
    %%#label { id = label, text="Some text.", html_encode=true },
    %% %% generate table with running jobs
    %%  %%#table { rows= index_fns:get_jobs() },
    
    %% #panel { body=[
    %% 		    #button { text="Clean", postback=clean }
    %% 		    %% #button { text="Redo", postback=redo },
    %% 		    %% #button { text="Kill", postback=kill }
    %% 		   ]}.
	#p{}.


%% inplace_textbox_event(_Tag, Value) ->
%%   %% wf:wire(#alert { text=wf:f("You entered: ~s", [Value]) }),
%%   %% Value.




event(click) ->
 %%   Result = rpc:call('emacs@rs', ec_master, get_schedulers, []), 
%%    wf:update(label, text = wf:f("Result ~p.", [Result])),
    RunDate = wf:q(dropdown1),
    Data = index_fns:get_jobs(RunDate),

    wf:replace(button, #panel{ 
    		 body = wf:f("~p", [Data]), 
    		 actions=#effect { effect=highlight }});

event(go) ->
    RunDate = wf:q(dropdown1),
    Query = wf:q(txt_query),
    Data = index_fns:select(RunDate, Query),
    ColumnMap = process_column_map(),
    wf:replace(pnl_processes, #panel{id=pnl_processes,
	       body = build_process_table(Data, ColumnMap), 
	       actions=#effect { effect=highlight }});


event(clean) ->
    RunDate = wf:q(dropdown1),
    index_fns:clean("bb/A", list_to_atom(RunDate)).


%%% ALTERNATE CASE %%%
alternate_case(DataRow, Acc) when Acc == []; Acc == odd  ->
    [Postback, Name, RunDate, State] = DataRow,
    F = fun string:to_upper/1,
    { [Postback, F(Name), F(RunDate),  F(State)], even, [] };

alternate_case(DataRow, Acc) when Acc == even  ->
    [Postback, Name, RunDate, State] = DataRow,
    F = fun string:to_lower/1,
    { [Postback, F(Name), F(RunDate),  F(State)], odd, [] }.


%%% ALTERNATE BACKGROUND COLORS %%%
alternate_color(DataRow, Acc) when Acc == []; Acc==odd ->
    {DataRow, even, {top@style, "background-color: #eee;"}};

alternate_color(DataRow, Acc) when Acc == even ->
    {DataRow, odd, {top@style, "background-color: #ddd;"}}.

%% define fields of the process table
process_column_map() -> 
    [
	myButton@postback,
	name@text, 
	rundate@text,
	state@text
    ].
