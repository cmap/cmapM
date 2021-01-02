classdef TestSigGex2Norm < matlab.unittest.TestCase
	% TestSigGex2Norm Unit and functional tests for SigGex2Norm
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigGex2Norm
        sig_tool = 'sig_gex2norm_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClassL1000(testCase)
        % Normalize L1000 data
            dsFile = fullfile(testCase.asset_path, 'GEX_n192x500.gct');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.output.ds), 'Result dataset not found');
            testqnpath = fullfile(testCase.asset_path, 'gex2norm_QNORM_n192x500.gct');
            testqn = parse_gctx(testqnpath, 'class', 'single');
            testCase.verifyTrue(all(abs(res.output.qn.mat(:)-testqn.mat(:))<1e-2));
        end
        
        function testClassAffx(testCase)
            % Normalize Affymetrix data
            paramobj = testCase.sig_class();
            reqFields = {'args', 'output'};
            AffyxFile = fullfile(testCase.asset_path, 'affx_example_data_n25x22268.gctx');
            paramobj.parseArgs('--ds', AffyxFile, 'feature_space', 'AFFX-U133A', 'islog2', true);
            paramobj.runAnalysis;
            paramresults = paramobj.getResults;
            hasReq = isfield(paramresults,reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            testCase.verifyTrue(isds(paramresults.output.ds), 'Result dataset not found');
            testqnpath = fullfile(testCase.asset_path, 'gex2norm_QNORM_n25x22268.gctx');
            testqn = parse_gctx(testqnpath, 'class', 'single');
            testCase.verifyTrue(all(abs(paramresults.output.qn.mat(:)-testqn.mat(:))<1e-2));
        end
                
         function testDemoTool(testCase)
            dsFile = fullfile(testCase.asset_path, 'GEX_n192x500.gct'); 
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile , '--showfig', false, 'minval', 3 ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'result_n*.gctx',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, ~] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
         end
              
    end 
end