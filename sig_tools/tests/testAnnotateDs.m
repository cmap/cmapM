% test annotate_ds 
% from morzech
% I am trying to annotate a gct file and I noticed that annotate_ds gives
% different results for missing values in rows and in columns (missing
% values in rows are represented as empty cells and in rows they have
% values set with the ?missingval? option). It doesn?t look like an
% intentional functionality to me.

ds = mkgctstruct(magic(6), 'rid', gen_labels(6), 'cid', gen_labels(6));

meta = struct('id', gen_labels(5), 'field1', 'X', 'field2', num2cell(rand(5,1)));

ds = annotate_ds(ds, meta, 'dim', 'row', 'skipmissing', true, 'missingval', '-666');
ds = annotate_ds(ds, meta, 'dim', 'column', 'skipmissing', true,'missingval', '-666');


rmeta = struct2cell(gctmeta(ds, 'row'))';
cmeta = struct2cell(gctmeta(ds, 'column'))';

disp(rmeta)
disp(cmeta)