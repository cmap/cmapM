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
#include "mongo.h"
#include "net.h"

#include <mex.h>

extern bson empty_bson;

EXPORT void mmongo_create(struct mongo_** conn) {
    mongo* conn_; 
    conn_ = (mongo*)malloc(sizeof(mongo));
    mongo_init(conn_);
    *conn = (struct mongo_*)conn_;
}


EXPORT void mmongo_connect(struct mongo_* conn, char* host) {
    mongo* conn_ = (mongo*)conn;
    mongo_host_port hp;
    mongo_parse_host(host, &hp);
    if (mongo_connect(conn_, hp.host, hp.port) != MONGO_OK)
        mexPrintf("Unable to connect to %s:%d, error code = %d\n", hp.host, hp.port, conn_->err);
}

EXPORT int mmongo_is_connected(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    return conn_->connected;
}


EXPORT int  mongo_is_master(struct mongo_* conn) {
    return mongo_cmd_ismaster((mongo*)conn, NULL);
}


EXPORT void mmongo_destroy(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    mongo_destroy(conn_);
    free(conn_);
}


EXPORT void mmongo_replset_init(struct mongo_* conn, char* name) {
    mongo* conn_ = (mongo*)conn;
    mongo_replset_init(conn_, name);
}


EXPORT void mongo_add_seed(struct mongo_* conn, char* host) {
    mongo* conn_ = (mongo*)conn;
    mongo_host_port hp;
    mongo_parse_host(host, &hp);
    mongo_replset_add_seed(conn_, hp.host, hp.port);
}


EXPORT int  mmongo_replset_connect(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    return (mongo_replset_connect(conn_) == MONGO_OK);
}


EXPORT void mmongo_disconnect(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    mongo_disconnect(conn_);
}


EXPORT int  mmongo_reconnect(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    return (mongo_reconnect(conn_) == MONGO_OK);
}


EXPORT int  mmongo_check_connection(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    return (mongo_check_connection(conn_) == MONGO_OK);
}


EXPORT void mongo_set_timeout(struct mongo_* conn, int timeout) {
    mongo* conn_ = (mongo*)conn;
    mongo_set_op_timeout(conn_, timeout);
}


EXPORT int mongo_get_timeout(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    return conn_->op_timeout_ms;
}


const char* get_host_port_(mongo_host_port* hp) {
    static char _hp[sizeof(hp->host)+12];
    sprintf(_hp, "%s:%d", hp->host, hp->port);
    return _hp;
}


EXPORT const char* mmongo_get_primary(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    return get_host_port_(conn_->primary);
}


EXPORT int mmongo_get_socket(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    return conn_->sock;
}


EXPORT mxArray* mongo_get_hosts(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    mongo_replset* r = conn_->replset;
    mxArray* ret;
    mongo_host_port* hp;
    int count = 0;
    int i = 0;
    if (!r) return 0;
    for (hp = r->hosts; hp; hp = hp->next)
        ++count;
    ret = mxCreateCellMatrix(count, 1);
    for (hp = r->hosts; hp; hp = hp->next, i++)
        mxSetCell(ret, i++, mxCreateString(get_host_port_(hp)));
    return ret;
}



EXPORT int mmongo_get_err(struct mongo_* conn) {
    mongo* conn_ = (mongo*)conn;
    return conn_->err;
}


EXPORT mxArray* mongo_get_databases(struct mongo_* conn) {
    bson out;
    mxArray* ret;
    int count = 0;
    bson_iterator it, databases, database;
    int i = 0;

    if (mongo_simple_int_command((mongo*)conn, "admin", "listDatabases", 1, &out) != MONGO_OK) {
        bson_destroy(&out);
        return 0;
    }
    bson_iterator_init(&it, &out);
    bson_iterator_next(&it);
    bson_iterator_subiterator(&it, &databases);
    while (bson_iterator_next(&databases)) {
        const char* name;
        bson_iterator_subiterator(&databases, &database);
        bson_iterator_next(&database);
        name = bson_iterator_string(&database);
        if (strcmp(name, "admin") != 0 && strcmp(name, "local") != 0)
            count++;
    }
    ret = mxCreateCellMatrix(count, 1);
    bson_iterator_subiterator(&it, &databases);
    while (bson_iterator_next(&databases)) {
        const char* name;
        bson_iterator_subiterator(&databases, &database);
        bson_iterator_next(&database);
        name = bson_iterator_string(&database);
        if (strcmp(name, "admin") != 0 && strcmp(name, "local") != 0)
            mxSetCell(ret, i++, mxCreateString(name));
    }
    bson_destroy(&out);
    return ret;
}


