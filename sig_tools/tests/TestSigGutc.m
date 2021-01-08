classdef TestSigGutc < matlab.unittest.TestCase
	% TestSigGutc Unit and functional tests for SigGutc
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       
    % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigGutc
        sig_tool = 'sig_gutc_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
    end
    
    methods(TestMethodSetup)
        function unPackFiles(testCase)
            tar_file = fullfile(testCase.asset_path, 'custom_gutc_input.tgz');
            untar(tar_file, testCase.result_path);
        end    
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
            dsFile = fullfile(testCase.result_path,...
                    'custom_gutc_input',...
                    'gutc_result',...
                    'matrices',...
                    'query',...
                    'cs_n10x10.gctx');
            bkg_path = fullfile(testCase.result_path,...
                'custom_gutc_input', 'gutc_background');  
            
            obj = testCase.sig_class();
            obj.parseArgs('--query_result', dsFile, 'bkg_path', bkg_path);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'query_result', 'gutc_result'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');     
        end

        function testClassQuerySet(testCase)            
            build_path = fullfile(testCase.result_path,...
                'custom_gutc_input', 'build');
            bkg_path = fullfile(testCase.result_path,...
                'custom_gutc_input', 'gutc_background');            
            query_path = fullfile(testCase.result_path,...
                'custom_gutc_input', 'queries');     
            score_file = fullfile(build_path, 'modzs_n10x10174.gctx');
            rank_file = fullfile(build_path, 'rank_bing_n10x10174.gctx');            
            upFile = fullfile(query_path,...
                'contest_query_ezid_up_n10.gmt');
            dnFile = fullfile(query_path,...
                'contest_query_ezid_down_n10.gmt');
            obj = testCase.sig_class();
            obj.parseArgs('bkg_path', bkg_path,...
                          'score', score_file, 'rank', rank_file,...
                          '--up', upFile, '--down', dnFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'query_result', 'gutc_result'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');     
        end
                
        function testDemoTool(testCase)
            dsFile = fullfile(testCase.result_path,...
                    'custom_gutc_input',...
                    'gutc_result',...
                    'matrices',...
                    'query',...
                    'cs_n10x10.gctx');
            bkg_path = fullfile(testCase.result_path,...
                'custom_gutc_input', 'gutc_background');  
            
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--bkg_path', bkg_path,...
                '--query_result', dsFile,...
                '--query_meta', '',...
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
            output_folders = {'matrices/query', 'matrices/gutc'};
            for ii=1:length(output_folders)
                this_folder = fullfile(outPath, output_folders{ii});
                tf = mortar.util.File.isfile(this_folder, 'dir');
                testCase.verifyTrue(tf, sprintf('Folder not found %s',this_folder));
            end            
        end
              
    end 
end
