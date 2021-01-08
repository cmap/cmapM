#include "mfilescanner.h"
#include <cassert>
#include <cstring>
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
using std::map;
using std::pair;
using std::make_pair;
using std::ostringstream;

%%{
  machine MFileScanner;
  write data;

  # end of file character
  EOF = 0;

  # any character other than end of file
  default = ^0;

  # end of line character
  EOL = ('\r'? . '\n') %{ ++line; };

  # scanner for comment blocks
  in_comment_block :=
  (
   ([ \t]* >{ tmp_p = p; } .
   # comment line begins with a percent sign
   '%')
     @{ fout_ << "\n";
        fout_.write(tmp_p, p - tmp_p);
        tmp_p = p+1; fout_ << " *";
      }
   # and then some default characters
   . (default - '\n')* . EOL
     @{ fout_.write(tmp_p, p - tmp_p); }
  )*
  $!{
    fout_ << " */\n";
//    if(is_getter_ || is_setter_)
//    {
//      fout_ << "*/\n";
//    }
    fhold;
    while (*p == ' ')
      fhold;
    fret;
  };

  action end_doxy_block
  {
    if(!docline)
    {
      p = ts-1;
      /* go backward until first non-whitespace is found */
      for(p=p-1; *p==' ' || *p == '\t'; --p)
        ;

      if(is_class_)
      {
        if(class_part_ == Header)
        {
          end_of_class_doc();
          fgoto classbody;
        } else if(class_part_ == Method || class_part_ == AtMethod)
        {
          if(runMode_.mode == RunMode::ParseParams)
            return 1;
          print_function_synopsis();
          fgoto funcbody;
        }
        else if(class_part_ == MethodDeclaration)
        {
          fgoto funcdef;
        }
        else if(class_part_ == Property || class_part_ == Event)
        {
          fgoto propertybody;
        }
        else if(class_part_ == InClassComment)
        {
          class_part_ = Method;
          fgoto methods;
        }
        else
        {
          cerr << "MTOCPP: missing class part handling for class part: " << ClassPartNames[class_part_] << endl;
        }
      }
      else
      {
        if(runMode_.mode == RunMode::ParseParams)
          return 1;
        print_function_synopsis();
        fgoto funcbody;
      }
    }
  }

  # executed when end of file is reached
  action end_of_file
  {
    end_function();
    for(  list<string>::iterator it = namespaces_.begin();
          it != namespaces_.end(); ++it)
    {
      fout_ << "};\n";
    }
  }

  # executed when we reached a comment block
  action in_c_block
  {
    assert(p >= tmp_p-1);
    fout_.write(tmp_p, p-tmp_p+1);
    fcall in_comment_block;
  }

  action echo { fout_ << fc; }

  action st_tok { tmp_p = p; }

  action echo_tok {
    assert (p >= tmp_p);
    fout_.write(tmp_p, p - tmp_p);
  }

  action string_tok {
    assert ( p >= tmp_p );
    tmp_string.assign(tmp_p, p-tmp_p);
  }

  # common definitions {{{2

  # comment in function body that might also be added to the doxygen block for
  # the function description
  is_doxy_comment =
    (
    # RAGEL comment: if percent character is followed by a bar we make the comment a doxygen
    # comment
     '|' @{ 
//    if(is_getter_ || is_setter_)
//            {
//              fout_ << "*/";
//            }
            fout_ << "/**"; tmp_p = p+1;
          }
     . (default - '\n')*
     . ( EOL . [ \t]*
       . '%' @{
                assert(p >= tmp_p -1);
                fout_.write(tmp_p, p - tmp_p);
                fout_ << " * ";
                tmp_p = p+1;
              }
     . (default - '\n')* )* . EOL
     |
    # RAGEL comment: else: a regular comment
     ( (default - '|')
       @{
//         if(is_getter_ || is_setter_)
//         {
//           fout_ << "\n#endif\n";
//         }
         fout_ << "/* ";
         tmp_p = p;
         } )
     . (default - '\n')* . EOL
    );

  # comment block in function body
  comment_block = (( [ \t]* >(st_tok)  . '%') @{fout_.write(tmp_p, p - tmp_p);}) . is_doxy_comment;

  # an empty line
  empty_line = [\t ]* . EOL;

  # documentation line begin
  doc_begin = [\t ]* . '%' @{ tmp_p = p + 1; };

  # swallow a comment line till the end of the line (make it a c comment)
  garble_comment_line =
    ( (default - [\r\n])* . EOL )
      @{
//        if(is_getter_ || is_setter_)
//        {
//          fout_ << "\n#endif\n";
//        }
        fout_ << "/* ";
        assert( p >= tmp_p );
        fout_.write(tmp_p, p - tmp_p) << "*/\n";
//        if(is_getter_ || is_setter_)
//        {
//          fout_ << "\n#if 0\n";
//        }
      };
  garble_comment_line_wo_eol =
    (default - [\r\n])*;

  # white space or comment
  WSOC =
    ( ([ \t]+ 
       @{
          {
            int i=0;
            if (*(p+1) != ' ' && *(p+1) != '\t')
            {
              while (*(p-i) == ' ' || *(p-i) == '\t')
                i++;
              if (*(p-i) == '\n')
                fout_ << std::string(i, ' ');
            }
          }
        })
      | ('%' @{ tmp_p = p+1; } . garble_comment_line)
      | ('...'.[ \t]*.EOL)
    );

  # white space or line continuation
  WS =
    ( [ \t]+
      | ('...'.[\t]*.EOL)
    );

  # matlab identifier
  IDENTEND = [A-Za-z0-9_];
  IDENT = [A-Za-z_]IDENTEND**;


  # matlab identifier with .
  IDENT_W_DOT = [A-Za-z_][A-Za-z0-9_.]**;

  # default arguments in function declarations
  default_arg = ([^,)\n] | EOL)** @echo;

  #}}}2

  # parameter list for functions {{{2
  paramlist =
    (
     (WSOC | ',' | EOL
     | ( '=' . default_arg ) )+
     |
     # matlab identifier (parameter)
     (IDENT | '~' )
       >st_tok
       %{
         assert(p >= tmp_p);
         string s(tmp_p, p - tmp_p);
         bool addBlock = true;
         // do not print this pointer
         if( is_class_ && ( !methodparams_.statical
                            && (
                                ( class_part_ == Method
                                  && cfuncname_ != classname_
                                )
                                || class_part_ == AtMethod
                                || class_part_ == MethodDeclaration
                               )
                          )
                       && ( ! (
                               methodparams_.abstr
                               && !runMode_.remove_first_arg_in_abstract_methods
                              )
                          )
           )
         {
            if(paramlist_.empty())
            {
              addBlock = false;
              paramlist_.push_back(string("this"));
            }
            else if(paramlist_.size() == 1 && paramlist_[0] == string("this"))
              paramlist_.clear();
         }

         if(addBlock) {

#ifdef DEBUG
{
  ostringstream oss;
  oss << "found parameter: " << s;
  debug_output(oss.str(), p);
}
#endif
           postprocess_unused_params(s, param_list_);
           // add an empty docu block for parameter \a s
           if(param_list_.find(s) == param_list_.end())
           {
             param_list_[s] = DocuBlock();
           }
#ifdef DEBUG
{
  ostringstream oss;
  oss << "in paramlist: add to paramlist: " << s;
  debug_output(oss.str(), p);
}
#endif
           paramlist_.push_back(s);
         }
       }
    )**;

  
  matrix_or_cell := (
      '[' . ( [^[{\]\n] | EOL | [[{] @{fhold; fcall matrix_or_cell;} )* . ']' @{ fret; }
      |
      '{' . ( [^[{}\n] | EOL | [[{] @{fhold; fcall matrix_or_cell;} )* . '}' @{ fret; }
      );

  matrix = ([[{] @{fhold; fcall matrix_or_cell;} );
  
  
  # return parameter list for functions
  lparamlist =
    ( (WSOC | EOL )+
      | ','
      # matlab identifier (return value)
      | ( (IDENT | '~') > st_tok
          %{
            assert(p >= tmp_p);
            string s(tmp_p, p - tmp_p);
            postprocess_unused_params(s, return_list_);
            returnlist_.push_back(s);
            // add an empty docu block for return value \a s
            if(return_list_.find(s) == return_list_.end())
            {
              return_list_[s] = DocuBlock();
            }
          }
        )
    )**;

  # return parameter or return parameter list
  lparams =
    (
      (
        (
         # matlab identifier
         ( IDENT | '~' )
           >st_tok
           %{
             assert(p >= tmp_p);
             string s(tmp_p, p - tmp_p);
             postprocess_unused_params(s, return_list_);
             returnlist_.push_back(s);
             // add an empty docu block for single return value \a s

             if(return_list_.find(s) == return_list_.end())
             {
               return_list_[s] = DocuBlock();
             }
#ifdef DEBUG
  cerr << "\n In return list: " << endl;
#endif
           }
        )
        | ( '['
          . lparamlist
          . ']'
          )
      )
      . ( [ \t]+ | ([ \t].'...'.[ \t]*.EOL))*
      :> '=' . WSOC*
    );
    # }}}2

  # a line in the function body {{{2
  funcline := |*
    # empty line
    ([ \t]+)
      => { fout_.write(ts, te-ts); };

    # line continuation
    ('...' . [ \t]* . EOL)
      => { fout_.write(ts, te-ts); };

    # two single quote in a row need to be changed to nothing
    ('\'\'');

    # a string should not be parsed for comment blocks, so we handle it separately.
    ('\'' . [^'\n]+ . '\'')
      => {
           // change double quotes to quotes and vice versa...
           fout_ << "\" ";
           string s(ts+1, te-ts-2);
           std::replace(s.begin(), s.end(), '\"', '\'');
           fout_ << s;
           fout_ << " \"";
         };

    # ('%' @{ tmp_p = p + 1; } . garble_comment_line);
    (comment_block)
      => {
           assert(p >= tmp_p);
           fout_.write(tmp_p, p - tmp_p);
           fcall in_comment_block;
         };

     (IDENT %{tmp_string.assign(ts,p-ts);})
     . [ \t]* . '=' . [ \t]* . 'inputParser' . [ \t]* . ';'
     {
#ifdef DEBUG
 std::cerr << "Found varargin parser candidate: " << tmp_string << std::endl;
#endif
       varargin_parser_candidate_ = tmp_string;
     };

     ('addRequired' . [ \t]* . '(' . [ \t]* . (IDENT > (st_tok) %{tmp_string.assign(tmp_p, p - tmp_p);})
       . [ \t]* . ',' . [ \t]* . '\'' . (IDENT > (st_tok) %{tmp_string2.assign(tmp_p, p - tmp_p);}) . '\'' )
       => {
         fout_.write(ts, te-ts);
         if (tmp_string == varargin_parser_candidate_ )
         {
           varargin_parser_values_[tmp_string2] = make_pair(0, "");
 #ifdef DEBUG
 std::cerr << "Found required varargin: " << tmp_string2 << std::endl;
 #endif
         }
       };
     
     ((IDENT %{tmp_string.assign(ts, p - ts);})
         . '.addRequired' . [ \t]* . '(' . [ \t]* 
         . '\'' . (IDENT > (st_tok) %{tmp_string2.assign(tmp_p, p - tmp_p);}) . '\'' )
       => {
         fout_.write(ts, te-ts);
         if (tmp_string == varargin_parser_candidate_ )
         {
           varargin_parser_values_[tmp_string2] = make_pair(0, "");
 #ifdef DEBUG
 std::cerr << "Found required varargin: " << tmp_string2 << std::endl;
 #endif
         }
       };


    ('addOptional' . [ \t]* . '(' . [ \t]* . (IDENT > (st_tok) %{tmp_string.assign(tmp_p, p - tmp_p);})
      . [ \t]* . ',' . [ \t]* . '\'' . (IDENT > (st_tok) %{tmp_string2.assign(tmp_p, p - tmp_p);} ) . '\''
      . [ \t]* . ',' . [ \t]* . ( [^;\n]* > (st_tok) %{tmp_string3.assign(tmp_p, p - tmp_p);}) . (';' | EOL) )
      => {
        fout_.write(ts, te-ts);
        if (tmp_string == varargin_parser_candidate_ )
        {
          extract_default_argument_of_inputparser(tmp_string3);
          varargin_parser_values_[tmp_string2] = make_pair(1, tmp_string3);
#ifdef DEBUG
std::cerr << "Found optional varargin: " << tmp_string2 << " with default value " << tmp_string3 << std::endl;
#endif
        }
        if (*p == '\n')
          fgoto funcbody;
      };
    
    ((IDENT %{tmp_string.assign(ts, p - ts);})
      . '.addOptional' . [ \t]* . '(' . [ \t]* 
      . '\'' . (IDENT > (st_tok) %{tmp_string2.assign(tmp_p, p - tmp_p);} ) . '\''
      . [ \t]* . ',' . [ \t]* . ( [^;\n]* > (st_tok) %{tmp_string3.assign(tmp_p, p - tmp_p);}) . (';' | EOL) )
      => {
        fout_.write(ts, te-ts);
        if (tmp_string == varargin_parser_candidate_ )
        {
          extract_default_argument_of_inputparser(tmp_string3);
          varargin_parser_values_[tmp_string2] = make_pair(1, tmp_string3);
#ifdef DEBUG
std::cerr << "Found optional varargin: " << tmp_string2 << " with default value " << tmp_string3 << std::endl;
#endif
        }
        if (*p == '\n')
          fgoto funcbody;
      };


    ('addParamValue' . [ \t]* . '(' . [ \t]* . (IDENT > (st_tok) %{tmp_string.assign(tmp_p, p - tmp_p);})
      . [ \t]* . ',' . [ \t]* . '\'' . (IDENT > (st_tok) %{tmp_string2.assign(tmp_p, p - tmp_p);}) . '\''
      . [ \t]* . ',' . [ \t]* . ( [^;\n]* > (st_tok) %{tmp_string3.assign(tmp_p, p - tmp_p);}) . (';' | EOL ) )
      => {
        fout_.write(ts, te-ts);
        if (tmp_string == varargin_parser_candidate_ )
        {
          extract_default_argument_of_inputparser(tmp_string3);
          varargin_parser_values_[tmp_string2] = make_pair(2, tmp_string3);
#ifdef DEBUG
std::cerr << "Found param value for varargin: " << tmp_string2 << " with default value " << tmp_string3 << std::endl;
#endif
        }
        if (*p == '\n')
          fgoto funcbody;
      };
    
    ((IDENT %{tmp_string.assign(ts, p - ts);})
      . '.addParamValue' . [ \t]* . '(' . [ \t]*
      . '\'' . (IDENT > (st_tok) %{tmp_string2.assign(tmp_p, p - tmp_p);}) . '\''
      . [ \t]* . ',' . [ \t]* . ( [^;\n]* > (st_tok) %{tmp_string3.assign(tmp_p, p - tmp_p);}) . (';' | EOL) )
      => {
        fout_.write(ts, te-ts);
        if (tmp_string == varargin_parser_candidate_ )
        {
          extract_default_argument_of_inputparser(tmp_string3);
          varargin_parser_values_[tmp_string2] = make_pair(2, tmp_string3);
#ifdef DEBUG
std::cerr << "Found param value for varargin: " << tmp_string2 << " with default value " << tmp_string3 << std::endl;
#endif
        }
        if (*p == '\n')
          fgoto funcbody;
      };


    # automatically add return value fields to retval_list_
    (
     # matlab identifier (which can be a return value and a structure)
     (IDENT
        %{tmp_string.assign(ts,p-ts);})
     . '.'
     # matlab identifer (fieldname)
     . (IDENT_W_DOT >(st_tok) %{tmp_p2 = p;} )
     # RAGEL comment: if a value is assigned to this field, the field is generated/modified
     . [ \t]* . '=' . (^'=')
    )
    => {
      fhold;
      // store fieldname
      assert(tmp_p2 >= tmp_p);
      string s(tmp_p, tmp_p2 - tmp_p);
      fout_ << tmp_string << "." << s << "=";
      // typedef of iterators
      typedef DocuList     :: iterator list_iterator;
      typedef DocuListMap  :: iterator map_iterator;
      typedef DocuBlock    :: iterator iterator;

      // check wether first IDENT is a return value
      iterator it = find(returnlist_.begin(), returnlist_.end(), tmp_string);
      if(it != returnlist_.end())
      {
        // if it is a return value...
        // ... check wether its found field is still missing a DocuBlock in the
        // retval list.
        bool missing = true;
        map_iterator rvoit = retval_list_.find(tmp_string);
        if(rvoit != retval_list_.end())
        {
          list_iterator lit = (*rvoit).second.find(s);
          if(lit != (*rvoit).second.end())
            missing = false;
        }
        // if it is missing, add an empty docu block
        if(missing)
        {
          retval_list_[tmp_string][s] = DocuBlock();
        }
      }
    };

    # automatically add parameter fields to required_list_
    (
     # matlab identifier (which can be a parameter and a structure)
     (IDENT
        %{tmp_string.assign(ts,p-ts);})
     . '.'
     # matlab identifer (fieldname)
     . (IDENT_W_DOT
         >(st_tok)
       )
    )
    => {
      // store fieldname
      assert(p >= tmp_p);
      string s(tmp_p, p - tmp_p+1);
      fout_ << tmp_string << "." << s;
      typedef DocuList     :: iterator list_iterator;
      typedef DocuListMap  :: iterator map_iterator;
      typedef DocuBlock    :: iterator iterator;

      // check wether first IDENT is a parameter
      iterator it = find(paramlist_.begin(), paramlist_.end(), tmp_string);
      if(it != paramlist_.end())
      {
        // if it is a parameter ...
        // ... check wether its found field is still missing a DocuBlock in the
        // return, optional and the required list.
        bool missing = true;
        map_iterator rvoit = retval_list_.find(tmp_string);
        if(rvoit != retval_list_.end())
        {
          list_iterator lit = (*rvoit).second.find(s);
          // found match in retval list
          if(lit != (*rvoit).second.end())
            missing = false;
        }
        map_iterator moit = optional_list_.find(tmp_string);
        if(moit != optional_list_.end())
        {
          // found match in optional list
          list_iterator lit = (*moit).second.find(s);
          if(lit != (*moit).second.end())
            missing = false;
        }
        map_iterator roit = required_list_.find(tmp_string);
        if(roit != required_list_.end())
        {
          // found match in required list
          list_iterator lit = (*roit).second.find(s);
          if(lit != (*roit).second.end())
            missing = false;
        }
        // in case it IS missing, add an empty field to the required block.
        if(missing)
        {
          required_list_[tmp_string][s] = DocuBlock();
        }
      }
    };

    # add a @deprecated command to function declaration if disp_deprecated is
    # used in function body
    ('disp_deprecated' . [ \t]*
      . (
          ';'
            @{tmp_string.assign("");}
          |
          '(' . [\t ]* . "'"
          . ([^\n']*
              >(st_tok)
              %(string_tok)
            )
          . "'" . [\t ]* . ')' . [\t ]* . ';'
        )
      . [\t ]* . EOL
    )
      => {
        string s;
        if(tmp_string.empty())
        {
          s.assign("@deprecated function deprecated\n");
        }
        else
        {
          s.assign("@deprecated method deprecated, use \'" + tmp_string + "\' instead.\n");
        }
        docuextra_.push_back(s);
        fhold;
      };

    # simple matlab identifier
    (IDENT)
      => { fout_.write(ts, te-ts); };

    # translate curly brackets in edgy brackets, because otherwise the doxygen
    # parser breaks.
    ('{')
      => { fout_ << '['; };

    ('}')
      => { fout_ << ']'; };
    
    ('\'')
      => { fout_ << "^t"; };

    # simply output all other characters
    (default - [\n{}\'])
      => { fout_ << fc; };

    # after EOL try to check for new function
    EOL
      => { fout_ << fc; fgoto funcbody; };

  *|;
  # }}}2

  # function body {{{2
  funcbody := |*

      # things that got replaced in function body {{{4
      ('% TO BE ADJUSTED TO NEW SYNTAX' . EOL)
        => {
          new_syntax_ = true;
          fout_ << "*/\n"; //fout_ << "add to special group */\n";
        };

      # a comment block
      ( ([ \t]* . '%' @{ fout_.write(ts, p - ts); }) . is_doxy_comment)
        => {
          assert(p >= tmp_p);
          fout_.write(tmp_p, p - tmp_p);
          fcall in_comment_block;
        };

      # empty line
      ([ \t]* . EOL)
        => { fout_ << '\n'; };

      #}}}4

      # line not beginning with words 'function' or 'end'
      ([ \t]*
       . ( (default - [ \r\t\n%])+ - ('function'|'end') )
      )
        => {
          p = ts-1;
          // further parse the function body line
#ifdef DEBUG
debug_output("in funcbody: goto funcline", p);
#endif
          fgoto funcline;
        };

      # things that could end the function body {{{4
      # line only containing word 'end'
      # the keyword needs to be in the same indentation level as beginning function
      ([ \t]* . 'end' . ';'* . (WSOC | EOL ) )
          => {
              if(is_class_ && class_part_ == Method)
              {
                tmp_string.assign(ts,p-ts+1);

                if(tmp_string.find("e") == funcindent_)
                {
                  end_function();
#ifdef DEBUG
debug_output("in funcbody: goto methods", p);
#endif
                  fgoto methods;
                }
              }
              // else
              p=ts-1;
              // further parse the function body line
#ifdef DEBUG
debug_output("in funcbody: goto funcline 2", p);
#endif
              fgoto funcline;
          };

      # line beginning with word 'function'
      ([ \t]*. 'function ')
      {
        tmp_string.assign(ts,p-ts+1);
        p = ts-1;

        if (!is_class_ && tmp_string.find("f") <= funcindent_)
        {
          // end the previous function if existent
          end_function();
#ifdef DEBUG
debug_output("in funcbody: goto main", p);
#endif
          fgoto main;
        }
        else
        {
          fgoto funcline;
        }
      };

      (EOF) $eof(end_of_file);

      # }}}4

  *|;
   # }}}2

  # fill a docublock list with input {{{2
  fill_list := |*

  # match an argument
  ( doc_begin . [ \t]*
    . "'"? . ( ([A-Za-z][A-Za-z0-9_{},()[\].]*)  >{tmp_p3 = p;} %{tmp_p2 = p;} ) . "'"? . [ \t]* . ":" @(st_tok)
    . ( default - '\n' )* . EOL
  )
    => {
      assert(tmp_p2 >= tmp_p3);
      tmp_string.assign(tmp_p3, tmp_p2 - tmp_p3);
      //    std::fout_ << tmp_string << '\n';
      assert(p >= tmp_p);
      (*clist_)[tmp_string].push_back(string(tmp_p+1, p - tmp_p));
    };

  # expand the paragraph for last argument matched
  ( doc_begin . [ \t]*
    # at least one word (non white-space characters and no double-colon)
    . ( default - [ \r\t:\n] )+ .
    # followed by something that is a white-space or a new-line, i.e *no*
    # double-colon
    (
     EOL
     |
     [ \t]+ . (EOL | [^ \r\n\t:] . (default - '\n')* . EOL)
     # [ \t] . (default - '\n')* . EOL
    )
  )
    => {
      assert(p+1 >= tmp_p);
      string s(tmp_p, p - tmp_p + 1);
      (*clist_)[tmp_string].push_back(s);
      /*fout_ << "add something results in\n" << (*clist_)[tmp_string];*/
    };

  # return on empty line
  ( doc_begin . [ \t]* . EOL )
    => { /*fout_ << "empty line\n";*/ fret; };

   # end of comment block
  ( [\t ]* . ( (default - '%') | EOL) )
    => {
      p =ts-1;
      // fout_ << "*/\n";
      fret;
    };

  *|; #}}}2

  # parse body of documentation block {{{2
  doxy_get_body := |*

    # special lists {{{4

    # begin required_list
    ( doc_begin . [ \t]*
      . /required fields of /i
      . (IDENT >(st_tok) %(string_tok) )
      . [ \t]* . ':' . [ \t]* . EOL
    )
      => {
        //fout_ << tmp_string << '\n';
        clist_ = &(required_list_[tmp_string]);
        docline = false;
        fcall fill_list;
      };

    # begin optional_list
    ( doc_begin . [ \t]*
      . /optional fields of /i
      . (IDENT
          >(st_tok)
          %(string_tok) )
      . [ \t]* . ':' . [ \t]* . EOL )
      => {
        clist_ = &(optional_list_[tmp_string]);
        docline = false;
        fcall fill_list;
      };

    # begin optional_list
    ( doc_begin . [ \t]*
      . /generated fields of /i
      . (IDENT
          >(st_tok)
          %(string_tok) )
      . [ \t]* . ':' . [ \t]* . EOL )
      => {
        clist_ = &(retval_list_[tmp_string]);
        docline = false;
        fcall fill_list;
      };

    # begin parameter list
    ( doc_begin . [ \t]*
      . /parameters/i . [ \t]* . ':'
      . [ \t]* . EOL )
      => {
        clist_ = &param_list_;
        docline = false;
        fcall fill_list;
      };

    # begin return list
    ( doc_begin . [ \t]*
      . /return values/i . [ \t]* . ':'
      . [ \t]* . EOL )
      => {
        clist_ = &return_list_;
        docline = false;
        fcall fill_list;
      };
    #}}}4

    # default substitutions {{{4

    # empty line
    ( doc_begin . [ \t]* . EOL )
      => {
        /*fout_ << "*\n  ";*/
        docubody_.push_back("\n");
        docline = false;
      };

    # paragraph line
    ( [ \t]* . '%' )
      => {
        if(!docline)
        {
          docline = true;
          tmp_p = p;
        }
      };

    # paragraph line with "see also" substituted by "@sa"
    ( /see also/i . ':'? )
      => {
        string s;
        assert(ts > tmp_p);
        s.assign(tmp_p+1, ts - tmp_p-1);
        docubody_.push_back(s+"@sa");
        tmp_p = p;
      };

    # lines that could end doxyblock {{{6
    # words
    #  RAGEL comment:  ( default - [ \t:%'`\n] )+
    ( default - [ \t:%\r\n] )+ @(end_doxy_block);

    # non-words/non-whitespace
    #  RAGEL comment:  ([:'`]) => {
    (':') @(end_doxy_block) ;


    # whitespace only
    ( [ \t] );

    # titled paragraph
    ( ':' . EOL )
      @(end_doxy_block)
      @{ if(docline)
         {
           assert(ts > tmp_p);
           docubody_.push_back("@par " + string(tmp_p+1, ts - tmp_p-1)+"\n");
           docline = false;
         }
       };
    # }}}6
    # }}}4

    # end of line {{{4
    ( EOL )
       @(end_doxy_block)
       @{ if(docline)
          {
            int offset = ( latex_begin ? 0 : 1 );
            assert(p >= tmp_p + offset);
            docubody_.push_back(string(tmp_p+1, p - tmp_p - offset));
            docline = false;
          }
        };
      # }}}4

  *|;
  #}}}2

  # doxy header parsing {{{2
  # swallow the synopsis line
  doxyfunction_garble := |*
    garbage = ( (default - '\n' )* -- '...' );

    ( doc_begin . (garbage . '...')+ . [\t ]* .  EOL );

    ( doc_begin . (garbage . '...')* . garbage . EOL )
      => { fgoto doxy_get_brief; };
  *|;


  # read first paragraph
  doxy_get_brief := |*

    # read in one comment line
    ( doc_begin . [\t ]*
      . (default - [\r\n\t ]) . (default - '\n')* . EOL
    )
      => {
        /* fout_ << "*"; fout_.write(tmp_p, p - tmp_p+1); */
        assert(p >= tmp_p);
        docuheader_.push_back(string(tmp_p, p - tmp_p+1));
      };

    # empty line
    ( doc_begin . [\t ]* . EOL )
      => {
        /*fout_ << "*\n";*/
#ifdef DEBUG
  debug_output("in doxy_get_brief: goto: doxy_get_body", p);
#endif
        fgoto doxy_get_body;
      };

    # end of comment block;
    ( [\t ]* . [^%] )
      => {
        p=ts-1;
#ifdef DEBUG
   debug_output("in doxy_get_brief: end!!", p);
#endif
        //fout_ << "*/\n";
        if(is_class_)
        {
#ifdef DEBUG
  debug_output(" in_doxy_get_brief: this is a class",p);
#endif

          if(class_part_ == Header)
          {
#ifdef DEBUG
  debug_output("  in_doxy_get_brief: method: goto classbody",p);
#endif
            end_of_class_doc();
            fgoto classbody;
          } else if(class_part_ == Method || class_part_ == AtMethod)
          {
#ifdef DEBUG
  debug_output("  in_doxy_get_brief: method: goto funcbody",p);
#endif
            if(runMode_.mode == RunMode::ParseParams)
              return 1;
            print_function_synopsis();
            fgoto funcbody;
          }
          else if(class_part_ == MethodDeclaration)
          {
#ifdef DEBUG
  debug_output("  in_doxy_get_brief: method: goto funcdef",p);
#endif
            fgoto funcdef;
          }
          else if(class_part_ == Property || class_part_ == Event)
          {
#ifdef DEBUG
  debug_output("  in_doxy_get_brief: method: goto propertybody",p);
#endif
            fgoto propertybody;
          }
          else if(class_part_ == InClassComment)
          {
            class_part_ = Method;
            fgoto methods;
          }
        }
        else
        {
          if(runMode_.mode == RunMode::ParseParams)
            return 1;
          print_function_synopsis();
          fgoto funcbody;
        }
      };

  *|;
  # }}}2

  # garble synopsis line and then parse the documentation header {{{2
  doxyheader := (
    '%' . [ \t]* .
       (
        ('function '|'classdef ') @{ p = tmp_p-2; fgoto doxyfunction_garble; }
       )
      $!{
#ifdef DEBUG
        debug_output("doxy_get_brief",p);
#endif
        p = tmp_p - 2;
        fgoto doxy_get_brief;
      }
   ); #}}}2

  # helper for setting the access specifier {{{2
  paramaccess =
    ( ('SetAccess' . WSOC* . '=' . WSOC*
      . ( (/public/i
            @{ access_.full = Public;
               access_.set = Public;
             } )
        | ( /protected/i
            @{ access_.full =
                 (access_.get == Public ? Public : Protected );
               access_.set = Protected;
             } )
        | ( /private/i
            @{ access_.full = access_.get;
               access_.set = Private;
             } )
        )
      )
     | ( 'GetAccess' . WSOC* . '=' . WSOC*
      . ( ( /public/i
            @{ access_.full = Public;
               access_.get = Public;
             } )
        | ( /protected/i
            @{ access_.full =
                 (access_.set == Public ? Public : Protected );
               access_.get = Protected;
             } )
        | ( /private/i
            @{ access_.full = access_.set;
               access_.get = Private;
             } )
        )
       )
     | ( 'Access' . WSOC* . '=' . WSOC*
      . ( ( /public/i
            @{ access_.full = Public;
               access_.get = Public;
               access_.set = Public;
             } )
        | ( /protected/i
            @{ access_.full = Protected;
               access_.get = Protected;
               access_.set = Protected;
             } )
        | ( /private/i
            @{ access_.full = Private;
               access_.get = Private;
               access_.set = Private;
             } )
        )
       )
      ); #}}}2

  # method and property params {{{2
  methodparam =
   (
    ( paramaccess )
    | ( ( 'Abstract' . ([^,)\n] | EOL)* )
        @{
           methodparams_.abstr = true;
         } )
    | ( ( 'Static' . ([^,)\n] | EOL)* )
        @{
           methodparams_.statical = true;
         } )
    | ( ('Hidden' . ([^,)\n] | EOL)* )
        @{
           methodparams_.hidden = true;
         } )
    | ( ( 'Sealed' . ([^,)\n] | EOL)* )
        @{
           methodparams_.sealed = true;
         } )
   );

  propertyparam =
   (
    ( paramaccess )
    | ( ( 'Constant' . ([^,)\n] | EOL)* )
        @{
           propertyparams_.constant = true;
         } )
    | ( ( 'Transient' . ([^,)\n] | EOL)* )
        @{
           propertyparams_.transient = true;
         } )
    | ( ( 'Dependent' . ([^,)\n] | EOL)* )
        @{
           propertyparams_.dependent = true;
         } )
    | ( ( 'Hidden' . ([^,)\n] | EOL)* )
        @{
           propertyparams_.hidden = true;
         } )
    | ( ( 'SetObservable' . ([^,)\n] | EOL)* )
        @{
           propertyparams_.setObservable = true;
         } )
    | ( ( 'Abstract' . ([^,)\n] | EOL)* )
        @{
           propertyparams_.abstr = true;
         } )
    | ( ( 'AbortSet' . ([^,)\n] | EOL)* )
        @{
           propertyparams_.abortSet = true;
         } )
   );

  methodparams =
   (
    '(' . WSOC*
    . methodparam
    . ( WSOC* . ',' . WSOC* . methodparam )* . WSOC* . ')'
   );

  propertyparams =
   (
    '(' . WSOC*
    . propertyparam
    . ( WSOC* . ',' . WSOC* . propertyparam )* . WSOC* . ')'
   ); #}}}2

  # methods and properties {{{2
  # methods {{{4
  methods := |*
# kommentare, newlines
# nur bei keyword 'function' => goto funcdef
# abstrakter fall, eine weitere Regel wird benötigt.
# end => classbody
    (empty_line) => {
      if(runMode_.mode != RunMode::ParseMethodParams)
      {
        end_method();
        fout_ << "\n";
      }
    };

    # default: method definition
    ([ \t]* . 'function' )
      => {
        tmp_string.assign(ts, te - ts+1);
        funcindent_ = tmp_string.find_first_not_of(" \t");
        fout_ << string(ts, ts+funcindent_);
        #if DEBUG
            {
              ostringstream oss;
              oss << "in methods: funcindent: " << funcindent_;
              debug_output(oss.str(), p);
            }
        #endif
        p=ts+funcindent_-1;
        fgoto funct;
       };

    # end of methods block
    ([ \t]* . 'end' . [ \t;]* . ('%' . garble_comment_line_wo_eol)? . EOL )
      => {
           if(runMode_.mode != RunMode::ParseMethodParams)
           {
             end_method();
             #if DEBUG
               debug_output("in methods: found end keyword, goto classbody",p);
             #endif
           }
           fgoto classbody;
         };

    # comment between two methods
    ([ \t]* . '%' ) => {
      #if DEBUG
        debug_output("in methods: garble comment line",p);
      #endif

      p = ts-1;
      class_part_ = InClassComment;
/*      fcall in_comment_block; */
      fgoto expect_doxyblock;
    };

    # if we reach this: method declaration without definition is found
    ([ \t]* . [^% \t\n]) =>
    {
      #if DEBUG
        debug_output("in methods: found method declaration, going to funcdef",p);
      #endif
      class_part_ = MethodDeclaration;
      p = ts-1;
      fgoto funcdef;
    };

      *|;


  methodsheader := (
    [ \t]* . methodparams? . [ \t;]* . ( '%' . garble_comment_line_wo_eol )? . EOL
         @{
            print_access_specifier(access_.full, methodparams_, propertyparams_);
            fgoto methods;
          }
              );

   #}}}4

  # single property {{{4
  prop = ( ( [ \t]* . (IDENT) >st_tok
            %{
              {
                char *i = tmp_p-1;
                for (; *i == ' ' || *i == '\t'; --i)
                  fout_ << *i;
              }
              
              end_of_property_doc();
              string s(tmp_p, p - tmp_p);
              if (s == "end")
                fgoto classbody;
              if (propertyparams_.dependent)
                specifier_[s].dependent = true;
              property_list_.push_back(s);
              //            fout_ << propertyparams_.ccprefix() << " " << s;
              undoced_prop_ = true;
            }
          )
        . WS* . ( ( '%' @{ fhold; } | ';' | EOL )  @{defaultprop_ = "";}
            |
            ( ('=' . [ ]*) %{tmp_p2 = p;} . ( matrix | [^[{;\n%] | ('...'.[ \t]*.EOL) )* . (';' | EOL | '%' @{fhold; } ))
            @{
              defaultprop_ = string(tmp_p2, p - tmp_p2);
              string::size_type last_elem = defaultprop_.length() -1;
              if(defaultprop_[0] == '\'' && defaultprop_[last_elem] == '\'')
              {
                defaultprop_[0] = '\"';
                defaultprop_[last_elem] = '\"';
              }
              string::size_type first_paren = defaultprop_.find_first_of("([{");
              string::size_type last_paren;
              if (first_paren == string::npos)
              {
                first_paren = 1;
                last_paren = last_elem;
              }
              else
              {
                last_paren = defaultprop_.find_last_of(")]}");
                if (last_paren == string::npos)
                  last_paren=last_elem-1;
                else
                {
                  if((first_paren >0 && defaultprop_[first_paren] == '(') || defaultprop_[first_paren] == '{')
                  {
                    first_paren++;
                    last_paren--;
                  }
                  defaultprop_.insert(first_paren, 1,'"');
                  defaultprop_.insert(last_paren+2, 1,'"');
                  first_paren++;
                  last_paren++;
                }
              }
              for (unsigned int i = first_paren; i < last_paren; ++i)
              {
                if(defaultprop_[i] == '.' && defaultprop_[i+1] == '.' && defaultprop_[i+2] == '.')
                {
                  defaultprop_[i]   = ' ';
                  defaultprop_[i+1] = ' ';
                  defaultprop_[i+2] = ' ';
                }
/*                else if(defaultprop_[i] == '[')
                  defaultprop_[i] = '{';
                else if(defaultprop_[i] == ']')
                  defaultprop_[i] = '}'; */
                else if(defaultprop_[i] == ';' && i < defaultprop_.length() - 1)
                  defaultprop_[i] = ',';
                else if(defaultprop_[i] == '\"')
                  defaultprop_[i] = '\'';
                else if(defaultprop_[i] == '@')
                {
                  defaultprop_.insert(i, 1, '\\');
                  ++i;
                }
                else if(defaultprop_[i] == '\n')
                {
                  defaultprop_.insert(i, 1, '\\');
                  ++i;
                }
              }
             }
          )
      );

  #}}}4

  #property body {{{4
  propertybody = (
    (prop)
    |
    ( (empty_line) @{ end_of_property_doc(); fout_ << "\n";} )
    |
    ( ([ \t]* . '%') @{ fhold; fgoto expect_doxyblock; } )
    );

  properties := ( (
    WSOC* . propertyparams? . [ \t;]* . ('%' . garble_comment_line_wo_eol )? . EOL @{
        print_access_specifier(access_.full, methodparams_, propertyparams_);
        }
    . propertybody* )
      );
  #}}}4

  #}}}2

  # class body {{{2
  classbody := |*

    # a comment block
    (comment_block)
      => {
        fout_.write(tmp_p, p - tmp_p);
        fcall in_comment_block;
      };

    (WSOC); # => { fout_.write(ts, te-ts); };

    (EOL) => { fout_ << "\n"; };

    ('end' . [ \t]* ';'?) => {
      std::map<std::string, PropExtraInformation>::iterator specIt;
      for (specIt = specifier_.begin(); specIt != specifier_.end(); specIt++)
      {
        fout_ << "/** @var " << (*specIt).first << "\n *\n *";
        if ( (*specIt).second.dependent)
        {
          if( (*specIt).second.getter && ! (*specIt).second.setter )
          {
            fout_ << "@note [readonly]\n *";
          }
        }
        else
        {
          fout_ << "@note This property has custom functionality when its value is ";
          if ((*specIt).second.getter)
          {
            fout_ << "retrieved";
            if ((*specIt).second.setter)
              fout_ << " or changed";
          }
          else if ((*specIt).second.setter)
            fout_ << "changed";
          fout_ << ".";
        }
        fout_ << "\n */\n";
      }
      fout_ << "\n};\n";
      for(  list<string>::iterator it = namespaces_.begin();
            it != namespaces_.end(); ++it)
      {
        fout_ << "}\n";
      }
    };

    ([ \t]* . 'properties')
      => {
        propertyparams_ = PropParams();
        access_ = AccessStruct();
        class_part_ = Property;
        fgoto properties;
      };
    ([ \t]* . 'methods')
      => {
        methodparams_ = MethodParams();
        access_ = AccessStruct();
        class_part_ = Method;
        fgoto methodsheader;
      };
    ([ \t]* . 'events')
      => {
        propertyparams_ = PropParams();
        access_ = AccessStruct();
        class_part_ = Event;
        fgoto properties;
      };
  *|; #}}}2

  # doxyblock expect {{{2
  # after function declaration expect a documentation block or the function
  # body
  expect_doxyblock :=
  (
    doc_begin
      @{
        //fout_ << "/*";
        p--;
        fgoto doxyheader;
      }
  )
 $!{
    fhold;
    {
      int i = 0;
      for (i = 0; *(p-i) == ' ' || *(p-i) == '\t'; ++i)
        ;
      std::string whitespaces(i, ' ');
//    if (string(p, 5) == " if ~")
//    {
//      debug_output("break;", p);
//      fout_ << "/* start */";
//    }
//    for (char * i = p; *i == ' ' || *i == '\t'; --i)
//      fout_ << *i;
//     fout_ << "/* end */"; 
#ifdef DEBUG
    debug_output("stopping expect_doxyblock", p);
#endif
    if(is_class_)
    {
      if(class_part_ == Header)
      {
        end_of_class_doc();
        fgoto classbody;
      } else if(class_part_ == Method || class_part_ == AtMethod)
      {
        string endstringtest;
        endstringtest.assign(p, 100);
        string::size_type first_char = endstringtest.find_first_not_of(" \t");
        if(runMode_.mode == RunMode::ParseParams)
          return 1;
        if (endstringtest.substr(first_char, 3) == "end")
        {
          p += first_char+4;
          print_function_synopsis();
          end_function();
          fgoto methods;
        }
        else
        {
          print_function_synopsis();
          fout_ << whitespaces;
          fgoto funcbody;
        }
      }
      else if(class_part_ == Property || class_part_ == Event)
      {
        fgoto propertybody;
      }
      else if(class_part_ == InClassComment || class_part_ == MethodDeclaration)
      {
        class_part_ = Method;
        fgoto methods;
      }
      else{
        cerr << "MTOCPP: Do not know where to go from here. Classpart " << ClassPartNames[class_part_] << " is not handled.\n";
      }
    }
    else
    {
      if(runMode_.mode == RunMode::ParseParams)
        return 1;
      print_function_synopsis();
      fout_ << whitespaces;
      fgoto funcbody;
    }
    }
  };
  #}}}2

  # function declaration {{{2
  funcdef = (
      (WSOC)* .
      # return values (if found opt = true)
      (lparams)? .
      # matlab identifier (function name stored in cfuncname_)
      ( ('get.' @{is_getter_ = true;} | 'set.' @{is_setter_=true;} )? .
        IDENT
          >st_tok
          %{
            cfuncname_.assign(tmp_p, p - tmp_p);
            #ifdef DEBUG
              cerr << "\n Identifier of function: " << cfuncname_ << endl;
            #endif
            // in ParseMethodParams mode, we only check for the method
            // parameters of a specific method.
            if(is_class_ && class_part_ == MethodDeclaration
               && runMode_.mode == RunMode::ParseMethodParams)
            {
              if(runMode_.methodname == cfuncname_)
              {
                return 0;
              }
            }
            if(runMode_.mode == RunMode::Normal
               && is_class_ && class_part_ == AtMethod)
            {
              update_method_params(cfuncname_);
            }
            is_script_ = false;
          }
      )
      . WSOC*
      . (
           '('
           # parameter list
           . ( paramlist
               %{
                 if(paramlist_.size() == 1 && paramlist_[0] == "this")
                 { paramlist_.clear(); }
               }
             )
           . ')' . ( [ \t] | ('%' @{ tmp_p=p; comment_found=true; }
             . garble_comment_line_wo_eol) | ( ';' ) )*
           . EOL
           @{
             if(comment_found)
             {
                tmp_string.assign(tmp_p+1, p - tmp_p-1);
                tmp_string = string("/* ") + tmp_string + string("*/");
             }
             else
             {
                tmp_string = "";
             }
             comment_found = false;
             if(is_class_ && class_part_ == MethodDeclaration )
             {
               class_part_ = Method;
               #if DEBUG
                 debug_output("in funcdef: end of method declaration, returning to methods",p);
               #endif
               fgoto methods;
             }
             else
             {
               //               fout_ << tmp_string << "{\n";
               // check for documentation block
               fgoto expect_doxyblock;
             }
           }
        # no parameter list && first function => ( script || method )
        | (( [ \t]
              |
             ('%' @{ tmp_p=p; comment_found=true; }
              . garble_comment_line_wo_eol) | ( ';' ) )* . EOL)
            @{
                 if(comment_found)
                 {
                   tmp_string.assign(tmp_p+1, p - tmp_p-1);
                   tmp_string = string("/* ") + tmp_string + string("*/");
                 }
                 else
                 {
                   tmp_string = "";
                 }
                 comment_found = false;
                 #if DEBUG
                   debug_output("in funcdef: script && no parameters: expect doxyblock",p);
                 #endif
                 if(is_class_ && class_part_ == MethodDeclaration)
                 {
                    class_part_ = Method;
                    fgoto methods;
                 }
                 else
                 {
                   fgoto expect_doxyblock;
                 }
             }
        )
      );

  funct :=
  (
    (
      comment_block @in_c_block
      | [ \t]*. EOL
    )*
    . ([\t]*) . 'function' . funcdef
  ) $eof( end_of_file ) ; #}}}2

  # no function definition => a script {{{2
  script := (default)
    @{
       string :: size_type found = filename_.rfind("/");
       if(found == string :: npos)
         found = -1;
       string funcname = filename_.substr(found+1, filename_.size()-3-found);
       cfuncname_.assign( funcname );
  /*     fout_ << "noret::substitute ";
       if(!is_first_function_)
         fout_ << "mtoc_subst_" << fnname_ << "_tsbus_cotm_";
       fout_ << funcname << "() {\n";*/
       is_script_ = true;
       fhold;
       fgoto expect_doxyblock;
     }; #}}}2

  # class definitions {{{2
  classparams =
      '(' . [^)]* . ')';

  superclass =
    ( ( IDENT_W_DOT ) >{ fout_ << "public ::"; }
                      @{ if(*p == '.')
                           fout_ << "::";
                         else fout_ << *p; } );

  superclasses = (
      '<' @{ fout_ << "\n  :"; } . WSOC* . superclass . WSOC*
          . ('&' @{ fout_ << ",\n   "; } . WSOC* . superclass . WSOC*)* );

  classdef := (
      'classdef' . WSOC* . ('(' . WSOC*
        . (( 'Sealed'
          @{
            docuextra_.push_back(std::string("@note This class has the class property 'Sealed' and cannot be derived from."));
           }
          )
		  |( 'Hidden'
          @{
            docuextra_.push_back(std::string("@note This class has the class property 'Hidden' and is invisible."));
           }
          ) ) . [^)]* . ')')? . WSOC* .
      # matlab identifier (class name stored in classname_)
      ( IDENT
          >st_tok
          %{
            classname_.assign(tmp_p, p - tmp_p);
            is_class_ = true;
            fout_ << "class " << classname_;
          }
      )
      . WSOC*
      . classparams?
      . WSOC*
      . superclasses?
      . [ \t;]*
      . ( '%'. garble_comment_line_wo_eol )?
      EOL
      @{
        fout_ << " {\n";
        fgoto expect_doxyblock;
      } );

  # }}}2

  # main loop {{{2
  expect_function_script_or_class =
  (
    # either we find a function or classdef definition with a possibly
    # preceding comment block or we have a script
    ( any
       @{
          fhold;
          tmp_p = p;
        }
      .
    (
      [ \t]*. '%' . (any - '\n')* . EOL
      | [ \t]*. EOL
    )*
    . [\t]*
    . ( 'function' @{
                     p-=8;
                     char *tp;
                     for(tp=p; *tp == ' ' || *tp == '\t'; --tp)
                       ;
                     funcindent_ = (int)(p - tp);
#if DEBUG
                     {
                       ostringstream oss;
                       oss << "in expect_function_script_or_class funcindent: " << funcindent_ << " " << (size_t) p << " " <<(size_t)tp;
                       debug_output(oss.str(), p);
                     }
#endif
                     if(is_class_ && class_part_ == Header)
                       class_part_ = AtMethod;
                     fgoto funct;
                    }
      | 'classdef' @{
                     p-=8;
                     fgoto classdef;
                    }
      ) )
  $!{
#ifdef DEBUG
    debug_output("goto script",p);
#endif
    p=tmp_p;
    fgoto script;
  }
  );

  main := expect_function_script_or_class*;
  # }}}2

}%%


