classdef Bson < handle
    % Bson - Binary JSON class
    % Objects of class "mongo.bson" are used to store BSON documents.
    % BSON is the form that MongoDB uses to store documents in its database.
    % MongoDB network traffic also uses BSON in messages.
    %
    % See http://www.mongodb.org/display/DOCS/BSON

    properties
        h   % lib.pointer handle to external data
    end

    methods (Static)
        function display_(i, depth)
            % Internal display function (called by display())
            while i.next()
                t = i.type;
                if t == BsonType.EOO
                    break;
                end
                for j = 1:depth
                    fprintf(1, '\t');
                end
                fprintf(1, '%s (%d) : ', i.key, int32(t));
                switch (t)
                    case BsonType.DOUBLE
                       fprintf(1, '%f', i.value);
                    case {BsonType.STRING, BsonType.SYMBOL, BsonType.CODE}
                        fprintf(1, '%s', i.value);
                    case BsonType.OID
                        fprintf(1, '%s', i.value.toString());
                    case BsonType.BOOL
                        if i.value
                            fprintf(1, 'true');
                        else
                            fprintf(1, 'false');
                        end
                    case BsonType.DATE
                        fprintf(1, '%s', datestr(i.value));
                    case BsonType.BINDATA
                        fprintf(1, 'BINDATA\n');
                        disp(i.value);
                    case BsonType.UNDEFINED
                        fprintf(1, 'UNDEFINED');
                    case BsonType.NULL
                        fprintf(1, 'NULL');
                    case BsonType.REGEX
                        r = i.value;
                        fprintf(1, '%s, %s', r.pattern, r.options);
                    case BsonType.CODEWSCOPE
                        c = i.value;
                        fprintf(1, 'CODEWSCOPE %s\n', c.code);
                        Bson.display_(c.scope.iterator, depth+1);
                    case BsonType.TIMESTAMP
                        ts = i.value;
                        fprintf(1, '%s (%d)', datestr(ts.date), ts.increment);
                    case {BsonType.INT, BsonType.LONG}
                        fprintf(1, '%d', i.value);
                    case {BsonType.OBJECT, BsonType.ARRAY}
                        fprintf(1, '\n');
                        Bson.display_(i.subiterator, depth+1);
                    otherwise
                        fprintf(1, 'UNKNOWN');
                end
                fprintf(1, '\n');
            end
        end

        function b = empty()
            % b = empty()  Construct an empy BSON document.
            b = Bson;
            calllib('MongoMatlabDriver', 'mongo_bson_empty', b.h);
        end
    end

    methods
        function b = Bson()
            % b = Bson()  Construct a null Bson document.
            % Mainly used internally, but may be used to specify an empty
            % BSON document argument to some functions.
            b.h = libpointer('bson_Ptr');
        end

        function s = size(b)
            % s = b.size()  Returns the size of this BSON document in bytes.
            if isNull(b.h)
                error('Bson:size', 'Uninitialized BSON');
            end
            s = calllib('MongoMatlabDriver', 'mongo_bson_size', b.h);
        end

        function i = iterator(b)
            % i = b.iterator()  Returns a BsonIterator that points to beginning of this BSON.
            if isNull(b.h)
                error('Bson:iterator', 'Uninitialized BSON');
            end
            i = BsonIterator(b);
        end

        function i = find(b, name)
            % i = b.find(name)  Search this document for a field of the given name.
            % If found, returns a BsonIterator that points to the field;
            % otherwise, returns empty ([]).
            % name may also be a dotted reference to a subfield.  For
            % example: v = b.value("address.city");
            if isNull(b.h)
                error('Bson:find', 'Uninitialized BSON');
            end
            i = BsonIterator;
            if ~calllib('MongoMatlabDriver', 'mongo_bson_find', b.h, name, i.h)
                i = [];
            end
        end

        function v = value(b, name)
            % v = b.value(name)  Returns the value of a field within this BSON.
            % Returns empty ([]) if the name is not found.
            % name may also be a dotted reference to a subfield.  For
            % example: v = b.value("address.city");
            i = b.find(name);
            if isempty(i)
                v = [];
            else
                v = i.value;
            end
        end

        function display(b)
            % b.display()  Display this BSON document.
            if ~isNull(b.h)
                b.display_(b.iterator, 0);
            end
        end

        function delete(b)
            % Release this BSON document.
            % It is not necessary to call this function by user code;
            % it will be called automatically by Matlab when the
            % document is no longer referenced.
            calllib('MongoMatlabDriver', 'mongo_bson_free', b.h);
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