EXPORT mxArray* mongo_get_database_collections(struct mongo_* conn, char* db) {
    mxArray* ret;
    mongo* conn_ = (mongo*)conn;
    mongo_cursor* cursor;
    char ns[512];
    int count = 0;
    int i = 0;
    bson empty;
    bson_empty(&empty);
    strcpy(ns, db);
    strcat(ns, ".system.namespaces");
    cursor = mongo_find(conn_, ns, NULL, &empty, 0, 0, 0);
    while (cursor && mongo_cursor_next(cursor) == MONGO_OK) {
        bson_iterator iter;
        if (bson_find(&iter, &cursor->current, "name")) {
            const char* name = bson_iterator_string(&iter);
            if (strstr(name, ".system.") || strchr(name, '$'))
                continue;
            ++count;
        }
    }
    mongo_cursor_destroy(cursor);
    cursor = mongo_find(conn_, ns, &empty, &empty, 0, 0, 0);
    ret = mxCreateCellMatrix(count, 1);
    while (cursor && mongo_cursor_next(cursor) == MONGO_OK) {
        bson_iterator iter;
        if (bson_find(&iter, &cursor->current, "name")) {
            const char* name = bson_iterator_string(&iter);
            if (strstr(name, ".system.") || strchr(name, '$'))
                continue;
            mxSetCell(ret, i++, mxCreateString(name));
        }
    }
    mongo_cursor_destroy(cursor);
    return ret;
}


EXPORT int mongo_rename(struct mongo_* conn, char* from_ns, char* to_ns) {
    mongo* conn_ = (mongo*)conn;
    bson cmd;
    int ret;
    bson_init(&cmd);
    bson_append_string(&cmd, "renameCollection", from_ns);
    bson_append_string(&cmd, "to", to_ns);
    bson_finish(&cmd);
    ret = (mongo_run_command(conn_, "admin", &cmd, NULL) == MONGO_OK);
    bson_destroy(&cmd);
    return ret;
}


EXPORT int mmongo_insert(struct mongo_* conn, char* ns, struct bson_* b) {
    mongo* conn_ = (mongo*)conn;
    bson* b_ = (bson*)b;
    return (mongo_insert(conn_, ns, b_) == MONGO_OK);
}


EXPORT int mmongo_update(struct mongo_* conn, char* ns, struct bson_* criteria, struct bson_* objNew, int flags) {
    mongo* conn_ = (mongo*)conn;
    bson* criteria_ = (bson*) criteria;
    bson* objNew_ = (bson*) objNew;
    return (mongo_update(conn_, ns, criteria_, objNew_, flags) == MONGO_OK);
}


EXPORT int mmongo_remove(struct mongo_* conn, char* ns, struct bson_* criteria) {
    mongo* conn_ = (mongo*)conn;
    bson* criteria_ = (bson*)criteria;
    return (mongo_remove(conn_, ns, criteria_) == MONGO_OK);
}


EXPORT int mmongo_find_one(struct mongo_* conn, char* ns, struct bson_* query, struct bson_* fields, struct bson_** result) {
    mongo* conn_ = (mongo*)conn;
    bson* query_ = (bson*)query;
    bson* fields_ = (bson*)fields;
    bson* out = (bson*)malloc(sizeof(bson));
    if (mongo_find_one(conn_, ns, query_, fields_, out) == MONGO_OK) {
        *result = (struct bson_*)out;
        return 1;
    } else {
        free(out);
        return 0;
    }
}


EXPORT int mmongo_find(struct mongo_* conn, char* ns, struct bson_* query,  struct bson_* sort, struct bson_* fields, int limit, int skip, int options, struct mongo_cursor_** result) {
    mongo* conn_ = (mongo*)conn;
    bson* query_ = (bson*)query;
    bson* sort_ = (bson*)sort;
    bson* fields_ = (bson*)fields;
    mongo_cursor* cursor;

    bson* q = query_;
    bson sorted_query;
    if (sort_ != NULL && bson_size(sort_) > 5) {
        q = &sorted_query;
        bson_init(q);
        if (query_ == NULL)
            query_ = &empty_bson;
        bson_append_bson(q, "$query", query_);
        bson_append_bson(q, "$orderby", sort_);
        bson_finish(q);
    }

    cursor = mongo_find(conn_, ns, q, fields_, limit, skip, options);

    if (q == &sorted_query)
        bson_destroy(&sorted_query);

    if (cursor != NULL) {
        *result = (struct mongo_cursor_*)cursor;
        return 1;
    }
    return 0;
}


