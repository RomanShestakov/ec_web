-module(db_api).
-export([init_db/1]).

init_db(MasterNode) ->
    mnesia:stop(),
    mnesia:delete_schema([node()]),
    mnesia:start(),
    dynamic_db_init(MasterNode).

dynamic_db_init(MasterNode) ->
    add_extra_node(MasterNode).

add_extra_node(MasterNode) ->
    io:format("Replicating mnesia node from(~s) ~n", [MasterNode]),
    case mnesia:change_config(extra_db_nodes, [MasterNode] ) of
	{ok, [_Node]} ->
	    mnesia:add_table_copy(schema, node(), ram_copies),
	    mnesia:add_table_copy(job, node(), ram_copies),
	    Tables = mnesia:system_info(tables),
	    mnesia:wait_for_tables(Tables, 5000),
	    ok;
	 Reason ->
	    {err, Reason}
    end.
