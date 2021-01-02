function qval_ds = computeFDRGseaDs(ncs_ds, is_null)
% computeFDRGseaDs compute FDR for each column in NCS dataset
% qval_ds = computeFDRGseaDs(ncs_ds, is_null)

[nr, nc] = size(ncs_ds.mat);
qval_mat = ones(nr, nc);
% FDR adjustments, see computeFDRGsea for details
apply_null_adjust = true;
apply_smooth = true;

for ii=1:nc
    qval_mat(:, ii) = mortar.compute.Gutc.computeFDRGsea(ncs_ds.mat(:, ii), is_null, [], apply_null_adjust, apply_smooth);    
end
qval_ds = mkgctstruct(qval_mat, 'rid', ncs_ds.rid, 'cid', ncs_ds.cid);

end