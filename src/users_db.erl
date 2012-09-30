-module(users_db).
-compile(export_all).

-include_lib("ec_web/include/ec_web.hrl").

validate_user(Username, Password) ->
    {ok, Data} = file:consult( filename:join([code:priv_dir(?APP), "users_db" ])),
    validate_user(Data, Username, Password).

validate_user([], _Username, _Password) ->
    {aborted, not_valid};
validate_user([{Name, Pass, Role}|T], Username, Password) ->
    case Username =:= Name andalso Password =:= Pass of
    	true ->
    	    {valid, Role};
    	false ->
	    validate_user(T, Username, Password)
    end.
