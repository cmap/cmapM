classdef TestSigGetGenesets < matlab.unittest.TestCase
    properties
        sig_class = @mortar.sigtools.SigGetGenesets
        sig_tool = 'sig_getgenesets_tool';
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
            dsFile = fullfile(testCase.asset_path , 'gene_id_example_data_n25x12328.gctx');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, ...
                '--set_size', 50, ...
                '--row_space', 'lm');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            gmtFields = {'head', 'desc', 'entry', 'len'};
            up_isGMT = isfield(res.up, gmtFields);
            dn_isGMT = isfield(res.dn, gmtFields);
            testCase.verifyTrue(all(up_isGMT), 'up output does not have GMT fields');      
            testCase.verifyTrue(all(dn_isGMT), 'dn output does not have GMT fields');
            up_result = parse_gmt(fullfile(testCase.asset_path , 'result_up_n25.gmt'));
            dn_result = parse_gmt(fullfile(testCase.asset_path , 'result_dn_n25.gmt'));
            for i=1:numel(res.up)
                testCase.verifyTrue(all(cellfun(@strcmp, up_result(i).entry, res.up(i).entry)),...
                    'Mismatched values between result and ground truth');
            end
            for i=1:numel(res.dn)
                testCase.verifyTrue(all(cellfun(@strcmp, dn_result(i).entry, res.dn(i).entry)),...
                    'Mismatched values between result and ground truth');
            end
        end
                
        function testDemoTool(testCase)
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'up_n*.gmt', 'down_n*.gmt',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end