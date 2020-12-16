classdef TestSigQueryl1k < matlab.unittest.TestCase
    % TestSigQueryl1k Unit and functional tests for SigQueryl1k
    % Note that calling the sig_tool with --runtests executes all the tests below.
    % while --rundemo only executes tests beginning with testDemo.
    % You can add as many tests as you want. You can also have more than one demo,
    % just begin their names with testDemo
    
    properties
        sig_class = @mortar.sigtools.SigQueryl1k
        sig_tool = 'sig_queryl1k_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
        build_path = 'SET_LATER';
        query_path = 'SET_LATER';
    end
    methods(TestMethodSetup)
        function unPackFiles(testCase)
            tar_file = fullfile(testCase.asset_path, 'queryl1k_input.tgz');
            untar(tar_file, testCase.result_path);
        end
        function setVariables(testCase)
            testCase.build_path = fullfile(testCase.result_path,...
                'queryl1k_input', 'build');
            testCase.query_path = fullfile(testCase.result_path,...
                'queryl1k_input', 'queries');
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        
        function testClass(testCase)
            scoreFile = fullfile(testCase.build_path,...
                'modzs_n10x10174.gctx');
            
            rankFile = fullfile(testCase.build_path,...
                'rank_bing_n10x10174.gctx');
            
            upFile = fullfile(testCase.query_path,...
                'contest_query_ezid_up_n10.gmt');
            
            dnFile = fullfile(testCase.query_path,...
                'contest_query_ezid_down_n10.gmt');
            
            sigMetaFile = fullfile(testCase.build_path,...
                'siginfo.txt');
            
            obj = testCase.sig_class();
            obj.parseArgs('--up', upFile,...
                '--down', dnFile,...
                '--score', scoreFile,...
                '--rank', rankFile,...
                '--sig_meta', sigMetaFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'query_result', 'ncs_result', 'fdr_result'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
        end
        
        function testClassQuerySet(testCase)
            score_file = fullfile(testCase.build_path, 'modzs_n10x10174.gctx');
            rank_file = fullfile(testCase.build_path, 'rank_bing_n10x10174.gctx');
            sig_meta_file = fullfile(testCase.build_path, 'siginfo.txt');
            upFile = fullfile(testCase.query_path,...
                'contest_query_ezid_up_n10.gmt');
            dnFile = fullfile(testCase.query_path,...
                'contest_query_ezid_down_n10.gmt');
            obj = testCase.sig_class();
            obj.parseArgs('score', score_file, 'rank', rank_file,...
                'sig_meta', sig_meta_file,...
                '--up', upFile, '--down', dnFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'query_result', 'ncs_result', 'fdr_result'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
        end
        
        function testDemoTool(testCase)

            score_file = fullfile(testCase.build_path, 'modzs_n10x10174.gctx');
            rank_file = fullfile(testCase.build_path, 'rank_bing_n10x10174.gctx');
            sig_meta_file = fullfile(testCase.build_path, 'siginfo.txt');
            upFile = fullfile(testCase.query_path,...
                'contest_query_ezid_up_n10.gmt');
            dnFile = fullfile(testCase.query_path,...
                'contest_query_ezid_down_n10.gmt');
            
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--score', score_file,...
                '--rank', rank_file,...
                '--sig_meta', sig_meta_file,...
                '--up', upFile,...
                '--down', dnFile,...
                '--exemplar_field', '',...
                '--out', outPath,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            % folder
            output_folders = {'matrices/query', 'arfs'};
            for ii=1:length(output_folders)
                this_folder = fullfile(outPath, output_folders{ii});
                tf = mortar.util.File.isfile(this_folder, 'dir');
                testCase.verifyTrue(tf, sprintf('Folder not found %s',this_folder));
            end       
        end        
    end
end