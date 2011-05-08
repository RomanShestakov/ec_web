-module(web_common).
-include_lib ("nitrogen_core/include/wf.hrl").
-compile(export_all).

header(Selected) ->
    wf:wire(Selected, #add_class { class=selected }),
    #panel { class=menu, body=[
        #link { id=index, url='/', text="INDEX" }
        %#link { id=page1, url='/page1', text="PAGE 1" },
	%%#link { id=page1, url='/page2', text="PAGE 2" },
	%#link { id=page3, url='/page3', text="PAGE 3" }
    ]}.

footer() ->
    #panel { class=credits, body=[
        "
        Nitrogen is copyright &copy; 2008-2010 <a href='http://rklophaus.com'>Rusty Klophaus</a>. 
        <img src='/images/MiniSpaceman.png' style='vertical-align: middle;' />
        Released under the MIT License.
        "
    ]}.

assert_path( Str ) when is_list( Str ) ->
    assert_path( #template { 
       file=filename:join([code:priv_dir(view), 
			   "templates", 
			   Str
			  ])
});

assert_path( Elem=#template {} ) ->
       Elem.


%% assert_path( Elem=#template {} ) ->
%%     case wf:path_info() of
%%         [] -> Elem;
%%         _ -> web_404:main()
%%      end.


available_rundates() ->
    #panel { class=menu, body=[
	#table{rows=[
	    #tablerow{class=row, cells=[
		#tablecell{class=col, body=[
		    #dropdown { id=dropdown1, options=index_fns:get_schedule_rundates() }
		]}
	    ]}
	]}
    ]}.
