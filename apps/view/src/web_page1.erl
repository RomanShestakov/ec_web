-module (web_page1).
-include_lib ("nitrogen_core/include/wf.hrl").
-compile(export_all).


%% main() -> 
%%     wf:content_type("image/svg+xml"),
%%     RunDate = wf:session(run_date),
%%     %% RunDate1 = string:tokens(wf_context:path_info(), "/"),

%%     ?PRINT({main, RunDate}),
%%     index_fns:get_svg(RunDate).



main() -> 
    RunDate = hd(string:tokens(wf_context:path_info(), "/")),
    ?PRINT({main, RunDate}),
    wf:content_type("image/svg+xml"),
    index_fns:get_svg(RunDate).

%% main() ->
%%        web_common:assert_path( "grid.html" ).



%% body() ->
%%     % Get the DeckID from PathInfo.
%%     % Load the Deck from Riak.

%%     %% wf:content_type("image/svg+xml"),
%%     %% RunDate = wf:session(run_date),

%%     %% RunDate1 = string:tokens(wf_context:path_info(), "/"),
%%     %% 	%% 	  [A]    -> {wf:to_binary(A), <<>>};
%%     %%     %% [A, B] -> {wf:to_binary(A), wf:to_binary(B)}
%%     ?PRINT({main, RunDate1}),
%% %%    index_fns:get_svg(RunDate),
%%     index_fns:get_svg(RunDate).


event(_) -> ok.

