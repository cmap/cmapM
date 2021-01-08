/**    Copyright 2009-2011 10gen Inc.
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */
#include "MongoMatlabDriver.h"
#include "gridfs.h"

#include <mex.h>

EXPORT int mongo_gridfs_create(struct mongo_* conn, char* db, char* prefix, struct gridfs_** gfs) {
    gridfs* gfs_ = (gridfs*)malloc(sizeof(gridfs));
    if (gridfs_init((mongo*)conn, db, prefix, gfs_) != MONGO_OK) {
        free(gfs_);
        return 0;
    }
    *gfs = (struct gridfs_*)gfs_;
    return 1;
}


EXPORT void mongo_gridfs_destroy(struct gridfs_* gfs) {
    if (gfs)
        gridfs_destroy((gridfs*) gfs);
}


EXPORT int  mongo_gridfs_store_file(struct gridfs_* gfs, char* filename, char* remoteName, char* contentType) {
    return (gridfs_store_file((gridfs*)gfs, filename, remoteName, contentType) == MONGO_OK);
}


EXPORT void mongo_gridfs_remove_file(struct gridfs_* gfs, char* remoteName) {
    gridfs_remove_filename((gridfs*)gfs, remoteName);
}


static void* calcSize(mxArray* data, uint64_t* size) {

    uint64_t numel = mxGetNumberOfElements(data);
    switch (mxGetClassID(data)) {
        case mxLOGICAL_CLASS: ;
        case mxINT8_CLASS:
        case mxUINT8_CLASS:
            *size = numel;
            return mxGetData(data);
        case mxCHAR_CLASS:
            *size = numel * sizeof(mxChar);
            return mxGetChars(data);
        case mxDOUBLE_CLASS:
            *size = numel * sizeof(double);
            return mxGetPr(data);
        case mxSINGLE_CLASS:
            *size = numel * sizeof(float);
            return mxGetData(data);
        case mxINT16_CLASS:
        case mxUINT16_CLASS:
            *size = numel * sizeof(short);
            return mxGetData(data);
        case mxINT32_CLASS:
        case mxUINT32_CLASS:
            *size = numel * sizeof(int);
            return mxGetData(data);
        case mxINT64_CLASS:
        case mxUINT64_CLASS:
            *size = numel * sizeof(int64_t);
            return mxGetData(data);
        default: {
            char s[256];
            sprintf(s, "GridFS - Unsupported type (%s)\n", mxGetClassName(data));
            mexErrMsgTxt(s);
            return 0;
        }
    }
}


EXPORT int  mongo_gridfs_store(struct gridfs_* gfs, mxArray* data, char* remoteName, char* contentType) {
    uint64_t size;
    void* p;
    if (mxIsComplex(data))
        mexErrMsgTxt("GridFS:store - Complex values not supported");
    p = calcSize(data, &size);
    return (gridfs_store_buffer((gridfs*)gfs, (char*)p, size, remoteName, contentType) == MONGO_OK);
}


EXPORT void mongo_gridfile_writer_create(struct gridfs_* gfs, char* remoteName, char* contentType, struct gridfile_** gf) {
    gridfile* gf_ = (gridfile*)malloc(sizeof(gridfile));
    gridfile_writer_init(gf_, (gridfs*)gfs, remoteName, contentType);
    *gf = (struct gridfile_*)gf_;
}


EXPORT void mongo_gridfile_writer_write(struct gridfile_* gf, mxArray* data) {
    uint64_t size;
    void* p;
    int cplx = mxIsComplex(data);
    if (cplx && mxGetClassID(data) != mxDOUBLE_CLASS)
        mexErrMsgTxt("GridfileWriter:write - only complex values of type double are supported");
    p = calcSize(data, &size);
    gridfile_write_buffer((gridfile*)gf, (char*)p, size);
    if (cplx)
        gridfile_write_buffer((gridfile*)gf, (char*)mxGetPi(data), size);
}


EXPORT int  mongo_gridfile_writer_finish(struct gridfile_* gf) {
    return (gridfile_writer_done((gridfile*)gf) == MONGO_OK);
}


