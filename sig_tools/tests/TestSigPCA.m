classdef TestSigPCA < matlab.unittest.TestCase
    properties
        sig_class = @mortar.sigtools.SigPCA
        sig_tool = 'sig_pca_tool';
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
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--sample_dim', 'column');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args','pc_coeff','pc_score','pc_var','pct_explained','col_mean'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            
            testCase.verifyTrue(isds(res.pc_coeff), 'Coeff matrix not found');
            testCase.verifyEqual(size(res.pc_coeff.mat), [978, 370], 'Coeff matrix size mismatch');
            testCase.verifyEqual(size(res.pc_score.mat), [371, 370], 'PC Score matrix size mismatch');
            testCase.verifyEqual(size(res.pc_var.mat), [370, 1], 'PC Var matrix size mismatch');
            testCase.verifyEqual(size(res.pct_explained.mat), [370, 1], 'PCT Explained matrix size mismatch');
            testCase.verifyEqual(size(res.col_mean.mat), [1, 978], 'Col Mean matrix size mismatch');
        end
                
        function testDemoBin(testCase)
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            dsMetaFile = fullfile(testCase.asset_path, 'column_meta_n371.txt');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile, '--sample_dim', 'column',...
                '--ds_meta', dsMetaFile,...
                '--row_space', 'lm_probeset',...
                '--out', outPath, '--create_subdir', false,...
                '--disable_table', false);
            dbg(1, '## %s', cmdStr);
            eval(cmdStr);
            output_files = {'pca.txt', 'pc_coeff_n*.gct*',...
                'pc_score_n*.gct*', 'pc_var_n1x*.gct*'...
                'pct_explained_n1x*.gct*',...
                'col_mean_n*x1.gct*',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            dbg(1, '## Done');
        end
              
    end 
end