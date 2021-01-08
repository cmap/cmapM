classdef TestDSSlice < matlab.unittest.TestCase

    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)

        function testSliceWithId(testCase)
            dsFile = fullfile(testCase.asset_path, 'gex2norm_CALIB_n3x10.gct');
            ds = parse_gct(dsFile);
            rows_to_keep = ds.rid(1:5);
            cols_to_keep = ds.cid(2);
            
            res = ds_slice(ds, 'rid', rows_to_keep, 'cid', cols_to_keep);            
            testCase.verifyEqual(res.rid, rows_to_keep, 'row id mismatch');
            testCase.verifyEqual(res.cid, cols_to_keep, 'col id mismatch');
        end

        function testSliceWithIndex(testCase)
            dsFile = fullfile(testCase.asset_path, 'gex2norm_CALIB_n3x10.gct');
            ds = parse_gct(dsFile);
            rows_to_keep = 2:6;
            cols_to_keep = 3;
            
            res = ds_slice(ds, 'ridx', rows_to_keep, 'cidx', cols_to_keep);
            testCase.verifyEqual(res.rid, ds.rid(rows_to_keep), 'row id mismatch');
            testCase.verifyEqual(res.cid, ds.cid(cols_to_keep), 'col id mismatch');
        end
        
        function testSliceWithLogicalIndex(testCase)
	        dsFile = fullfile(testCase.asset_path, 'gex2norm_CALIB_n3x10.gct');
            ds = parse_gct(dsFile);
            rows_to_keep = mod(1:size(ds.mat, 1), 2)>0;
            res = ds_slice(ds, 'ridx', rows_to_keep);
            expect = ds_slice(ds, 'rid', ds.rid(rows_to_keep));            
            testCase.verifyTrue(gctcomp(res,expect), 'matrices do not match');
        end
                
    end 
end