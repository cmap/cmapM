function [sig, samp_wt, cc] = distil_core(repzs, metric, lmidx, clip_low_wt, clip_low_cc, modz_metric)

nrep = size(repzs, 2);
switch (lower(metric))
    case 'stoufz'
        % Stouffer's Zscore
        sig = sum(repzs, 2)/sqrt(nrep);
        samp_wt = ones(nrep, 1);
        cc = fastcorr(repzs, 'spearman');
    case 'medianz'
        %median
        sig = median(repzs, 2);
        samp_wt = ones(nrep, 1);
        cc = fastcorr(repzs, 'spearman');
    case 'avgz'
        %mean
        sig = mean(repzs, 2);
        samp_wt = ones(nrep, 1);
        cc = fastcorr(repzs, 'spearman');
    case 'modz'
        % zs moderated by replicate correlations        
        [sig, samp_wt, cc] = modzs(repzs, lmidx, ...
            'clip_low_wt', clip_low_wt,...
            'clip_low_cc', clip_low_cc,...
            'metric', modz_metric);
    otherwise
        error('Unknown signature method: %s', metric)
end