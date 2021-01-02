#ifndef MFILESCANNER_H_
#define MFILESCANNER_H_

#include "config.h"

#include "confscanner.h"
#include <string>
#include <vector>
#include <map>
#include <set>
#include <list>
#include <sstream>
#include <fstream>

#ifdef WIN32
  #include <direct.h>
#else
extern "C" {
  #include <unistd.h>
  #include <errno.h>
}
#include <climits>
#endif

// 160 KB
#define BUFSIZE 100*16384

#define stringify( name ) #name

struct RunMode
{
  RunMode() : mode(Normal), methodname(),
  /* configuration defaults */
  latex_output(false),
  print_fields(PRINT_FIELDS),
  auto_add_fields(AUTO_ADD_FIELDS),
  auto_add_params(AUTO_ADD_PARAMETERS),
  auto_add_class_properties(AUTO_ADD_CLASS_PROPERTIES),
  auto_add_class(AUTO_ADD_CLASSES),
  copy_typified_field_docu(COPY_TYPIFIED_FIELD_DOCU),
  remove_first_arg_in_abstract_methods(REMOVE_FIRST_ARG_IN_ABSTRACT_METHODS),
  parse_of_type(ENABLE_OF_TYPE_PARSING),
  void_type_in_return_values(VOID_TYPE_IN_RETURN_VALUES),
  print_return_value_name(PRINT_RETURN_VALUE_NAME),
  generate_subfunction_documentation(GENERATE_SUBFUNTION_DOCUMENTATION)
  {}

  typedef enum
  {
    Normal = 0,
    ParseParams,
    ParseMethodParams
  } Mode;

  Mode mode;
  std::string methodname;
  bool latex_output;
  bool print_fields;
  bool auto_add_fields;
  bool auto_add_params;
  bool auto_add_class_properties;
  bool auto_add_class;
  bool copy_typified_field_docu;
  bool remove_first_arg_in_abstract_methods;
  bool parse_of_type;
  bool void_type_in_return_values;
  int print_return_value_name;
  bool generate_subfunction_documentation;
};

typedef enum
{
  Public = 0, Protected, Private
} AccessEnum;


/*extern const char * AccessEnumNames[];*/

typedef enum
{
  InClassComment,
  Header,
  Method,
  AtMethod,
  MethodDeclaration,
  Property,
  Event
} ClassPart;

/*extern const char * ClassPartNames[];*/

struct AccessStruct
{
  AccessEnum full;
  AccessEnum get;
  AccessEnum set;

public:
  AccessStruct()
    : full(Public), get(Public), set(Public) {};

  friend std::ostream & operator<<(std::ostream & os, AccessStruct & as);
};



struct PropParams
{
  bool constant;
  bool transient;
  bool dependent;
  bool hidden;
  bool setObservable;
  bool abstr;
  bool abortSet;

  std::string ccprefix()
  {
    if(constant)
      return "static const ";
    else
      return "";
  }

  std::string print_list()
  {
    std::ostringstream oss;
    char pre = '(';
    if(constant)
    {
      oss << pre << " Constant";
      pre = ',';
    }
    if(transient)
    {
      oss << pre << " Transient";
      pre = ',';
    }
    if(dependent)
    {
      oss << pre << " Dependent";
      pre = ',';
    }
    if(hidden)
    {
      oss << pre << " Hidden";
      pre = ',';
    }
    if(setObservable)
    {
      oss << pre << " setObservable";
      pre = ',';
    }
    if(abstr)
    {
      oss << pre << " Abstract";
      pre = ',';
    }
    if(pre == ',') oss << " )";
    return oss.str();
  }

public:
  PropParams()
    : constant(false),
      transient(false),
      dependent(false),
      hidden(false),
      setObservable(false),
      abstr(false) {};

  friend std::ostream & operator<<(std::ostream & os, PropParams & pp);
};

struct PropExtraInformation
{
  bool dependent;
  bool setter;
  bool getter;

public:
  PropExtraInformation()
    : dependent(false),
    setter(false),
    getter(false)
  {};
};

struct MethodParams
{
  bool abstr;
  bool statical;
  bool hidden;
  bool sealed;

  std::string ccprefix()
  {
    if(statical)
      return "static ";
    else if(abstr)
      return "virtual ";
    else
      return "";
  }
  std::string ccpostfix()
  {
    if(abstr)
      return " = 0;";
    else
      return ";";
  }

  std::string print_list()
  {
    std::ostringstream oss;
    char pre = '(';
    if(abstr)
    {
      oss << pre << " Abstract";
      pre = ',';
    }
    if(statical)
    {
      oss << pre << " Static";
      pre = ',';
    }
    if(hidden)
    {
      oss << pre << " Hidden";
      pre = ',';
    }
    if(sealed)
    {
      oss << pre << " Sealed";
      pre = ',';
    }
    if(pre == ',') oss << " )";
    return oss.str();

  }
public:
  MethodParams()
    : abstr(false),
      statical(false),
      hidden(false),
      sealed(false) {};