// run the scanner
int MFileScanner :: execute()
{
  std::ios::sync_with_stdio(false);

  fout_ << "\n/* (Autoinserted by mtoc++)\n * This source code has been filtered by the mtoc++ executable,\n";
  fout_ << " * which generates code that can be processed by the doxygen documentation tool.\n *\n";
  fout_ << " * On the other hand, it can neither be interpreted by MATLAB, nor can it be compiled with a C++ compiler.\n";
  fout_ << " * Except for the comments, the function bodies of your M-file functions are untouched.\n";
  fout_ << " * Consequently, the FILTER_SOURCE_FILES doxygen switch (default in our Doxyfile.template) will produce\n";
  fout_ << " * attached source files that are highly readable by humans.\n *\n";
  fout_ << " * Additionally, links in the doxygen generated documentation to the source code of functions and class members refer to\n";
  fout_ << " * the correct locations in the source code browser.\n";
  fout_ << " * However, the line numbers most likely do not correspond to the line numbers in the original MATLAB source files.\n */\n\n";
  
  %% write init;

  /* Do the first read. */
  bool done = false;
  while ( !done )
  {
    char *p = buf + have;
    char *tmp_p = p, *tmp_p2 = p, *tmp_p3 = p;
    string tmp_string, tmp_string2, tmp_string3;
    bool docline = false;
    bool latex_begin = true;
    bool comment_found = false;
    int space = BUFSIZE - have;

    if ( space == 0 )
    {
      /* We filled up the buffer trying to scan a token. */
      cerr << "MTOCPP: OUT OF BUFFER SPACE" << endl;
      exit(-1);
    }

    fin_.read( p, space );
    int len = fin_.gcount();
    char *pe = p + len;
    char *rpe = pe;
    char *eof = 0;

    /* If we see eof then append the EOF char. */
    if ( fin_.eof() )
    {
      char eof_c = *pe;
      *pe = '\n';
      pe++;
      *pe = eof_c;
      eof = pe;
      rpe = pe;

      done = true;
    }
    else
    {
      /* Find the last newline by searching backwards. This is where
       * we will stop processing on this iteration. */
      while ( pe >= p )
      {
        if( *pe != '\n')
          pe--;
        else
        {
          if(pe >= p+3
              && *(pe-1) == '.' && *(pe-2) == '.' && *(pe-3) == '.')
            pe-=3;
          else
            break;
        }
      }
    }

    %% write exec;

    /* Check if we failed. */
    if ( cs == MFileScanner_error )
    {
      /* Machine failed before finding a token. */
      cerr << "MTOC++:" << std::string(filename_) << ": PARSE ERROR in line " << line << " (Most common issue: wrong MatLab-indentation)" << endl;
      debug_output("Grrrr!!!!", p);
      exit(-1);
    }

    /* Now set up the prefix. */
    if ( ts == 0 )
    {
      have = rpe - pe;
      /* cerr << "memmove by " << have << "bytes\n";*/
      memmove( buf, pe, have );
    }
    else
    {
      have = rpe - ts;
      /* cerr << "memmove by " << have << "bytes to ts\n";*/
      memmove( buf, ts, have );
    }

    if ( ts != 0 )
    {
      te -= (ts-buf);
      ts = buf;
    }
  }

  return 0;
}


/* vim: set et sw=2 ft=ragel foldmethod=marker: */
