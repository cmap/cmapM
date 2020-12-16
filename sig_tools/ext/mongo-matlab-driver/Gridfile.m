classdef Gridfile < handle
    % Gridfile - Used to access data stored in MongoDB's GridFS file system.
    properties
        h    % lib.pointer to external data
        gfs  % hold a reference to prevent release
    end

    methods
        function gf = Gridfile()
            % Used internally.  Use GridFS.find() to create these objects.
            gf.h = libpointer('gridfile_Ptr');
        end

        function filename = getFilename(gf)
            % filename = gf.getFilename()  Get the filename of this gridfile
            filename = calllib('MongoMatlabDriver', 'mongo_gridfile_get_filename', gf.h);
        end

        function length = getLength(gf)
            % length = gf.getLength()  Get the content length in bytes of this gridfile.
            length = calllib('MongoMatlabDriver', 'mongo_gridfile_get_length', gf.h);
        end

        function chunkSize = getChunkSize(gf)
            % chunkSize = gf.getChunkSize()  Get the size of the chunks of this gridfile.
            chunkSize = calllib('MongoMatlabDriver', 'mongo_gridfile_get_chunk_size', gf.h);
        end

        function count = getChunkCount(gf)
            % count = gf.getChunkCount()  Get the number of chunks of this gridfile.
            count = calllib('MongoMatlabDriver', 'mongo_gridfile_get_chunk_count', gf.h);
        end

        function type = getContentType(gf)
            % type = gf.getContentType()  Get the content type of this gridfile.
            type = calllib('MongoMatlabDriver', 'mongo_gridfile_get_content_type', gf.h);
        end

        function date = getUploadDate(gf)
            % date = gf.getUploadDate()  Get the date this gridfile was created.
            date = calllib('MongoMatlabDriver', 'mongo_gridfile_get_upload_date', gf.h);
        end

        function md5 = getMD5(gf)
            % md5 = gf.getMD5()  Get the MD5 hash of this gridfile
            md5 = calllib('MongoMatlabDriver', 'mongo_gridfile_get_md5', gf.h);
        end

        function b = getDescriptor(gf)
            % b = gf.getDescriptor()  Get the descriptor of this gridfile as a BSON document.
            b = Bson;
            calllib('MongoMatlabDriver', 'mongo_gridfile_get_descriptor', gf.h, b.h);
        end

        function b = getMetadata(gf)
            % b = gf.getMetadata()  Get any metadata associated with this gridfile
            % as a BSON document.  Returns [] if this is none.
            b = Bson;
            if ~calllib('MongoMatlabDriver', 'mongo_gridfile_get_metadata', gf.h, b.h)
                b = [];
            end
        end

        function b = getChunk(gf, i)
            % b = gf.getChunk(i)  Get the ith chunk of data of this gridfile as a BSON document.
            % field 'data' of the document contains the actual data as a BsonType.BINDATA field.
            b = Bson;
            if ~calllib('MongoMatlabDriver', 'mongo_gridfile_get_chunk', gf.h, i, b.h)
                b = [];
            end
        end

        function cursor = getChunks(gf, start, count)
            % cursor = gf.getChunks(start, count)  Get a cursor to step through a range of chunks.
            % start is the 0-based index of the first chunk to retrieve.  count is the number.
            % Usage:
            %    cursor = gf.getChunks(5, 10);
            %    while (cursor.next())
            %       b = cursor.value();
            %       i = b.find('data');
            %       % do something with i.value
            %    end
            cursor = MongoCursor();
            calllib('MongoMatlabDriver', 'mongo_gridfile_get_chunks', gf.h, start, count, cursor.h);
        end

        function ok = read(gf, data)
            % ok = gf.read(data)  Read data from this gridfile.
            % Preallocate data to be the appropriate type, size, and dimensions.
            % Example:
            %     data = zeros([3,4]);
            %     gf.read(data)   % Read 12 doubles as a 3x4 matrix.
            % Returns logical 1 if there were enough bytes left to be read; otherwise, 0.
            % No partial read is done if there were not enough bytes remaining.
            ok = (calllib('MongoMatlabDriver', 'mongo_gridfile_read', gf.h, data) ~= 0);
        end

        function pos = seek(gf, offset)
            % pos = gf.seek(offset)  Set the offset at which to read data from this gridfile.
            pos = calllib('MongoMatlabDriver', 'mongo_gridfile_seek', gf.h, offset);
        end

        function pos = getPos(gf)
            % Get the position at which reading will be done on this gridfile.
            % gf.read() advances the position by the size of the data read.
            pos = calllib('MongoMatlabDriver', 'mongo_gridfile_get_pos', gf.h);
        end

        function delete(gfw)
            % Release this gridfile.
            % It is not necessary to call this function explicitly as it will be
            % called by Matlab automatically with this gridifle is no longer referenced.
            calllib('MongoMatlabDriver', 'mongo_gridfile_destroy', gfw.h);
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
