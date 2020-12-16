classdef utils
 % methods for PRISM data
 methods (Static = true)
     plist = valid_plate_check(plates,plate_path,varargin);
     s = annot2struct(file,varargin);
     dsmatch = matchwellids(ds,annot);
     pert_type = identify_ctl(ds,varargin);
     s = platestats(plates_mfi, plates_count, varargin);
     
    % fix_ds_feature_id Fix the feature ids for legacy Prism datasets
     fix_ds_feature_id(in_path, out_path);

     % compute frequency of cell line hits
     hit_rpt = get_cell_hit_freq(ds, col_group, hit_thresh);
     
     % Extract a subset of signatures from a Prism build
     [sig_metrics, inst_info, l5_ds, l4_ds] = extract_build_subset(build_path, sig_id_list, norm_type);
 end
 
end
