classdef TestSigDevGutcPSLookup < matlab.unittest.TestCase
	% TestSigDevGutcPSLookup Unit and functional tests for SigDevGutcPSLookup
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigDevGutcPSLookup
        sig_tool = 'sig_devgutcpslookup_tool';
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
            dsFile = fullfile(testCase.asset_path, 'norm_pert_n5x10.gctx');
            ns2psFile = fullfile(testCase.asset_path, 'ns2ps_n10001x10.gctx');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--ns2ps', ns2psFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'ps'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.ps), 'Result dataset not found');
            testCase.verifyEqual(size(res.ps.mat), [10, 5], 'Result matrix size mismatch');
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            dsFile = fullfile(testCase.asset_path, 'norm_pert_n5x10.gctx');
            ns2psFile = fullfile(testCase.asset_path, 'ns2ps_n10001x10.gctx');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile , '--ns2ps', ns2psFile,...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'ps_n*.gctx',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end