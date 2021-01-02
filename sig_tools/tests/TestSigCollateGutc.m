classdef TestSigCollateGutc < matlab.unittest.TestCase
	% TestSigCollateGutc Unit and functional tests for SigCollateGutc
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigCollateGutc
        sig_tool = 'sig_collategutc_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
    end
    
    methods(TestClassSetup)
        function unpackFiles(testCase)
            tar_file = fullfile(testCase.asset_path, 'gutc_result.tgz');            
            untar(tar_file, testCase.result_path);
        end
    end

    methods(TestClassTeardown)
        function deleteFiles(testCase)
            rmdir(testCase.result_path, 's');
        end
    end

    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    
    methods(Test)
        function testClass(testCase)
	% ADD TESTS FOR YOUR SIGCLASS HERE            
            result_folder = fullfile(testCase.result_path, 'gutc_result');
            obj = testCase.sig_class();
            obj.parseArgs('--folder', result_folder, '--result_wildcard', '*');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'result_folders'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            result_folder = fullfile(testCase.result_path, 'gutc_result');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--skip_annot', true,...
                '--folder', result_folder, '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'matrices',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end