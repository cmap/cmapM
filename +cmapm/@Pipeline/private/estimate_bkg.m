function [bkg, bkg_correct] = estimate_bkg(lxbpath, well, varargin)
% ESTIMATE_BKG Estimate background expression for a set of wells.
% BKG = ESTIMATE_BKG(LXBPATH, WELL) Estimates background expression of
% list of wells WELL located at LXBPATH.
pnames = {'bkg_percentile', 'low_exp_thresh'};
dflts = {1, 128};
arg = parse_args(pnames, dflts, varargin{:});
nw = length(well);
pct = zeros(nw, 1);

for jj=1:nw
    d = dir(fullfile(lxbpath, sprintf('*_%s.lxb', well{jj})));
    if ~isempty(d)
    lxbfile = fullfile(lxbpath, d(1).name);
    lxb = parse_lxb(lxbfile);
    %ignore unassigned non-control beads
    x = lxb.RP1(lxb.RID > 10);
    % censor low expressing beads
%     x = x(x >= arg.low_exp_thresh);
    pct(jj) = prctile(x, arg.bkg_percentile);
    else
        warning('estimate_bkg:well_not_found', 'Well %s not found!', well{jj})
    end
end
bkg = nanmedian(pct);
%background correction
bkg_correct = max(bkg - arg.low_exp_thresh, 0);
end