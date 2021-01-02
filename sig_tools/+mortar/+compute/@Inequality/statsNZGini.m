function G = statsNZGini(x, varargin)
% statsNZGini compute the weighted Gini coefficient
%   G = statsNZGini(X) returns the unweighted Gini coefficient G for each
%   column of X
%
%   G = statsNZGini(X, W) returns the weighted Gini coefficient G for each
%   column of X using weights W. The dimensions of X and W should be the
%   same.
%
%   G = statsNZGini(X, W, DIM) Computes Gini coeffcients along the dimension
%   DIM. Valid options are 1 or 'column' and 2 or 'row'
%
%  Examples:
%  x=[3;1;7;2;5]
%  w=[1;2;3;4;5]
%  statsNZGini(x,w) % should yield 0.2983050847
%  statsNZGini([0.25; 0.75], [1;1]) % should yield 0.25
%
% This is a Matlab port of R code from:
% Reference: Accurate calculation of a Gini index using SAS and R.
% http://archive.stats.govt.nz/methods/research-papers/working-papers-original/calc-gini-index-17-02.aspx

nin = nargin;
[nr, nc] = size(x);
if nin<2
    w = [];
    dim = 1;
elseif nin<3
    w = varargin{1};
    dim = 1;
else
    w = varargin{1};
    dim = varargin{2};
end

if isempty(w)
    w = ones(nr, nc);
end

assert(isequal(size(w), size(x)),...
    'Dimensions of X and W should be the same');

[dim_str, dim_val] = get_dim2d(dim);
if isequal(dim_str, 'row')
    x = x';
    w = w';
    tmp = nr;
    nr = nc;
    nc = tmp;
end
G = nan(nc, 1);

keep_idx = ~isnan(x);
for ii=1:nc
    this_keep = keep_idx(:, ii);
    this_x = x(this_keep, ii);
    this_w = w(this_keep, ii);
    G(ii) = statsNZGiniVector(this_x, this_w);
end

end

function G = statsNZGiniVector(x, w)
% statsNZGiniVector
% G = statsNZGiniVector(X, W) returns the weighted Gini coefficient of
% vector X weighted by W. X and W are assumed to be column vectors of the
% same size.
%

n = size(x, 1);
if n>1
    wxsum = sum(w.*x, 1);
    wsum = sum(w, 1);
    
    % Ascending order sort
    [~, sxw] = sortrows([x,w]);
    sx = w(sxw) .* x(sxw);
    sw = w(sxw);
    
    pxi = cumsum(sx)./wxsum;
    pci = cumsum(sw)./wsum;
    G = 0;
    for ii=2:n
        G = G - (pci(ii)*pxi(ii-1) - pxi(ii)*pci(ii-1));
    end
else
    if ~isnan(x)
        G = 0;
    else
        G = nan;
    end
    bcG = G;
    bcwG = G;
end
end