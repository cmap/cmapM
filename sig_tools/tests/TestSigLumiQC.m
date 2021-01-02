classdef TestSigLumiQC < matlab.unittest.TestCase
	% TestSigLumiQC Unit and functional tests for SigLumiQC
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigLumiQC
        sig_tool = 'sig_lumiqc_tool';
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
            csvFile = fullfile(testCase.asset_path, 'Test_lumiqc_fix.csv');
            out_path = tempname;
            obj = testCase.sig_class();
            obj.parseArgs('--in', csvFile, '--out', out_path,...
                        '--create_subdir', false);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
        out_path = tempname;
        csv_file = fullfile(testCase.asset_path, 'Test_lumiqc_fix.csv');   
        cmdStr = print_cmdline(testCase.sig_tool,...
                        '--in', csv_file,...
                        '--out', out_path,...
                        '--create_subdir', false,...
                        '--cal_ymax', 5000);
            eval(cmdStr);
            expected_files = {'well_median_raw.png', 'calibplot.png', 'beadset_ctrl.png',...
                'drspan.png', 'invset_confmatrix.png', 'invset_medexp.png', 'legend_plate_ptype.png',...
                'med_count.png', 'mfi_ctrl.png', 'plate_count.png', 'plate_ptype.png', ...
                'qc_level10.png', 'qc_plate_flogp.png', 'qc_plate_iqr.png', 'qc_plate_q1.png',...
                'quantiles_raw.png', 'stripe_o_gram_score.png', 'well_scaled_median.png', 'mfi_rows.png',...
                'mfi_columns.png'};
            
            for i = 1:length(expected_files)
                this_file = fullfile(out_path, expected_files{i});
                assert(mortar.util.File.isfile(this_file, 'file'),...
                    'File missing: %s', this_file);
                file_size = dir(this_file);
                assert(file_size.bytes > 0, 'File is empty : %s',...
                    this_file);            
            end 
        end
              
    end 
end