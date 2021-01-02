classdef TestSigGutcARF < matlab.unittest.TestCase
	% TestSigGutcARF Unit and functional tests for SigGutcARF
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigGutcARF
        sig_tool = 'sig_gutcarf_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
    end
    
    methods(TestMethodSetup)
        function unpackFiles(testCase)
            tar_file = fullfile(testCase.asset_path, 'gutc_result.tgz');            
            untar(tar_file, testCase.result_path);
        end
    end
    
    methods(TestMethodTeardown)
        function deleteFiles(testCase)
            rmdir(testCase.result_path, 's');
        end
    end
    
    methods(Test)
                    
        function testClass(testCase)
	% ADD TESTS FOR YOUR SIGCLASS HERE
            result_folder = fullfile(testCase.result_path,...
                                        'gutc_result', 'input_1');            
            testCase.verifyTrue(all(isdirexist(result_folder)),...
                sprintf('Gutc results not found at %s', testCase.result_path));
            obj = testCase.sig_class();
            obj.parseArgs('--inpath', result_folder);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
        end
        
        function testArfByPert(testCase)                        
            result_folder = fullfile(testCase.result_path,...
                'input_per_cp');
            query_meta_file = fullfile(result_folder, 'query_info.txt');
            outPath = tempname;
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--inpath', result_folder,...
                '--query_meta', query_meta_file,...
                'make_arf_by_pert', true,...
                '--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'BRD-K02404261',...
                'config.yaml', 'index.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            arf_files = {'query_info.txt',...
                'pcl_cell.gct', 'pcl_summary.gct',...
                'pert_id_cell.gct', 'pert_id_summary.gct'};
            arf_path = fullfile(outPath, 'BRD-K02404261');
            narf_files = length(arf_files);
            for ii=1:narf_files
                this_file = fullfile(arf_path, arf_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end            
        end
        
        function testDemoTool(testCase)
	% ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            result_folder = fullfile(testCase.result_path,...
                'gutc_result', 'input_1');
            outPath = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--inpath', result_folder ,'--out', outPath, '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = {'REP.A001_A375_24H_DMSO_-666',...
                'config.yaml', 'index.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            arf_files = {'query_info.txt',...
             'pcl_cell.gct', 'pcl_summary.gct',...
             'pert_id_cell.gct', 'pert_id_summary.gct'};
            arf_path = fullfile(outPath, 'REP.A001_A375_24H_DMSO_-666');
            narf_files = length(arf_files);
            for ii=1:narf_files
                this_file = fullfile(arf_path, arf_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
         
        end
              
    end 
end