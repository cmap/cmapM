classdef Mongo < handle
    % Mongo - Objects of this class are used to connect to a MongoDB server
    %  and to perform database operations on that server.
    properties
        h   % lib.pointer to external data
    end

    properties (Constant)
        update_upsert = uint32(1);
        update_multi  = uint32(2);
        update_basic  = uint32(4);

        index_unique     = uint32(1);
        index_drop_dups  = uint32(4);
        index_background = uint32(8);
        index_sparse     = uint32(16);
    end

    methods
        function m = Mongo(varargin)  
            % m = Mongo(...) Construct a MongoDB connection object.
            % m = Mongo()  Connect to the local host at port 27017.
            % m = Mongo(host)  Connect to the given host[:port] (string)
            % m = Mongo('replset', name)  Construct a replset connection but don't connect yet.
            % Use mongo.addSeed() to add the hosts of a replset before calling 
            % replsetConnect().
            host = '127.0.0.1:27017';
            switch (nargin)
                case 0
                    ;
                case 1
                    host = varargin{1};
                case 2
                    host = varargin{1};
                    if ~strcmp('replset', host)
                        error('Mongo:Mongo', 'Expected ''replset'' or a host for 1st argument');
                    end
                    replset_name = varargin{2};
                otherwise
                    error('Mongo:Mongo', 'Unexpected number of arguments');
            end

            m.h = libpointer('mongo_Ptr');
            calllib('MongoMatlabDriver', 'mmongo_create', m.h)
            if strcmp('replset', host)
                calllib('MongoMatlabDriver', 'mmongo_replset_init', m.h, replset_name);
            else
                calllib('MongoMatlabDriver', 'mmongo_connect', m.h, host);
            end
        end

        function delete(m)
            % Release this MongoDB connection.
            % Called automatically by Matlab when this connection object is no 
            % longer referenced.
            calllib('MongoMatlabDriver', 'mmongo_destroy', m.h);
        end

        function addSeed(m, host)
            % mongo.addSeed(host)  Add a host seed to the replset
            calllib('MongoMatlabDriver', 'mongo_add_seed', m.h, host);
        end
        
        function ok = replsetConnect(m)
            % ok = mongo.replsetConnect()  % Connect to a replset.
            % Call this after using addSeed() to establish a connection.
            % Returns logigal 1 if successful; otherwise, 0.
            ok = (calllib('MongoMatlabDriver', 'mmongo_replset_connect', m.h, host) ~= 0);
        end

        function disconnect(m)
            % mongo.disconnect()  Temporarily disconnect from the MongoDB server.
            % mongo.reconnect() may be called to restablish the connection.
            calllib('MongoMatlabDriver', 'mmongo_disconnect', m.h);
        end

        function ok = reconnect(m)
            % ok = mongo.reconnect()  Reconnect to the MongoDB server.
            % Call this to resume operations after disconnect() has been called.
            ok = (calllib('MongoMatlabDriver', 'mmongo_reconnect', m.h) ~= 0);
        end

        function b = isConnected(m)
            % b = mongo.isConnected()  Determine connection status.
            % Returns logical 1 if this object is connected to a MongoDB connection;
            % otherwise, 0.
            if isNull(m.h)
                b = false
            else
                b = (calllib('MongoMatlabDriver', 'mmongo_is_connected', m.h) ~= 0);
            end
        end

        function b = isMaster(m)
            % b = mongo.isMaster()  Determine if host reports it is a master
            b = (calllib('MongoMatlabDriver', 'mongo_is_master', m.h) ~= 0);
        end

        function b = checkConnection(m)
            % b = mongo.checkConnection()  Check the connection.
            % Returns logical 1 if isConnected() and the server could be pinged;
            % otherwise, 0.
            b = (calllib('MongoMatlabDriver', 'mmongo_check_connection', m.h) ~= 0);
        end

        function setTimeout(m, timeout)
            % mongo.setTimeout(timeout)  Set the timeout in milliseconds.
            % 0 (the default) indicates no timeout.
            calllib('MongoMatlabDriver', 'mongo_set_timeout', m.h, timeout);
        end

        function t = getTimeout(m)
            % t = getTimeout(m)  Get the timeout value in milliseconds.
            % 0 (the default) indicates no timeout.
            t = calllib('MongoMatlabDriver', 'mongo_get_timeout', m.h);
        end

        function host = getPrimary(m)
            % host = mongo.getPrimary()  Get the host to which we are connected
            % as a host:port string.
            host = calllib('MongoMatlabDriver', 'mmongo_get_primary', m.h);
        end

        function socket = getSocket(m)
            % socket = getSocket(m)  Get the TCP/IP socket handle.
            socket = calllib('MongoMatlabDriver', 'mmongo_get_socket', m.h);
        end

        function hosts = getHosts(m)
            % hosts = mongo.getHosts()  Get the hosts of a replset
            % as a cell array of strings (host:port).
            hosts = calllib('MongoMatlabDriver', 'mongo_get_hosts', m.h);
        end

        function err = getErr(m)
            % err = mongo.getErr()  Get the error code of the connection
            % object as reported by the C driver.  This may be checked if an
            % operation failed.
            err = calllib('MongoMatlabDriver', 'mmongo_get_err', m.h);
        end

        function databases = getDatabases(m)
            % databases = mongo.getDatabases()  Get a cell array of strings
            % giving the databases on the server.
            databases = calllib('MongoMatlabDriver', 'mongo_get_databases', m.h);
        end

        function collections = getDatabaseCollections(m, db)
            % collections = mongo.getDatabaseCollections(db)
            % Get a cell array of strings giving the collections that
            % belong to a database gieven the database name (string).
            collections = calllib('MongoMatlabDriver', 'mongo_get_database_collections', m.h, db);
        end

        function ok = rename(m, from_ns, to_ns)
            % ok = mongo.rename(from_ns, to_ns)  Rename a collection.
            % Returns logical 1 if successful; otherwise, 0.
            % This may also be used to move a collection to a different database.
            ok = (calllib('MongoMatlabDriver', 'mongo_rename', m.h, from_ns, to_ns) ~= 0);
        end

        function ok = insert(m, ns, b)
            % ok = mongo.insert(ns, b)  Insert a BSON document into the database.
            % The collection namespace (ns) is in the form 'database.collection'.
            % See http://www.mongodb.org/display/DOCS/Inserting
            % Returns logical 1 if successful; otherwise, 0.

            ok = (calllib('MongoMatlabDriver', 'mmongo_insert', m.h, ns, b.h) ~= 0);
        end

        function ok = update(m, ns, criteria, objNew, varargin)
            % ok = mongo.update(ns, criteria, objNew, optional flags)
            % Perform an update on the server.
            % The collection namespace (ns) is in the form 'database.collection'.
            % criteria and ObjNew are Bson objects.
            % See http://www.mongodb.org/display/DOCS/Updating
            % Returns logical 1 if successful; otherwise, 0.
            % Optional flags may be update_upsert, update_multi, or update_basic.
            flags = uint32(0);
            for f = 1 : size(varargin, 2) 
                flags = bitor(flags, varargin{f});
            end
            ok = (calllib('MongoMatlabDriver', 'mmongo_update', m.h, ns, criteria.h, objNew.h, flags) ~= 0);
        end

        function ok = put(m, name, value)
            % ok = putMat(m, name, value)  Save a value to a name
            % in collection 'Matlab.vars'  (does an upsert).
            buf = BsonBuffer();
            buf.append('name', name);
            criteria = buf.finish();
            buf = BsonBuffer();
            buf.append('name', name);
            buf.append('value', value);
            objNew = buf.finish();
            ok = m.update('Matlab.vars', criteria, objNew, Mongo.update_upsert);
        end

        function ok = remove(m, ns, criteria)
            % ok = mongo.remove(ns, criteria)  Remove documents from the server.
            % The collection namespace (ns) is in the form 'database.collection'.
            % criteria is a Bson object.
            % See http://www.mongodb.org/display/DOCS/Removing
            ok = (calllib('MongoMatlabDriver', 'mmongo_remove', m.h, ns, criteria.h) ~= 0);
        end

        function b = findOne(m, ns, query, varargin)
            % b = mongo.findOne(ns, query, optional fields)  Find a single document.
            % The collection namespace (ns) is in the form 'database.collection'.
            % query is a Bson object specifying the match criteria.
            % See http://www.mongodb.org/display/DOCS/Querying
            % Optional fields (Bson object) may be used to specify a limited set
            % of fields to be returned of the matching document.  This can cut down
            % network traffic.
            % findOne is a shortcut alternative to mongo.find(), bypassing the need 
            % to step through a result set with a cursor.
            % Returns the matching document as a Bson object if there was a match;
            % otherwise, returns the empty array [].
            if nargin > 4
                error('Mongo:findOne', 'Too many arguments')
            end
            if nargin == 4
                fields = varargin{1};
            else
               fields = Bson;
            end
            b = Bson;
            if ~calllib('MongoMatlabDriver', 'mmongo_find_one', m.h, ns, query.h, fields.h, b.h)
                b = [];
            end
        end

        function value = get(m, name)
            % value = mongo.get(name)  Retrieve a value stored with put().
            % The collection 'Matlab.vars' is searched for a document with
            % the 'name' field equal to the requested name.  If found, the
            % document's 'value' field is returned; otherwise, the empty
            % matrix.
            buf = BsonBuffer();
            buf.append('name', name);
            query = buf.finish();
            b = m.findOne('Matlab.vars', query);
            if isempty(b)
                value = [];
            else
                value = b.value('value');
            end
        end

        function list(m)
            % list(m)  list the names of the values stored in 'Matlab.vars'.
            cursor = MongoCursor();
            buf = BsonBuffer();
            buf.append('name', true);
            cursor.sort = buf.finish();
            if m.find('Matlab.vars', cursor)
                while cursor.next()
                    disp(cursor.value.value('name'));
                end
            end
        end

        function found = find(m, ns, cursor)
            % found = mongo.find(ns, cursor)  Find a set a documents mathing a query.
            % The collection namespace (ns) is in the form 'database.collection'.
            % Specify the query when constructing the cursor.
            % Example:
            %     bb = BsonBuffer;
            %     bb.append('lastname', 'Jones');
            %     query = bb.finish();
            %     cursor = MongoCursor(query);
            %     if mongo.find('test.people', cursor)
            %         while cursor.next()
            %             % do something with cursor.value()
            %             b = cursor.value();
            %             disp(b.value('firstname'));
            %         end
            %     end
            % See http://www.mongodb.org/display/DOCS/Querying
            % Also see class MongoCursor
            % Returns logical 1 if the search was successful and at least one
            % document matched the query; otherwise 0.
            if isempty(cursor.query)
                cursor.query = Bson;
            end
            if isempty(cursor.sort)
                cursor.sort = Bson;
            end
            if isempty(cursor.fields)
                cursor.fields = Bson;
            end
            cursor.mongo = m;
            found = (calllib('MongoMatlabDriver', 'mmongo_find', m.h, ns, cursor.query.h, cursor.sort.h, cursor.fields.h, ...
                             cursor.limit, cursor.skip, cursor.options, cursor.h) ~= 0);
        end

        function num = count(m, ns, varargin)
            % num = mongo.count(ns, optional query)  Count documents in a collection.
            % The collection namespace (ns) is in the form 'database.collection'.
            % if optional Bson object query is not given, all documents in the 
            % collection are counted.
            % See http://www.mongodb.org/display/DOCS/Querying
            % Example:
            %     bb = BsonBuffer;
            %     bb.append('state', 'Indiana');
            %     query = bb.finish();
            %     hoosiers = mongo.count('test.people', query);
            if nargin == 2
                query = Bson;
            elseif nargin == 3
                query = varargin{1};
            else
                error('Mongo:count', 'Unexpected number of arguments');
            end
            num = calllib('MongoMatlabDriver', 'mmongo_count', m.h, ns, query.h);
        end

        function err = indexCreate(m, ns, key, varargin)
            % err = mongo.indexCreate(ns, key, optional options)
            % Create an index on the server.
            % The collection namespace (ns) is in the form 'database.collection'.
            % key is a Bson document listing the names of the fields
            % involved in the key of the index.
            % See http://www.mongodb.org/display/DOCS/Indexes
            % Example:
            %     bb = BsonBuffer();
            %     bb.append('state', true);
            %     key = bb.finish();
            %     mongo.indexCreate('test.people', key);
            %     % created an index that makes searching by state faster
            options = uint32(0);
            for i = 1 : size(varargin, 2) 
                options = bitor(options, varargin{i});
            end
            if isa(key, 'char')
                k = BsonBuffer;
                k.append(key, true);
                key = k.finish;
            end
            err = Bson;
            if calllib('MongoMatlabDriver', 'mongo_index_create', m.h, ns, key.h, options, err.h)
                err = [];
            end
        end

        function ok = addUser(m, user, password, varargin)
            % ok = mongo.addUser(user, password, optional db='admin')  Add a user.
            % user and password are strings.
            % Optional db (string) defaults to 'admin'
            % See http://www.mongodb.org/display/DOCS/Security+and+Authentication
            db = 'admin';
            if nargin > 4
                error('Mongo:addUser', 'Unexpected number of arguments');
            elseif nargin == 4
                db = varargin{1}
            end
            ok = (calllib('MongoMatlabDriver', 'mongo_add_user', m.h, db, user, password) ~= 0);
        end


        function ok = authenticate(m, user, password, varargin)
            % ok = mongo.authenticate(user, password, optional db='admin')
            % Authenticate a user and password
            % Optional db (string) gives to the database to authenticate against.
            % Returns logical 1 if successfully authenticated; otherwise, 0.
            % See http://www.mongodb.org/display/DOCS/Security+and+Authentication
            db = 'admin';
            if nargin > 4
                error('Mongo:authenticate', 'Unexpected number of arguments');
            elseif nargin == 4
                db = varargin{1};
            end
            ok = (calllib('MongoMatlabDriver', 'mongo_authenticate', m.h, db, user, password) ~= 0);
        end


        function result = command(m, db, cmd)
            % result = mongo.command(db, cmd)  Issue a command to the server.
            % If succuessful, returns the server's response as a Bson object;
            % otherwise, an empty [].
            % This function supports any of the MongoDB database commands by allowing
            % you to specify the command object completely yourself.
            % See http://www.mongodb.org/display/DOCS/List+of+Database+Commands
            % Example:
            %     bb = BsonBuffer;
            %     bb.append('count', 'people');
            %     cmd = bb.finish;
            %     mongo.command(db, cmd)
            % This returns the count within a Bson object instead of directly as a double
            % like mongo.count() does.
            result = Bson;
            if ~calllib('MongoMatlabDriver', 'mongo_command', m.h, db, cmd.h, result.h)
                result = [];
            end
        end

        function keys = distinct(m, ns, key)
            % keys = mongo.distinct(ns, key)  Get the distinct keys of a collection.
            % The collection namespace (ns) is in the form 'database.collection'.
            % key is a string naming the field for which to return distinct values.
            pos = strfind(ns, '.');
            if isempty(pos)
                error('Mongo:distinct', 'Expected a ''.'' in the namespace');
            end
            db = substr(ns, 1, pos(1)-1);
            collection = substr(ns, pos(1)+1, length(ns)-pos(1));
            buf = BsonBuffer;
            buf.append('distinct', collection);
            buf.append('key', key);
            cmd = buf.finish;
            keys = m.command(db, cmd);
            if ~isempty(keys)
                keys = keys.value('values');
            end
        end

        function result = simpleCommand(m, db, cmdstr, arg)
            % result = mongo.simpleCommand(db, cmdstr, arg)  Issue a simple command
            % to the server which canbe specified by just a command string and an
            % argument.
            % Example:
            %     bi = mongo.simpleCommand("admin", "buildInfo", true);
            bb = BsonBuffer;
            bb.append(cmdstr, arg);
            cmd = bb.finish;
            result = m.command(db, cmd);
        end

        function err = getLastErr(m, db)
            % err = mongo.getLastErr(db)  Get the last server error.
            % This returns a Bson object decribing the error if there was one;
            % otherwise, an empty [].
            err = Bson
            if ~calllib('MongoMatlabDriver', 'mongo_get_last_err', m.h, db, err.h)
                err = [];
            end
        end

        function err = getPrevErr(m, db)
            % err = mongo.getPrevErr(db)  Get the previous server error.
            % This returns a Bson object decribing the error if there was one;
            % otherwise, an empty [].
            err = Bson
            if ~calllib('MongoMatlabDriver', 'mongo_get_prev_err', m.h, db, err.h)
                err = [];
            end
        end

        function resetErr(m, db)
            % mongo.resetErr(db)  Reset the server's error status.
            m.simpleCommand(db, 'reseterror', true);
        end

        function errNo = getServerErr(m)
            % errNo = mongo.getServerErr()  Get the server error code
            errNo = calllib('MongoMatlabDriver', 'mmongo_get_server_err', m.h);
        end

        function errStr = getServerErrString(m)
            % errStr = mongo.getServerErrString()   Get a string decribing the error
            errStr = calllib('MongoMatlabDriver', 'mmongo_get_server_err_string', m.h);
        end

        function ok = dropDatabase(m, db)
            % ok = mongo.dropDatabase(db)  Drop a database from a server.
            % db is the string name of the database.
            % Returns logical 1 if successful; otherwise, 0.
            % Example:
            %     mongo.dropDatabase('test');   % Remove the 'test' database
            ok = (calllib('MongoMatlabDriver', 'mongo_drop_database', m.h, db) ~= 0);
        end

        function ok = drop(m, ns)
            % ok = mongo.drop(ns)  Remove a collection from the server
            % The collection namespace (ns) is in the form 'database.collection'.
            % Returns logical 1 if successful; otherwise, 0.
            ok = (calllib('MongoMatlabDriver', 'mongo_drop', m.h, ns) ~= 0);
        end

        function gfs = gridFsCreate(m, db, varargin)
            % gfs = mongo.gridFsCreate(db, optional prefix)
            % Construct a GridFS object.
            % Optional prefix string (defaults 'fs') is appended to the database
            % and forms part of the collection names that are used to maintain the GridFS.
            if nargin > 3
                error('Mongo:gridFSCreate', 'Too many arguments');
            end
            if nargin == 3
                prefix = varargin{1}
            else
                prefix = 'fs';
            end
            gfs = GridFS(m, db, prefix);
        end
    end
end

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
