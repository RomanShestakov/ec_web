-module (web_page3).
-include_lib ("nitrogen_core/include/wf.hrl").
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
    ?PRINT({page3, "hit main"}),

    #container_12 { body=[
        #grid_12 { body="Welcome to Nitrogen" }
	#grid_12 { body = string:tokens(wf_context:path_info(), "/")}
    ]}.

event(_) -> ok.

