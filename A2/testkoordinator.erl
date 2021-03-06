-module(testkoordinator).

-include_lib("eunit/include/eunit.hrl").


%    start/0,

%    init_loop/4
%    create_circle/2,
%    set_neighbors/4,
%    get_next_to_last_and_last_elem/1

%    calculation_receive_loop/3,
%    briefmi/3,
%    briefterm/4,
%    reset/2,
%    calc/3,
%    get_pms/2,
%    select_random_some_ggtprocesses/1,
%    send_pms_to_ggtprocesses/3,
%    send_ys_to_ggtprocesses/3,
%    get_first_n_elems_of_list/3,
%    send_message_to_processname/3,
%    prompt/0,
%    nudge/2,
%    toggle/1,
%    kill/2,
%    kill_all_ggtprocesses/2,

%    ggtpropid_exists/2,
%    get_ggtpropid/2

init_loop_1_test() ->
    SteeringValues = {steeringval, 0, 0, 1, 5},
    ThisPid = self(),
    register(nameservice, self()),
    TestPid = spawn(fun() -> 
                    GGTProNameList = koordinator:init_loop(
                                        ThisPid, 
                                        SteeringValues, 
                                        0, 
                                        []), 
                    ThisPid ! GGTProNameList
                end),

    TestPid ! {ThisPid, getsteeringval},
    receive
        Any1 ->
            ?assertEqual({steeringval, 0, 0, 4, 5}, Any1)
    end,

    TestPid ! {ThisPid, getsteeringval},
    receive
        Any2 ->
            ?assertEqual({steeringval, 0, 0, 8, 5}, Any2)
    end,

    TestPid ! {hello, nameC},
    TestPid ! {hello, nameB},
    TestPid ! {hello, nameA},

    TestPid ! step,

    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),
    receive
        Any3 ->
            {setneighbors, nameC, nameB} = Any3
    end,
    answer_lookup(nameC, ThisPid),
    answer_lookup(nameC, ThisPid),
    receive
        Any4 ->
            {setneighbors, nameB, nameA} = Any4
    end,
    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),
    receive
        Any5 ->
            {setneighbors, nameA, nameC} = Any5
    end,

    receive
        Any6 ->
            ?assertEqual([nameA, nameB, nameC], Any6)
    end,
    unregister(nameservice),
    kill_pid_and_clear_this_mailbox(TestPid).

calc_quote_1_test() ->
    ?assertEqual(0, koordinator:calc_quote(0,0)).

calc_quote_2_test() ->
    ?assertEqual(0, koordinator:calc_quote(3,0)).

calc_quote_3_test() ->
    ?assertEqual(0, koordinator:calc_quote(0,3)).

calc_quote_4_test() ->
    ?assertEqual(20, koordinator:calc_quote(5,5)).

calc_quote_5_test() ->
    ?assertEqual(5, koordinator:calc_quote(3,2)).

create_circle_1_test() -> 
    ?assertError({badmatch, []}, koordinator:create_circle([], self())).

create_circle_2_test() -> 
    ?assertError({badmatch, [nameA]}, koordinator:create_circle([nameA], self())).

create_circle_3_test() -> 
    ThisPid = self(),
    TestPid = spawn(fun() -> 
            koordinator:create_circle([nameA, nameB, nameC], ThisPid)
        end),

    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),
    receive
        Any2 ->
            {setneighbors, nameC, nameB} = Any2
    end,
    answer_lookup(nameC, ThisPid),
    answer_lookup(nameC, ThisPid),
    receive
        Any4 ->
            {setneighbors, nameB, nameA} = Any4
    end,
    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),
    receive
        Any6 ->
            {setneighbors, nameA, nameC} = Any6
    end,
    kill_pid_and_clear_this_mailbox(TestPid).

set_neighbors_1_test() -> 
    ThisPid = self(),
    TestPid = spawn(fun() ->
            koordinator:set_neighbors(nameA, nameC, nameB, ThisPid)
        end),
    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),
    receive
        Any2 ->
            {setneighbors, nameC, nameB} = Any2
    end,
    kill_pid_and_clear_this_mailbox(TestPid).

