classdef TestCalculateCCandRank < matlab.unittest.TestCase
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),'assets')
        wkdir_path = [];
        delete_wkdir = false;
    end
    
    % add the wkdir_path property to the testcase object
    methods(TestClassSetup)
        function makeWkDir(testcase)
            testcase.wkdir_path = [testcase.self_path filesep ...
                strcat('test_dir_calculate_cc_and_rank_',strrep(datestr(datetime('now')),' ','_'))];
            if ~exist(testcase.wkdir_path, 'dir')
                mkdir(testcase.wkdir_path)
            end
        end
    end
    
    methods(TestMethodTeardown)
        function removeWkDir(testcase)
            % Only delete wkdir is test runs successfully
            if testcase.delete_wkdir
                fprintf('The test was succesful. Removing the temporary directory:\n%s\n', testcase.wkdir_path)
                rmdir(testcase.wkdir_path, 's')
            else
                fprintf('Something went wrong and the test failed\n')
                fprintf('All the outputs were saved in the temporary directory:\n%s\n',...
                    testcase.wkdir_path)
            end
        end
    end
    
    methods(Test)
        
        % Testing happy path
        function run_calculate_cc_and_rank(testcase)
            det_plate = {'LJP006_PC3_24H_X3_B19'};
            cell_id_annot = {'PC3'};
            gct_file = fullfile(testcase.asset_path,'LJP006_PC3_24H_X3_B19_QNORM_n10x978.gct');
            disp(gct_file)
            ref_library = '/cmap/data/vdb/dactyloscopy/cline_rnaseq_n1022x12450.gctx';
            lincs_lines = '/cmap/data/vdb/dactyloscopy/ljp_rep_lincs_lines.grp';
            
            fprintf('wkdir_path: %s\n', testcase.wkdir_path)
            fprintf('det_plate: %s\n', det_plate{1})
            fprintf('cell_id_annot: %s\n', cell_id_annot{1})
            fprintf('gct_file: %s\n', gct_file)
            fprintf('ref_library: %s\n', ref_library)
            fprintf('lincs_lines: %s\n', lincs_lines)
            
            fprintf('Running the calculate_cc_and_rank function\n\n')
            fprintf('----------\n')
            
            ds_plate = parse_gctx(gct_file);
            ds_ref = parse_gctx(ref_library);
            ds_ref_lm = ds_slice(ds_ref,'rid',ds_plate.rid,...
                'ignore_missing',true,'isverbose',false);
            ds_plate_slice = ds_slice(ds_plate,'rid',ds_ref_lm.rid);
            cell_ids_annot_all = ds_get_meta(ds_plate_slice,'column','cell_id');
            ll = parse_grp(lincs_lines);
            ll_present = intersect(ds_ref_lm.cid,ll);
            
            tic
            [ds_cc,ds_rank,ds_cc_lincs,ds_rank_lincs,ds_median,ds_median_lincs,...
                cc_sorted_median,cc_sorted_median_table,cc_sorted_median_lincs,...
                cc_sorted_median_lincs_table] = calculate_cc_and_rank(det_plate,...
                ds_plate_slice, ds_ref_lm, cell_ids_annot_all, cell_id_annot, ll_present);
            t1 = toc;
            
            fprintf('Finished running the calculate_cc_and_rank function\n')
            fprintf('It took: %.4fs to run calculate_cc_and_rank.\n\n', t1)
            
            % Verifying if the function worked correctly
            is_struct = (isstruct(ds_cc)) && (isstruct(ds_rank)) &&...
                (isstruct(ds_cc_lincs)) && (isstruct(ds_rank_lincs)) && ...
                (isstruct(ds_median)) && (isstruct(ds_median_lincs));
            size_ds_cc = size(ds_cc.mat);
            size_ds_rank = size(ds_rank.mat);
            size_ds_median = size(ds_median.mat);
            top_rank = cc_sorted_median_table.cell_id(1);
            
            testcase.delete_wkdir = is_struct && (size_ds_cc(2) == 10) && ...
                (size_ds_rank(2) == 10) && (size_ds_median(2) == 4) && ...
                strcmp(top_rank,'PC3') && t1<10;
        end
    end
end
