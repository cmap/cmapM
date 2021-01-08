classdef TestSigRandomSet < matlab.unittest.TestCase
	% TestSigRandomSet Unit and functional tests for SigRandomSet
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       
    % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigRandomSet
        sig_tool = 'sig_randomset_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testSingleCustomUniverse(testCase)
            num_sets = 5;
            set_size = 50;
            touchstone = '/cmap/data/vdb/touchstone/touchstone.grp';
            outPath = tempname;
            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--num_sets',num_sets,'--set_size',set_size,'--rid',touchstone,'--out',outPath,...
                'single_sided',true,'--create_subdir',false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'random*.gmt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, ~] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
                testCase.verifyNumElements(output_files,1);
            end
        end
        
        function testMakeGrp(testCase)
            num_sets = 1;
            set_size = 10;
            outPath = tempname;
            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--num_sets',num_sets,'--set_size',set_size,'--feature_space','bing','--out',outPath,...
                '--make_grp',true,'--create_subdir',false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'random.grp'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, ~] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
        end
                
        
        function testDemoTool(testCase)
            
            num_sets = 5;
            set_size = 50;
            ps = 'lm';
            outPath = tempname;
            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--num_sets',num_sets,'--set_size',set_size,'--feature_space',ps,'--out',outPath,...
                'single_sided',false,'--create_subdir',false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'random*.gmt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, ~] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            
        end
              
    end 
end