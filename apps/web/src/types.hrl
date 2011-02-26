%% possible states fsm process could be in
-type(state() :: unrunnable | 
		 waiting |
		 ready |
		 launched |
		 running |
		 done |
		 failed |
		 succeeded |
		 cancelled |
		 not_started |
		 cloning |
		 clone_waiting |
		 skipped
		 ).

-type(process_type() :: 'NOP' |
			regular |
			clone |
			clone_base).

-type(date()::{Year::integer(),
	       Month::integer(),
	       Day::integer()}).

-type(time()::{Hour::integer(),
	       Minute::integer(),
	       Second::integer()}).

-type(dayofweek()::'mon' | 
		   'tue' |
		   'wed' |
		   'thu' |
		   'fri' |
		   'sat' |
		   'sub' |
		   'today').
