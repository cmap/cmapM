function cc = ds_corr(ds, varargin)
% DS_CORR Compute pairwise correlations for a dataset.
%   CC = DS_CORR(DS) Compute spearman correlation. A Wrapper function
%   to fastcorr that returns a dataset instead of a matrix.
%   CC = DS_CORR(DS, 'type', 'pearson') Computes pearson instead.

cc = ds_corr(ds, varargin{:});

end