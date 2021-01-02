classdef TestFilterRecord < matlab.unittest.TestCase
    % Test suite for filter record function
    properties (Access = private)
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
        assets;
    end
    
    
    methods (TestMethodSetup)
        function setUp(testCase)
            % Setup (called before each test)
            filter_file = fullfile(testCase.asset_path, 'filter_list_multi.gmx');
            filter_list = parse_geneset(filter_file);
            table_file = fullfile(testCase.asset_path, 'table_to_filter.txt');
            test_table = parse_record(table_file);
            testCase.assets = struct('filter_file', filter_file,...
                                'table_file', table_file,...
                                'test_table', test_table,...
                                'filter_list', filter_list);
        end
    end
    
    methods(TestMethodTeardown)
        function tearDown(testCase)
            % Called after each test
        end
    end
    methods(Test)
        function testFilterExact(testCase)
            test_table = testCase.assets.test_table;
            filter_list = mkgmtstruct({'10 um'}, {'pert_idose'}, {'exact'});
            filt_table = filter_record(test_table, filter_list);
            keep = strcmp('10 um', {test_table.pert_idose}');
            exp_table = test_table(keep);
            
            testCase.verifyEqual(length(exp_table), length(filt_table), 'Num record mismatch');
            testCase.verifyEqual({exp_table.id}', {filt_table.id}', 'ID mismatch');
        end     
        
        function testFilterInvert(testCase)
            test_table = testCase.assets.test_table;
            filter_list = mkgmtstruct({'10 um'}, {'pert_idose'}, {'!exact'});
            filt_table = filter_record(test_table, filter_list);
            keep = ~strcmp('10 um', {test_table.pert_idose}');
            exp_table = test_table(keep);
            
            testCase.verifyEqual(length(exp_table), length(filt_table), 'Num record mismatch');
            testCase.verifyEqual({exp_table.id}', {filt_table.id}', 'ID mismatch');
        end
         
        function testFilterMulti(testCase)
            test_table = testCase.assets.test_table;
            filter_list = testCase.assets.filter_list;
            nfilt = length(filter_list);
            for ii=1:nfilt
                filt_table = filter_record(test_table, filter_list(ii));
                testCase.verifyTrue(~isempty(filt_table),...
                    sprintf('%d Empty result returned', ii));
            end                        
        end       
        
        function testFilterSlice(testCase)
            test_table = testCase.assets.test_table;
            filter_list = mkgmtstruct({'10 um'}, {'pert_idose'}, {'exact'});
            nrec = length(test_table);
            x = randn(50, nrec);
            ds = mkgctstruct(x,...
                             'rid', gen_labels(size(x, 1)),...
                             'cid', {test_table.id}');
            ds = annotate_ds(ds, test_table);            
            res = ds_slice(ds, 'column_filter', filter_list);
            keep = strcmp('10 um', {test_table.pert_idose}');
            exp_table = test_table(keep);
            filt_table = gctmeta(res, 'column');
            nfilt = length(exp_table);
            testCase.verifyEqual(size(res.mat), [50, nfilt], 'Matrix dimension mismatch');
            testCase.verifyEqual(length(exp_table), length(filt_table), 'Num record mismatch');
            testCase.verifyEqual({exp_table.id}', {filt_table.cid}', 'ID mismatch');              
        end
        
        function testFilterGCT(testCase)
            ds_file = fullfile(testCase.asset_path, 'filter_test_n100x50.gct');
            test_table = testCase.assets.test_table;
            filter_list = mkgmtstruct({'10 um'}, {'pert_idose'}, {'exact'});
            res = parse_gct(ds_file, 'column_filter', filter_list);
            keep = strcmp('10 um', {test_table.pert_idose}');
            exp_table = test_table(keep);
            filt_table = gctmeta(res, 'column');
            nfilt = length(exp_table);
            testCase.verifyEqual(size(res.mat), [50, nfilt], 'Matrix dimension mismatch');
            testCase.verifyEqual(length(exp_table), length(filt_table), 'Num record mismatch');
            testCase.verifyEqual({exp_table.id}', {filt_table.cid}', 'ID mismatch');                          
        end
                
        function testFilterGCTX(testCase)
            ds_file = fullfile(testCase.asset_path, 'filter_test_n100x50.gctx');
            test_table = testCase.assets.test_table;
            filter_list = mkgmtstruct({'10 um'}, {'pert_idose'}, {'exact'});
            res = parse_gctx(ds_file, 'column_filter', filter_list);
            keep = strcmp('10 um', {test_table.pert_idose}');
            exp_table = test_table(keep);
            filt_table = gctmeta(res, 'column');
            nfilt = length(exp_table);
            testCase.verifyEqual(size(res.mat), [50, nfilt], 'Matrix dimension mismatch');
            testCase.verifyEqual(length(exp_table), length(filt_table), 'Num record mismatch');
            testCase.verifyEqual({exp_table.id}', {filt_table.cid}', 'ID mismatch');

        end
    end
end