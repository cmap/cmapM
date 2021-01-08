%MKSQLITE Eine MATLAB Schnittstelle zu SQLite
%  SQLite ist eine Embedded SQL Engine, welche ohne Server SQL Datenbanken
%  innerhalb von Dateien verwalten kann. MKSQLITE bietet die Schnittstelle
%  zu dieser SQL Datenbank.
%
% Genereller Aufruf:
%  dbid = mksqlite([dbid, ] SQLBefehl [, Argument])
%    Der Parameter dbid ist optional und wird nur dann benötigt, wenn mit
%    mehreren Datenbanken gleichzeitig gearbeitet werden soll. Wird dbid
%    weggelassen, so wird automatisch die Datenbank Nr. 1 verwendet.
%
% Funktionsaufrufe:
%  mksqlite('open', 'datenbankdatei')
% oder
%  dbid = mksqlite(0, 'open', 'datenbankdatei')
% Öffnet die Datenbankdatei mit dem Dateinamen "datenbankdatei". Wenn eine
% solche Datei nicht existiert wird sie angelegt.
% Wenn eine dbid angegeben wird und diese sich auf eine bereits geöffnete
% Datenbank bezieht, so wird diese vor Befehlsausführung geschlossen. Bei
% Angabe der dbid 0 wird die nächste freie dbid zurück geliefert.
%
%  mksqlite('close')
% oder
%  mksqlite(dbid, 'close')
% oder
%  mksqlite(0, 'close')
% Schliesst eine Datenbankdatei. Bei Angabe einer dbid wird diese Datenbank
% geschlossen. Bei Angabe der dbid 0 werden alle offenen Datenbanken
% geschlossen.
%
%  mksqlite('SQL-Befehl')
% oder
%  mksqlite(dbid, 'SQL-Befehl')
% Führt SQL-Befehl aus.
%
% Beispiel:
%  mksqlite('open', 'testdb.db3');
%  result = mksqlite('select * from testtable');
%  mksqlite('close');
% Liest alle Felder der Tabelle "testtable" in der Datenbank "testdb.db3"
% in die Variable "result" ein.
%
% Beispiel:
%  mksqlite('open', 'testdb.db3')
%  mksqlite('show tables')
%  mksqlite('close')
% Zeigt alle Tabellen in der Datenbank "testdb.db3" an.
%
% (c) 2008 by Martin Kortmann <mail@kortmann.de>
%

