function ds_rore = fuseRankScore(ds_score, ds_rank, data_type)
% fuseRankScore Generate composite rank-score dataset
% ds_rore = fuseRankScore(ds_score, ds_rank) Combines scores and ranks from
% GCT datasets ds_score and ds_rank to single precision floats. See
% FUSE_RANKSCORE for details. Use defuseRankScore to obtain scores and
% ranks from a rank-score dataset

ds_score = parse_gctx(ds_score);
%ds_score.mat = double(ds_score.mat);
ds_rank = parse_gctx(ds_rank);
%ds_rank.mat = double(ds_rank.mat);

% Ensure that matrices have the same dimensions and are ordered identically
is_row_match = isequal(ds_score.rid, ds_rank.rid);
is_col_match = isequal(ds_score.cid, ds_rank.cid);
if ~is_row_match || ~is_col_match;
    ds_score = ds_slice(ds_score, 'rid', ds_rank.rid,...
                    'cid', ds_rank.cid);
    is_row_match = isequal(ds_score.rid, ds_rank.rid);
    is_col_match = isequal(ds_score.cid, ds_rank.cid);
end
assert(is_row_match, 'Row id mismatch');
assert(is_col_match, 'Column id mismatch');

ds_rore = ds_score;
ds_rore.mat = mortar.compute.Connectivity.fuse_rankscore(...
                ds_score.mat, ds_rank.mat, data_type);

end