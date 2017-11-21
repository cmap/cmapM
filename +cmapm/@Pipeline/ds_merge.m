function combods = ds_merge(ds1, ds2, varargin)
% DS_MERGE Combine two datasets
% COMBODS = DS_MERGE(DS1, DS2);

combods = merge_two(ds1, ds2, varargin{:});

end