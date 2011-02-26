-include("types.hrl").

%% used to pass extra info about the source process which posted event
-record(evn_src, {name, run_date, state}).

%% used as state for fsm process
-record(fsm_state, {name,
		    description,
		    command,
		    env = [],
		    depends_on = [],
		    repeat,
		    start_after,
		    days,
		    type = regular,
		    clonesourcelist,
		    run_date,
		    parents,
		    children = dict:new(),
		    pid,
		    tsk_pid,
		    state::state(), 
		    job_definition,
		    node
		   }).

%% used in mnesia for storing info about process.
-record(job, {id,
	      name,
	      run_date,
	      pid,
	      start_time,
	      end_time,
	      state::state(),
	      depends_on
	     }).
	      
%% used to defind task
-record(task, {
	  name::string(),
	  command::string(),
	  run_date::date(),
	  env::list(),
	  source_pid::pid()
	 }).

%% used to pass info from parent to children
-record(parent_info, {name,
		      pid,
		      state,
		      type,
		      clonesourcelist}).

-define(SEND_ALL_EVENT(Pid, Event), gen_fsm:send_all_state_event(Pid, Event)).
-define(SEND_EVENT(Pid, Event), send_event(self(), Event)).
-define(SEND_STATE_CNG(NewState, Name, RunDate), ec_event:state_change(NewState, {Name, RunDate})).
-define(SEND_CHECK_STATE_EVENT(DepName, DepStateName),
	gen_fsm:send_all_state_event(self(), {?EVENT_PARENT_STATE_CNG, DepName, DepStateName})).
-define(NTF_CHLDR(State, Name, Event), notify_children(State#fsm_state.children, Name, Event)).
-define(RCV_MSG, "RCV_MSG: Event: ~p, STATE: ~p, Name: ~p, Date: ~p").
-define(UNX_MSG, "UNX_MSG: Event: ~p, STATE: ~p, Name: ~p, Date: ~p").
-define(NO_INTERLEAF, false).
-define(INTERLEAF, true).
-define(TIMER_NAME, "TimerJobName").

%% events
-define(EVENT_INIT_FSM, init_fsm).
-define(EVENT_PARENT_STATE_CNG, parent_state_change).
-define(EVENT_CHK_INTERLEAVING, check_interleaving).
-define(EVENT_LINK_TO_PRN, link_to_parents).
-define(EVENT_LINK_TO_CLN, link_to_clones).
-define(EVENT_CHECK_DAYS, check_days).
-define(EVENT_TRG_INTERL, trigger_intrl).
-define(EVENT_DPCY_SATISF, dpcy_satisfied).
-define(EVENT_CLN_DPCY_SATISF, cln_dpcy_satisfied).
-define(EVENT_RPL_TO_LINK_MSG, reply_link).
-define(EVENT_SET_TIMER, set_timer).


%% possible FSM states
-define(STATE_UNRNBLE, unrunnable).
-define(STATE_LINKING, linking).
-define(STATE_WAITING, waiting).
-define(STATE_CLONING, cloning).
-define(STATE_CLONE_WAITING, clone_waiting).
-define(STATE_READY, ready).
-define(STATE_LAUNCHED, launched).
-define(STATE_RUNNING, running).
-define(STATE_CANCELD, cancelled).
-define(STATE_SUCCESS, succeeded).
-define(STATE_DONE, done).
-define(STATE_FAILED, fail).
-define(STATE_SKIPPED, skipped).
