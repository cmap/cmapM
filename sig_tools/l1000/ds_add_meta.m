function ds = ds_add_meta(ds, dim, hd, meta)
% DS_ADD_META Add / Update metadata fields in GCT.
% NEWDS = DS_ADD_META(DS, DIM, HD, META)

%[nr, nc] = size(ds.mat);
nr = numel(ds.rid);
nc = numel(ds.cid);
if ischar(hd)
    hd = {hd};
end
nhd = length(hd);
if ischar(meta)
    meta = {meta};
end
if isscalar(meta)
    if all(strcmpi('row', dim))
        meta = meta(ones(nr, nhd));
    else
        meta = meta(ones(nc, nhd));
    end
end

switch(lower(dim))
    case 'row'
        assert(isequal(size(meta, 1), nr), ...
            'Number of rows in meta should match rows in matrix');
        assert(isequal(size(meta, 2), nhd), ...
            'Number of columns in meta should match number of elements in hd');
        for ii=1:nhd
        if ds.rdict.isKey(hd{ii})
            ds.rdesc(:, ds.rdict(hd{ii})) = meta(:, ii);
        else
            ds.rhd = [ds.rhd(:); hd(ii)];
            if isempty(ds.rdesc)
                ds.rdesc = meta(:, ii);
            else
                ds.rdesc(:, end+1) = meta(:, ii);
            end
        end
        end
        ds.rdict = list2dict(ds.rhd);
    case 'column'
        assert(isequal(size(meta, 1), nc), ...
            'Number of rows in meta should match columns in matrix');
        assert(isequal(size(meta, 2), nhd), ...
            'Number of columns in meta should match number of elements in hd');
        for ii=1:nhd
        if ds.cdict.isKey(hd{ii})
            ds.cdesc(:, ds.cdict(hd{ii})) = meta(:, ii);
        else
            ds.chd = [ds.chd(:); hd(ii)];
            if isempty(ds.cdesc)
                ds.cdesc = meta(:, ii);
            else
                ds.cdesc(:, end+1) = meta(:, ii);
            end
        end
        end
        ds.cdict = list2dict(ds.chd);

    otherwise
        error('Dim should be ''row'' or ''column''')
end
end
