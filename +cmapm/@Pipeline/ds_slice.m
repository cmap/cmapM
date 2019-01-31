function ds = ds_slice(ds, varargin)
% DS_SLICE Extract a subset of data from a GCT structure.
%   DS_SLICE(DS, 'param1', value1, ...)
%   Extracts a subset of data from GCT structure DS. The following
%   parameters are supported:
%       Parameter   Value
%       'rid'       List of row-ids to extract. Default is all row ids.
%       'cid'       List of column-ids to extract. Default is all column ids.
%       'exclude_rid'   Select row-ids excluding 'rid' if true. Default is false
%       'exclude_cid'   Select column-ids excluding 'cid' if true. Default is false
%       'ridx'      Array of row indices to extract.
%       'cidx'      Array of column indices to extract.
%       'ignore_missing'    Ignore missing ids if true. Default is false.
%       'isverbose' Verbosity. Default is true.

ds = ds_slice(ds, varargin{:});

end