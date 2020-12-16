classdef TestDsConcatenate < matlab.unittest.TestCase
    methods(Test)
        function test_ds_concatenate(testCase)
            fprintf('test_ds_concatenate\n')
            fprintf('basic testing that wrapper ds_concatenate works.  For more detailed tests see TestDsConcatenateClass\n')

            %unhappy path, insufficient number of datasets
            testCase.verifyError(@() ds_concatenate({}), 'ds_concatenate:need_at_least_2_ds')
            testCase.verifyError(@() ds_concatenate({'a'}), 'ds_concatenate:need_at_least_2_ds')

            %happy path concatenate 2 datasets
            rid1 = {'1', '2', '3'};
            cid1 = {'b', 'a'};
            mat1 = [-1 -2
                -3 -4
                -5 -6];
            rhd1 = {'rm1', 'rm2'};
            rdesc1 = {4, 5; 6, 7; 8, 9};
            chd1 = {'cm1', 'cm2', 'cm3'};
            cdesc1 = {10, 11, 12; 13, 14, 15};
            ds1 = mkgctstruct(mat1, 'rid', rid1, 'cid', cid1, 'rhd', rhd1, 'rdesc', rdesc1, 'chd', chd1, 'cdesc', cdesc1)

            
            rid2 = {'5', '2', '4'};
            cid2 = {'c', 'd', 'f', 'e'};
            mat2 = [-7 -8 -9 -10
                -11 -12 -13 -14
                -15 -16 -17 -18];
            rhd2 = {'rm2', 'rm1', 'rm3'};
            rdesc2 = {16, 17, 18; 19, 20, 21; 22, 23, 24};
            chd2 = {'cm4', 'cm3', 'cm2'};
            cdesc2 = {25, 26, 27; 28, 29, 30; 31, 32, 33; 34, 35, 36};
            ds2 = mkgctstruct(mat2, 'rid', rid2, 'cid', cid2, 'rhd', rhd2, 'rdesc', rdesc2, 'chd', chd2, 'cdesc', cdesc2)

            ds = ds_concatenate({ds1, ds2})
        end
    end
end
