function [outds, row_meta_orig, col_meta_orig] = castDSToLong(ds, row_field, col_field)

    [nr, nc] = size(ds.mat);
    if ischar(row_field)
        row_field = {row_field};
    end
    if ischar(col_field)
        col_field = {col_field};
    end
    % row groups
    [row_id, row_gp, irow_gp] = get_groupvar(ds.cdesc, ds.chd, row_field);
    nrow = length(row_gp);
    
    % column groups
    [col_id, col_gp, icol_gp] = get_groupvar(ds.cdesc, ds.chd, ...
                                                       col_field, ...
                                                       'no_space', ...
                                                       true, 'case', ...
                                                       '');
%     [ocell_id, iord] = orderas(col_gp, 'summly');
    ncol = numel(col_gp);

%     assert(isempty(intersect(row_field, col_field)), 'shared field between row and columns not allowed')
%     all_id = get_groupvar(ds.rdesc, ds.rhd, union(row_field, col_field));    
%     assert(isempty(duplicates(all_id)), 'duplicates found in row:col field groups')
    
    row_gp2idx = mortar.containers.Dict(row_gp);
    outmat = nan(nrow*nr, ncol);
    
    % matrix of row indices to target matrix
    ridx_mat = bsxfun(@plus, (1:nr)', nr*(0:nrow));
    
    for ii=1:ncol
        this_col = icol_gp == ii;
        ridx = ridx_mat(:, row_gp2idx(row_id(this_col)));
        ridx = ridx(:);
        x = ds.mat(:, this_col);
        outmat(ridx, ii) = x(:);
    end
    
    row_gp_meta = repmat(row_gp', nr, 1);        
    rid_only = repmat(ds.rid, 1, nrow);    
    rid = strcat(rid_only, ':', row_gp_meta);
    rid = rid(:);
    rid_only = rid_only(:);
    row_gp_meta = row_gp_meta(:);
    outds = mkgctstruct(outmat, 'rid', rid, 'cid', col_gp);

    % row meta
    row_meta_orig = gctmeta(ds, 'row');
    row_meta = row_meta_orig;
    idx = repmat((1:nr)', 1, nrow);
    row_meta = row_meta(idx(:));
    [row_meta.rid] = rid{:};
    row_fn = validvar(print_dlm_line(row_field,'dlm','_'), '_');
    [row_meta.(row_fn{1})] = row_gp_meta{:};

    % retain original metadata
    col_meta_orig = gctmeta(ds, 'column');
    % add a match_group field with column grouping
    [col_meta_orig.match_group] = col_id{:};
    % drop row_field from column annotations
    col_meta = keepfield(col_meta_orig,...
                setdiff(fieldnames(col_meta_orig), row_field, 'stable'));
    [~, uicid] = unique(icol_gp, 'stable');
    col_meta = col_meta(uicid);
    col_meta = mvfield(col_meta, 'match_group', 'cid');
    %cid = col_id(uicid);
    %[col_meta.cid] = cid{:};
    outds = annotate_ds(outds, col_meta, 'dim', 'column', 'keyfield', 'cid');
    outds = annotate_ds(outds, row_meta, 'dim', 'row', 'keyfield', 'rid');
    outds = ds_delete_missing(outds);        
end
