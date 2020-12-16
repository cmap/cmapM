classdef TestSigScore2Rank < matlab.unittest.TestCase
	% TestSigScore2Rank Unit and functional tests for SigScore2Rank
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigScore2Rank
        sig_tool = 'sig_score2rank_tool';
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
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            gndFile = fullfile(testCase.asset_path, 'gctv13_01_rank.gctx');
            gnd = parse_gctx(gndFile);
            outPath = tempname;
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--out', outPath, '--create_subdir', false);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');  
            rank_file_pat = fullfile(outPath, 'rank_n*.gct*');
            [~, fp] = find_file(rank_file_pat);            
            testCase.verifyTrue(~isempty(fp), sprintf('Result dataset not found: %s', rank_file_pat));
            ds_rank = parse_gctx(fp{1});
            testCase.verifyEqual(size(ds_rank.mat), [978, 371], 'Result matrix size mismatch');
            testCase.verifyTrue(all(all(gnd.mat - ds_rank.mat < 0.01)), 'Errors found in matrix');        
        end

        function testDemoTool(testCase)
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            outPath = tempname;            
            gndFile = fullfile(testCase.asset_path, 'gctv13_01_rank.gctx');
            gnd = parse_gctx(gndFile);

            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile ,'--out', outPath, '--create_subdir', false, 'read_mode', 'iterative', 'block_size', 50);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            
            output_files = {'rank*.gctx',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            
            rank_file_pat = fullfile(outPath, 'rank*.gct*');
            [~, fp] = find_file(rank_file_pat);
            ds_rank = parse_gctx(fp{1});
            testCase.verifyEqual(size(ds_rank.mat), [978, 371], 'Result matrix size mismatch');
            testCase.verifyTrue(all(all(gnd.mat - ds_rank.mat < 0.01)), 'Errors found in matrix');            
        end
              
    end 
end