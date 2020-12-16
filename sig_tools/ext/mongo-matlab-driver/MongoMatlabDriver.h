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
#ifdef _MSC_VER
#define mxint64 int64_t
#ifndef MONGO_USE__INT64
#define MONGO_USE__INT64
#endif
#endif


#ifdef __GNUC__
typedef long long mxint64;
#ifndef MONGO_HAVE_STDINT
#define MONGO_HAVE_STDINT
#endif
#endif

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#include <matrix.h>

#include "platform.h"

/* Define dummy structures for the interface with Matlab.
   Provides a level of abstraction and hides the details
   of the types from Matlab.  Also, we don't need to include here
   the C driver files that define the types these are mapped to.
*/
struct bson_buffer {
    int dummy;
};

struct bson_ {
    int dummy;
};

struct bson_iterator_ {
    int dummy;
};

struct mongo_ {
    int dummy;
};

struct mongo_cursor_ {
    int dummy;
};

struct gridfs_ {
    int dummy;
};

struct gridfile_ {
    int dummy;
};


EXPORT void mongo_bson_buffer_create(struct bson_buffer** b);
EXPORT void mongo_bson_buffer_free(struct bson_buffer* b);
EXPORT int mongo_bson_buffer_append(struct bson_buffer* b, char* name, mxArray* value);
EXPORT int  mongo_bson_buffer_append_string(struct bson_buffer* b, char* name, char* value);
EXPORT int  mongo_bson_buffer_append_binary(struct bson_buffer* b, char* name, int type, void* value, int len);
EXPORT void mongo_bson_oid_gen(void* oid);
EXPORT const char* mongo_bson_oid_to_string(void* oid);
EXPORT void mongo_bson_oid_from_string(char* s, void* oid);
EXPORT int  mongo_bson_buffer_append_oid(struct bson_buffer* b, char* name, void* value);
EXPORT int  mongo_bson_buffer_append_date(struct bson_buffer* b, char *name, mxArray* value);
EXPORT int  mongo_bson_buffer_append_null(struct bson_buffer* b, char *name);
EXPORT int  mongo_bson_buffer_append_regex(struct bson_buffer* b, char *name, char* pattern, char* options);
EXPORT int  mongo_bson_buffer_append_code(struct bson_buffer* b, char *name, char* value);
EXPORT int  mongo_bson_buffer_append_symbol(struct bson_buffer* b, char *name, char* value);
EXPORT int  mongo_bson_buffer_append_codewscope(struct bson_buffer* b, char *name, char* code, struct bson_* scope);
EXPORT int  mongo_bson_buffer_append_timestamp(struct bson_buffer* b, char *name, int date, int increment);
EXPORT int  mongo_bson_buffer_start_object(struct bson_buffer* b, char* name);
EXPORT int  mongo_bson_buffer_finish_object(struct bson_buffer* b);
EXPORT int  mongo_bson_buffer_start_array(struct bson_buffer* b, char* name);
EXPORT int  mongo_bson_buffer_append_bson(struct bson_buffer* b, char* name, struct bson_* bs); 
EXPORT void mongo_bson_buffer_to_bson(struct bson_buffer* b, struct bson_** out);
EXPORT void mongo_bson_empty(struct bson_** b);
EXPORT int  mongo_bson_size(struct bson_* b);
EXPORT int  mongo_bson_buffer_size(struct bson_buffer* b);
EXPORT void mongo_bson_free(struct bson_* b);
EXPORT int mongo_bson_find(struct bson_* b, char* name, struct bson_iterator_** i);
EXPORT void mongo_bson_iterator_create(struct bson_* b, struct bson_iterator_** i);
EXPORT void mongo_bson_iterator_free(struct bson_iterator_* i);
EXPORT int  mongo_bson_iterator_type(struct bson_iterator_* i);
EXPORT int  mongo_bson_iterator_next(struct bson_iterator_* i);
EXPORT const char* mongo_bson_iterator_key(struct bson_iterator_* i);
EXPORT void mongo_bson_subiterator(struct bson_iterator_* i, struct bson_iterator_** si);
EXPORT int  mongo_bson_iterator_int(struct bson_iterator_* i);
EXPORT mxint64 mongo_bson_iterator_long(struct bson_iterator_* i);
EXPORT double mongo_bson_iterator_double(struct bson_iterator_* i);
EXPORT const char* mongo_bson_iterator_string(struct bson_iterator_* i);
EXPORT int  mongo_bson_iterator_bin_type(struct bson_iterator_* i);
EXPORT int  mongo_bson_iterator_bin_len(struct bson_iterator_* i);
EXPORT void mongo_bson_iterator_bin_value(struct bson_iterator_* i, void* v);
EXPORT void mongo_bson_iterator_oid(struct bson_iterator_* i, void* oid);
EXPORT int  mongo_bson_iterator_bool(struct bson_iterator_* i);
EXPORT mxint64  mongo_bson_iterator_date(struct bson_iterator_* i);
EXPORT const char* mongo_bson_iterator_regex(struct bson_iterator_* i);
EXPORT const char* mongo_bson_iterator_regex_opts(struct bson_iterator_* i);
EXPORT const char* mongo_bson_iterator_code(struct bson_iterator_* i);
EXPORT void mongo_bson_iterator_code_scope(struct bson_iterator_* i, struct bson_buffer** b);
EXPORT int mongo_bson_iterator_timestamp(struct bson_iterator_* i, int* increment);
EXPORT mxArray* mongo_bson_array_value(struct bson_iterator_* i);

