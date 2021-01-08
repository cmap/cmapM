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
#include "bson.h"
#include <malloc.h>

#include <mex.h>

#define MAXDIM 20

const char* numstr(int i) {
    extern const char bson_numstrs[1000][4];
    if (i < 1000)
        return bson_numstrs[i];
    else {
        static char s[20];
        sprintf(s, "%d", i);
        return s;
    }
}


EXPORT void mongo_bson_buffer_create(struct bson_buffer** b)
{
    bson* _b = (bson*)bson_malloc(sizeof(bson));
    bson_init(_b);
    *b = (struct bson_buffer*)_b;
}


EXPORT void mongo_bson_buffer_to_bson(struct bson_buffer* b, struct bson_** out) {
    bson* _b = (bson*)b;
    bson_finish(_b);
    *out = (struct bson_*) _b;
    //*b = 0;
}


EXPORT void mongo_bson_free(struct bson_* b) {
    if (b != NULL) {
        bson_destroy((bson*)b);
        free(b);
    }
}


EXPORT void mongo_bson_buffer_free(struct bson_buffer* b) {
    bson_destroy((bson*)b);
    free(b);
}


static void reverse(mwSize* p, mwSize len) {
    mwSize* q = p + len - 1;
    mwSize t;
    while (p < q) {
        t = *p;
        *p = *q;
        *q = t;
        p++, q--;
    }
}


static int mongo_bson_buffer_append_complex(struct bson_buffer* b, const char* name, double r, double i) {
    bson* _b = (bson*) b;
    return (bson_append_start_object(_b, name) == BSON_OK) &&
           (bson_append_double(_b, "r", r) == BSON_OK) && 
           (bson_append_double(_b, "i", i) == BSON_OK) && 
           (bson_append_finish_object(_b) == BSON_OK);
}


