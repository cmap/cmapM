/*
 * mfilescanner_code.cc
 *
 *  Created on: 17.10.2012
 *      Author: mdroh_01
 */

#include "mfilescanner.h"
#include <cassert>
#include <cstring>
#include <cstdlib>
#include <iostream>
#include <algorithm>
#include <iterator>

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

const char * AccessEnumNames[] =
{
  stringify( Public ),
  stringify( Protected ),
  stringify( Private )
};

const char * ClassPartNames[] =
{
  stringify( InClassComment ),
  stringify( Header ),
  stringify( Method ),
  stringify( AtMethod ),
  stringify( MethodDeclaration ),
  stringify( Property ),
  stringify( Event )
};




void MFileScanner :: update_method_params(const std::string & methodname)
{
  istream  *fcin;
  ifstream  fin;
  try
  {
    std::string filename(dirname_ + "/" + classname_ + ".m");
    std::ios_base::iostate oldstate = fin.exceptions();
    fin.exceptions ( ifstream::failbit | ifstream::badbit );
    fin.open(filename.c_str());
    fin.exceptions(oldstate);
    fcin = &fin;
    ostringstream oss;
    RunMode methodParamsMode = runMode_;
    methodParamsMode.mode = RunMode::ParseMethodParams;
    methodParamsMode.methodname = methodname;
    MFileScanner scanner(*fcin, oss, filename, cscan_.get_conffile(), methodParamsMode);
    scanner.execute();
    methodparams_ = scanner.getMethodParams();
  }
  catch (const ifstream::failure & e)
  {
    std::cerr << "MTOCPP Warning: No method params for @-function " << methodname << " found!\n";
  }
}

/** prints the c++ function synopsis into the c++ source file and the frist
 * line of the corresponding documentation block.
 *
 */
void MFileScanner :: print_pure_function_synopsis()
{
  // do we have a constructor?
  if(is_class_ && (cfuncname_ == classname_))
    returnlist_.clear();
  else{
    if(returnlist_.size() == 0)
      fout_ << "noret::substitute ";
    else
    {
      if(returnlist_.size() > 1)
        fout_ << "mlhsSubst<";
      for(unsigned int i=0; i < returnlist_.size(); ++i)
      {
        std::string typen;
        if(runMode_.void_type_in_return_values)
          get_typename(returnlist_[i], typen, "void");
        else
          get_typename(returnlist_[i], typen);

        fout_ << "mlhsInnerSubst<" << typen;
        if (runMode_.print_return_value_name - (returnlist_.size() == 1) > 0)
          fout_ << "," << returnlist_[i];
        fout_ << "> ";
        if (i < returnlist_.size() - 1)
          fout_ << ",";
      }
      if(returnlist_.size() > 1)
        fout_ << "> ";
    }
  }

  bool first = true;
  if(is_first_function_)
  {
    if(is_class_ && class_part_ == AtMethod)
      fout_ << namespace_string() << classname_ << "::";
  }
  else
    fout_ << "mtoc_subst_" << fnname_ << "_tsbus_cotm_";

  fout_ << cfuncname_;

  if(paramlist_.size() == 0)
    fout_ << "()";
  else
  {
#if DEBUG
    cerr << "paramlist size of " << cfuncname_ << ": " << paramlist_.size() << " first element: " << paramlist_[0] << endl;
#endif
    fout_ << "(";

    bool is_default_necessary = false;
    for(unsigned int i=0; i < paramlist_.size(); ++i)
    {
      if(!first)
        fout_ << ",";
      else
        first = false;

      std::string typen;// = "matlabtypesubstitute";
      get_typename(paramlist_[i], typen);
      std::string defvalue;
      get_default(paramlist_[i], defvalue);
      if (defvalue.empty())
      {
        if (is_default_necessary && paramlist_[i] != "varargin")
        {
          std::ostringstream oss;
          oss << "Optional parameter '" << paramlist_[i] << "' of method '" 
              << cfuncname_ << "' has no specified default value";
          print_warning(oss.str());
        }
      }
      else
        is_default_necessary = true;

      fout_ << typen << " " << paramlist_[i];
    }
/*    for(unsigned int i=0; i < returnlist_.size(); ++i)
    {
      std::string typen;// = "matlabtypesubstitute";
      get_typename(returnlist_[i], typen);
    }
*/
    fout_ << ")";
  }
}

/**
 * @change{1,4,dw,2012-11-19} Removed the current line from warning messages, as the line numbers are sometimes grossly
 * wrong due to the way Ragel "counts" them
 */
void MFileScanner :: print_warning(const std::string & message)
{
  std::cerr << "mtoc++ warning in " << filename_ << ": " << message << "\n";
  warning_buffer_ << "mtoc++ warning: " << message << "\n";
}

/*
 * @change{1,4,dw,2012-10-29} Added a short comment after inclusion of getter/setter sources
 */
void MFileScanner :: print_function_synopsis()
{
  if(is_getter_) {
   	fout_ << "\n#if 0 //mtoc++: 'get." << cfuncname_ << "'\n";
  } else if (is_setter_){
    fout_ << "\n#if 0 //mtoc++: 'set." << cfuncname_ << "'\n";
  }
  if(is_class_ && (class_part_ == Method
                   || class_part_ == AtMethod
                   || class_part_ == MethodDeclaration)
    )
  {
    fout_ << methodparams_.ccprefix();
  }

  print_pure_function_synopsis();

  if(is_class_ && class_part_ == MethodDeclaration )
    fout_ << methodparams_.ccpostfix() << "\n";
  else
    fout_ << " {\n";
}

std::string MFileScanner :: access_specifier_string(AccessEnum & access)
{
  if(access == Public)
    return "public";
  else if(access == Protected)
    return "protected";
  else if(access == Private)
    return "private";
  return "";
}

void MFileScanner :: print_access_specifier(AccessEnum & access, MethodParams & mp, PropParams & pp)
{
  const std::string ass = access_specifier_string(access);
  const std::string mp_list = mp.print_list();
  const std::string pp_list = pp.print_list();
  fout_ << ass << ":";
  if (!mp_list.empty())
    fout_ << " /* " << mp_list << " */";
  if (!pp_list.empty())
    fout_ << " /* " << pp_list << " */";
  fout_ << "\n\n";
}