EXPORT int mmongo_cursor_next(struct mongo_cursor_* cursor) {
    if (cursor == NULL)
        return 0;

    return (mongo_cursor_next((mongo_cursor*)cursor) == MONGO_OK);
}


EXPORT int mongo_cursor_value(struct mongo_cursor_* cursor, struct bson_** value) {
    mongo_cursor* cursor_ = (mongo_cursor*)cursor;
    bson* data;
    if (!cursor_ || !cursor_->current.data)
        return 0;
    data = (bson*)malloc(sizeof(bson));
    bson_copy(data, &cursor_->current);
    *value = (struct bson_*)data;
    return 1;
}


EXPORT void mongo_cursor_free(struct mongo_cursor_* cursor) {
    mongo_cursor* cursor_ = (mongo_cursor*)cursor;
    mongo_cursor_destroy(cursor_);
}


EXPORT double mmongo_count(struct mongo_* conn, char* ns, struct bson_* query) {
    mongo* conn_ = (mongo*)conn;
    char* p = strchr(ns, '.');
    if (!p) {
        mexPrintf("Mongo:count - Expected a '.' in the namespace.\n");
        return 0;
    }
    *p = '\0';
    return (double)mongo_count(conn_, ns, p+1, (bson*)query);
}


EXPORT int mongo_index_create(struct mongo_* conn, char* ns, struct bson_* key, int options, struct bson_** out) {
    bson err;
    bson* errCopy;
    if (mongo_create_index((mongo*)conn, ns, (bson*)key, options, &err) == MONGO_OK)
        return 1;
    errCopy = (bson*)malloc(sizeof(bson));
    *errCopy = err;
    *out = (struct bson_*)errCopy;
    return 0;
}


EXPORT int  mongo_add_user(struct mongo_* conn, char* db, char* user, char* password) {
    return (mongo_cmd_add_user((mongo*)conn, db, user, password) == MONGO_OK);
}


EXPORT int  mongo_authenticate(struct mongo_* conn, char* db, char* user, char* password) {
    return (mongo_cmd_authenticate((mongo*)conn, db, user, password) == MONGO_OK);
}


EXPORT int mongo_command(struct mongo_* conn, char* db, struct bson_* cmd, struct bson_** result) {
    bson out;
    bson* outCopy;
    if (mongo_run_command((mongo*)conn, db, (bson*)cmd, &out) == MONGO_OK) {
        outCopy = (bson*)malloc(sizeof(bson));
        *outCopy = out;
        *result = (struct bson_*)outCopy;
        return 1;
    }
    return 0;
}


EXPORT int mongo_get_last_err(struct mongo_* conn, char* db, struct bson_** err) {
    bson out;
    bson* outCopy;
    if (mongo_cmd_get_last_error((mongo*)conn, db, &out) == MONGO_ERROR) {
        outCopy = (bson*)malloc(sizeof(bson));
        *outCopy = out;
        *err = (struct bson_*)outCopy;
        return 1;
    }
    return 0;

}


EXPORT int mongo_get_prev_err(struct mongo_* conn, char* db, struct bson_** err) {
    bson out;
    bson* outCopy;
    if (mongo_cmd_get_prev_error((mongo*)conn, db, &out) == MONGO_ERROR) {
        outCopy = (bson*)malloc(sizeof(bson));
        *outCopy = out;
        *err = (struct bson_*)outCopy;
        return 1;
    }
    return 0;

}


EXPORT int  mmongo_get_server_err(struct mongo_* conn) {
    return ((mongo*)conn)->lasterrcode;
}


EXPORT char*  mmongo_get_server_err_string(struct mongo_* conn) {
    return ((mongo*)conn)->lasterrstr;
}


EXPORT int mongo_drop_database(struct mongo_* conn, char* db) {
    mongo* conn_ = (mongo*)conn;
    return (mongo_cmd_drop_db(conn_, db) == MONGO_OK);
}


EXPORT int mongo_drop(struct mongo_* conn, char* ns) {
    mongo* conn_ = (mongo*)conn;
    char* p = strchr(ns, '.');
    if (!p) {
        mexPrintf("Mongo:drop - Expected a '.' in the namespace.\n");
        return 0;
    }
    *p = '\0';
    return (mongo_cmd_drop_collection(conn_, ns, p+1, NULL) == MONGO_OK);
}
