function c = num2cellstr(x,varargin)
% NUM2CELLSTR Convert an array of numbers into a cell array of strings
%   C = NUM2CELLSTR(X) 
%   S = NUM2CELLSTR(X, param1, value1,...) Specify optional parameters
%   'fmt': Format string for numeric input. Default is '%g'
% 'precison' : prints numeric values with specified precision [Default=4]
% 'emptyval' : Used if empty value is found [Default='']

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

[nr, nc] = size(x);
pnames = {'--fmt'; '--precision'; '--emptyval'};
dflts = {'%g'; inf; ''};
help_str = {'Format string for numeric input';...
            'Prints numeric values with specified precision';...
            'Used if empty value is found'};

config = struct('name', pnames,...
    'default', dflts,...
    'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Print a delimited line');
args = cmapm.util.ArgParse.getArgs(config, opt, varargin{:});


if ~isinf(args.precision)
    args.fmt = sprintf('%%.%df', args.precision);
end

if ~isempty(x)
    %c = reshape(strtrim(cellstr(num2str(x(:),args.fmt)).'),nr,nc);
    % this is faster
    % add extra space to format for num2str
    c = reshape(regexp(num2str(x(:)', sprintf('%s ', args.fmt)), ...
        '\s+','split'),nr,nc);
else
    c = {args.emptyval};
end

