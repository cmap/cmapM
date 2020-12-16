function [czs, norm_wt, cc] = modzs(zs, ridx, varargin)
% MODZS Compute a moderated Z-score.
% CZS = MODZS(ZS, RIDX) Applies the moderated z-score procedure on matrix
% ZS. The procedure computes a weighted average of columns of ZS, where the
% weights are determined by pairwise spearman correlations of the columns
% of ZS in the space of rows RIDX. It returns a column vector CZS of length
% equal to the number of rows in ZS.
%
% [CZS, WT, CC] = MODZS(...) Also returns the weights used of each column
% in ZS and the pairwise correlation matrix CC
%
% MODZS(ZS, RIDX, 'PARAM1', val1,...) specify optional parameter name/value
% pairs.
%   'clip_low_wt'   true (default) thresholds low weights if true to the
%                   value specified by 'low_thresh_wt'
%
%   'low_thresh_wt' 0.01 (default) minimum weight threshold. Used if
%                   'clip_low_wt' is true
%
%   'clip_low_cc'   true (default) thresholds low correlations if true to the
%                   value specified by 'low_thresh_cc'
%
%   'low_thresh_cc' 0 (default) minimum correlation. Used if 'clip_low_cc' is true
%
%   'metric'        'wt_avg' (default), or 'wt_stouffer' weighting method to use   
          
pnames = {'clip_low_wt', 'clip_low_cc',...
          'low_thresh_wt', 'low_thresh_cc', 'metric'};
dflts = {true, true,...
         0.01, 0, 'wt_avg'};
args = parse_args(pnames, dflts, varargin{:});

[~, nc] = size(zs);
if nc > 1    
    cc = fastcorr(zs(ridx, :), 'type', 'spearman');
    cc = cc - diag(diag(cc));    
    if args.clip_low_cc
        % clip low cc's
        cc = clip(cc, args.low_thresh_cc, inf);
    end
    
    wt = 0.5*sum(cc, 2);
    if args.clip_low_wt
        % clip low weights
        wt = clip(wt, args.low_thresh_wt, inf);
    end
    
    switch(lower(args.metric))
        case 'wt_avg'
            sum_wt = sum(abs(wt));
        case 'wt_stouffer'
            sum_wt = sqrt(sum(wt.^2));
    end
    norm_wt = wt / sum_wt;
    czs = zs * norm_wt;
else
    czs = zs;
    norm_wt = 1;
    cc = 1;
end
end