/*
 * constructor
 *
 * @change{1,5,dw,2013-07-01} Included the class modifier "Hidden" for parsing.
 * Thanks to MathWorks Pilot Engineer '''Arvind Jayaraman''' for providing the feedback and code!
 *
 */
MFileScanner :: MFileScanner(istream & fin, ostream & fout,
                             const std::string & filename,
                             const std::string & conffilename,
                             RunMode runMode = RunMode()
                            ) :
  fin_(fin), fout_(fout), filename_(filename),
  cscan_(filename_, conffilename),
  fnname_(filename), namespaces_(),
  buf(new char[BUFSIZE]), line(1),
  ts(0), have(0), top(0),
  opt(false), new_syntax_(false),
  is_script_(false), is_first_function_(true),
  is_class_(false), is_setter_(false), is_getter_(false),
  classname_(), funcindent_(0),
  class_part_(Header),
  access_(), propertyparams_(), methodparams_(), property_list_(),
  runMode_(runMode),
  undoced_prop_(false)
{
  string::size_type found = fnname_.find_last_of('/');
  if(found != string::npos)
    dirname_ = filename.substr(0, found);

  list<string> namespaces;
  string classname;
  string::size_type enddir = dirname_.size();
  string::size_type ppos = 0;
  while (ppos != string::npos)
  {
    ppos = dirname_.find_last_of('/', enddir);
    string directory;
    if(ppos == string::npos)
      directory = dirname_.substr(0, enddir+1);
    else
      directory = dirname_.substr(ppos+1, enddir-ppos);

    if(directory[0] == '+')
    {
      namespaces_.push_front(directory.substr(1));
    }
    else if(directory[0] == '@')
    {
      classname_ = directory.substr(1);
      is_class_ = true;
      if(classname_
          != fnname_.substr(fnname_.find_last_of('/')+1, classname_.size()))
      {
        class_part_ = AtMethod;
        fout_ << "#include \"" << classname_ << ".m\"" << endl;
      }
    }
    else
      break;
    enddir = ppos - 1;
  }
  for (list<string>::iterator it = namespaces_.begin();
       it != namespaces_.end(); ++it)
    fout_ << "namespace " << *it << "{" << endl;
  fout_ << "\n";

  found = fnname_.rfind("/");
  if(found != string::npos)
    fnname_ = fnname_.substr(found+1);
  for( std::string::size_type i = 0; i < fnname_.size(); ++i )
  {
    if(fnname_[i] == '@')
      fnname_[i] = '_';
    else if(fnname_[i] == '.')
      fnname_[i] = '_';
  }

  cscan_.execute();
  if(cscan_.vars_.find(string("LATEX_OUTPUT"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("LATEX_OUTPUT")][0] == string("true"))
    {
      runMode_.latex_output = true;
    }
    else
    {
      runMode_.latex_output = false;
    }
  }
  if(cscan_.vars_.find(string("PRINT_FIELDS"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("PRINT_FIELDS")][0] == string("true"))
    {
      runMode_.print_fields = true;
    }
    else
    {
      runMode_.print_fields = false;
    }
  }
  if(cscan_.vars_.find(string("COPY_TYPIFIED_FIELD_DOCU"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("COPY_TYPIFIED_FIELD_DOCU")][0] == string("true"))
    {
      runMode_.copy_typified_field_docu = true;
    }
    else
    {
      runMode_.copy_typified_field_docu = false;
    }
  }
  if(cscan_.vars_.find(string("AUTO_ADD_FIELDS"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("AUTO_ADD_FIELDS")][0] == string("true"))
    {
      runMode_.auto_add_fields = true;
    }
    else
    {
      runMode_.auto_add_fields = false;
    }
  }
  if(cscan_.vars_.find(string("AUTO_ADD_PARAMETERS"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("AUTO_ADD_PARAMETERS")][0] == string("true"))
    {
      runMode_.auto_add_params = true;
    }
    else
    {
      runMode_.auto_add_params = false;
    }
  }
  if(cscan_.vars_.find(string("AUTO_ADD_CLASS_PROPERTIES"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("AUTO_ADD_CLASS_PROPERTIES")][0] == string("true"))
    {
      runMode_.auto_add_class_properties = true;
    }
    else
    {
      runMode_.auto_add_class_properties = false;
    }
  }
  if(cscan_.vars_.find(string("AUTO_ADD_CLASSES"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("AUTO_ADD_CLASSES")][0] == string("true"))
    {
      runMode_.auto_add_class = true;
    }
    else
    {
      runMode_.auto_add_class = false;
    }
  }
  if(cscan_.vars_.find(string("REMOVE_FIRST_ARG_IN_ABSTRACT_METHODS"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("REMOVE_FIRST_ARG_IN_ABSTRACT_METHODS")][0] == string("true"))
    {
      runMode_.remove_first_arg_in_abstract_methods = true;
    }
    else
    {
      runMode_.remove_first_arg_in_abstract_methods = false;
    }
  }
  if(cscan_.vars_.find(string("ENABLE_OF_TYPE_PARSING"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("ENABLE_OF_TYPE_PARSING")][0] == string("true"))
    {
      runMode_.parse_of_type = true;
    }
    else
    {
      runMode_.parse_of_type = false;
    }
  }
  if(cscan_.vars_.find(string("VOID_TYPE_IN_RETURN_VALUES"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("VOID_TYPE_IN_RETURN_VALUES")][0] == string("true"))
    {
      runMode_.void_type_in_return_values = true;
    }
    else
    {
      runMode_.void_type_in_return_values = false;
    }
  }
  if(cscan_.vars_.find(string("PRINT_RETURN_VALUE_NAME"))!=cscan_.vars_.end())
  {
    string tmp = cscan_.vars_[string("PRINT_RETURN_VALUE_NAME")][0];
    if(tmp == string("0"))
    {
      runMode_.print_return_value_name = 0;
    }
    else if(tmp == string("1"))
    {
      runMode_.print_return_value_name = 1;
    }
    else
    {
      runMode_.print_return_value_name = 2;
    }
  }
  if(cscan_.vars_.find(string("GENERATE_SUBFUNTION_DOCUMENTATION"))!=cscan_.vars_.end())
  {
    if(cscan_.vars_[string("GENERATE_SUBFUNTION_DOCUMENTATION")][0] == string("true"))
    {
      runMode_.generate_subfunction_documentation = true;
    }
    else
    {
      runMode_.generate_subfunction_documentation = false;
    }
  }
};