EXPORT int  mongo_bson_buffer_append(struct bson_buffer* b, char* name, mxArray* value) {
    size_t numel = mxGetNumberOfElements(value);
    mxClassID cls = mxGetClassID(value);
    bson* _b = (bson*)b;
    mwSize i, j;
    mwSize dims[MAXDIM];
    mwSize ijk[MAXDIM];
    mwSize sizes[MAXDIM];
    mwSize ndims;
    const mwSize *odims;
    int depth = 0;
    int success;
    if (numel == 1) {
        /* Append a single element using the given name */
        switch (cls) {
        case mxLOGICAL_CLASS:
            return (bson_append_bool(_b, name, ((char*)mxGetData(value))[0]) == BSON_OK);
        case mxDOUBLE_CLASS:
            if (mxIsComplex(value))
                return mongo_bson_buffer_append_complex(b, name, mxGetPr(value)[0], mxGetPi(value)[0]);
            else
                return (bson_append_double(_b, name, mxGetPr(value)[0]) == BSON_OK);
        case mxSINGLE_CLASS:
            return (bson_append_double(_b, name, ((float*)mxGetData(value))[0]) == BSON_OK);
        case mxINT8_CLASS:
            return (bson_append_int(_b, name, ((signed char*)mxGetData(value))[0]) == BSON_OK);
        case mxUINT8_CLASS:
            return (bson_append_int(_b, name, ((unsigned char*)mxGetData(value))[0]) == BSON_OK);
        case mxINT16_CLASS:
            return (bson_append_int(_b, name, ((short*)mxGetData(value))[0]) == BSON_OK);
        case mxUINT16_CLASS:
            return (bson_append_int(_b, name, ((unsigned short*)mxGetData(value))[0]) == BSON_OK);
        case mxINT32_CLASS:
            return (bson_append_int(_b, name, ((int*)mxGetData(value))[0]) == BSON_OK);
        case mxUINT32_CLASS:
            return (bson_append_int(_b, name, ((unsigned int*)mxGetData(value))[0]) == BSON_OK);
        case mxINT64_CLASS: ;
        case mxUINT64_CLASS:
            return (bson_append_long(_b, name, ((int64_t*)mxGetData(value))[0]) == BSON_OK);
        default:
            mexPrintf("BsonBuffer:append - Unhandled type: %s\n", mxGetClassName(value));
            return 0;
        }
    }
    success = (bson_append_start_array(_b, name) == BSON_OK);
    odims = mxGetDimensions(value);
    ndims = mxGetNumberOfDimensions(value);
    memcpy(dims, odims, ndims*sizeof(mwSize));
    if (ndims > 1)
        reverse(dims, ndims);
    i = ndims;
    /* calculate offset to multiply each dimension's index by */
    j = 1;
    do {
        i--;
        sizes[i] = j;
        j *= dims[i];
    } while (i > 0);
    if (ndims == 2 && dims[1] == 1)
        ndims--;  /* 1 dimensional row vector */
    if (ndims > 1) {
        /* reverse row and columns */
        j = dims[ndims-1];
        dims[ndims-1] = dims[ndims-2];
        dims[ndims-2] = j;
        j = sizes[ndims-1];
        sizes[ndims-1] = sizes[ndims-2];
        sizes[ndims-2] = j;
    }
    memset(ijk, 0, ndims * sizeof(mwSize));
    while (success && depth >= 0) {
        if (ijk[depth] < dims[depth]) {
            const char* num = numstr((int)(ijk[depth]++));
            if (depth < (int)(ndims - 1)) {
                depth++;
                success = (bson_append_start_array(_b, num) == BSON_OK);
            }
            else {
                i = 0;
                for (j = 0; j < ndims; j++)
                    i += (ijk[j]-1) * sizes[j];
                switch (cls) {
                case mxLOGICAL_CLASS:
                    success = (bson_append_bool(_b, num, ((char*)mxGetData(value))[i]) == BSON_OK);
                    break;
                case mxDOUBLE_CLASS:
                    if (mxIsComplex(value))
                        success = mongo_bson_buffer_append_complex(b, num, mxGetPr(value)[i], mxGetPi(value)[i]);
                    else
                        success = (bson_append_double(_b, num, mxGetPr(value)[i]) == BSON_OK);
                    break;
                case mxSINGLE_CLASS:
                    success = (bson_append_double(_b, num, ((float*)mxGetData(value))[i]) == BSON_OK);
                    break;
                case mxINT8_CLASS:
                    success = (bson_append_int(_b, num, ((signed char*)mxGetData(value))[i]) == BSON_OK);
                    break;
                case mxUINT8_CLASS:
                    success = (bson_append_int(_b, num, ((unsigned char*)mxGetData(value))[i]) == BSON_OK);
                    break;
                case mxINT16_CLASS:
                    success = (bson_append_int(_b, num, ((short*)mxGetData(value))[i]) == BSON_OK);
                    break;
                case mxUINT16_CLASS:
                    success = (bson_append_int(_b, num, ((unsigned short*)mxGetData(value))[i]) == BSON_OK);
                    break;
                case mxINT32_CLASS:
                    success = (bson_append_int(_b, num, ((int*)mxGetData(value))[i]) == BSON_OK);
                    break;
                case mxUINT32_CLASS:
                    success = (bson_append_int(_b, num, ((unsigned int*)mxGetData(value))[i]) == BSON_OK);
                    break;
                case mxINT64_CLASS: ;
                case mxUINT64_CLASS:
                    success = (bson_append_long(_b, num, ((int64_t*)mxGetData(value))[i]) == BSON_OK);
                    break;
                default:
                    mexPrintf("BsonBuffer:append - Unhandled type: %s\n", mxGetClassName(value));
                    return 0;
                }
            }
        }
        else {
            ijk[depth] = 0;
            success = (bson_append_finish_object(_b) == BSON_OK);
            depth--;
        }
    }
    return success;
}