EXPORT int  mongo_gridfs_find(struct gridfs_* gfs, struct bson_* query, struct gridfile_** gf) {
    gridfile* gf_ = (gridfile*)malloc(sizeof(gridfile));
    if (gridfs_find_query((gridfs*)gfs, (bson*)query, gf_) != MONGO_OK) {
        free(gf_);
        return 0;
    }
    *gf = (struct gridfile_*)gf_;
    return 1;
}


EXPORT void mongo_gridfile_destroy(struct gridfile_* gf) {
    if (gf) {
        gridfile_destroy((gridfile*)gf);
        free(gf);
    }
}


EXPORT const char* mongo_gridfile_get_filename(struct gridfile_* gf) {
    return gridfile_get_filename((gridfile*)gf);
}


EXPORT double mongo_gridfile_get_length(struct gridfile_* gf) {
    return (double)gridfile_get_contentlength((gridfile*)gf);
}


EXPORT int mongo_gridfile_get_chunk_size(struct gridfile_* gf) {
    return gridfile_get_chunksize((gridfile*)gf);
}


EXPORT int mongo_gridfile_get_chunk_count(struct gridfile_* gf) {
    return gridfile_get_numchunks((gridfile*)gf);
}


EXPORT const char* mongo_gridfile_get_content_type(struct gridfile_* gf) {
    return gridfile_get_contenttype((gridfile*)gf);
}


EXPORT double mongo_gridfile_get_upload_date(struct gridfile_* gf) {
    return 719529 + gridfile_get_uploaddate((gridfile*)gf) / (1000.0 * 60 * 60 * 24);
}


EXPORT const char* mongo_gridfile_get_md5(struct gridfile_* gf) {
    return gridfile_get_md5((gridfile*)gf);
}


EXPORT void mongo_gridfile_get_descriptor(struct gridfile_* gf, struct bson_** out) {
    bson* b = (bson*)malloc(sizeof(bson));
    bson_copy(b, ((gridfile*)gf)->meta);
    *out = (struct bson_*) b;
}


int mongo_gridfile_get_metadata(struct gridfile_* gf, struct bson_** out) {
    bson meta, *b;
    gridfile_get_metadata((gridfile*)gf, &meta);
    if (bson_size(&meta) <= 5)
        return 0;
    b = (bson*)malloc(sizeof(bson));
    bson_copy(b, &meta);
    *out = (struct bson_*) b;
    return 1;
}


int mongo_gridfile_get_chunk(struct gridfile_* gf, int i, struct bson_** out) {
    bson chunk, *b;
    gridfile_get_chunk((gridfile*)gf, i, &chunk);
    if (bson_size(&chunk) <= 5)
        return 0;
    b = (bson*)malloc(sizeof(bson));
    *b = chunk;
    *out = (struct bson_*)b;
    return 1;
}


EXPORT int mongo_gridfile_get_chunks(struct gridfile_* gf, int start, int count, struct mongo_cursor_** out) {
    mongo_cursor* cursor = gridfile_get_chunks((gridfile*)gf, start, count);
    if (!cursor)
        return 0;
    *out = (struct mongo_cursor_*)cursor;
    return 1;
}


EXPORT int mongo_gridfile_read(struct gridfile_* gf, mxArray* data) {
    gridfile* gf_ = (gridfile*)gf;
    uint64_t size;
    void* p;
    gridfs_offset remaining;
    int cplx = mxIsComplex(data);
    if (cplx && mxGetClassID(data) != mxDOUBLE_CLASS)
        mexErrMsgTxt("Gridfile:read - only complex values of type double are supported");
    p = calcSize(data, &size);
    remaining = gridfile_get_contentlength(gf_) - gf_->pos;
    if (size > remaining || cplx && size*2 > remaining)
        return 0;
    if (size) gridfile_read(gf_, size, (char*)p);
    if (size && cplx)
        gridfile_read(gf_, size, (char*)mxGetPi(data));
    return 1;
}


EXPORT double mongo_gridfile_get_pos(struct gridfile_* gf) {
    return (double)((gridfile*)gf)->pos;
}


EXPORT double mongo_gridfile_seek(struct gridfile_* gf, double offset) {
    return (double)gridfile_seek((gridfile*)gf, (gridfs_offset)offset);
}
