%% Copyright 2009 Joony (jonathan.mcallister@gmail.com)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% web_users_login.erl
%%
%% The login screen.
%%

-module (web_users_login).
-include_lib ("nitrogen_core/include/wf.hrl").

-compile(export_all).

main() -> 
    web_common:assert_path( "grid.html" ).
%%	#template { file="./wwwroot/template.html"}.

title() -> "Login".

layout() ->

    #container_12 { body=[
        %%#grid_12 { body="Welcome to Nitrogen" }
	
	%% show dropbox with Rundates
	#grid_12 { body = [
	    #flash{},
	    #label { text="Login:" },
	    #textbox { id=username, postback=login, next=password },
	    #br {},
	    #label { text="Password:" },
	    #password { id=password, postback=login, next=submit },
	    #br {},
	    #button { id=submit, text="Login", postback=login }
	]}
    ]}.





%% body() ->

%%     Body = [
%% 	    #label { text="Login:" },
%% 	    #textbox { id=username, postback=login, next=password },
%% 	    #br {},
%% 	    #label { text="Password:" },
%% 	   % #password { id=password, postback=login, next=submit },
%% 	    #br {},
%% 	    #button { id=submit, text="Login", postback=login }
%%     ],
%%     wf:wire(submit, username, #validate { validators = [ #is_required { text="Required" }]}).
%%     %%wf:render(Body).

event(login) ->
    Name = wf:q(username),
    Password = wf:q(password),
    ?PRINT({login, Name, Password}), 
    case validate_user(Name, Password) of
	{valid, Role} ->
	    %io:format("User: ~s has logged in~n", [wf:q(username)]),
	    %wf:flash("Correct"),
	    %%wf:user(Name),
	    %%wf:redirect("login");
	    wf:role(Role, true),
	    wf:redirect_from_login("/");
	    %%wf:redirect("web_index");
	_ ->
	    wf:flash("Incorrect login")
    end;

event(_) -> ok.


validate_user(Username, Password) ->
    case Username =:= "demo" andalso Password =:= "test" of
	true ->
	    {valid, admin};
	false ->
	    {aborted, "Not Valid"}
    end.
