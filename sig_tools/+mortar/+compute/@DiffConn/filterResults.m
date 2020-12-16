function ds_filt = filterResults(ds, ps_th, min_rows_to_pass)
% Filter significant diffconn results
verbose = false;
row_meta = gctmeta(ds, 'row');
% connectivity in the positive class
pos_q = [row_meta.pos_q]';
d_gain = [row_meta.d_gain]';

% group by pert_id
[pid_gp, pid_idx] = getcls({row_meta.pert_id}');
[~, uidx] = unique(pid_idx, 'stable');
ngp = length(pid_gp);
pid_rpt = keepfield(row_meta(uidx), {'pert_id', 'pert_iname'});
% group sizes
num_agg = accumarray(pid_idx, ones(size(pid_idx)));
% aggregate positive class score
posq_agg = zeros(ngp, 1);
% aggregate diff gain score
dgain_agg = zeros(ngp, 1);

% PS threshold for passing a row
%ps_th = 90;
% minimum number of rows in a group required to pass filter
%min_rows_to_pass = 3;

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
        posq_agg(ii) = q75(pos_q(is_this_high_pos_q));
        dgain_agg(ii) = q75(d_gain(is_this_high_pos_q));
        is_cnx = is_cnx | is_this_high_pos_q;
        dbg(verbose, '%d / %d, %s gpsz:%d nhi: %d, nlow:%d, pos_agg:%2.2f',...
            ii, ngp, pid_gp{ii}, num_agg(ii), n_high_pos_q, n_low_pos_q,...
            posq_agg(ii));
    elseif n_low_pos_q >= min_rows_to_pass
        posq_agg(ii) = q25(pos_q(is_this_low_pos_q));
        dgain_agg(ii) = q75(d_gain(is_this_low_pos_q));
        is_cnx = is_cnx | is_this_low_pos_q;
        dbg(verbose, '%d / %d, %s gpsz:%d nhi: %d, nlow:%d, pos_agg:%2.2f',...
            ii, ngp, pid_gp{ii}, num_agg(ii), n_high_pos_q, n_low_pos_q,...
            posq_agg(ii));
    end
end

% metadata filtered for connections
row_meta_cnx = row_meta(is_cnx);

pid_rpt = setarrayfield(pid_rpt, [], {'num_agg', 'posq_agg', 'dgain_agg'},...
            num_agg, posq_agg, dgain_agg);
row_meta_cnx = join_table(row_meta_cnx, pid_rpt, 'pert_id', 'pert_id');

% hit frequency stats
[~, pint_gp, pint_gp_idx, ~, pint_gpsz_all] = get_groupvar(row_meta, [], {'pert_iname', 'pert_type'});
[num_expt, num_cnx] = grpstats(is_cnx, pint_gp_idx, {@numel, @sum});
% fraction of profiles (expts) per name-type that are connected
frac_hit = num_cnx ./ num_expt;
cnx_idx = pint_gp_idx(is_cnx);
row_meta_cnx = setarrayfield(row_meta_cnx, [],...
            {'num_expt', 'num_cnx', 'frac_cnx'},...
            num_expt(cnx_idx), num_cnx(cnx_idx), frac_hit(cnx_idx));

% frequency of types per unique pert_iname
[pin_idx, pin_name] = grp2idx({row_meta.pert_iname}');
pert_type = {row_meta.pert_type}';
pert_type_idx = grp2idx(pert_type);
num_pert_type = grpstats(pert_type_idx, pin_idx, @(x) length(unique(x)));
num_pert_type_cnx = grpstats(pert_type_idx .* is_cnx, pin_idx, @(x) length(unique(x(x>0))));
is_multi_type_cnx = num_pert_type>1 & num_pert_type_cnx>1;
cnx_idx2 = pin_idx(is_cnx);
row_meta_cnx = setarrayfield(row_meta_cnx, [],...
            {'num_pert_type_cnx', 'is_multi_type_cnx'},...
            num_pert_type_cnx(cnx_idx2), is_multi_type_cnx(cnx_idx2));

ds_filt = ds_slice(ds, 'ridx', is_cnx);
ds_filt = annotate_ds(ds_filt, row_meta_cnx, 'dim', 'row');

% order rows by d_gain
[~, row_order] = sort(ds_get_meta(ds_filt, 'row', 'd_gain'), 'descend');
ds_filt = ds_slice(ds_filt, 'ridx', row_order);


end