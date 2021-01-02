classdef TestSigDevGutcPercentile < matlab.unittest.TestCase
	% TestSigDevGutcPercentile Unit and functional tests for SigDevGutcPercentile
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigDevGutcPercentile
        sig_tool = 'sig_devgutcpercentile_tool';
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
            dsFile = fullfile(testCase.asset_path, 'ncsagg_n1000x100.gctx');
            rowMetaFile = fullfile(testCase.asset_path, 'ncsagg_row.txt');
            columnMetaFile = fullfile(testCase.asset_path, 'ncsagg_column.txt');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile,...
                          '--row_meta', rowMetaFile,...
                          '--column_meta', columnMetaFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
        end
                
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            dsFile = fullfile(testCase.asset_path, 'ncsagg_n1000x100.gctx');
            rowMetaFile = fullfile(testCase.asset_path, 'ncsagg_row.txt');
            columnMetaFile = fullfile(testCase.asset_path, 'ncsagg_column.txt');
            ridFile = fullfile(testCase.asset_path, 'ncsrid.grp');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', dsFile ,'--row_meta', rowMetaFile, ...
                '--column_meta', columnMetaFile,...
                '--match_field', 'pert_type',...
                '--rid', ridFile,...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'norm.gctx', 'norm2ps.gctx', 'stats.gctx',...
                'config.yaml', 'success.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
 
    end 
end