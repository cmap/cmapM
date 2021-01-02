function [G, bcG, bcwG] = weightedGini(x, varargin)
% weightedGini compute the weighted Gini coefficient
%   [G, bcG, bcwG] = weightedGiniVector(x, w) return the Gini coefficient G
%   and bias corrected variants bcG and bcwG
%
%  Examples:
%  weightedGini(ones(5,1)) % should yield 0
%  weightedGini([0.25; 0.75], [1;1]) % should yield 0.25
%  x=[3;1;7;2;5]
%  w=[1;2;3;4;5]
%  weightedGini(x,w) % should yield 0.2983050847
%
%  % Small sample sizes can yield biased estimates
%  x2 = zeros(1000, 1);
%  x2(1) = 1;
%  % Note that G != 1 for small sample sizes
%  % but approaches 1 for larger samples
%  [G10, bcG10, bcwG10] = weightedGini(x2(1:10, 1)) 
%  [G, bcG, bcwG] = weightedGini(x2)

% Note: This is a Matlab port of weighted.gini from the R acid package
% https://cran.r-project.org/web/packages/acid/index.html

nin = nargin;
[nr, nc] = size(x);
if nin<2
    w = ones(nr, nc);
    dim = 1;
elseif nin<3
    w = varargin{1};
    dim = 1;
else
    w = varargin{1};
    dim = varargin{2};
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
bcG = nan(nc, 1);
bcwG = nan(nc, 1);
keep_idx = ~isnan(x);
for ii=1:nc
    this_keep = keep_idx(:, ii);
    this_x = x(this_keep, ii);
    this_w = w(this_keep, ii);
    [G(ii), bcG(ii), bcwG(ii)] = weightedGiniVector(this_x, this_w);
end
end

function [G, bcG, bcwG] = weightedGiniVector(x, w)
% weightedGiniVector compute the weighted Gini coefficient for a single
% column vector.
%   [G, bcG, bcwG] = weightedGiniVector(x, w) return the Gini coefficient G
%   and bias corrected variants bcG and bcwG
%

n = size(x, 1);
if n>1
    [x, x_order] = sort(x, 1);
    w = w(x_order) / sum(w);
    wc = cumsum(w);
    xwc = cumsum(w.*x);
    % coercing such cumulative distr with max=1
    xwc = xwc/xwc(n);
    G = (xwc(2:end,:))' * wc(1:end-1,:) - (xwc(1:end-1))'*wc(2:end);
    % bias corrected
    bcG = G * n/(n-1);
    % using bias correction from cov.wt
    bcwG = G * 1/(1-sum(w.^2));
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
