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
    %?PRINT({main111, main}),
    web_common:assert_path( "log_template.html" ).
    
%%main() -> #template { file="./site/templates/caster_grid.html" }.

%title() -> "Nitrogen Web Framework for Erlang".

layout() ->
   % Argv = string:tokens(wf_context:path_info(), "/"),

    LogFile = string:join(string:tokens(wf_context:path_info(), "/"), "/"),
    %%?PRINT({logfile, LogFile}),

    Root  = ec_cli:get_master_config(),%%ec_app_helper:get_env(ec_web, logs_root),
    %%?PRINT({log, Root}),
    
    FullPath = filename:join([Root, LogFile]),
    %%?PRINT({log, FullPath}),
    %%{ok, File} = file:open(LogFile, read),
%%    L = filename:join(Root, LogFile),


    {ok, Bin} = file:read_file(FullPath),
    %% {_V, Rec} = index_fns:select_node(NameRundate),
    %%?PRINT({data, Bin}),

    %%#literal { text="<b>This</b> is some <i>text</i>" }.

    %%#literal { text=wf:html_encode(wf:to_list(Bin))}.

    wf:content_type("text/plain"),
    #literal { text=wf:to_list(Bin)}.

%% event(_) -> ok.

%% name_rundate_from_url(Tokens) ->
%%     {string:join(tl(Tokens), "/"), hd(Tokens)}.

    
%% html_encode(L, true) -> html_encode(wf:to_list(lists:flatten([L]))).	
%% html_encode([]) -> [];
%% html_encode([H|T]) ->
%%     case H of
%% 	$< -> "&lt;" ++ html_encode(T);
%% 	$> -> "&gt;" ++ html_encode(T);
%% 	$" -> "&quot;" ++ html_encode(T);
%% 	$' -> "&#39;" ++ html_encode(T);
%% 	$& -> "&amp;" ++ html_encode(T);
%%         $\n -> "<br>" ++ html_encode(T);
%% 	_ -> [H|html_encode(T)]
%%     end.


