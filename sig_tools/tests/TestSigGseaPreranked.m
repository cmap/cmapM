classdef TestSigGseaPreranked < matlab.unittest.TestCase
	% TestSigGseaPreranked Unit and functional tests for SigGseaPreranked
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       
    % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigGseaPreranked
        sig_tool = 'sig_gseapreranked_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
        score_file = 'SET_LATER';
        set_file = 'SET_LATER';
    end
    methods(TestMethodSetup)
        function setVariables(testCase)
            testCase.set_file = fullfile(testCase.asset_path, 'hallmark_sig_sets_n188.gmt');
            testCase.score_file = fullfile(testCase.asset_path, 'ncs_mcf7_frasor_er_n1x38773.gctx');
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
            obj = testCase.sig_class();
            obj.parseArgs('--score', testCase.score_file, '--up', testCase.set_file);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'query_result', 'nes_result', 'fdr_result'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.query_result.cs), 'Result dataset not found');
            testCase.verifyTrue(isds(res.nes_result), 'Result dataset not found');
            %testCase.verifyEqual(size(res.output), [978, 371], 'Result matrix size mismatch');
        end
                
        function testDemoTool(testCase)
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--score', testCase.score_file,...
                '--up', testCase.set_file,...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            % folders
            output_folders = {'matrices', 'arfs'};
            for ii=1:length(output_folders)
                this_folder = fullfile(outPath, output_folders{ii});
                tf = mortar.util.File.isfile(this_folder, 'dir');
                testCase.verifyTrue(tf, sprintf('Folder not found %s',this_folder));
            end
            
        end
              
    end 
end