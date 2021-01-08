function res = processPlate(lxb_path, out_path, row_meta_file, col_meta_file)

% read annotations
row_meta = parse_record(row_meta_file);
col_meta = parse_record(col_meta_file);

% run dpeak
[pkstats, fn] = mortar.prism.dpeak.dpeakFolder(lxb_path);

% assign peaks
ds = mortar.prism.dpeak.assignPeaks(pkstats);

save(fullfile(out_path, 'pkstats.mat'), 'pkstats');
%mkgctx(fullfile(out_path, 'dpeak.gctx'), ds)

% create annotated datasets
res = mortar.prism.dpeak.createDataset(pkstats, ds, row_meta, col_meta);

% save datasets
mortar.prism.dpeak.saveDataset(res, out_path);


end