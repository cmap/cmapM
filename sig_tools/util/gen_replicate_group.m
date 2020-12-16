function gb_id = gen_replicate_group(tbl, gp_fields, nrep)
% GEN_REPLICATE_GROUP Generate grouping variable of replicates
%   gb_id = gen_replicate_group(tbl, gp_fields, nrep)

[gpv, gpn, gpi, ~, gpsz] = get_groupvar(tbl, [], gp_fields);
n_gp = length(gpn);
% handle groups with more than nrep reps
has_many_reps = find(gpsz>nrep);
n_many = length(has_many_reps);
gb_id = gpv;

dbg(1, '%d/%d groups have more than %d replicates', n_many, n_gp, nrep);

for ii=1:n_many
    this_gp_idx = has_many_reps(ii);
    dbg(1, '%s, nrep:%d', gpn{this_gp_idx}, gpsz(this_gp_idx))
    this = gpi == this_gp_idx;
    this_idx = find(this);
    nthis = nnz(this);
    pad_size = ceil(nthis/nrep)*nrep;
    n_to_pad = pad_size - nthis;
    
    this_idx_pad = [this_idx; nan(n_to_pad, 1)];
    rand_idx = randsample(this_idx_pad, pad_size);
    to_keep = ~isnan(rand_idx);
    
    gp_num = mod((1:pad_size)'-1, pad_size/nrep)+1;    
    gp_name = strcat(gpv(rand_idx(to_keep)),':', num2cellstr(gp_num(to_keep)));
    gb_id(rand_idx(to_keep)) = gp_name;
end

end