  friend std::ostream & operator<<(std::ostream & os, MethodParams & mp);
};

template <class ST>
class ordered_map : public std::vector<std::pair<std::string, ST> >
{
public:

  typedef std :: pair< std :: string, ST >                           item;
  typedef std :: vector< item >                                      base_type;
  typedef typename base_type :: iterator                             iterator;
  typedef typename base_type :: const_iterator                       const_iterator;

public:

  ordered_map() : base_type()
  {};

  ST & operator[](const std::string & key)
  {
    iterator it = this->find(key);
    if (it == this->end())
    {
      this->push_back(make_pair(key, ST()));
      it = this->end() - 1;
    }
    return it->second;
  }

  iterator find(const std::string & key)
  {
    iterator it = this->begin();
    for (; it != this->end(); ++it)
    {
      if (it->first == key)
        break;
    }
    return it;
  }
};

/**
 * @class MFileScanner
 *
 * @change{1,4,md,2012-10-19} prettify the output of postprocessed source
 * for source code browsing in doxygen. Now, we recommend the usage of the
 * FILTER_SOURCE_FILES doxygen switch.
 *
 * @change{1,4,md,2012-10-17} implemented varargin handling by Matlab
 * inputParser, as suggested here:
 * http://www.mathworks.de/de/help/matlab/ref/inputparser.parse.html
 *
 * @change{1,4,md,2012-02-24} ignore comments in front of classdef (fixes
 * Grrr message from Jesse Hopkins)
 *
 * @change{1,3,md,2012-02-17} added events section
 *
 * @change{1,3,md,2012-02-15} improved documentation for dependent flags
 *
 * @change{1,3,md,2012-02-15} remove =0 for purely virtual class methods
 *
 * @change{1,3,md,2012-02-15} bugfix: no Grrr! messages for complex property
 * declarations.
 *
 * @change{1,3,md,2012-02-15} We totally ignore functions which are locally
 * defined inside another function.
 *
 * @change{1,3,md,2012-02-15} Added config GENERATE_SUBFUNTION_DOCUMENTATION
 * and format for output of subfunctions.
 *
 * @change{1,3,md,2012-02-03} Bugfix: Default values were printed twice if
 * documented in the documenation block and given as property default values.
 * Now, the documentated default value is preferred.
 *
 * @change{1,3,md,2012-02-03} Improved the automatic documentation text for
 * MATLAB specific attributes of properties and methods, add a link to the
 * online MATLAB documentation.
 *
 * @new{1,3, md, 2012-02-03} Print a warning message to stderr when optional
 * parameter in methods of functions are not documented with default values.
 *
 * @new{1,3,md,2012-01-10} "Bugfix": Allowing the use of the \c AbortSet tag in
 * property declarations, however, to extra action (e.g. inserting a note in
 * documentation) is taken so far.
 *
 * @change{1,3,md,2012-01-10} Some minor modifications for the postprocessor
 * regarding dots '.' and '::'
 *
 * @new{1,3,md,2011-12-16} Allowing multiple lines for default values in
 * property comments & code and added a test case.
 *
 * @change{1,3,md,2011-12-16} Bugfix: On Windows platforms the wrong \c getcwd
 * command was issued and is now fixed.
 *
 * @change{1,3,md,2011-12-13} Bugfix: Now handling the \b Abstract property
 * correctly (was previously added for \b SetObservable declarations due to
 * copy&paste)
 *
 * @change{1,3,md,2012-01-13}  Added a test case for default properties
 * containing semicolons
 *
 * @change{1,3,md,2012-01-13} Changed format for documentation of default
 * properties and parameters
 *
 * @change{1,3,md,2012-01-13} Default arguments for properties are added to the
 * properties documentation block
 *
 * @change{1,3,md,2012-01-13} Bugfix: observable properties have been
 * documented as abstract ones.
 *
 * @change{1,3,md,2011-12-13} Adding a bold "Default:" line in property
 * documentation blocks if a default value/default tag is set in either code or
 * property comment.
 *
 * @change{1,3,md,2011-12-04} Bugfix reported by Evgeny Pr on mathworks: allow
 * property definitions not ended by semicolons.
 *
 * @change{1,2,md,2011-11-28}
 * Allow long (including line breaks) default values for properties
 *
 * @change{1,2,md,2011-11-17} Fixed a bug that messed up the documentation if a
 * new line was started after a @@type tag and added a test case to classA.m
 *
 * @change{1,2,md,2011-11-17} Non-standard access modifier strings are now
 * separated by a comma
 *
 * @change{1,2,md,2011-11-17} Fixed a parse error occuring with the new
 * ~-notation in newer MatLab versions. Calls like <tt>foo = bar(par1, ~,
 * par3)</tt> now work.
 *
 * @change{1,2,md,2011-11-17} The order of @@default and @@type tags in
 * parameters (if occurring) is no longer fixed.
 *
 * @new{1,2,md,2011-11-17} New config flag COPY_TYPIFIED_FIELD_DOCU which
 * allows to toggle the automatic insertion of required fields for method
 * parameters.
 * This flag sets whether the documentation of fields in 'Required fields of
 * param', 'Optional fields of param' or 'Generated fields of retval' shall be
 * copied
 * in case the Parameter 'param' or 'retval' have a type.
 */
