classdef TestPlotReplicateCorr < matlab.unittest.TestCase
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),'assets')
        wkdir_path = [];
    end
    
    methods(TestClassSetup)
        function makeWkDir(testcase)
            testcase.wkdir_path = fullfile(testcase.asset_path, 'wkdir_TestPlotReplicateCorr');
            if exist(testcase.wkdir_path, 'dir')
	        rmdir(testcase.wkdir_path, 's')
	    end
            mkdir(testcase.wkdir_path)
        end
    end

    methods(TestClassTeardown)
    end

    methods(TestMethodTeardown)
        function closeAll(testcase)
            close all
        end
    end
        
    methods(Test)
        function test_happy_path(testcase)
	    input_file = fullfile(testcase.asset_path, 'TestPlotReplicateCorr_COMPZ_CORR_n10x10.gctx');
            [~, ccstats] = plot_replicate_corr(input_file)
	    display_struct(ccstats);
	    testcase.verifyEqual(2, length(ccstats.pert_id))
	    print(fullfile(testcase.wkdir_path, 'test_happy_path.png'), '-dpng')
        end

        %this test (and the entire test case) was added because this situation was causing brew to fail
	%for baseline plates run with just cell lines, no treatments, the plot_replicate_corr method would
	%fail because it would attempt to generate a null distribution of the correlation of non-replicates
	%this test case reproduces that condition to ensure it now handles the condition without crashing
        function test_no_non_replicates(testcase)
            input_file = fullfile(testcase.asset_path, 'TestPlotReplicateCorr_noNonReplicates_COMPZ_CORR_n10x10.gctx');
            [~, ccstats] = plot_replicate_corr(input_file)
	    display_struct(ccstats);
	    testcase.verifyEqual(1, length(ccstats.pert_id))
	    print(fullfile(testcase.wkdir_path, 'test_no_non_replicates.png'), '-dpng')
	end

        %this test is based on an observation from a specific dataset that the text message warning
	%about not having a null distribution was not displayed on the plot because of an incorrect position.
	%The test reproduces that although there is no reasonable way to test for the presence of the text 
	%in the viewable area except for manually checking the results
	function test_no_non_replicates_low_frequencies(testcase)
            input_file = fullfile(testcase.asset_path, 'TestPlotReplicateCorr_low_frequencies_INS_CORR_n10x10.gctx');
            %input_file = '~/custom/XPR/brew/pc/XPR.BASE009_XC_XH/by_x_rep_group_vals/xy/XPR.BASE009_XC_XH_INS_CORR_n363x363.gctx';

	    [~, ccstats] = plot_replicate_corr(input_file, 'group_by', 'pert_id', ...
	                        'name', 'q75_instance_corr', ...
                                'labelrt', 'my_fake_brew_id', ...
	                        'title','Correlations between instances (Q75)', ...
                                'showfig', false, ...
                                'type', 'q75')
	    display_struct(ccstats);
	    testcase.verifyEqual(1, length(ccstats.pert_id))

	    print(fullfile(testcase.wkdir_path, 'test_no_non_replicates_low_frequencies.png'), '-dpng')
	end

	function test_multi_field_group_by(testcase)
	    input_file = fullfile(testcase.asset_path, 'TestPlotReplicateCorr_COMPZ_CORR_n10x10.gctx');
            
	    [~, ccstats] = plot_replicate_corr(input_file, 'group_by', 'pert_id,pert_dose')
	    display_struct(ccstats);
	    testcase.verifyEqual(7, length(ccstats.pert_id_pert_dose))

	    print(fullfile(testcase.wkdir_path, 'test_multi_field_group_by.png'), '-dpng')
	end
    end
end

function display_struct(my_struct)
    my_fieldnames = fieldnames(my_struct);
    for ii = 1:length(my_fieldnames)
	fn = my_fieldnames{ii};
	fprintf('my_struct values for field fn:  %s', fn);
	getfield(my_struct, fn)
    end
end

