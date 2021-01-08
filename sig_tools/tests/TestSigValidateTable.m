classdef TestSigValidateTable < matlab.unittest.TestCase
	% TestSigValidateTable Unit and functional tests for SigValidateTable
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigValidateTable
        sig_tool = 'sig_validatetable_tool';
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
            test_table = fullfile(testCase.asset_path, 'test_gctlong.csv');
            ref_table = fullfile(testCase.asset_path, 'ref_gctlong.csv');
            obj = testCase.sig_class();
            obj.parseArgs('--table', test_table, '--ref', ref_table);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'missing_rpt', 'error_rpt'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyEqual(size(res.missing_rpt), [3, 1], 'Dimension mismatch in missing report');
            testCase.verifyEqual(size(res.error_rpt), [2, 1], 'Dimension mismatch in error report');
        end
                
        function testDemoTool(testCase)
            test_table = fullfile(testCase.asset_path, 'test_gctlong.csv');
            ref_table = fullfile(testCase.asset_path, 'ref_gctlong.csv');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--table', test_table , '--ref', ref_table, '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'missing.txt', 'error.txt'...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end