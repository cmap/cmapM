function rpt = compareClassSimilarity(ds_sim, tbl, cid_field, group_field, class_field, pos_class)

[gpv, gpn, gpi] = get_groupvar(tbl, [], group_field);
[class_gpv, class_gpn, class_gpi] = get_groupvar(tbl, [], class_field);

cid = {tbl.(cid_field)}';
num_group = length(gpn);

is_pos_class = class_gpi == find(strcmp(class_gpn, pos_class));

rpt = struct(group_field, gpn);

pos_sim = nan(num_group, 1);
neg_sim = nan(num_group, 1);
inter_sim = nan(num_group, 1);

parfor ii=1:num_group
    dbg(1, '%d/%d %s', ii, num_group, gpn{ii});
    this_group = gpi == ii;
    this_cid = cid(this_group);
    this_pos = is_pos_class & this_group;
    this_neg = ~is_pos_class & this_group;
    ds_this_sim = parse_gctx(ds_sim, 'cid', this_cid, 'rid', this_cid);
    % pos similarity
    ds_this_sim_pos = ds_slice(ds_this_sim, 'cid', cid(this_pos), 'rid', cid(this_pos));
    % neg similarity
    ds_this_sim_neg = ds_slice(ds_this_sim, 'cid', cid(this_neg), 'rid', cid(this_neg));
    % pos vs neg similarity
    ds_this_sim_inter = ds_slice(ds_this_sim, 'cid', cid(this_pos), 'rid', cid(this_neg));
    pos_sim(ii) = nanmedian(nanmedian(set_diagonal(ds_this_sim_pos.mat, nan)));
    neg_sim(ii) = nanmedian(nanmedian(set_diagonal(ds_this_sim_neg.mat, nan)));
    inter_sim(ii) = nanmedian(nanmedian(ds_this_sim_inter.mat));
end

rpt = setarrayfield(rpt, [], {'pos_sim', 'neg_sim', 'inter_sim'},...
        pos_sim, neg_sim, inter_sim);

end
