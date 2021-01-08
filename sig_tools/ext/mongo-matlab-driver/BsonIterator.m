classdef BsonIterator < handle
    % BsonIterator - Used to step through BSON documents

    properties
        h   % lib.pointer handle to external data
    end

    methods
        function i = BsonIterator(varargin)
            % i = BsonIterator(bson)  Create an iterator for stepping through a Bson document.
            % May be passed a Bson object or another iterator that
            % points to a subobject.
            % i = BsonIterator(iter)
            % This function is not usually called directly.  It is preferable to use
            % i = bson.iterator() or i = iter.subiterator().
            % Internally called with no arguments to create an uninitialized iterator.
            i.h = libpointer('bson_iterator_Ptr');
            if nargin > 0
                b = varargin{1};
                if isa(b, 'Bson')
                    calllib('MongoMatlabDriver', 'mongo_bson_iterator_create', b.h, i.h);
                else
                    calllib('MongoMatlabDriver', 'mongo_bson_subiterator', b.h, i.h);
                end
            end
        end

        function t = type(i)
            % t = i.type()  Returns the type of the field pointed to by this iterator. See BsonType.
            if isempty(i.h) || isNull(i.h)
                t = BsonType.EOO
            else
                t = BsonType(calllib('MongoMatlabDriver', 'mongo_bson_iterator_type', i.h));
            end
        end

        function t = next(i)
            % t = i.next()  Step this iterator to the first or next field of a Bson document.
            % Returns the BsonType of the next field or BsonType.EOO if there are no more fields
            % in the document.
            % Example:
            % i = b.iterator;
            % while (i.next())
            %     display(i.value());
            % end
            if isempty(i.h) || isNull(i.h)
                t = BsonType.EOO
            else
                t = BsonType(calllib('MongoMatlabDriver', 'mongo_bson_iterator_next', i.h));
            end
        end

        function k = key(i)
            % k = i.key()  Return the key (name) of the field pointed to by this iterator.
            k = calllib('MongoMatlabDriver', 'mongo_bson_iterator_key', i.h);
        end

        function v = value(i)
            % v = i.value()  Returns the value of the field pointed to by this iterator.
            % Multidimensional values are detected and returned as appropriate.
            % The mapping from BsonTypes to Matlab types is as follows:
            % EOO           []
            % DOUBLE        double
            % STRING        char array
            % OBJECT        complex if { "r" : real, "i" : imag } is detected;
            %                   otherwise, error.
            % BINDATA       [1, n] array of uint8 bytes.  See binaryType().
            % UNDEFINED     []
            % OID           BsonOID
            % BOOL          logical
            % DATE          double datenum
            % NULL          []
            % REGEX         BsonRegex
            % DEBREF        Deprecated (not supported)
            % CODE          char array
            % SYMBOL        char array
            % CODEWSCOPE    BsonCodeWScope
            % INT           int32
            % TIMESTAMP     BsonTimestamp
            % LONG          int64
            switch (i.type)
                case {BsonType.EOO, BsonType.UNDEFINED, BsonType.NULL}
                    v = [];
                case BsonType.DOUBLE
                    v = calllib('MongoMatlabDriver', 'mongo_bson_iterator_double', i.h);
                case {BsonType.STRING, BsonType.SYMBOL}
                    v = calllib('MongoMatlabDriver', 'mongo_bson_iterator_string', i.h);
                case BsonType.OBJECT
                    j = i.subiterator;
                    j.next;
                    success = strcmp(j.key, 'r') && j.type == BsonType.REAL;
                    if success
                        r = j.value;
                        j.next;
                        success = strcmp(j.key, 'i') && j.type == BsonType.REAL;
                        if success
                            v = complex(r, j.value);
                            success = (j.next == BsonType.EOO);
                        end
                    end
                    if ~success
                        error('BsonIterator:value', 'Iterator points to a subobject. Use subiterator().');
                    end
                case BsonType.ARRAY
                    v = calllib('MongoMatlabDriver', 'mongo_bson_array_value', i.h);
                case BsonType.BINDATA
                    s = calllib('MongoMatlabDriver', 'mongo_bson_iterator_bin_len', i.h);
                    v = zeros([1, s], 'uint8');
                    p = libpointer('uint8Ptr', v);
                    calllib('MongoMatlabDriver', 'mongo_bson_iterator_bin_value', i.h, p);
                    v = p.Value;
                case BsonType.OID
                    v = zeros([1, 12], 'uint8');
                    p = libpointer('uint8Ptr', v);
                    calllib('MongoMatlabDriver', 'mongo_bson_iterator_oid', i.h, p);
                    v = BsonOID(p.Value);
                case BsonType.BOOL
                    v = (calllib('MongoMatlabDriver', 'mongo_bson_iterator_bool', i.h) ~= 0);
                case BsonType.DATE
                    v =  719529 + calllib('MongoMatlabDriver', 'mongo_bson_iterator_date', i.h) / (1000.0 * 60 * 60 * 24);
                case BsonType.REGEX
                    v = BsonRegex(calllib('MongoMatlabDriver', 'mongo_bson_iterator_regex', i.h), ...
                                  calllib('MongoMatlabDriver', 'mongo_bson_iterator_regex_opts', i.h));
                case BsonType.DBREF
                    error('BsonIterator:value', 'No support for deprecated DBREF');
                case BsonType.CODE
                    v = calllib('MongoMatlabDriver', 'mongo_bson_iterator_code', i.h);
                case BsonType.CODEWSCOPE
                    scope = Bson();
                    calllib('MongoMatlabDriver', 'mongo_bson_iterator_code_scope', i.h, scope.h);
                    v = BsonCodeWScope(calllib('MongoMatlabDriver', 'mongo_bson_iterator_code', i.h), scope);
                case BsonType.TIMESTAMP
                    inc = int32(0);
                    [t, dummy_ih, inc] = calllib('MongoMatlabDriver', 'mongo_bson_iterator_timestamp', i.h, inc);
                    v = BsonTimestamp(719529 + t / (60.0 * 60 * 24), inc);
                case BsonType.INT
                    v = int32(calllib('MongoMatlabDriver', 'mongo_bson_iterator_int', i.h));
                case BsonType.LONG
                    v = int64(calllib('MongoMatlabDriver', 'mongo_bson_iterator_long', i.h));
                otherwise
                    error('BsonIterator:value', 'Unknown BSON type: %d', i.type);
            end
        end

        function t = binaryType(i)
            % t = i.binaryType()  Return the subtype of a binary BSON field.
            % (if this iterator points to one).
            if i.type == BsonType.BINDATA
               t = calllib('MongoMatlabDriver', 'mongo_bson_iterator_bin_type', i.h);
            else
                error('BsonIterator:binaryType', 'Expected a binary BSON field');
            end
        end

        function si = subiterator(i)
            % si = i.subiterator()  Returns an iterator to a subobject or array.
            si = BsonIterator(i);
        end

        function delete(i)
            % Release this iterator.
            % It is not necessary to called this function directly.  Matlab will call this
            % automatically when this iterator is no longer referenced.
            calllib('MongoMatlabDriver', 'mongo_bson_iterator_free', i.h);
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