EXPORT int mongo_bson_buffer_append_string(struct bson_buffer* b, char* name, char* value) {
    return (bson_append_string((bson*) b, name, value) == BSON_OK);
}


EXPORT int mongo_bson_buffer_append_binary(struct bson_buffer* b, char* name, int type, void* value, int len) {
    return (bson_append_binary((bson*) b, name, type, (const char*) value, len) == BSON_OK);
}


EXPORT int mongo_bson_buffer_append_oid(struct bson_buffer* b, char* name, void* value) {
    return (bson_append_oid((bson*) b, name, (bson_oid_t*) value) == BSON_OK);
}


EXPORT int  mongo_bson_buffer_append_date(struct bson_buffer* b, char *name, mxArray* value) {
    size_t numel = mxGetNumberOfElements(value);
    mxClassID cls = mxGetClassID(value);
    bson* _b = (bson*)b;
    mwSize i, j;
    mwSize dims[MAXDIM];
    mwSize ijk[MAXDIM];
    mwSize sizes[MAXDIM];
    mwSize ndims;
    const mwSize *odims; /* original dimensions */
    char* p;
    int depth = 0;
    int success;
    if (cls != mxDOUBLE_CLASS) {
        mexPrintf("Only double values are permitted in appendDate\n");
        return 0;
    }
    if (numel == 1)
        return (bson_append_date(_b, name, (bson_date_t)((mxGetPr(value)[0] - 719529) * (1000 * 60 * 60 * 24)) ) == BSON_OK);
    success = (bson_append_start_array(_b, name) == BSON_OK);
    odims = mxGetDimensions(value);
    ndims = mxGetNumberOfDimensions(value);
    memcpy(dims, odims, ndims*sizeof(mwSize));
    if (ndims > 1)
        reverse(dims, ndims);
    i = ndims;
    j = 1;
    /* calculate offset to multiply each dimension's index by */
    do {
        i--;
        sizes[i] = j;
        j *= dims[i];
    } while (i > 0);
    if (ndims == 2 && dims[1] == 1)
        ndims--;
    if (ndims > 1) {
        /* reverse row and columns */
        j = dims[ndims-1];
        dims[ndims-1] = dims[ndims-2];
        dims[ndims-2] = j;
        j = sizes[ndims-1];
        sizes[ndims-1] = sizes[ndims-2];
        sizes[ndims-2] = j;
    }
    memset(ijk, 0, ndims * sizeof(mwSize));
    p = (char*)mxGetData(value);
    while (success && depth >= 0) {
        if (ijk[depth] < dims[depth]) {
            const char* num = numstr((int)(ijk[depth]++));
            if (depth < (int)(ndims - 1)) {
                depth++;
                success = (bson_append_start_array(_b, num) == BSON_OK);
            }
            else {
                i = 0;
                for (j = 0; j < ndims; j++)
                    i += (ijk[j]-1) * sizes[j];
                success = (bson_append_date(_b, num, (bson_date_t)((mxGetPr(value)[i] - 719529) * (1000 * 60 * 60 * 24)) ) == BSON_OK);
            }
        }
        else {
            ijk[depth] = 0;
            success = (bson_append_finish_object(_b) == BSON_OK);
            depth--;
        }
    }
    return success;
}


EXPORT int  mongo_bson_buffer_append_null(struct bson_buffer* b, char *name) {
    return (bson_append_null((bson*) b, name) == BSON_OK);
}


EXPORT int  mongo_bson_buffer_append_regex(struct bson_buffer* b, char *name, char* pattern, char* options) {
    return (bson_append_regex((bson*) b, name, pattern, options) == BSON_OK);
}


EXPORT int  mongo_bson_buffer_append_code(struct bson_buffer* b, char *name, char* value) {
    return (bson_append_code((bson*) b, name, value) == BSON_OK);
}


EXPORT int  mongo_bson_buffer_append_symbol(struct bson_buffer* b, char *name, char* value) {
    return (bson_append_symbol((bson*) b, name, value) == BSON_OK);
}


