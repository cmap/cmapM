function s = stringify(x, varargin)
% STRINGIFY Convert input to string.
%   S = STRINGIFY(X) Converts X to a string. Allowed inputs char, numeric,
%   or logical.
%   S = STRINGIFY(X, param1, value1,...) Specify optional parameters
%   'fmt': <STRING> Format string for numeric input. Default is '%g'
%   'struct2str': <LOGICAL> Convert structure to string containing
%       dimensions and fieldnames. Default is true.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'--fmt'; '--struct2str'};
dflts = {'%g'; true};
help_str = {'Format string for numeric input';...
            'Convert structure to string containing dimensions and fieldnames'};
            
config = struct('name', pnames,...
    'default', dflts,...
    'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Print a delimited line');

args = cmapm.util.ArgParse.getArgs(config, opt, varargin{:});
%get variable name
% vname = @(x) inputname(1);

if isempty(x)
    s = '';
else
    r = size(x, 1);
    if r==1
        if isnumeric(x) || islogical(x)
%             s=sprintf(args.fmt, x);
            s = cmapm.util.String.printDelimitedLine(x, 'dlm', ',');
        elseif ischar(x)
            s=sprintf('%s',x);
        elseif isstruct(x)
            % struct dimensions as a string
            if args.struct2str
                if isds(x)
                    s = sprintf('[%dx%d ds] %s', size(x.mat), x.src);
                else
                    s = sprintf('[%dx%d struct] fields:%s', size(x),...
                        cmapm.util.String.printDelimitedLine(fieldnames(x),'dlm',','));
                end
            else
                s = x;
            end
        elseif iscell(x)
            s = cmapm.util.String.printDelimitedLine(x, 'dlm', '|');
            % catch all, could be dangerous
        else
            s = x;
        end
    elseif r>1
        if isstruct(x)
            s = sprintf('[%dx%d struct] fields:%s', size(x),...
                cmapm.util.String.printDelimitedLine(fieldnames(x), 'dlm', ','));
        else
            s = cell(r,1);
            if isnumeric(x) || islogical(x)
                s = strtrim(cmapm.util.String.num2cellstr(x, 'fmt', args.fmt));                
            elseif iscellstr(x)
                s = cmapm.util.String.printDelimitedLine(x, 'dlm', '|');
            end
        end
        
    end
end