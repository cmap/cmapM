classdef L1kPipeline
    % L1kPipeline A class for L1000 data processing
    % This class comprises of several core computation methods used in
    % processing L1000 data. These include the following:
    %
    % Normalization
    %   liss    Perform L1000 invariant set scaling
    %   qnorm   Perform quantile normalization
    % Differential Expression Computation
    %   zscore  z-score a matrix
    %   modzs   Compute a moderated Z-score from replicate signatures
    
    methods (Static=true)
                
        % LISS  Perform L1000 invariant set scaling
        [raw, qcrpt, cal, cidx_fail] = liss(raw, calib, ref, varargin)

        % QNORM Perform quantile normalization
        x = qnorm(x, varargin)

        % ZSCORE z-score a matrix
        [zs, mu, sigma] = zscore(varargin);

        % MODZS Compute a moderated Z-score
        [czs, norm_wt, cc] = modzs(zs, ridx, varargin)
        
        %Gex2Norm SigTool runAnalysis function.
        [ds, calib, sc, qcpass, cal_linear, qn] = gex2Norm(varargin);
        
        % foldchangeByCohort Compute fold change relative to a specified control
        [fc, status] = foldchangeByCohort(ds_file, meta_data_file, cohort_field, ctl_field, ctl_id);

        % dpeak on a single analyte
        pkstats = detect_lxb_peaks_single(x, varargin);

        % dpeak on multiple analytes
        pkstats = detect_lxb_peaks_multi(rp1, rid, varargin);

        % dpeak on a folder of lxb files
        [pkstats,fn] = detect_lxb_peaks_folder(dspath, varargin);

        % assign peaks post dpeak
        ds = assign_lxb_peaks(pkstats, varargin);
        
        % Generate Map file from Mapsrc
        mapList = mapsrcTomap(plates, map_src_path);
        
    end
end