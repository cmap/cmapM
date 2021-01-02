classdef TestSigFastQuery < matlab.unittest.TestCase
	% TestSigFastQuery Unit and functional tests for SigFastQuery
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigFastQuery
        sig_tool = 'sig_fastquery_tool';
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
            uptag = fullfile(testCase.asset_path, 'query_up_n1.gmt');
            dntag = fullfile(testCase.asset_path, 'query_down_n1.gmt');
            obj = testCase.sig_class();
            outPath = tempname;
            obj.parseArgs('--uptag', uptag, '--dntag', dntag, '--create_subdir', false, '--out', outPath);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'output'};
            hasReq = isfield(res, reqFields);
            %fprintf('Output directory = %s\n', outPath);
            if (res.output.support_flag)
                testCase.verifyTrue((res.output.exit_code == 0), 'Run script did not run successfully');      
                testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
                testCase.verifyTrue(isfileexist(fullfile(outPath, res.args.outfile)), ...
                    'Result dataset file not found');
                ds = parse_gct(fullfile(outPath, res.args.outfile), 'verbose', false);
                testCase.verifyEqual(size(ds.mat), [476251,1]);
            else
               fprintf('CPU does not meet requirements. Passing tests...\n'); 
            end
        end                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE

            uptag = fullfile(testCase.asset_path, 'query_up_n1.gmt');
            dntag = fullfile(testCase.asset_path, 'query_down_n1.gmt');
            outPath = tempname;
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--uptag', uptag, '--dntag', dntag, ... 
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            
            %check for cpu support
            fid = fopen(fullfile(outPath, 'support.txt'), 'r');
            support = fscanf(fid, '%d');
            fclose(fid);
            
            if (support == 1)
                output_files = {'result.gct',...
                    'config.yaml', 'success.txt'};
                for ii=1:length(output_files)
                    this_file = fullfile(outPath, output_files{ii});
                    [fn, fp] = find_file(this_file);
                    testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
                end
            else
               fprintf('CPU does not meet requirements. Passing tests...\n'); 
            end
        end
              
    end 
end
