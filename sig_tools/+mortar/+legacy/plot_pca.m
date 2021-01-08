function [hf1, hf2] = plot_pca(score, pcvar, varargin)

pnames = {'title', 'showfig', 'group'};
dflts = {'PCA', true, {}};
args = parse_args(pnames, dflts, varargin{:});

% Scatter of leading two components
hf1 = myfigure(args.showfig);
if isempty(args.group)
    scatter(score(:,1), score(:, 2));
else
    gpscatter(score(:,1), score(:,2), args.group, 'sym', 'o');
end
xlabel('PC1')
ylabel('PC2')
title(sprintf('Leading two principal components, n:%d', size(score, 1)));
ylabelrt(texify(args.title), 'color', 'b', 'fontsize', 10);
namefig('pca_scatter');

% Variance vs components
pctvar = 100*cumsum(pcvar)/sum(pcvar);
n80 = find(pctvar>=80, 1, 'first');
hf2 = myfigure(args.showfig);
plot(pctvar, 'r', 'linewidth', 3)
hold on
plot(n80, pctvar(n80), 'ko','markerfacecolor','c','markersize',8)
axis tight
ylabel('% Variance')
xlabel('Num Components');
title(sprintf('80%% of the variance explained by %d components', n80))
ylabelrt(texify(args.title), 'color', 'b', 'fontsize', 10);
namefig('pca_variance');
end