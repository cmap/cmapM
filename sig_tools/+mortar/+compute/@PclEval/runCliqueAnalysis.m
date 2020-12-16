function [rpt, mu, sigma,p25,p75, gpset, agg_path] = runCliqueAnalysis(ds_path, args, wkdir, prefix, row_meta, col_meta)
% Run clique analysis and generate reports.
close all
agg_path = [];

if iscell(ds_path)
    ds_path = ds_path{1};
    assert(ischar(ds_path), 'ds_path must be char');
end
[rankpt_ds, gpset] = mortar.compute.PclEval.computeSelfMatrices(ds_path, args.pcl, ...
                                         args.match_field, row_meta,...
                                         col_meta, prefix);
[rpt, sig_rpt] = mortar.compute.PclEval.getConcordanceReport(rankpt_ds, gpset, args.match_field);

outpath = fullfile(wkdir, prefix);
mkdirnotexist(outpath);
if numel(sig_rpt)
    % plots
    mortar.compute.PclEval.plotSummary(rpt, args);
    
    if (args.moa_conn) 
        agg_row_first = ds_aggregate_set(rankpt_ds, gpset, 'fun', 'median', 'match_field', args.match_field);
        agg_col_first = ds_aggregate_set(rankpt_ds, gpset, 'fun', 'median', 'match_field', args.match_field, 'rows_first', false);
        agg_ds = agg_row_first;
        agg_ds.mat = (agg_row_first.mat + agg_col_first.mat)/2;

        switch (args.cluster_method)
            case 'hclust'
                inan = isnan(agg_ds.mat);
                x0 = agg_ds.mat;
                x0(inan) = 0;
                agg_ds.mat = x0;
                agg_ds = hclust(agg_ds, 'make_symmetric', true, 'is_pairwise', true);
            case 'median'
                x = agg_ds.mat;
                med_x = median(x);
                [~, ord] = sort(med_x, 'descend');
                agg_ds = ds_order(agg_ds, 'column', ord);
                agg_ds = ds_order(agg_ds, 'row', ord);
            otherwise
                error ('Invalid cluster method:%s', cluster_method);
        end   
     
        agg_path = mkgctx(fullfile(outpath, [prefix '_moa_conn.gct']), agg_ds);
    
        fig_path = mkheatmap(agg_path, agg_path, ...
            'color_scheme', 'rankpoint_95');
    else
       fig_path = {}; 
    end
    
    if args.make_heatmap
        mortar.compute.PclEval.plotPWMatrix(rpt, args.cluster_method, args)
    end 

    if args.make_jellyfish
        mortar.compute.PclEval.plotJellyfish(rankpt_ds, gpset, args, wkdir, prefix);      
    end
    
    % save data
    mortar.compute.PclEval.save_data(outpath, rankpt_ds, rpt, sig_rpt, ...
        args.figure_format, 'add_figs', fig_path);  

end



mu = mkgctstruct([rpt.median_rankpt]', 'rid', {rpt.group_id}', ...
    'cid', {prefix});
sigma = mkgctstruct([rpt.iqr_rankpt]', 'rid', {rpt.group_id}', ...
    'cid', {prefix});
p25 = mkgctstruct([rpt.q25_rankpt]', 'rid', {rpt.group_id}', ...
    'cid', {prefix});
p75 = mkgctstruct([rpt.q75_rankpt]', 'rid', {rpt.group_id}', ...
    'cid', {prefix});
end
