classdef TestSigQNorm < matlab.unittest.TestCase
	% TestSigQNorm Unit and functional tests for SigQNorm
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigQNorm
        sig_tool = 'sig_qnorm_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                   
        function testQNorm(testCase)
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
            
            qnorm = parse_gctx(fullfile(testCase.asset_path,'gctv13_01_qnorm.gctx'));
            testCase.verifyEqual(res.output.mat, qnorm.mat, 'Result matrix does not match reference')
            testCase.verifyEqual(qnorm.rid, res.output.rid);
            testCase.verifyEqual(qnorm.cid, res.output.cid);
        
        end   
        
        function testDemoTool(testCase)
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'gctv13_01_qnorm_n*.gctx',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end