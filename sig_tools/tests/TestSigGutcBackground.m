classdef TestSigGutcBackground < matlab.unittest.TestCase
	% TestSigGutcBackground Unit and functional tests for SigGutcBackground
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigGutcBackground
        sig_tool = 'sig_gutcbackground_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
    end
    
    methods(TestMethodSetup)
        function unpackFiles(testCase)
            tar_file = fullfile(testCase.asset_path, 'custom_build.tgz');            
            untar(tar_file, testCase.result_path);
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
            % ADD TESTS FOR YOUR SIGCLASS HERE
            build_path = fullfile(testCase.result_path,...
                'custom_build', 'build');
            introspect_path = fullfile(testCase.result_path,...
                'custom_build', 'introspect');
            testCase.verifyTrue(all(isdirexist(build_path)),...
                sprintf('Build not found at %s', build_path));
            testCase.verifyTrue(all(isdirexist(introspect_path)),...
                sprintf('Introspect results not found at %s', introspect_path));

            obj = testCase.sig_class();
            obj.parseArgs('--build_path', build_path,...
                          '--introspect_path', introspect_path);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            build_path = fullfile(testCase.result_path,...
                'custom_build', 'build');
            introspect_path = fullfile(testCase.result_path,...
                'custom_build', 'introspect');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--build_path', build_path,...
                '--introspect_path', introspect_path,...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'annot/siginfo*.txt',...
                'sig/ns2ps.gctx',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end