classdef TestSigAnnotate < matlab.unittest.TestCase
    % Tests for SigAnnotate
    properties
        sig_class = @mortar.sigtools.SigAnnotate;
        sig_tool = 'sig_annotate_tool';
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        
        function testReadAnnotation(testCase)
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'row_meta', 'column_meta', 'ds', 'is_updated'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            row_meta = parse_tbl(fullfile(testCase.asset_path, 'row_meta_n978.txt'), 'outfmt', 'record');
            column_meta = parse_tbl(fullfile(testCase.asset_path, 'column_meta_n371.txt'), 'outfmt', 'record');
            testCase.verifyFalse(res.is_updated, 'is_updated field not false');            
            testCase.verifyTrue(all(isfield(res.row_meta, fieldnames(row_meta))), 'Row annotation mismatch');
            testCase.verifyTrue(all(isfield(res.column_meta, fieldnames(column_meta))), 'Column annotation mismatch');            
        end
        
        function testUpdateAnnotation(testCase)
            ds_file = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            ds = parse_gctx(ds_file);
            ds = ds_strip_meta(ds);
            row_meta_file = fullfile(testCase.asset_path, 'row_meta_n978.txt');
            column_meta_file = fullfile(testCase.asset_path, 'column_meta_n371.txt');
            row_meta = parse_tbl(row_meta_file, 'outfmt', 'record');
            column_meta = parse_tbl(column_meta_file, 'outfmt', 'record');
            
            obj = testCase.sig_class();
            obj.parseArgs('--ds',...
                ds, '--row_meta', row_meta_file,...
                '--column_meta', column_meta_file);
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'row_meta', 'column_meta', 'ds', 'is_updated'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            testCase.verifyTrue(res.is_updated, 'is_updated field not true');
            
            res_row_meta = gctmeta(res.ds, 'row');
            res_column_meta = gctmeta(res.ds);            
            testCase.verifyTrue(all(isfield(res_row_meta, fieldnames(row_meta))), 'Row annotation mismatch');
            testCase.verifyTrue(all(isfield(res_column_meta, fieldnames(column_meta))), 'Column annotation mismatch');
        end
        
        function testStripMatrix(testCase)
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            obj = testCase.sig_class();
            obj.parseArgs('--ds', dsFile, '--strip_matrix', 'both');
            obj.runAnalysis;
            res = obj.getResults;
            reqFields = {'args', 'row_meta', 'column_meta', 'ds', 'is_updated', 'is_strip', 'ds_strip'};
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Required result fields not found');
            testCase.verifyTrue(isempty(res.ds_strip.rdesc));            
            testCase.verifyTrue(isempty(res.ds_strip.cdesc));            
        end
        
        function testDemoRead(testCase)
            dbg(1, '## Running demo Read...');
            dsFile = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            outPath = tempname;
%             cmdStr = sprintf('sig_annotate_tool --ds %s --out %s --create_subdir false', dsFile, outPath);
            cmdStr = print_cmdline(testCase.sig_tool, '--ds', dsFile, '--out', outPath, '--create_subdir', false');
            
            dbg(1, cmdStr)
            eval(cmdStr);
            output_files = {'config.yaml', 'success.txt', 'row_meta_n*.txt', 'column_meta_n*.txt'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            dbg(1, '## Done');
        end
        
        function testDemoUpdate(testCase)
            dbg(1, '## Running demo Update...');
            ds_file = fullfile(testCase.asset_path, 'gctv13_01.gctx');
            row_meta_file = fullfile(testCase.asset_path, 'row_meta_n978.txt');
            column_meta_file = fullfile(testCase.asset_path, 'column_meta_n371.txt');            
            outPath = tempname;
            cmdStr = print_cmdline(testCase.sig_tool,...
                '--ds', ds_file, '--row_meta', row_meta_file,...
                '--column_meta', column_meta_file, '--out', outPath,...
                '--create_subdir', false);
            dbg(1, cmdStr)
            eval(cmdStr);
            output_files = {'config.yaml', 'success.txt', 'gctv13_01_n371x978.gctx'};
            for ii=1:length(output_files)
                this_file = fullfile(outPath, output_files{ii});
                [fn, fp] = find_file(this_file);
                testCase.verifyNotEmpty(fn, sprintf('File not found %s',this_file));
            end
            dbg(1, '## Done');
        end
    end
    
end