classdef TestSigIntrospect < matlab.unittest.TestCase
	% TestSigIntrospect Unit and functional tests for SigIntrospect
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigIntrospect
        sig_tool = 'sig_introspect_tool';
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
            obj.parseArgs('--sig_score', dsFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'introspect_result'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            resultDSFields = {'cs', 'ncs', 'ps','ps_bkg'};     
            resultOtherFields = {'up', 'dn'};  
            hasResultDSFields = isfield(res.introspect_result, resultDSFields);
            hasResultOtherFields = isfield(res.introspect_result, resultOtherFields);
            testCase.verifyTrue(all(hasResultDSFields),...
                'Dataset fields not found in the results');                                    
            testCase.verifyTrue(all(hasResultOtherFields),...
                'Non-Dataset fields not found in the results');
            for ii=1:length(resultDSFields)        
                testCase.verifyTrue(...
                    isds(res.introspect_result.(resultDSFields{ii})),...
                    sprintf('Dataset %s not found in result',...
                    resultDSFields{ii}));
            end               
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--sig_score', dsFile ,...
                '--row_space', 'lm_probeset',...
                '--out', outPath,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'cs_n*.gctx','ncs_n*.gctx',...
                'ps_n*.gctx','ps_bkg_n*.gctx'...
                'up.gmt', 'dn.gmt',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end