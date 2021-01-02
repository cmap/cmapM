classdef TestSigPclEval < matlab.unittest.TestCase
	% TestSigPclEval Unit and functional tests for SigPclEval
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigPclEval
        sig_tool = 'sig_pcleval_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        pcl_file = 'pcl_n5.gmt';
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testClass(testCase)
	% ADD TESTS FOR YOUR SIGCLASS HERE
%             pclFile = fullfile(testCase.asset_path, testCase.pcl_file);
%             obj = testCase.sig_class();
%             obj.parseArgs('--pcl', pclFile);
%             obj.runAnalysis;
%             res = obj.getResults;
%             reqFields = {'args', 'rpt', 'mu','sigma','p25','p75'};
%             hasReq = isfield(res, reqFields);
%             testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
%             dsFiles = {'mu','sigma','p25','p75'};
%             for ii=1:length(dsFiles)
%                 this = res.(dsFiles{ii});
%                 testCase.verifyTrue(isds(this), 'Result dataset not found:%s',dsFiles{ii});
%                 testCase.verifyEqual(size(this.mat), [5, 10], 'Result matrix size mismatch');
%             end            
        end

         function testDSinput(testCase)
	% ADD TESTS FOR YOUR SIGCLASS HERE
%             pclFile = fullfile(testCase.asset_path, testCase.pcl_file);
%             obj = testCase.sig_class();
%             obj.parseArgs('--pcl', pclFile);
%             obj.runAnalysis;
%             res = obj.getResults;
%             reqFields = {'args', 'rpt', 'mu','sigma','p25','p75'};
%             hasReq = isfield(res, reqFields);
%             testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
%             dsFiles = {'mu','sigma','p25','p75'};
%             for ii=1:length(dsFiles)
%                 this = res.(dsFiles{ii});
%                 testCase.verifyTrue(isds(this), 'Result dataset not found:%s',dsFiles{ii});
%                 testCase.verifyEqual(size(this.mat), [5, 10], 'Result matrix size mismatch');
%             end            
        end
        
        function testDemoTool(testCase)
            pclFile = fullfile(testCase.asset_path, testCase.pcl_file);
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--pcl', pclFile ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            result_folders = union({'inter_cell', 'pcl_pages', 'SUMMLY'},...
                mortar.common.Spaces.cell('lincs_core').asCell,...
                'stable');
            for ii=1:length(result_folders)
                this_folder = fullfile(outPath, result_folders{ii});
                [fn, fp] = find_file(this_folder);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_folder));
            end
        end
              
    end 
end