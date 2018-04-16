-module(ggtprozess).

-export([
    go/1,
    init/2,

    calc_receive_loop/2,

    vote/4,
    kill/2,
    calc_and_send_new_mi/5,
    send_new_mi/4,
    vote_yes/1,
    start_vote/4,
    tellmi/2,
    pongGGT/2,
    calc_new_mi/2
]).

-define(CONFIG_FILENAME, "ggt.cfg").

-define(NSNODE, hole_wert_aus_config_mit_key(nameservicenode)).
-define(NSNAME, nameservice).

-define(KOORDINATORNAME, hole_wert_aus_config_mit_key(koordinatorname)).


go({GGTProName, ArbeitsZeit, TermZeit, Quota}) ->
    {KoPid, NsPid} = get_ko_and_ns_pid(GGTProName),
    go({GGTProName, ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});

go({GGTProName, ArbeitsZeit, TermZeit, Quota, NsPid, KoPid}) ->
    GlobalVariables = {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid},

    GGTProPid = spawn(fun() -> init(GGTProName, GlobalVariables) end),
    true = register(GGTProName, GGTProPid),
    logge_status(GGTProName, lists:flatten(
                                io_lib:format("gestartet mit PID ~p",[GGTProPid]))),
    GGTProPid.

get_ko_and_ns_pid(GGTProName) -> 
    net_adm:ping(?NSNODE),
    timer:sleep(timer:seconds(2)),
    case global:whereis_name(?NSNAME) of
        undefined -> 
            logge_status(GGTProName, "Nameservice global nicht gefunden, ggT faehrt runter"),
            timer:sleep(timer:seconds(5)),
            exit(kill);
        NsPid -> 
            KoPid = lookup_name_at_ns(?KOORDINATORNAME, NsPid),
            case KoPid of
                not_found -> 
                    logge_status(GGTProName, "Koordinator nicht im Nameservice bekannt, ggT faehrt runter"),
                    timer:sleep(timer:seconds(5)),
                    exit(kill);
                _ -> continue
            end
    end.

init(GGTProName, {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid}) ->
    NsPid ! {self(), {rebind, GGTProName, node()}},
    receive
        ok -> logge_status(GGTProName, "registriert und bekannt beim nameservice")
    end,
    KoPid ! {hello, GGTProName},

    receive
        {setneighbors, LeftN, RightN} ->  
            logge_status(GGTProName, io_lib:format("Nachbarn bekommen: ~p (Left) ~p (Right)",[LeftN, RightN])),

            LeftPid = lookup_name_at_ns(LeftN, NsPid),
            RightPid = lookup_name_at_ns(RightN, NsPid),

            case LeftPid of 
                not_found -> logge_status(GGTProName, "LeftN Pid not_found in nameservice"), exit(kill);
                _ -> continue
            end,
            case RightPid of 
                not_found -> logge_status(GGTProName, "RightN Pid not_found in nameservice"), exit(kill);
                _ -> continue
             end
    end,
    receive {setpm, NewMi} -> logge_status(GGTProName, io_lib:format("Pm bekommen: ~p",[NewMi])) end,
    
    calc_receive_loop({GGTProName, NewMi, {LeftPid, RightPid}, empty}, 
                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid}).

lookup_name_at_ns(Name, NsPid) ->
    NsPid ! {self(), {lookup, Name}},
    receive
        {pin, Pid} -> Pid;
        not_found -> not_found
    end.

