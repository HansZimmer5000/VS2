Zu dem Paket gehoeren die Datein:
    - core.erl
    - messagehelper.erl
    - payloadserver.erl
    - receiver.erl
    - sender.erl
    - slotfinder.erl
    - station.erl
    - utcclock.erl

Sowie Dateien vom Professor ("util.erl" und "vsutil.erl") und die Datenquelle.

------------------------
Starten der Applikation:
------------------------
Wenn Python auf dem Windows Gerät vorhanden ist kann man auch:
python startall.py 
    Compiled alle .erl Dateien mit "erl -make".
    Danach werden alle .beam Dateien (außer nameservice.beam und *util.beam) geloescht.
    Ist dazu gedacht, schnell zu pruefen ob alle Dateien compilen.
python startall.py 0
    Siehe ohne Parameter
python startall.py 1
    Compiled alle .erl Dateien und fuehrt alle Tests aus.
    Loescht danach alle .beam (Ausnahmen siehe ohne Paramter) Dateien.
python startall.py 2
    Compiled alle .erl Dateien.
    Leert dann alle vorhandenen .log Dateien.
    Fuehrt die Applikation aus.
python startall.py 3
    Loescht alle .beam (Ausnahmen siehe ohne Paramter), .dump, .log Dateien.
    Raeumt quasi den Ordner auf, so dass nur noch bestimmte .beam Dateien, .cfg und .erl Dateien übrig bleiben.


--------------------
Starten der Station:
--------------------
1> station:start([InterfaceNameAtom, McastAddressAtom, ReceivePortAtom, StationClassAtom, UTCoffsetMsAtom, StationNumberAtom]).





