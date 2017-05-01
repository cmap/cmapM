function qnormds = l1kt_qnorm(ds, out, varargin)
% L1KT_QNORM Perform quantile normalization on .gct data set
%   QNORMDS = L1KT_QNORM(DS,OUT) takes as input a .gct data structure or
%   the path to a .gct file. It returns a quantile-normalized .gct data
%   structure QNORMDS to the MATLAB workspace, and saves the data set to
%   the directory OUT. It also saves gene expression quantile plots to the
%   directory OUT.

% Get optional arguments
pnames = {'plate'};
dflts = {''};
args = parse_args(pnames,dflts,varargin{:});

qnormds = parse_gct(ds, 'class', 'double');
% plot the data set quantiles before qnorming
myfigure(false)
subplot(2,1,1)
qtlplot(qnormds.mat, 'pre-qnorm')

% Apply qnorm
qnormds.mat = qnorm(qnormds.mat);

% post qnorm plot
subplot(2,1,2)
qtlplot(qnormds.mat, 'post-qnorm')
namefig('quantile_plots');
savefigures('out', out, 'mkdir', false, 'closefig', true, 'overwrite', true)
mkgct(fullfile(out, sprintf('%s_QNORM', args.plate)), qnormds)
end

function qtlplot(m, ptitle)
% A stripped-down version of the plot_quantiles function
% 5 point summary

q = [1, 25, 50, 75, 99];
p = prctile(m, q);
plot(p', 'linewidth', 2)
axis tight
ylim([0 15])
title({sprintf('%s quantile summary', ptitle)})
xlabel('Samples')
ylabel('Log2 expression')
plbl = num2cellstr(median(p, 2), 'precision', 2);
leg = strcat(gen_labels(q, 'prefix', 'Q', 'suffix', ': ', ...
    'zeropad', false), plbl);
legend(leg, 'location','southeast')
end