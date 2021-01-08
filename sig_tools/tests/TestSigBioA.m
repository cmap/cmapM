classdef TestSigBioA < matlab.unittest.TestCase
	% TestSigBioA Unit and functional tests for SigBioA
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigBioA
        sig_tool = 'sig_bioa_tool';
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
            dsFile = fullfile(testCase.asset_path, 'bioa_siginfo.txt');
            obj = testCase.sig_class();
            obj.parseArgs('--siginfo', dsFile, '--tas_field', 'tas_median');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'outtable', 'siginfo', 'cnt_tas_bins', 'tas_bins'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isstruct(res.outtable), 'Result table not found');
            testCase.verifyEqual(size(res.outtable), [numel(unique({res.siginfo.pert_iname})), 1], 'Result table size mismatch');
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            dsFile = fullfile(testCase.asset_path, 'bioa_siginfo.txt');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--siginfo', dsFile ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'pert_stats.txt','SC_plot*.png', 'TAS_vs_Recall_Rank*.png'...
                'Active_Signatures_Distribution*.png', 'gallery.html', 'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end