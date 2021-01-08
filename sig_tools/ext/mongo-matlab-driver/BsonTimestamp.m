classdef BsonTimestamp
    % BsonTimestamp - Used for BsonType.TIMESTAMP
    % Objects of this class are detected by BsonBuffer.append() and
    % returned by Bson.value() and BsonIterator.value().
    properties
        date        % The date of this timestamp (double datenum)
        increment   % The increment of this timestamp (int32)
    end
    methods
        function bts = BsonTimestamp(date_, increment_)
            bts.date = date_;
            bts.increment = increment_;
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
