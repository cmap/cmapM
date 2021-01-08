classdef TestSigCalib < matlab.unittest.TestCase
	% TestSigCalib Unit and functional tests for SigCalib
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigCalib
        sig_tool = 'sig_calib_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
            siginfo = fullfile(testCase.asset_path, 'siginfo_NDIS.txt');
            obj = testCase.sig_class();
            outPath = tempname; 
            obj.parseArgs('--siginfo', siginfo, '--experimental_param', ...
                {'pert_time', 'x_density'}, '--out', outPath);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            %checks number of plots to be generated
            testCase.verifyEqual(length(res.output), 3);
        end
                
        function testDemoTool(testCase)
            siginfo = fullfile(testCase.asset_path, 'siginfo_NDIS.txt');
            path_to_conn = fullfile(testCase.asset_path, 'ps_pcl_summary.gctx');
            pcl_class = 'CP_TOPOISOMERASE_INHIBITOR';
            outPath = tempname; 
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--siginfo', siginfo, '--experimental_param', 'x_density', ...
                '--conn_to_ref', path_to_conn,...
                '--pcls_to_display', pcl_class,...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, ~] = find_file(this_file);
                %ensures expected plots were saved
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
                
            end
            plots = {'tas_vs_pert_types_xc.png',...
                'tas_vs_x_density_xc.png', 'GUTC_heatmap.png'};
            for jj = 1:length(plots)
                this_file = fullfile(outPath, plots{ii});
                [fn, ~] = find_file(this_file);
                file = dir(this_file);
                %ensures expected plots were saved
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
                testCase.verifyTrue((file.bytes > 20000), ...
                        sprintf('File %s is smaller than expected', this_file));
            end
            out_mat = {'ps_pcl_summary_treated_n36x171.gctx'};
            for ii=1:length(out_mat)
                this_file = fullfile(outPath, out_mat{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
                out_ds = parse_gctx(this_file);
                testCase.verifyEqual(size(out_ds.mat), [171, 36], 'Result matrix size mismatch');
                test_asset = fullfile(testCase.asset_path, 'ps_pcl_summary_result.gctx');
                pcl_subset = parse_gctx(test_asset);
                testCase.verifyEqual(out_ds.mat, pcl_subset.mat, 'Treated PCL matrix did not match reference');

            end
            close all
        end

              
    end 
end