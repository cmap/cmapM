classdef TestSigDpeak < matlab.unittest.TestCase
	% TestSigDeakTool Unit and functional tests for SigDeakTool
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigDpeak
        sig_tool = 'sig_dpeak_tool';
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
            dsPath = fullfile(testCase.asset_path, 'DPK.CP001_A549_24H_X1_B42');
            dsFile = fullfile(testCase.asset_path, 'dpeak_test_RAW_n10x976.gct');
            refDS = parse_gct(dsFile);
            obj = testCase.sig_class();
            obj.parseArgs('--dspath', dsPath);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.output), 'Result dataset not found');
            testCase.verifyEqual(size(res.output.mat), [976, 10], 'Result matrix size mismatch');
            delta = abs(refDS.mat(:) - res.output.mat(:));
            % make sure values are accurate to 10 FI units
            testCase.verifyTrue(logical(max(delta) < 10), 'Result matrix differs from expected');
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            dsPath = fullfile(testCase.asset_path, 'DPK.CP001_A549_24H_X1_B42');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--dspath', dsPath ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'RAW*.gct',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end