-module (web_page1).
-include_lib ("nitrogen_core/include/wf.hrl").
-compile(export_all).

main() -> 
    RunDate = hd(string:tokens(wf_context:path_info(), "/")),
    ?PRINT({main, RunDate}),
    wf:content_type("image/svg+xml"),
    index_fns:get_svg(RunDate).

event(_) -> ok.

