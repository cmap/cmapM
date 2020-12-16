function rnk = rankorder(m, varargin)
% RANKORDER Compute rank order of elements in a numeric matrix.
%   RNK = RANKORDER(M)
%   Ranks are computed by sorting M in ascending order along each column.
%   RANKORDER(..., 'param1', 'value1',...) specify optional parameters.
%   Valid parameters are:
%
%   'as_fraction'   Logical, returns ranks as a fraction of total rows (or
%   columns
%   'as_percentile'   Logical, returns ranks as a percentile of total rows (or
%   columns
%   'dim'           Integer, sorts along dimension specified can be 1 for
%                   rows or 2 for columns (is 1 by default).
%   'direc'         String, sort in ascending or descending order. Can be
%                   'ascend' or 'descend' (is 'ascend' by default).
%   'fixties'       Logical, adjusts for ties (is true by default).
%   'zeroindex'     Logical, if true the returned ranks are zero indexed
%                   (is false by default).

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

% Changes: wrapper for tiedrank now

% nin=nargin;
% error(nargchk(1,3,nin,'struct'));

% breakties = false;

pnames = {'dim', 'direc', 'zeroindex',...
          'fixties', 'as_fraction', 'as_percentile', 'ignore_nan'};
dflts = {1, 'ascend', false,...
        true, false, false, true};
arg = parse_args(pnames, dflts, varargin{:});

if arg.fixties
    rank_alg = @tiedrank;
else
    if arg.ignore_nan
        rank_alg = @nan_rankorder;
    else
        rank_alg = @custom_rankorder;
    end
end

if arg.as_fraction || arg.as_percentile
    arg.zeroindex = true;
end

if ndims(m)<=2
    if isequal(arg.dim, 2)
        m = m';
    end
    switch lower(arg.direc)
        case 'ascend'
            rnk = rank_alg(m);
        case 'descend'
            rnk = rank_alg(-m);
        otherwise
            error ('Invalid direc specified: %s', arg.direc);
    end
    
    if arg.zeroindex
        rnk = rnk-1;
    end
    if arg.as_fraction || arg.as_percentile
       nrows = size(rnk, 1)-1;
       scale = (1 + 99*arg.as_percentile);
       if nrows > 0
           rnk = scale*rnk / nrows;
       else
           rnk = scale*ones(size(rnk));
       end       
    end
    if isequal(arg.dim, 2)
        rnk = rnk';
    end
else
    error('Input should have <=2 dimensions')
end
end

function m = custom_rankorder(m)
% Compute ranks for matrix m along the first dimension
% Does not adjust for ties
[nr, nc]= size(m);
ord = (1:nr)';

if nr==1 && nc>1 
    [~, sidx] = sort(m, 2);    
    m(sidx) = ord;
else
    [~, sidx] = sort(m, 1);
    sidx = bsxfun(@plus, sidx, (nr*(0:nc-1)));
    % m = zeros(nr, nc);
    % m(sidx) = ord(:, ones(nc,1));
    m(sidx) = repmat(ord, 1, nc);    
end

end

function m = nan_rankorder(m)
% NAN_RANKORDER Rankorder ignoring NaNs without adjusting for ties
[nr, nc]= size(m);
inan = isnan(m);
ord = (1:nr)';

if nr==1 && nc>1 
    [~, sidx] = sort(m, 2);    
    m(sidx) = ord;
else
    [~, sidx] = sort(m, 1);
    sidx = bsxfun(@plus, sidx, (nr*(0:nc-1)));
    m(sidx) = repmat(ord, 1, nc);
end
m(inan) = nan;
end

