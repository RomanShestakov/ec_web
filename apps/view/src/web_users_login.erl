-module (web_users_login).
-include_lib ("nitrogen_core/include/wf.hrl").

-compile(export_all).

main() -> 
    web_common:assert_path( "grid.html" ).

title() -> "Login".

layout() ->
    wf:wire(submit, username, #validate { validators=[
        #is_required { text="Required." }
    ]}),
    wf:wire(submit, password, #validate { validators=[
        #is_required { text="Required." }
    ]}),
    
    #panel { style="margin: 50px;", body=[
	#flash{},
	#label { text="Login:" },
	#textbox { id=username, postback=login, next=password },
	#br {},
	#label { text="Password:" },
	#password { id=password, postback=login, next=submit },
	#br {},
	#button { id=submit, text="Login", postback=login }
    ]}.

event(login) ->
    Name = wf:q(username),
    Password = wf:q(password),
    case users_db:validate_user(Name, Password) of
    	{valid, Role} ->
    	    wf:role(Role, true),
    	    wf:redirect("/");
	%%wf:redirect_from_login("/");
    	_ ->
    	    wf:flash("Incorrect login")
    end;

event(_) -> ok.


%% validate_user(Username, Password) ->
%%     case Username =:= "demo" andalso Password =:= "test" of
%% 	true ->
%% 	    {valid, admin};
%% 	false ->
%% 	    {aborted, "Not Valid"}
%%     end.
