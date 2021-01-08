function fix_ds_feature_id(in_path, out_path)
% fix_ds_feature_id Fix the feature ids for legacy Prism datasets
% FIX_DS_FEATURE_ID(IN_PATH, OUT_PATH) Changes the feature-ids of all GCT(x) 
% files in IN_PATH and wrties the modified files to OUT_PATH
[fn , fp] = find_file(fullfile(in_path, '*.gct*'));
nf = length(fn);
feature_tbl = parse_record('/cmap/data/vdb/merino/cell_set_definitions/PRISM_PR500.CS5_definition.txt', 'detect_numeric', false);
feature_lut = mortar.containers.Dict({feature_tbl.feature_id}');
%% rename row ids with 'c-' prefix
for ii=1:nf
    ds = parse_gctx(fp{ii});
    new_rid = strcat('c-', strrep(ds.rid', 'c-', ''));
    ds = ds_change_id(ds, 'row', new_rid, 'old_id');
    is_valid_feature = feature_lut.isKey(ds.rid);
    assert(all(is_valid_feature), 'Invalid features');
    mkgctx(fullfile(out_path, fn{ii}), ds_strip_meta(ds))
end
end