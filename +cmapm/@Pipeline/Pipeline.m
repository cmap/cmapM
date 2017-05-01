classdef Pipeline
% PIPELINE Core routines for CMap data processing pipeline for L1000 data

    methods (Static=true)
        % Download test data
        download_test_data;
        
        % Process a single plate from level 1 (LXB) to level 4 (ZS)
        [gex_ds, qnorm_ds, inf_ds, zs_ds_qnorm, zs_ds_inf] = process_plate(varargin);
        % Level 1 (LXB) to Level 2 (GEX)
        gex_ds = level1_to_level2(varargin);
        % Level 2 (GEX) to Level 3 (INF)
        [qnorm_ds, inf_ds] = level2_to_level3(varargin);        
        % Level 3 (INF) to Level 4 (ZS)
        ds = level3_to_level4(ds, varargin);        
        % Level 4 (ZS) to Level 5 (MODZ)
        modz_ds = level4_to_level5(zsrep_file, col_meta_file, landmark_file, gp_var);

        % Demo of peak detection
        [lxb, pkstats] = dpeak_demo;
        
        % File formats
        function ds = parse_gct(fname,varargin)
            ds = parse_gct(fname, varargin{:});
        end
        
        function ds = parse_lxbbin(fname,varargin)
        ds = parse_lxbbin(fname, varargin{:});        
        end
        
        dpeak_heuristic;
        example_methods;
    end
    
end