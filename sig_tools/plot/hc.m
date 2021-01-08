function ord = hc(x, varargin)
pnames = {'metric', 'linkage'};
dflts = {'spearman', 'complete'};
args = parse_args(pnames, dflts, varargin{:});

y = pdist(x', args.metric);
z = linkage(y, args.linkage);
hf =myfigure(false);
[h, t, ord] = dendrogram(z, 0);
c = 1-squareform(y);
imagesc(c(ord,ord));
caxis([-1 1])
axis square
colorbar
set(hf, 'visible', 'on');

end