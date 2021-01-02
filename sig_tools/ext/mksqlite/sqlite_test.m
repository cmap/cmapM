function mksqlite_test ()

database = 'my_testdb';
table = 'testtabelle';

NumOfSamples = 100000;

try
    delete (database);
catch
    error ('Konnte db nicht löschen');
end

% Datenbank öffnen
mksqlite('open', database);
mksqlite('PRAGMA synchronous = OFF');

% Testtabelle erzeugen
fprintf ('Erstelle neue Tabelle\n');
mksqlite(['create table ' table ' (Eintrag char(32), GrosserFloat double, KleinerFloat float, Zahl int, Zeichen tinyint, Boolean bit, VieleZeichen char(255))']);

disp ('------------------------------------------------------------');

fprintf ('Erstelle %d Einträge in einer Transaction\n', NumOfSamples);
% Einträge erstellen
VieleZeichen = '12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
tic;
mksqlite('begin');
try
    for idx=1:NumOfSamples
        mksqlite(['insert into ' table ' (Eintrag, GrosserFloat, VieleZeichen) values (''' sprintf('Eintrag_%d', idx) ''', ' num2str(idx) ', ''' VieleZeichen ''')']);
    end
catch
end
mksqlite('commit');
toc
fprintf ('Einträge erstellt\n');

fprintf ('Frage Anzahl der Einträge ab\n')
res = mksqlite(['select count(*) as anzahl from ' table]);
fprintf ('select count(*) liefert als Ergebnis %d\n', res.anzahl);

fprintf ('Summiere alle Werte zwischen 10 und 75 auf\n');
res = mksqlite(['select sum(GrosserFloat) as summe from ' table ' where GrosserFloat between 10 and 75']);
fprintf ('sum liefert %d\n', res.summe);

disp ('------------------------------------------------------------');
mksqlite('close');
mksqlite('open', database);

disp ('Lese alle Records in ein Array ein');
tic;
res = mksqlite(['SELECT * FROM ' table]);
a = toc;
fprintf ('fertig, %f sekunden = %d Records pro Sekunde\n', a, int32(NumOfSamples/a));
disp ('fertig.');

% Datenbank weder schliessen
mksqlite('close');

% Datenbank in memory kopieren

disp (' ');
disp ('-- In Memory test --');

disp ('kopieren Datenbank in memory');
% In mem Datenbank erstellen
mksqlite('open', ':memory:');

% Original attachen
mksqlite(['ATTACH DATABASE ''' database ''' AS original']);
mksqlite('begin');
% Alle Tabellen kopieren
tables = mksqlite('SELECT name FROM original.sqlite_master WHERE type = ''table''');
for idx=1:length(tables)
    mksqlite(['CREATE TABLE ''' tables(idx).name ''' AS SELECT * FROM original.''' tables(idx).name '''']);
end
% Alle Inicies kopieren
tables = mksqlite('SELECT sql FROM original.sqlite_master WHERE type = ''index''');
for idx=1:length(tables)
    mksqlite(tables(idx).sql);
end
% Original Detachen
mksqlite('commit');
mksqlite('DETACH original');
disp ('kopieren fertig.');

% Nun den Test inmemory durchführen
fprintf ('Frage Anzahl der Einträge ab\n')
res = mksqlite(['select count(*) as anzahl from ' table]);
fprintf ('select count(*) liefert als Ergebnis %d\n', res.anzahl);

fprintf ('Summiere alle Werte zwischen 10 und 75 auf\n');
res = mksqlite(['select sum(GrosserFloat) as summe from ' table ' where GrosserFloat between 10 and 75']);
fprintf ('sum liefert %d\n', res.summe);
disp ('Lese alle Records in ein Array ein');
tic;
res = mksqlite(['SELECT * FROM ' table]);
a = toc;
fprintf ('fertig, %f sekunden = %d Records pro Sekunde\n', a, int32(NumOfSamples/a));
disp ('fertig.');
mksqlite('close');
