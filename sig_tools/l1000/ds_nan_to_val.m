function ds = ds_nan_to_val(ds, val)
% DS_NAN_TO_VAL replaces NaN with scalar value
% NEWDS = DS_NAN_TO_VAL(DS, V)

narginchk(2, 2);
assert(isds(ds), 'Invalid dataset');

ds.mat = nan_to_val(ds.mat, val);

end