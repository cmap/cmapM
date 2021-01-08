function meta = gctmeta(ds, dim)
% GCTMETA Extract Column or row annotations from a GCT structure.
%   META = GCTMETA(DS) returns a structure containing metainformation for
%   columns in DS
%   META = GCTMETA(DS, DIM) returns row annotations if DIM is 2 or 'row'. The
%   default is 1

ds = parse_gctx(ds);

if ~isvarexist('dim')
    dim = 1;
end

dim_str = get_dim2d(dim);

switch (dim_str)
    case 'column'         
        [~, keep_idx] = setdiff(ds.chd, 'cid', 'stable');
        if any(keep_idx)
            field_names = validvar([{'cid'}; ds.chd(keep_idx)], '_');
            meta = cell2struct([ds.cid, ds.cdesc(:, keep_idx)], field_names, 2);
        else
            meta = cell2struct(ds.cid, {'cid'}, 2);
        end
    case 'row'
        [~, keep_idx] = setdiff(ds.rhd, 'rid', 'stable');
        if any(keep_idx)
            field_names = validvar([{'rid'}; ds.rhd(keep_idx)], '_');
            meta = cell2struct([ds.rid, ds.rdesc(:, keep_idx)], field_names, 2);            
        else
            meta = cell2struct(ds.rid, {'rid'}, 2);
        end
end
        
end