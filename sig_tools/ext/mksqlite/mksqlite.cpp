/*
 * mksqlite: A MATLAB Interface To SQLite
 *
 * (c) 2008-2011 by M. Kortmann <mail@kortmann.de>
 * ditributed under LGPL
 */

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <string.h>
#define _strcmpi strcasecmp
#endif

#include <mex.h>
#include "sqlite3.h"

/* Versionnumber */
#define VERSION "1.11"

/* Default Busy Timeout */
#define DEFAULT_BUSYTIMEOUT 1000

/* get the SVN Revisionnumber */
#include "svn_revision.h"


/* declare the MEX Entry function as pure C */
extern "C" void mexFunction(int nlhs, mxArray*plhs[], int nrhs, const mxArray*prhs[]);

/* Flag: Show the welcome message */
static bool FirstStart = false;

/* Flag: return NULL as NaN  */
static bool NULLasNaN  = false;
static const double g_NaN = mxGetNaN();

/*
 * Table of used database ids.
 */
#define MaxNumOfDbs 5
static sqlite3* g_dbs[MaxNumOfDbs] = { 0 };

/*
 * a poor man localization.
 * every language have an table of messages.
 */

/* Number of message table to use */
static int Language = -1;

#define MSG_HELLO               messages[Language][ 0]
#define MSG_INVALIDDBHANDLE     messages[Language][ 1]
#define MSG_IMPOSSIBLE          messages[Language][ 2]
#define MSG_USAGE               messages[Language][ 3]
#define MSG_INVALIDARG          messages[Language][ 4]
#define MSG_CLOSINGFILES        messages[Language][ 5]
#define MSG_CANTCOPYSTRING      messages[Language][ 6]
#define MSG_NOOPENARG           messages[Language][ 7]
#define MSG_NOFREESLOT          messages[Language][ 8]
#define MSG_CANTOPEN            messages[Language][ 9]
#define MSG_DBNOTOPEN           messages[Language][10]
#define MSG_INVQUERY            messages[Language][11]
#define MSG_CANTCREATEOUTPUT	messages[Language][12]
#define MSG_UNKNWNDBTYPE        messages[Language][13]
#define MSG_BUSYTIMEOUTFAIL     messages[Language][14]

/* 0 = english message table */
static const char* messages_0[] = 
{
	"mksqlite Version " VERSION " " SVNREV ", an interface from MATLAB to SQLite\n"
    "(c) 2008-2011 by Martin Kortmann <mail@kortmann.de>\n"
    "based on SQLite Version %s - http://www.sqlite.org\n\n",
    
    "invalid database handle\n",
	"function not possible",
	"Usage: %s([dbid,] command [, databasefile])\n",
	"no or wrong argument",
	"mksqlite: closing open databases.\n",
	"Can\'t copy string in getstring()",
    "Open without Databasename\n",
    "No free databasehandle available\n",
    "cannot open database\n%s, ",
	"database not open",
	"invalid query string (Semicolon?)",
	"cannot create output matrix",
	"unknown SQLITE data type",
    "cannot set busytimeout"
};

/* 1 = german message table */
static const char* messages_1[] = 
{
	"mksqlite Version " VERSION " " SVNREV ", ein MATLAB Interface zu SQLite\n"
    "(c) 2008-2011 by Martin Kortmann <mail@kortmann.de>\n"
    "basierend auf SQLite Version %s - http://www.sqlite.org\n\n",
    
    "ungültiger Datenbankhandle\n",
    "Funktion nicht möglich",
	"Verwendung: %s([dbid,] Befehl [, datenbankdatei])\n",
	"kein oder falsches Argument übergeben",
	"mksqlite: Die noch geöffneten Datenbanken wurden geschlossen.\n",
    "getstring() kann keine neue zeichenkette erstellen",
    "Open Befehl ohne Datenbanknamen\n",
    "Kein freier Datenbankhandle verfügbar\n",
	"Datenbank konnte nicht geöffnet werden\n%s, ",
	"Datenbank nicht geöffnet",
    "ungültiger query String (Semikolon?)",
    "Kann Ausgabematrix nicht erstellen",
    "unbek. SQLITE Datentyp",
    "busytimeout konnte nicht gesetzt werden"
};

/*
 * Message Tables
 */
