function pval_ds = permutationPValue(ns_pcl, rnd_ns2ps)
% Lookup p-value for observed PCL scores based on permuted sets
set_size = ds_get_meta(ns_pcl, 'row', 'pcl_size');
[size_gp, size_idx] = getcls(set_size);
n_size = length(size_gp);
[nr, nc] = size(ns_pcl.mat);
pval = nan(nr, nc);
for ii=1:n_size
    ridx = size_idx == ii;
    this = ds_slice(ns_pcl, 'rid', ns_pcl.rid(ridx));
%     cid = this.cid;
    this.cid = strcat(this.cid, ':', num2str(size_gp(ii)));
    ps = mortar.compute.Gutc.scoreToPercentile(this, rnd_ns2ps, 'row');
    pval(ridx,:) = -log10(50 - abs(0.5*ps.mat) +eps);    
end

pval_ds = ns_pcl;
pval_ds.mat = pval;


end
