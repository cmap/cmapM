function h = plot_quantiles(m, varargin)
% PLOT_QUANTILES Plot five-point summary of data matrix.
%   PLOT_QUANTILES(M) Plots the [1, 25, 50, 75, 99] percentiles of a data
%   matrix.

pnames = {'out', 'title', 'showfig', ...
    'savefig', 'islog2','name',...
    'axes', 'dolegend'};
dflts = {'.', '', true, ...
    true, false, '5pt_summary',...
    '', true};
arg = parse_args(pnames,dflts, varargin{:});

% 5 point summary
if ishandle(arg.axes)
    if arg.showfig
        axes(arg.axes);
    else
        axesoff(arg.axes);
    end
    h = gcf;
else
    h = myfigure(arg.showfig);
end
q = [1,25, 50,75,99];
if ~arg.islog2
    m = safe_log2(m);
end
p = prctile(m, q);
plot(p', 'linewidth', 2)
axis tight
ylim([0 15])
title(texify(sprintf('%s Quantile summary', arg.title)))
xlabel('Samples')
ylabel('Log2 expression')
plbl = num2cellstr(median(p, 2), 'precision', 2);
if arg.dolegend
    leg = strcat(gen_labels(q, 'prefix', 'Q', 'suffix', ': ', 'zeropad', false), plbl);
    legend(leg, 'location','southeast')
end
namefig(arg.name);
if arg.savefig
    savefigures('out', arg.out, 'mkdir', false, ...
        'overwrite', true);
end
end