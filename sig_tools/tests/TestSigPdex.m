classdef TestSigPdex < matlab.unittest.TestCase
	% TestSigPdex Unit and functional tests for SigPdex
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigPdex
        sig_tool = 'sig_pdex_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        pdex_path
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
	% ADD TESTS FOR YOUR SIGCLASS HERE
            queryFile = fullfile(testCase.asset_path, ...
                                 'pdex_query_n1.gmt');
            query = parse_geneset(queryFile);
            obj = testCase.sig_class();
            obj.parseArgs('--up', queryFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'cs', 'ns', 'ps', 'query_stats'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), ['Required result fields ' ...
                                'not found']);
            testCase.verifyEqual(res.ps.cid, {query.head}', ['Query ' ...
                                'name mismatch']);            
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            queryFile = fullfile(testCase.asset_path, ...
                                 'pdex_query_n1.gmt');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--up', queryFile ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'query_stats.txt', 'cs*.gctx', 'ns*.gctx',...
                            'ps*.gctx', 'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end
