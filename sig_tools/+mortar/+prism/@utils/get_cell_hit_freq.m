function hit_rpt = get_cell_hit_freq(ds, col_group, hit_thresh)
ds = parse_gctx(ds);
[gpv, gpn, gpi] = get_groupvar(ds.cdesc, ds.chd, col_group);
ngp = length(gpn);
row_meta = gctmeta(ds, 'row');
for ii=1:ngp
    this_gp = gpi == ii;
    this_ds = ds_slice(ds, 'cidx', this_gp);
    is_hit = this_ds.mat <= hit_thresh;
    hit_freq = 100*nansum(is_hit, 2) / size(is_hit, 2);
    zs_freq = robust_zscore(hit_freq, 1, 'min_mad', 0.001, 'var_adjustment', 'fixed');
    this_hit_rpt = setarrayfield(row_meta, [], {'col_group', 'hit_freq', 'zs_freq'},...
        gpn{ii}, num2cell(hit_freq), num2cell(zs_freq));
    if (ii>1)
        hit_rpt = [hit_rpt; this_hit_rpt];
    else
        hit_rpt = this_hit_rpt;
    end            
end


end