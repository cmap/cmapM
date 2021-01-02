function h = plot_df_with_tail(x, varargin)
% Plot distribution along with tails

pnames = {'showfig', 'title', 'xlabel',...
          'xlim', 'xlim_left', 'xlim_right',...
          'name', 'bin_size', 'linewidth',...
          'color'};
dflts =  {true, '', '', ...
          [], [], [],...
          '', 30, 2,... 
          get_color('blue')};
args = parse_args(pnames, dflts, varargin{:});

if isempty(args.xlim) || isempty(args.xlim_left) || isempty(args.xlim_right)
    d = describe(x);
    if isempty(args.xlim)
        args.xlim = [d.min, d.max];
    end
    if isempty(args.xlim_left)
        args.xlim_left = [d.min, max(d.fivenum(2), d.min+d.fivenum(2))];
    end
    if isempty(args.xlim_right)
        args.xlim_right = [min(d.max-d.fivenum(4), d.fivenum(4)), d.max];
    end
end

myfigure(args.showfig);
subplot(2, 2, 1)
bins = linspace(args.xlim(1), args.xlim(2), args.bin_size);
h11 = plot_norm_hist(x, bins);
xlim(args.xlim);
if ~isempty(args.xlabel)
    xlabel(args.xlabel);
end
title('Histogram');

subplot(2, 2, 2)
h12 = cdfplot(x);
xlim(args.xlim);

subplot(2, 2, 3)
h21 = cdfplot(x);
xlim(args.xlim_left);
title('Left tail');

subplot(2, 2, 4)
h22 = cdfplot(x);
xlim(args.xlim_right);
title('Right tail');

h = [h11; h12; h21; h22];

if isempty(args.title)
    args.title = sprintf('n=%d', length(x));
end
mtit(args.title);

if ~isempty(args.name)
    namefig(args.name);
end

% color and linewidth
set(h11, 'facecolor', args.color);
set(h(2:end), 'color', args.color, 'linewidth', args.linewidth);


end