term_receive_loop({GGTProName, Mi, Neighbors, OldMissingCountForQuota}, 
                {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid}) ->
    case OldMissingCountForQuota of
        0 -> term(KoPid, GGTProName, Mi),
             MissingCountForQuota = empty;
        _ -> MissingCountForQuota = OldMissingCountForQuota
    end,
    receive
        {InitiatorPid, {vote, InitiatorName}} -> vote(InitiatorPid, InitiatorName, GGTProName, true),
                                                term_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                                {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {voteYes, OtherGGTProName} ->   logge_status_vote_yes(GGTProName, OtherGGTProName),
                                        NewMissingCountForQuota = vote_yes(MissingCountForQuota),
                                        term_receive_loop({GGTProName, Mi, Neighbors, NewMissingCountForQuota},
                                                        {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {sendy, Y} ->               logge_status(GGTProName, io_lib:format("Korrektur Y = ~p erhalten", [Y])),
                                    timer:sleep(timer:seconds(ArbeitsZeit)),
                                    NewMi = calc_and_send_new_mi(Mi, Y, Neighbors, GGTProName, KoPid),
                                    calc_receive_loop({GGTProName, NewMi, Neighbors, empty},
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {setpm, NewMi} ->           logge_status(GGTProName, io_lib:format("Starte neue Berechnung mit Mi = ~p", [NewMi])),
                                    calc_receive_loop({GGTProName, NewMi, Neighbors, empty}, 
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {AbsenderPid, tellmi} ->    tellmi(AbsenderPid, Mi),
                                    term_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {AbsenderPid, pingGGT} ->   pongGGT(AbsenderPid, GGTProName),
                                    term_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        kill -> kill(GGTProName, NsPid);
        Any ->  logge_status(GGTProName, io_lib:format("Got unkonwn: ~p", [Any])),
                term_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid})
    end.

term(KoPid, GGTProName, Mi) ->
    KoPid ! {self(), briefterm, {GGTProName, Mi, vsutil:now2string(erlang:timestamp())}},
    logge_status(GGTProName, "Genuegend Votes bekommen, briefterm gesendet").

calc_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota}, 
                {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid}) ->
    receive
        {InitiatorPid, {vote, InitiatorName}} ->vote(InitiatorPid, InitiatorName, GGTProName, false),
                                                calc_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                                {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {voteYes, OtherGGTProName} ->   logge_status_vote_yes(GGTProName, OtherGGTProName),
                                        NewMissingCountForQuota = vote_yes(MissingCountForQuota),
                                        calc_receive_loop({GGTProName, Mi, Neighbors, NewMissingCountForQuota},
                                                        {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {sendy, Y} ->               timer:sleep(timer:seconds(ArbeitsZeit)),
                                    NewMi = calc_and_send_new_mi(Mi, Y, Neighbors, GGTProName, KoPid),
                                    calc_receive_loop({GGTProName, NewMi, Neighbors, empty},
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {AbsenderPid, tellmi} ->    tellmi(AbsenderPid, Mi),
                                    calc_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {AbsenderPid, pingGGT} ->   pongGGT(AbsenderPid, GGTProName),
                                    calc_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        kill -> kill(GGTProName, NsPid);
        Any ->  logge_status(GGTProName, io_lib:format("Got unkonwn: ~p", [Any])),
                calc_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid})

        after timer:seconds(round(TermZeit/2)) ->  calc_vote_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                            {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid})
    end.

calc_vote_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota}, 
                {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid}) ->
    receive
        {InitiatorPid, {vote, InitiatorName}} -> vote(InitiatorPid, InitiatorName, GGTProName, true),
                                                calc_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                                {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {voteYes, OtherGGTProName} ->   logge_status_vote_yes(GGTProName, OtherGGTProName),
                                        NewMissingCountForQuota = vote_yes(MissingCountForQuota),
                                        calc_receive_loop({GGTProName, Mi, Neighbors, NewMissingCountForQuota},
                                                        {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {sendy, Y} ->               timer:sleep(timer:seconds(ArbeitsZeit)),
                                    NewMi = calc_and_send_new_mi(Mi, Y, Neighbors, GGTProName, KoPid),
                                    calc_receive_loop({GGTProName, NewMi, Neighbors, empty},
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {AbsenderPid, tellmi} ->    tellmi(AbsenderPid, Mi),
                                    calc_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        {AbsenderPid, pingGGT} ->   pongGGT(AbsenderPid, GGTProName),
                                    calc_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                                    {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid});
        kill -> kill(GGTProName, NsPid);
        Any ->  logge_status(GGTProName, io_lib:format("Got unkonwn: ~p", [Any])),
                calc_receive_loop({GGTProName, Mi, Neighbors, MissingCountForQuota},
                                {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid})

        after timer:seconds(round(TermZeit/2)) ->   NewMissingCountForQuota = start_vote(GGTProName, Mi, NsPid, Quota),
                                                    term_receive_loop({GGTProName, Mi, Neighbors, NewMissingCountForQuota},
                                                            {ArbeitsZeit, TermZeit, Quota, NsPid, KoPid})
    end.

vote(InitiatorPid, InitiatorName, GGTProName, WillRespond) ->
    logge_status_vote(GGTProName, InitiatorName, WillRespond),
    case WillRespond of 
        true -> InitiatorPid ! {voteYes, GGTProName};
        false -> donothing
    end.

calc_and_send_new_mi(Mi, Y, Neighbors, GGTProName, KoPid) ->
    NewMi = calc_new_mi(Mi, Y),
    case NewMi of
        Mi ->   ok;
        _Any -> send_new_mi(NewMi, Neighbors, GGTProName, KoPid)
    end,
    NewMi.

calc_new_mi(Mi, Y) -> 
    case Mi > Y of
        true -> NewMi = ((Mi - 1) rem Y) + 1;
        false -> NewMi = Mi
    end,
    NewMi.

send_new_mi(NewMi, {LeftN, RightN}, GGTProName, KoPid) ->
    LeftN ! {sendy, NewMi},
    RightN ! {sendy, NewMi},
    KoPid ! {briefmi, {GGTProName, NewMi, vsutil:now2string(erlang:timestamp())}}.

vote_yes(MissingCountForQuota) ->
    case MissingCountForQuota of
        empty -> NewMissingCountForQuota = empty;
        _Any -> NewMissingCountForQuota = MissingCountForQuota - 1
    end,
    NewMissingCountForQuota.

tellmi(ReceiverPid, Mi) ->
    ReceiverPid ! {mi, Mi}.

pongGGT(ReceiverPid, GGTProName) ->
    ReceiverPid ! {pongGGT, GGTProName}.

kill(GGTProName, NsPid) ->
    NsPid ! {self(), {unbind, GGTProName}},
    receive
        ok -> ok
    end,

    case whereis(GGTProName) of
        undefined -> ok; %Only for Test purposes! Because since its in the same process the name is always registered during normal run until unregistered here.
        _Any -> unregister(GGTProName)
    end,
    logge_status(GGTProName, "ist heruntergefahren").

start_vote(GGTProName, Mi, NsPid, Quota) ->
    logge_status(GGTProName, lists:flatten(io_lib:format("mit ~p (Mi) wird vote gestartet", [Mi]))),
    NsPid ! {self(), {multicast, vote, GGTProName}},
    MissingCountForQuota = Quota,
    MissingCountForQuota.

hole_wert_aus_config_mit_key(Key) ->
    {ok, ConfigListe} = file:consult(?CONFIG_FILENAME),
    {ok, Value} = vsutil:get_config_value(Key, ConfigListe),
    Value.

logge_status_vote(GGTProName1, GGTProName2, WillRespond) ->
    logge_status(GGTProName1, lists:flatten(io_lib:format("Vote from ~p, voteYes send: ~p", [GGTProName2, WillRespond]))).

logge_status_vote_yes(GGTProName1, GGTProName2) ->
    logge_status(GGTProName1, lists:flatten(io_lib:format("VoteYes from ~p", [GGTProName2]))).

logge_status(GGTProName, Inhalt) ->
    LogDateiName = lists:flatten(io_lib:format("~p.log", [GGTProName])),
    AktuelleZeit = vsutil:now2string(erlang:timestamp()),
    LogNachricht = io_lib:format("~p ~p ~s.\n", [GGTProName, AktuelleZeit, Inhalt]),
    io:fwrite(LogNachricht),
    util:logging(LogDateiName, LogNachricht).