static const char **messages[] = 
{
    messages_0,	/* English messages */
    messages_1	/* German messages  */
};

/*
 * duplicate a string, 
 */
static char* strnewdup(const char* s)
{
	char *newstr = 0;
	
	if (s)
	{
		newstr = new char [strlen(s) +1];
		if (newstr)
			strcpy(newstr, s);
	}

	return newstr;
}

/*
 * a single Value of an database row, including data type information
 */
class Value
{
public:
    int         m_Type;
    int         m_Size;

    char*		m_StringValue;
    double      m_NumericValue;
    
			Value () : m_StringValue(0) {}
virtual    ~Value () { if (m_StringValue) delete [] m_StringValue; } 
};

/*
 * all values of an database row
 */
class Values
{
public:
	int     m_Count;
    Value*	m_Values;
    
    Values* m_NextValues;
    
         Values(int n) : m_Count(n), m_NextValues(0)
            { m_Values = new Value[n]; }
            
virtual ~Values() 
            { delete [] m_Values; }
};

/*
 * close left over databases.
 */
static void CloseDBs(void)
{
    /*
	 * Is there any database left?
	 */
    bool dbsClosed = false;
    for (int i = 0; i < MaxNumOfDbs; i++)
	{
		/*
		 * close it
		 */
        if (g_dbs[i])
        {
            sqlite3_close(g_dbs[i]);
       	    g_dbs[i] = 0;
	        dbsClosed = true;
        }
    }
	if (dbsClosed)
    {
		/*
		 * Set the language to english if something
		 * goes wrong before the language could been set
		 */
		if (Language < 0)
            Language = 0;
		/*
		 * and inform the user
		 */
        mexWarnMsgTxt (MSG_CLOSINGFILES);
    }
}

/*
 * Get the last SQLite Error Code as an Error Identifier
 */
static char* TransErrToIdent(sqlite3 *db)
{
    static char dummy[32];

    int errorcode = sqlite3_errcode(db);
    
    switch(errorcode)
	 {    
		case 0:   return ("SQLITE:OK");
		case 1:   return ("SQLITE:ERROR");
		case 2:   return ("SQLITE:INTERNAL");
		case 3:   return ("SQLITE:PERM");
		case 4:   return ("SQLITE:ABORT");
		case 5:   return ("SQLITE:BUSY");
		case 6:   return ("SQLITE:LOCKED");
		case 7:   return ("SQLITE:NOMEM");
		case 8:   return ("SQLITE:READONLY");
		case 9:   return ("SQLITE:INTERRUPT");
		case 10:  return ("SQLITE:IOERR");
		case 11:  return ("SQLITE:CORRUPT");
		case 12:  return ("SQLITE:NOTFOUND");
		case 13:  return ("SQLITE:FULL");
		case 14:  return ("SQLITE:CANTOPEN");
		case 15:  return ("SQLITE:PROTOCOL");
		case 16:  return ("SQLITE:EMPTY");
		case 17:  return ("SQLITE:SCHEMA");
		case 18:  return ("SQLITE:TOOBIG");
		case 19:  return ("SQLITE:CONSTRAINT");
		case 20:  return ("SQLITE:MISMATCH");
		case 21:  return ("SQLITE:MISUSE");
		case 22:  return ("SQLITE:NOLFS");
		case 23:  return ("SQLITE:AUTH");
		case 24:  return ("SQLITE:FORMAT");
		case 25:  return ("SQLITE:RANGE");
		case 26:  return ("SQLITE:NOTADB");
		case 100: return ("SQLITE:ROW");
		case 101: return ("SQLITE:DONE");

		default:
			sprintf (dummy, "SQLITE:%d", errorcode);
			return dummy;
	 }
}

/*
 * Convert an String to char *
 */
static char *getstring(const mxArray *a)
{
   int llen = mxGetM(a) * mxGetN(a) * sizeof(mxChar) + 1;
   char *c = (char *) mxCalloc(llen,sizeof(char));

   if (mxGetString(a,c,llen))
      mexErrMsgTxt(MSG_CANTCOPYSTRING);
   
   return c;
}

/*
 * get an integer value from an numeric
 */
