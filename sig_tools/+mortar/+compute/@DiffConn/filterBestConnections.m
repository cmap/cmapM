function ds_filt = filterBestConnections(ds, row_metric_field, ps_th, min_rows_to_pass)
% filterBestConnections Select best connections for each unique pert_id
% ds_filt = filterBestConnections(ds, row_metric_field, ps_th, min_rows_to_pass)
% group by pert_id
% if nhit>=min_rows, keep all rows that pass
% else keep top min_rows
verbose = false;
row_meta = gctmeta(ds, 'row');
% connectivity in the positive class
pos_q = [row_meta.(row_metric_field)]';

% group by pert_id
[pid_gp, pid_idx] = getcls({row_meta.pert_id}');
[~, uidx] = unique(pid_idx, 'stable');
ngp = length(pid_gp);

nrow = length(row_meta);
is_cnx = false(nrow, 1);

is_high_pos_q = pos_q >= ps_th;
is_low_pos_q = pos_q <= -ps_th;

dbg(1, 'Processing %d pert_id groups', ngp);
for ii=1:ngp
    this = pid_idx == ii;
    % positive connections
    is_this_high_pos_q = is_high_pos_q & this;
    % negative connections
    is_this_low_pos_q = is_low_pos_q & this;
    n_high_pos_q = nnz(is_this_high_pos_q);
    n_low_pos_q = nnz(is_this_low_pos_q);
    
    if n_high_pos_q >= n_low_pos_q && n_high_pos_q >= min_rows_to_pass
        % positive connection
        is_cnx = is_cnx | is_this_high_pos_q;
    elseif n_low_pos_q >= min_rows_to_pass
        % negative connection
        is_cnx = is_cnx | is_this_low_pos_q;
    else
        % not significant connection
        this_pos_q = pos_q(this);
        num_pos = nansum(this_pos_q > 0);        
        num_neg = nansum(this_pos_q < 0);
        is_pos_majority = num_pos >= num_neg;
        [~, ord] = sort(this_pos_q * sign(is_pos_majority-0.5), 'descend');
        this_idx = find(this);
        is_cnx(this_idx(ord(1:min(length(ord), min_rows_to_pass)))) = true;        
    end
end

% metadata filtered for connections
row_meta_cnx = row_meta(is_cnx);

ds_filt = ds_slice(ds, 'ridx', is_cnx);
ds_filt = annotate_ds(ds_filt, row_meta_cnx, 'dim', 'row');

% order rows by row_metric field
[~, row_order] = sort(ds_get_meta(ds_filt, 'row', row_metric_field), 'descend');
ds_filt = ds_slice(ds_filt, 'ridx', row_order);

end