classdef Mongo < handle
    % Mongo A matlab class for handling MongoDb access.
    % Mongo(), Create an empty Mongo object
    %
    % Mongo(host) Connect to server host
    % Mongo(host, port) Specify alternate port.
    %
    % Example
    % m = Mongo('localhost')
    % m.getDB('test', 'username', 'pass')
    % m.getCollectionNames
    % m.getCollection('mycollection', '
    
    
    % Author: Rajiv Narayan
    
    properties (Access = private)
        host = '';
        port = 27017;
        user = '';
        password = '';
        dbname = '';
        collection = '';
        
        con = '';
        db = '';
        admin = '';
        col = '';
        cur = '';
    end
    
    % Constants
    properties(Constant = true, GetAccess=private)
        MONGO_DRIVER = fullfile(fileparts(mfilename('fullpath')),...
                                '../../../ext/jars/mongo.jar');
    end
    
    % Public methods
    methods
        function obj = Mongo(varargin)
            % Constructor
            obj.importDriver_();
            if nargin
                obj.open(varargin{:});
            end
        end
        
        function delete(obj)
            % Destructor
            try
                obj.con.close()
            catch e
            end
        end
        
        function status = open(obj, host, port)
            % Establish connection to server
            narginchk(2, 3);
            assert(ischar(host)||iscell(host), 'host should be a string or cell array');
            obj.host = host;
            if nargin>2
                assert(isequal(port, fix(abs(port))),...
                    'port must be a positive integer');
                obj.port = port;
            end
            if ~isempty(obj.host)
                if iscell(obj.host)
                    replica_set = java.util.ArrayList;
                    for ii=1:length(obj.host)
                        replica_set.add(com.mongodb.ServerAddress(obj.host{ii}, obj.port));
                    end
                    obj.con = com.mongodb.MongoClient(replica_set);
                elseif ischar(obj.host)
                    obj.con = com.mongodb.MongoClient(obj.host, obj.port);
                else
                    error('Invalid host format');
                end
            end
            status = ~isempty(obj.con);
        end
        
        function status = getDB(obj, dbname, user, password)
            % Connect to a database
            narginchk(2, 4);
            assert(ischar(dbname), 'db should be a string');
            obj.dbname = dbname;
            obj.db = obj.con.getDB(dbname);
            status = ~isempty(obj.db);
            if isequal(nargin, 4)
                status = obj.authenticateDB(user, password);
            end            
        end
        
        function status = isAuthenticated(obj)
            % Test if database is authenticated
            if obj.isAdmin()
                status = true;
            elseif ~isempty(obj.db)
                status = obj.db.isAuthenticated();
            else
                status = false;
            end
        end
        
        function dbid = getCurrentDB(obj)
            % Get current database name
            if ~isempty(obj.db)
                dbid = obj.db.getName();
            else
                error('Need to connect and authenticate to a database first');
            end
        end
        
        function status = authenticateDB(obj, user, password)
            % Authenticate to a database with supplied credentials.
            status = false;
            if ~isempty(obj.db)
                assert(ischar(user));
                assert(ischar(password));
                obj.user = user;
                obj.password = password;
                status = obj.db.authenticate(user, password);                                
            end
        end
        
        %% Admin tasks
        function status = authenticateAdmin(obj, admin_user, admin_password)
            % Authenticate as administrator
            obj.admin = obj.con.getDB('admin');
            status = obj.admin.authenticate(admin_user, admin_password);
        end
        
        function status = isAdmin(obj)
            % Test if user is administrator
            if ~isempty(obj.admin)
                status = obj.admin.isAuthenticated();
            else
                status = false;
            end
        end
        
        function status = addUser(obj, user, password, isreadonly)
            % Add a new user to the current database
            status = false;
            if obj.isAdmin && ~isempty(obj.db)
                narginchk(3, 4)
                assert(ischar(user));
                assert(ischar(password));
                if nargin < 4
                    isreadonly = false;
                end
                assert(islogical(isreadonly));
                try
                    obj.db.addUser(user, password, isreadonly);
                catch e
                    disp(e);
                    error('Error adding user')
                end
                status = true;
            else
                error('Must specify a DB and be admin to add a user');
            end
        end                
        
        function d = getDBNames(obj)
            % Get a list of databases available in the host. Note needs
            % admin access.
            
            if obj.isAdmin
                d = cell(obj.con.getDatabaseNames().toArray());
            else
                error('Needs admin access');
            end
        end
        
        function insert(obj, rec)
            % Insert a record into a collection.
            narginchk(2, 2);
            isdbo=isa(rec, 'com.mongodb.BasicDBObject');
            assert(isstruct(rec) || isdbo);
            
            if obj.isAdmin && obj.isAuthenticated && ~isempty(obj.col)
                if isdbo
                    obj.col.insert(rec);
                else
                nrow = length(rec);
                block_size = 5000;
                nblock = ceil(nrow/block_size);
                for ii=1:nblock
                    st = (ii-1)*block_size + 1;
                    stp = min(nrow, st + block_size - 1);
                    bobj = obj.makeDBObjectFromStruct_(rec(st:stp));
                    obj.col.insert(bobj);
                end
                end
            end
        end
        
        function update(obj, query, rec, is_upsert, is_multi)
            % Update fields in document(s) in a collection.            
            narginchk(3, 5);
            assert(isstruct(rec) && isequal(length(rec), 1));
            nin = nargin;
            % defaults
            if nin < 4
                is_upsert = false;
                is_multi = true;
            elseif nin <5
                is_multi = true;
            end
            assert(islogical(is_upsert));
            assert(islogical(is_multi));

            if obj.isAdmin && obj.isAuthenticated && ~isempty(obj.col)
                qobj = obj.parseQuery_(query);                
                upobj = obj.makeDBObjectFromStruct_(rec);
                % update fields, dont replace
                upobj = com.mongodb.BasicDBObject('$set', upobj);                
                obj.col.update(qobj, upobj, is_upsert, is_multi);
            end            
        end
        
        function updateFromStruct(obj, qfield, rec, is_upsert, is_multi)
            % Update a collection from a Matlab structure.
            narginchk(3, 5);
            assert(isstruct(rec));
            nin = nargin;
            % defaults
            if nin < 4
                is_upsert = false;
                is_multi = true;
            elseif nin <5
                is_multi = true;
            end
            if ischar(qfield)
                qfield = {qfield};
            end
            assert(iscell(qfield));
            nr = length(rec);
            nf = length(qfield);
            val = cell(nr, nf);
            for ii=1:nf
                val(:, ii) = {rec.(qfield{ii})};
            end
            for ii=1:nr
                qobj = obj.makeDBObjectFromKeyValue_(qfield, val(ii,:));
                upd = rmfield(rec(ii), qfield);
                obj.update(qobj, upd, is_upsert, is_multi);
            end            
        end
        
        function replace(obj, query, rec)
            % Replace document(s) in a collection that match a query.
            narginchk(3, 3);
            assert(isstruct(rec) && isequal(length(rec), 1));
            
            if obj.isAdmin && obj.isAuthenticated && ~isempty(obj.col)                
                % find all docs matching a query
                this_cur = obj.find(query, {'_id'});
                if this_cur.size 
                upobj = obj.makeDBObjectFromStruct_(rec);
                while this_cur.hasNext()
                    tgt_doc = this_cur.next;
                    obj.col.update(tgt_doc, upobj, false, false);
                end
                else
                    warning('No documents matched the query');
                end
            end
        end
        
        function dropCollection(obj)
            % Deletes current collection
            if obj.isAdmin && obj.isAuthenticated && ~isempty(obj.col)
                obj.col.drop();
                obj.col = '';
            end
        end
        
        function dropDB(obj)
            % Deletes current database
            if obj.isAdmin && obj.isAuthenticated
                obj.db.drop();
                obj.db = '';
                obj.col = '';
            end
        end
        
        function createIndex(obj, keyStruct, optStruct)
            % create indices for a collection
            narginchk(2, 3);
            if nargin < 3
                optStruct = struct([]);
            end

            assert(isstruct(keyStruct) && isstruct(optStruct));
            assert(all(ismember({'key', 'order'}, fieldnames(keyStruct))));
            
            if obj.isAdmin && obj.isAuthenticated && ~isempty(obj.col)
               nk = length(keyStruct);
               if ~isempty(optStruct)
                   assert(isequal(length(keyStruct), length(optStruct)));
               end
               for ii=1:nk
                   % default ordering is ascending
                   if ~iscell(keyStruct(ii).key)
                       kobj = obj.makeDBObjectFromKeyValue_({keyStruct(ii).key}, num2cell(keyStruct(ii).order));
                   else
                       kobj = obj.makeDBObjectFromKeyValue_(keyStruct(ii).key, num2cell(keyStruct(ii).order));
                   end
                   
                   % create the index
                   if isempty(optStruct)
                       obj.col.ensureIndex(kobj);
                   else
                       optobj = obj.makeDBObjectFromStruct_(optStruct(ii));
                       obj.col.ensureIndex(kobj, optobj);
                   end
                   
               end
            end
        end
        
        function indStruct = getIndex(obj)
            % Get all indices for a collection
            if obj.isAdmin && obj.isAuthenticated && ~isempty(obj.col)
                indobj = obj.col.getIndexInfo();
                indStruct = obj.makeStructFromDBObject_(indobj);
                % add field and sort order fields
                for ii=1:length(indStruct)
                    indStruct(ii).order = cell2mat(indStruct(ii).key.values.toArray.cell);
                    indStruct(ii).field = indStruct(ii).key.keySet.toArray.cell;
                end
            end
        end
        
        function dropIndex(obj, keys)
            % Remove indices from a collection.            
            narginchk(2, 2)
            assert(iscell(keys));
            if obj.isAdmin && obj.isAuthenticated && ~isempty(obj.col)
                for ii=1:length(keys)
                    obj.col.dropIndex(keys{ii});
                end
            end
        end
        
        %% Operations on collections
        function c = getCollectionNames(obj)
            % Get list of collections within a database
            if obj.isAuthenticated()
                c = cell(obj.db.getCollectionNames().toArray());
            else
                error('Need to connect and authenticate to a database first');
            end
        end
        
        function status = getCollection(obj, collection)
            % Connect to a collection
            narginchk(2, 2)
            assert(ischar(collection));
            if obj.isAuthenticated()
                try
                    obj.col = obj.db.getCollection(collection);
                catch e
                    disp(e)
                    error('Unable to get collection %s', collection)
                end
                status = true;
            else
                error('Need to connect and authenticate to a database first');
            end            
        end
        
        function tf = isCollection(obj, collection)
            % Check if collection(s) exist(s) in a database.
            narginchk(2, 2);
            if obj.isAuthenticated
                assert(ischar(collection) | iscell(collection),...
                    'collection should be a string or cell array');
                if ischar(collection)
                    collection = {collection};
                end
                nc = length(collection);
                tf = false(nc, 1);
                for ii=1:nc
                    tf(ii) = obj.db.collectionExists(collection{ii});
                end                
            else
                error('Need to connect and authenticate to a database first');
            end
            
        end
        
        function dbid = getCurrentCollection(obj)
            % Get current collection name
            if ~isempty(obj.col) && obj.isAuthenticated
                dbid = obj.col.getName();
            elseif ~obj.isAuthenticated
                error('Need to connect and authenticate to a database first');
            else
                error('Need to connect to a collection first');
            end
        end
                
        function len = count(obj, query)
            % count number of documents matching a query
            narginchk(1, 2);
            len = -1;
            if nargin>1
                qobj = obj.parseQuery_(query);
                if ~isempty(qobj)
                    len = obj.col.count(qobj);
                end
            else
                len = obj.col.count();
            end
        end
        
        function doc = findOne(obj, query, fields)
            % Find first document matching query
            narginchk(1, 3);
            qobj = obj.parseQuery_(query);
            if isequal(nargin, 3)
                fobj = obj.makeDBObjectFromList_(fields);
                doc = obj.col.findOne(qobj, fobj);
            elseif isequal(nargin, 2)
                doc = obj.col.findOne(qobj);
            else
                doc = obj.col.findOne;
            end
        end
        
        function d = distinct(obj, field, query)
            % find distinct values for a given field
            narginchk(2, 3);
            assert(ischar(field), 'field should be a string');
            
            if isequal(nargin, 3)
                qobj = obj.parseQuery_(query);
                d = cell(obj.col.distinct(field, qobj).toArray);
            else
                d = cell(obj.col.distinct(field).toArray);
            end
        end
        
        function cur = findFromList(obj, tgt, list, fields)
            % Find documents with a field matching a list.
            narginchk(3, 4);
            assert(ischar(tgt));
            assert(iscell(list));
            inobj = com.mongodb.BasicDBObject('$in', list);
            qobj = com.mongodb.BasicDBObject(tgt, inobj);
            
            if isequal(nargin, 3)
                cur = obj.col.find(qobj);
            else
                fobj = obj.makeDBObjectFromList_(union(tgt, fields));
                cur = obj.col.find(qobj, fobj);
            end
        end
        
        function cur = find(obj, query, fields)
            % Find documents matching a query
            narginchk(2, 3);
            qobj = obj.parseQuery_(query);
            if isequal(nargin, 3)
                fobj = obj.makeDBObjectFromList_(fields);
                cur = obj.col.find(qobj, fobj);
            else
                cur = obj.col.find(qobj);
            end
        end    
        
    end
    
    
    % Private methods
    methods(Access = private)
        function importDriver_(obj)
            % Import Mongo driver
            if ~any(strcmp(obj.MONGO_DRIVER, javaclasspath('-dynamic')))
                dbg(1, 'Importing Mongo Java driver');
                javaaddpath(obj.MONGO_DRIVER)
            end
        end
        
        function qobj = parseQuery_(obj, query)
            % Parse query input, return a DBObject
            qobj = {};
            if isequal(class(query), 'com.mongodb.BasicDBObject')
                qobj = query;
            elseif ischar(query)
                % json string
                json = com.mongodb.util.JSON();
                qobj = com.mongodb.BasicDBObject(json.parse(query));
            end            
        end
        
        function dbobj = makeDBObjectFromList_(obj, list)
            % Create DBObject from a cell array.
            % D = makeDBObjectFromList_(L) returns a BasicDBObject with the
            % value of each element in the list set to 1.
            
            dbobj = obj.makeDBObjectFromKeyValue_(list, 1);
        end

        function dbobj = makeDBObjectFromKeyValue_(obj, key, val)
            % Create DBObject from a cell array of keys and a
            % cell array of values or a scalar value.            
            nl = length(key);
            dbobj = com.mongodb.BasicDBObject(nl);
            if isequal(length(val), 1) && ~iscell(val)           
                for ii=1:nl
                    dbobj.put(key{ii}, val);
                end
            else
                for ii=1:nl
                    dbobj.put(key{ii}, val{ii});
                end
            end
        end

        function bobj = makeDBObjectFromStruct_(obj, rec)
            % Convert a Matlab structure to a BSON array object
            if ~isempty(rec)
                nr = length(rec);
                fn = fieldnames(rec);
                nf = length(fn);
                if nr>1
                    % create a java array
                    bobj = javaArray('com.mongodb.BasicDBObject', nr);
                    for ii=1:nr
                        bobj(ii) = com.mongodb.BasicDBObject();
                        for jj=1:nf
                            bobj(ii).put(fn{jj}, rec(ii).(fn{jj}));
                        end
                    end
                else
                    bobj = com.mongodb.BasicDBObject();
                    for jj=1:nf
                        bobj.put(fn{jj}, rec.(fn{jj}));
                    end
                end
                
            end
        end
        
        function s = makeStructFromDBObject_(obj, dbo)
            % Convert DBObject array to matlab structure            
            if isjava(dbo)
                nr = dbo.size;
                keyMap = containers.Map();
                lastIdx=0;
                for ii=1:nr
                    k = dbo.get(ii-1).keySet.toArray.cell;
                    k = k(~keyMap.isKey(k));
                    for jj=1:length(k)
                        keyMap(k{jj}) = lastIdx + jj;
                    end
                    lastIdx = lastIdx + length(k);
                end                
                nk = keyMap.length;
                % keylist ordered as they were inserted
                k = keyMap.keys;
                k = k(cell2mat(keyMap.values));
                kdict = containers.Map(k,1:nk);
                val = cell(nr, nk);
                for ii=1:nr
                    o = dbo.get(ii-1);
                    f = o.keySet.toArray.cell;
                    ford = kdict.values(f);
                    ford = cat(1, ford{:});
                    v = o.values.toArray.cell;
                    val(ii, ford) = v;
                end
                s = cell2struct(val, k, 2);
            else
                disp('singleton stub not implemented');
            end            
            
        end
    end
    
end