// escape '@' and '\' characters in string \a s
const string & MFileScanner::escape_chars(std::string & s)
{
  string::size_type found = s.find_first_of("@\\");
  while(found != string::npos )
  {
    s.insert(found, "\\");
    found = s.find_first_of("@\\",found+2);
  }
  return s;
}

// standard brief text (replace '_' -> ' ' in s)
const string & MFileScanner::replace_underscore(std::string & s)
{
  string::size_type found = s.find("_");
  while(found != string::npos )
  {
    s[found] = ' ';
    found = s.find("_", found+1);
  }
  return s;
}

// pretty print the documentation block \a block
void MFileScanner::write_docu_block(const DocuBlock & block_orig)
{

  DocuBlock block = block_orig;
  std::string temp;
  extract_typen(block, temp, true);

  bool add_prefix   = false;
  bool latex_begin  = true;
  bool not_verbatim = true;
  for( unsigned int i = 0; i < block.size(); i += 1 )
  {
    // begin all documentation lines after the first one with an asterisk (unless in verbatim mode)
    if(add_prefix)
    {
      if(not_verbatim)
        fout_ << "* ";
      else
        fout_ << "  ";
    }

    add_prefix = false;
    // read in new line of docu block
    const string & s = block[i];

    // parse for special comments
    string::size_type j=0;
    const char * tokens = "\'`@\n";
    bool last_char_escaped = false;
    for( string::size_type i = 0; j < s.size(); i=j )
    {
      j=s.find_first_of(tokens,i+1);
      if(j==string::npos)
        j=s.size();
      if(s[j-1] == '\\' && not_verbatim && latex_begin)
        --j;
      // respect @code and @verbatim blocks
      if(s[i] == '@')
      {
        if(s.substr(i+1,4) == "code" || s.substr(i+1,8) == "verbatim")
          not_verbatim = false;
        else if(s.substr(i+1,7) == "endcode" || s.substr(i+1,11) == "endverbatim")
          not_verbatim = true;
        fout_ << s.substr(i,j-i);
      }
      // use typewriter fonts for words in single quotes
      else if(s[i] == '\'' && not_verbatim && latex_begin)
      {
        if(j != s.size() && s[j] == '\'' && !last_char_escaped)
        {
          if(j==i+1)
            fout_ << '\'';
          else
            fout_ << "<tt>" << s.substr(i+1, j-i-1) << "</tt>";
          ++j;
        }
        else
          fout_ << s.substr(i,j-i);
      }
      // use latex output for words in backtick quotes
      else if(s[i] == '`' && not_verbatim)
      {
        string lout;
        if(!last_char_escaped)
        {
          // in case of double backtick quotes, use latex block
          if(s[i+1] == '`')
          {
            if(latex_begin)
              lout = "@f[";
            else
              lout = "@f]";
            ++i;
            j=s.find_first_of(tokens,i+1);
            if(j==string::npos)
              j=s.size();
          }
          else
            lout = "@f$";
          if(latex_begin)
            latex_begin = false;
          else
            latex_begin = true;
          ++i;
        }
        else
        {
          lout = "";
        }
        fout_ << lout << s.substr(i, j-i);
      }
      // new line
      else if(s[i] == '\n')
      {
        fout_ << "\n  ";
        if(latex_begin)
          add_prefix = true;
        else
        {
          fout_ << "  ";
          add_prefix = false;
        }
      }
      else
      {
        fout_ << s.substr(i,j-i);
      }
      if(s[j-1] != '\\' && s[j] == '\\')
      {
        last_char_escaped = true;
      }
      else
        last_char_escaped = false;
      if(s[j] == '\\')
        ++j;
    }
  }
}

/* pretty print the documentation block list \a list for the list item named \a
 * item_text. If docu blocks are empty, \a alternative is used. The alternative
 * is normally read in by the confscanner.
 *
 * @change{1,4,dw,2012-11-06} Now auto-adding a comment for unused parameters to the processed file.
 */
void MFileScanner::write_docu_list(const DocuList & list,
                                   const string & item_text,
                                   const AltDocuList & alternative,
                                   bool add_undocumented = false,
                                   const string separator = string(),
                                   const string docu_list_name = string())
{
  typedef DocuList :: const_iterator                                 list_iterator;
  typedef AltDocuList :: const_iterator                              alt_list_iterator;
  list_iterator lit = list.begin();
  // iterate over documentation blocks
  for(; lit != list.end(); ++lit)
  {
    std::string name = (*lit).first;
    /*
     * Special treatment for ~ parameters; here we just display a hint that this parameter is marked as unused
     * in the source m-file.
     */
    if (name.substr(0, 6) == std::string("unused")
        && name.find_first_not_of("0123456789", 7) == std::string::npos) {
    	ostringstream oss;
    	oss << "* " << item_text << " " << name << separator << " Marked as \"~\" in original m-file.\n  ";
    	fout_ << oss.str();
      continue;
    }
    ostringstream oss;
    oss << "* " << item_text << " " << name << separator << "    ";
    const DocuBlock & block = (*lit).second;

    bool use_alternative = false;
    if(block.size() == 1)
    {
      size_t typeof_length = 0;
      if (block[0].substr(0, 9) == std::string(" of type "))
        typeof_length = 9;
      else if (block[0].substr(0, 7) == std::string(" @type "))
        typeof_length = 7;

      if (typeof_length > 0
           && block[0].find_first_of(" ", typeof_length) == std::string::npos)
        use_alternative = true;
    }

    if(block.empty() || use_alternative)
    {
      // then look for alternative documentation block from global
      // configuration file ...
      alt_list_iterator alit = alternative.find((*lit).first);
      if(alit == alternative.end() || (*alit).second.empty())
      {
        string s((*lit).first);
        typedef map< string, string > :: iterator                  MapIterator;
        MapIterator param_type_map_entry = param_type_map_.end();
        if(!docu_list_name.empty() && runMode_.copy_typified_field_docu)
        {
          param_type_map_entry = param_type_map_.find(docu_list_name);
        }

        if(param_type_map_entry != param_type_map_.end())
        {
          // ... or copy documentation brief text from class documentation ...
          string temp = s.substr(0, s.find_first_of("."));
          fout_ << oss.str() << "@copybrief " << (*param_type_map_entry).second << "::" << temp << "\n  ";
        }
        else
        {
          if (add_undocumented)
          {
            // ... or use default text generated from variable name.
            fout_ << oss.str() << replace_underscore(s) << "\n  ";
          }
        }
      }
      else
      {
        fout_ << oss.str();
        write_docu_block((*alit).second);
      }
    }
    else
    {
      fout_ << oss.str();
      write_docu_block(block);
    }
  }
}