get_next_to_last_and_last_elem_1_test() -> 
    ?assertEqual(
        [1,2], 
        koordinator:get_next_to_last_and_last_elem([1,2])).

get_next_to_last_and_last_elem_2_test() -> 
    ?assertEqual(
        [1,2], 
        koordinator:get_next_to_last_and_last_elem([3,4,5,6,1,2])).

calculation_receive_loop_1_test() -> 
    ThisPid = self(),
    TestPid = spawn(fun() ->
            koordinator:calculation_receive_loop([nameA, nameB], ThisPid, false, 0)
        end),
    TestPid ! prompt,

    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),

    receive 
        Any1 -> 
            {TestPid, tellmi} = Any1,
            TestPid ! {mi, 3}
    end,

    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),

    receive 
        Any2 -> 
            {TestPid, tellmi} = Any2,
            TestPid ! {mi, 4}
    end,

    TestPid ! kill,
    
    receive
        Any5 -> 
            {TestPid, {unbind, koordinator}} = Any5,
            TestPid ! ok
    end,

    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),
    receive 
        Any3 -> ?assertEqual(kill, Any3) 
    end,

    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),
    receive 
        Any4 -> ?assertEqual(kill, Any4) 
    end,

    timer:sleep(500),

    ?assertEqual(undefined, process_info(TestPid, registered_name)).


briefmi_1_test() ->
    ?assertEqual(0, koordinator:briefmi(nameA, 3, empty, 0)).

briefmi_2_test() ->
    ?assertEqual(3, koordinator:briefmi(nameA, 3, empty, 3)).

briefmi_3_test() ->
    ?assertEqual(3, koordinator:briefmi(nameA, 3, empty, 4)).

briefterm_1_test() ->
    ?assertEqual(3, koordinator:briefterm(self(), nameA, 3, empty, 4, false)).

briefterm_2_test() ->
    ?assertEqual(3, koordinator:briefterm(self(), nameA, 4, empty, 3, true)),
    receive 
        Any -> ?assertEqual({sendy, 3}, Any)
    end.

briefterm_3_test() ->
    ?assertEqual(3, koordinator:briefterm(self(), nameA, 4, empty, 3, false)).


reset_1_test() ->
    ProList = [nameA, nameB],
    ThisPid = self(),
    TestPid = spawn(fun() -> 
                        koordinator:reset(ProList, ThisPid)
                    end),
    receive
        Any3 -> 
            {TestPid, {unbind, koordinator}} = Any3,
            TestPid ! ok
    end,
            
    receive
        Any4 -> 
            {TestPid, {rebind, koordinator, _Node}} = Any4,
            TestPid ! ok
    end,
    exit(TestPid, kill).

calc_1_test() ->
    ThisPid = self(),
    GGTList = [nameA, nameB, nameC],
    WggT = 15,
    TestPid = spawn(fun() -> 
                       koordinator:calc(WggT, GGTList, ThisPid)
                    end),

    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),

    receive
        Any1 -> {setpm, _Any1Pm} = Any1
    end,

    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),

    receive
        Any2 -> {setpm, _Any2Pm} = Any2
    end,

    answer_lookup(nameC, ThisPid),
    answer_lookup(nameC, ThisPid),

    receive
        Any3 -> {setpm, _Any3Pm} = Any3
    end,

    receive Any4 -> {TestPid, {lookup, Any4Name}} = Any4 end,
    TestPid ! {pin, ThisPid},
    receive Any5 -> {TestPid, {lookup, Any5Name}} = Any5 end,
    ?assertEqual(Any4Name, Any5Name),
    ?assert(lists:member(Any4Name, GGTList)),
    TestPid ! {pin, ThisPid},

    receive Any6 -> {sendy, _Any6Pm} = Any6 end,

    receive Any7 -> {TestPid, {lookup, Any7Name}} = Any7 end,
    TestPid ! {pin, ThisPid},
    receive Any8 -> {TestPid, {lookup, Any8Name}} = Any8 end,
    ?assertEqual(Any7Name, Any8Name),
    ?assert(lists:member(Any7Name, GGTList)),
    TestPid ! {pin, ThisPid},

    receive Any9 -> {sendy, _Any9Pm} = Any9 end,

    kill_pid_and_clear_this_mailbox(TestPid),
    clear_mailbox().



