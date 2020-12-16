function fnlist = plot_qc(calibds, varargin)
% QCPLOTS Generate L1000 QC plots.
%
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
% Changes: 
%   Nov 30,2010: simplified, assumes just one plate (ie nPlate=1)

pnames = {'out', 'rpt', 'showfig', 'savefig', 'mkplatemap', 'closefig', 'cal_ylim'};
dflts = {'.', '', true, true, true, false, [0, 8000]};
arg = parse_args(pnames,dflts, varargin{:});

excludefigs = findobj('type', 'figure');
if(arg.savefig)
    
    %RankOrderFile = sprintf('stripe_o_gram_%s', arg.rpt);            
    
    %MedianExpHMFile = sprintf('invset_medexp_hm_%s', arg.rpt);
else
    fnlist={};
end

%basic quality scores
[pMat, pScore] = compute_prob_score(calibds);
ccScore = compute_cc_score(calibds);
nCalib = length(pMat);

%colormap
% cm = jet;
% cm = cm(round(linspace(1, length(cm), 14)), :);

% summary calib plot with sample plots super-imposed: calibplot_

if calibds.cdict.isKey('pert_type') && calibds.cdict.isKey('pert_mfc_desc')
    pt = ds_get_meta(calibds, 'column', 'pert_type');    
    pd = ds_get_meta(calibds, 'column', 'pert_mfc_desc');
    lma_idx = strcmpi('lma_x', pt);
    pt(lma_idx) = pd(lma_idx);
    
    plot_calib(calibds.mat, 'showfig', arg.showfig, ...
        'group', pt,...
        'sl', calibds.cid, ...
        'showsamples',true, 'title', arg.rpt,...
        'showmean', false,...
        'ylim', arg.cal_ylim);
else
    plot_calib(calibds.mat, 'showfig', arg.showfig, 'sl', ...
        calibds.cid, 'showsamples', true, 'title', arg.rpt,...
        'ylim', arg.cal_ylim);
end
namefig('calibplot');

%inv set median expression plots: invset_medexp_
% exp vs sample plot
nSample = size(calibds.mat,2);
myfigure(arg.showfig);
plot(calibds.mat', '.');
axis tight
legend(calibds.rid,'location','northeastoutside')
xlabel ('Sample')
ylabel ('Invariant set median expression')
title (texify(sprintf('%s', arg.rpt)))
xlim(0.5 + [0 nSample]);
ylim([0 8000])
grid on
namefig('invset_medexp');

%level vs sample heatmap
% myfigure(arg.showfig);
% imagesc(calibds.ge);
% axis xy
% colorbar
% xlabel ('Sample')
% ylabel ('Invset Level')
% title (texify(sprintf('%s', arg.rpt)))
% set (gcf, 'tag', sprintf('%s', MedianExpHMFile))

% plate probability matrices: invset_confmatrix_
myfigure(arg.showfig);
imagesc(1-pMat)
colormap bone
xlabel ('Expected order')
ylabel ('Observed order')
title (texify(sprintf('%s, Plate:%d', arg.rpt)))
axis square
set(gca, 'xtick', 1:nCalib, 'ytick', 1:nCalib);
namefig('invset_confmatrix');

% Span - range plot
myfigure(arg.showfig);
span = range(calibds.mat);
dr = max(calibds.mat) ./ min(calibds.mat);
if calibds.cdict.isKey('pert_type') 
    %NOTE: custom gscatter for legend fix
%     gpscatter(dr, span, calibds.sdesc('pert_type'), 'krbgm', 'osh*pv', 8);    
    gpscatter(dr, span, calibds.cdesc(:, calibds.cdict('pert_type')),...
        'clr', 'krbgm', 'sym', 'osh*pv', 'siz', 8, 'location','southeast');    
else
    plot(dr, span, '.');
end
axis tight
xlabel ('Calibration Fold change')
ylabel ('Calibration Range')
title (texify(sprintf('%s, Range vs Fold change fc:%2.1f range:%2.1f',...
    arg.rpt, nanmedian(dr), nanmedian(span))))
grid on
xlim([0 25])
ylim([0 8000])
namefig('drspan');

%stripe-o-gram plot of calib geneset rankorder
% myfigure(arg.showfig);
% 
% [sortge, sortidx] = sort(calibds.ge);
% imagesc(sortidx)
% colormap(jet(size(calibds.ge, 1)))
% axis xy
% colorbar
% xlabel ('Sample')
% ylabel ('Invset Level')
% title (texify(sprintf('Rank order:%s, Plate:%d', arg.rpt)))
% set(gcf, 'tag', RankOrderFile);

%stripe-o-gram plot of calib geneset rankorder + probability score for each plate
% stripe_o_gram_score_*
myfigure(arg.showfig);
[sortge, sortidx] = sort(calibds.mat);
subplot(2,1,1)
imagesc(sortidx)
colormap(jet(size(calibds.mat,1)))
axis xy
xlabel ('Sample')
ylabel ('Invset Level')
title (texify(sprintf('Rank order:%s', arg.rpt)))
subplot(2,1,2)
plot(ccScore)
axis tight
ylim ([0 1]);
xlabel ('Sample')
ylabel ('Quality score')
namefig('stripe_o_gram_score');

%table of prob scores
if (arg.savefig)    
    fid = fopen (fullfile(arg.out, 'sample_score.txt'), 'wt');
else
    fid = 1;
end

head = {'SAMPLE_NAME';...
    'QUALITY_SCORE';...
    };
print_dlm_line(head, 'fid', fid);
for ii=1:length(calibds(1).cid)
    fprintf (fid, '%s\t%2.2f\n', calibds.cid{ii}, ccScore(ii));
end

% platemap of quality scores: plate_scores_
if arg.mkplatemap
    fprintf('Generating platemap scores...\n')
    [wn, word] = get_wellinfo(calibds.cid);
    if ~isempty(wn)
        % myfigure(arg.showfig);
        plot_platemap(ccScore, wn, 'title', arg.rpt,...
            'colormap', 'jet', 'showfig', ...
            arg.showfig, 'name', 'plate_scores');
        caxis([0.8 1])
    end
end

if (arg.savefig)    
    fnlist = savefigures('out', arg.out,...
        'mkdir', false, ...
        'exclude', excludefigs,...
        'overwrite', true,...
        'closefig', arg.closefig);     
    fclose(fid);
end