//! pretty print a documentation block list map \a listmap with prepended title
//! \a text. If listmap entry is empty, \a altlistmap is used instead.
void MFileScanner::write_docu_listmap(const DocuListMap & listmap,
                                      const string & text,
                                      const AltDocuListMap & altlistmap)
{
  typedef DocuListMap :: const_iterator                              map_iterator;
  typedef AltDocuListMap :: const_iterator                           alt_map_iterator;
  if(!listmap.empty())
  {
    map_iterator mit = listmap.begin();
    for(; mit != listmap.end(); ++mit)
    {
      fout_ << "*\n  ";
      fout_ << "* " << text << (*mit).first << ":\n  ";
      alt_map_iterator amit = altlistmap.find((*mit).first);
      write_docu_list((*mit).second,
                      "@arg \\c",
                      ( amit != altlistmap.end() ? (*amit).second : AltDocuList() ),
                      runMode_.auto_add_fields,
                      "&nbsp;&mdash;&nbsp;",
                      (*mit).first );
    }
//    fout_ << "* </TABLE>\n  ";

  }
}

string MFileScanner::namespace_string()
{
  ostringstream oss;
  oss << "";
  for( list<string>::iterator it = namespaces_.begin();
       it != namespaces_.end(); ++it)
  {
    oss << *it << "::";
  }
  return oss.str();
}

void MFileScanner::end_of_class_doc()
{
  if (!docuheader_.empty() || runMode_.auto_add_class)
  {
    fout_ << "/** @class \"" << namespace_string() << classname_ << "\"\n  ";

    cout_ingroup();

    fout_ << "* @brief ";
    cout_docuheader(cfuncname_);
    fout_ << "*\n  ";
    cout_docubody();
    fout_ << "*\n ";
    cout_docuextra();
    fout_ << "*/\n";
  }

  const std::string & warnings = warning_buffer_.str();
  if (!warnings.empty())
  {
    fout_ << "/* " << warnings << " */";
  }
  warning_buffer_.str("");
  warning_buffer_.clear();
}


/** print the documentation block for a property after all information about
 * its declaration has been gathered.
 *
 */
void MFileScanner::end_of_property_doc()
{
  if (undoced_prop_)
  {
    add_property_params_info();
    typedef DocuBlock :: iterator                                    DBIt;
    string typen;
    if (class_part_ == Event)
      typen = "EVENT";
    else
    {
      extract_typen(docuheader_, typen);
      if(typen.empty())
        extract_typen(docubody_, typen);

      if(typen.empty())
        typen = "matlabtypesubstitute";
    }

    fout_ << propertyparams_.ccprefix() << typen << " " << property_list_.back();
    if(defaultprop_.empty())
      fout_ << ";\n";
    else
      fout_ << " = " << defaultprop_ << ";\n";

    string defval;
    extract_default(docubody_, defval);
    if (!defval.empty())
      defaultprop_.clear();

    if (!docuheader_.empty() || runMode_.auto_add_class_properties || class_part_ == Event)
    {
      fout_ << "/** @var " << property_list_.back() << "\n  ";
      fout_ << "* @brief ";
      cout_docuheader(property_list_.back());
      fout_ << "*\n  ";
      cout_docubody();
      fout_ << "*\n  ";
      cout_docuextra();
      if(!defaultprop_.empty())
      {
        fout_ << "* <br/>@b Default: " << defaultprop_ << "\n";
      }
      if (class_part_ == Event)
        fout_ << "* @event " << property_list_.back() << "\n  ";
      fout_ << "*/\n";
    }
    docuheader_.clear();
    docubody_.clear();
    docuextra_.clear();
  }
  undoced_prop_ = false;
}

void MFileScanner::cout_docuheader(string altheader, bool clear)
{
  if(docuheader_.empty() && cscan_.docuheader_.empty())
  {
    fout_ << replace_underscore(altheader) << "\n  ";
  }
  else
  {
    if(! docuheader_.empty())
    {
      write_docu_block(docuheader_);
    }
    if(! cscan_.docuheader_.empty())
    {
      write_docu_block(cscan_.docuheader_);
    }
  }
  if(clear)
    docuheader_.clear();
}

void MFileScanner :: cout_docubody()
{
  if(!docubody_.empty())
  {
    fout_ << "*\n  * ";
    write_docu_block(docubody_);
  }
  docubody_.clear();
  if(!cscan_.docubody_.empty())
  {
    fout_ << "*\n  * ";
    write_docu_block(cscan_.docubody_);
  }
}

void MFileScanner :: cout_docuextra()
{
  if(! cscan_.docuextra_.empty())
  {
    fout_ << "*\n  * ";
    write_docu_block(cscan_.docuextra_);
  }
  if(! docuextra_.empty())
  {
    fout_ << "*\n  * ";
    write_docu_block(docuextra_);
  }
  docuextra_.clear();
}

