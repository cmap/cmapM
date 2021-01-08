classdef TestSigBuild < matlab.unittest.TestCase
	% TestSigBuild Unit and functional tests for SigBuild
	% Note that calling the sig_tool with --runtests executes all the tests below.
	% while --rundemo only executes tests beginning with testDemo.
	% You can add as many tests as you want. You can also have more than one demo,	       % just begin their names with testDemo

    properties
        sig_class = @mortar.sigtools.SigBuild
        sig_tool = 'sig_build_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        asset_file = 'brew_folder.tgz';
        result_path = tempname;
        build_files = {'success.txt';...
                'config.yaml';...
                'up100_aig.gmt';...
                'dn100_aig.gmt';...
                'up100_bing.gmt';...
                'dn100_bing.gmt';...
                'up50_lm.gmt';...
                'dn50_lm.gmt';...
                'geneinfo.txt';...
                'instinfo.txt';...
                'siginfo.txt';...
                'sigstats.json';...
                'sig_id.grp';...
                'distil_id.grp';...
                'zspc_n*.gctx';...
                'q2norm_n*.gctx';...
                'modzs_n*.gctx';...
                'rank_lm_n*.gctx';...
                'rank_aig_n*.gctx';...
                'rank_bing_n*.gctx'};
            
       quick_build_files = {'success.txt';...
                'config.yaml';...
                'geneinfo.txt';...
                'modzs_n*.gctx'
           };     
            
            
    end
    methods(TestMethodSetup)
        function unpackFiles(testCase)
            tar_file = fullfile(testCase.asset_path, testCase.asset_file);            
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
            brew_path = fullfile(testCase.result_path,...
                                 'brew_folder');
            brew_list = fullfile(brew_path, 'tobrew_n2.grp');
            brew_root = 'brew/pc';            
            out_path = tempname;
            obj = testCase.sig_class();
            obj.parseArgs('--brew_path', brew_path,...
                          '--brew_list', brew_list,...
                          '--brew_root', brew_root,...
                          '--out', out_path,...                          
                          '--create_subdir', false);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');      
        end
        
        function testQuickBuild(testCase)
            % Tests gene-id output
            % dose discretization
            % quick build
            brew_path = fullfile(testCase.result_path,...
                'brew_folder');
            brew_list = fullfile(brew_path, 'tobrew_n2.grp');
            brew_root = 'brew/pc';
            column_filter_file = fullfile(testCase.asset_path,...
                'filter_build_columns.gmt');
            out_path = tempname;
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--brew_path', brew_path,...
                '--brew_list', brew_list,...
                '--brew_root', brew_root,...
                '--column_filter', column_filter_file,...
                '--do_quick_build', true,...
                '--out', out_path,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = testCase.quick_build_files;
            for ii=1:length(output_files)
                this_file = fullfile(out_path, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            % test if column filter worked
            sig_info_file = fullfile(out_path, 'siginfo.txt');
            sig_info = parse_record(sig_info_file);
            has_correct_iname = all(ismember({sig_info.pert_iname}', 'physostigmine'));
            testCase.verifyTrue(has_correct_iname, 'Expected iname(s) not found');
        end
        
        function testGeneIdOutput(testCase)
            % Tests gene-id output
            % dose discretization
            % column filtering
            brew_path = fullfile(testCase.result_path,...
                'brew_folder');
            brew_list = fullfile(brew_path, 'tobrew_n2.grp');
            brew_root = 'brew/pc';
            column_filter_file = fullfile(testCase.asset_path,...
                'filter_build_columns.gmt');
            dose_list_file = fullfile(testCase.asset_path,...
                                    'dose_list_um.grp');
            out_path = tempname;
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--brew_path', brew_path,...
                '--brew_list', brew_list,...
                '--brew_root', brew_root,...
                '--feature_id', 'gene_id',...
                '--dose_list', dose_list_file,...
                '--column_filter', column_filter_file,...
                '--out', out_path,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = testCase.build_files;
            for ii=1:length(output_files)
                this_file = fullfile(out_path, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            % test if column filter worked
            sig_info_file = fullfile(out_path, 'siginfo.txt');
            sig_info = parse_record(sig_info_file);
            has_correct_iname = all(ismember({sig_info.pert_iname}', 'physostigmine'));
            testCase.verifyTrue(has_correct_iname, 'Expected iname(s) not found');
            
           [~, modz_file] = find_file(fullfile(out_path, 'modzs_n*.gctx'));
           gene_info = parse_record(fullfile(out_path, 'geneinfo.txt'), 'detect_numeric', false);
           modz_ds = parse_gctx(modz_file{1});           
           gene_diff = setdiff(modz_ds.rid, {gene_info.pr_gene_id}');
           testCase.verifyEmpty(gene_diff, 'Incorrect gene-ids in output');           
        end
        
        function testDemoTool(testCase)
            % ADD A DEMO ILLUSTRATING USE OF YOUR SIGTOOL HERE
            brew_path = fullfile(testCase.result_path,...
                                 'brew_folder');
            brew_list = fullfile(brew_path, 'tobrew_n2.grp');
            brew_root = 'brew/pc';
            column_filter_file = fullfile(testCase.asset_path,...
                                    'filter_build_columns.gmt');
            out_path = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--brew_path', brew_path,...
                '--brew_list', brew_list,...
                '--brew_root', brew_root,...
                '--column_filter', column_filter_file,...
                '--out', out_path,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = testCase.build_files;
            for ii=1:length(output_files)
                this_file = fullfile(out_path, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            % test if column filter worked
            sig_info_file = fullfile(out_path, 'siginfo.txt');
            sig_info = parse_record(sig_info_file);
            has_correct_iname = all(ismember({sig_info.pert_iname}', 'physostigmine'));
            testCase.verifyTrue(has_correct_iname, 'Expected iname(s) not found');            
        end              
        
        function testBrewWithDuplicatePlates(testCase)
            brew_path = fullfile(testCase.result_path,...
                'brew_folder');
            brew_list = fullfile(testCase.asset_path, 'tobrew_with_dups_n3.grp');
            brew_root = 'brew/pc';
            column_filter_file = fullfile(testCase.asset_path,...
                'filter_build_columns.gmt');
            out_path = tempname;
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--brew_path', brew_path,...
                '--brew_list', brew_list,...
                '--brew_root', brew_root,...
                '--column_filter', column_filter_file,...
                '--do_quick_build', true,...
                '--out', out_path,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = testCase.quick_build_files;
            for ii=1:length(output_files)
                this_file = fullfile(out_path, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            % test if column filter worked
            sig_info_file = fullfile(out_path, 'siginfo.txt');
            sig_info = parse_record(sig_info_file);
            has_correct_iname = all(ismember({sig_info.pert_iname}', 'physostigmine'));
            testCase.verifyTrue(has_correct_iname, 'Expected iname(s) not found');            
        end
        
         function testCovidBuild(testCase)
            % Build L1000-covid data
            brew_path = fullfile(testCase.result_path,...
                                 'brew_folder');
            brew_list = fullfile(brew_path, 'tobrew_n2.grp');
            brew_root = 'brew/pc';
            column_filter_file = fullfile(testCase.asset_path,...
                                    'filter_build_columns.gmt');
            out_path = tempname;            
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--brew_path', brew_path,...
                '--brew_list', brew_list,...
                '--brew_root', brew_root,...
                '--column_filter', column_filter_file,...
                '--feature_platform', 'l1000_covid',...
                '--out', out_path,...
                '--create_subdir', false);
            dbg(1, '%s', cmdStr);
            eval(cmdStr);
            output_files = testCase.build_files;
            for ii=1:length(output_files)
                this_file = fullfile(out_path, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            % test if column filter worked
            sig_info_file = fullfile(out_path, 'siginfo.txt');
            sig_info = parse_record(sig_info_file);
            has_correct_iname = all(ismember({sig_info.pert_iname}', 'physostigmine'));
            testCase.verifyTrue(has_correct_iname, 'Expected iname(s) not found');            
         end 
        
         function testCustomChip(testCase)
             % Build L1000-covid data
             brew_path = fullfile(testCase.result_path,...
                 'brew_folder');
             brew_list = fullfile(brew_path, 'tobrew_n2.grp');
             brew_root = 'brew/pc';
             column_filter_file = fullfile(testCase.asset_path,...
                 'filter_build_columns.gmt');
             custom_chip_file = fullfile(testCase.asset_path,...
                 'l1kaig_COVID.V1.0.chip');
             out_path = tempname;
             cmdStr = print_cmdline(testCase.sig_tool,...
                 '--brew_path', brew_path,...
                 '--brew_list', brew_list,...
                 '--brew_root', brew_root,...
                 '--column_filter', column_filter_file,...
                 '--custom_chip', custom_chip_file,...
                 '--out', out_path,...
                 '--create_subdir', false);
             dbg(1, '%s', cmdStr);
             eval(cmdStr);
             output_files = testCase.build_files;
             for ii=1:length(output_files)
                 this_file = fullfile(out_path, output_files{ii});
                 [fn, fp] = find_file(this_file);
                 testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
             end
             % test if column filter worked
             sig_info_file = fullfile(out_path, 'siginfo.txt');
             sig_info = parse_record(sig_info_file);
             has_correct_iname = all(ismember({sig_info.pert_iname}', 'physostigmine'));
             testCase.verifyTrue(has_correct_iname, 'Expected iname(s) not found');
         end
         
    end 
end