classdef TestSigZScore < matlab.unittest.TestCase
	% TestSigZScore Unit and functional tests for SigZScore
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigZScore
        sig_tool = 'sig_zscore_tool';
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
	% ADD TESTS FOR YOUR SIGCLASS HERE
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.output), 'Result dataset not found');
            testCase.verifyEqual(size(res.output.mat), [978, 371], 'Result matrix size mismatch');
            dsResFile = fullfile(testCase.asset_path, 'gctv13_01_zs.gctx');
            zscore = parse_gctx(dsResFile);
            testCase.verifyEqual(res.output.mat, zscore.mat, 'Result did not match answer dataset.');
            
            
            dimtest = testCase.sig_class();
            dimtest.parseArgs('--ds', dsFile, '--dim', 'column', '--min_var', 2, '--var_adjustment', 'estimate', '--estimate_prct', 20);
            dimtest.runAnalysis;
            res = dimtest.getResults;
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.output), 'Result dataset not found');
            testCase.verifyEqual(size(res.output.mat), [978, 371], 'Result matrix size mismatch');
            rowResFile = fullfile(testCase.asset_path, 'gctv13_01_params.gctx');
            rowzscore = parse_gctx(rowResFile);
            testCase.verifyEqual(res.output.mat, rowzscore.mat, 'Row z-score result did not match answer dataset.');

    end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile , '--dim', 'row', '--zscore_method', 'standard', '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'result_n*.gctx',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end