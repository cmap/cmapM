function rpt = lookupCpAnnotByPertId(pid_list, refresh_cache)
% lookupCpAnnotByPertId Get annotations for a list of perturbagen ids
% RPT = lookupCpAnnotByPertId(PID_LIST)

if isequal(nargin, 2)
    do_refresh = refresh_cache;
else
    do_refresh = false;
end

pid_list = parse_grp(pid_list);

rpt = struct('pert_id', pid_list);

cp_db_tbl = mortar.common.Annot.getCpTable(do_refresh);
moa_tbl = mortar.common.Annot.getMoaTable(do_refresh);
tgt_tbl = mortar.common.Annot.getTargetTable(do_refresh);

rpt = join_table(rpt, cp_db_tbl, 'pert_id', 'pert_id');
rpt = tbl_fill_missing_value(rpt, '-666');
rpt = join_table(rpt, moa_tbl, 'pert_id', 'pert_id');
rpt = join_table(rpt, tgt_tbl, 'pert_iname', 'pert_iname');
rpt = tbl_fill_missing_value(rpt, '-666');

end