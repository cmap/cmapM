classdef TestDactyloscopyMakePlots < matlab.unittest.TestCase
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),'assets')
        wkdir_path = [];
    end
    
    % add the wkdir_path property to the testcase object
    methods(TestClassSetup)
        function makeWkDir(testcase)
            testcase.wkdir_path = fullfile(testcase.self_path, 'wkdir');
            if exist(testcase.wkdir_path, 'dir')
	        rmdir(testcase.wkdir_path, 's')
            end
            mkdir(testcase.wkdir_path)
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        % Testing happy path
        function test_happy_path(testcase)
	    fprintf('test_happy_path\n')

            my_assets = fullfile(testcase.asset_path, 'TestDactyloscopyMakePlots', 'test_happy_path');
            fprintf('inputs (Dactyloscopy_single results), aka report_path - my_assets:  %s\n', my_assets)

	    my_wkdir = fullfile(testcase.wkdir_path, 'test_happy_path');
	    mkdir(my_wkdir);
            fprintf('wkdir_path: %s\n', my_wkdir)
            
            fprintf('Running the dactyloscopy_make_plots function\n\n')
            fprintf('----------\n')

            tic
	    my_dmp = DactyloscopyMakePlots(my_assets);
            my_dmp.make_plots('--save_out', true, '--dname_out', my_wkdir);
            t1 = toc;
            
            fprintf('Finished running the dactyloscopy_make_plots function\n')
            fprintf('It took: %.4fs to run dactyloscopy_make_plots.\n\n', t1)
            
            % Verifying if the function worked correctly
            d = dir(fullfile(my_wkdir,'*.png'));

	    testcase.verifyEqual(size(d,1), 2, 'expected 2 output files found something else');
        end

	function test_multiple_cell_lines(testcase)
            fprintf('test_multiple_cell_lines\n')

            my_assets = fullfile(testcase.asset_path, 'TestDactyloscopyMakePlots', 'test_multiple_cell_lines');
            fprintf('inputs (Dactyloscopy_single results), aka report_path - my_assets:  %s\n', my_assets)

       	    my_wkdir = fullfile(testcase.wkdir_path, 'test_multiple_cell_lines');
	    mkdir(my_wkdir);
            fprintf('wkdir_path: %s\n', my_wkdir)
            
            fprintf('Running the dactyloscopy_make_plots function\n\n')
            fprintf('----------\n')

            tic
	    my_dmp = DactyloscopyMakePlots(my_assets);
            my_dmp.make_plots('--save_out', true, '--dname_out', my_wkdir);
            t1 = toc;
            
            fprintf('Finished running the dactyloscopy_make_plots function\n')
            fprintf('It took: %.4fs to run dactyloscopy_make_plots.\n\n', t1)
            
            % Verifying if the function worked correctly
            d = dir(fullfile(my_wkdir,'*.png'));

	    testcase.verifyEqual(size(d,1), 4, 'expected 2 output files found something else');
	end

	function test_find_report_file(testcase)
	    fprintf('test_find_report_file')
	    
            my_assets = fullfile(testcase.asset_path, 'TestDactyloscopyMakePlots', 'test_find_report_file')

	    my_dmp = DactyloscopyMakePlots(my_assets);
	    dr_file = my_dmp.find_report_file('ds_rank_', 'BT549')
	    testcase.verifyTrue(~isempty(dr_file), 'expected to find an actual filepath, returned empty')
	end
    end
end