void MFileScanner :: cout_ingroup()
{
  typedef GroupSet     :: iterator group_iterator;
  // add @ingroup commands from the configuration file
  if((! groupset_.empty() || ! cscan_.groupset_.empty() ))
  {
    fout_ << "* @ingroup ";
    bool not_first = false;
    group_iterator git = cscan_.groupset_.begin();
    for(; git != cscan_.groupset_.end(); ++git)
    {
      if(not_first)
        fout_ << " ";
      else
        not_first = true;

      fout_ << *git;
    }
    groupset_.clear();
    fout_ << "\n  ";
  }
}

void MFileScanner::clear_lists()
{
#ifdef DEBUG
  std::cerr << "clear lists" << endl;
#endif
  paramlist_.clear();
  /* param_defaults_.clear(); */
  returnlist_.clear();
  param_list_.clear();
  return_list_.clear();
  required_list_.clear();
  optional_list_.clear();
  retval_list_.clear();
  param_type_map_.clear();

  varargin_parser_candidate_.clear();
  varargin_parser_values_.clear();
}

/* we come here, from an empty line in a methods block or the end of a
 * methods block
 */
void MFileScanner::end_method()
{
  if (!cfuncname_.empty())
  {

    if(runMode_.mode != RunMode::ParseMethodParams
       && docuheader_.empty()
       && !methodparams_.abstr)
    {
      istream  *fcin;
      ifstream  fin;
      try
      {
        std::string filename(dirname_ + "/" + cfuncname_ + ".m");
        std::ios_base::iostate oldstate = fin.exceptions();
        fin.exceptions ( ifstream::failbit | ifstream::badbit );
        fin.open(filename.c_str());
        fin.exceptions(oldstate);
        fcin = &fin;
        ostringstream oss;
        RunMode paramsMode = runMode_;
        paramsMode.mode = RunMode::ParseParams;
        MFileScanner scanner(*fcin, oss, filename, cscan_.get_conffile(), paramsMode);
        scanner.execute();
        param_list_ = scanner.getParamList();
      }
      catch (const ifstream::failure & e)
      {
        std::ostringstream oss;
        oss << "Class " << classname_ << " misses definition of function " << cfuncname_ << "!";
        print_warning(oss.str());
      }
    }

    class_part_ = MethodDeclaration;
    print_function_synopsis();
    class_part_ = Method;

    // for abstract methods: print out documentation of the abstract method
    // declaration
    if(methodparams_.abstr)
      end_function();
    else
    // otherwise: all the following comments are not related to this function
    // anymore, so we delete traces of the method name...
    {
      cfuncname_.clear();
      clear_lists();
    }
  }
  // free documentation block variables
  docuheader_.clear();
  docubody_.clear();
  docuextra_.clear();
}

const std::string & MFileScanner::extract_default(DocuBlock & db, std::string & defvalue)
{
  typedef DocuBlock :: iterator                                      DBIt;

  for(DBIt dit = db.begin(); dit != db.end(); ++dit)
  {
    std::string & line   = *dit;
    size_t found         = std::string::npos;
    size_t deflength     = std::string("(default").length();
    found                = line.find("(default");
    if(found != std::string::npos)
    {
      size_t tmp;
      if(line[found+1] == '=')
        tmp = found + deflength + 1;
      else if (line[found+2] == '=')
        tmp = found + deflength + 2;
      else
        found = std::string::npos;

      if (found != std::string::npos)
      {
        defvalue = line.substr(tmp+1);
        defvalue = defvalue.substr(0, defvalue.length() - 1);
      }
    }
    if(found == std::string::npos)
    {
      deflength     = string("@default ").length();
      found         = line.find("@default ");
      if (found != std::string::npos)
      {
        size_t end = line.find("@", found+1);
        if (end == std::string::npos)
          end = line.find("of type");
        if (end == std::string::npos)
          end = line.length();
        end = end - 1;
        size_t start = found + deflength;
        defvalue = line.substr(start, end - start);
        line[found]   = '(';
        line[found+8] = '=';
        line = line.substr(0, found) + "@b Default: "
          + line.substr(found+9,end-found-9) + " " + line.substr(end);
      }
    }
  }
  return defvalue;
}

void MFileScanner::get_default(const std::string & paramname, std::string & defvalue)
{
  typedef DocuList :: iterator                                       DLIt;
  DLIt it  = param_list_.find(paramname);
  if(it != param_list_.end() && !(it->second).empty())
  {
    DocuBlock & db   = it->second;
    extract_default(db, defvalue);
  }
  else
  {
    defvalue = std::string("");
  }
}

void MFileScanner::get_typename(const std::string & paramname, std::string & typen, std::string voidtype)
{
  typedef DocuList :: iterator                                       DLIt;
  typedef AltDocuList :: iterator                                    ADLIt;
  typedef DocuBlock :: iterator                                      DBIt;
  DLIt it  = param_list_.find(paramname);
  DocuBlock * pdb;
  if(it != param_list_.end() && !(it->second).empty())
    pdb   = &(it->second);
  else
  {
    it = return_list_.find(paramname);
    if(it != return_list_.end() && !(it->second).empty())
      pdb   = &(it->second);
    else
    {
      ADLIt ait = cscan_.param_list_.find(paramname);
      if(ait != cscan_.param_list_.end() && !(ait->second).empty())
        pdb   = &(ait->second);
      else
      {
        ait = cscan_.return_list_.find(paramname);
        if(ait != cscan_.return_list_.end() && !(ait->second).empty())
          pdb   = &(ait->second);
        else
        {
          typen=voidtype;
          return;
        }
      }
    }
  }

  DocuBlock & db = *pdb;
  extract_typen(db, typen);

  if(typen.empty())
    typen = voidtype;
  else
    param_type_map_[paramname] = typen;
}

