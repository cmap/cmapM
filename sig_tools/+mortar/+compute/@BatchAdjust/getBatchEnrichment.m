function batch_res = getBatchEnrichment(ds, dim, batch)
% Compute enrichment of a batch variable
% RES = getBatchEnrichment(DS, DIM, BATCH) Computes enrichment of BATCH in
% in dataset DS along dimension DIM

ds = parse_gctx(ds);
[dim_str, dim_val] = get_dim2d(dim);

switch(dim_str)
    case 'column'
        meta = gctmeta(ds);
        batch_set = tbl2gmt(meta, 'group_field', batch,...
                        'desc_field', batch, 'member_field', 'cid');
        ds = transpose_gct(ds);
    case 'row'
        meta = gctmeta(ds, 'row');
        batch_set = tbl2gmt(meta, 'group_field', batch,...
                        'desc_field', batch, 'member_field', 'rid');        
end
ds_rnk = score2rank(ds, 'direc', 'descend');
res = mortar.compute.Connectivity.runCmapQuery('up', batch_set, 'dn', [],...
    'score', ds, 'rank', ds_rnk, 'es_tail', 'up', 'metric', 'wtcs');

batch_res = res.cs;

end