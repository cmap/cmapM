classdef TestSigCollateBuild < matlab.unittest.TestCase
	% TestSigCollateBuild Unit and functional tests for SigCollateBuild
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigCollateBuild
        sig_tool = 'sig_collatebuild_tool';
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
            src_folder = fullfile(testCase.asset_path, 'test_build/');
            targ_folder = fullfile(testCase.asset_path, 'test_build2/');
            obj = testCase.sig_class();
            obj.parseArgs('--src', src_folder, '--target', targ_folder);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');                  
            
            [nr,~] = size(res.output);
            for i=1:nr
                switch upper(res.output{i,1})
                    case 'GCT'
                        testCase.verifyTrue(isds(res.output{i,3}), ...
                            'Result dataset not found');
                        testCase.verifyEqual(size(res.output{i,3}.mat), [978, 10],...
                            'Result matrix size mismatch');
                    case 'GCTX'
                        testCase.verifyTrue(isds(res.output{i,3}), ...
                            'Result dataset not found');
                        testCase.verifyEqual(size(res.output{i,3}.mat), [978, 10],...
                            'Result matrix size mismatch');
                    case 'TXT'
                        testCase.verifyEqual(numel(res.output{i,3}), 10,...
                            'Result table size mismatch');
                    case 'GMT'
                        testCase.verifyEqual(numel(res.output{i,3}), 10,...
                            'Result geneset size mismatch');
                    otherwise
                        continue
                end
            end        
        end
                
        function testDemoTool(testCase)
            src_folder = fullfile(testCase.asset_path, 'test_build/');
            targ_folder = fullfile(testCase.asset_path, 'test_build2/');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--src', src_folder, '--target', targ_folder,...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end