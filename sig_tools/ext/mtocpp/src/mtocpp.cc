#include "mfilescanner.h"

#include <cassert>
#include <cstring>
#include <cstdlib>
#include <iostream>
#include <algorithm>
#include <iterator>
#ifdef WIN32
#define PATH_MAX 4096
#else
#ifdef __APPLE__
#include <limits.h>
#else
#include <linux/limits.h>
#endif
#endif

using std::cerr;
using std::cout;
using std::cin;
using std::endl;
using std::string;
using std::vector;
using std::list;
using std::copy;
using std::map;
using std::set;
using std::istream;
using std::ifstream;
using std::ostream;
using std::ostream_iterator;
using std::ostringstream;

void usage()
{
  cout
    << "This is mtocpp Version " << MTOCPP_VERSION_MAJOR << "." << MTOCPP_VERSION_MINOR << "\n"
    << "\n"
    << "mtocpp parses the Matlab m-file <mfile> and produces c++-compliant output that can be processed by doxygen.\n"
    << "\n"
    << "Usage: mtocpp <mfile> [<configuration-file>]\n"
    << "       mtocpp --help\n"
    << "\n"
    << "If no explicit configuration file is given, mtocpp also looks for './mtocpp.conf' by default." << endl;
}

/**
 * @change{1,4,dw,2012-10-22} Added an additional comment about indentation in matlab on parse errors
 *
 * @change{1,2,dw,2011-11-27} Included a new option \c --verbose for short mtoc++ version output.
 */
// main routine
int main(int argc, char ** argv)
{
  istream * fcin;
  std::ifstream fin;
  string filename;
  if(argc >= 2)
  {
    if (string(argv[1]) == string("--help"))
    {
      usage();
      exit(0);
    }
    if (string(argv[1]) == string("--version"))
    {
      cout << MTOCPP_VERSION_MAJOR << "." << MTOCPP_VERSION_MINOR << endl;
      exit(0);
    }
    std::ios_base::iostate oldstate = fin.exceptions();
    fin.exceptions ( ifstream::failbit );
    try
    {
      fin.open(argv[1]);
      fcin = &fin;
      filename = argv[1];
    }
    catch (std::ifstream::failure &e)
    {
      cout << "Exception opening/reading file: " << argv[1] << "\n";
      usage();
      exit(-1);
    }
    fin.exceptions(oldstate);
  }
  else
  {
    fcin = &cin;
    filename = "stdin";
  }

  std::string conffilename;
  if(argc == 3)
  {
    conffilename = std::string(argv[2]);
  }

#ifdef WIN32
  char buf[1000];
  _getcwd(buf, 1000);
  string cwd(buf);
#else
  string cwd;
  for (unsigned int bufsize = 1000; bufsize < PATH_MAX; bufsize*=2)
  {
    char buf[bufsize];
    if (getcwd(buf, bufsize) != 0 || errno != ERANGE)
    {
      cwd = buf;
      break;
    }
  }
#endif

  string::size_type found = 0;
  found = filename.find(cwd);
  if(found!=string::npos)
  {
    filename = filename.substr(cwd.size()+1);
  }
  RunMode runMode;
  MFileScanner scanner(*fcin, cout, filename, conffilename, runMode);
  scanner.execute();
  return 0;
}

/* vim: set et sw=2 ft=ragel foldmethod=marker: */

