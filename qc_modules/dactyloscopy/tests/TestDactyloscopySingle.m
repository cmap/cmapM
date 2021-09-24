classdef TestDactyloscopySingle < matlab.unittest.TestCase
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
                strcat('test_dir_dactyloscopy_single_',strrep(datestr(datetime('now')),' ','_'))];
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
        function run_dactyloscopy_single(testcase)
            det_plate = {'LJP006_PC3_24H_X3_B19'};
            cell_id_annot = {'PC3'};
            gct_file = fullfile(testcase.asset_path, 'LJP006_PC3_24H_X3_B19_QNORM_n10x978.gct');
            
            fprintf('wkdir_path: %s\n', testcase.wkdir_path)
            fprintf('det_plate: %s\n', det_plate{1})
            fprintf('cell_id_annot: %s\n', cell_id_annot{1})
            fprintf('gct_file: %s\n', gct_file)

            
            fprintf('Running the dactyloscopy_single function\n\n')
            fprintf('----------\n')

            tic
            [out_table, bfds] = dactyloscopy_single(gct_file,...
                '--save_out', true, '--dname_out', testcase.wkdir_path,...
		'--api_user_key_file',fullfile(testcase.asset_path,'api_user_key.config'));
            t1 = toc;
            
            fprintf('Finished running the dactyloscopy_single function\n')
            fprintf('It took: %.4fs to run dactyloscopy_single.\n\n', t1)
            
            % Verifying if the function worked correctly
            fn = {'det_plate'
                'cell_id_annot'
                'cell_id'
                'cell_lineage'
                'cell_histology'
                'cell_line_is_guessed'
                'cell_line_is_missing'
                'cell_line_is_lincs'
                'selected_ref_db'
                'ds_plate_slice'
                'ds_ref_lm'
                'lincs_lines'
                'ds_cc'
                'ds_rank'
                'ds_cc_lincs'
                'ds_rank_lincs'
                'ds_median'
                'ds_median_lincs'
                'cc_sorted_median'
                'cc_sorted_median_table'
                'cc_sorted_median_lincs'
                'cc_sorted_median_lincs_table'
                'best_cell_id'
                'best_lineage'
                'best_lincs_cell_id'
                'best_lincs_lineage'
                'sidx'
                'lidx'
                'rank_pos'
                'rank_pos_lincs'
                'rank_per_well_table'
                'dactyloscopy_pass'
                'is_ambig'
                'out'
                'out_table'};

            vn = {'det_plate'
                'cell_id_annot'
                'cell_lineage_annot'
                'cell_id'
                'is_guessed'
                'is_missing'
                'is_lincs'
                'rank'
                'rank_lincs'
                'cell_id_best'
                'best_lineage'
                'cell_id_lincs_best'
                'lincs_best_lineage'
                'selected_ref_db'
                'dactyloscopy_pass'
                'is_ambiguous'};
            
            d = dir(testcase.wkdir_path);
            n_files_ok = size(d,1)==6;
            is_table = istable(out_table);
            is_struct = isstruct(bfds);
            bfds_fieldnames = fieldnames(bfds);
            all_out_table_variablenames_ok = (sum(ismember(vn,out_table.Properties.VariableNames))==length(vn));
            all_bfds_fieldnames_ok = (sum(ismember(fn,bfds_fieldnames))==length(fn));
            det_plate_ok = strcmp(out_table.det_plate, det_plate);
            cell_id_annot_ok = strcmp(out_table.cell_id_annot, cell_id_annot);
            rank_ok = (out_table.rank{1}==1);
            dactyloscopy_pass_ok = (out_table.dactyloscopy_pass{1}==1);
            bfds_cc_sorted_median_table_cell_id_ok = ...
                strcmp(bfds.cc_sorted_median_table.cell_id{1}, cell_id_annot);
            
            testcase.delete_wkdir = n_files_ok && is_table && is_struct && ...
                all_out_table_variablenames_ok && all_bfds_fieldnames_ok && ...
                det_plate_ok && cell_id_annot_ok && rank_ok && t1<60 && ...
                dactyloscopy_pass_ok && bfds_cc_sorted_median_table_cell_id_ok;
        end

        function run_dactyloscopy_single_neg666_cell_line(testcase)
            det_plate = {'LJP006_NEG666_24H_X3_B19'};
            cell_id_annot = {'PC3'};
            gct_file = fullfile(testcase.asset_path, 'LJP006_NEG666_24H_X3_B19_QNORM_n10x978.gct');
            
            fprintf('wkdir_path: %s\n', testcase.wkdir_path)
            fprintf('det_plate: %s\n', det_plate{1})
            fprintf('cell_id_annot: %s\n', cell_id_annot{1})
            fprintf('gct_file: %s\n', gct_file)

            
            fprintf('Running the dactyloscopy_single function\n\n')
            fprintf('----------\n')

            tic
            [out_table, bfds] = dactyloscopy_single(gct_file,...
                '--save_out', true, '--dname_out', testcase.wkdir_path,...
		'--api_user_key_file',fullfile(testcase.asset_path,'api_user_key.config'));
            t1 = toc;
            
            fprintf('Finished running the dactyloscopy_single function\n')
            fprintf('It took: %.4fs to run dactyloscopy_single.\n\n', t1)
            
            % Verifying if the function worked correctly
            fn = {'det_plate'
                'cell_id_annot'
                'cell_id'
                'cell_lineage'
                'cell_histology'
                'cell_line_is_guessed'
                'cell_line_is_missing'
                'cell_line_is_lincs'
                'selected_ref_db'
                'ds_plate_slice'
                'ds_ref_lm'
                'lincs_lines'
                'ds_cc'
                'ds_rank'
                'ds_cc_lincs'
                'ds_rank_lincs'
                'ds_median'
                'ds_median_lincs'
                'cc_sorted_median'
                'cc_sorted_median_table'
                'cc_sorted_median_lincs'
                'cc_sorted_median_lincs_table'
                'best_cell_id'
                'best_lineage'
                'best_lincs_cell_id'
                'best_lincs_lineage'
                'sidx'
                'lidx'
                'rank_pos'
                'rank_pos_lincs'
                'rank_per_well_table'
                'dactyloscopy_pass'
                'is_ambig'
                'out'
                'out_table'};

            vn = {'det_plate'
                'cell_id_annot'
                'cell_lineage_annot'
                'cell_id'
                'is_guessed'
                'is_missing'
                'is_lincs'
                'rank'
                'rank_lincs'
                'cell_id_best'
                'best_lineage'
                'cell_id_lincs_best'
                'lincs_best_lineage'
                'selected_ref_db'
                'dactyloscopy_pass'
                'is_ambiguous'};
            
            d = dir(testcase.wkdir_path);
            n_files_ok = size(d,1)==6;
            is_table = istable(out_table);
            is_struct = isstruct(bfds);
            bfds_fieldnames = fieldnames(bfds);
            all_out_table_variablenames_ok = (sum(ismember(vn,out_table.Properties.VariableNames))==length(vn));
            all_bfds_fieldnames_ok = (sum(ismember(fn,bfds_fieldnames))==length(fn));
            det_plate_ok = strcmp(out_table.det_plate, det_plate);
            cell_id_annot_ok = strcmp(out_table.cell_id_annot, cell_id_annot);
            rank_ok = (out_table.rank{1}==1);
            dactyloscopy_pass_ok = (out_table.dactyloscopy_pass{1}==1);
            bfds_cc_sorted_median_table_cell_id_ok = ...
                strcmp(bfds.cc_sorted_median_table.cell_id{1}, cell_id_annot);
            
            testcase.delete_wkdir = n_files_ok && is_table && is_struct && ...
                all_out_table_variablenames_ok && all_bfds_fieldnames_ok && ...
                det_plate_ok && cell_id_annot_ok && rank_ok && t1<60 && ...
                dactyloscopy_pass_ok && bfds_cc_sorted_median_table_cell_id_ok;
        end

    end
end
