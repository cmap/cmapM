#include "config.h"

#include <string>
#include <fstream>
#include <iostream>
#include <cstdlib>
// New for directory recursion
#ifdef WIN32
	#include <dirent_msvc.h>
#else
	#include <dirent.h>
#endif


using std::cin;
using std::cout;
using std::cerr;
using std::ifstream;
using std::ofstream;
using std::string;
using std::ios_base;
using std::endl;

%%{
  machine PostProcess;
  write data;

  # end of file character
  EOF = 0;

  # all but end of file character
  default = ^0;

  # end of line
  EOL = ('\r'? . '\n') @{line++;};

  # matlab identifier
  IDENT = [A-Z\\a-z\-_][A-Z\\a-z0-9\-_]*;

  # matlab ifdentifier without underscore characters
  IDENT_WO_US = [A-Z\\a-z\-][A-Z\\a-z0-9\-]*;

  ANY_TAG = '<' . [^>]* . '>';

  action echo {
    fout << fpc;
    if (!quiet)
      cout << fpc;
  }

  action st_tok { tmp_p = p; }

  action echo_tok { fout.write(tmp_p, p - tmp_p);
                    if (!quiet)
                      cout.write(tmp_p, p-tmp_p); }

  rettype:= |*

    # matlab is typeless, so discard the type
    ('matlabtypesubstitute' . (' '?)) => {};

    # replace all "::" by "."
    ('::' . [A-Z\\a-z\-_]) => { fout << '.' << *(te-1); };

    # a word
    (any - [\n <>\&\$:,\t])+ => { fout.write(ts, te-ts); };

    # word separators
    ([\n <>\&\$:\t]) => {fout << *ts;};

    # bugfix: allow '>' in the end of typenames for Daniel's generic types
    (('&lt;'|'$<$') . [^&$]* . ('$>$'|'&gt;')) => { fout.write(ts, te-ts); };

    # comma or &gt; end the type
    (',') => { fhold; fret; };
    ('&gt;'|'$>$') => { p -=4; fret; };
  *|;

  # reconstruct return values
  retval:= |*
    (('&lt;'|'$<$') . ('::')?) => { fcall rettype; };

    # matlab identifier (1 return value)
#    ('&lt;' . (default - [,&])*) => { cerr.write(ts+4, te - ts-4); cerr << std::endl; fout.write(ts+4, te - ts-4); };

    (',' . (default - ('\&'|'\$'))*) => {
      if (*p == '&')
        fout << " <span class=\"paramname\">";
      fout.write(ts+1, te-ts-1);
      if (*p == '&')
        fout << "</span>";
    };

    # end of return value
    ('&gt;'|'$>$') => {
                  if(only_retval) { fout << " ="; }
                  fret;
                };

    # white spaces
    ([ \t\n]*) => { fout.write(ts, te - ts); };

    # typebreak
    ('<br class="typebreak"/>') => {};

    # other tags
    #(ANY_TAG) => { fout.write(ts, te-ts); };
    
    ('\\\*') => {};

  *|;

  retvals := |*

    ('&lt;' | '$<$') => {};

    ('mlhs' . '\\\-'? . 'Inner' . '\\\-'? . 'Subst' . '\\\*'?) => { fcall retval; };

    ('&gt;' | '$>$') => { fout << "] ="; fgoto main; };

    # white spaces and commata
    ([ \t\n]*) => { fout.write(ts, te - ts); };
    ('<br class="typebreak"/>' . [ \t\n]* . ',') => { fout << ",<br class=\"typebreak\"/>\n"; };
    (',') => { fout << ", "; };

    # other tags
    (ANY_TAG) => { fout.write(ts, te-ts); };
    
    ('\\\*') => {};

  *|;

  # function name
  mtocsubst:= |*
    ('_' | '\\_');

    (IDENT_WO_US) => { fout.write(ts, te-ts); };

    ('_m_tsbus_cotm_' )  => { fout << "&gt;"; fgoto main; };
    
    ( '\\-m\\-\\_\\-tsbus\\-\\_\\-cotm') => { fgoto main; };
  *|;

  main:= |*
   # list of return values
   ('mlhs' . ('\\-')? . 'Subst') => { fout << "function ["; only_retval = false; fgoto retvals; };

   # one return value
   ('mlhs' . ('\\-')? . 'Inner' . ('\\-')? . 'Subst' . ('\\\*')?) => { fout << "function "; only_retval = true; fcall retval; fout << " ="; };

   # no return values
   ('noret::' . ('\\-')? . 'substitute' . ('\\\*')?) => {fout << "function ";};

   # function name
   ('mtoc_subst_' | 'mtoc\\-\\_\\-subst\\-\\_\\-') => { fgoto mtocsubst; };
   
   ('::mtoc_subst_' | ('\\-'? . '::' . '\\-' . 'mtoc\\-\\_\\-subst\\-\\_')) => { fout << '.'; fgoto mtocsubst; };

   # matlab is typeless, so discard the type
   ('matlabtypesubstitute'. (' '?)) => {};

   # remove leading "::" (global namespace identifier)
   ([(,>] . '::') => { fout.write(ts, 1); };
   ( ('&lt;' '$<$') . '::') => { fout.write(ts, 4); };

   # replace all "::" by "."
   ('::' . [A-Z\\a-z\-_]) => { fout << '.' << *(te-1); };

   # a word
   (any - [\n <>()[\]{}\&\$:.,;_\t\-])+ => { fout.write(ts, te-ts); };

   (')=0') => { fout << ")"; };

   # word separators
   ([\n <>()[\]{}\t:.;,_\&\$\-]) => {fout << *ts;};

   # a single dot stays a dot
   ('.') => {fout << '.';};
   *|;
}%%

class PostProcess {

private:
  string docdir_;
  int          line            , col;
  char        *ts              , *te;
  int          act             , have;
  int          cs;
  int          top;
  int          stack[5];
  bool         only_retval;
  bool         quiet_;
  bool         dry_run_;

public:
  /**
   * @class PostProcess
   *
   * @change{1,2,dw,2011-11-04} Changed the postprocessor interface from taking a single file argument to
   * assuming the passed string to be a folder whos contents are to be postprocessed.
   */
  // constructor
  PostProcess(const string &docdir, const bool quiet_flag, const bool dry_run_flag) :
    docdir_(docdir),
    line(1),
    ts(0), te(0), have(0),
    top(0), only_retval(false),
    quiet_(quiet_flag),
    dry_run_(dry_run_flag)
  { }

  int execute()
  {
    DIR *dp;
    if ((dp  = opendir(docdir_.c_str())) == NULL) {
      cerr << "Error opening directory " << docdir_ << endl;
      return -1;
    }

    struct dirent* dirp;
    string file;
    while ((dirp = readdir(dp)) != NULL) {
      file = string(dirp->d_name);
      // Process only html files
      if (file.substr(file.find_last_of(".") + 1) == "tex"
    		  || file.substr(file.find_last_of(".") + 1) == "js"
    		  || (file.substr(file.find_last_of(".") + 1) == "html" && file.find("8rl") == string::npos)) {
        postprocess(docdir_ + string("/") + file);
      }
    }
    closedir(dp);
    return 0;
  }

  // run postprocessor
  int postprocess(string file)
  {
    std::ios::sync_with_stdio(false);

    %% write init;

    ifstream is;
    try {
      is.open(file.c_str());
    } catch (std::ifstream::failure e) {
      cerr << "Exception opening/reading file";
      exit(-1);
    }

    is.seekg(0, ios_base::end);
    int length = is.tellg();
    is.seekg(0, ios_base::beg);

    char* buf = new char[(int)(1.1*length)];
    char* p = buf;
//    char * tmp_p = p;

    is.read(buf, length);
    is.close();
    
    
    ofstream fout2;
    if (!dry_run_)
    {
      try {
        fout2.open(file.c_str(), ios_base::trunc);
      } catch (std::ofstream::failure e) {
        cerr << "Exception opening/writing file";
        exit(-1);
      }
    }
    
    std::ostream * fout_ptr;
    
    if (dry_run_)
      fout_ptr = &std::cout;
    else
      fout_ptr = &fout2;
    std::ostream & fout = *fout_ptr; 

    int len = is.gcount();
    char *pe = p + len;
    char *eof = pe;

    %% write exec;

    /* Check if we failed. */
    if ( cs == PostProcess_error )
    {
      /* Machine failed before finding a token. */
      cerr << file << ": PARSE ERROR " << endl;
      cerr.write(p, 100);
      exit(-1);
    }

    if (!dry_run_)
      fout2.close();
    delete buf;

    return 0;
  }
};

void usage()
{
  cout << "mtocpp_post Version " << MTOCPP_VERSION_MAJOR << "."
    << MTOCPP_VERSION_MINOR << endl;
  cout << "Usage: mtocpp_post [-q] target" << endl;
  cout << "\nOptions:\n  -q\t\tsuppresses debug output.\n" << endl;
  cout << "  -f\t\tsingle file argument instead of directory." << endl;
}

/**
 * @change{dw,1,4,2012-11-19} Re-Added the possibility to directly specify a file target instead of a whole folder.
 */
int main(int argc, char ** argv)
{
  bool quiet = false;
  bool dry_run = false;
  bool isfile = false;
  string docdir;
  if(argc >= 2)
  {
    if (std::string("--help") == std::string(argv[1]))
    {
      usage();
      return 0;
    }
    if (argc == 3 && std::string("-q") == std::string(argv[1]))
    {
      quiet = true;
      docdir = argv[2];
    }
    else if (argc == 3 && std::string("-d") == std::string(argv[1]))
    {
      dry_run = true;
      docdir = argv[2];
    }
    else if (argc == 3 && std::string("-f") == std::string(argv[1]))
	{
	  isfile = true;
	  docdir = argv[2];
	}
    else if (argc == 3 && (std::string("-qf") == std::string(argv[1]) || std::string("-fq") == std::string(argv[1])))
	{
	  isfile = true;
	  quiet = true;
	  docdir = argv[2];
	}
    else if(argc == 2)
      docdir = argv[1];
    else
    {
      cerr << "wrong arguments!" << endl;
      usage();
      exit(-2);
    }
  }
  else
  {
    cerr << "wrong number of arguments!" << endl;
    usage();
    exit(-2);
  }

  if (!quiet) {
	  if (isfile) {
		  cout << "Running mtoc++ postprocessor on file " << docdir << endl;
	  } else {
		  cout << "Running mtoc++ postprocessor on directory " << docdir << endl;
	  }
  }

  PostProcess scanner(docdir, quiet, dry_run);
  if (isfile) {
	  scanner.postprocess(docdir);
  } else {
	  scanner.execute();
  }
  return 0;
}

/* vim: set et sw=2 ft=ragel: */

