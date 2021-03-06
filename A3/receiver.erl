-module(receiver).

-export([
    start/8,
    create_socket/3
]).

-define(SLOTLENGTHMS, 40).

% -------------------- Init --------------------------
start(CorePid, ClockPid, SlotFinderPid, StationName, InterfaceAddress, McastAddress, ReceivePort,LogFile) ->
    Socket = create_socket(InterfaceAddress, McastAddress, ReceivePort),
    HandlerPid = spawn(fun() -> listen_loop(CorePid, ClockPid, SlotFinderPid, StationName, LogFile) end),
    _Receive_loop = spawn(fun() -> receive_loop(HandlerPid, ClockPid, Socket,LogFile) end),
    logge_status("Listening to ~p:~p", [McastAddress, ReceivePort], LogFile),
    HandlerPid.
    
% --------------------------------------------------
receive_loop(HandlerPid, ClockPid, Socket, LogFile) -> 
    case gen_udp:recv(Socket, 0) of
        {ok, {_Address, _Port, Message}} ->
            ClockPid ! {getcurrenttime, self()},
            receive
                {currenttime, CurrentTime} ->
                    HandlerPid ! {receivedmessage, Message, CurrentTime},
 		    logge_status("Got Message", LogFile)
            end;
        {error, _Reason} ->
            nothing
    end,
    receive_loop(HandlerPid, ClockPid, Socket, LogFile).

listen_loop(CorePid, ClockPid, SlotFinderPid, StationName, LogFile) ->
    receive
	listentoframe -> 
		listen_to_slots_and_adjust_clock_and_slots(25, ClockPid, SlotFinderPid, CorePid, StationName, LogFile)
    end,
    listen_loop(CorePid, ClockPid, SlotFinderPid, StationName, LogFile).

% ---------- Internal Functions -------------
listen_to_slots_and_adjust_clock_and_slots(0, _ClockPid, _SlotFinderPid, _CorePid, _StationName, _LogFile) ->
    done;
listen_to_slots_and_adjust_clock_and_slots(RestSlotCount, ClockPid, SlotFinderPid, CorePid, StationName, LogFile) ->
    %StartTime = vsutil:getUTC(),
    timer:send_after(39 ,self(),stoplistening),
    {ReceivedMessages, ReceivedTimes} = listen_to_slot([],[], LogFile),
    spawn(fun() -> 
            %logge_status("Received ~p Messages this slot", [length(ReceivedMessages)], LogFile),
            case length(ReceivedMessages) of
                0 ->
                    CorePid ! {stationwasinvolved, false};
                _Any ->
                    ConvertedMessages = messagehelper:convert_received_messages_from_byte(ReceivedMessages, ReceivedTimes),
                    {CollisionHappend, StationWasInvolved} = collision_happend(ConvertedMessages, StationName, LogFile),
                    case CollisionHappend of
                        true -> 
                            CorePid ! {stationwasinvolved, StationWasInvolved};
                        false ->
			    logge_status("Now Sending to the pids", LogFile),
                            ClockPid ! {adjust, ConvertedMessages},
                            SlotFinderPid ! {newmessages, ConvertedMessages},
                            CorePid ! {stationwasinvolved, StationWasInvolved}
                    end
            end
        end),
    %logge_status("Took ~p for Slot", [vsutil:getUTC() - StartTime], LogFile),
    listen_to_slots_and_adjust_clock_and_slots(RestSlotCount - 1, ClockPid, SlotFinderPid, CorePid, StationName, LogFile).

create_socket_klc(InterfaceAddress, McastAddress, ReceivePort) ->
    vsutil:openRec(McastAddress, InterfaceAddress, ReceivePort).

create_socket(InterfaceAddress, McastAddress, ReceivePort) ->
        {ok, Socket} = gen_udp:open(ReceivePort, [
            {mode, binary},
            {reuseaddr, true},
            {ip, McastAddress}, %may use Mcast
            {multicast_ttl, 1},
            {multicast_loop, true},
            {broadcast, true},
            {add_membership, {McastAddress, InterfaceAddress}},
            {active, false}]), %once = dann mit receive Any -> ... end holen
        Socket.
    
listen_to_slot(Messages, ReceivedTimes, LogFile) ->
    %logge_status("Waiting for next receivedmessage", LogFile),
    receive
	stoplistening ->
	    {Messages, ReceivedTimes};
        {receivedmessage, Message, ReceivedTime} ->
            NewMessages = [Message | Messages],
            NewReceivedTimes = [ReceivedTime | ReceivedTimes],
            listen_to_slot(NewMessages, NewReceivedTimes, LogFile)
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

