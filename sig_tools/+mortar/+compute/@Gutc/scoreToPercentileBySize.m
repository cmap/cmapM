function [ps, ns] = scoreToPercentileBySize(ncs, ns2ps_lut, dim, query_size, varargin)
% scoreToPercentileBySize Convert normalized connectivity scores to
% percentile scores using size-matched, score to percentile score lookup table.
% ps = scoreToPercentile(ns, ns2ps_lut, dim, query_size, varargin)


assert(isa(ns2ps_lut, 'mortar.containers.Dict'), 'ns2ps lookup should be a dictionary');
[dim_str, dim_val] = get_dim2d(dim);
if isequal(dim_str, 'column')
    id_dim = 'cid';
    id = ncs.cid;
else
    id_dim = 'rid';
    id = ncs.rid;
end

ref_size = cell2mat(ns2ps_lut.keys);
best_set_size = mortar.compute.Gutc.getNearestSetSize(ref_size, query_size);
[size_id, size_gp] = getcls(best_set_size);
nsize = length(size_id);
for ii=1:nsize    
    this_size = size_gp == ii;
    dbg(1, '%d/%d Computing percentiles for %d queries using setsize=%d',...
        ii, nsize, nnz(this_size), size_id(ii));
    this_ns2ps_file = ns2ps_lut(size_id(ii));
    this_ns2ps = parse_gctx(this_ns2ps_file{1});
    this_ncs = ds_slice(ncs, id_dim, id(this_size));
    [this_ps, this_ns] = mortar.compute.Gutc.scoreToPercentile(this_ncs,...
                            this_ns2ps, dim_str);
    if isequal(ii, 1)
        ps = this_ps;
        ns = this_ns;
    else
        ps = merge_two(ps, this_ps);
        ns = merge_two(ns, this_ns);
    end
end
ps = ds_slice(ps, id_dim, id);
ns = ds_slice(ns, id_dim, id);