get_pms_1_test() ->
    GGTProNameList = [nameA, nameB, nameC, nameD],
    PMList = koordinator:get_pms(16, GGTProNameList),
    ?assertEqual(
        4,
        length(PMList)
    ).

select_random_some_ggtprocesses_1_test() ->
    GGTProNameList = [nameA, nameB, nameC],
    Result = koordinator:select_random_some_ggtprocesses(GGTProNameList),
    ResultStr = util:list2string(Result),
    ResultTokens = lists:delete("\n", string:tokens(ResultStr, " ")),
    io:fwrite("~p", [ResultTokens]),

    ?assertEqual(2, length(ResultTokens)),

    [ResultElem1, ResultElem2] = Result,

    ?assertNotEqual(ResultElem1, ResultElem2),
    ?assert(lists:member(ResultElem1, GGTProNameList)),
    ?assert(lists:member(ResultElem2, GGTProNameList)).


send_pms_to_ggtprocesses_1_test() ->
    ThisPid = self(),
    GGTList = [nameA, nameB, nameC],
    Pms = [3,2,1],
    _TestPid = spawn(fun() -> 
                       koordinator:send_pms_to_ggtprocesses(Pms, GGTList, ThisPid)
                    end),
    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),

    receive
        Any1 -> ?assertEqual({setpm, 3}, Any1)
    end,

    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),

    receive
        Any2 -> ?assertEqual({setpm, 2}, Any2)
    end,

    answer_lookup(nameC, ThisPid),
    answer_lookup(nameC, ThisPid),

    receive
        Any3 -> ?assertEqual({setpm, 1}, Any3)
    end.

send_ys_to_ggtprocesses_1_test() ->
    ThisPid = self(),
    GGTList = [nameA, nameB],
    Ys = [3,2,1],
    _TestPid = spawn(fun() -> 
                       koordinator:send_ys_to_ggtprocesses(Ys, GGTList, ThisPid)
                    end),
    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),

    receive
        Any1 -> ?assertEqual({sendy, 3}, Any1)
    end,

    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),

    receive
        Any2 -> ?assertEqual({sendy, 2}, Any2)
    end.

get_first_n_elems_of_list_1_test() ->
    List = [1,2,3,4,5,6,7,8],
    ?assertEqual(
        [2,1],
        koordinator:get_first_n_elems_of_list(2, List, [])).

get_first_n_elems_of_list_2_test() ->
    List = [1,2,3,4,5,6,7,8],
    ?assertEqual(
        [],
        koordinator:get_first_n_elems_of_list(0, List, [])).

send_message_to_processname_1_test() ->
    Message = hallo,
    ThisPid = self(),
    _TestPid = spawn(fun() -> 
                       koordinator:send_message_to_processname(Message, nameA, ThisPid)
                    end),
    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),

    receive
        Any -> ?assertEqual(Message, Any)
    end.

prompt_1_test() ->
    GGTProNameList = [nameA, nameB],
    ThisPid = self(),
    TestPid = spawn(fun() -> 
                       koordinator:prompt(GGTProNameList, ThisPid)
                    end),
    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),

    receive 
        Any1 -> 
            {TestPid, tellmi} = Any1,
            TestPid ! {mi, 3}
    end,

    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),

    receive 
        Any2 -> 
            {TestPid, tellmi} = Any2,
            TestPid ! {mi, 4}
    end.


nudge_1_test() ->
    ThisPid = self(),
    TestPid = spawn(fun() -> 
                        ok = koordinator:nudge([nameA], ThisPid)
                    end),
    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),
    receive
        Any3 ->
            {TestPid, pingGGT} = Any3,
            TestPid ! {pongGGT, nameA}
    end.

