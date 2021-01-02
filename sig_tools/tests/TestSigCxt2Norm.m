classdef TestSigCxt2Norm < matlab.unittest.TestCase
	% TestSigCxt2Norm Unit and functional tests for SigCxt2Norm
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigCxt2Norm
        sig_tool = 'sig_cxt2norm_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        cxt_files = 'cxt_files_n3.grp';
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
	% ADD TESTS FOR YOUR SIGCLASS HERE
            obj = testCase.sig_class();
            cxt = fullfile(testCase.asset_path, testCase.cxt_files);
            obj.parseArgs('--cxt', cxt);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'gex', 'missing', 'qn', 'calib'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.gex), 'Result dataset not found');
            testCase.verifyEqual(size(res.gex.mat), [22268, 3], 'Result matrix size mismatch');
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            outPath = tempname;            
            cxt = fullfile(testCase.asset_path, testCase.cxt_files);
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--cxt', cxt,...
                '--out', outPath,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'config.yaml',...
                            'success.txt',...
                            'calib_n*.gct*',...
                            'norm_n*.gct*',...
                            'qnorm_n*.gct*',...
                            'qc_n*.txt',...
                            'qcplot.png',...
                            'rangefc.png'};
                            
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end
