classdef TestSigGeneConvert < matlab.unittest.TestCase
	% TestSigGeneConvert Unit and functional tests for SigGeneConvert
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigGeneConvert
        sig_tool = 'sig_geneconvert_tool';
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
	% ADD TESTS FOR YOUR SIGCLASS HERE
            gsetFile = fullfile(testCase.asset_path, 'sets_01.gmt');
            obj = testCase.sig_class();
            obj.parseArgs('--gset', gsetFile, '--input_id', 'gene_symbol');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'map_set', 'notmap_set', 'map_meta', 'set_rpt'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.map_set), 'Mapped set not found');
            testCase.verifyTrue(isstruct(res.notmap_set), 'UnMapped set not found');
%             testCase.verifyEqual(size(res.output), [978, 371], 'Result matrix size mismatch');
        end
        
        %Testing GCT/GCTX row id conversion (AIG space)
        function testMatrixAigSpace(testCase)    
            dsFile = fullfile(testCase.asset_path, ...
                'affx_example_data_n25x22268.gctx');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--input_id', 'affx', ...
                '--output_id', 'gene_id', '--feature_space', 'aig');
            obj.runAnalysis
            res = obj.getResults;
            reqFields = {'args', 'map_set', 'notmap_set', 'map_meta', ...
                'set_rpt', 'ds'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.map_set), 'Mapped set not found');
            testCase.verifyTrue(isstruct(res.notmap_set), 'UnMapped set not found');
              gnd_truth_ds = parse_gctx(fullfile(testCase.asset_path, ...
                  'gene_id_example_data_n25x12328.gctx'), ...
                  'id_only', 1);
              %gnd_truth_ids = cellfun(@str2num, gnd_truth_ds.rid);
              %result_ids = cellfun(@str2num, res.ds.rid); 
              %testCase.verifyEqual(gnd_truth_ids, result_ids);
              testCase.verifyEqual(gnd_truth_ds.rid, res.ds.rid);
              testCase.verifyEqual(gnd_truth_ds.cid, res.ds.cid);
        end      
        
           %Testing GCT/GCTX row id conversion (lm space)
        function testMatrixLmSpace(testCase)    
            dsFile = fullfile(testCase.asset_path, ...
                'affx_example_data_n25x22268.gctx');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--feature_space', 'lm'); %input/output_id default test
            obj.runAnalysis
            res = obj.getResults;
            reqFields = {'args', 'map_set', 'notmap_set', 'map_meta', ...
                'set_rpt', 'ds'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.map_set), 'Mapped set not found');
            testCase.verifyTrue(isstruct(res.notmap_set), 'UnMapped set not found');
              gnd_truth_ds = parse_gctx(fullfile(testCase.asset_path, ...
                  'gene_id_example_data_n25x978.gctx'));
              gnd_truth_ids = cellfun(@str2num, gnd_truth_ds.rid);
              result_ids = cellfun(@str2num, res.ds.rid); 
              testCase.verifyEqual(gnd_truth_ids, result_ids);
              testCase.verifyTrue(all(all(gnd_truth_ds.mat - res.ds.mat < 0.0001)), ...
                  'Result matrix does not match ground truth');
              
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            gsetFile = fullfile(testCase.asset_path, 'sets_01.gmt');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--gset', gsetFile, '--input_id', 'gene_symbol',...
                '--out', outPath, '--create_subdir', false,...
                '--min_set_size', 10);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'mapped_n*.gmt','unmapped_n*.gmt',...
                'filtered_by_size_n*.gmt',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end