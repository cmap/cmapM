classdef TestSigMakePhenos < matlab.unittest.TestCase

    properties
        sig_class = @mortar.sigtools.SigMakePhenos
        sig_tool = 'sig_makephenos_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testPhenotypeGen(testCase)
            infoFile = fullfile(testCase.asset_path, 'test_instinfo.txt');
            obj = testCase.sig_class();
            obj.parseArgs('--instinfo', infoFile, 'trt_params', 'pert_itime');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(istable(res.phenotypes), 'Result table not found');
            result = parse_record(fullfile(testCase.asset_path, 'result_phenotypes.txt'));
            [ncombs,~] = size(result);
            testCase.verifyEqual(height(res.phenotypes), ncombs, ...
                'Resulting infofile size mismatch');
            testCase.verifyEqual(numel(res.phenotypes.Properties.VariableNames), numel(fieldnames(result)), ...
                'Resulting infofile size mismatch');

        end
        
        function testSiginfoFile(testCase)
            infoFile = fullfile(testCase.asset_path, 'test_instinfo.txt');
            obj = testCase.sig_class();
            obj.parseArgs('--instinfo', infoFile, 'trt_params', 'pert_itime');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(istable(res.phenotypes), 'Result table not found');
            n_sigids = numel(unique(res.phenotypes.sig_id));
            testCase.verifyEqual(numel(res.siginfo.sig_id), n_sigids, ...
                'Siginfo file length mismatch');
        end
                
        function testDemoTool(testCase)
            infoFile = fullfile(testCase.asset_path, 'test_instinfo.txt');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--instinfo', infoFile ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'phenotypes.txt',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end