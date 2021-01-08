classdef BsonOID
    % BsonOID - Stores a BSON ObjectID
    % See http://www.mongodb.org/display/DOCS/Object+IDs
    properties
        value   % 12 uint8 bytes representing the ObjectID
    end

    methods
        function oid = BsonOID(varargin)
            % oid = BsonOID()  Generate an ObjectID.
            % oid = BsonOID(u8)  Construct an ObjectID from 12 unit8 bytes.
            % oid = BsonOID(string)  Construct an ObjectID from a 24-digit hex string.
            if nargin == 0
                p = libpointer('uint8Ptr', zeros([1, 12], 'uint8'));
                calllib('MongoMatlabDriver', 'mongo_bson_oid_gen', p);
                oid.value = p.Value;
            elseif nargin ~= 1
                error('BsonOID:BsonOID', 'Expected 0 or 1 arguments');
            else
                parm = varargin{1};
                if isa(parm, 'uint8')
                    if numel(parm) ~= 12
                        error('BsonOID:BsonOID', 'Expected a 12-byte uint8 array');
                    end
                    oid.value = parm;
                elseif isa(parm, 'char')
                    if numel(parm) ~= 24
                        error('BsonOID:BsonOID', 'Expected a 24-digit hex string');
                    end
                    p = libpointer('uint8Ptr', zeros([1, 12], 'uint8'));
                    calllib('MongoMatlabDriver', 'mongo_bson_oid_from_string', parm, p);
                    oid.value = p.Value;
                else
                    error('BsonOID:BsonOID', 'Unexpected type: %s', class(parm))
                end
            end
        end
        
        function s = toString(oid)
            % s = oid.toString()  Get a 24-digit hex string representing this ObjectID.
            p = libpointer('uint8Ptr', oid.value);
            s = calllib('MongoMatlabDriver', 'mongo_bson_oid_to_string', p);
        end

        function display(oid)
            % oid.display()  Display this oid on the console.
            fprintf(1, '{ $oid : "%s" }\n', oid.toString());
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
