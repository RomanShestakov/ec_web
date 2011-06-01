-module (web_page4).
-include_lib ("nitrogen_core/include/wf.hrl").
-include_lib("ec_master/include/record_definitions.hrl").

-compile(export_all).

%% main() -> 
%%     Name = string:tokens(wf_context:path_info(), "/"),
%%     ?PRINT({main111, Name}),
%%     web_common:assert_path( "grid.html" ).

main() ->
%%    Name = string:tokens(wf_context:path_info(), "/"),
    ?PRINT({main111, main}),
    web_common:assert_path( "grid.html" ).
    
%%main() -> #template { file="./site/templates/caster_grid.html" }.

title() -> "Nitrogen Web Framework for Erlang".

layout() ->
   % Argv = string:tokens(wf_context:path_info(), "/"),
    LogFile = wf_context:path_info(),
    ?PRINT({logfile, LogFile}),

    Root  = ec_cli:get_master_config(),%%ec_app_helper:get_env(ec_web, logs_root),
    %%{ok, File} = file:open(LogFile, read),

    {ok, Bin} = file:read_file(filename:join(Root, LogFile)),
    %% {_V, Rec} = index_fns:select_node(NameRundate),
    ?PRINT({data, Bin}),

    %%#literal { text="<b>This</b> is some <i>text</i>" }.

    #literal { text=wf:html_encode(wf:to_list(Bin))}.

    %% #grid_12 { body = #table{rows=[
    %% 	#tablerow{class=row, cells=[
    %% 	    #tablecell{class=col, body=#literal { text=wf:to_list(Bin)}}]
    %% 	   %% #tablecell{class=col, body=#label { text=Rec#fsm_state.name}}]
    %% 	}
	%% #tablerow{class=row, cells=[
	%%     #tablecell{class=col, body=#label { text="Command", html_encode=true }},
	%%     #tablecell{class=col, body=#label { text=Rec#fsm_state.command}}]
	%% },
	%% #tablerow{class=row, cells=[
	%%     #tablecell{class=col, body=#label { text="State", html_encode=true }},
	%%     #tablecell{class=col, body=#label { text=Rec#fsm_state.state}}]
	%% },
	%% #tablerow{class=row, cells=[
	%%     #tablecell{class=col, body=#label { text="ExitStatus", html_encode=true }},
	%%     #tablecell{class=col, body=#label { text=wf:to_list(Rec#fsm_state.exit_status)}}]
	%% },
	%% #tablerow{class=row, cells=[
	%%     #tablecell{class=col, body=#label { text="Log", html_encode=true }},
	%%     #tablecell{class=col, body=#link { text="log", url = "/web_page4/" ++ Rec#fsm_state.logfile}}]
	%% }

%%    ]}}.

event(_) -> ok.

name_rundate_from_url(Tokens) ->
    {string:join(tl(Tokens), "/"), hd(Tokens)}.

    
html_encode(L, true) -> html_encode(wf:to_list(lists:flatten([L]))).	
html_encode([]) -> [];
html_encode([H|T]) ->
    case H of
	$< -> "&lt;" ++ html_encode(T);
	$> -> "&gt;" ++ html_encode(T);
	$" -> "&quot;" ++ html_encode(T);
	$' -> "&#39;" ++ html_encode(T);
	$& -> "&amp;" ++ html_encode(T);
        $\n -> "<br>" ++ html_encode(T);
	_ -> [H|html_encode(T)]
    end.


