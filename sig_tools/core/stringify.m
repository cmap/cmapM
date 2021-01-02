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

pnames = {'fmt','struct2str'};
dflts = {'%g', true};
arg = parse_args(pnames, dflts, varargin{:});
%get variable name
% vname = @(x) inputname(1);

if isempty(x)
    s = '';
else
    r = size(x, 1);
    if r==1
        if isnumeric(x) || islogical(x)
%             s=sprintf(arg.fmt, x);
            s = print_dlm_line(x, 'dlm', ',');
        elseif ischar(x)
            s=sprintf('%s',x);
        elseif isstruct(x)
            % struct dimensions as a string
            if arg.struct2str
                if isds(x)
                    s = sprintf('[%dx%d ds] %s', size(x.mat), x.src);
                else
                    s = sprintf('[%dx%d struct] fields:%s', size(x),...
                        print_dlm_line(fieldnames(x),'dlm',','));
                end
            else
                s = x;
            end
        elseif iscell(x)
            s = print_dlm_line(x, 'dlm', '|');
            % catch all, could be dangerous
        else
            s = x;
        end
    elseif r>1
        if isstruct(x)
            s = sprintf('[%dx%d struct] fields:%s', size(x),...
                print_dlm_line(fieldnames(x), 'dlm', ','));
        else
            s = cell(r,1);
            if isnumeric(x) || islogical(x)
                s = strtrim(num2cellstr(x, 'fmt', arg.fmt));
                
            elseif iscellstr(x)
                s = print_dlm_line(x, 'dlm', '|');
                %             s=x;
            end
        end
        
    end
end