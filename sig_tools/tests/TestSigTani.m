classdef TestSigTani < matlab.unittest.TestCase

    properties
        sig_class = @mortar.sigtools.SigTani
        sig_tool = 'sig_tani_tool';
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
            dsFile = fullfile(testCase.asset_path, 'trt_cp_output.gctx');
            obj = testCase.sig_class();
            outPath = tempname;
            obj.parseArgs('--create_subdir', 0, '--out', outPath, '--igctx', dsFile, '--ogct', 'tani.gct');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'ds'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.ds), 'Result dataset not found');
            obj.saveResults

            ds = parse_gct(fullfile(outPath,'tani_n10x10.gct'));
            ds_verified = parse_gct(fullfile(testCase.asset_path, 'trt_cp_output_tani_n10x10.gct'));
            testCase.verifyEqual(ds.mat, ds_verified.mat, 'Matrix in the GCT file with Tanimoto coefficients does NOT match the one in the reference file.')
            testCase.verifyEqual(ds.rid, ds_verified.rid, 'RIDs in the file with Tanimoto coefficients do NOT match the ones in the reference file.')
            testCase.verifyEqual(ds.cid, ds_verified.cid, 'CIDs in the file with Tanimoto coefficients do NOT match the ones in the reference file.')
            sprintf('Consider deleting directory %s', outPath)
        end
                
         function testDemoTool(testCase)
            dsFile = fullfile(testCase.asset_path, 'trt_cp_output.gctx');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--create_subdir', 0, '--out', outPath,...
                '--igctx', dsFile, '--ogctx', 'tani.gctx', '--ts', 1);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            sprintf('Consider deleting directory %s', outPath)
         end
    end 
end