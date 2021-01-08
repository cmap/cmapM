classdef GridFS < handle
    % GridFS - Objects of this class are used to store and/or
    % access a "Grid File System" (GridFS) on a MongoDB server.
    % While primarily intended to store large documents that
    % won't fit on the server as a single BSON object,
    % GridFS may also be used to store large numbers of smaller files.
    %
    % See http://www.mongodb.org/display/DOCS/GridFS and
    % http://www.mongodb.org/display/DOCS/When+to+use+GridFS.
    %
    % Objects of class Gridfile are used to access gridfiles and read from them.
    % Objects of class GridfileWriter are used to write buffered data to the GridFS.

    properties
        h      % lib.pointer to external data
        mongo  % hold a reference to prevent release
    end

    methods
        function gfs = GridFS(m, db, varargin)
            % gfs = GridFS(m, db, optional prefix)  Construct a GridFS.
            % m is a Mongo connection object.
            % db is the name of the GirdFS database.
            % optional prefix is appended to the database name. This
            % defaults to 'fs'.
            if nargin > 3
                error('GridFS:GridFS', 'Too many arguments');
            end
            if nargin == 3
                prefix = varargin{1};
            else
                prefix = 'fs';
            end
            gfs.mongo = m;
            gfs.h = libpointer('gridfs_Ptr');
            if ~calllib('MongoMatlabDriver', 'mongo_gridfs_create', m.h, db, prefix, gfs.h)
                error('GridFS:GridFS', 'Unable to create GridFS');
            end
        end

        function delete(gfs)
            % Release this GridFS object
            calllib('MongoMatlabDriver', 'mongo_gridfs_destroy', gfs.h);
        end

        function ok = storeFile(gfs, filename, varargin)
            % ok = gfs.storeFile(filename, optional remoteName, optional contentType)
            % Copy the given file to the GridFS.
            % remoteName defaults to filename
            % contentType defaults to ''
            % Returns logical 1 if successful; otherwise, 0.
            remoteName = filename;
            contentType = '';
            if nargin > 4
                error('GridFS:storeFile', 'Too many arguments');
            end
            if nargin == 4
                contentType = varargin{2};
            end
            if nargin >= 3
                remoteName = varargin{1};
            end
            ok = (calllib('MongoMatlabDriver', 'mongo_gridfs_store_file', gfs.h, filename, remoteName, contentType) ~= 0);
        end

        function removeFile(gfs, remoteName)
            % gfs.removeFile(remoteName)  Remove a file from this GridFS.
            calllib('MongoMatlabDriver', 'mongo_gridfs_remove_file', gfs.h, remoteName)
        end

        function ok = store(gfs, data, remoteName, varargin)
            % ok = store(gfs, data, remoteName, varargin)  Store data to the GridFS.
            % Use this function to store a single item of data by name to the GridFS.
            % data may be any numeric, logical or char type including arrays.
            % Returns logical 1 if successful; otherwise, 0.
            contentType = '';
            if nargin > 4
                error('GridFS:store', 'Too many arguments');
            end
            if nargin == 4
                contentType = varargin{1};
            end
            ok = (calllib('MongoMatlabDriver', 'mongo_gridfs_store', gfs.h, data, remoteName, contentType) ~= 0);
        end


        function gfw = writerCreate(gfs, remoteName, varargin)
            % gfw = gfs.writerCreate(remoteName, optional contentType)
            % Construct a GridfileWriter object.  See that class for more information.
            contentType = '';
            if nargin > 3
                error('GridFS:writerCreate', 'Too many arguments');
            end
            if nargin == 3
                contentType = varargin{1};
            end
            gfw = GridfileWriter(gfs, remoteName, contentType);
        end

        function gf = find(gfs, query)
            % gf = gfs.find(query)  Get a Gridfile matching a query.
            % Usually this is a filename (the remoteName) string.  The query
            % may also be a bson record decribing a query on the GridFS
            % descriptors.  See Gridfile.
            gf = Gridfile();
            if class(query) == 'char'
                bb = BsonBuffer;
                bb.append('filename', query);
                query = bb.finish;
            end
            gf.gfs = gfs;
            if ~calllib('MongoMatlabDriver', 'mongo_gridfs_find', gfs.h, query.h, gf.h)
                gf = [];
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
