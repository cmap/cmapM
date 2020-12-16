function rnd_ns2ps = permutationPercentileTransform(ns, set_size, pcl_field, n_perm, aggregate_method, aggregate_param)
% Compute percentile lookup table for permuted sets
univ_space = ds_get_meta(ns, 'row', pcl_field);
rnd_set = mortar.compute.PCL.genSizeMatchedRandomSet(univ_space,...
            set_size, n_perm);
rnd_stat = mortar.compute.Gutc.aggregateSet(...
            ns,...
            [],...
            rnd_set,...
            'column',...
            pcl_field,...
            aggregate_method,...
            aggregate_param);
n_size = numel(set_size);
rnd_size = ds_get_meta(rnd_stat, 'row', 'pcl_size');
for ii=1:n_size
    ridx = abs(rnd_size - set_size(ii)) < eps;
    this = ds_slice(rnd_stat, 'rid', rnd_stat.rid(ridx));
    [ns2ps, stats] = mortar.compute.Gutc.scoreToPercentileTransform(...
                        this, 'column', -4, 4, 10001);
    ns2ps = ds_add_meta(ns2ps, 'row', 'id', num2cell(set_size(ii)));
    ns2ps = ds_add_meta(ns2ps, 'row', 'set_size', num2cell(set_size(ii)));
    ns2ps.rid = strcat(ns2ps.rid,':',num2str(set_size(ii)));
    if isequal(ii, 1)
        rnd_ns2ps = ns2ps;
    else
        rnd_ns2ps = merge_two(rnd_ns2ps, ns2ps);
    end
end
end