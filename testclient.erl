
-module(testclient).

-include_lib("eunit/include/eunit.hrl").

%TODO        frage_nach_neuer_nnr/0,
%        erstelle_nachricht/2,
%TODO        erstelle_nachrichten_text/0,
%TODO        pruefe_nnr_und_sende_nachricht/2,
%        kalkuliere_neuen_intervall_sek/1,

%TODO       frage_nach_neuer_nachricht/0,
%TODO       empfangene_nachricht_ist_von_meinem_redakteur/2,
%TODO       logge_empfangene_nachricht/2,

%        zufalls_boolean/0,
%        element_ist_in_liste/2,
%        nachricht_zu_text/1,
%        neue_nnr_einfuegen/2

frage_nach_neuer_nnr_1_test() ->
    false.

erstelle_nachricht_1_test() ->
    NNR = 1,
    TS = vsutil:now2string(erlang:timestamp()),
    Text =  io_lib:format("hostname1, gruppe1, team1, ~s", [TS]),
    TestNachricht = [NNR, Text, TS],
    ResultNachricht = client:erstelle_nachricht(NNR, TS),
    io:fwrite("\n"),
    io:fwrite(TestNachricht),
    io:fwrite("\n"),
    io:fwrite(ResultNachricht),
    TestNachricht == ResultNachricht.



pruefe_nnr_und_sende_nachricht_1_test() ->
    false.

kalkuliere_neuen_intervall_sek_1_test() ->
    Result = client:kalkuliere_neuen_intervall_sek(2),
    case Result of
        3.0 -> true;
        2.0 -> true;
        _Else -> false
    end.

kalkuliere_neuen_intervall_sek_2_test() -> 
    2.0 = client:kalkuliere_neuen_intervall_sek("a").

kalkuliere_neuen_intervall_sek_3_test() ->
    2.0 = client:kalkuliere_neuen_intervall_sek(a).




frage_nach_neuer_nachricht_1_test() ->
    false.

empfangene_nachricht_ist_von_meinem_redakteur_1_test() ->
    false.

logge_empfangene_nachricht_1_test() ->
    false.



zufalls_boolean_1_test() ->
    case client:zufalls_boolean() of
        true -> true;
        false -> true;
        _Else -> false
    end.

element_ist_in_liste_1_test() ->
    client:element_ist_in_liste(a, [a,b]).

element_ist_in_liste_2_test() ->
    false = client:element_ist_in_liste(c, [a,b]).

element_ist_in_liste_3_test() ->
    false = client:element_ist_in_liste([],[a,b]).


neue_nnr_einfuegen_1_test() ->
    [1] = client:neue_nnr_einfuegen(1,[]).

neue_nnr_einfuegen_2_test() ->
    [1,2,3] = client:neue_nnr_einfuegen(1,[2,3]).

nachricht_zu_text_1_test() ->
    TS = {1516, 47115, 874000},
    Nachricht = [1, 
                "Test", 
                vsutil:now2string(TS),
                vsutil:now2string(TS),
                vsutil:now2string(TS),
                vsutil:now2string(TS)
                ],
    "1, Test, 15.01 21:11:55,874|, 15.01 21:11:55,874|, 15.01 21:11:55,874|, 15.01 21:11:55,874|" = client:nachricht_zu_text(Nachricht).

nachricht_zu_text_2_test() ->
    TS = {1516, 47115, 874000},
    Nachricht = [1, 
                "Test", 
                vsutil:now2string(TS)
                ],
    "1, Test, 15.01 21:11:55,874|" = client:nachricht_zu_text(Nachricht).