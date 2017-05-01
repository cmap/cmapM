function rnk = rankorder(m, varargin)
% RANKORDER Compute rank order of elements in a numeric matrix.
%   RNK = RANKORDER(M)
%   Ranks are computed by sorting M in ascending order along each column.
%
%   RANKORDER(M,'dim',DIM) sorts M along dimension DIM. DIM can be 1 or 2
%   (is 1 by default). 
%
%   RANKORDER(M,'direc', DIREC) sorts M in ascending or
%   descending order. DIREC can be 'ascend or 'descend' (is 'ascend' by
%   default). 
%
%   RANKORDER(M,'zeroindex', ISZEROINDEX) Returned ranks are zero
%   or one indexed. ISZEROINDEX is boolean (is false by default).
%
%   RANKORDER(M,'fixties', FIX) Adjusts for ties FIX is boolean (is true by
%   default). 

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

% Changes: wrapper for tiedrank now

% nin=nargin;
% error(nargchk(1,3,nin,'struct'));

% breakties = false;

pnames = {'dim', 'direc', 'zeroindex', 'fixties'};
dflts = {1, 'ascend', false, true};
arg = parse_args(pnames, dflts, varargin{:});

if arg.fixties
    rank_alg = @tiedrank;
else
    rank_alg = @myrankorder;
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
    if isequal(arg.dim, 2)
        rnk = rnk';
    end
    
else
    error('Input should have <=2 dimensions')
end
end

% Compute ranks for matrix m along the first dimension
% Does not adjust for ties
function rnk = myrankorder(m)
[nr, nc]= size(m);
if nr==1 && nc>1 
    m=m(:);
end
nel= size(m, 1);
ord = (1:nel)';
[~, sidx] = sort(m, 1);
[~, ia] = sort(sidx, 1);
rnk = ord(ia);
end
