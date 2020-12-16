function h = plotCellSetStats(gmt, varargin)

pnames = {'--bins',...
          '--showfig'};
dflts = {30,...
         true};
help_str = {'Integer, Number of bins for histograms',...
            'Booolean, Display figures'};
config = struct('name', pnames,...
    'default', dflts,...
    'help', help_str);
opt = struct('prog', mfilename,...
        'desc', 'Plot set stats',...
        'undef_action', 'error');

[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

[rpt, freq_ds, ov_ds] = mortar.prism.curie.getCellSetStats(gmt);

set_size = [gmt.len]';
pct_set_size = 100*set_size/rpt.num_feature;

% Distribution of set sizes
hf1 = myfigure(args.showfig);
plot_cdfhist(set_size, args.bins);
xlabel(sprintf('Set size (of %d features)', rpt.num_feature))
title(sprintf('N=%d sets', rpt.num_set));
namefig('hist_set_size');

% Distribution of percent set sizes

hf2 = myfigure(args.showfig);
plot_cdfhist(pct_set_size, args.bins);
xlabel(sprintf('%% Set size (of %d features)', rpt.num_feature))
title(sprintf('N=%d sets', rpt.num_set));
namefig('hist_pct_set_size');

% set overlaps
hf3 = myfigure(args.showfig);
imagesc(ov_ds.mat)
axis square
grid off
title(sprintf('N=%d sets', rpt.num_set));
colorbar;
caxis([0, 1]);
colormap(parula(6));
namefig('pw_set_jaccard');

% Distribution of Jaccard overlap across sets
hf4 = myfigure(args.showfig);
plot_cdfhist(tri2vec(ov_ds.mat), args.bins);
xlabel('Set overlap (Jaccard)')
namefig('hist_set_jaccard');

% Distribution of set frequency (percentage of sets with a given feature)
hf5 = myfigure(args.showfig);
plot_cdfhist(freq_ds.mat(:, 2), args.bins);
xlabel(sprintf('%% Set frequency (of %d sets)', rpt.num_set))
title(sprintf('N=%d features', rpt.num_feature));
namefig('hist_pct_set_freq');


h = [hf1; hf2; hf3; hf4; hf5];
end