EXPORT int  mongo_bson_buffer_append_codewscope(struct bson_buffer* b, char *name, char* code, struct bson_* scope) {
    return (bson_append_code_w_scope((bson*) b, name, code, (bson*) scope) == BSON_OK);
}


EXPORT int  mongo_bson_buffer_append_timestamp(struct bson_buffer* b, char *name, int date, int increment) {
    bson_timestamp_t ts;
    ts.i = increment;
    ts.t = date;
    return (bson_append_timestamp((bson*) b, name, &ts) == BSON_OK);

}

EXPORT int mongo_bson_buffer_start_object(struct bson_buffer* b, char* name) {
    return (bson_append_start_object((bson*) b, name) == BSON_OK);
}


EXPORT int mongo_bson_buffer_finish_object(struct bson_buffer* b) {
    return (bson_append_finish_object((bson*) b) == BSON_OK);
}


EXPORT int mongo_bson_buffer_start_array(struct bson_buffer* b, char* name) {
    return (bson_append_start_array((bson*) b, name) == BSON_OK);
}


EXPORT int  mongo_bson_buffer_append_bson(struct bson_buffer* b, char* name, struct bson_* bs) {
    return (bson_append_bson((bson*)b, name, (bson*)bs) == BSON_OK);
}


EXPORT void mongo_bson_empty(struct bson_** b) {
    bson empty;
    bson* b_ = (bson*)malloc(sizeof(bson));
    bson_empty(&empty);
    bson_copy(b_, &empty);
    *b = (struct bson_*)b_;
}


EXPORT int mongo_bson_size(struct bson_* b) {
    return bson_size((bson*) b);
}


EXPORT int  mongo_bson_buffer_size(struct bson_buffer* b) {
    bson* _b = (bson*)b;
    return (int)(_b->cur - _b->data) + 1;
}


EXPORT void mongo_bson_iterator_create(struct bson_* b, struct bson_iterator_** i) {
    bson_iterator* _i = (bson_iterator*)malloc(sizeof(bson_iterator));
    bson_iterator_init(_i, (bson*) b);
    *i = (struct bson_iterator_*)_i;
}


EXPORT int mongo_bson_find(struct bson_* b, char* name, struct bson_iterator_** i) {
    bson* _b = (bson*)b;
    bson sub;
    bson_iterator iter;
    const char* next = name;
    do {
        int t;
        char *p;
        char prefix[2048];
        int len;
        if (bson_find(&iter, _b, next) != BSON_EOO) {
            bson_iterator* _i = (bson_iterator*)malloc(sizeof(bson_iterator));
            *_i = iter;
            *i = (struct bson_iterator_*)_i;
            return 1;
        }
        p = strchr((char*)next, '.');
        if (!p)
            return 0;
        len = (int)(p - next);
        strncpy(prefix, next, len);
        prefix[len] = '\0';
        if ((t = bson_find(&iter, _b, prefix)) == BSON_EOO)
            return 0;
        if (t == BSON_ARRAY || t == BSON_OBJECT) {
            bson_iterator_subobject(&iter, &sub);
            _b = &sub;
            next = p + 1;
        }
        else
            return 0;
    }
    while (1);
    /* never gets here */
    return 0;
}


EXPORT void mongo_bson_iterator_free(struct bson_iterator_* i) {
    free(i);
}


EXPORT int  mongo_bson_iterator_type(struct bson_iterator_* i) {
    return bson_iterator_type((bson_iterator*) i);
}


EXPORT int  mongo_bson_iterator_next(struct bson_iterator_* i) {
    return bson_iterator_next((bson_iterator*) i);
}


EXPORT const char* mongo_bson_iterator_key(struct bson_iterator_* i) {
    return bson_iterator_key((bson_iterator*) i);
}


