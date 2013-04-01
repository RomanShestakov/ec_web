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
    %% web_common:assert_path( "grid.html" ).
    web_common:assert_path( "bare.html" ).

%%main() -> #template { file="./site/templates/caster_grid.html" }.

title() -> "Job Details".

layout() ->
   %% %%Argv = string:tokens(wf_context:path_info(), "/"),
   NameRundate = name_rundate_from_url(string:tokens(wf_context:path_info(), "/")),
   %% %%  %% ?PRINT({NameRundate}),

   {_V, Rec} = index_fns:select_node(NameRundate),
   %%  %% ?PRINT({rec, Rec}),

   %%  %%LogUrl = "/web_page4/" ++ Rec#fsm_state.logfile,
   %%  ShowLog = false,
%%     case Rec#fsm_state.logfile of
%% 	undefined ->
%% 	    false;
%% 	_Other ->
%% 	    true
%%     end,
    [#panel{body = [
    	#label { text="Job Name", html_encode=true },
    	#label { text=Rec#fsm_state.name },
    	#p{},
    	#label { text="Command", html_encode=true },
    	#label { text=Rec#fsm_state.command},
    	#p{},
    	#label { text="State", html_encode=true },
    	#label { text=Rec#fsm_state.state},
    	#p{},
    	#label { text="ExitStatus", html_encode=true },
    	#label { text=wf:to_list(Rec#fsm_state.exit_status)}
    ]}].
    %% #label{text = "YYYYYYYYYYYYYY"}.


event(_) -> ok.
name_rundate_from_url(Tokens) ->
    {string:join(tl(Tokens), "/"), hd(Tokens)}.




