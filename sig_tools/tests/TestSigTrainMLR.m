classdef TestSigTrainMLR < matlab.unittest.TestCase
	% TestSigTrainMLR Unit and functional tests for SigTrainMLR
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigTrainMLR
        sig_tool = 'sig_trainmlr_tool';
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
            %dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            dsFile = fullfile(testCase.asset_path, 'affymetrix_inf_training_testing_n1000x1978.gctx');
            landmarkgrp = fullfile(testCase.asset_path, 'landmark_gene_ids_n978.grp');
            comparefile = fullfile(testCase.asset_path, 'model_n979x1000.gctx');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--grp_landmark', landmarkgrp);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            model = parse_gctx(comparefile);
            testCase.verifyEqual(double(model.mat), double(res.output.mat), 'AbsTol', 1e-3,...
                'Failure at verification');
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            dsFile = fullfile(testCase.asset_path, 'affymetrix_inf_training_testing_n1000x1978.gctx');
            landmarkgrp = fullfile(testCase.asset_path, 'landmark_gene_ids_n978.grp');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile , '--grp_landmark', landmarkgrp, '--outfmt', 'gctx','--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'*.gctx',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            comparefile = fullfile(testCase.asset_path, 'model_n979x1000.gctx');
            model = parse_gctx(comparefile, 'matrix_class', 'double');
            this_file = fullfile(outPath, '*.gctx');
            [file, ~] = find_file(this_file);
            filepath = fullfile(outPath, file);
            result = parse_gctx(filepath{:}, 'matrix_class', 'double');
            testCase.verifyEqual(result.mat , model.mat, ...
            'AbsTol', 1e-3, 'Result matrix mismatch');           
        end
              
    end 
end