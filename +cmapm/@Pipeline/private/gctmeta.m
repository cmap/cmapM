function meta = gctmeta(ds, dim)
% GCTMETA Extract Column or row annotations from a GCT structure.
%   META = GCTMETA(DS) returns a structure containing metainformation for
%   columns in DS
%   META = GCTMETA(DS, DIM) returns row annotations if DIM is 2 or 'row'. The
%   default is 1

ds = parse_gctx(ds);

if ~isvarexist('dim')
    dim = 1;
elseif ischar(dim)
    % support 'row'=2, 'column'=1 
    dim = strcmpi(dim,'row')+1;
end

assert(any(ismember(dim, [1,2])),...
        'dim must be 1 or 2, got %d', dim);

switch (dim)
    case 1
        keep_idx = ~strcmp(ds.chd, 'cid');   
        if any(keep_idx)
        meta = cell2struct([ds.cid, ds.cdesc(:, keep_idx)], [{'cid'}; ds.chd(keep_idx)], 2);
        else
            meta = cell2struct(ds.cid, {'cid'}, 2);
        end
    case 2
        keep_idx = ~strcmp(ds.rhd, 'rid');
        if any(keep_idx)
            meta = cell2struct([ds.rid, ds.rdesc(:, keep_idx)], [{'rid'}; ds.rhd(keep_idx)], 2);            
        else
            meta = cell2struct(ds.rid, {'rid'}, 2);
        end
end
        
end