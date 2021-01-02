%    Copyright 2009-2011 10gen Inc.
%
%    Licensed under the Apache License, Version 2.0 (the "License");
%    you may not use this file except in compliance with the License.
%    You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
%    Unless required by applicable law or agreed to in writing, software
%    distributed under the License is distributed on an "AS IS" BASIS,
%    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%    See the License for the specific language governing permissions and
%    limitations under the License.

% MongoSample.m
%
% A sample Matlab script
%
% First, we add 3 documents to the collection 'mongoquest.Spells'
% Each of these documents represents a spell with a name and a level.
% 2nd, we do a normal query/find loop to display the names of the level 1 spells.
% 3rd, we update each document to include a flavor field.
% and lastly, we run another query loop to display both names and flavors of the level 1 spells.

MongoStart;
m = Mongo('vitalstatistix:27017');
if ~m.isConnected()
   error('MongoSample:MongoSample', 'No connection');
end

db = 'mongoquest';
ns = sprintf('%s.Spells', db);  % Construct a namespace string

buf = BsonBuffer();
buf.append('name', 'Poke');
buf.append('level', 1);
m.insert(ns, buf.finish());
buf = BsonBuffer();
buf.append('name', 'Zap');
buf.append('level', 1);
m.insert(ns, buf.finish());
buf = BsonBuffer();
buf.append('name', 'Blast');
buf.append('level', 2);
m.insert(ns, buf.finish());

% At level 1, we only know level 1 spells.
disp('Level 1 spell list:');
buf = BsonBuffer();
buf.append('level', 1);
cursor = MongoCursor(buf.finish());
if m.find(ns, cursor)
    while cursor.next()
        b = cursor.value();
        disp(sprintf('name: %s', b.value('name')));
    end
 end
  

% Since these spells aren't very exciting, let's add a little flavor
% to each of them.
buf = BsonBuffer();
buf.append('name', 'Poke');
criteria = buf.finish();
buf = BsonBuffer();
buf.startObject('$set');
buf.append('flavor', 'Snick snick!');
buf.finishObject();
objNew = buf.finish();
m.update(ns, criteria, objNew);

buf = BsonBuffer();
buf.append('name', 'Zap');
criteria = buf.finish();
buf = BsonBuffer();
buf.startObject('$set');
buf.append('flavor', 'Bzazt!');
buf.finishObject();
objNew = buf.finish();
m.update(ns, criteria, objNew);

buf = BsonBuffer();
buf.append('name', 'Blast');
criteria = buf.finish();
buf = BsonBuffer();
buf.startObject('$set');
buf.append('flavor', 'PWOOM!');
buf.finishObject();
objNew = buf.finish();
m.update(ns, criteria, objNew);

% This time we query again, with flavor!

disp('Level 1 spell list with flavor:');
buf = BsonBuffer();
buf.append('level', 1);
cursor = MongoCursor(buf.finish());
if m.find(ns, cursor)
    while cursor.next()
        b = cursor.value();
        disp(sprintf('name:   %s', b.value('name')));
        disp(sprintf('flavor: %s', b.value('flavor')));
    end
 end

% Since this is an example, we'll clean up after ourselves.
m.drop(ns);

  