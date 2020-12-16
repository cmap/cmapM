classdef PclEval
% Algorithms for Perturbational class analysis

    methods(Static=true)
        mat = annotateInterCellMatrix(mat, annot)
        [rankpt_ds, gset] = computeSelfMatrices(lass_path, gset_file, ...
            gp_field, row_meta, col_meta, cell_id)

        [rpt, member_info] = getConcordanceReport(rankpt_ds, gpset, gp_field)

        rpt = runCellAggregate(dspath, meta, pcl, varargin)
        
        makeDistinctIndex(inpath, cell_line, gpset)
        
        makeGlobalSummary(inpath, cell_lines)

        [rpt, sil_gct] = makeSilhouetteReport(ds_path,siginfo_path, gpset, args)
        
        makePCLIndex(inpath, cell_line)

        plotJellyfish(rankpt_ds, gpset, args, wkdir, prefix)
        
        plotPWMatrix(rpt, cluster_method, args)

        plotSummary(rpt, args)

        [rpt, mu, sigma,p25,p75, gpset, agg_path] = runCliqueAnalysis(ds_path, args,...
            wkdir, prefix, row_meta, col_meta)

        runInterCellAnalysis(mu_summly, sigma_summly, wkdir)

        runInterCellAnalysisWithIQR(mu_summly, q25_summly, q75_summly, ...
            wkdir, outfmt,mk_radar)

        save_data(wkdir, rankpt_ds, rpt, sig_rpt, figure_format, varargin)
    end
       
end
