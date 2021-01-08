classdef TestSigMarker < matlab.unittest.TestCase
    properties
        sig_class = @mortar.sigtools.SigMarker
        sig_tool = 'sig_marker_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testMarker(testCase)
            dsFile = fullfile(testCase.asset_path, 'qnorm_n27x22268.gctx');
            phenoFile = fullfile(testCase.asset_path, 'phenotype_def_1.txt');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--phenotype', phenoFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args','sig','full_score','up_set','dn_set','stats'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            
            testCase.verifyTrue(isds(res.full_score), 'Score matrix not found');
            testCase.verifyEqual(size(res.full_score.mat), [22268, 2], 'Score matrix size mismatch');
        end
        
        function testMarkerLM(testCase)
            % restrict feature space
            dsFile = fullfile(testCase.asset_path, 'qnorm_n27x22268.gctx');
            phenoFile = fullfile(testCase.asset_path, 'phenotype_def_1.txt');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile,...
                          '--phenotype', phenoFile,...
                          '--feature_space', 'lm_probeset');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args','sig','full_score','up_set','dn_set','stats'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');            
            testCase.verifyTrue(isds(res.full_score), 'Score matrix not found');
            testCase.verifyEqual(size(res.full_score.mat), [978, 2], 'Score matrix size mismatch');
            testCase.verifyTrue(all(ismember(res.full_score.rid,...
                                    mortar.common.Spaces.probe('lm_probeset').asCell)),...
                                    'Feature space mismatch');
        end
        
        function testDemoBin(testCase)
            dbg(1, '## Running demo ...');
            dsFile = fullfile(testCase.asset_path, 'qnorm_n27x22268.gctx');
            phenoFile = fullfile(testCase.asset_path, 'phenotype_def_1.txt');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile, '--phenotype', phenoFile,...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '#CMD:', cmdStr);
            eval(cmdStr);
            output_files = {'matrices', 'config.yaml', 'index.html', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            dbg(1, '## Done');
        end
    end 
end