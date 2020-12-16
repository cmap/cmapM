function save_cmap_score(outpath, scoreds)
% SAVE_CMAP_SCORE Save results of CMAP_SCORE.
%   SAVE_CMAP_SCORE(OUTPATH, SCOREDS)

gctwrite=@mkgct;
gctwrite(fullfile(outpath, 'combined.gct'), scoreds)
gctwrite(fullfile(outpath, 'up.gct'), scoreds, 'data', 'up_score')
gctwrite(fullfile(outpath, 'dn.gct'), scoreds, 'data', 'dn_score')

end