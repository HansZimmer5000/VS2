-module(receiver).

-export([
    start/3,
    start/4,
    
    loop/3,
    listen_to_slot/3,

    collision_happend/3,
    send_to_core/5
]).

-define(NSNODE, hole_wert_aus_config_mit_key(node)).
-define(NSNAME, nameservice).

-define(SLOTLENGTHMS, 40).


start(CorePid, StationName, LogFile) ->
    start(CorePid, StationName, LogFile, {?NSNAME, ?NSNODE}).

start(CorePid, StationName, LogFile, NsPid) ->
    Pid = spawn(fun() -> loop(CorePid, StationName, LogFile) end),
    NsPid ! {enlist, Pid},
    logge_status("starte", LogFile),
    Pid.

% --------------------------------------------------

loop(CorePid, StationName, LogFile) ->
    receive
        {udp, _Socket0, _Ip0, _Port0, Message} ->
            logge_status("Missed Message: ~p in loop", [Message], LogFile);
        listentoslot -> 
            listen_to_slot(CorePid, StationName, LogFile);
        Any -> 
            logge_status("Got: ~p in loop", [Any], LogFile)
    end,
    loop(CorePid, StationName, LogFile).

listen_to_slot(CorePid, StationName, LogFile) ->
    ConvertedSlotMessages = get_converted_slot_messages(LogFile),

    {CollisionHappend, StationWasInvolved} = collision_happend(ConvertedSlotMessages, StationName, LogFile),
    send_to_core(ConvertedSlotMessages, CollisionHappend, StationWasInvolved, CorePid, LogFile).

get_converted_slot_messages(LogFile) ->
    %Start = vsutil:getUTC(),
    %timer:send_after(?SLOTLENGTHMS, self(), stop_listening),
    {SlotMessages, ReceivedTimes} = listen(40, [], [], LogFile),
    %logge_status("Converting at ~p length: ~p", [vsutil:getUTC() rem 10000, (vsutil:getUTC() - Start) rem 10000], LogFile),
    ConvertedSlotMessages = messagehelper:convert_received_messages_from_byte(SlotMessages, ReceivedTimes),
    ConvertedSlotMessages.

listen(RestTime, SlotMessages, ReceivedTimes, _LogFile) when RestTime =< 0 ->
    {SlotMessages, ReceivedTimes};
listen(RestTime, SlotMessages, ReceivedTimes, LogFile) ->
    StartListeningAt = vsutil:getUTC(),
    receive
        {udp, _Socket0, _Ip0, _Port0, Message} -> 
            NewSlotMessages = [Message | SlotMessages],
            NewReceivedTimes = [vsutil:getUTC() | ReceivedTimes],
            EndingListeningAt = vsutil:getUTC(),
            ElapsedTime = EndingListeningAt - StartListeningAt,
            NewRestTime = RestTime - ElapsedTime,
            listen(NewRestTime, NewSlotMessages, NewReceivedTimes, LogFile);
        Any -> 
            logge_status("Got: ~p in listen_to_slot", [Any], LogFile),
            EndingListeningAt = vsutil:getUTC(),
            ElapsedTime = EndingListeningAt - StartListeningAt,
            NewRestTime = RestTime - ElapsedTime,
            listen(NewRestTime, SlotMessages, ReceivedTimes, LogFile)
        after RestTime ->
            {SlotMessages, ReceivedTimes}
    end.

collision_happend(ConvertedSlotMessages, StationName, LogFile) ->
    %If a message is handled as received in slot X but was meant for slot Y (X <> Y) its a collision.
    case length(ConvertedSlotMessages) of
        0 -> {false, false};
        1 -> {false, false};
        _Any -> 
            StationWasInvolved = station_was_involved(ConvertedSlotMessages, StationName, LogFile),
            {true, StationWasInvolved}
    end.

send_to_core(ConvertedSlotMessages, CollisionHappend, StationWasInvolved, CorePid, LogFile) ->
    case CollisionHappend of
        true ->
            CorePid ! {slotmessages, [], StationWasInvolved},

            %TODO: make better logging for this, don't print all the messages just the necessary infos
            logge_status("(Involved: ~p) Collision detected in: ~p", [StationWasInvolved, ConvertedSlotMessages], LogFile);
        false ->
            CorePid ! {slotmessages, ConvertedSlotMessages, StationWasInvolved}
    end.


station_was_involved([], StationName, LogFile) ->
    logge_status("Wasn't Involved: ~p", [StationName], LogFile),
    false;
station_was_involved(ConvertedSlotMessages, StationName, LogFile) ->
    [FirstConvertedSlotMessage | RestConvertedSlotMessages] = ConvertedSlotMessages,
    MessageStationName = messagehelper:get_station_name(FirstConvertedSlotMessage),
    case string:equal(MessageStationName, StationName) of
        true ->
            logge_status("Was Involved: ~p ~p", [StationName, messagehelper:get_station_name(FirstConvertedSlotMessage)], LogFile),
            true;
        false ->
            station_was_involved(RestConvertedSlotMessages, StationName, LogFile)
    end.    

%------------------------------------------
logge_status(Text, Input, LogFile) ->
    Inhalt = io_lib:format(Text,Input),
    logge_status(Inhalt, LogFile).

logge_status(Inhalt, LogFile) ->
    AktuelleZeit = vsutil:now2string(erlang:timestamp()),
    LogNachricht = io_lib:format("~p - Recv ~s.\n", [AktuelleZeit, Inhalt]),
    io:fwrite(LogNachricht),
    util:logging(LogFile, LogNachricht).

hole_wert_aus_config_mit_key(Key) ->
    {ok, ConfigListe} = file:consult('nameservice.cfg'),
    {ok, Value} = vsutil:get_config_value(Key, ConfigListe),
    Value.

