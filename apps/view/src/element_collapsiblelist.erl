-module (element_collapsiblelist).
-include_lib ("nitrogen_core/include/wf.hrl").

-include("../include/elements.hrl").

-compile(export_all).

-define(PLUS, "nitrogen/plus.gif").
-define(MINUS, "nitrogen/minus.gif").

reflect() -> record_info(fields, collapsiblelist).

render_element(Record) ->
    PanelID = wf:temp_id(),
    ListID = wf:temp_id(),
    ImageID = wf:temp_id(),

    %% show panel only if there are data
    IsShow = case (Record#collapsiblelist.body)#bind.data of
	[] ->
	    false;
	_Other ->
	    true
    end,

    {Image, Postback} = case Record#collapsiblelist.collapsed of
	true ->
	    wf:wire(ListID, #hide{}),
	    {?PLUS, click_show};
	false ->
	    {?MINUS, click_hide}
    end,

    #panel{ id = PanelID, show_if = IsShow, body = [
	#image{id = ImageID, image = Image, show_if = true, actions = [#event { 
	    type=click,
	    delegate=?MODULE, 
	    postback={Postback, ImageID, PanelID, ListID}}
	]}, 
	#list{id = ListID, numbered = true, body = Record#collapsiblelist.body}
    ]}.

event({click_hide, ImageID, PanelID, ListID}) ->
    wf:replace(ImageID, [#image{id = ImageID, image = ?PLUS, actions = [#event { 
	    type=click,
	    delegate=?MODULE, 
	    postback={click_show, ImageID, PanelID, ListID}}]}]),
     wf:wire(ListID, #hide{});

event({click_show, ImageID, PanelID, ListID}) ->
    wf:replace(ImageID, [#image{id = ImageID, image = ?MINUS, actions = [#event { 
	    type=click,
	    delegate=?MODULE, 
	    postback={click_hide, ImageID, PanelID, ListID }}]}]),
    wf:wire(ListID, #show{}).
