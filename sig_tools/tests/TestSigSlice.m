classdef TestSigSlice < matlab.unittest.TestCase
    properties
        sig_class = @mortar.sigtools.SigSlice;
        sig_tool = 'sig_slice_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        
        function testSliceSubset(testCase)
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            cidFile = fullfile(testCase.asset_path, 'gctv13_01_colsubset_n10.grp');
            ridFile = fullfile(testCase.asset_path, 'gctv13_01_rowsubset_n10.grp');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--cid', cidFile, '--rid', ridFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'ds'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            rid = parse_grp(ridFile);
            cid = parse_grp(cidFile);            
            testCase.verifyEqual(res.ds.rid, rid, 'Row id mismatch');
            testCase.verifyEqual(res.ds.cid, cid, 'Column id mismatch');
        end        
        
        function testSliceRowSpace(testCase)
            dsFile = fullfile(testCase.asset_path, 'qnorm_n27x22268.gctx');
            lmspace = parse_grp(fullfile(testCase.asset_path, 'lm_epsilon_n978.grp'));
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--row_space', 'lm_probeset');
            obj.runAnalysis;
            res = obj.getResults;
            testCase.verifyTrue(all(ismember(res.ds.rid, lmspace)), 'Row space mismatch');
        end
        
        function testDemoClass(testCase)
            dbg(1, '## Running demo ...');
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            cidFile = fullfile(testCase.asset_path, 'gctv13_01_colsubset_n10.grp');
            ridFile = fullfile(testCase.asset_path, 'gctv13_01_rowsubset_n10.grp');
            outPath = tempname;
            obj = testCase.sig_class();
            obj.run('--ds', dsFile, '--cid', cidFile, '--rid', ridFile, '--out', outPath, '--create_subdir', false);
            output_files = {'config.yaml', 'success.txt', 'gctv13_01_n10x10.gctx'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            dbg(1, '## Done');
        end
        
        function testDemoBin(testCase)
            dbg(1, '## Running demo ...');            
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            cidFile = fullfile(testCase.asset_path, 'gctv13_01_colsubset_n10.grp');
            ridFile = fullfile(testCase.asset_path, 'gctv13_01_rowsubset_n10.grp');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile, '--cid', cidFile,...
                '--rid', ridFile, '--out', outPath,...
                '--create_subdir', false);
            eval(cmdStr);
            output_files = {'config.yaml', 'success.txt', 'gctv13_01_n10x10.gctx'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            dbg(1, '## Done');
        end
    end 
end