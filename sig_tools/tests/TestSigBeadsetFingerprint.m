classdef TestSigBeadsetFingerprint < matlab.unittest.TestCase
	% TestSigBeadsetFingerprint Unit and functional tests for SigBeadsetFingerprint
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigBeadsetFingerprint
        sig_tool = 'sig_beadsetfingerprint_tool';
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
            inPath = testCase.asset_path;
            obj = testCase.sig_class();
            obj.parseArgs('--in', inPath,...
                '--map', '/cmap/data/vdb/beadset_fingerprint/bead_map.txt',...
                '--wildcard', 'DEV_BCHECK*.csv');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            inPath = testCase.asset_path;
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--in', inPath ,...
                '--map', '/cmap/data/vdb/beadset_fingerprint/bead_map.txt',...
                '--wildcard', 'DEV_BCHECK*.csv',...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'heatmap/targetcount_*.png',...
                'total_count/count_*.txt'
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end