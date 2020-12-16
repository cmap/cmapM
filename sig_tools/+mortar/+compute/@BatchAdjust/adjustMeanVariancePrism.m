function adj_ds = adjustMeanVariancePrism(ds, col_group, row_group, col_gp_as_batch, method)
% adjustMeanVariancePrism Apply Mean-variance standardization to PRISM data
% adj_ds = adjustMeanVariancePrism(ds, col_group, row_group, col_gp_as_batch)

% cell x treatments
ds = parse_gctx(ds);

isk_row = ds.rdict.isKey(row_group);
isk_col = ds.cdict.isKey(col_group);

assert(all(isk_row), '%d/%d Row grouping variables not found in metadata',...
        length(row_group), nnz(~isk_row));
assert(all(isk_col), '%d/%d Column grouping variables not found in metadata',...
        length(col_group), nnz(~isk_col));
    
% column grouping
[col_gpv, col_gpn, col_gpi, ~, col_gpsz] = get_groupvar(ds.cdesc, ds.chd, col_group);
ncol_gp = length(col_gpn);

% row grouping
[row_gpv, row_gpn, row_gpi, ~, row_gpsz] = get_groupvar(ds.rdesc, ds.rhd, row_group);
nrow_gp = length(row_gpn);

adj_ds = ds;
nrow_ds = size(ds.mat, 1);

dbg(1, '%d Column groups and %d Row groups found', ncol_gp, nrow_gp);
if col_gp_as_batch
    dbg(1, 'Apply adjustments, with %d batches and treating members within a column group as separate batches', nrow_gp);
else
    dbg(1, 'Apply adjustments, using %d batches', nrow_gp);
end

for ii=1:ncol_gp
    this_gp = col_gpi == ii;
    n_this_gp = nnz(this_gp);
    x = ds.mat(:, this_gp);
    batch_matrix = row_gpi * ones(1, n_this_gp);    
    if col_gp_as_batch
       % consider each column as a separate batch
       offset = ones(nrow_ds, 1) * (0:n_this_gp-1) * nrow_gp;
       batch_matrix = batch_matrix + offset;
    end
    x_long = x(:);
    batch_long = batch_matrix(:);
    is_not_nan = ~isnan(x);
    
    y_long = nan(size(x));
    y_long(is_not_nan) = mortar.compute.BatchAdjust.adjustMeanVariance(x_long(is_not_nan), batch_long(is_not_nan), method);
    y = reshape(y_long, nrow_ds, n_this_gp);
    adj_ds.mat(:, this_gp) = y;
    if isequal(mod(ii, 500), 1)
        dbg(1, '%d/%d %s %d batches %d reps',...
            ii, ncol_gp, col_gpn{ii},...
            length(unique(batch_long)), n_this_gp);
    end
end

end