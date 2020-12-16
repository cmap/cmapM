classdef TestCompareMatrices < matlab.unittest.TestCase
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')), 'assets');
        ds = [];
    end
    
    methods(TestClassSetup)
        function createDs(testcase)
            % This way, only have to import gct once
            testcase.ds = parse_gctx([testcase.asset_path filesep 'gctv13_01.gct']);
        end
    end
    
    methods(Test)
        % TODO(lev): test if input matrices are different sizes
        function testSameDs(testcase)
            import mortar.compute.Connectivity
            ds1 = testcase.ds;
            ds2 = testcase.ds;
            
            % Run function
            out_gct = Connectivity.compareMatrices(ds1, ds2);
            sim_mat = out_gct.mat;
            
            testcase.assertEqual(diag(sim_mat), ones(size(ds1.mat, 2), 1), ...
                'AbsTol', 1e-3, 'The diagonal of the similarity matrix should be all 1s.')
            testcase.assertEqual(sim_mat(end-1, end-2), 0.8116, 'AbsTol', 1e-3)
        end
        
        function testReordered(testcase)
            import mortar.compute.Connectivity
            ds1 = testcase.ds;
            ds2 = testcase.ds;
            
            % Reorder ds2 columns
            ds2.mat = ds2.mat(:, size(ds2.mat, 2):-1:1);
            out_gct = Connectivity.compareMatrices(ds1, ds2);
            sim_mat = out_gct.mat;
            
            testcase.assertEqual(sim_mat(1, 1), 0.7522, 'AbsTol', 1e-3)
        end
        
        function testTransposed(testcase)
            import mortar.compute.Connectivity
            SET_SIZE = 50;
            
            % Operate along rows rather than columns
            ds1 = testcase.ds;
            ds2 = testcase.ds;
            
            % Rename cid to det_well entry
            ds1.cid = ds1.cdesc(:, ds1.cdict('det_well'));
            ds2.cid = ds2.cdesc(:, ds1.cdict('det_well'));
            
            out_gct = Connectivity.compareMatrices(ds1, ds2, ...
                'set_size', SET_SIZE, 'dim', 'row');
            sim_mat = out_gct.mat;
            
            testcase.assertEqual(diag(sim_mat), ones(size(ds1.mat, 1), 1), ...
                'AbsTol', 1e-3, 'The diagonal of the similarity matrix should be all 1s.')
            testcase.assertEqual(sim_mat(end, end-1), -0.0911, 'AbsTol', 1e-3)
        end
        
        function testDiffSizes(testcase)
            import mortar.compute.Connectivity
            ds1 = testcase.ds;
            ds2 = testcase.ds;
            
            % Reorder and remove some ds2 columns
            ds2.mat = ds2.mat(:, size(ds2.mat, 2):-1:1);
            [~, ds2_cols] = size(ds2.mat);
            ds2_sliced = ds_slice(ds2, 'cidx', 1:ds2_cols-5);
            out_gct = Connectivity.compareMatrices(ds1, ds2_sliced);
            sim_mat = out_gct.mat;
            
            testcase.assertEqual(size(sim_mat), ...
                [size(ds1.mat, 2), size(ds2_sliced.mat, 2)], 'The size of output matrix is incorrect.')
            testcase.assertEqual(sim_mat(1, 2), 0.8397, 'AbsTol', 1e-3)
        end
        
    end
end