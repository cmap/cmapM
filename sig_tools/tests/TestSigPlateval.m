classdef TestSigPlateval < matlab.unittest.TestCase
	% TestSigPlateval Unit and functional tests for SigPlateval
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigPlateval
        sig_tool = 'sig_plateval_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
    end
    methods(TestMethodSetup)
        function unpackFiles(testCase)
            tar_file = fullfile(testCase.asset_path, 'for_plateval.tgz');            
            untar(tar_file, testCase.result_path);
%             [~, dsList] = find_file(fullfile(testCase.result_path, 'for_sig_recall', '*.gctx'));            
%             mkgrp(fullfile(testCase.result_path, 'ds_list.grp'), dsList);
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
            plate = 'KDC004_A375_96H_X1_B5';
            lxb_path = fullfile(testCase.result_path, 'for_plateval', 'lxb');
            map_src_path = fullfile(testCase.result_path, 'for_plateval', 'map_src');
            obj = testCase.sig_class();
            obj.parseArgs('--plate', plate,...
                          '--lxb_path', lxb_path,...
                          '--map_src_path', map_src_path);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'map_rpt', 'lxb_rpt'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.map_rpt), 'Map source report missing');
            testCase.verifyEqual(length(res.lxb_rpt), 1, 'LXB report missing');
      end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            plate = 'KDC004_A375_96H_X1_B5';
            lxb_path = fullfile(testCase.result_path, 'for_plateval', 'lxb');
            map_src_path = fullfile(testCase.result_path, 'for_plateval', 'map_src');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--plate', plate,...
                '--lxb_path', lxb_path,...
                '--map_src_path', map_src_path,...
                '--out', outPath,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'map_report.txt',...
                'lxb_report.txt',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end