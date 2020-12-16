function ds = gct2long_gct(ds, varargin)
% GCT2LONG_GCT convert gct dataset to long form.
% long_ds = GCT2LONG_GCT(DS)

pnames = {'cid'};
dflts = {'Value'};
args = parse_args(pnames, dflts, varargin{:});

[nr, nc] = size(ds.mat);
ncdesc = length(ds.chd);
[ic,ir] = meshgrid(1:nc, 1:nr);
new_rid = strcat(ds.rid(ir(:)),':', ds.cid(ic(:)));
rhd = [{'id';'col_id'}; ds.chd; {'row_id'}; ds.rhd];
if ncdesc
    col_meta = [ds.cid, ds.cdesc];
else
    col_meta = ds.cid;
end
row_meta = cell2struct([new_rid,...
    reshape(repmat(col_meta, 1, nr)', ncdesc+1, nc*nr)',...
    repmat([ds.rid, ds.rdesc], nc, 1)],...
    rhd, 2);
ds = mkgctstruct(ds.mat(:), 'rid', new_rid, 'cid', {args.cid});
ds = annotate_ds(ds, row_meta, 'dim', 'row');

end
