function dstornk(ds, out_path)
% DSTORNK Convert dataset to GSEA rnk files
% DSTORNK(DS, OUT_PATH)

ds = parse_gctx(ds);

nc = length(ds.cid);

mkdirnotexist(out_path);
index = gctmeta(ds);

for ii=1:nc

    this_rnk = struct('rid', ds.rid,...
           'score', num2cell(ds.mat(:, ii)));
    [~, fn]=validate_fname(ds.cid{ii}, '_');
    this_file = fullfile(out_path, sprintf('%s.rnk', fn));
    mktbl(this_file, this_rnk, 'noheader', true);
    index = setarrayfield(index, ii, 'rnk_file', this_file);    
end

jmktbl(fullfile(out_path, 'index.txt'), index);
end