% CONTROL_PLOTS Plots of L1000 Control analytes

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function fnlist = control_plots(ds, dscnt, varargin)

pnames = {'out', 'rpt', 'showfig', 'savefig', 'closefig'};
dflts = {'.', '', true, true, false};
arg = parse_args(pnames,dflts, varargin{:});
%delta
% mfi_ctrl = [11, 401, 402, 403];
% count_ctrl = [11, 402];
%epsilon
mfi_ctrl = [11, 499];
count_ctrl = [11, 499];
excludefigs = findobj('type', 'figure');

%MFI of control analytes
myfigure(arg.showfig);
plot(safe_log2(ds.mat(mfi_ctrl,:))', 'linewidth', 2)
axis tight
xlabel('Well')
ylabel('log2 (expression)')
title(texify(sprintf('%s MFI ctrl',arg.rpt)))
legend(gen_labels(mfi_ctrl,'zeropad',false,'prefix', 'Analyte '),...
    'location', 'southeast')
ylim([4 15])
namefig('mfi_ctrl');

% platemap of median counts per well: plate_count_
wellcnt = nanmedian(dscnt.mat);
plate_med = median(wellcnt);
plate_cv = 100*iqr(wellcnt)/plate_med;
figlbl = 'plate_count';
figtitle = sprintf('%s Median count / well median:%3.0f cv:%2.0f', ...
    arg.rpt, plate_med, plate_cv);
plot_platemap(wellcnt, dscnt.well, 'name', figlbl, 'title', figtitle, ...
    'colormap', 'hot', 'showfig', arg.showfig);
if ~isempty(regexpi(arg.rpt, 'duo'))
    caxis([30 140])
else
    caxis([10 70])
end

%platemap of pert_type: plate_ptype_

if ds.cdict.isKey('pert_type')
    figlbl = 'plate_ptype';
    figtitle = sprintf('%s Sample Type', arg.rpt);
    plot_platemap(ds.cdesc(:,ds.cdict('pert_type')), ds.well, 'discrete', true,...
        'name', figlbl, 'title', figtitle, 'showfig', arg.showfig, 'do_leg', false);
end

% Median counts
medcnt = nanmedian(dscnt.mat,2);
medcnt_med = median(medcnt);
medcnt_cv = 100*iqr(medcnt)/medcnt_med;
myfigure(arg.showfig);
plot(medcnt, 'k', 'linewidth', 2)
outliers = outlier1d(medcnt, 'tail', 'left');
hold on
plot(outliers, medcnt(outliers), 'ro', 'markerfacecolor', 'r')
% jitter = 6*(rand(size(outliers))-0.5);
% th = text(outliers+1, medcnt(outliers)+jitter, num2cellstr(outliers));
th = smart_text(outliers, medcnt(outliers), num2cellstr(outliers));
set (th, 'color', 'b', 'fontweight', 'bold')
axis tight
ylim([0 150])
xlabel('Analyte')
ylabel('Median bead count')
grid on
title(texify(sprintf('%s Bead count/analyte med:%3.0f cv:%2.0f',arg.rpt,...
    medcnt_med, medcnt_cv)))
namefig('med_count');

%Counts of control analytes
myfigure(arg.showfig);
plot(dscnt.mat(count_ctrl, :)', 'linewidth', 2)
axis tight
xlabel('Well')
ylabel('Count')
med_count = median(dscnt.mat(count_ctrl, :), 2);
title(texify(sprintf('%s Bead Set Controls: Hi:%2.0f Lo:%2.0f Ratio: %2.2f', ...
    arg.rpt, max(med_count), min(med_count), max(med_count)/min(med_count))))
legend(gen_labels(count_ctrl,'zeropad',false,'prefix', 'Analyte '), ...
    'location', 'southeast')
ylim([0 150])
namefig('beadset_ctrl');

% 5 point summary
hdr = sprintf ('%s RAW', arg.rpt);
plot_quantiles(ds.mat, 'title', hdr, 'name', 'quantiles_raw', ...
    'islog2', false, 'showfig', arg.showfig,'savefig', false);

% myfigure(arg.showfig);
% q = [1,25, 50,75,99];
% p = prctile(ds.ge,q);
% plot(safe_log2(p)', 'linewidth', 2)
% axis tight
% ylim([0 15])
% title(texify(sprintf('%s Quantile summary', arg.rpt)))
% xlabel('Samples')
% ylabel('Log2 expression')
% plbl = num2cellstr(median(safe_log2(p), 2), 'precision', 2);
% leg = strcat(gen_labels(q,'prefix','Q', 'suffix',': ','zeropad',false), plbl);
% legend(leg, 'location','southeast')
% namefig('5pt_summary');


if arg.savefig
    fnlist = savefigures('out', arg.out,...
        'mkdir', false,...
        'exclude', excludefigs,...
        'overwrite', true,...
        'closefig', arg.closefig);         
else
    fnlist={};
end
