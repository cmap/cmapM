classdef BsonType < uint32
    % BsonType - An enumeration of the types of fields with BSON documents.
    enumeration
        EOO         (0) % End Of Object
        DOUBLE      (1)
        STRING      (2)
        OBJECT      (3)
        ARRAY       (4)
        BINDATA     (5)
        UNDEFINED   (6)
        OID         (7)
        BOOL        (8)
        DATE        (9)
        NULL        (10)
        REGEX       (11)
        DBREF       (12) % Deprecated. %
        CODE        (13)
        SYMBOL      (14)
        CODEWSCOPE  (15)
        INT         (16)
        TIMESTAMP   (17)
        LONG        (18)
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
