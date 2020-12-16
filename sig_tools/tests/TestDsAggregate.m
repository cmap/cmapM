classdef TestDsAggregate < matlab.unittest.TestCase
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        tolerance = 1e-6;
        ds;
    end
    
    properties(TestParameter)
        agg_fun = cell2struct({'sum'; 'min'; 'max';...
                   'mean'; 'median'; 'std';...
                   'iqr'; 'sem'; 'absmax';...
                   'range'; 'numel'; 'mad';...
                   @(x, dim) max_quantile(x, 33, 67, dim)
                   },...
                   {'sum'; 'min'; 'max';...
                   'mean'; 'median'; 'std';...
                   'iqr'; 'sem'; 'absmax';...
                   'range'; 'numel'; 'mad';...
                   'max_quantile'
                   },...                   
                   1);
    end
    
    methods(TestMethodSetup)
        function createDataset(testCase)
            n = 5;
            rid = gen_labels(n);
            cid = gen_labels(n);           
            testCase.ds = mkgctstruct(randn(n), 'rid', rid, 'cid', cid);
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        
        function testAggregateRows(testCase, agg_fun)
            gp = num2cell(ones(5,1));            
            this_ds = ds_add_meta(testCase.ds, 'row', 'group', gp);
            this_ds = ds_add_meta(this_ds, 'column', 'group', gp);
            hfun = aggregate_fun(agg_fun);
            expect_val = hfun(this_ds.mat, 1);
            agg_rows = ds_aggregate(this_ds,...
                'row_fields', {'group'},...
                'fun',  agg_fun);            
            testCase.assertEqual(expect_val, agg_rows.mat,...
                'row aggregation mismatch');
        end
        
        function testAggregateColumns(testCase, agg_fun)
            gp = num2cell(ones(5,1));
            this_ds = ds_add_meta(testCase.ds, 'row', 'group', gp);
            this_ds = ds_add_meta(this_ds, 'column', 'group', gp);
            hfun = aggregate_fun(agg_fun);
            expect_val = hfun(this_ds.mat, 2);
            agg_cols = ds_aggregate(this_ds,...
                'col_fields', {'group'},...
                'fun',  agg_fun);
            
            testCase.assertEqual(expect_val, agg_cols.mat,...
                'column aggregation mismatch');
        end
        
        function testAggregateRowsThenColumns(testCase, agg_fun)
            gp = num2cell(ones(5,1));
            this_ds = ds_add_meta(testCase.ds, 'row', 'group', gp);
            this_ds = ds_add_meta(this_ds, 'column', 'group', gp);
            hfun = aggregate_fun(agg_fun);
            expect_val = hfun(hfun(this_ds.mat, 1),2);
            agg_both = ds_aggregate(this_ds,...
                'row_fields', {'group'},...
                'col_fields', {'group'},...
                'fun',  agg_fun);            
            testCase.assertEqual(expect_val, agg_both.mat, 'aggregation mismatch');
        end
        
        function testAggregateColumnsThenRows(testCase, agg_fun)
            gp = num2cell(ones(5,1));
            this_ds = ds_add_meta(testCase.ds, 'row', 'group', gp);
            this_ds = ds_add_meta(this_ds, 'column', 'group', gp);
            hfun = aggregate_fun(agg_fun);
            expect_val = hfun(hfun(this_ds.mat, 2),1);
            agg_both = ds_aggregate(this_ds,...
                'row_fields', {'group'},...
                'col_fields', {'group'},...
                'fun',  agg_fun, 'rows_first', false);            
            testCase.assertEqual(expect_val, agg_both.mat, 'aggregation mismatch');
        end      
        
    end

end