nudge_2_test() ->
    ThisPid = self(),
    _TestPid = spawn(fun() -> 
                        ?assertThrow(
                            ggtpronameUnkownForNs, 
                            koordinator:nudge([nameA], ThisPid))
                    end),
    answer_lookup(nameA, not_found).

toggle_1_test() ->
    ?assert(koordinator:toggle(false)).

toggle_2_test() ->
    ?assertNot(koordinator:toggle(true)).

kill_1_test() ->
    ProList = [nameA, nameB],
    ThisPid = self(),
    TestPid = spawn(fun() -> 
                        koordinator:kill(ProList, ThisPid)
                    end),
    receive
        Any3 -> 
            {TestPid, {unbind, koordinator}} = Any3,
            TestPid ! ok
    end,

    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),
    receive 
        Any1 -> ?assertEqual(kill, Any1) 
    end,

    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),
    receive 
        Any2 -> ?assertEqual(kill, Any2) 
    end,

    timer:sleep(500),

    ?assertEqual(undefined, process_info(TestPid, registered_name)).

kill_all_ggtprocesses_1_test() ->
    ProList = [nameA, nameB],
    ThisPid = self(),
    _TestPid = spawn(fun() -> 
                        koordinator:kill_all_ggtprocesses(ProList, ThisPid)
                    end),
    answer_lookup(nameA, ThisPid),
    answer_lookup(nameA, ThisPid),
    receive 
        Any1 -> ?assertEqual(kill, Any1) 
    end,

    answer_lookup(nameB, ThisPid),
    answer_lookup(nameB, ThisPid),
    receive 
        Any2 -> ?assertEqual(kill, Any2) 
    end,

    timer:sleep(500).
    

ggtpropid_exists_1_test() ->
    ThisPid = self(),
    _TestPid = spawn(fun() -> 
                        Result = koordinator:ggtpropid_exists(nameA, ThisPid),
                        ThisPid ! Result
                    end),
    answer_lookup(nameA, ThisPid),
    receive
        Any ->
            ?assert(Any)
    end.

ggtpropid_exists_2_test() ->
    ThisPid = self(),
    _TestPid = spawn(fun() -> 
                        Result = koordinator:ggtpropid_exists(nameA, ThisPid),
                        ThisPid ! Result
                    end),
    answer_lookup(nameA, not_found),
    receive
        Any ->
            ?assertEqual(false, Any)
    end.

get_ggtpropid_1_test() ->
    ThisPid = self(),
    _TestPid = spawn(fun() -> 
                        Result = koordinator:get_ggtpropid(nameA, ThisPid),
                        ThisPid ! Result
                    end),
    answer_lookup(nameA, ThisPid),
    receive
        Any ->
            ?assertEqual(ThisPid, Any)
    end.

get_ggtpropid_2_test() ->
    ThisPid = self(),
    _TestPid = spawn(fun() -> 
                        ?assertThrow(
                            ggtpronameUnkownForNs,
                            koordinator:get_ggtpropid(nameA, ThisPid))
                    end),
    answer_lookup(nameA, not_found).
%-----------------

answer_lookup(ToResolvedName, ToResolvedPid) ->
    receive
        {AbsenderPid, {lookup, ToResolvedName}} ->
            case ToResolvedPid of 
                not_found ->
                    AbsenderPid ! ToResolvedPid;
                _ ->
                    AbsenderPid ! {pin, ToResolvedPid}
            end;
        Any ->
            io:fwrite("Unbekannte nachricht in answer_lookup(~p,~p): ~p", [ToResolvedName, ToResolvedPid, Any]),
            ?assert(false)
    end.

kill_pid_and_clear_this_mailbox(Pid) ->
    exit(Pid, kill),
    clear_mailbox().
clear_mailbox() ->
    receive
        _Any -> clear_mailbox()
        after 0 -> cleared
    end.

