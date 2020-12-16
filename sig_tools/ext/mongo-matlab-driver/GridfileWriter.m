classdef GridfileWriter < handle
    % GridfileWriter - Used to write buffered data to MongoDB's GridFS
    properties
        h   % lib.pointer to external data
        gfs % hold a reference to prevent release %
    end

    methods
        function gfw = GridfileWriter(gfs, remoteName, varargin)
            % gfw = GridfileWriter(gfs, remoteName, optional contentType)
            % Contruct a Gridfile writer given a GridFS object and the
            % name of the remote file.  contentType is optional and should be
            % a MIME-type string if specified.
            if nargin > 3
                error('GridfileWriter:GridfileWriter', 'Too many arguments');
            end
            contentType = '';
            if nargin == 3
                contentType = varargin{1};
            end
            gfw.gfs = gfs;
            gfw.h = libpointer('gridfile_Ptr');
            calllib('MongoMatlabDriver', 'mongo_gridfile_writer_create', gfs.h, remoteName, contentType, gfw.h);
        end


        function write(gfw, data)
            % gfw.write(data)  write data to this GridfileWriter
            % Numeric, char, and logical arrays are supported
            calllib('MongoMatlabDriver', 'mongo_gridfile_writer_write', gfw.h, data);
        end

        function ok = finish(gfw)
            if ~isempty(gfw.h) && ~isNull(gfw.h)
                ok = (calllib('MongoMatlabDriver', 'mongo_gridfile_writer_finish', gfw.h) ~= 0);
                gfw.h = [];
            else
                ok = true;
            end
        end

        function delete(gfw)
            gfw.finish();
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