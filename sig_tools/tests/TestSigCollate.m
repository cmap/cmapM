classdef TestSigCollate < matlab.unittest.TestCase
    properties
        sig_class = @mortar.sigtools.SigCollate
        sig_tool = 'sig_collate_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testCollateFiles(testCase)
            fileList = {'gctv13_subset1.gctx';...
                        'gctv13_subset2.gctx';...
                        'gctv13_subset3.gctx'};
            expFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            out_path = tempname;
            obj = testCase.sig_class();
            obj.parseArgs('--files', fileList,...
                '--parent_folder', testCase.asset_path,...
                '--out', out_path, '--create_subdir', false);
            obj.runAnalysis;
            obj.saveResults;
            res = obj.getResults;
            reqFields = {'args','file_list', 'out_file'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            
            % check collated file
            exp_ds = parse_gctx(expFile);
            res_ds = parse_gctx(res.out_file);
            testCase.verifyTrue(gctcomp(exp_ds, res_ds), 'Collated matrix is not accurate');
        end
                
        function testDemoBin(testCase)
            fileList = fullfile(testCase.asset_path, 'files_to_collate.grp');
            expFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            out_path = tempname;
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--files', fileList, '--parent_folder', testCase.asset_path,...
                '--out', out_path, '--create_subdir', false');
            
            dbg(1, cmdStr)
            eval(cmdStr);
            output_files = {'config.yaml', 'success.txt',...
                            'result_n371x978.gctx', 'filelist_n3.grp'};
            for ii=1:length(output_files)
                this_file = fullfile(out_path, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            res_ds_file = fullfile(out_path, 'result_n371x978.gctx');
            exp_ds = parse_gctx(expFile);
            res_ds = parse_gctx(res_ds_file);
            testCase.verifyTrue(gctcomp(exp_ds, res_ds), 'Collated matrix is not accurate');

            dbg(1, '## Done');            
        end
        
        function collatePartialOverrlap(testCase)
            fileList = {'gctv13_subset1.gctx';...
                        'gctv13_subset2_partial.gctx'};
            expFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            out_path = tempname;
            obj = testCase.sig_class();
            obj.parseArgs('--files', fileList,...
                '--parent_folder', testCase.asset_path,...
                '--out', out_path, '--create_subdir', false,...
                '--merge_partial', true);
            obj.runAnalysis;
            obj.saveResults;
            res = obj.getResults;
            reqFields = {'args','file_list', 'out_file'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            
        end
        
    end 
end