EXPORT void mongo_bson_subiterator(struct bson_iterator_* i, struct bson_iterator_** si) {
    bson_iterator* sub = (bson_iterator*)malloc(sizeof(bson_iterator));
    bson_iterator_subiterator((bson_iterator*)i, sub);
    *si = (struct bson_iterator_*)sub;
}


EXPORT int mongo_bson_iterator_int(struct bson_iterator_* i) {
    return bson_iterator_int((bson_iterator*)i);
}


EXPORT mxint64 mongo_bson_iterator_long(struct bson_iterator_* i) {
    return bson_iterator_long((bson_iterator*)i);
}


EXPORT double mongo_bson_iterator_double(struct bson_iterator_* i) {
    return bson_iterator_double((bson_iterator*)i);
}


EXPORT const char* mongo_bson_iterator_string(struct bson_iterator_* i) {
    return bson_iterator_string((bson_iterator*)i);
}


EXPORT int mongo_bson_iterator_bin_type(struct bson_iterator_* i) {
    return bson_iterator_bin_type((bson_iterator*)i);
}


EXPORT int mongo_bson_iterator_bin_len(struct bson_iterator_* i) {
    return bson_iterator_bin_len((bson_iterator*)i);
}


EXPORT void mongo_bson_iterator_bin_value(struct bson_iterator_* i, void* v) {
    int len = bson_iterator_bin_len((bson_iterator*)i);
    memcpy(v, bson_iterator_bin_data((bson_iterator*)i), len);
}


EXPORT void mongo_bson_oid_gen(void* oid) {
    bson_oid_gen((bson_oid_t*) oid);
}


EXPORT const char* mongo_bson_oid_to_string(void* oid) {
    static char s[25];
    bson_oid_to_string((bson_oid_t*) oid, s);
    return s;
}


EXPORT void mongo_bson_oid_from_string(char* s, void* oid) {
    bson_oid_from_string((bson_oid_t*) oid, s);
}


EXPORT void mongo_bson_iterator_oid(struct bson_iterator_* i, void* oid) {
    memcpy(oid, bson_iterator_oid((bson_iterator*) i), 12);
}


EXPORT int mongo_bson_iterator_bool(struct bson_iterator_* i) {
    return (bson_iterator_bool((bson_iterator*) i) != 0);
}


EXPORT mxint64  mongo_bson_iterator_date(struct bson_iterator_* i) {
    return bson_iterator_date((bson_iterator*) i);
}


EXPORT const char* mongo_bson_iterator_regex(struct bson_iterator_* i) {
    return bson_iterator_regex((bson_iterator*) i);
}


EXPORT const char* mongo_bson_iterator_regex_opts(struct bson_iterator_* i) {
    return bson_iterator_regex_opts((bson_iterator*) i);
}


EXPORT const char* mongo_bson_iterator_code(struct bson_iterator_* i) {
    return bson_iterator_code((bson_iterator*) i);
}


EXPORT void mongo_bson_iterator_code_scope(struct bson_iterator_* i, struct bson_buffer** b) {
    bson* _b = (bson*)malloc(sizeof(bson));
    bson scope;
    bson_iterator_code_scope((bson_iterator*) i, &scope);
    bson_copy(_b, &scope);
    *b = (struct bson_buffer*)_b;
}


EXPORT int mongo_bson_iterator_timestamp(struct bson_iterator_* i, int* increment) {
    bson_timestamp_t ts = bson_iterator_timestamp((bson_iterator*) i);
    *increment = ts.i;
    return ts.t;
}


struct Rcomplex {
    double r;
    double i;
};


int _iterator_getComplex(bson_iterator* iter, struct Rcomplex* z) {
    bson_iterator sub;
    if (bson_iterator_type(iter) != BSON_OBJECT)
        return 0;
    bson_iterator_subiterator(iter, &sub);
    if (bson_iterator_next(&sub) != BSON_DOUBLE || strcmp(bson_iterator_key(&sub), "r") != 0)
        return 0;
    z->r = bson_iterator_double(&sub);
    if (bson_iterator_next(&sub) != BSON_DOUBLE || strcmp(bson_iterator_key(&sub), "i") != 0)
        return 0;
    z->i = bson_iterator_double(&sub);
    if (bson_iterator_next(&sub) != BSON_EOO)
        return 0;
    return 1;
}


