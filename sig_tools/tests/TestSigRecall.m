classdef TestSigRecall < matlab.unittest.TestCase
	% TestSigRecall Unit and functional tests for SigRecall
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigRecall
        sig_tool = 'sig_recall_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
    end
    methods(TestMethodSetup)
        function unpackFiles(testCase)
            tar_file = fullfile(testCase.asset_path, 'for_sig_recall.tgz');            
            untar(tar_file, testCase.result_path);
            [~, dsList] = find_file(fullfile(testCase.result_path, 'for_sig_recall', '*.gctx'));            
            mkgrp(fullfile(testCase.result_path, 'ds_list.grp'), dsList);
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
	% ADD TESTS FOR YOUR SIGCLASS HERE
            dsList = fullfile(testCase.result_path, 'ds_list.grp');            
            obj = testCase.sig_class();
            obj.parseArgs('--ds_list', dsList, '--metric', 'spearman', '--sample_field', 'det_well');            
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'recall_stats'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.recall_stats), 'Result dataset not found');
            testCase.verifyEqual(length(res.recall_stats), 1, 'Result matrix size mismatch');
        end
 
        function testCosineRecall(testCase)
	% ADD TESTS FOR YOUR SIGCLASS HERE
            dsList = fullfile(testCase.result_path, 'ds_list.grp');            
            obj = testCase.sig_class();
            obj.parseArgs('--ds_list', dsList, '--metric', 'cosine', '--sample_field', 'det_well');            
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'recall_stats'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.recall_stats), 'Result dataset not found');
            testCase.verifyEqual(length(res.recall_stats), 1, 'Result matrix size mismatch');
        end        

        function testInPlateRecall(testCase)
            % Inplate reps
            dsList = parse_grp(fullfile(testCase.result_path, 'ds_list.grp'));
            dsSelf = dsList([1,1]);
            obj = testCase.sig_class();
            obj.parseArgs('--ds_list', dsSelf, '--metric', 'spearman', '--sample_field', 'pert_type');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'recall_stats'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            testCase.verifyTrue(isstruct(res.recall_stats), 'Result dataset not found');
            testCase.verifyEqual(length(res.recall_stats), 1, 'Result matrix size mismatch');
        end
        
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            dsList = fullfile(testCase.result_path, 'ds_list.grp');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds_list', dsList , '--metric', 'wtcs',...
                '--sample_field', 'det_well', '--out',...
                outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'ds_list/recall_report_pairs.txt',...
                'ds_list/recall_report_datasets.txt',...
                'ds_list/recall_report_sets.txt', 'ds_list/recall_summary.txt',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end