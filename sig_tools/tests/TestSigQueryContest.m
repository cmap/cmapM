classdef TestSigQueryContest < matlab.unittest.TestCase
	% TestSigQueryContest Unit and functional tests for SigQueryContest
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigQueryContest
        sig_tool = 'sig_querycontest_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        query_up_path;
        query_dn_path;
        score_path;
        rank_path;
        rore_path;
        result_path;
    end
    methods(TestMethodSetup)
        function setupPaths(testCase)
            testCase.query_up_path = fullfile(testCase.asset_path, 'contest_query_ezid_up_n10.gmt');
            testCase.query_dn_path = fullfile(testCase.asset_path, 'contest_query_ezid_down_n10.gmt');            
            testCase.score_path = fullfile(testCase.asset_path, 'contest_modzs_ezid_n10x10174.gctx');
            testCase.rank_path = fullfile(testCase.asset_path, 'contest_rank_ezid_n10x10174.gctx');
            testCase.rore_path = fullfile(testCase.asset_path, 'contest_rore_ezid_n10x10174.gctx');
            testCase.result_path = fullfile(testCase.asset_path, 'contest_results_n10x10.gctx');            
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
	% ADD TESTS FOR YOUR SIGCLASS HERE
            obj = testCase.sig_class();
            obj.parseArgs('--up', testCase.query_up_path,...
                          '--dn', testCase.query_dn_path,...
                          '--score', testCase.score_path,...
                          '--rank', testCase.rank_path);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'query_result', 'query_stats'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyEqual(size(res.query_result.cs.mat), [10, 10], 'Result matrix size mismatch');
            expectedResult = parse_gctx(testCase.result_path);
            [is_match, rmsd] = gctcomp(expectedResult, res.query_result.cs, 'tol', 1e-4);
            testCase.verifyTrue(is_match,...
                    sprintf('Result mismatch RMSD: %f', rmsd));            
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--up', testCase.query_up_path,...
                '--dn', testCase.query_dn_path,...
                '--rank_score', testCase.rore_path,...
                '--out_fmt', 'gctx',...
                '--max_col', 5,...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'result.*', 'query_stats.txt',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
                if isequal(output_files{ii}, 'result.*')
                    resultFile = fp{1};
                end
            end
            obsResult = parse_gctx(resultFile);
            expResult = parse_gctx(testCase.result_path);
            [is_match, rmsd] = gctcomp(expResult, obsResult, 'tol', 1e-4);
            testCase.verifyTrue(is_match,...
                sprintf('Result mismatch RMSD: %f', rmsd));                        
        end
              
    end 
end