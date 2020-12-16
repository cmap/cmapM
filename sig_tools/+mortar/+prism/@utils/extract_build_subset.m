function [sig_metrics, inst_info, l5_ds, l4_ds] = extract_build_subset(build_path, sig_id_list, norm_type)

sig_id_field = 'sig_id';
inst_id_field = 'profile_ids';
sig_id = parse_grp(sig_id_list);
nsig = length(sig_id);

[~, sig_metrics_file] = find_file(fullfile(build_path, sprintf('*_sig_metrics_MODZ.%s.COMBAT.txt', norm_type)));
[~, l5_file] = find_file(fullfile(build_path, sprintf('*_LEVEL5_MODZ.%s.COMBAT_n*.gctx', norm_type)));
[~, l4_file] = find_file(fullfile(build_path, sprintf('*_LEVEL4_%s.COMBAT_n*.gctx', norm_type)));
[~, inst_info_file] = find_file(fullfile(build_path, '*_inst_info.txt'));

assert(~isempty(sig_metrics_file), 'Sig metrics file not found');
assert(~isempty(l5_file), 'Leve5 matrix not found');
assert(~isempty(l4_file), 'Level4 matrix file not found');

% subset sig metrics
sig_metrics_all = parse_record(sig_metrics_file{1}, 'detect_numeric', false);
inst_info_all = parse_record(inst_info_file{1}, 'detect_numeric', false);

[sig_id_cmn, ~, sig_idx]  = intersect(sig_id, {sig_metrics_all.(sig_id_field)}', 'stable');
nsig_found = length(sig_id_cmn);
if ~isequal(nsig, nsig_found)
    warning('%d/%d signatures found ignoring %d', nsig_found, nsig, nsig-nsig_found);    
end
sig_metrics = sig_metrics_all(sig_idx);

% subset inst info
inst_ids = tokenize({sig_metrics.(inst_id_field)}', ',');
inst_ids_long = cat(1, inst_ids{:});
ninst = length(inst_ids_long);
[inst_id_cmn, ~, inst_idx]  = intersect(inst_ids_long, {inst_info_all.profile_id}', 'stable');
ninst_found = length(inst_id_cmn);
if ~isequal(ninst, ninst_found)
    error('%d/%d profile ids found. Not found %d', ninst_found, ninst, ninst-ninst_found);    
end
inst_info = inst_info_all(inst_idx);

% subset datasets
l5_ds = parse_gctx(l5_file{1}, 'cid', sig_id_cmn);
l4_ds = parse_gctx(l4_file{1}, 'cid', inst_id_cmn);

end