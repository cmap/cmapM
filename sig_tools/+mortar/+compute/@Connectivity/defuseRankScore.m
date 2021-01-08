function [ds_score, ds_rank] = defuseRankScore(ds_rore)
% defuseRankScore Convert a composite rank-score matrix to components
% [ds_score, ds_rank] = defuseRankScore(ds_rore)
% SEE makeRankScore
ds_rore = parse_gctx(ds_rore);
ds_score = ds_rore;
ds_rank = ds_rore;

[ds_score.mat, ds_rank.mat] = mortar.compute.Connectivity.defuse_rankscore(ds_rore.mat);

end