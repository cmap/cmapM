function [score_mat, rank_mat] = defuse_rankscore(rore_mat)
%  defuse_rankscore Convert a composite rank-score matrix to components
% [score_mat, rank_mat] = defuseRankScore(rore_mat)
% SEE fuse_rankscore

rank_mat = fix(abs(rore_mat)/1e2);
score_mat = sign(rore_mat) .* (abs(rore_mat) - rank_mat*1e2);

% compute is done in single-precision currently
rank_mat = single(rank_mat);
score_mat = single(score_mat);
end