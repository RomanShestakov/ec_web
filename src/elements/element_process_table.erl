-module(element_process_table).
-compile(export_all).

-include_lib ("nitrogen_core/include/wf.hrl").
-include_lib("ec_web/include/elements.hrl").

%% define fields of the process table
-define(COLUMN_MAP,
	[
	 myButton@postback,
	 name@text,
	 name@url,
	 rundate@text,
	 state@text,
	 start_time@text,
	 end_time@text,
	 depends_on@data
	]).

reflect() -> record_info(fields, process_table).

render_element(#process_table{data = Data} = Record) ->
    [
	#table{id=tbl_processes, rows=[
	    #tablerow{cells=[
		#tableheader { },
		#tableheader { class = col, text="Name" },
		#tableheader { class = col, text="RunDate" },
		#tableheader { class = col, text="State" },
		#tableheader { class = col, text="Start Time" },
		#tableheader { class = col, text="End Time" },
		#tableheader { class = col, text="Depends" }
	    ]},
	    #bind{id=tableBinding, data=Data, map=?COLUMN_MAP, transform=fun alternate_color/2, body=
		#tablerow { id=top, cells= [
		    #tablecell { class = col, body=#checkbox{}},
		    #tablecell { class = col, body=#link{id=name}},
		    #tablecell { class = col, id=rundate },
		    #tablecell { class = col, id=state },
		    #tablecell { class = col, id=start_time },
		    #tablecell { class = col, id=end_time },
		    #tablecell { class = col, body = #collapsiblelist{collapsed = true, body =
			#bind{id=depends_on, map = [d_name@text, d_name@url], body=[#listitem{body = #link{id=d_name}}]}}}
		]}
	    }
	]}
    ].

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
