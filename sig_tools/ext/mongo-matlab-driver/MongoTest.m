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

MongoStart; % load the dll

% Test appending various array types to a Bson buffer
% and pull them out with BsonIterator.value
x = [1,2,3; 4,5,6]          % Construct a 2x3 matrix (doubles) and display
bc = BsonBuffer;            % Construct a buffer to store it in
bc.append('mat2x3', x);     % Stuff it in the buffer
z = bc.finish()             % Turn the BsonBuffer into a Bson and display that
i = z.iterator;             % Get an iterator to the Bson's 1st field
v = i.value                 % Get the value of the field pointed to by the iterator
                            % and display it for comparison

% Complex array
y = [.5, 1, 2; 0.6, 1.1, 2.1]
c = complex(x, y);
bc = BsonBuffer;
bc.append('cmat2x3', c);
z = bc.finish()
i = z.iterator;
v = i.value

% a vertical column
x = [1;2;3]
bc = BsonBuffer;
bc.append('vmat3x1', x);
z = bc.finish()
i = z.iterator;
v = i.value
v = z.value('vmat3x1.1.0')  % 2nd row 1ist col - should be successful (dotted reference)
v = z.value('vmat3x1.1')    % 2nd row - also should be successful
v = z.value('vmat3x1.3.3')  % should fail - no 4th row

% a horizontal row
x = [1,2,3]
bc = BsonBuffer;
bc.append('hmat1x3', x);
z = bc.finish()
i = z.iterator;
v = i.value

% a 3 dimensional matrix - 2x3x2
B = cat(3, [1 2 3; 4 5 6], [7 8 9; 10 11 12])
bc = BsonBuffer;
bc.append('mat2x3x2', B);
z = bc.finish()
i = z.iterator;
q = i.value

% a 3D array of floats
bc = BsonBuffer;
bc.append('smat2x3x2', single(B));  % converted to doubles in the buffer
z = bc.finish()
i = z.iterator;
q = i.value         % pull out doubles

% a 3D array of int32
bc = BsonBuffer;
bc.append('imat2x3x2', int32(B));  % stored in the buffer as 32-bit ints
z = bc.finish()
i = z.iterator;
q = i.value
class(q)

% a logical 4x4 matrix
lmat4x4 = magic(4) >= 9
bc = BsonBuffer;
bc.append('lmat4x4', lmat4x4);  % stored in the buffer as BOOLs
z = bc.finish()
i = z.iterator;
q = i.value                     % pulled out as logicals
class(q)

% Store a string in a buffer
ba = BsonBuffer;
ba.append('test', 'testing');
y = ba.finish;                  % y is used for BsonCodeWScope's scope
y.display();

% store an array of dates
ds = [now, now + 1];
bc = BsonBuffer;
bc.appendDate('dates', ds);
z = bc.finish()
i = z.iterator;
v = i.value


