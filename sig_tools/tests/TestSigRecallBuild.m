classdef TestSigRecallBuild < matlab.unittest.TestCase
	% TestSigRecallBuild Unit and functional tests for SigRecallBuild
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       
    % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigRecallBuild
        sig_tool = 'sig_recallbuild_tool';
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
            buildPath = fullfile(testCase.asset_path, 'recall_build/');
            obj = testCase.sig_class();
            outPath = tempname;
            obj.parseArgs('--build', buildPath, '--out', outPath);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'recall_stats'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.recall_stats), 'Result dataset not found');
            testCase.verifyEqual(length(res.recall_stats), 2, 'Result matrix size mismatch');
        end
                
        function testDemoTool(testCase)
            buildPath = fullfile(testCase.asset_path, 'recall_build/');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--build', buildPath ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'index.html',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end