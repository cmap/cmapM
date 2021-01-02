function hfun = aggregate_fun(fun, dim)
% AGGREGATE_FUN Create an aggregate function handle.
% HFUN = AGGREGATE_FUN(FUN) Returns a handle to function FUN that
% operates on the first dimension of an array. FUN can be a string or a
% user-defined anonymous function.
%
% where possible return handle function is nan-compatible
%
% Several in-built functions are recognized:
%   'iqr' : Interquartile range
%   'mad' : Median absolute deviation
%   'max' : Maximum
%   'mean' : Mean
%   'median' : Median
%   'min' : Minimum
%   'numel' : count, or number of non-NaN elements
%   'range' : maximum - minimum
%   'sem' : standard error of the mean
%   'std' : standard deviation
%   'var' : variance
%
% HFUN = AGGREGATE_FUN(FUN, DIM) Operates along the dimension DIM
%

error(nargchk(1, 2, nargin));
if nargin==1
    dim = 1;
end
assert (dim >0 && dim <3, 'Dim must be 1 or 2');
switch (class(fun))
    case 'char'
        switch(lower(fun))
            case 'mean',  hfun = @(x, dim) nanmean(x, dim);
            case 'sem',   hfun = @(x, dim) nanstd(x, 0, dim) / sqrt(size(x, dim));
            case 'std',   hfun = @(x, dim) nanstd(x, 0, dim);
            case 'var',   hfun = @(x, dim) nanvar(x, 0, dim);
            case 'min',   hfun = @(x, dim) nanmin(x, [], dim);
            case 'max',   hfun = @(x, dim) nanmax(x, [], dim);
            case 'absmax', hfun = @(x,dim) absmax(x, dim);
            case 'range', hfun = @(x, dim) range(x, dim);
            case 'numel', hfun = @(x, dim) nansum(~isnan(x), dim);
            case 'median',hfun = @(x, dim) nanmedian(x, dim);
            case 'iqr',   hfun = @(x, dim) iqr(x, dim);
            case 'mad',   hfun = @(x, dim) mad(x, 1, dim);            
            otherwise
                hfun = @(x, dim) feval(fun, x, dim);                
        end
    case 'function_handle'
        hfun = fun;
    otherwise
        error('Invalid input')
end
check_fn(hfun, dim);
end

function check_fn(hfun, dim)

if dim==1
    result = hfun(ones(1, 2), dim);
else
    result = hfun(ones(2, 1), dim);
end
assert(~isequal(numel(result), 1), ...
    'Function does not operate correctly in the specified dimension');

end
