classdef TestSig2DCluster < matlab.unittest.TestCase

    properties
        sig_class = @mortar.sigtools.Sig2DCluster
        sig_tool = 'sig_2dcluster_tool';
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
            ds_tani = fullfile(testCase.asset_path, 'trt_cp_tani_n14x14.gctx');
            obj = testCase.sig_class();
            outPath = tempname;
            obj.parseArgs('--create_subdir', 0, '--out', outPath, '--generate_figures', 0, ...
                            '--ds_tani', ds_tani, '--tani_threshold', 0.99);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'gmt', 'gmtn'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
                        
            %gmt = parse_gmt(fullfile(outPath,'clusters_v7.gmt'));
            %gmtn = parse_gmt(fullfile(outPath,'clusters_v7_names.gmt'));
            gmt = res.siml_groups;
            gmtn = res.siml_groups_names;
            gmt_ref = parse_gmt(fullfile(testCase.asset_path, 'sig_2dclusters_tool_ids.gmt'));
            gmtn_ref = parse_gmt(fullfile(testCase.asset_path, 'sig_2dclusters_tool_inames.gmt'));
            testCase.verifyEqual(gmt,gmt_ref, 'GMT file with pert_ids does not match the reference file.')
            testCase.verifyEqual(gmtn,gmtn_ref, 'GMT file with pert_inames does not match the reference file.')
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            ds_tani = fullfile(testCase.asset_path, 'trt_cp_tani_n14x14.gctx');
            ds_gex = fullfile(testCase.asset_path, 'trt_cp_gex_n14x14.gctx');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--create_subdir', 0, '--out', outPath, '--generate_figures', 1, ...
                '--ds_tani', ds_tani, '--tani_threshold', 0.99, '--ds_gex', ds_gex);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            fprintf('Consider deleting directory %s\n\n', outPath)
        end
    end 
end