static int getinteger(const mxArray* a)
{
    switch (mxGetClassID(a))
    {
        case mxINT8_CLASS  : return (int) *((char*) mxGetData(a));
        case mxUINT8_CLASS : return (int) *((unsigned char*) mxGetData(a));
        case mxINT16_CLASS : return (int) *((short*) mxGetData(a));
        case mxUINT16_CLASS: return (int) *((unsigned short*) mxGetData(a));
        case mxINT32_CLASS : return (int) *((int*) mxGetData(a));
        case mxUINT32_CLASS: return (int) *((unsigned int*) mxGetData(a));
        case mxSINGLE_CLASS: return (int) *((float*) mxGetData(a));
        case mxDOUBLE_CLASS: return (int) *((double*) mxGetData(a));
    }
    
    return 0;
}

/*
 * This ist the Entry Function of this Mex-DLL
 */
void mexFunction(int nlhs, mxArray*plhs[], int nrhs, const mxArray*prhs[])
{
    mexAtExit(CloseDBs);
    
    /*
     * Get the current Language
     */
    if (Language == -1)
    {
#ifdef _WIN32        
        switch(PRIMARYLANGID(GetUserDefaultLangID()))
        {
            case LANG_GERMAN:
                Language = 1;
                break;
                
            default:
                Language = 0;
        }
#else
        Language = 0;
#endif
    }
    
	/*
	 * Print Version Information
	 */
	if (! FirstStart)
    {
    	FirstStart = true;

        mexPrintf (MSG_HELLO, sqlite3_libversion());
    }
    
    int db_id = 0;
    int CommandPos = 0;
    int NumArgs = nrhs;
    int i;
    
    /*
     * Check if the first argument is a number, then we have to use
	 * this number as an database id.
     */
    if (nrhs >= 1 && mxIsNumeric(prhs[0]))
    {
        db_id = getinteger(prhs[0]);
        if (db_id < 0 || db_id > MaxNumOfDbs)
        {
            mexPrintf(MSG_INVALIDDBHANDLE);
            mexErrMsgTxt(MSG_IMPOSSIBLE);
        }
        db_id --;
        CommandPos ++;
        NumArgs --;
    }

    /*
     * no argument -> fail
     */
    if (NumArgs < 1)
    {
        mexPrintf(MSG_USAGE);
        mexErrMsgTxt(MSG_INVALIDARG);
    }
    
    /*
     * The next (or first if no db number available) is the command,
     * it has to be a string.
     * This fails also, if the first arg is a db-id and there is no 
     * further argument
     */
    if (! mxIsChar(prhs[CommandPos]))
    {
        mexPrintf(MSG_USAGE);
        mexErrMsgTxt(MSG_INVALIDARG);
    }
    
	/*
	 * Get the command string
	 */
    char *command = getstring(prhs[CommandPos]);
    
    /*
     * Adjust the Argument pointer and counter
     */
    int FirstArg = CommandPos +1;
    NumArgs --;
    
    if (! strcmp(command, "open"))
    {
		/*
		 * open a database. There has to be one string argument,
		 * the database filename
		 */
        if (NumArgs != 1 || !mxIsChar(prhs[FirstArg]))
        {
            mexPrintf(MSG_NOOPENARG, mexFunctionName());
			mxFree(command);
            mexErrMsgTxt(MSG_INVALIDARG);
        }
        
		// TODO: possible Memoryleak 'command not freed' when getstring fails
        char* dbname = getstring(prhs[FirstArg]);

		/*
		 * Is there an database ID? The close the database with the same id 
		 */
        if (db_id > 0 && g_dbs[db_id])
        {
            sqlite3_close(g_dbs[db_id]);
            g_dbs[db_id] = 0;
        }

		/*
		 * If there isn't an database id, then try to get one
		 */
        if (db_id < 0)
        {
            for (i = 0; i < MaxNumOfDbs; i++)
            {
                if (g_dbs[i] == 0)
                {
                    db_id = i;
                    break;
                }
            }
        }
		/*
		 * no database id? sorry, database id table full
		 */
        if (db_id < 0)
        {
            plhs[0] = mxCreateDoubleScalar((double) 0);
            mexPrintf(MSG_NOFREESLOT);
			mxFree(command);
        	mxFree(dbname);
            mexErrMsgTxt(MSG_IMPOSSIBLE);
        }
       
		/*
		 * Open the database
		 */
        int rc = sqlite3_open(dbname, &g_dbs[db_id]);
        
        if (rc)
        {
			/*
			 * Anything wrong? free the database id and inform the user
			 */
            mexPrintf(MSG_CANTOPEN, sqlite3_errmsg(g_dbs[db_id]));
            sqlite3_close(g_dbs[db_id]);

            g_dbs[db_id] = 0;
            plhs[0] = mxCreateDoubleScalar((double) 0);
            
			mxFree(command);
	        mxFree(dbname);
            mexErrMsgTxt(MSG_IMPOSSIBLE);
        }
        
        /*
         * Set Default Busytimeout
         */
        rc = sqlite3_busy_timeout(g_dbs[db_id], DEFAULT_BUSYTIMEOUT);
        if (rc)
        {
			/*
			 * Anything wrong? free the database id and inform the user
			 */
            mexPrintf(MSG_CANTOPEN, sqlite3_errmsg(g_dbs[db_id]));
            sqlite3_close(g_dbs[db_id]);

            g_dbs[db_id] = 0;
            plhs[0] = mxCreateDoubleScalar((double) 0);
            
			mxFree(command);
	        mxFree(dbname);
            mexErrMsgTxt(MSG_BUSYTIMEOUTFAIL);
        }
        
		/*
		 * return value will be the used database id
		 */
        plhs[0] = mxCreateDoubleScalar((double) db_id +1);
        mxFree(dbname);
    }
    else if (! strcmp(command, "close"))
    {
		/*
		 * close a database
		 */

        /*
         * There should be no Argument to close
         */
        if (NumArgs > 0)
        {
			mxFree(command);
            mexErrMsgTxt(MSG_INVALIDARG);
        }
        
		/*
		 * if the database id is < 0 than close all open databases
		 */
        if (db_id < 0)
        {
            for (i = 0; i < MaxNumOfDbs; i++)
            {
                if (g_dbs[i])
                {
                    sqlite3_close(g_dbs[i]);
                    g_dbs[i] = 0;
                }
            }
        }
        else
        {
			/*
			 * If the database is open, then close it. Otherwise
			 * inform the user
			 */
            if (! g_dbs[db_id])
            {
				mxFree(command);
                mexErrMsgTxt(MSG_DBNOTOPEN);
            }
            else
            {
                sqlite3_close(g_dbs[db_id]);
                g_dbs[db_id] = 0;
            }
        }
    }
    else if (! strcmp(command, "status"))
    {
        /*
         * There should be no Argument to status
         */
        if (NumArgs > 0)
        {
			mxFree(command);
            mexErrMsgTxt(MSG_INVALIDARG);
        }
        
    	for (i = 0; i < MaxNumOfDbs; i++)
        {
            mexPrintf("DB Handle %d: %s\n", i, g_dbs[i] ? "OPEN" : "CLOSED");
        }
    }
    else if (! _strcmpi(command, "setbusytimeout"))
    {
        /*
         * There should be one Argument, the Timeout in ms
         */
        if (NumArgs != 1 || !mxIsNumeric(prhs[FirstArg]))
        {
			mxFree(command);
            mexErrMsgTxt(MSG_INVALIDARG);
        }

        if (! g_dbs[db_id])
        {
            mxFree(command);
            mexErrMsgTxt(MSG_DBNOTOPEN);
        }
        else
        {
            /*
             * Set Busytimeout
             */
            int TimeoutValue = getinteger(prhs[FirstArg]);
    
            int rc = sqlite3_busy_timeout(g_dbs[db_id], TimeoutValue);
            if (rc)
            {
                /*
                 * Anything wrong? free the database id and inform the user
                 */
                mexPrintf(MSG_CANTOPEN, sqlite3_errmsg(g_dbs[db_id]));
                sqlite3_close(g_dbs[db_id]);

                g_dbs[db_id] = 0;
                plhs[0] = mxCreateDoubleScalar((double) 0);

                mxFree(command);
                mexErrMsgTxt(MSG_BUSYTIMEOUTFAIL);
            }
        }
    }
    else
    {
		/*
		 * database id < 0? Thats an error...
		 */
        if (db_id < 0)
        {
            mexPrintf(MSG_INVALIDDBHANDLE);
			mxFree(command);
            mexErrMsgTxt(MSG_IMPOSSIBLE);
        }
        
		/*
		 * database not open? -> error
		 */
        if (!g_dbs[db_id])
        {
			mxFree(command);
            mexErrMsgTxt(MSG_DBNOTOPEN);
        }
        
		/*
		 * Every unknown command is treated as an sql query string
		 */
		const char* query = command;

        /*
         * a query shuld have no arguments
         */
        if (NumArgs > 0)
        {
			mxFree(command);
            mexErrMsgTxt(MSG_INVALIDARG);
        }
        
		/*
		 * emulate the "show tables" sql query
		 */
        if (! _strcmpi(query, "show tables"))
        {
            query = "SELECT name as tablename FROM sqlite_master "
                    "WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%' "
                    "UNION ALL "
                    "SELECT name as tablename FROM sqlite_temp_master "
                    "WHERE type IN ('table','view') "
                    "ORDER BY 1";
        }

		/*
		 * complete the query
		 */
        if (sqlite3_complete(query))
        {
			mxFree(command);
            mexErrMsgTxt(MSG_INVQUERY);
        }
        
        sqlite3_stmt *st;
        
		/*
		 * and prepare it
		 * if anything is wrong with the query, than complain about it.
		 */
        if (sqlite3_prepare_v2(g_dbs[db_id], query, -1, &st, 0))
        {
            if (st)
                sqlite3_finalize(st);
            
			mxFree(command);
            mexErrMsgIdAndTxt(TransErrToIdent(g_dbs[db_id]), sqlite3_errmsg(g_dbs[db_id]));
        }

		/*
		 * Any results?
		 */
        int ncol = sqlite3_column_count(st);
        if (ncol > 0)
        {
            char **fieldnames = new char *[ncol];   /* Column names */
            Values* allrows = 0;                    /* All query results */
            Values* lastrow = 0;					/* pointer to the last result row */
            int rowcount = 0;						/* number of result rows */
            
			/*
			 * Get the column names of the result set
			 */
            for(i=0; i<ncol; i++)
            {
                const char *cname = sqlite3_column_name(st, i);
                
                fieldnames[i] = new char [strlen(cname) +1];
                strcpy (fieldnames[i], cname);
				/*
				 * replace invalid chars by '_', so we can build
				 * valid MATLAB structs
				 */
                char *mk_c = fieldnames[i];
                while (*mk_c)
                {
                	if ((*mk_c == ' ') || (*mk_c == '*') || (*mk_c == '?'))
                    	*mk_c = '_';
                    mk_c++;
                }
            }
            
            /*
			 * get the result rows from the engine
			 *
			 * We cannot get the number of result lines, so we must
			 * read them in a loop and save them into an temporary list.
			 * Later, we can transfer this List into an MATLAB array of structs.
			 * This way, we must allocate enough memory for two result sets,
			 * but we save time by allocating the MATLAB Array at once.
			 */
            for(;;)
            {
				/*
				 * Advance to teh next row
				 */
                int step_res = sqlite3_step(st);

				/*
				 * no row left? break out of the loop
				 */
                if (step_res != SQLITE_ROW)
                    break;

				/*
				 * get new memory for the result
				 */
                Values* RecordValues = new Values(ncol);
                
                Value *v = RecordValues->m_Values;
                for (int j = 0; j < ncol; j++, v++)
                {
                     int fieldtype = sqlite3_column_type(st,j);

                     v->m_Type = fieldtype;
                     v->m_Size = 0;
                     
                     switch (fieldtype)
                     {
                         case SQLITE_NULL:      v->m_NumericValue = g_NaN;                                   break;
                         case SQLITE_INTEGER:	v->m_NumericValue = (double) sqlite3_column_int(st, j);      break;
                         case SQLITE_FLOAT:     v->m_NumericValue = (double) sqlite3_column_double(st, j);	 break;
                         case SQLITE_TEXT:      v->m_StringValue  = strnewdup((const char*) sqlite3_column_text(st, j));   break;
                         case SQLITE_BLOB:      
                            {
                                v->m_Size = sqlite3_column_bytes(st,j);
                                if (v->m_Size > 0)
                                {
                                    v->m_StringValue = new char[v->m_Size];
                                    memcpy(v->m_StringValue, sqlite3_column_blob(st,j), v->m_Size);
                                }
                                else
                                {
                                    v->m_Size = 0;
                                }
                            }
                            break;
                         default:	
							mxFree(command);
							mexErrMsgTxt(MSG_UNKNWNDBTYPE);
                     }
                }
				/*
				 * and add this row to the list of all result rows
				 */
                if (! lastrow)
                {
                    allrows = lastrow = RecordValues;
                }
                else
                {
                    lastrow->m_NextValues = RecordValues;
                    lastrow = lastrow->m_NextValues;
                }
				/*
				 * we have one more...
				 */
                rowcount ++;
            }
            
			/*
			 * end the sql engine
			 */
            sqlite3_finalize(st);

			/*
			 * got nothing? return an empty result to MATLAB
			 */
            if (rowcount == 0 || ! allrows)
            {
                if (!( plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL) ))
				{
					mxFree(command);
                    mexErrMsgTxt(MSG_CANTCREATEOUTPUT);
				}
            }
            else
            {
				/*
				 * Allocate an array of MATLAB structs to return as result
				 */
                int ndims[2];
                
                ndims[0] = rowcount;
                ndims[1] = 1;
                
                if (( plhs[0] = mxCreateStructArray (2, ndims, ncol, (const char**)fieldnames)) == 0)
                {
					mxFree(command);
                    mexErrMsgTxt(MSG_CANTCREATEOUTPUT);
                }
                
				/*
				 * transfer the result rows from the temporary list into the result array
				 */
                lastrow = allrows;
                i = 0;
                while(lastrow)
                {
                    Value* recordvalue = lastrow->m_Values;
                    
                    for (int j = 0; j < ncol; j++, recordvalue++)
                    {
                        if (recordvalue -> m_Type == SQLITE_TEXT)
                        {
                            mxArray* c = mxCreateString(recordvalue->m_StringValue);
                            mxSetFieldByNumber(plhs[0], i, j, c);
                        }
                        else if (recordvalue -> m_Type == SQLITE_NULL && !NULLasNaN)
                        {
                            mxArray* out_double = mxCreateDoubleMatrix(0,0,mxREAL);
                            mxSetFieldByNumber(plhs[0], i, j, out_double);
                        }
                        else if (recordvalue -> m_Type == SQLITE_BLOB)
                        {
                            if (recordvalue->m_Size > 0)
                            {
                                int BytePos;
                                int NumDims[2]={1,1};
                                NumDims[1]=recordvalue->m_Size;
                                mxArray*out_uchar8=mxCreateNumericArray(2, NumDims, mxUINT8_CLASS, mxREAL);
                                unsigned char *v = (unsigned char *) mxGetData(out_uchar8);
                                
                                memcpy(v, recordvalue->m_StringValue, recordvalue->m_Size);
                                    
                                mxSetFieldByNumber(plhs[0], i, j, out_uchar8);
                            }
                            else
                            {
                                // empty BLOB
                                mxArray* out_double = mxCreateDoubleMatrix(0,0,mxREAL);
                                mxSetFieldByNumber(plhs[0], i, j, out_double);
                            }
                        }
                        else
                        {
                            mxArray* out_double = mxCreateDoubleScalar(recordvalue->m_NumericValue);
                            mxSetFieldByNumber(plhs[0], i, j, out_double);
                        }
                    }
                    allrows = lastrow;
                    lastrow = lastrow->m_NextValues;
                    delete allrows;
                    i++;
                }
            }
            for(int i=0; i<ncol; i++)
                delete [] fieldnames[i];
            delete [] fieldnames;
        }
        else
        {
			/*
			 * no result, cleanup the sqlite engine
			 */
            int res = sqlite3_step(st);
            sqlite3_finalize(st);

			if (!( plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL) )) 
			{
                mexErrMsgTxt(MSG_CANTCREATEOUTPUT);
            }

            if (res != SQLITE_DONE)
            {
				mxFree(command);
                mexErrMsgIdAndTxt(TransErrToIdent(g_dbs[db_id]), sqlite3_errmsg(g_dbs[db_id]));
            }            
        }
    }
	mxFree(command);
}

/*
 *
 * Formatierungsanweisungen für den Editor vim
 *
 * vim:ts=4:ai:sw=4
 */