// ATTENTION: The get_typename method changes the docublock and removes the
// "@type " respectively "of type" strings if remove is set to true.
void MFileScanner::extract_typen(DocuBlock & db, std::string & typen, bool remove)
{
  int linenr = 1;
  typedef DocuBlock :: iterator                                      DBIt;
  for(DBIt dit = db.begin(); dit != db.end(); ++dit, ++linenr)
  {
    std::string line   = *dit;
    size_t found         = std::string::npos;
    size_t typeof_length = 0;                         // length of string "of type" respectively "@type"
    if(runMode_.parse_of_type && linenr < 2)
    {
      found         = line.find("of type");
      typeof_length = string("of type").length();
    }
    if(found == std::string::npos)
    {
      found         = line.find("@type");
      typeof_length = string("@type").length();
    }
    if(found != std::string::npos)
    {
      size_t typenstart = found + typeof_length;
      // find start of type name
      typenstart=line.find_first_not_of( " \t\n\0", typenstart );
      if (typenstart == std::string::npos)
      {
        // read in next line
        if (remove)
          (*dit).erase(found, line.length() - found - 1);

        ++dit;
        if (dit == db.end())
          break;
        line = *dit;
        found = 0;
        typenstart = line.find_first_not_of( " \t");
      }
      // find end of type name
      size_t typenend =
        line.find_first_of( " \n\0", typenstart );
      typen = line.substr(typenstart, typenend - typenstart);
      // remove trailing '.' if necessary
      if (typen[typen.length()-1] == '.')
      {
        typen = typen.substr(0, typen.length() - 1);
      }
      // add leading '::' just to make sure, we only have global scope variables.
      if(typen[0] != ':')
      {
        for(size_t i=0; i < typen.length(); ++i)
          if(typen.at(i) == '.')
            typen.replace(i,1,std::string("::"));
        typen = string("::") + typen;

//        (*dit).replace(typenstart, typenend - typenstart, typen);
      }
      if (remove)
      {
        (*dit).erase(found, typenend - found);
      }
    }
  }
}

void MFileScanner::add_access_info(std::string what)
{
  if (access_.get != access_.set)
  {
    docuextra_.push_back(std::string("@note This ") + what + std::string(" has non-unique access specifier: <tt>"));
    std::string setAccess = access_specifier_string(access_.set);
    std::string getAccess = access_specifier_string(access_.get);
    docuextra_.push_back(std::string("SetAccess = ") + setAccess + ", "
                       + std::string("GetAccess = ") + getAccess + std::string("</tt>\n"));
  }
}

/** adds a block at the end of the documentation with information on uesed
 * attributes of a property.
 *
 */
void MFileScanner::add_property_params_info()
{
  bool any_property_set = false;
  if (propertyparams_.hidden)
  {
    any_property_set = true;
    docuextra_.push_back(std::string("@note This property has the MATLAB attribute @c Hidden set to true.\n"));
  }
  if (propertyparams_.transient)
  {
    any_property_set = true;
    docuextra_.push_back(std::string("@note This property has the MATLAB attribute @c Transient set to true.\n"));
  }
  if (propertyparams_.dependent)
  {
    any_property_set = true;
    docuextra_.push_back(std::string("@note This property has the MATLAB attribute @c Dependent set to true.\n"));
  }
  if (propertyparams_.setObservable)
  {
    any_property_set = true;
    docuextra_.push_back(std::string("@note This property has the MATLAB attribute @c SetObservable set to true.\n"));
  }
  if (propertyparams_.abstr)
  {
    any_property_set = true;
    docuextra_.push_back(std::string("@note This property is an @em abstract property without implementation.\n"));
  }
  if (propertyparams_.abortSet)
  {
    any_property_set = true;
    docuextra_.push_back(std::string("@note This property has the MATLAB attribute @c AbortSet set to true.\n"));
  }

  add_access_info("property");

  if (access_.get != access_.set)
    any_property_set = true;

  if (any_property_set)
    docuextra_.push_back("@note <a href=\"http://www.mathworks.de/help/techdoc/matlab_oop/brjjwby.html\">Matlab documentation of property attributes.</a>\n");
}

void MFileScanner::add_method_params_info()
{
  bool any_property_set = false;
  if (methodparams_.hidden)
  {
    any_property_set = true;
    docuextra_.push_back(std::string("@note This method has the MATLAB method attribute @c Hidden set to true.\n"));
  }
  if (methodparams_.sealed)
  {
    any_property_set = true;
    docuextra_.push_back(std::string("@note This method has the MATLAB method attribute @c Sealed set to true. It cannot be overwritten.\n"));
  }
  add_access_info("method");

  if (access_.get != access_.set)
    any_property_set = true;

  if (any_property_set)
    docuextra_.push_back("@note <a href=\"http://www.mathworks.com/help/matlab/matlab_oop/method-attributes.html\">matlab documentation of method attributes.</a>\n");
}

