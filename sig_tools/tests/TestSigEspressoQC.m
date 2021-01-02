classdef TestSigEspressoQC < matlab.unittest.TestCase
	% TestSigEspressoQC Unit and functional tests for SigEspressoQC
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigEspressoQC
        sig_tool = 'sig_espressoqc_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
    end
    methods(TestMethodSetup)
        function unpackFiles(testCase)
            tar_file = fullfile(testCase.asset_path, 'for_espresso_qc.tgz');            
            untar(tar_file, testCase.result_path);
%             [~, dsList] = find_file(fullfile(testCase.result_path, 'for_sig_recall', '*.gctx'));            
%             mkgrp(fullfile(testCase.result_path, 'ds_list.grp'), dsList);
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
            
            proj_path = fullfile(testCase.result_path, 'for_espresso_qc');
            plate_list = fullfile(proj_path, 'espresso_plate_list.grp');

            obj = testCase.sig_class();
            obj.parseArgs('--plate_list', plate_list,...
                          '--proj_base_dir', proj_path);                      
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'plate_rpt', 'qc_rpt'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.qc_rpt), 'QC report missing');            
      end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            proj_path = fullfile(testCase.result_path, 'for_espresso_qc');
            plate_list = fullfile(proj_path, 'espresso_plate_list.grp');

            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--plate_list', plate_list,...
                '--proj_base_dir', proj_path,...
                '--out', outPath,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'plates_processed.txt',...
                'qc_report.txt',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end