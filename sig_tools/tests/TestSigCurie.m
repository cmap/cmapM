classdef TestSigCurie < matlab.unittest.TestCase
    % TestSigCurie Unit and functional tests for SigCurie
    % Note that calling the sig_tool with --runtests executes all the tests below.
    % while --rundemo only executes tests beginning with testDemo.
    % You can add as many tests as you want. You can also have more than one demo,	       
    % just begin their names with testDemo
    
    properties
        sig_class = @mortar.sigtools.SigCurie
        sig_tool = 'sig_curie_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        auc_score_file = 'cell_viability_log2auc_n10x489.gctx';
        auc_rank_file = 'cell_viability_log2aucrank_n10x489.gctx';
        query_cell_id = 'cell_id_query.gmt';
        query_pr500_id = 'pr500_id_query.gmt';
        sig_meta_file = 'cell_viability_sig_meta.txt';
        query_meta_file = 'cell_viability_query_meta.txt';
    end
    methods(TestMethodSetup)
        
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        
        function testClass(testCase)            
            obj = testCase.sig_class();
            score_file = fullfile(testCase.asset_path, testCase.auc_score_file);
            rank_file = fullfile(testCase.asset_path, testCase.auc_rank_file);
            up_file = fullfile(testCase.asset_path, testCase.query_cell_id);
            obj.parseArgs('--score', score_file,...
                '--rank', rank_file,...
                '--up', up_file,...
                '--es_tail', 'up',...
                '--feature_space', 'cell_iname');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'query_result'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            reqFields = {'cs', 'ncs', 'pctrank_col', 'pctrank_row'};
            hasQueryResultFields = isfield(res.query_result, reqFields);
            testCase.verifyTrue(all(hasQueryResultFields), 'Required result fields not found');
        end
        
        function testDemoTool(testCase)                        
            outPath = tempname;
            score_file = fullfile(testCase.asset_path, testCase.auc_score_file);
            rank_file = fullfile(testCase.asset_path, testCase.auc_rank_file);
            up_file = fullfile(testCase.asset_path, testCase.query_pr500_id);
            sig_meta = fullfile(testCase.asset_path, testCase.sig_meta_file);
            query_meta = fullfile(testCase.asset_path, testCase.query_meta_file);
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--score', score_file,...
                '--rank', rank_file,...
                '--up', up_file,...
                '--feature_space', 'feature_id',...
                '--es_tail', 'up',...
                '--sig_meta', sig_meta,...
                '--query_meta', query_meta,...
                '--out', outPath,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'ncs*.gct*';...
                'cs*.gct*';...
                'cs_up*.gct*';...
                'cs_dn*.gct*';...
                'leadf_up*.gct*';...
                'leadf_dn*.gct*';...
                'config.yaml';...
                'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
        
    end
end