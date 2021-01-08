function [hf1, hf2, hf3] = plot_pca(score, pcvar, varargin)

pnames = {'title', 'showfig', 'group', 'location'};
dflts = {'PCA', true, {}, 'best'};
args = parse_args(pnames, dflts, varargin{:});

pctvar_per_pc = 100*pcvar./sum(pcvar);
pctvar = 100*cumsum(pcvar)/sum(pcvar);

% Scatter of leading two components
hf1 = myfigure(args.showfig);
if isempty(args.group)
    scatter(score(:,1), score(:, 2));
else
    gpscatter(score(:,1), score(:,2), args.group,...
        'sym', 'o', 'location', args.location);
end
xlabel(sprintf('PC1 (%2.1f%% of var)', pctvar_per_pc(1)));
ylabel(sprintf('PC2 (%2.1f%% of var)', pctvar_per_pc(2)));
title(sprintf('Leading two principal components, n:%d', size(score, 1)));
ylabelrt(texify(args.title), 'color', 'b', 'fontsize', 10);
axis square
namefig('pca_scatter');

% Variance vs components
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

hf3 = myfigure(args.showfig);
explained = 100*pcvar/sum(pcvar);
npc = min(length(explained), 10);
bar(explained(1:npc))
hold on
plot(pctvar(1:npc), 'ro-', 'linewidth', 2, 'markeredgecolor', 'r');
axis tight
ylim([0 100])
title (sprintf('Variance explained by the first %d components', npc));
xlabel('PC')
ylabel('Variance explained')
ylabelrt(texify(args.title), 'color', 'b', 'fontsize', 10);
namefig('pca_explained_by_10');

end
