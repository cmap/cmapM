classdef Pipeline
% PIPELINE Core routines for CMap data processing pipeline for L1000 data

    methods (Static=true)
        % Download test data
        download_test_data;
        
        %% CMap data pipeline
        % Process a single plate from level 1 (LXB) to level 4 (ZS)
        [gex_ds, qnorm_ds, inf_ds, zs_ds_qnorm, zs_ds_inf] = process_plate(varargin);        
        % A demo of peak detection
        [lxb, pkstats] = dpeak_demo;
        % Pipeline Modules
        % Level 1 (LXB) to Level 2 (GEX)
        gex_ds = level1_to_level2(varargin);
        % Level 2 (GEX) to Level 3 (INF)
        [qnorm_ds, inf_ds] = level2_to_level3(varargin);        
        % Level 3 (INF) to Level 4 (ZS)
        ds = level3_to_level4(ds, varargin);        
        % Level 4 (ZS) to Level 5 (MODZ)
        modz_ds = level4_to_level5(zsrep_file, col_meta_file, landmark_file, gp_var);
        
        %% I/O functions for common file formats
        % Parsers
        ds = parse_lxb(fname, varargin);
        ds = parse_gct(fname,varargin);
        ds = parse_gctx(fname,varargin);
        ds = parse_gmt(fname);
        ds = parse_grp(fname);
        ds = parse_tbl(fname,varargin);
        
        % Writers
        ds = mkgctstruct(mat, varargin);
        ds = mkgct(fname, gct_struct, varargin);
        ds = mkgctx(fname, gct_struct, varargin);
        ds = mkgmt(fname);
        ds = mkgrp(fname);
        ds = mktbl(fname, varargin);
        
        % Utilities        
        % Combine two GCT structures
        combods = ds_merge(ds1, ds2, isverbose);
        % Transpose a GCT structure      
        ds = ds_transpose(ds);

        % Extract metadata fields from GCT structure 
        metadata = ds_get_meta(ds, dim, meta, varargin);
        % Add metadata to a GCT structure
        metadata = ds_add_meta(ds, dim, hd, meta);
        % Remove metadata from a GCT structure
        metadata = ds_delete_meta(ds, dim, hd);
        % Annotate rows or columns in a dataset.
        ds = ds_set_annotations(ds, annot, varargin);
        % Extract all rows or column annotations from a dataset.
        meta = ds_get_annotations(ds, dim);
        
        % Extract a subset of data from a GCT structure.
        ds = ds_slice(ds, varargin);
        % Compute pairwise correlations for a dataset.
        cc = ds_corr(ds, varargin);

        %% Common analysis
        [z, mu, sigma] = robust_zscore(x, dim, varargin);
    end
    
end