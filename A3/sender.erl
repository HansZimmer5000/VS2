-module(sender).

-export([
    start/3
]).

start(McastAddressAtom, ReceivePort, LogFile) ->
    Socket = create_socket(),
    Pid = spawn(fun() -> loop(Socket, McastAddressAtom, ReceivePort, LogFile) end),
    logge_status("Sending to ~p:~p", [McastAddressAtom, ReceivePort], LogFile),
    Pid.

create_socket() ->
    {ok, Socket} = gen_udp:open(0, [binary]),
    Socket.
% --------------------------------------------------

loop(Socket, McastAddressAtom, ReceivePort, LogFile) ->
    receive
        {send, Message} -> 
            send(Socket, McastAddressAtom, ReceivePort, Message, LogFile)
    end,
    loop(Socket, McastAddressAtom, ReceivePort, LogFile).

send(Socket, McastAddressAtom, ReceivePort, Message, LogFile) ->
    {ok, McastAddress} = inet_parse:address(atom_to_list(McastAddressAtom)),
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