EXPORT mxArray* mongo_bson_array_value(struct bson_iterator_* i) {
    bson_type sub_type, common_type;
    struct Rcomplex z;
    bson_iterator sub[MAXDIM+1];
    mwSize ndims = 0;
    mwSize count[MAXDIM+1];
    mwSize dim[MAXDIM+1];
    mwSize* mdim = dim + 1;
    mwSize sizes[MAXDIM+1];
    mxArray* ret;
    mwSize depth, j, len, ofs;
    int isRow = 0;
    sub[0] = *(bson_iterator*)i;
    /* count number of dimensions.  This is equal to the number of
       consecutive array markers in the BSON */
    do {
        bson_iterator_subiterator(&sub[ndims], &sub[ndims+1]);
        if (++ndims > MAXDIM) {
            mexPrintf("Max dimensions (%d) exceeded. Use an iterator\n", MAXDIM);
            return 0;
        }
        sub_type = bson_iterator_next(&sub[ndims]);
    }
    while (sub_type == BSON_ARRAY);

    /* get the first data value's type */
    switch (common_type = sub_type) {
    case BSON_INT: ;
    case BSON_LONG: ;
    case BSON_DOUBLE: ;
    case BSON_BOOL: ;
    case BSON_DATE:
        break;
    case BSON_STRING: 
        if (ndims > 1) {
            mexPrintf("Unable to convert array - Only 1 dimenisonal arrays of strings supported");
            return 0;
        }
        break;
    case BSON_OBJECT:
        if (_iterator_getComplex(&sub[ndims], &z))
            break;
        /* fall thru to default */
    default:
        /* including empty array */
        mexPrintf("Unable to convert array - invalid type (%d)", common_type);
        return 0;
    }

    /* initial lowest level count */
    for (j = 0; j <= ndims; j++)
        count[j] = 1;
    while ((sub_type = bson_iterator_next(&sub[ndims])) != BSON_EOO) {
        if (sub_type != common_type) {
            mexPrintf("Unable to convert array - inconsistent types");
            return 0;
        }
        if (sub_type == BSON_OBJECT && !_iterator_getComplex(&sub[ndims], &z)) {
            mexPrintf("Unable to convert array - invalid subobject");
            return 0;
        }
        ++count[ndims];
    }

    /* step through rest of array -- checking common type and dimensions */
    memset(dim, 0, sizeof(dim));
    depth = ndims;
    while (depth >= 1) {
        sub_type = bson_iterator_next(&sub[depth]);
        switch (sub_type) {
        case BSON_EOO:
            if (dim[depth] == 0)
                dim[depth] = count[depth];
            else if (dim[depth] != count[depth]) {
                mexPrintf("Unable to convert array - inconsistent dimensions");
                return 0;
            }
            depth--;
            break;
        case BSON_ARRAY:
            count[depth]++;
            bson_iterator_subiterator(&sub[depth], &sub[depth+1]);
            if (++depth > ndims) {
                mexPrintf("Unable to convert array - inconsistent dimensions");
                return 0;
            }
            count[depth] = 0;
            break;
        case BSON_INT: ;
        case BSON_LONG: ;
        case BSON_DOUBLE: ;
        case BSON_STRING: ; 
        case BSON_BOOL: ;
        case BSON_DATE: ;
GotEl:  {
            if (depth != ndims || sub_type != common_type) {
                mexPrintf("Unable to convert array - inconsistent dimensions or types");
                return 0;
            }
            count[depth]++;
            break;
        }
        case BSON_OBJECT:
            if (_iterator_getComplex(&sub[depth], &z))
                goto GotEl;
            /* fall thru to default */
        default:
            mexPrintf("Unable to convert array - invalid type (%d)", sub_type);
            return 0;
        }
    }

    if (ndims > 1) {
        j = dim[ndims];            /* reverse row and column */
        dim[ndims] = dim[ndims-1];
        dim[ndims-1] = j;
    }
    /* calculate offset each dimension multiplies it's index by */
    len = 1;
    for (depth = ndims; depth > 0; depth--) {
        sizes[depth] = len;
        len *= dim[depth];
    }

    if (ndims > 1) {
        reverse(mdim, ndims); /* reverse dimensions for Matlab */
        j = sizes[ndims];
        sizes[ndims] = sizes[ndims-1];
        sizes[ndims-1] = j;
    } else {
        isRow = 1;
        ndims = 2;
        mdim[1] = mdim[0];
        mdim[0] = 1;
    }
/*
    for (j = 1; j <= ndims; j++)
        mexPrintf("%d ", dim[j]);
    mexPrintf("\n");

    for (j = 1; j <= ndims; j++)
        mexPrintf("%d ", sizes[j]);
    mexPrintf("\n");
*/
    switch (common_type) {
    case BSON_INT:    ret = mxCreateNumericArray(ndims, mdim, mxINT32_CLASS, mxREAL); break;
    case BSON_LONG:   ret = mxCreateNumericArray(ndims, mdim, mxINT64_CLASS, mxREAL); break;
    case BSON_DATE:
    case BSON_DOUBLE: ret = mxCreateNumericArray(ndims, mdim, mxDOUBLE_CLASS, mxREAL); break;
    case BSON_STRING: ret = mxCreateCellMatrix(len, 1); break;
    case BSON_BOOL:   ret = mxCreateLogicalArray(ndims, mdim); break;
    case BSON_OBJECT: ret = mxCreateNumericArray(ndims, mdim, mxDOUBLE_CLASS, mxCOMPLEX); break;
    default:
        /* never reaches here */
        ret = 0;
    }

    if (isRow)
        ndims--;
    /* step through array(s) again, pulling out values */
    bson_iterator_subiterator(&sub[0], &sub[1]);
    depth = 1;
    count[depth] = 0;
    while (depth >= 1) {
        sub_type = bson_iterator_next(&sub[depth]);
        count[depth]++;
        if (sub_type == BSON_EOO) {
            depth--;
        } else if (sub_type == BSON_ARRAY) {
            bson_iterator_subiterator(&sub[depth], &sub[depth+1]);
            depth++;
            count[depth] = 0;
        } else {
            ofs = 0;
            for (j = 1; j <= ndims; j++)
                ofs += sizes[j] * (count[j] - 1);

            switch (sub_type) {
                case BSON_INT:
                    ((int*)mxGetData(ret))[ofs] = bson_iterator_int(&sub[depth]);
                    break;
                case BSON_DATE:
                    mxGetPr(ret)[ofs] = 719529.0 + bson_iterator_date(&sub[depth]) / (1000.0 * 60 * 60 * 24);
                    break;
                case BSON_DOUBLE: 
                    mxGetPr(ret)[ofs] = bson_iterator_double(&sub[depth]);
                    break;
                case BSON_LONG:
                    ((int64_t*)mxGetData(ret))[ofs] = bson_iterator_long(&sub[depth]);
                    break;
                case BSON_BOOL: ;
                    ((mxLogical*)mxGetData(ret))[ofs] = bson_iterator_bool(&sub[depth]);
                    break;
                case BSON_OBJECT:
                    _iterator_getComplex(&sub[depth], &z);
                    mxGetPr(ret)[ofs] = z.r;
                    mxGetPi(ret)[ofs] = z.i;
                    break;
                case BSON_STRING:
                    mxSetCell(ret, count[depth]-1, mxCreateString(bson_iterator_string(&sub[depth])));
                    break;
                default: ;
                    /* never reaches here */
            }
        }
    }

    return ret;
}


