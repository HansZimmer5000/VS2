-module(sender).

-export([
    start/5,

    start_sending_process/9
]).

% -------------------- Init --------------------------
start(InterfaceAddress,  McastAddress, ReceivePort, ClockPid, LogFile) ->
    Socket = create_socket(InterfaceAddress, ReceivePort),
    Pid = spawn(fun() -> loop(Socket, McastAddress, ReceivePort, ClockPid, LogFile) end),
    logge_status("Sending to ~p:~p", [McastAddress, ReceivePort], LogFile),
    Pid.

% ------------------- Loop ---------------------------

loop(Socket, McastAddress, ReceivePort, ClockPid, LogFile) ->
    receive
        {send, IncompleteMessage, Payload} -> 
	    ClockPid ! {getcurrenttime, self()},
	    receive 
		{currenttime, SendTime} -> 
			Message = messagehelper:prepare_incomplete_message_for_sending(IncompleteMessage, SendTime, Payload),
    		logge_status("Sende Nachricht", LogFile),
			send(Socket, McastAddress, ReceivePort, Message, LogFile)
	    end
    end,
    loop(Socket, McastAddress, ReceivePort, ClockPid, LogFile).

% ------------------ Exported Functions --------------
start_sending_process(CorePid, SendPid, FrameStart, SlotNumber, StationType, ClockPid, SlotFinderPid, PayloadServerPid, LogFile) ->
    spawn(fun() -> 
            {MessageWasSend, NextSlotNumber} = sending_process(SendPid, FrameStart, SlotNumber, StationType, ClockPid, SlotFinderPid, PayloadServerPid, LogFile),
            CorePid ! {messagewassend, MessageWasSend, NextSlotNumber}
        end).


% ------------------ Internal Functions --------------
create_socket(InterfaceAddress, ReceivePort) ->
        %vsutil:openSe(InterfaceAddress, ReceivePort).
        {ok, Socket} = gen_udp:open(0, [binary]),
        Socket.

sending_process(SendPid, FrameStart, SlotNumber, StationType, ClockPid, SlotFinderPid, PayloadServerPid, LogFile) ->
    SendtimeMS = notify_when_preperation_and_send_due(ClockPid, FrameStart, SlotNumber, LogFile),
    logge_status("SendTimeMS at ~p",  [SendtimeMS], LogFile),
    {MessageWasSend, NextSlotNumber}= wait_for_prepare(StationType, SendtimeMS, ClockPid, SlotFinderPid, PayloadServerPid, SendPid, LogFile),
    {MessageWasSend, NextSlotNumber}.

notify_when_preperation_and_send_due(ClockPid, FrameStart, SlotNumber, _LogFile) ->
    ClockPid ! {calcslotmid, FrameStart, SlotNumber, self()},
    receive
        {resultslotmid, SendtimeMS} ->
            ClockPid ! {alarm, preperation, SendtimeMS - 20, self()},
            ClockPid ! {alarm, send, SendtimeMS - 10, self()}
    end,
    SendtimeMS.

wait_for_prepare(StationType, SendtimeMS, ClockPid, SlotFinderPid, PayloadServerPid, SendPid, LogFile) ->
    receive
        preperation ->
            %Lassen wir vorerst drin, dann kann man evtl. noch eine Idee leichter umsetzen.
            {MessageWasSend, NextSlotNumber} = wait_for_send(SendtimeMS, StationType, SlotFinderPid, ClockPid, PayloadServerPid, SendPid, LogFile)
        after 980 ->
            logge_status("Timeout preperation", LogFile),
            MessageWasSend = false,
            NextSlotNumber = 0
    end,
    {MessageWasSend, NextSlotNumber}.

wait_for_send(SendtimeMS, StationType, SlotFinderPid, ClockPid, PayloadServerPid, SendPid, LogFile) ->
    receive
        send ->
            ClockPid ! {getcurrenttime, self()},
            receive
                {currenttime, CurrentTime} ->
                    {MessageWasSend, NextSlotNumber} = check_sendtime_and_send(
                                        SendtimeMS, CurrentTime, StationType, SlotFinderPid, PayloadServerPid, SendPid, LogFile)
                after 980 ->
                    logge_status("Timeout resultdifftime", LogFile),
                    NextSlotNumber = 0,
                    MessageWasSend = false
            end
        after 980 ->
            logge_status("Timeout send", LogFile),
            NextSlotNumber = 0,
            MessageWasSend = false
    end,
    {MessageWasSend, NextSlotNumber}.

check_sendtime_and_send(SendtimeMS, CurrentTime, StationType, SlotFinderPid, PayloadServerPid, SendPid, LogFile) ->
    logge_status("~p (Seti) ~p (Now)", [SendtimeMS, CurrentTime], LogFile),
    DiffTime = SendtimeMS - CurrentTime,
    case DiffTime of
        DiffTime when DiffTime > 0 -> 
            logge_status("SendTime in the future: ~p", [DiffTime], LogFile),
            timer:sleep(DiffTime - 2), % little bit earlier, because Payload and Slotfinder will take some time to get
            NextSlotNumber = send_message(StationType, SlotFinderPid, PayloadServerPid, SendPid, LogFile),
            MessageWasSend = true;
        DiffTime when DiffTime < 0 -> 
            logge_status("SendTime in the past: ~p", [DiffTime], LogFile),
            NextSlotNumber = 0,
            MessageWasSend = false; 
        DiffTime -> 
            logge_status("SendTime is now: ~p", [DiffTime], LogFile),
            NextSlotNumber = send_message(StationType, SlotFinderPid, PayloadServerPid, SendPid,LogFile),
            MessageWasSend = true
    end,
    {MessageWasSend, NextSlotNumber}.

send_message(StationType, SlotFinderPid, PayloadServerPid, SendPid, LogFile) ->
    logge_status("Frage nach Payload", LogFile),
    Payload = request_payload(PayloadServerPid, LogFile),
    NextSlotNumber = request_nextslotnumber(SlotFinderPid, LogFile),
    IncompleteMessage = messagehelper:create_incomplete_message(StationType, NextSlotNumber),
    SendPid ! {send, IncompleteMessage, Payload},
    NextSlotNumber.

request_payload(PayloadServerPid, LogFile) ->
	    StartTime = vsutil:getUTC(),
            PayloadServerPid ! {self(), getNextPayload},
            receive
                {payload, Payload} ->
		    logge_status("Took ~p to get Payload", [vsutil:getUTC() - StartTime], LogFile),
                    Payload
            end.

request_nextslotnumber(SlotFinderPid, LogFile) ->
    SlotFinderPid ! {getFreeSlotNum, self()},
    receive 
        {slotnum, NextSlotNumber} -> 
            NextSlotNumber,
            logge_status("Got NextSlotnumber ~p", [NextSlotNumber], LogFile)
    end,
    NextSlotNumber.

send(Socket, McastAddress, ReceivePort, Message, LogFile) ->
    ReturnVal = gen_udp:send(Socket, McastAddress, ReceivePort, Message),
    logge_status("sended with: ~p", [ReturnVal], LogFile).

%------------------------------------------
logge_status(Text, Input, LogFile) ->
    Inhalt = io_lib:format(Text,Input),
    logge_status(Inhalt, LogFile).

logge_status(Inhalt, LogFile) ->
    AktuelleZeit = vsutil:now2string(erlang:timestamp()),
    LogNachricht = io_lib:format("~p - Send ~s.\n", [AktuelleZeit, Inhalt]),
    io:fwrite(LogNachricht),
    util:logging(LogFile, LogNachricht).