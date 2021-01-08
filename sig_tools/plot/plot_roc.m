function plot_roc(xpdf, ypdf, varargin)
% Plot ROC curves for a pair of distributions.
assert(isequal(size(xpdf), size(ypdf)));

pnames = {'group', 'title', 'xlabel','ylabel', 'name', 'showfig'};
dflts = {'', '', '', '', '', true};

args = parse_args(pnames, dflts, varargin{:});
[nr, nc] = size(xpdf);

myfigure(args.showfig);
h = plot(100-cumsum(xpdf'), 100-cumsum(ypdf'));
xlim([0 100])
ylim([0 100])

legend(args.group, 'location', 'eastoutside');
axis square
col = get_palette(nr);
for ii=1:length(h); 
    set(h(ii),'color',col(ii,:),'linewidth', 2)
end
hold on
plot([0 100], [0 100],'k--')

title(args.title)
xlabel(args.xlabel)
ylabel(args.ylabel)
namefig(args.name);

end