// end a function and pretty print the documentation for this function
void MFileScanner::end_function()
{
  bool is_constructor = false;
  bool is_method = false;
  bool skip_parameters = false;
  /* If copydoc or copydetails is used in the documentation body or the
   * documentation header, the automatic parameter doc strings need to be
   * skipped. */
  if (! docuheader_.empty()
       && docuheader_[0].find("copydoc") != std::string::npos)
  {
    skip_parameters = true;
  }
  if (! docubody_.empty())
  {
    for (unsigned int i = 0; i < docubody_.size(); ++i)
    {
      size_t pos_begin_copy = docubody_[i].find("copydoc");
      if(pos_begin_copy == std::string::npos)
      {
        pos_begin_copy = docubody_[i].find("copydetails");
      }
      if(pos_begin_copy != std::string::npos)
      {
        size_t pos_word_begin = docubody_[i].find_first_of(" \n", pos_begin_copy + 1);
        pos_word_begin        = docubody_[i].find_first_not_of(" \n", pos_word_begin);
        if(pos_word_begin != std::string::npos)
        {
          size_t pos_word_end   = docubody_[i].find_first_of("(", pos_word_begin);
          if(pos_word_end != std::string::npos)
          {
            std::string func      = docubody_[i].substr(pos_word_begin, pos_word_end-pos_word_begin);
            size_t pos_func_beg   = func.find_last_of(":. ");
            func                  = func.substr(pos_func_beg+1);
            if(func == cfuncname_)
            {
              skip_parameters = true;
            }
          }
        }
      }
    }
  }
  if(is_class_)
  {
    if(class_part_ == Property || class_part_ == Event)
      return;

    add_method_params_info();

    if(cfuncname_ == classname_)
      is_constructor = true;
    if(class_part_ == Method)
      is_method = true;
  }
  // end function
  if(!is_method || !methodparams_.abstr)
    fout_ << string(funcindent_, ' ') << "}\n";
  if(is_getter_ || is_setter_)
    fout_ << "\n#endif\n";
  if(is_setter_)
    specifier_[cfuncname_].setter = true;
  if(is_getter_)
    specifier_[cfuncname_].getter = true;

  if (  ( !docuheader_.empty() || runMode_.auto_add_class_properties )
     && ( is_first_function_ || runMode_.generate_subfunction_documentation )
     )
  {
    // is the first function?
    if(is_first_function_)
    {
      if(! runMode_.latex_output && ! is_class_)
      {
        // Then make a file documentation block
        fout_ << "/** @file \"" << filename_ << "\"\n  ";
        cout_ingroup();
        fout_ << "* @brief ";
        cout_docuheader(cfuncname_, false);
        fout_ << "*/\n";
      }
    }
    fout_ << "/*";
    if(runMode_.latex_output && !is_class_)
    {
      cout_ingroup();
      fout_ << "\n  ";
    }
    {
      // specify the @fn part
      fout_ << "* @fn ";
      print_pure_function_synopsis();

      // specify the @brief part
      fout_ << "\n  * @brief ";
    }
    cout_docuheader(cfuncname_);
    fout_ << "*\n  ";

    // specify the @details part

    // standard body definitions
    cout_docubody();

    if (! skip_parameters)
    {
      // parameters
      if(!param_list_.empty() && !is_getter_ && !is_setter_)
      {
        fout_ << "*\n  ";
        handle_param_list_for_varargin();
      }

      // return values
      if(!return_list_.empty() && !is_constructor && !is_getter_ && !is_setter_)
      {
        fout_ << "*\n  ";
        write_docu_list(return_list_, "@retval", cscan_.return_list_,
            runMode_.auto_add_params);
      }

      if(runMode_.print_fields)
      {
        // required fields
        write_docu_listmap(required_list_, "@par Required fields of ", cscan_.field_docu_);

        // optional fields
        write_docu_listmap(optional_list_, "@par Optional fields of ", cscan_.field_docu_);

        // return fields
        write_docu_listmap(retval_list_, "@par Generated fields of ", cscan_.field_docu_);
      }
    }
#ifdef DEBUG
    std::cerr << "CLEARING LISTS!";
#endif
    clear_lists();

    // extra docu fields
    cout_docuextra();
    if( new_syntax_ )
    {
      fout_ << "* @synupdate Syntax needs to be updated! \n  ";
    }
    fout_ << "*/\n";
  }
  else
  {
    clear_lists();
  }
  if(!is_method)
    is_first_function_ = false;

  is_setter_ = false; is_getter_ = false;
  cfuncname_.clear();

  fout_ << "\n";

  std::string warnings = warning_buffer_.str();
  if (!warnings.empty())
  {
    fout_ << "/* " << warnings << " */";
  }
  warning_buffer_.str("");
  warning_buffer_.clear();
}

void MFileScanner::debug_output(const std::string & msg, char * p)
{
  std::cerr << "Message: " << msg << "\n";
  std::cerr << "Next 20 characters to parse: \n";
  std::cerr.write(p, 20);
  std::cerr << "\n------------------------------------\n";
  std::cerr << "States are: ClassPart: " << ClassPartNames[class_part_] << "\n"
    << propertyparams_ << methodparams_ << access_;
  std::cerr << "\n------------------------------------\n";
}

void MFileScanner::extract_default_argument_of_inputparser(std::string & last_args)
{
  string::size_type at_sign = last_args.find_last_of("@");
  if (at_sign == string::npos)
  {
    string::size_type brace = last_args.find_last_of(")");
    string::size_type end_of_last_arg = last_args.find_last_not_of(" \t\n", brace);
    char endchar = last_args[end_of_last_arg];
    if (endchar == ')' || endchar == ']' || endchar == '}')
    {
      last_args = last_args.substr(0, end_of_last_arg);
    }
    else
    {
      string::size_type comma = last_args.find_last_of(",", brace);
      last_args = last_args.substr(0, comma);
    }
  }
  else
  {
    string::size_type comma = last_args.find_last_of(",", at_sign);
    last_args = last_args.substr(0, comma);
  }
}

void MFileScanner::postprocess_unused_params(std::string & param, DocuList & doculist)
{
  if (param == std::string("~"))
  {
    int counter = 1;
    bool found = true;
    while ( found )
    {
      std::ostringstream oss;
      oss << "unused" << counter;
      if (doculist.find(oss.str()) == doculist.end())
      {
        param = oss.str();
        found = false;
      }
      ++counter;
    }
  }
}

