classdef TestSigTSNE < matlab.unittest.TestCase
    properties
        sig_class = @mortar.sigtools.SigTSNE;
        sig_tool = 'sig_tsne_tool';
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
            obj.parseArgs('--ds', dsFile, 'row_space', 'lm_probeset');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args','ds','cost'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');            
            testCase.verifyTrue(isds(res.ds), 'Tsne result not found');
            testCase.verifyEqual(size(res.ds.mat), [371, 2], 'TSNE result size mismatch');
        end
        
        function testMissingVal(testCase)
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            obj = testCase.sig_class();
            ds = parse_gctx(dsFile);
            ds.mat(randsample(numel(ds.mat), 10)) = nan;
            obj.parseArgs('--ds', ds, '--missing_action', 'impute');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args','ds','cost'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            testCase.verifyTrue(isds(res.ds), 'Tsne result not found');
            testCase.verifyEqual(size(res.ds.mat), [371, 2], 'TSNE result size mismatch');
        end
        
        function testBarnesHut(testCase)
            dsFile = fullfile(testCase.asset_path, 'qnorm_n27x22268.gctx');
            obj = testCase.sig_class();
            dsAnnot = parse_gctx(dsFile, 'annot_only', true);
            ds = parse_gctx(dsFile, 'rid', dsAnnot.rid(1:6000));
            obj.parseArgs('--ds', ds,...
                          '--sample_dim', 2,...
                          '--algorithm', 'barnes-hut',...
                          '--disable_table', true);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args','ds','cost'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');            
            testCase.verifyTrue(isds(res.ds), 'Tsne result not found');
            testCase.verifyEqual(size(res.ds.mat), [6000, 2], 'TSNE result size mismatch');
        end
        
        function testPairwise(testCase)
            dsFile = fullfile(testCase.asset_path, 'qnorm_n27x22268.gctx');
            ds = parse_gctx(dsFile);
            pw = ds_corr(ds, 'type', 'spearman');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', pw,...
                '--sample_dim', 1,...
                '--is_pairwise', true,...
                '--disable_table', true);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args','ds','cost'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            testCase.verifyTrue(isds(res.ds), 'Tsne result not found');
            testCase.verifyEqual(size(res.ds.mat), [27, 2], 'TSNE result size mismatch');
        end

        
        function testDemoBin(testCase)
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');            
            colMetaFile = fullfile(testCase.asset_path, 'column_meta_n371.txt');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                        '--ds', dsFile,...
                        '--ds_meta', colMetaFile,...
                        '--out', outPath,...
                        '--create_subdir', false,...
                        '--disable_table', false);
            eval(cmdStr);
            output_files = {'tsne_n2x371.gctx',...
                'config.yaml', 'tsne.txt', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end            
            dbg(1, '## Done');
        end
    end 
end
