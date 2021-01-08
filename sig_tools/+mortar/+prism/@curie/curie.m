classdef curie
    % Methods to compute connectivities using relative inhibition
    % public properties
    properties (Constant=true)
        
    end
    
    methods (Static=true)
        % run query on viability profiles
        qres = runCurie(varargin);
        % save curie result
        saveCurieResult(qres, outpath, use_gctx, skip_key_as_text);     
        % get pre-canned dataset
        ds_rec = getDataset(dataset_source, dataset_id);
        % Convert curie scores to ranks
        rnk = rankCurieScore(ncs, dim)
        
        % get cell set
        [gmt, ds, rpt] = getCellSets(varargin);
        % cell set stats
        [rpt, freq_ds, ov_ds] = getCellSetStats(gmt);
        h = plotCellSetStats(gmt, varargin);
        
        ds_auc = transformAUC(ds_auc, transform);
        
        % deduplicate cell sets
        [uniq_gmt, set_rpt, ds_ov] = findUniqueSets(gmt, thresh, metric);
        
        % Transform NCS to percentiles
        ps = ncsToPercentile(ncs_mat);
        ps = absNcsToPercentile(ncs_mat);
        
        nb_rpt = getIntrospectNeighbors(cc_ds, index_tbl, sim_th);
    end
    
end