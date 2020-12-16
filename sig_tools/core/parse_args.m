function [s, eid, emsg, matchidx, varargout] = parse_args(pnames, dflts, varargin)
% PARSE_ARGS Process parameter name/value pairs for functions 
%   ARG = PARSE_ARGS(PNAMES, DFLTS, 'NAME1',VAL1,'NAME2',VAL2,...)
%   accepts a cell array PNAMES of valid parameter names, a cell array
%   DFLTS of default values for the parameters named in PNAMES, and
%   additional parameter name/value pairs.  Returns parameter values in a
%   structure ARG with fields NAME1, NAME2,...
%   Example:
%       pnames = {'color' 'linestyle', 'linewidth'}
%       dflts  = {    'r'         '_'          '1'}
%       x = {'linew' 2 'nonesuch' [1 2 3] 'linestyle' ':'}
%       arg = parse_args(pnames,dflts,x{:})
% Ignores leading dashes in the parameter names. For example '-color' or
% '--color' would also work.

%fprintf(1, 'parse_args:  start\n')
emsg = '';
eid = '';
nparams = length(pnames);
varargout = dflts;
unrecog = {};

% handle escaped strings from the command line
%fprintf(1, 'parse_args:  handle escaped strings from the command line\n')
varargin = unescape(varargin);

nargs = length(varargin);
varnames = regexprep(pnames, '^-+', '');
s = cell2struct(dflts(:), varnames(:), 1);
matchidx = zeros(nparams, 1);

% turn off debugging
%fprintf(1, 'parse_args:  turn off debugging\n')
warning('off', 'GETARGS:paramUnrecognized');

if ~isempty(varargin) && any(strcmp('help', varargin))
    stk = dbstack;
    callers = {stk.file};
    if ~isdeployed && length(callers)>1
        %if not deployed print help of caller
        help (callers{2})
    else
        % If deployed print parameters and defaults
        if length(callers)>1
            fprintf('%s\n', upper(callers{2}));
        end
        fprintf('Supported parameters:\nPARAMETER\tDEFAULT\n');
        for ii=1:nparams
            fprintf('%s:\t%s\n', pnames{ii}, stringify(dflts{ii}));
        end
    end
    error('GETARGS:help','help');
end

% check if first argument is a struct
%fprintf(1, 'parse_args:  check if first argument is a struct\n')
if nargs>=1 && isstruct(varargin{1})
    % get values from structure
    st = varargin{1};
    [cmnfn, fnidx] = intersect(varnames, fieldnames(st));
    for ii=1:length(cmnfn)
        s.(cmnfn{ii}) = assign_val(st.(cmnfn{ii}), dflts{fnidx(ii)});
    end
    varargin(1) = [];
    nargs = nargs -1;
end

% Must have name/value pairs
%fprintf(1, 'parse_args:  check that all are name/value pairs\n')
%nargs
if mod(nargs, 2)~=0
    eid = 'WrongNumberArgs';
    emsg = 'Wrong number of arguments.';
else
    % Process name/value pairs
%    fprintf(1, 'parse_args:  process name/value pairs\n')
    for j=1:2:nargs
        pname = regexprep(varargin{j},'^-+','');
        if ~ischar(pname)
            eid = 'BadParamName';
            emsg = 'Parameter name must be text.';
            break;
        end
        %i = strmatch(lower(pname),pnames,'exact');
        i = find(strcmpi(pname, varnames));
        if isempty(i)
            % if they've asked to get back unrecognized names/values, add this
            % one to the list
            if nargout > nparams+2
                unrecog((end+1):(end+2)) = {varargin{j} varargin{j+1}};
            else
                warning('GETARGS:paramUnrecognized', 'Skipping unrecognized parameter: %s', pname);
            end
        elseif length(i)>1
            eid = 'BadParamName';
            emsg = sprintf('Ambiguous parameter name:  %s.',pname);
            break;
        else
            varargout{i} = varargin{j+1};
            matchidx(i)=j+1;
            %s.(varnames{i}) = assign_val(mystringify(varargin{j+1}), dflts{i});
            s.(varnames{i}) = assign_val(varargin{j+1}, dflts{i});
        end
    end
end

%fprintf(1, 'parse_args:  appending unrecognized parameters\n')
varargout{nparams+1} = unrecog;
%fprintf(1, 'parse_args:  finished\n')
end

function res = assign_val(val, dflt)
if isequal(class(val), class(dflt))
    res = val;
else    
    switch class(dflt)
        case {'char'}
            if isnumeric(val)
                res = num2str(val);
            else
                res = val;
            end
            if isempty(res)
                res = '';
            end
        case {'double','single', 'int8' ,...
                'uint8', 'int16', 'uint16', ...
                'int32', 'uint32', 'int64',...
                'uint64'}
            if isempty(val)
                res = [];
            elseif isnumeric(val)
                res = val;
            else
                res = str2double(val);
            end
        case {'logical'}
            if isnumeric(val)
                res = val>0;
            else
                res = strcmpi('true', val);
            end
        otherwise
            res = val;
    end
end
end
% Convert input to string
% a modified version of stringify.m to handle structs correctly and avoid
% recursion problems.
function s = mystringify(x)

if isempty(x)
    s = '';
else
    r = length(x);
    if r==1
        if ishandle(x)
            s = x;
        elseif isnumeric(x) || islogical(x)
            s=sprintf('%g', x);
        elseif ischar(x)
            s=sprintf('%s',x);
        elseif isstruct(x)
            s = x;
            % catch all, could be dangerous
        else
            s = x;
        end
    elseif r>1
        if isnumeric(x) || islogical(x)
            s = strtrim(num2cellstr(x, 'fmt', '%g'));
        else
            s=x;
        end
    end
end
end
