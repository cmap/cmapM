classdef ArgParse < handle
    % ARGPARSE A class for handling command-line options and arguments.
    %
    % Usage:
    %
    % The preferred way to use this class is via the static method getArgs.
    % For usage see:
    % help mortar.common.ArgParse.getArgs
    %
    % Alternatively you can use the class directly as follows:
    %
    % p = mortar.common.Argparse('myprogram', 'does something';
    %
    %% Add arguments using cell arrays
    % p.add('foo', 10, 'parameter foo');
    % p.add('bar', 'xyz', 'parameter bar');
    %
    %% Add arguments using structure
    % param = struct('name', 'param1',...
    %    'default', 10,...
    %    'help', 'parameter param1');
    % p.add(param);
    %
    %% Add multiple arguments as a struct array
    % s = struct('name', {'n';'--zeropad';'--prefix';'--suffix'},...
    %    'default', {[];true;'';''});
    % p.add(s);
    
    % TODO:
    % singleton argument ignored p.parse('ignoreme')
    %   check for required optionalargs
    % help: print defaults and choices
    
    % Author: Rajiv Narayan, 2013
    
    properties
        undef_action = 'warn';
    end
    
    properties (Dependent=true)
        args
        nargs
    end
    
    properties (Access=protected)
        % parser info
        info_
        % argument config structure (one record per argument)
        arg_
        % argument name to arg_ index dictionary
        name_
    end
    
    properties (Constant=true, GetAccess=private)
        
        input_struct = struct('name', {{}},...
            'default', '', ...
            'help', '',...
            'nargs', '',...
            'type', '',...
            'isrequired', false,...
            'choices', '',...
            'dest', '',...
            'action', 'store',...
            'access', 'public');
        
        info_struct =  struct('name', '',...
            'summary', '',...
            'description', '');
        
        % included configs
        config_files = mortar.containers.Dict();
        
        valid_action = {'store', 'store_const',...
            'store_true','store_false', 'help',...
            'read_args', 'undef'};
        flag_action = {'store_const', 'store_true', 'store_false', 'help'};
        valid_type = {'double', 'single', 'char', 'logical', 'cell', 'struct'};
        valid_undef_action = {'warn', 'ignore', 'error'};
    end
    
    methods (Static=true)
        
        % Simple helper to parse arguments
        [args, help_flag, used_args] = getArgs(configFile, opt, varargin);
        
    end % end static methods
    
    methods
        function obj = ArgParse(prog, desc)
            % ArgParse Create a new ArgParse object.
            %   Parameters:
            %    prog : Program name of type char
            %    desc : Brief description of the program of type char
            %    undef_action: Action to take when undefined arguments are
            %    encountered {'ignore'
            narginchk(1, 2);
            if nargin < 2
                desc = '';
            end
            
            istruct = struct('name', prog, 'description', desc,...
                'usage', '');
            obj.addInfo(istruct);
            %obj.arg_ = obj.input_struct;
            %obj.name_ = mortar.containers.Dict();
            
            % Default arguments
            name = {{'--help', '-h'}, '--help_markdown', '--undef_action'};
            default = {'', '', ''};
            action = {'help', 'help', 'undef'};
            help_str = {'Show this help message and exit',...
                        'Print help in Markdown format',...
                        'Action for undefined argument'};
            default_arg = struct('name', name, 'default', default, 'action', action, 'help', help_str);
            obj.add(default_arg);
        end
        
        function nargs = get.nargs(obj)
            nargs = length(obj.arg_);
        end
        
        function set.undef_action(obj, v)
            isok = strcmpi(v, obj.valid_undef_action);
            if any(isok)
                obj.undef_action = obj.valid_undef_action{isok};
            else
                expect = sprintf('%s,', obj.valid_undef_action{:});
                error('Invalid action for undefined arguments: %s expected:[%s]',...
                    v, expect(1:end-1));
            end
        end
        
        function addFile(obj, cfg_file)
            % AddFile Add arguments from YAML config file or URI
            assert(nargin==2, 'common.ArgParse.addConfig:InsufficentInputs');
            
            obj.config_files(cfg_file) = true;
            try
                cfgText = urltext(cfg_file);
            catch me
                error('ArgParse:FileNotFound', 'File not found: %s', cfg_file);
            end
            cfg = ReadYaml(cfgText, 0, 1, 1);
            cfg_base_path = fileparts(cfg_file);
            for ii=1:length(cfg)
                if isfield(cfg{ii}, 'ispreamble') && cfg{ii}.ispreamble
                    obj.addInfo(cfg{ii}, cfg_base_path);
                    % add new included files
                    includes = obj.config_files.keys;
                    is_included = obj.config_files.values;
                    to_include = includes(~cellfun(@all, ...
                        is_included));
                    for jj=1:length(to_include)
                        obj.addFile(to_include{jj});
                    end
                else
                    obj.add(cfg{ii});
                end
            end
        end
        
        function addInfo(obj, info_struct, cfg_base_path)
            % addInfo Add Program info
            default = obj.info_struct;
            if ~isstruct(obj.info_)
                obj.info_ = default;
            end
            fn = fieldnames(info_struct);
            if isfield(info_struct, 'include')
                to_include = info_struct.include;
                % skip already included files
                to_include = to_include(~ ...
                    obj.config_files.isKey(to_include));
                % add base_path
                to_include = strcat(cfg_base_path, '/', to_include);
                if ~isempty(to_include)
                    obj.config_files.add(to_include, ...
                        num2cell(false(size(to_include))));
                end
            end
            fn = intersect(fieldnames(default), fn);
            for ii=1:length(fn)
                if (isfield(obj.info_, fn{ii}) && ...
                        isempty(obj.info_.(fn{ii}))) || ~isfield(obj.info_, ...
                        fn{ii})
                    obj.info_.(fn{ii}) = info_struct.(fn{ii});
                end
            end
        end
        
        function add(obj, varargin)
            % ADD Add command-line arguments.
            %
            %   add(NAME, DEFAULT, DESC) Adds a single argument NAME with a
            %   default value of DEFAULT and a help string DESC. NAME is a
            %   string of any valid variable in Matlab. DEFAULT can be of
            %   any type.
            %
            %   add(S) Adds command-line arguments from the a structure
            %   array S. The following fieldnames are accepted:
            %
            %   name : String or cell array (Required), command-line
            %          argument(s)
            %   default : default value
            %   help : String, help description
            %   nargs :
            %   type : double|single|char|logical|cell|struct|file|dir
            %   isrequired : {false}|true
            %   choices :
            %   dest : String, name of argument returned by @ARGPARSE/PARSE
            %   action : {store}|store_const|store_true|store_false|help
            %   access : {public}|hidden|private
            %
            % Examples:
            % p = mortar.common.Argparse('myprogram', 'does something';
            %
            %% Add arguments using cell arrays
            % p.add('foo', 10, 'parameter foo');
            % p.add('bar', 'xyz', 'parameter bar');
            %
            %% Add arguments using structure
            % param = struct('name', 'param1',...
            %    'default', 10,...
            %    'help', 'parameter param1');
            % p.add(param);
            %
            %% Add multiple arguments as a struct array
            % s = struct('name', {'n';'--zeropad';'--prefix';'--suffix'},...
            %    'default', {[];true;'';''});
            % p.add(s);
            
            nin = nargin - 1;
            assert(nin>=1, 'common.ArgParse.add:InsufficentInputs');
            input = [];
            if isstruct(varargin{1})
                % struct array
                if length(varargin{1}) > 1
                    for ii=1:length(varargin{1})
                        a = {varargin{1}(ii)};
                        obj.add(a{:});
                    end
                else
                    % scalar struct
                    input = obj.input_struct;
                    fn = fieldnames(varargin{1});
                    fn = intersect(fieldnames(input), fn);
                    for ii=1:length(fn)
                        input.(fn{ii}) = varargin{1}.(fn{ii});
                    end
                end
            else
                % cell array input
                input = obj.input_struct;
                input_name = fieldnames(obj.input_struct);
                for ii=1:nin
                    input.(input_name{ii}) = varargin{ii};
                end
            end
            % check and insert
            if ~isempty(input)
                assert(ismember(input.action, obj.valid_action), ...
                    'common.ArgParse.add:Invalid action: %s', input.action)
                
                % parameter name
                if ischar(input.name)
                    input.name = {input.name};
                end
                assert(~isempty(input.name), 'Name not specified');
                % default destination
                if isempty(input.dest)
                    % prefer long form
                    islong = ~cellfun(@isempty, regexp(input.name, '^--[a-z09]'));
                    if any(islong)
                        dest = input.name{find(islong, 1, 'first')};
                    else
                        dest = input.name{1};
                    end
                    input.dest = regexprep(dest, '^-+', '');
                    % TODO: check if dest is a valid variable name
                end
                % type
                if isempty(input.type)
                    if ~isempty(input.default)
                        input.type = class(input.default);
                    else
                        input.type = class(input.default);
                    end
                end
                % choices
                if ~isempty(input.choices)
                    if mortar.common.Util.isNumericType(input.type)
                        if iscell(input.choices)
                            input.choices = cell2mat(input.choices);
                        elseif ischar(input.choices)
                            input.choices = str2num(input.choices);
                        end
                    end
                end
                % set defaults for flag actions
                if isequal(input.action, 'store_false')
                    input.default = true;
                elseif isequal(input.action, 'store_true')
                    input.default = false;
                end
                % assert(all(~isk), 'common.ArgParse.add:ArgumentConflict');
                % sort order: long, short
                %                 input.name = sort(input.name);
                if isa(obj.name_, 'mortar.containers.Dict')
                    isk = obj.name_.iskey(input.name);
                else
                    isk = false;
                end
                
                if any(isk)
                    this_key = find(isk, 1, 'first');
                    obj.arg_(obj.name_(input.name{this_key}),1) = input;
                elseif isa(obj.name_, 'mortar.containers.Dict')
                    obj.arg_(end + 1, 1) = input;
                    obj.name_(input.name) = num2cell(ones(size(input.name))*length(obj.arg_));
                else
                    obj.arg_ = input;
                    obj.name_ = mortar.containers.Dict(input.name,...
                        num2cell(ones(size(input.name))*length(obj.arg_)));
                end
                
            end
        end
        
        function [args, used_args] = parse(obj, varargin)
            % PARSE Read command-line arguments from input.
            %   ARGS = PARSE(A) parses cell array A for pre-specified
            %   arguments.
            %
            %   See also @ARGPARSE/ADD, @ARGPARSE/ADDFILE
            
            % process input
            if nargin > 1
                [args, used_args] = obj.parse_(varargin{:});
            else
                [args, used_args] = obj.parse_();
            end
        end
        
        function args = get.args(obj)
            % List all arguments
            args = obj.name_.sortKeysOnValue;
        end
        
        function pos_args = getPositionalArgs(obj)
            % list positional arguments
            pos_args = obj.args(~strncmp(obj.args, '-', 1));
        end
        
        function opt_args = getOptionalArgs(obj)
            % list optional arguments
            opt_args = obj.args(strncmp(obj.args, '-', 1));
        end
        
        function args = getArgInfo(obj, key)
            % get argument information
            isk = obj.name_.isKey(key);
            if all(isk)
                args = obj.arg_(obj.name_(key));
            else
                disp(key(~isk));
                error('Some arguments were not recognized');
            end
        end
        
        function printHelp(obj)
            % Print Usage
            usage_str = sprintf('Synopsis:\n%s', obj.info_.name);
            pos_help = cell(obj.nargs, 1);
            opt_help = cell(obj.nargs, 1);
            opt_ctr = 0;
            pos_ctr = 0;
            %             flag_action = {'store_const', 'store_true', 'store_false', 'help'};
            blank = {char(9)};
            
            for ii=1:obj.nargs
                this_arg = print_dlm_line(obj.arg_(ii).name, 'dlm', ', ');
                if isequal(obj.arg_(ii).access, 'public')
                    this_dest = upper(obj.arg_(ii).dest);
                    this_help = obj.arg_(ii).help;
                    this_default = obj.arg_(ii).default;
                    this_choices = obj.arg_(ii).choices;
                    isopt = strncmp(this_arg, '-', 1);
                    isflag = ismember(obj.arg_(ii).action, obj.flag_action);
                    this_opt_help = {};
                    this_pos_help = {};
                    opt_ctr = opt_ctr + isopt;
                    pos_ctr = pos_ctr + ~isopt;
                    if ~isempty(this_default)
                        this_help = sprintf('%s. Default is %s',...
                            this_help,...
                            stringify(this_default));
                    end
                    if ~isempty(this_choices)
                        this_help = sprintf('%s. Options are {%s}',...
                            this_help,...
                            stringify(this_choices));
                    end
                    this_help = textwrap({this_help}, 80);
                    this_help = strcat(blank, this_help);
                    this_help = sprintf('%s\n', this_help{:});
                    if isopt && isflag
                        % optional flag argument
                        this_usage = sprintf('[%s]', this_arg);
                        this_opt_help = sprintf('%s\n%s', this_arg, this_help);
                    elseif isopt
                        % optional argument
                        this_usage = sprintf('[%s %s]', this_arg, this_dest);
                        this_opt_help = sprintf('%s %s\n%s', ...
                            this_arg, this_dest, this_help);
                    elseif ~isopt && isflag
                        % positional flag argument
                        this_usage = sprintf('%s', this_arg);
                        this_pos_help = sprintf('%s\n%s', this_usage, this_help);
                    else
                        % positional argument
                        this_usage = sprintf('%s <%s>', this_dest, this_arg);
                        this_pos_help = sprintf('%s <%s>\n%s', this_dest,...
                            this_arg,...
                            this_help);
                    end
                    usage_str = sprintf('%s %s', usage_str, this_usage);
                    
                    if isopt
                        opt_help{opt_ctr} = this_opt_help;
                    else
                        pos_help{pos_ctr} = this_pos_help;
                    end
                end
            end
            opt_help(cellfun(@isempty, opt_help)) = [];
            pos_help(cellfun(@isempty, pos_help)) = [];
            
            if ~isempty(obj.info_.summary)
                fprintf (1, '%s: %s\n\n', upper(obj.info_.name), obj.info_.summary);
            else
                fprintf (1, '%s\n\n', upper(obj.info_.name));
            end
            usage_str = textwrap({usage_str}, 90);
            fprintf (1, '%s\n', usage_str{:});
            fprintf (1, '\nPositional Arguments:\n');
            
            for ii=1:length(pos_help)
                s = pos_help{ii};
                fprintf('   %s', s);
            end
            fprintf (1, '\nOptional Arguments:\n');
            for ii=1:length(opt_help)
                s = opt_help{ii};
                fprintf(1, '   %s', s);
            end
            
            if ~isempty(obj.info_.description)
                desc_str = strrep(obj.info_.description, '#name#', obj.info_.name);
                desc = obj.formatLines_(desc_str, 80, true);
                fprintf(1, '\nDescription:\n');
                fprintf(1, '%s\n', desc{:});
            end
        end
        
        function printHelpMarkdown(obj)
            % Pandoc compatible output            
            % Print Usage
            usage_str = sprintf('## Synopsis:\n`%s`', obj.info_.name);
            pos_help = cell(obj.nargs, 1);
            opt_help = cell(obj.nargs, 1);
            opt_ctr = 0;
            pos_ctr = 0;
            %             flag_action = {'store_const', 'store_true', 'store_false', 'help'};
            blank = {char(9)};
            
            for ii=1:obj.nargs
                this_arg = print_dlm_line(obj.arg_(ii).name, 'dlm', ', ');
                if isequal(obj.arg_(ii).access, 'public')
                    this_dest = upper(obj.arg_(ii).dest);
                    this_help = obj.arg_(ii).help;
                    this_default = obj.arg_(ii).default;
                    this_choices = obj.arg_(ii).choices;
                    isopt = strncmp(this_arg, '-', 1);
                    isflag = ismember(obj.arg_(ii).action, obj.flag_action);
                    this_opt_help = {};
                    this_pos_help = {};
                    opt_ctr = opt_ctr + isopt;
                    pos_ctr = pos_ctr + ~isopt;
                    if ~isempty(this_default)
                        this_help = sprintf('%s. Default is %s',...
                            this_help,...
                            stringify(this_default));
                    end
                    if ~isempty(this_choices)
                        this_help = sprintf('%s. Options are {%s}',...
                            this_help,...
                            stringify(this_choices));
                    end
                    this_help = textwrap({this_help}, 80);
                    %this_help = strcat(blank, this_help);
                    this_help = sprintf('%s\n', this_help{:});
                    if isopt && isflag
                        % optional flag argument
                        this_usage = sprintf('[%s]', this_arg);
                        this_opt_help = sprintf('`%s`\n: %s\n', this_arg, this_help);
                    elseif isopt
                        % optional argument
                        this_usage = sprintf('[%s %s]', this_arg, this_dest);
                        this_opt_help = sprintf('`%s` *%s*\n: %s\n', ...
                            this_arg, this_dest, this_help);
                    elseif ~isopt && isflag
                        % positional flag argument
                        this_usage = sprintf('%s', this_arg);
                        this_pos_help = sprintf('`%s`\n: %s\n', this_usage, this_help);
                    else
                        % positional argument
                        this_usage = sprintf('%s <%s>', this_dest, this_arg);
                        this_pos_help = sprintf('`%s` *<%s>*\n: %s\n', this_dest,...
                            this_arg,...
                            this_help);
                    end
                    usage_str = sprintf('%s %s', usage_str, this_usage);
                    
                    if isopt
                        opt_help{opt_ctr} = this_opt_help;
                    else
                        pos_help{pos_ctr} = this_pos_help;
                    end
                end
            end
            opt_help(cellfun(@isempty, opt_help)) = [];
            pos_help(cellfun(@isempty, pos_help)) = [];
            % header block
            fprintf(1, '---\n');
            fprintf (1, 'title: %s\n', obj.info_.name);
            fprintf (1, 'subtitle: %s\n', obj.info_.summary);
            fprintf (1, 'author: Connectivity Map, Broad Institute\n');
            fprintf (1, 'date: %s\n', datestr(now, 'mmm dd,yyyy'));
            fprintf (1, '%s: %s\n', upper(obj.info_.name), obj.info_.summary);
            fprintf(1, '---\n');
            
                usage_str = textwrap({usage_str}, 90);
            fprintf (1, '%s\n', usage_str{:});
            fprintf (1, '\n## Positional Arguments:\n');
            
            for ii=1:length(pos_help)
                s = pos_help{ii};
                fprintf('   %s', s);
            end
            fprintf (1, '\n## Optional Arguments:\n');
            for ii=1:length(opt_help)
                s = opt_help{ii};
                fprintf(1, '%s', s);
            end
            
            if ~isempty(obj.info_.description)
                desc_str = strrep(obj.info_.description, '#name#', obj.info_.name);
                desc = obj.formatLines_(desc_str, 80, false);
                fprintf(1, '## Description:\n');
                fprintf(1, '%s\n', desc{:});
                %fprintf(1, '%s\n', desc_str);
            end
        end
    end
    
    % Private methods
    methods(Access = private)
        
        function cfg = getArgConfig_(obj, name)
            cfg = obj.arg_(obj.name_(name));
        end
        
        function [res, used_args] = parse_(obj, varargin)
            % parse the parameter values.
            
            narg = length(varargin);
            used_args = false(narg, 1);
            % check if help is set
            is_help = strcmp('--help', varargin) | strcmp('-h', varargin)|...
                    strcmp('help', varargin);
            if any(is_help)
                used_args(is_help) = true;
                obj.printHelp();                
                ME = MException('mortar:common:ArgParse:HelpRequest',...
                    'Help requested');
                throw(ME);
            end
            is_help_md = strcmp('--help_markdown', varargin);
            if any(is_help_md)
                used_args(is_help_md) = true;
                obj.printHelpMarkdown();
                ME = MException('mortar:common:ArgParse:HelpRequest',...
                    'Help requested');
                throw(ME);
            end
            
            % check if undef_action is set
            has_undef_arg = strcmp('--undef_action', varargin);
            if any(has_undef_arg)
                undef_action_idx = find(has_undef_arg)+1;
                assert(undef_action_idx<=narg, 'undef_action has no value');
                new_undef_action = varargin{undef_action_idx};
                obj.undef_action = new_undef_action;
                used_args(has_undef_arg) = true;
                used_args(undef_action_idx) = true;
            end
            % skip help and undef_action
            res = cell2struct({obj.arg_(3:end).default},...
                {obj.arg_(3:end).dest}, 2);
            
            % positional arguments
            pos_arg = obj.getPositionalArgs;
            npos = length(pos_arg);
            if(narg<npos)
                ME = MException('mortar:common:ArgParse:InsufficientArguments',...
                    'Too few arguments expected %d, got %d',...
                    npos, narg);
                throw(ME);
            end
            for ii=1:length(pos_arg)
                cfg = obj.getArgConfig_(pos_arg{ii});
                res.(cfg.dest) = obj.assignValue_(pos_arg{ii},...
                    varargin{ii});
                used_args(ii) = true;
            end
            
            % optional arguments
            cur = length(pos_arg) + 1;
            % increment counter
            inc = 2;
            while cur<=narg
                % get param name
                param = varargin{cur};
                % prefix '--' if absent
                if ischar(param) && ~isequal(param(1), '-')
                    param = strcat('--', param);
                end
                if obj.name_.iskey(param)
                    % destination field
                    cfg = obj.getArgConfig_(param);
                    switch(cfg.action)
                        case 'help'
                            obj.printHelp();
                            ME = MException('mortar:common:ArgParse:HelpRequest',...
                                'Help requested');
                            throw(ME);
                        case 'read_args'
                            v = obj.assignValue_(param,...
                                varargin{cur + 1});
                            if ~isempty(v)
                                res = obj.readArgs_(varargin{cur+1}, res);
                            end
                            res.(cfg.dest) = v;
                            inc = 2;
                        case 'store'
                            res.(cfg.dest) = obj.assignValue_(param,...
                                varargin{cur + 1});
                            inc = 2;
                        case 'store_true'
                            res.(cfg.dest) = true;
                            inc = 1;
                        case 'store_false'
                            res.(cfg.dest) = false;
                            inc = 1;
                        otherwise
                            error('Unknown action: %s', action);
                    end
                    used_args(cur+(0:inc-1)) = true;
                else
                    obj.undefAction_(param);
                    inc = 1;
                end
                
                
                cur = cur + inc;
            end
            % check if required arguments
            assert(obj.hasRequired_(res));
        end
        
        function undefAction_(obj, param)
            % handle undefined arguments
            switch(obj.undef_action)
                case 'warn'
                    warning('mortar:common:ArgParse:UnknownParameter',...
                        'Unknown parameter %s', param);
                case 'error'
                    error('mortar:common:ArgParse:UnknownParameter',...
                        'Unknown parameter %s', param);
                case 'ignore'
            end
        end
        
        function res = readArgs_(obj, cfg_file, res)
            assert(ischar(cfg_file),...
                'common.ArgParse.readArgs_:NotAChar');
            cfg_text = urltext(cfg_file);
            cfg = ReadYaml(cfg_text, 0, 1, 1);
            
            fn = fieldnames(cfg);
            positionalArgs = obj.getPositionalArgs;
            for ii=1:length(fn)
                param = fn{ii};
                if ismember(param, positionalArgs)
                    % dont append --
                elseif ischar(param) && ~isequal(param(1), '-')
                    param = strcat('--', param);
                end
                if obj.name_.iskey(param)
                    argcfg = obj.getArgConfig_(param);
                    res.(argcfg.dest) = cfg.(fn{ii});
                else
                    obj.undefAction_(param);
                end
            end
        end
        
        function res = assignValue_(obj, param, val)
            % assign value for a given parameter
            cfg = obj.getArgConfig_(param);
            tgt_type = cfg.type;
            if isa(val, tgt_type)
                res = val;
            else
                switch tgt_type
                    case {'char'}
                        if isempty(val)
                            res = '';
                        elseif isnumeric(val)
                            res = num2str(val);
                        elseif ischar(val)
                            res = val;
                        elseif iscell(val) || isstruct(val)
                            res = val;
                        else
                            error('Cannot convert %s to char', class(val));
                        end
                    case {'double','single', 'int8' ,...
                            'uint8', 'int16', 'uint16', ...
                            'int32', 'uint32', 'int64',...
                            'uint64'}
                        if isempty(val)
                            res = [];
                        elseif all(islogical(val)) || all(ishandle(val))
                            res = val;
                        elseif isnumeric(val)
                            res = cast(val, tgt_type);
                        elseif ischar(val)
                            res = cast(str2double(val), tgt_type);
                        else
                            error('Cannot convert %s to %s', class(val),...
                                tgt_type);
                        end
                    case {'logical'}
                        is_scalar = isequal(numel(val),1) || ischar(val);
                        if ~is_scalar
                            error('mortar:common:ArgParse:InvalidLogical',...
                                'Logical inputs must be scalar, got array with %d elements',...
                                numel(val));
                        end
                        if isnumeric(val)
                            is_one = (val-1)<eps;
                            is_zero = (val<eps);
                            if ~(any([is_one, is_zero]))
                                error('mortar:common:ArgParse:InvalidLogical',...
                                    'Logical inputs must be {1,0,true or false} got %d',...
                                    val);
                            end
                            
                            res = is_one && ~is_zero;
                        elseif ischar(val)
                            is_true = (strcmpi('true', val) || strcmpi('1', val));
                            is_false = (strcmpi('false', val) || strcmpi('0', val));
                            if ~(any([is_true, is_false]))
                                error('mortar:common:ArgParse:InvalidLogical',...
                                    'Logical inputs must be {1,0,true or false} got %d',...
                                    val);
                            end
                            res =  is_true && ~is_false;
                        else
                            error('mortar:common:ArgParse:InvalidLogical', 'Cannot convert %s to logical',...
                                class(val));
                        end
                    case 'cell'
                        if ischar(val)
                            val = tokenize(val, ',', true);
                        elseif ~iscell(val)
                            error('mortar:common:ArgParse:InvalidCell',...
                                'Cell input must be a comma separated string or cell array, got %s',...
                                class(val));
                        end
                        res = val;
                    otherwise
                        if isa(val, tgt_type)
                            res = val;
                        else
                            error('Bad type for %s, expected %s found %s',...
                                param, tgt_type, class(val))
                        end
                end
            end
            if ~isempty(cfg.choices)
                [tf, msg] = obj.isValidChoice_(cfg.choices, tgt_type, res);
                if ~tf
                    error('mortar:common:ArgParse:InvalidChoice',...
                        sprintf('%s, %s', param, msg));
                end
            end
        end
        
        function [tf, msg] = isValidChoice_(~, choices, typ, v)
            msg = '';
            switch typ
                case 'char'
                    tf = any(ismember(v, choices));
                    if ~tf
                        choice_str = sprintf('%s, ', choices{:});
                        msg = sprintf('Invalid choice: %s choose from %s', v, choice_str(1:end-1));
                    end
                    
                case {'double','single', 'int8' ,...
                        'uint8', 'int16', 'uint16', ...
                        'int32', 'uint32', 'int64',...
                        'uint64', 'logical'}
                    tf = any(abs(v-choices)<eps);
                    if ~tf
                        choice_str = sprintf('%g, ', choices);
                        msg = sprintf('Invalid choice: %g choose from %s', v,...
                            choice_str(1:end-1));
                    end
                    
                otherwise
                    tf = false;
                    msg = sprintf('Unknown type: %s', typ);
            end
        end
        
        function yn = hasRequired_(obj, args)
            %             req_field = {obj.arg_([obj.arg_.isrequired]).dest};
            %             for ii=1:length(req_field)
            %                 if isisempty
            %             end
            yn = true;
        end
        
        function fmt = formatLines_(~, s, width, add_indent)
            % Formats strings for printing
            s = tokenize(s, char(10));
            nlines = length(s);
            fmt = cell(2*nlines - 1, 1);
            fmt(1:2:end) = s;
            fmt(2:2:end) = {''};
            fmt = textwrap(fmt, width);
            if add_indent
                fmt = strcat({char(9)}, fmt);
            end
        end
        
    end
    
end

