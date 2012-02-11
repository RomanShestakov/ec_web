-module (web_page3).
-include_lib ("nitrogen_core/include/wf.hrl").
-include_lib("ec_master/include/record_definitions.hrl").

-compile(export_all).

%% main() -> 
%%     Name = string:tokens(wf_context:path_info(), "/"),
%%     ?PRINT({main111, Name}),
%%     web_common:assert_path( "grid.html" ).

main() ->
%%    Name = string:tokens(wf_context:path_info(), "/"),
    %%?PRINT({main111, main}),
    web_common:assert_path( "grid.html" ).
    
%%main() -> #template { file="./site/templates/caster_grid.html" }.

title() -> "Nitrogen Web Framework for Erlang".

layout() ->
   % Argv = string:tokens(wf_context:path_info(), "/"),
    NameRundate = name_rundate_from_url(string:tokens(wf_context:path_info(), "/")),
    ?PRINT({NameRundate}),    

    {_V, Rec} = index_fns:select_node(NameRundate),
    ?PRINT({rec, Rec}),

    %%LogUrl = "/web_page4/" ++ Rec#fsm_state.logfile,
    ShowLog = false,
%%     case Rec#fsm_state.logfile of
%% 	undefined ->
%% 	    false;
%% 	_Other ->
%% 	    true
%%     end,

    #grid_12 { body = #table{rows=[
	#tablerow{class=row, cells=[
	    #tablecell{class=col, body=#label { text="Job Name", html_encode=true }},
	    #tablecell{class=col, body=#label { text=Rec#fsm_state.name}}]
	},
	#tablerow{class=row, cells=[
	    #tablecell{class=col, body=#label { text="Command", html_encode=true }},
	    #tablecell{class=col, body=#label { text=Rec#fsm_state.command}}]
	},
	#tablerow{class=row, cells=[
	    #tablecell{class=col, body=#label { text="State", html_encode=true }},
	    #tablecell{class=col, body=#label { text=Rec#fsm_state.state}}]
	},
	#tablerow{class=row, cells=[
	    #tablecell{class=col, body=#label { text="ExitStatus", html_encode=true }},
	    #tablecell{class=col, body=#label { text=wf:to_list(Rec#fsm_state.exit_status)}}]
	},
	#tablerow{class=row, show_if = ShowLog, cells=[
	    #tablecell{class=col, body=#label { text="Log", html_encode=true }},
	    #tablecell{class=col, body=#link { text="log", url = "/web_page4/" ++ "logfile"}}]
	}

    ]}}.

event(_) -> ok.

name_rundate_from_url(Tokens) ->
    {string:join(tl(Tokens), "/"), hd(Tokens)}.

    


