classdef TestSigTestMLR < matlab.unittest.TestCase
	% TestSigTestMLR Unit and functional tests for SigTestMLR
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigTestMLR
        sig_tool = 'sig_testmlr_tool';
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
            dsFile = fullfile(testCase.asset_path, 'affymetrix_inf_training_testing_n1000x1978.gctx');
            model = fullfile(testCase.asset_path, 'model_n979x1000.gctx');
            comparefile = fullfile(testCase.asset_path, 'affymetrix_inf_training_testing_INF_n1000x1978.gctx');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--model', model);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            inferredmat = parse_gctx(comparefile); 
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.output), 'Result dataset not found');
            testCase.verifyEqual(double(res.output.mat), double(inferredmat.mat),...
                'AbsTol', 1e-3, 'Result matrix mismatch');
        end
                
        function testDemoTool(testCase)
            dsFile = fullfile(testCase.asset_path, 'affymetrix_inf_training_testing_n1000x1978.gctx');
            model = fullfile(testCase.asset_path, 'model_n979x1000.gctx');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile , 'model', model, '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'*.gctx',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, ~] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            comparefile = fullfile(testCase.asset_path, 'affymetrix_inf_training_testing_INF_n1000x1978.gctx');
            inferredmat = parse_gctx(comparefile);
            this_file = fullfile(outPath, '*.gctx');
            [~, file_path] = find_file(this_file);
            assert(~isempty(file_path), 'File %s not found', this_file);
            result = parse_gctx(file_path{1});
            testCase.verifyEqual(double(result.mat) , double(inferredmat.mat), ...
            'AbsTol', 1e-3, 'Result matrix mismatch');            
        end
              
    end 
end