function plot_mds(Y, e, varargin)

pnames = {'title', 'showfig'};
dflts = {'Multi-dimensional scaling', true};
args = parse_args(pnames, dflts, varargin{:});

% Scatter of leading two components
myfigure(args.showfig)
scatter(Y(:,1), Y(:, 2));
xlabel('MDS1')
ylabel('MDS2')
title(texify(args.title));

% Eigenvalue plot
relvar = e/max(abs(e));
myfigure(args.showfig)
plot(relvar, 'r', 'linewidth', 3)
axis tight
ylabel('Eigen Value')
end