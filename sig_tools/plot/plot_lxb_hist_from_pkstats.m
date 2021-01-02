function hf =  plot_lxb_hist_from_pkstats(x, pkstats, varargin)

pnames = {'verbose', ...
    'highthresh', ...
    'logxform', ...
    'lowthresh', ...
    'out', ...
    'overwrite', ...
    'rpt', ...
    'savefig', ...
    'showfig', ...
    'title',...
    'name',...
    'x_reference',...
    'x_reference_label'};

dflts = {true, ...
    14, ...
    true, ...
    4, ...
    pwd, ...
    false, ...
    'hist', ...
    false, ...
    false, ...
    '',...
    '',...
    [],...
    ''};

args = parse_args(pnames, dflts, varargin{:});
if args.logxform
    x = safe_log2(x);
end

badbeads = (x < args.lowthresh | x > args.highthresh);
xcensored = x;
xcensored(badbeads) = [];

% pkexp is in linear scale
pkstats.pkexp = safe_log2(pkstats.pkexp);

[f, xi] = ksdensity(xcensored);
fstar = interp1(xi, f, pkstats.pkexp);

hf = myfigure(~args.savefig);
bins = linspace(4, 16, 50);
[a0,b0] = hist(x, bins);
bar(b0,a0/max(a0), 'facecolor',[0.75,0.75,0.75])
hold on
[a, b] = hist(xcensored, bins);

bh = bar(b,a/max(a), 'hist');
% color brewer PuOr scheme
purple = [153, 142, 195]/255;
orange = [241, 163, 64]/255;
set (bh, 'facecolor', orange)
th = text(pkstats.pkexp+0.05, fstar+0.05, num2cellstr(1:length(pkstats.pkexp)));
set(th,'color', 'k', 'fontsize', 16, 'fontweight', 'bold', ...
    'backgroundcolor', [.7 .9 .7])
plot(xi, f, 'k', 'linewidth', 2)
plot(pkstats.pkexp, fstar, 'ko','markerfacecolor', 'c', 'markersize', 7)
keep = 1:min(4, length(pkstats.pkexp));
expstr = print_dlm_line(pkstats.pkexp(keep), 'dlm', ', ', 'precision', 1);
supstr = print_dlm_line(pkstats.pksupport(keep), 'dlm', ', ', 'precision', 0);
suppctstr = print_dlm_line(pkstats.pksupport_pct(keep),'dlm',', ','precision',0);
xlim ([4, 15])
h = title(texify(sprintf('%s n=%d exp:(%s) sup:(%s) pct:(%s)', ...
    args.title, pkstats.ngoodbead, expstr, supstr, suppctstr)));
set(h,'fontweight','bold','fontsize',11)

if ~isempty(args.x_reference)
    yl = get(gca, 'ylim');
    nref = length(args.x_reference);
    if isempty(args.x_reference_label)
        args.x_reference_label = gen_labels(nref, 'prefix', 'ref_');
    end
    if nref >1
        pal = get_palette(nref);
    else
        pal = get_color('azure');
    end
    for ii=1:nref
        plot_constant(args.x_reference(ii), false, 'color', pal(ii, :),...
            'linewidth', 2, 'linestyle', '--');
        th_ref = text(args.x_reference(ii)+0.05, 0.9, texify(args.x_reference_label{ii}));
        set(th_ref,'color', 'k', 'fontsize', 10, 'fontweight', 'normal',...
            'rotation', 0);
    end
    ylim(yl);
end

ylabelrt(texify(args.rpt), 'color', 'b');
if ~isempty(args.name)
    namefig(args.name);
end
if args.savefig
    hf = savefigures('out', args.out, 'mkdir', false,...
        'overwrite', args.overwrite, 'closefig', true,...
        'verbose', args.verbose);
end
