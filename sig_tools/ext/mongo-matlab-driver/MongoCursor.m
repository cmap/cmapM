classdef MongoCursor < handle
    % MongoCursor - Used to step through matching documents.
    % Example:
    %     % Display alphabetically names of people age 18.
    %     bb = BsonBuffer;
    %     bb.append('age', int32(18));
    %     query = bb.finish();
    %     cursor = MongoCursor(query);
    %     bb = BsonBuffer;
    %     bb.append('name', true);
    %     cursor.sort = bb.finish();
    %     if mongo.find('test.people', cursor)
    %         while cursor.next()
    %             b = cursor.value();
    %             disp(b.value('name'));
    %         end
    %         clear cursor
    %     end
    properties
        h   % lib.pointer to external data
        query  % The query to match against
        sort   % Any sort to be applied to the results
        fields % bson object describing a subset of fields to be returned
        mongo  % hold a reference to prevent release %
        limit   = int32(0)  % Number of documents to return. 0 default = all.
        skip    = int32(0)  % Number of documents to skip
        options = uint32(0) % Options to be applied to the search
    end

    properties (Constant)
        % Options:
        tailable   = uint32(2);   % Create a tailable cursor. %
        slave_ok   = uint32(4);   %*< Allow queries on a non-primary node. %
        no_timeout = uint32(16);  %*< Disable cursor timeouts. %
        await_data = uint32(32);  %*< Momentarily block for more data. %
        exhaust    = uint32(64);  %*< Stream in multiple 'more' packages. %
        partial    = uint32(128); %*< Allow reads even if a shard is down. %
    end

    methods
        function cursor = MongoCursor(varargin)
            % cursor = MongoCursor()  Construct a cursor with an empty query
            % which will match all documents in a collection.
            % cursor = MongoCursor(query)  Construct a cursor and
            % initialize the query (Bson object) property to that given.
            % Manually initialize the other properties yourself before
            % calling mongo.find().
            cursor.h = libpointer('mongo_cursor_Ptr');
            if nargin > 1
                error('MongoCursor:MongoCursor', 'Too many arguments');
            elseif nargin == 1
                cursor.query = varargin{1};
            end
        end

        function more = next(cursor)
            % more = cursor.next()  Advance to the next record of the result set.
            % Returns logical 1 if there was another document; otherwise, 0.
            more = (calllib('MongoMatlabDriver', 'mmongo_cursor_next', cursor.h) ~= 0);
        end

        function v = value(cursor)
            % v = cursor.value()  Return the current document of the result set.
            v = Bson;
            if ~calllib('MongoMatlabDriver', 'mongo_cursor_value', cursor.h, v.h)
                v = [];
            end
        end

        function delete(cursor)
            % Release this cursor.  MongoCursor objects should be cleared after use so
            % that resources attached to the cursor may be released on both the client
            % and server ends.
            if ~isNull(cursor.h)
                calllib('MongoMatlabDriver', 'mongo_cursor_free', cursor.h);
            end
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
