function rpt = pwgroup_stats(ds, gset, match_field)
ds = parse_gctx(ds);
gset = parse_geneset(gset);
ngroup = numel(gset);

col_id = ds_get_meta(ds, 'column', match_field);
row_id = ds_get_meta(ds, 'row', match_field);

cid_lut = mortar.containers.Dict(col_id);
rid_lut = mortar.containers.Dict(row_id);

rpt = struct('gp_id', {gset.head}',...
    'gp_desc', {gset.desc}',...
    'gp_size', num2cell([gset.len]'),...
    'mom', nan,...
    'iqrom', nan,...
    'minom', nan,...
    'maxom', nan,...
    'nnan', nan);

for ii=1:ngroup
    this_cidx = cid_lut(gset(ii).entry);
    this_cidx = this_cidx(~isnan(this_cidx));
    this_ridx = rid_lut(gset(ii).entry);
    this_ridx = this_ridx(~isnan(this_ridx));
    if ~isempty(this_cidx) && ~isempty(this_ridx)
        
        this_ds = ds_slice(ds, 'cidx', this_cidx,...
            'ridx', this_ridx,...
            'ignore_missing', true);
        x = this_ds.mat;
        x(1:size(x,1)+1:end) = nan;
        m = nanmedian(x);
        mom = nanmedian(m);
        iqrom = iqr(m);
        rpt(ii).mom = mom;
        rpt(ii).iqrom = iqrom;
        rpt(ii).minom = nanmin(m);
        rpt(ii).maxom = nanmax(m);
        rpt(ii).nnan = nnz(isnan(m));
    else
        dbg(1, '%d/%d %s empty matrix, skipping', ii, ngroup, rpt(ii).gp_id);
    end
end

end