class MFileScanner
{
public:
  typedef std :: vector< std :: string >                             DocuBlock;
  typedef ordered_map< DocuBlock >                                   DocuList;
  typedef ordered_map< DocuList >                                    DocuListMap;
  typedef std :: map< std :: string, DocuBlock >                     AltDocuList;
  typedef std :: map< std :: string, AltDocuList >                   AltDocuListMap;
  typedef std :: set< std :: string >                                GroupSet;

  typedef ordered_map<std::pair<int, std::string> >        VararginParserValuesType;

public:
  MFileScanner (std::istream & fin, std::ostream & fout,
                const std::string & filename,
                const std::string & conffilename,
                RunMode runmode);

  virtual ~MFileScanner()
  {
    delete buf;
  }

  int execute();

  DocuList & getParamList()
  {
    return param_list_;
  }

  MethodParams & getMethodParams()
  {
    return methodparams_;
  }

  void end_function();


private:

  void extract_default_argument_of_inputparser(std::string & last_args);
  void add_access_info(std::string);
  void add_property_params_info();
  void add_method_params_info();
  void end_of_class_doc();
  std::string access_specifier_string(AccessEnum & access);
  void print_access_specifier(AccessEnum & access, MethodParams & mp, PropParams & pp);
  void print_pure_function_synopsis();
  void print_function_synopsis();
  void end_of_property_doc();
  void get_typename(const std::string &, std::string &, std::string voidtype = std::string("matlabtypesubstitute"));
  void get_default(const std::string &, std::string &);
  void handle_param_list_for_varargin();
  void extract_typen(DocuBlock & db, std::string & typen, bool remove = false);
  const std::string & extract_default(DocuBlock &, std::string &);
  void update_method_params(const std::string & methodname);

  void end_method();
  void clear_lists();
  std::string namespace_string();

  void cout_ingroup();
  void cout_docuheader(std::string, bool clear = true);
  void cout_docubody();
  void cout_docuextra();
  const std::string & replace_underscore(std::string & s);

  const std::string & escape_chars(std::string & s);

  void print_warning(const std::string &);
  void write_docu_block(const DocuBlock & block);

  void write_docu_list(const DocuList & list,
                       const std::string & item_text,
                       const AltDocuList & alternative,
                       bool,
                       const std::string separator,
                       const std::string docu_list_name);

  void write_docu_listmap(const DocuListMap & listmap,
                          const std::string & text,
                          const AltDocuListMap & altlistmap);


  void debug_output(const std::string & msg, char * p);

  void postprocess_unused_params(std::string &, DocuList & );

private:
  std::istream & fin_;
  std::ostream & fout_;
  const std::string  filename_;
  ConfFileScanner cscan_;
  std::string  fnname_;
  std::list<std::string> namespaces_;
  char         *buf;
  int          line            , col;
  char        *ts              , *te;
  int          act             , have;
  int          cs;
  int          top;
  int          stack[10];
  bool         opt;
  bool         new_syntax_;
  DocuListMap  required_list_;
  DocuListMap  optional_list_;
  DocuListMap  retval_list_;
  DocuList     param_list_;
  DocuList     return_list_;
  DocuBlock    returnlist_;
  DocuList    *clist_;
  DocuBlock    docuheader_;
  DocuBlock    docubody_;
  DocuBlock    docuextra_;
  DocuBlock    paramlist_;
/*  AltDocuList  param_defaults_;*/
  std::string  cfuncname_;
  GroupSet     groupset_;
  bool         is_script_;
  bool         is_first_function_;
  bool         is_class_;
  bool         is_setter_;
  bool         is_getter_;
  std::string  classname_;
  std::string::size_type funcindent_;
  ClassPart    class_part_;
  AccessStruct access_;
  PropParams   propertyparams_;
  MethodParams methodparams_;
  std::vector<std::string> property_list_;
  RunMode      runMode_;
  std::string  defaultprop_;
  std::string  dirname_;

  std::map<std::string,std::string> param_type_map_;
  bool undoced_prop_;
  std::map<std::string, PropExtraInformation> specifier_;

  std::string varargin_parser_candidate_;
  VararginParserValuesType varargin_parser_values_;
  std::ostringstream warning_buffer_;

};

extern const char * AccessEnumNames[];

extern const char * ClassPartNames[];

/* vim: set et sw=2: */
#endif /* MFILESCANNER_H_ */

