function meta = ds_get_annotations(ds, dim)
% GCTMETA Extract Column or row annotations from a GCT structure.
%   META = GCTMETA(DS) returns a structure containing metainformation for
%   columns in DS
%
%   META = GCTMETA(DS, DIM) returns row annotations if DIM is
%   2 or 'row'. The default is 'column'

if ~isvarexist('dim')
    dim_str = 'column';
else
    
    dim_str = get_dim2d(dim);
end

meta = gctmeta(ds, dim_str);

end