classdef TestSigMetrics < matlab.unittest.TestCase
	% TestSigMetrics Unit and functional tests for SigMetrics
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigMetrics
        sig_tool = 'sig_metrics_tool';
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
            obj.parseArgs('--ds_brew', dsFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'sig_output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.sig_output), 'Result table not found');
            % testCase.verifyEqual(size(res.output.mat), [978, 371], 'Result matrix size mismatch');
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds_brew', dsFile ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'sig_metric_tbl_n*.txt',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end