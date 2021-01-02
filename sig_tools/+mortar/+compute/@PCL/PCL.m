classdef PCL
% Algorithms for Perturbational class analysis

    methods(Static=true)

       %==PCL scoring methods
       % BEGIN NOTE: these methods are deprecated
       [ds, pcl, pcl_info] = getData(args);
       rpt = computePCLScores(ds, pcl, pcl_info);
       saveResult(res, out_path);       
       rpt = runPCLAnalysis(varargin);
       % END NOTE
       
       % PCL analysis against touchstone
        res = runPCLTouchstone(varargin);
        saveTouchstoneResult(res, out_path);

       %==PCL validation methods
       
       % Random set generation
       gmt = genSizeMatchedRandomSet(full_space, set_size, n_rep);
       % Compute percentile lookup table for permuted sets
       rnd_ns2ps = permutationPercentileTransform(ns,...
                        set_size,...
                        pcl_field,...
                        n_perm,...
                        aggregate_method,...
                        aggregate_param);
       % Lookup p-value for observed PCL scores based on permuted sets
       pval_ds = permutationPValue(ns_pcl, rnd_ns2ps);                    
       
    end % Static methods block
       
end
