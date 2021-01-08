classdef TestSigSMI2FP < matlab.unittest.TestCase
    properties
        sig_class = @mortar.sigtools.SigSMI2FP
        sig_tool = 'sig_smi2fp_tool';
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
            dsFile = fullfile(testCase.asset_path, 'trt_cp_input.csv');
            obj = testCase.sig_class();
            outPath = tempname;
            obj.parseArgs('--create_subdir', 0, '--out', outPath, '--icsv', dsFile, '--ogctx', 'trt_cp_output.gctx');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'status'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            testCase.verifyEqual(res.status, 0, 'Python tool exited with an error');
            
            ds = parse_gctx(fullfile(outPath,'trt_cp_output.gctx'));
            ds.src = [];
            ds_verified = parse_gctx(fullfile(testCase.asset_path, 'trt_cp_output.gctx'));
            ds_verified.src = [];
            testCase.verifyEqual(ds, ds_verified, 'GCTX file does NOT match the reference file.')
            sprintf('Consider deleting directory %s', outPath)
            
        end
                
        function testDemoBin(testCase)
            dsFile = fullfile(testCase.asset_path, 'trt_cp_input.csv');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--create_subdir', 0, '--out', outPath,...
                '--icsv', dsFile, '--ogctx', 'trt_cp_output.gctx');
            dbg(1, '## %s', cmdStr);
            eval(cmdStr);
            dbg(1, '## Done');
            sprintf('Consider deleting directory %s', outPath)
        end
              
    end 
end