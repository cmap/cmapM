classdef TestSig2to4 < matlab.unittest.TestCase
	% TestSig2to4 Unit and functional tests for Sig2to4
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.Sig2to4
        sig_tool = 'sig_2to4_tool';
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
            dsFile = fullfile(testCase.asset_path, 'level2_n376x490.gct');
            calFile = fullfile(testCase.asset_path, 'cal_n376x10.gct');
            calrefFile = fullfile(testCase.asset_path, 'log_ybio_epsilon.gct');
            level4File = fullfile(testCase.asset_path, 'level4_n376x490.gct');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--cal', calFile, '--calref', calrefFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'liss', 'level3', 'level4'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
            testCase.verifyTrue(isds(res.level4), 'Result dataset not found');
            testCase.verifyEqual(size(res.level4.mat), [490, 376], 'Result matrix size mismatch');
            level4 = parse_gctx(level4File, 'class', 'double');
            delta = abs(level4.mat(:) - res.level4.mat(:));
            % make sure values are accurate to within 4 decimal places
            testCase.verifyTrue(logical(max(delta) < 1e-4), 'Result matrix differs from expected');
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            dsFile = fullfile(testCase.asset_path, 'level2_n376x490.gct');
            calFile = fullfile(testCase.asset_path, 'cal_n376x10.gct');
            calrefFile = fullfile(testCase.asset_path, 'log_ybio_epsilon.gct');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile , '--cal', calFile, ...
                '--calref', calrefFile, '--out', outPath, ...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'level4_ZSPC_n*.gct',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
              
    end 
end