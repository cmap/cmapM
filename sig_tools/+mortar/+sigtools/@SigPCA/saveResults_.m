function saveResults_(obj, out_path)
required_fields = {'args', 'pc_coeff', 'pc_score',...
    'pc_var', 'pct_explained', 'col_mean'};

res = obj.getResults;                
ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end
args = obj.getArgs;

% save results
gctwriter = @mkgctx;
gctwriter(fullfile(out_path, 'pc_coeff.gctx'), res.pc_coeff);
gctwriter(fullfile(out_path, 'pc_score.gctx'), res.pc_score);
gctwriter(fullfile(out_path, 'pc_var.gctx'), res.pc_var);
gctwriter(fullfile(out_path, 'pct_explained.gctx'), res.pct_explained);
gctwriter(fullfile(out_path, 'col_mean.gctx'), res.col_mean);

if ~args.disable_table
    first2_tbl = gct2tbl(ds_slice(res.pc_score, 'cid', res.pc_score.cid(1:2)));
    mktbl(fullfile(out_path ,'pca.txt'), first2_tbl);
end

% make plots
[hf1,hf2,hf3] = plot_pca(res.pc_score.mat, res.pc_var.mat, 'showfig', false);
savefigures('out', out_path, 'mkdir', false, 'closefig', true, 'include', [hf1,hf2,hf3]);