% Create a document with many different types of fields
bb = BsonBuffer;
bb.append('name', 'Gerald');            % string
bb.append('age', int32(48));            % int32
bb.append('city', 'Cincinnati');        % string
bb.append('foo', 5);                    % double
bb.append('boo', 'buzz');               % string
bb.append('bar', int64(2));             % int64 (LONG)
bb.appendBinary('bin', uint8(eye(5)), 1);  % BINDATA
oid = BsonOID   % Generate an OID
bb.append('oid', oid);                  % OID
bb.append('true', true');               % BOOL
bb.appendDate('date', now);             % DATE
bb.append('null', []);                  % NULL
bb.append('regex', BsonRegex('pattern', 'options'));    % REGEX
bb.appendCode('code', '{ this = is + code; }');         % CODE
bb.appendSymbol('symbol', 'symbol');    % SYMBOL
bb.append('codewscope', BsonCodeWScope('code for scope', y));   % CODEWSCOPE
bb.append('timestamp', BsonTimestamp(now, 63));         % TIMESTAMP

% Start a subobject within the buffer
bb.startObject('sub');
bb.append('baz', int32(3));     % append 2 fields to the subobject
bb.append('zip', 26);
bb.finishObject;                % and finish the subobject

bb.append('more', 'much');      % append one more string to the buffer
                                % (not part of the subobject)

w = bb.finish       % Turn the BsonBuffer into a Bson and display

i = w.find('regex');    % Get an iterator for a field by name
display(i.value);       % display the value of the field

i = w.find('notfound');   % Search for a field that won't be found
if ~isempty(i)
    error('MongoTest:Bson.find', 'should have been not found');
end

w.value('oid')      % get and display the 'oid' field
ts = w.value('timestamp')   % get and display the 'timestamp' field
class(ts.increment)         % display the class of its increment


mongo = Mongo();       % connect to a MongoDB server on the localhost
if mongo.isConnected
    primary = mongo.getPrimary  % get the host to which we are connected
    socket = mongo.getSocket  % Get the TCP/IP socket of the connection
    hosts = mongo.getHosts  % should be empty since not a replset

    db = 'test';
    % mongo.dropDatabase(db); %  Drop database 'test'

    people = sprintf('%s.people', db);  % Construct a namespace string

    mongo.drop(people);     % drop the 'test.people' collection

    mongo.insert(people, w);    % insert the collage document

    % add 5 more people to the collection
    bb = BsonBuffer;
    bb.append('name', 'Abe');
    bb.append('age', int32(32));
    bb.append('city', 'Washington');
    x = bb.finish;
    mongo.insert(people, x);

    bb = BsonBuffer;
    bb.append('name', 'Joe');
    bb.append('age', int32(35));
    bb.append('city', 'Natick');
    x = bb.finish;
    mongo.insert(people, x);

    bb = BsonBuffer;
    bb.append('name', 'Jeff');
    bb.append('age', int32(19));
    bb.append('city', 'Florence');
    x = bb.finish;
    mongo.insert(people, x);

    bb = BsonBuffer;
    bb.append('name', 'Harry');
    bb.append('age', int32(35));
    bb.append('city', 'Fort Aspenwood');
    x = bb.finish;
    mongo.insert(people, x);

    bb = BsonBuffer;
    bb.append('name', 'John');
    bb.append('age', int32(21));
    bb.append('city', 'Cincinnati');
    x = bb.finish;
    mongo.insert(people, x);

    % update Joe's document with a new one
    bb = BsonBuffer;
    bb.append('name', 'Joe');
    bb.append('age', int32(36));
    bb.append('city', 'Natick');
    x = bb.finish;          % x = objNew
    bb = BsonBuffer;
    bb.append('name', 'Joe');
    criteria = bb.finish;   % criteria = { name : 'Joe' }
    mongo.update(people, criteria, x);

    % remove all people age 19 (Jeff)
    bb = BsonBuffer;
    bb.append('age', int32(19));
    criteria = bb.finish;
    mongo.remove(people, criteria);

    % Create an index on 'test.people' (key=name)
    % using a string to give the field name of the key
    % This won't permit duplicate names
    mongo.indexCreate(people, 'name', Mongo.index_unique);

    % Create an index on 'test.people' (key=city)
    % using a Bson document to describe the key of the index
    bb = BsonBuffer;
    bb.append('city', true);
    key = bb.finish;
    mongo.indexCreate(people, key);

    % find one document matching city='Natick'
    bb = BsonBuffer;
    bb.append('city', 'Natick');
    query = bb.finish;
    result = mongo.findOne(people, query)

    % find all documents in collection 'test.people'
    % and display them
    cursor = MongoCursor();
    if mongo.find(people, cursor)
        while (cursor.next)
            display(cursor.value);
            fprintf(1, '\n');
        end
        clear cursor
    end

    % find all documents matching name='Harry'
    bb = BsonBuffer;
    bb.append('name', 'Harry');
    cursor = MongoCursor(bb.finish);
    % Return only name and city fields
    bb = BsonBuffer;
    bb.append('name', true);
    bb.append('city', true);
    cursor.fields = bb.finish;
    if mongo.find(people, cursor)
        while (cursor.next)
            display(cursor.value);
            fprintf(1, '\n');
        end
        clear cursor
    end

    % get the distinct people names
    distinct = mongo.distinct(people, 'name')

    % count the number of documents in 'test.people'
    num = mongo.count(people)

    % count them another way
    bb = BsonBuffer;
    bb.append('count', 'people');
    cmd = bb.finish;
    b = mongo.command(db, cmd)
    num = b.value('n')

    % count them using simpleCommand
    b = mongo.simpleCommand(db, 'count', 'people')
    num = b.value('n')

    % Reset server error status
    mongo.resetErr(db);

    % Force the server to report an error (debugging purposes)
    mongo.simpleCommand(db, 'forceerror', true)

    % Get the last server error as a Bson document
    mongo.getLastErr(db)

    % Cause an error another way by inserting the same key
    % twice where the index was defined as unique
    bb = BsonBuffer;
    bb.append('name', 'dupkey');
    d = bb.finish;
    mongo.insert(people, d)
    mongo.insert(people, d)

    % get a Bson document descibing the dupkey error
    mongo.getLastErr(db)

    % get the error code and descriptive string of the server error
    mongo.getServerErr
    mongo.getServerErrString

    % Get the previous error as a Bson document
    mongo.getPrevErr(db)

    % Clear the error status
    mongo.resetErr(db)

    % and verify there's no error
    err = mongo.getLastErr(db)
    if ~isempty(err)
        error('Should not have been an error on the server');
    end

    % Issue a bad query
    bb = BsonBuffer;
    bb.startObject('name');
    bb.append('$badop', true);
    bb.finishObject;
    query = bb.finish;
    mongo.findOne(people, query)
    mongo.getServerErrString % display the error string for the bad query

    % add a user to database 'admin'
    mongo.addUser('Gerald', 'P97gwep16');

    % authenticate with correct credentials
    auth = mongo.authenticate('Gerald', 'P97gwep16')

    % try authenicate with bad password
    auth = mongo.authenticate('Gerald', 'BadPass21')

    % try authenticate with bad user
    auth = mongo.authenticate('Unsub', 'BadUser67')

    % report whether we are connected to a master
    master = mongo.isMaster

    % get a list of databases on the server
    mongo.getDatabases

    % get a list of collections within database 'test'
    mongo.getDatabaseCollections(db)

    % Test out the rename command
    mongo.rename(people, 'test.rename')  % test.people -> test.rename
    mongo.rename('test.rename', people)  % test.rename -> test.people
    mongo.rename('test.noname', 'test.dontexist')  % fails

    % get the last error on the 'admin' database
    mongo.getLastErr('admin')


    % Test out GridFS
    gfs = GridFS(mongo, 'grid')  % Constuct the GridFS object

    gfs.storeFile('MongoTest.m')    % Store a couple files
    gfs.storeFile('MongoStart.m')   % to the GridFS

    gfs.removeFile('MongoTest.m')   % remove one of them

    m = [1 2 3];
    gfs.store(m, 'M')               % store a small matrix as a gridfile

    gfs.store(lmat4x4, 'lmat4x4');  % store a logical mat

    % Test GridfileWriter
    gfw = gfs.writerCreate('gfwTest');  % Set up to write to gridfile 'gfwTest'
    gfw.write(c)            % Store 2 arrays
    gfw.write(B)    
    gfw.finish()            % and finish with the writer

    % find a file in the GridFS and display the housekeeping information
    % on it.
    gf = gfs.find('MongoStart.m')
    filename = gf.getFilename
    length = gf.getLength
    chunkSize = gf.getChunkSize
    chunkCount = gf.getChunkCount
    type = gf.getContentType
    datestr(gf.getUploadDate)
    md5 = gf.getMD5
    desc = gf.getDescriptor

    % display a chunk from 'MongoStart.m'
    gf.getChunk(0)
    gf.getChunk(1) % fails (empty) %

    % Get a range of chunks (illustrative, actually only 1 chunk is
    % displayed)
    cursor = gf.getChunks(0, 1);
    while (cursor.next)
        disp(cursor.value);
    end

    % get a Gridfile describing the small matrix
    gf = gfs.find('M')
    m = [7 8 9];        % Make a buffer to read into
    gf.read(m)          % read from the gridfile into m
    m                   % display the read data

    % Get a Grifile describing 'lmat4x4'
    gf = gfs.find('lmat4x4');
    l2mat4x4 = magic(4) <= 3    % Make a buffer
    gf.read(l2mat4x4);          % Read into the buffer
    l2mat4x4                    % display it (looks like lmat4x4!)

    % Try a seek within the Gridfile
    gf.seek(4);
    lmat3x3 = magic(3) >= 4     % make a buffer
    gf.read(lmat3x3);           % read into the buffer
    lmat3x3
    gf.getPos                   % report the current position
    gf.read(lmat3x3) % fails - not enough data left to read
end
