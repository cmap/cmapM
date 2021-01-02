function [is_similarity, is_distance, is_square, is_symmetric] = ds_is_pairwise(ds)
% DS_IS_PAIRWISE Check if dataset is a pairwise similarity or distance matrix
% [is_similarity, is_distance, is_square, is_symmetric] = DS_IS_PAIRWISE(DS)

[is_similarity, is_distance, is_square, is_symmetric] = is_pairwise(ds.mat);

end