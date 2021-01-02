function outds = castDSToWide(ds, row_field, col_field)

    [nrow, ncol] = size(ds.mat);
    if ischar(row_field)
        row_field = {row_field};
    end
    if ischar(col_field)
        col_field = {col_field};
    end
    % row groups
    [row_id, row_gp, irow_gp] = get_groupvar(ds.rdesc, ds.rhd, row_field);
    npert = length(row_gp);
    
    % column groups
    [col_id, col_gp, icol_gp] = get_groupvar(ds.rdesc, ds.rhd, col_field);
    [ocell_id, iord] = orderas(col_gp, 'summly');
    ncell = numel(ocell_id);

    assert(isempty(intersect(row_field, col_field)), 'shared field between row and columns not allowed')
    all_id = get_groupvar(ds.rdesc, ds.rhd, union(row_field, col_field));    
    assert(isempty(duplicates(all_id)), 'duplicates found in row:col field groups')
    
    pid2idx = mortar.containers.Dict(row_gp);
    outmat = nan(npert, ncell*ncol);

    for ii=1:ncell
        this_cell = icol_gp == iord(ii);
        cidx = ii:ncell:ncol*ncell;
        ridx = pid2idx(row_id(this_cell));
        outmat(ridx, cidx) = ds.mat(this_cell, :);
    end
    res_col = repmat(col_gp, 1, ncol);
    cid_only = repmat(ds.cid', ncell, 1);    
    cid = strcat(cid_only, ':', res_col);
    cid = cid(:);
    cid_only = cid_only(:);
    outds = mkgctstruct(outmat, 'rid', row_gp, 'cid', cid);

    col_meta = gctmeta(ds, 'column');
    cfn = fieldnames(col_meta);
    cmeta_exists = ismember(cfn, col_field);
    col_field_name = col_field{1};
    if any(cmeta_exists)
	col_field_name = ['dup_', col_field_name];
    end
    idx = repmat(1:length(col_meta), ncell, 1);
    col_meta = col_meta(idx(:));
    [col_meta.cid] = cid{:};
    [col_meta.query_cid] = cid_only{:};
    [col_meta.(col_field_name)] = res_col{:};

    % drop col_field from row annotations
    row_meta = keepfield(gctmeta(ds, 'row'),...
                setdiff(ds.rhd, col_field, 'stable'));
    [~, uipid] = unique(irow_gp, 'stable');
    row_meta = row_meta(uipid);
    rid = row_id(uipid);
    [row_meta.rid] = rid{:};
    outds = annotate_ds(outds, col_meta, 'dim', 'column', 'keyfield', 'cid');
    outds = annotate_ds(outds, row_meta, 'dim', 'row', 'keyfield', 'rid');
    outds = ds_delete_missing(outds);        
end
