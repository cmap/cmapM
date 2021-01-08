function [cc, gp_vec, srt_ord] = corrMatrixToGroup(mat, gp_idx, agg_fun, corr_metric)
% corrMatrixToGroup Correlate the columns of a matrix to a subgroup of columns
% [CC, GP_VEC, SRT_ORD] = corrMatrixToGroup(MAT, GP_IDX, AGG_FUN, CORR_METRIC)
% Calculates the correlation (specified by CORR_METRIC) of each column of
% MAT to an aggregated column vector GP_VEC derived by applying AGG_FUN
% row-wise to the submatrix MAT(:, GP_IDX) CC is the the correlation of
% each column to the group aggregate vector, SRT_ORD is the ordering of
% columns when CC is sorted in descending order.

hfun = aggregate_fun(agg_fun, 2);
gp_vec = feval(hfun, mat(:, gp_idx), 2);
cc = fastcorr(mat, gp_vec, 'type', corr_metric);
[srt_cc, srt_ord] = sort(cc, 'descend');

end
