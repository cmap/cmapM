#ifndef CONFSCANNER_H_

#define CONFSCANNER_H_

#include <cstring>
#include <cstdlib>
#include <iostream>
#include <string>
#include <fstream>
#include <vector>
#include <map>
#include <set>

// 160 KB
#define BUFSIZE 100*16384

class ConfFileScanner {
private:
  typedef std :: vector< std :: string >                             DocuBlock;
  typedef std :: map< std :: string, DocuBlock >                     DocuList;
  typedef std :: map< std :: string, DocuList >                      DocuListMap;
  typedef std :: set< std :: string >                                GroupSet;
  typedef std :: vector< std :: string >                             GlobList;
  typedef std :: map< std :: string, GlobList >                      GlobListMap;
  typedef std :: vector< GlobList >                                  GlobListStack;


public:
  ConfFileScanner(const std::string & filename, const std::string & conffilename);

  virtual ~ConfFileScanner()
  {
    delete buf;
  }

  int execute();

  const char * get_conffile();

public:
  DocuList     param_list_;
  DocuList     return_list_;
  DocuListMap  field_docu_;
  DocuBlock    docuheader_;
  DocuBlock    docubody_;
  DocuBlock    docuextra_;
  GroupSet     groupset_;
  DocuList     vars_;

private:

  void check_glob_level_up();

  void go_level_down();

  bool check_for_match(int l, const char * str);


  bool check_glob_rec(int l, const std::string & s);

  void cerr_stack()
  {
    for (unsigned int i = 0; i < globlist_stack_.size(); i++) {
      if (!globlist_stack_[i].empty()) {
        std::cerr << globlist_stack_[i][0] << " ";
      }
    }
    std::cerr << "current level: " << level_ << std::endl;
    std::cerr << "size of globlist_stack: " << globlist_stack_.size() << std::endl;
    std::cerr << std::endl;
  }

  void clear_all()
  {
    param_list_.clear();
    return_list_.clear();
    field_docu_.clear();
    docuheader_.clear();
    docubody_.clear();
    docuextra_.clear();
    groupset_.clear();
  }

private:
  /* ragel scanner variables */
  char        *buf;
  int          line            , col;
  int          have;
  int          cs;
  int          top;
  int          stack[30];
  bool         opt;

  /* references to data from the confscanner */
  const std::string  filename_;

private:
  /* own data */
  std::string       conffile_;
  std::ifstream     confistream_;

  int            level_;
  bool           arg_to_be_added_;
  bool           match_at_level_[30];
  DocuBlock     *cblock_;
  DocuList      *clist_;
  DocuListMap   *clistmap_;
  GlobListMap    globlist_map_;
  GlobListStack  globlist_stack_;
  DocuBlock     *arglist_;

};

/* vim: set et sw=2: */
#endif /* CONFSCANNER_H_ */
