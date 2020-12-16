function genPCLEvalInputs(ps_file, row_meta, gp_fn, out_path)
% Generate inputs for PCL Eval tools
row_meta = parse_record(row_meta);
col_meta = row_meta;
%%
ps_all = parse_gctx(ps_file);
% order rows and columns identically
ps_all = ds_slice(ps_all, 'rid',  ps_all.cid);

ps_all = annotate_ds(ps_all, col_meta);
ps_all = annotate_ds(ps_all, row_meta, 'dim', 'row');
pert_id = ds_get_meta(ps_all, 'column', 'pert_id');

[gpv, gpn, gpi] = get_groupvar(gctmeta(ps_all), [], gp_fn, 'dlm', '.');
ngp = length(gpn);

if ~isdirexist(out_path)
    mkdir(out_path)
end
jmktbl(fullfile(out_path, sprintf('row_meta_n%d.txt', numel(row_meta))),...
    row_meta);
jmktbl(fullfile(out_path, sprintf('col_meta_n%d.txt', numel(col_meta))),...
    col_meta);
for ii=1:ngp
    dbg(1, '%d/%d %s', ii, ngp, gpn{ii});
    this_gp = gpi == ii;
    [dup,idup]=duplicates(pert_id(this_gp));
    if ~isempty(dup)
        disp(dup);
        error('Duplicate pert_ids found in group %s', gpn{ii});
    end
    this_ps = ds_slice(ps_all, 'cidx', this_gp, 'ridx', this_gp);
    this_ps = ds_make_symmetric(this_ps, 'mean', nan);
    [~, out_file] = validate_fname(sprintf('ps_%s.gctx', upper(gpn{ii})), '.');
    outfile = fullfile(out_path, out_file);
    mkgctx(outfile, this_ps);
end

end