function splitIntrospectForPCL(ps, col_meta, split_by, unique_by, out_path)
% splitIntrospectForPCL Format introspect matrix for sig_pcleval
mkdirnotexist(out_path);
ps_annot = parse_gctx(ps, 'annot_only', true);

if ~isempty(col_meta)
    col_meta = parse_record(col_meta);
    fn = fieldnames(col_meta);
    if ~isfield(col_meta, 'cid')
        keyfield = fn{1};
    else
        keyfield = 'cid';
    end
    ps_annot = ds_slice(ps_annot, 'cid', {col_meta.(keyfield)}');
    ps_annot = annotate_ds(ps_annot, col_meta, 'keyfield', keyfield);
    col_meta = gctmeta(ps_annot);
else
    col_meta = gctmeta(ps_annot);
end
assert(all(isfield(col_meta, unique_by)), 'unique_by field %s missing from metadata', unique_by);
[gpv, gpn, gpi] = get_groupvar(col_meta, [], split_by, 'dlm','-','no_space', true,'case','upper');
ngp = length(gpn);
ncol = length(col_meta);
mkdirnotexist(out_path);
jmktbl(fullfile(out_path, sprintf('col_meta_n%d.txt', ncol)), col_meta);
jmktbl(fullfile(out_path, sprintf('row_meta_n%d.txt', ncol)), col_meta);

for ii=1:ngp
    this_gp = gpi == ii;
    this_meta = col_meta(this_gp);
    % note enforce one unique pert_id
    [~, uidx] = unique({this_meta.(unique_by)}');
    cid = {this_meta(uidx).cid}';
    this_ps = parse_gctx(ps, 'cid', cid, 'rid', cid);
    %this_ps = ds_slice(ps, 'cidx', this_gp, 'ridx', this_gp);
    out_file = fullfile(out_path, sprintf('ps_%s.gctx', gpn{ii}));
    mkgctx(out_file, ds_strip_meta(this_ps));
end


end