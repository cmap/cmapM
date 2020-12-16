function [h, Xq, Yq, Vq] = plot_scatterdensity(x, y, nbin, lambda, varargin)
% SCATTERDENSITY Plot binned and smoothed histogram of bivariate data.
%   SCATTERDENSITY(X, Y, NBIN, LAMBDA) Plot a bivariate histogram of vector
%   X vs vector Y using NBINs to compute the histogram and a smoothing
%   parameter LAMBDA to perform local smoothing based on Eilers et
%   al(2009). Set LAMBDA to zero to turn off smoothing. The choice of NBINS
%   and LAMBDA are dependent partly on the data and partly to personal
%   taste. If the number of data pairs are ~10^4, NBINS of 100 to 200 and
%   LAMBDA between 1 to 100 yield reasonable results.
%
%  References: 
%   1. Enhancing scatterplots with smoothed densities. (2009) Eilers, Paul
%   H.C. and Goeman, Jelle J. Bioinformatics 20(5).
%   2. FileExchange:ScatterCloud 
%   http://www.mathworks.com/matlabcentral/fileexchange/6037-scattercloud/content/scattercloud.m

pnames = {'--type'};
dflts = {'count'};
choices = {{'count', 'percent', 'fraction'}};
desc = {'binning options'};
conf = struct('name', pnames, 'default', dflts, 'choices', choices, ...
              'help', desc);
opt = struct('prog', mfilename, 'desc', ['Plot binned and smoothed ' ...
                    'histogram of bivariate data']);
args = mortar.common.ArgParse.getArgs(conf, opt, varargin{:});

x = x(:);
y = y(:);
if isscalar(nbin)
    nbin = [nbin, nbin];
end

% bin the data
[n, b] = hist3([y, x], nbin);
switch(lower(args.type))
  case 'percent'
    n = 100 * n / max(sum(n(:)), 1);
  case 'fraction'
    n = n / max(sum(n(:)), 1);
end

% smooth both dimensions
Vq = localsmooth(localsmooth(n, lambda)', lambda)';
Xq = b{2};
Yq = b{1};

% plot as surface
%h = surf(Xq, Yq, Vq, 'edgecolor', 'none', 'facecolor', 'flat');
h = imagesc(Xq, Yq, Vq);
hold on
contour(Xq, Yq, Vq, 5, 'color', get_color('grey'));
ax = gca;
view(ax, 2);
axis xy
colormap(flipud(bone))
colorbar

% make the grid visible on top
set(ax, 'layer', 'top')

end

function Z = localsmooth(Y, lambda)
m = size(Y, 1);
E = speye(m);
D1 = diff(E);
D2 = diff(D1);
P = lambda^2*(D2'*D2) + 2*lambda*(D1'*D1);
Z = (E+P)\Y;
end

