function ds = ds_mask_group(ds, group_field, mask_val, invert)
% DS_MASK_GROUP Mask portions of a dataset
% M = DS_MASK_GROUP(D, G, V, TF) given a list of meta-data fields G for
% dataset D, applies mask value V to portions of the matrix where the 
% grouped meta-data values for rows and columns dont match if TF is true.
% If TF is false elements where the meta-data groups match are set to V.

[~, row_gp, row_gpi] = get_groupvar(ds.rdesc, ds.rhd, group_field);
[~, col_gp, col_gpi] = get_groupvar(ds.cdesc, ds.chd, group_field);

row_gpi_lut = mortar.containers.Dict(row_gp);
col_gpi_matched = row_gpi_lut(col_gp(col_gpi));
[nr, nc] = size(ds.mat);
irow = row_gpi(:, ones(1, nc));
icol = col_gpi_matched(:, ones(1, nr))';
if invert
    ds.mat(irow ~= icol) = mask_val;
else
    ds.mat(irow == icol) = mask_val;
end

end