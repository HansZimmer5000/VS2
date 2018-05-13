-module(payloadserver).
-export([
	start/3, 
	send/1,
	receive_loop/1
]).

-define(SERVERNAME, payloadserver).

-define(TEAMNUMBER, "06").

start(CoreNode, StationNumberString, LogFile) ->
	CoreNodeString = atom_to_list(CoreNode),

	ServerPid = start_payload_server(LogFile),
	VesselPid = start_vessel(CoreNodeString, StationNumberString, LogFile),

	logge_status("PayloadserverPID: ~p // Vessel3 with Send Pipe PID: ~p", [self(), VesselPid], LogFile),
	ServerPid.

start_payload_server(LogFile) ->
	ServerPid = spawn(fun() -> receive_loop(LogFile) end),
	register(payloadserver, ServerPid),
	ServerPid.

start_vessel(CoreNodeString, StationNumberString, LogFile) ->
	CommandString = create_vessel_command_string(CoreNodeString, StationNumberString, LogFile),
	logge_status(CommandString, LogFile),
	VesselPid = spawn(fun() -> os:cmd(CommandString) end),
	VesselPid.

send([CoreNode, LogFile]) ->
	logge_status(CoreNode, LogFile),
	case net_adm:ping(CoreNode) of
		pong ->
			logge_status("Found Payloadserver: ~p", [CoreNode], LogFile),
			ServerPid = {?SERVERNAME, CoreNode},
			send_loop(ServerPid, LogFile);
		_Any ->
			logge_status("Couldn't find Payloadserver!", LogFile)
	end.

send_loop(PayloadServerPid, LogFile) ->
	Text = io:get_chars('', 24),
	%Text = "team 06-01-1234567890123",
	%logge_status("Got ~p ~n", [Text], LogFile),
	PayloadServerPid ! Text,
	send_loop(PayloadServerPid, LogFile).

% Bekommt alle Payloads, verwirft sie direkt ausser:
% Wenn aktueller Payload angefragt bekommt der Absender den nächsten empfangenen Payload
receive_loop(LogFile) ->
	receive
		{AbsenderPid, getNextPayload} ->
			%logge_status("Next Payload to: ~p", [AbsenderPid], LogFile),
			receive
				eof ->
					logge_status("Got eof", LogFile);
				Payload ->
					logge_status("Sending Payload ~s to: ~p", [Payload, AbsenderPid], LogFile),
					AbsenderPid ! {payload, Payload}
			end;
		_Any ->
			nothing%logge_status("got: ~p\n", [Any], LogFile)
	end,
	receive_loop(LogFile).

create_vessel_command_string(CoreNodeString, StationNumberString, LogFile) ->
	_Macerlcommand = "cd /Users/hapemac/Repo/TalDerTraenen/a3 && java vessel3.Vessel " ++ ?TEAMNUMBER ++ 
					" " ++ StationNumberString ++ " | " ++
					"erl -noshell -sname team-" ++ ?TEAMNUMBER ++ "-" ++ StationNumberString ++ 
					"-pipe -noshell -s payloadserver send " ++ CoreNodeString ++ " " ++ LogFile,
    %_CommandStringMac = "osascript -e " + "'" + "tell application " ++ atom_to_list('"') ++ "Terminal" ++ '"' ++ " to do script " ++ '"' ++ Macerlcommand ++ '"' ++ "'",
	CommandString = "noah Gegeben/datasource/64bit/Vessel3 " ++ ?TEAMNUMBER ++ " " ++ StationNumberString ++ 
					" | erl -sname team-" ++ ?TEAMNUMBER ++ "-" ++ StationNumberString ++ 
					"-pipe -noshell -s payloadserver send " ++ CoreNodeString ++ " " ++ LogFile,
	CommandString.

%------------------------------------------
logge_status(Text, Input, LogFile) ->
    Inhalt = io_lib:format(Text,Input),
    logge_status(Inhalt, LogFile).

logge_status(Inhalt, LogFile) ->
    AktuelleZeit = vsutil:now2string(erlang:timestamp()),
    LogNachricht = io_lib:format("~p ---- PYLD ~s.\n", [AktuelleZeit, Inhalt]),
    io:fwrite(LogNachricht),
    util:logging(LogFile, LogNachricht).