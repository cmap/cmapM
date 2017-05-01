function c = num2cellstr(x,varargin)
% NUM2CELLSTR Convert an array of numbers into a cell array of strings
%   C = NUM2CELLSTR(X) 
%

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

[nr, nc] = size(x);
pnames = {'fmt', 'precision'};
dflts = {'%g', inf};
arg = parse_args(pnames, dflts, varargin{:});
if ~isinf(arg.precision)
    arg.fmt = sprintf('%%.%df', arg.precision);
end

if ~isempty(x)
    %c = reshape(strtrim(cellstr(num2str(x(:),arg.fmt)).'),nr,nc);
    % this is faster
    % add extra space to format for num2str
    c = reshape(regexp(num2str(x(:)', sprintf('%s ', arg.fmt)), ...
        '\s+','split'),nr,nc);
else
    c = '';
end