EXPORT void mmongo_create(struct mongo_** conn);
EXPORT void mmongo_connect(struct mongo_* conn, char* host);
EXPORT int  mmongo_is_connected(struct mongo_* conn);
EXPORT int  mongo_is_master(struct mongo_* conn);
EXPORT void mmongo_destroy(struct mongo_* conn);
EXPORT void mmongo_replset_init(struct mongo_* conn, char* name);
EXPORT void mongo_add_seed(struct mongo_* conn, char* host);
EXPORT int  mmongo_replset_connect(struct mongo_* conn);
EXPORT void mmongo_disconnect(struct mongo_* conn);
EXPORT int  mmongo_reconnect(struct mongo_* conn);
EXPORT int  mmongo_check_connection(struct mongo_* conn);
EXPORT void mongo_set_timeout(struct mongo_* conn, int timeout);
EXPORT int  mongo_get_timeout(struct mongo_* conn);
EXPORT const char* mmongo_get_primary(struct mongo_* conn);
EXPORT int  mmongo_get_socket(struct mongo_* conn);
EXPORT mxArray* mongo_get_hosts(struct mongo_* conn);
EXPORT int  mmongo_get_err(struct mongo_* conn);
EXPORT mxArray* mongo_get_databases(struct mongo_* conn);
EXPORT mxArray* mongo_get_database_collections(struct mongo_* conn, char* db);
EXPORT int mongo_rename(struct mongo_* conn, char* from_ns, char* to_ns);
EXPORT int  mmongo_insert(struct mongo_* conn, char* ns, struct bson_* b);
EXPORT int  mmongo_update(struct mongo_* conn, char* ns, struct bson_* criteria, struct bson_* objNew, int flags);
EXPORT int  mmongo_remove(struct mongo_* conn, char* ns, struct bson_* criteria);
EXPORT int  mmongo_find_one(struct mongo_* conn, char* ns, struct bson_* query, struct bson_* fields, struct bson_** result);
EXPORT int  mmongo_find(struct mongo_* conn, char* ns, struct bson_* query,  struct bson_* sort, struct bson_* fields, int limit, int skip, int options, struct mongo_cursor_** result);
EXPORT int  mmongo_cursor_next(struct mongo_cursor_* cursor);
EXPORT int  mongo_cursor_value(struct mongo_cursor_* cursor, struct bson_** value);
EXPORT void mongo_cursor_free(struct mongo_cursor_* cursor);
EXPORT double mmongo_count(struct mongo_* conn, char* ns, struct bson_* query);
EXPORT int  mongo_index_create(struct mongo_* conn, char* ns, struct bson_* key, int options, struct bson_** out);
EXPORT int  mongo_add_user(struct mongo_* conn, char* db, char* user, char* password);
EXPORT int  mongo_authenticate(struct mongo_* conn, char* db, char* user, char* password);
EXPORT int  mongo_command(struct mongo_* conn, char* db, struct bson_* cmd, struct bson_** result);
EXPORT int  mongo_get_last_err(struct mongo_* conn, char* db, struct bson_** err);
EXPORT int  mongo_get_prev_err(struct mongo_* conn, char* db, struct bson_** err);
EXPORT int  mmongo_get_server_err(struct mongo_* conn);
EXPORT char*  mmongo_get_server_err_string(struct mongo_* conn);
EXPORT int  mongo_drop_database(struct mongo_* conn, char* db);
EXPORT int  mongo_drop(struct mongo_* conn, char* ns);

EXPORT int  mongo_gridfs_create(struct mongo_* conn, char* db, char* prefix, struct gridfs_** gfs);
EXPORT void mongo_gridfs_destroy(struct gridfs_* gfs);
EXPORT int  mongo_gridfs_store_file(struct gridfs_* gfs, char* filename, char* remoteName, char* contentType);
EXPORT void mongo_gridfs_remove_file(struct gridfs_* gfs, char* remoteName);
EXPORT int  mongo_gridfs_store(struct gridfs_* gfs, mxArray* data, char* remoteName, char* contentType);
EXPORT void mongo_gridfile_writer_create(struct gridfs_* gfs, char* remoteName, char* contentType, struct gridfile_** gf);
EXPORT void mongo_gridfile_writer_write(struct gridfile_* gf, mxArray* data);
EXPORT int  mongo_gridfile_writer_finish(struct gridfile_* gf);
EXPORT int  mongo_gridfs_find(struct gridfs_* gfs, struct bson_* query, struct gridfile_** gf);
EXPORT void mongo_gridfile_destroy(struct gridfile_* gf);
EXPORT const char* mongo_gridfile_get_filename(struct gridfile_* gf);
EXPORT double mongo_gridfile_get_length(struct gridfile_* gf);
EXPORT int mongo_gridfile_get_chunk_size(struct gridfile_* gf);
EXPORT int mongo_gridfile_get_chunk_count(struct gridfile_* gf);
EXPORT const char* mongo_gridfile_get_content_type(struct gridfile_* gf);
EXPORT double mongo_gridfile_get_upload_date(struct gridfile_* gf);
EXPORT const char* mongo_gridfile_get_md5(struct gridfile_* gf);
EXPORT void mongo_gridfile_get_descriptor(struct gridfile_* gf, struct bson_** out);
EXPORT int mongo_gridfile_get_metadata(struct gridfile_* gf, struct bson_** out);
EXPORT int mongo_gridfile_get_chunk(struct gridfile_* gf, int i, struct bson_** out);
EXPORT int mongo_gridfile_get_chunks(struct gridfile_* gf, int start, int count, struct mongo_cursor_** out);
EXPORT int mongo_gridfile_read(struct gridfile_* gf, mxArray* data);
EXPORT double mongo_gridfile_get_pos(struct gridfile_* gf);
EXPORT double mongo_gridfile_seek(struct gridfile_* gf, double offset);

