classdef Annot

    properties(Constant = true)
        cp_tbl_file = '/cmap/projects/metadata_curation/rnwork/masterdb/master_cmpd_db_n8723_v5.txt';
        moa_tbl_file = '/cmap/projects/metadata_curation/rnwork/masterdb/litdb_cp_moa_wide_pert_id_n8723.txt';
        target_tbl_file = '/cmap/projects/metadata_curation/rnwork/masterdb/litdb_cp_targets_wide_n4970.txt';
    end
    
    methods(Static=true)
        
        function cp_tbl = getCpTable(refresh_cache)
            % getCpTable Read compound annotation table
            if isequal(nargin, 1)
                do_refresh = refresh_cache;
            else
                do_refresh = false;
            end
            persistent cp_tbl_;
            if isempty(cp_tbl_) || do_refresh
                cp_tbl_ = parse_record(mortar.common.Annot.cp_tbl_file, 'detect_numeric', false);
            end
            cp_tbl = cp_tbl_;
        end
        
        function moa_tbl = getMoaTable(refresh_cache)
            % getMoaTable Read compound MoA table
            if isequal(nargin, 1)
                do_refresh = refresh_cache;
            else
                do_refresh = false;
            end
            persistent moa_tbl_;
            if isempty(moa_tbl_) || do_refresh
                moa_tbl_ = parse_record(mortar.common.Annot.moa_tbl_file, 'detect_numeric', false);
            end
            moa_tbl = moa_tbl_;
        end
        
        function target_tbl = getTargetTable(refresh_cache)
            % getTargetTable Read compound target table
            if isequal(nargin, 1)
                do_refresh = refresh_cache;
            else
                do_refresh = false;
            end
            persistent target_tbl_;
            if isempty(target_tbl_) || do_refresh
                 target_tbl_ = parse_record(mortar.common.Annot.target_tbl_file, 'detect_numeric', false);
            end
            target_tbl = target_tbl_;
        end
        
        rpt = lookupCpAnnotByPertId(pid_list, refresh_cache);
        
    end
    
end