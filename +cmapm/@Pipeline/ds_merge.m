function combods = ds_merge(ds1, ds2, varargin)
% DS_MERGE Combine two datasets
% COMBODS = DS_MERGE(DS1, DS2) will attempt to concatenate DS1 and DS2
% either horizontally or vertically depending on the overlap of their row
% and column ids. If the row ids of DS1 and DS2 overlap exactly
% and the column ids are mutually exclusive, then the datasets are stacked
% horizontally by concatenating their columns. If on the other hand
% the column ids overlap while the row ids are mutually exclusive the
% datasets are stacked vertically by concatenating their rows.
%

combods = merge_two(ds1, ds2, varargin{:});

end