void MFileScanner::handle_param_list_for_varargin()
{
  typedef VararginParserValuesType::iterator ItType;
  typedef DocuList::item DocuListItem;
  typedef DocuList::iterator DocuListIt;


  DocuListIt vararginIt = param_list_.find("varargin");
  bool has_varargin = (vararginIt != param_list_.end());

  if (has_varargin)
  {
    DocuList requiredParams;
    DocuList optionalParams;
    DocuList mappedParams;

    DocuListIt last_param_tmp_it = vararginIt+1;
    DocuListItem last_param_item_tmp;

    for (;last_param_tmp_it != param_list_.end(); last_param_tmp_it++)
    {
      last_param_item_tmp = *last_param_tmp_it;
      std::string defval_temp;
      bool hasUserDefault = (extract_default(last_param_item_tmp.second, defval_temp) != "");
      string last_paramname_tmp = last_param_item_tmp.first;
      ItType pvit = varargin_parser_values_.find(last_paramname_tmp);
      if (pvit == varargin_parser_values_.end() || (*pvit).second.first == 0)
      {
        requiredParams[last_paramname_tmp] = last_param_item_tmp.second;
      }
      else if((*pvit).second.first == 1)
      {
        string & defaultval = (*pvit).second.second;
        optionalParams[last_paramname_tmp] = last_param_item_tmp.second;
        if (!defaultval.empty() && !hasUserDefault)
          optionalParams[last_paramname_tmp].push_back(string("     ( @b Default: <tt>") + defaultval + "</tt> )\n");


      }
      else if((*pvit).second.first == 2)
      {
        string & defaultval = (*pvit).second.second;
        mappedParams[last_paramname_tmp] = last_param_item_tmp.second;
        if (!defaultval.empty() && !hasUserDefault)
          mappedParams[last_paramname_tmp].push_back(string("     ( @b Default: <tt>") + defaultval + "</tt> )\n");

      }
      if (pvit != varargin_parser_values_.end())
      {
        varargin_parser_values_.erase(pvit);
      }
    }

    param_list_.erase(vararginIt+1, param_list_.end());


    for (ItType pvit = varargin_parser_values_.begin(); pvit != varargin_parser_values_.end(); ++pvit)
    {
      const string & paramname = (*pvit).first;
      int index = (*pvit).second.first;
      const string & defaultval = (*pvit).second.second;
      string paramname_copy(paramname);
      replace_underscore(paramname_copy);
      DocuBlock documentation;
      documentation.push_back(paramname_copy + "\n");
      if (!defaultval.empty())
        documentation.push_back(string("     ( @b Default: <tt>") + defaultval + "</tt> )\n");
      switch (index)
      {
      case 0:
        requiredParams[paramname] = documentation;
        break;
      case 1:
        optionalParams[paramname] = documentation;
        break;
      case 2:
        mappedParams[paramname] = documentation;
        break;
      }

    }

    unsigned long int req_param_size = requiredParams.size();
    unsigned long int opt_param_size = optionalParams.size();
    unsigned long int mapped_param_size = mappedParams.size();

    DocuBlock format;


    if (req_param_size + opt_param_size + mapped_param_size > 0)
    {
      ostringstream * oss = new ostringstream;

      *oss << "@code " << cfuncname_ << " ( ";
      if (param_list_.size() > 1)
        *oss << "..., ";
      int first = 0;
      for (unsigned int i = 0; i < req_param_size; ++i)
      {
        if (i > 0)
          *oss << ", ";

        first = 1;
        *oss << requiredParams.at(i).first;
      }

      for (unsigned int i = 0; i < opt_param_size; ++i)
      {
        if (first == 1)
        {
          *oss << ",\n";
          format.push_back(oss->str());
          delete oss; oss = new ostringstream;
          *oss << std::string(cfuncname_.size()-1, ' ') << "[ ";
        }
        else if (i > 0)
          *oss << " [, ";
        else
          *oss << " [ ";

        first = 2;
        *oss << optionalParams.at(i).first;
      }

      for (unsigned int i = 0; i < mapped_param_size; ++i)
      {
        if (first > 0 || (i> 0 && i % 2 == 0) )
        {
          if (first == 1)
            *oss << ",\n";
          else
            *oss << "\n";

          format.push_back(oss->str());
          delete oss; oss = new ostringstream;
          *oss << std::string(cfuncname_.size()-1, ' ');
          if (first != 1)
            *oss << "[, ";
        }
        else if (i > 0)
          *oss << " [, ";
        else
          *oss << " [ ";

        first = 0;
        *oss << '"' << mappedParams.at(i).first << "\", " << mappedParams.at(i).first << "_value ]";
      }

      unsigned int nOptParams = optionalParams.size();
      if (nOptParams < 5)
        for (unsigned int count = 0; count < nOptParams; ++count)
          *oss << " ]";
      else
        *oss << " ] ... ]";

      *oss << " ) @endcode\n";
      format.push_back(oss->str());
      delete oss;
    }

    DocuBlock & varargin_docu = param_list_["varargin"];
    varargin_docu.insert(varargin_docu.end(), format.begin(), format.end());

    write_docu_list(param_list_, "@param", cscan_.param_list_,
                    runMode_.auto_add_params);
    if (!requiredParams.empty())
    {
      fout_ << "* <i>Required Parameters for varargin:</i>\n  ";
      write_docu_list(requiredParams, "- <span class=\"paramname\">", cscan_.param_list_,
                      runMode_.auto_add_params, "</span>");
      fout_ << "* .\n  ";
    }
    if (!optionalParams.empty())
    {
      fout_ << "* <i>Optional Parameters for varargin:</i>\n  ";
      write_docu_list(optionalParams, "- <span class=\"paramname\">", cscan_.param_list_,
                      runMode_.auto_add_params, "</span>");
      fout_ << "* .\n  ";
    }
    if (!mappedParams.empty())
    {
      fout_ << "* <i>Named Parameters for varargin:</i>\n  ";
      write_docu_list(mappedParams, "- <span class=\"paramname\">",
                      cscan_.param_list_,
                      runMode_.auto_add_params, "</span>");
      fout_ << "* .\n  ";
    }
  }
  else
  {
    write_docu_list(param_list_, "@param", cscan_.param_list_,
                    runMode_.auto_add_params);
  }
}



std::ostream & operator<<(std::ostream & os, AccessStruct & as)
{
  os << "AccessStruct: full = " << AccessEnumNames[as.full] << " get  = " <<
    AccessEnumNames[as.get] << " set  = " << AccessEnumNames[as.set] << "\n";
  return os;
}

std::ostream & operator<<(std::ostream & os, PropParams & pp)
{
  os << "PropParams: constant = " << pp.constant << "\n";
  return os;
}

std::ostream & operator<<(std::ostream & os, MethodParams & mp)
{
  std::string abstract = mp.abstr ? "abstract, " : "";
  std::string statics = mp.statical ? "static, " : "";
  os << "MethodParams: " << abstract << statics << "\n";
  return os;
}
