function ds = ds_delete_missing(ds)
% DS_DELETE_MISSING Remove rows and columns with missing data.
%   Y = DS_DELETE_MISSING(X) returns a dataset Y comprising rows and
%   columns of X such entire rows or columns with missing data (NaNs) are
%   removed.

[nr, nc] = size(ds.mat);
inan = isnan(ds.mat);
col_nan = sum(inan, 1);
row_nan = sum(inan, 2);

ic = find(col_nan < nr);
ir = find(row_nan < nc);

ds = ds_slice(ds, 'ridx', ir, 'cidx', ic);

end