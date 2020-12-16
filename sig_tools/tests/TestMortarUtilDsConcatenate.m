classdef TestMortarUtilDsConcatenate < matlab.unittest.TestCase
    properties (Constant)
    end

    properties
    end

    methods(TestMethodSetup)
        %setup conditions for the tests
    end
    
    methods(TestMethodTeardown)
        %cleanup after running the tests
    end

    methods(Static)
    end

    methods(Test)
        function test_calculate_union_of_all(testCase)
            fprintf('test_calculate_union_of_all\n')
            entries = {{'a', 'b', 'c'}, {'c', 'd', 'e'}, {'d', 'e', 'f'}};

            r = mortar.util.DsConcatenate.calculate_union_of_all(entries)

            expected_letters = {'a', 'b', 'c', 'd', 'e', 'f'};
            for ii = 1:length(expected_letters)
                el = expected_letters{ii};
                el_count = sum(strcmp(r, el));
                testCase.verifyEqual(1, el_count)
            end
        end

        function test_calculate_intersection_of_all(testCase)
            fprintf('test_calculate_intersection_of_all\n')
            
            entries = {{'a', 'b', 'c'}, {'c', 'd', 'e'}, {'d', 'e', 'c'}};

            r = mortar.util.DsConcatenate.calculate_intersection_of_all(entries)

            testCase.verifyEqual(1, length(r));
            testCase.verifyTrue(strcmp('c', r{1}))
        end

        function test_remove_hd_from_meta_desc(testCase)
            fprintf('test_remove_hd_from_meta_desc\n')

            all_desc = {{1,2,3; 4,5,6}, {7,8,9}, {10, 11; 12, 13}};
            all_hd = {{'a', 'b', 'c'}, {'c', 'd', 'e'}, {'e', 'f'}};
            hd_to_remove = {'c', 'd'};

            [r, r_hd] = mortar.util.DsConcatenate.remove_hd_from_meta_desc(all_desc, all_hd, hd_to_remove);

            for ii = 1:length(all_desc)
                expected_rows = size(all_desc{ii}, 1);
                returned_rows = size(r{ii}, 1);
                fprintf('ii:  %i  expected_rows:  %i  returned_rows:  %i\n', ii, expected_rows, returned_rows)
                testCase.verifyEqual(expected_rows, returned_rows, 'expected number of rows to be preserved, they were not');
            end

            testCase.verifyEqual(2, size(r{1}, 2), 'expected only 2 column to be present in r{1} after removing headers (1 removed)');
            testCase.verifyEqual(1, size(r{2}, 2), 'expected only 1 column to be present in r{2} after removing headers (2 removed)');
            testCase.verifyEqual(2, size(r{3}, 2), 'expected 2 columns to be present in r{3} after removing headers (0 removed)');

            testCase.verifyEqual(2, length(r_hd{1}), 'expected only 2 headers to be present in r_hd{1} after removing headers (1 removed)');
            testCase.verifyEqual(1, length(r_hd{2}), 'expected only 1 header to be present in r_hd{2} after removing headers (2 removed)');
            testCase.verifyEqual(2, length(r_hd{3}), 'expected 2 headers to be present in r_hd{3} after removeing headers (0 removed)');
        end

        function test_build_union_meta(testCase)
            fprintf('test_build_union_meta\n')

            meta_hd = {{'a', 'c', 'b'}, {'a', 'b', 'c'}, {'a', 'b', 'c'}};
            expected_meta_hd = meta_hd{2};
            
            ids = {{'1'}, {'1', '2'}, {'4', '2', '1', '3'}};
            expected_ids = sort(mortar.util.DsConcatenate.calculate_union_of_all(ids));

            meta_desc = {{1,2,3}, {4,5,6; 7,8,9}, {10,11,12; 13,14,15; 16,17,18; 19,20,21}};
            expected_meta_desc = {1, 3, 2;
                7, 8, 9; %first row of meta_desc{2} is excluded b/c it's id == 1 is a repeat
                19, 20, 21;  %this is the 4th row of meta_desc{3} because rows 2-3 are repeats, and the id is 3 which is less than the the first id == 4
                10, 11, 12}; %this is the 1st row of meta_desc{3} its id == 4 is greater than 3 (so they are swapped in the expected)  

            [r_desc, r_hd, r_id] = mortar.util.DsConcatenate.build_union_meta(meta_desc, meta_hd, ids)

            testCase.verifyEqual(length(expected_ids), length(r_id))
            for ii = 1:length(expected_ids)
                eid = expected_ids{ii};
                cur_r_id = r_id{ii};
                testCase.verifyTrue(strcmp(eid, cur_r_id), ['ii:  ' num2str(ii)  '  eid:  ' eid '  cur_r_id:  ' cur_r_id])
            end

            testCase.verifyEqual(3, length(r_hd))
            testCase.verifyTrue(strcmp('a', r_hd{1}))
            testCase.verifyTrue(strcmp('b', r_hd{2}))
            testCase.verifyTrue(strcmp('c', r_hd{3}))

            testCase.verifyEqual(length(expected_ids), size(r_desc, 1))
            testCase.verifyEqual(3, size(r_desc, 2))

            testCase.verifyEqual(cell2mat(expected_meta_desc), cell2mat(r_desc))
        end

        function test_assemble_common_meta(testCase)
            fprintf('test_assemble_common_meta\n')

            hd_to_remove = {'a', 'b'};
            hds = {{'a', 'b', 'c', 'd', 'e'}, {'e', 'c', 'a', 'f'}, {'d', 'b', 'c', 'e', 'f'}};
            expected_hds = {'c', 'e'} %these are common to all 3 above and are not removed
            
            ids = {{'1','2','3','4'}, {'2', '3', '4'}, {'3','4','5'}};
            expected_ids = mortar.util.DsConcatenate.calculate_union_of_all(ids)

            md1 = {6, 7, 8, 9, 10; 
                11, 12, 13, 14, 15; 
                16, 17, 18, 19, 20; 
                21, 22, 23, 24, 25}; %5 columns matching hds{1} above and 4 rows matching ids{1} above

            md2 = {26, 27, 28, 29; 
                30, 31, 32, 33; 
                34, 35, 36, 37}; %4 columns matching hds{2} above and 3 rows matching ids{2} above

            md3 = {38, 39, 40, 41, 42;
                43, 44, 45, 46, 47;
                48, 49, 50, 51, 52}; % 5 columns matching hds{3} above and 3 rows matching ids{3} above

            meta_desc = {md1, md2, md3};

            expected_meta_desc = {8, 10;
                    13, 15;
                    18, 20; %md1 will be pulled from first, and it has ids 1-4, and we are only keeping hd 'c','e' which are 3rd and 5th columns of md1
                    23, 25; %md2 has nothing new to contribute
                    50, 51}; %md3 is the only one with id5, 'c','e' are its 3rd and 4th columns for the last row of expected_meta_desc

            [r_meta_desc, r_meta_hd, r_ids] = mortar.util.DsConcatenate.assemble_common_meta(meta_desc, hds, hd_to_remove, ids)

            testCase.verifyEqual(length(expected_hds), length(r_meta_hd))
            testCase.verifyTrue(isempty(setxor(expected_hds, r_meta_hd)))

            testCase.verifyEqual(length(expected_ids), length(r_ids))
            testCase.verifyTrue(isempty(setxor(expected_ids, r_ids)))

            testCase.verifyEqual(cell2mat(expected_meta_desc), cell2mat(r_meta_desc))
        end

        function test_assemble_concatenated_meta(testCase)
            fprintf('test_assemble_concatenated_meta\n')

            my_dscc = mortar.util.DsConcatenate()

            %unhappy path, duplicate meta_ids
            bad_meta_ids = {{'1', '2', '3'}, {'3', '4', '5', '2'}};
            testCase.verifyError(@() my_dscc.assemble_concatenated_meta({}, {}, bad_meta_ids), ...
                'mortar_util_DsConcatenate_assemble_concatenated_meta:duplicate_concat_meta_ids');

            %happy path
            meta_ids = {{'1', '2'}, {'3', '4'}};
            expected_ids = mortar.util.DsConcatenate.calculate_union_of_all(meta_ids);

            meta_hd = {{'a', 'b'}, {'c', 'b'}};
            expected_hd = mortar.util.DsConcatenate.calculate_union_of_all(meta_hd);

            md1 = {5, 6;
                7, 8};
            md2 = {9, 10;
                11, 12};
            meta_desc = {md1, md2};
            expected_meta_desc = {5, 6, -666;
                7,     8, -666;
                -666, 10,    9;
                -666, 12,   11};

            [r_md, r_hd, r_id] = my_dscc.assemble_concatenated_meta(meta_desc, meta_hd, meta_ids)

            testCase.verifyEqual(length(expected_ids), length(r_id))
            testCase.verifyTrue(isempty(setxor(expected_ids, r_id)))

            testCase.verifyEqual(length(expected_hd), length(r_hd))
            testCase.verifyTrue(isempty(setxor(expected_hd, r_hd)))
 
            testCase.verifyEqual(cell2mat(expected_meta_desc), cell2mat(r_md))
        end

        function test_assemble_data(testCase)
            fprintf('test_assemble_data\n')

            my_dscc = mortar.util.DsConcatenate()

            %unhappy path invalid concat_direction
            testCase.verifyError(@() my_dscc.assemble_data({}, {}, 'hello world!!!'), 'mortar_util_DsConcatenate_assemble_data:unrecognized_concat_direction');

            %happy path along-columns
            row_ids = {{'1', '2', '3'}, {'3', '1', '4'}};
            expected_row_ids = mortar.util.DsConcatenate.calculate_union_of_all(row_ids);

            matrices = {[5 6 7 7.7
                8 9 10 10.10
                11 12 13 13.13], ...
                [14 15 16
                17 18 19
                20 21 22]};
            expected_matrix = [5 6 7 7.7 17 18 19
                  8   9  10 10.10 NaN NaN NaN
                 11  12  13 13.13  14  15  16
                NaN NaN NaN   NaN  20  21  22];

            [r_comb_mat, r_comb_ids] = my_dscc.assemble_data(matrices, row_ids, 'along-columns')

            testCase.verifyEqual(length(expected_row_ids), length(r_comb_ids))
            testCase.verifyTrue(isempty(setxor(expected_row_ids, r_comb_ids)))

            testCase.verifyEqual(expected_matrix, r_comb_mat)

            %happy path along-rows
            col_ids = {{'1', '2'}, {'2', '4', '3'}};
            expected_col_ids = mortar.util.DsConcatenate.calculate_union_of_all(col_ids);

            matrices = {[5 6
                7 8
                9 10], ...
                [11 12 13
                14 15 16]};
            expected_matrix = [5 6 NaN NaN
                7 8 NaN NaN
                9 10 NaN NaN
                NaN 11 13 12
                NaN 14 16 15]

            [r_comb_mat, r_comb_ids] = my_dscc.assemble_data(matrices, col_ids, 'along-rows')

            testCase.verifyEqual(length(expected_col_ids), length(r_comb_ids))
            testCase.verifyTrue(isempty(setxor(expected_row_ids, r_comb_ids)))

            testCase.verifyEqual(expected_matrix, r_comb_mat)
        end
        
        function test_transform_ds_array(testCase)
            fprintf('test_transform_ds_array\n')

            %unhappy path invalid concat direction
            testCase.verifyError(@() mortar.util.DsConcatenate.transform_ds_array({}, 'hello again world :('), 'mortar_util_DsConcatenate_transform_ds_array:unrecognized_concat_direction')

            rid1 = {'1', '2', '3'};
            cid1 = {'b', 'a'};
            mat1 = rand(3,2);
            rhd1 = {'rm1', 'rm2'};
            rdesc1 = {4, 5; 6, 7; 8, 9};
            chd1 = {'cm1', 'cm2', 'cm3'};
            cdesc1 = {10, 11, 12; 13, 14, 15};
            ds1 = mkgctstruct(mat1, 'rid', rid1, 'cid', cid1, 'rhd', rhd1, 'rdesc', rdesc1, 'chd', chd1, 'cdesc', cdesc1)

            rid2 = {'3', '2', '4'};
            cid2 = {'a', 'b', 'c', 'd'};
            mat2 = rand(3,4);
            rhd2 = {'rm2', 'rm1', 'rm3'};
            rdesc2 = {16, 17, 18; 19, 20, 21; 22, 23, 24};
            chd2 = {'cm4', 'cm3', 'cm2'};
            cdesc2 = {25, 26, 27; 28, 29, 30; 31, 32, 33; 34, 35, 36};
            ds2 = mkgctstruct(mat2, 'rid', rid2, 'cid', cid2, 'rhd', rhd2, 'rdesc', rdesc2, 'chd', chd2, 'cdesc', cdesc2)

            [concat_meta_desc, concat_meta_hd, concat_meta_ids, common_meta_desc, common_meta_hd, common_meta_ids] = mortar.util.DsConcatenate.transform_ds_array({ds1, ds2}, 'along-rows');

            testCase.verifyTrue(isempty(setxor(concat_meta_hd{1}, rhd1)))
            testCase.verifyTrue(isempty(setxor(concat_meta_hd{2}, rhd2)))
            testCase.verifyTrue(isempty(setxor(concat_meta_ids{1}, rid1)))
            testCase.verifyTrue(isempty(setxor(concat_meta_ids{2}, rid2)))
            testCase.verifyTrue(isempty(setxor(common_meta_hd{1}, chd1)))
            testCase.verifyTrue(isempty(setxor(common_meta_hd{2}, chd2)))
            testCase.verifyTrue(isempty(setxor(common_meta_ids{1}, cid1)))
            testCase.verifyTrue(isempty(setxor(common_meta_ids{2}, cid2)))

            testCase.verifyEqual(cell2mat(rdesc1), cell2mat(concat_meta_desc{1}))
            testCase.verifyEqual(cell2mat(rdesc2), cell2mat(concat_meta_desc{2}))
            testCase.verifyEqual(cell2mat(cdesc1), cell2mat(common_meta_desc{1}))
            testCase.verifyEqual(cell2mat(cdesc2), cell2mat(common_meta_desc{2}))

            [concat_meta_desc, concat_meta_hd, concat_meta_ids, common_meta_desc, common_meta_hd, common_meta_ids] = mortar.util.DsConcatenate.transform_ds_array({ds1, ds2}, 'along-columns');

            testCase.verifyTrue(isempty(setxor(concat_meta_hd{1}, chd1)))
            testCase.verifyTrue(isempty(setxor(concat_meta_hd{2}, chd2)))
            testCase.verifyTrue(isempty(setxor(concat_meta_ids{1}, cid1)))
            testCase.verifyTrue(isempty(setxor(concat_meta_ids{2}, cid2)))
            testCase.verifyTrue(isempty(setxor(common_meta_hd{1}, rhd1)))
            testCase.verifyTrue(isempty(setxor(common_meta_hd{2}, rhd2)))
            testCase.verifyTrue(isempty(setxor(common_meta_ids{1}, rid1)))
            testCase.verifyTrue(isempty(setxor(common_meta_ids{2}, rid2)))

            testCase.verifyEqual(cell2mat(cdesc1), cell2mat(concat_meta_desc{1}))
            testCase.verifyEqual(cell2mat(cdesc2), cell2mat(concat_meta_desc{2}))
            testCase.verifyEqual(cell2mat(rdesc1), cell2mat(common_meta_desc{1}))
            testCase.verifyEqual(cell2mat(rdesc2), cell2mat(common_meta_desc{2}))
        end

        function test_concat_invalid_concat_direction(testCase)
            my_dscc = mortar.util.DsConcatenate()
            testCase.verifyError(@() my_dscc.concat({}, 'hello again world :('), 'mortar_util_DsConcatenate_concat:unrecognized_concat_direction')
        end
   
        function test_concat_along_rows(testCase)
            fprintf('test_concat_along_rows\n')

            my_dscc = mortar.util.DsConcatenate()

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
    
            %ds1 schematic
            %id     rm1     rm2     b       a
            %cm1                    10      13
            %cm2                    11      14
            %cm3                    12      15
            %1      4       5       -1      -2
            %2      6       7       -3      -4
            %3      8       9       -5      -6

            rid2 = {'5', '6', '4'};
            cid2 = {'a', 'b', 'c', 'd'};
            mat2 = [-7 -8 -9 -10
                -11 -12 -13 -14
                -15 -16 -17 -18];
            rhd2 = {'rm2', 'rm1', 'rm3'};
            rdesc2 = {16, 17, 18; 19, 20, 21; 22, 23, 24};
            chd2 = {'cm4', 'cm3', 'cm2'};
            cdesc2 = {25, 26, 27; 28, 29, 30; 31, 32, 33; 34, 35, 36};
            ds2 = mkgctstruct(mat2, 'rid', rid2, 'cid', cid2, 'rhd', rhd2, 'rdesc', rdesc2, 'chd', chd2, 'cdesc', cdesc2)

            %ds2 schematic
            %id     rm2     rm1     rm3     a       b       c       d
            %cm4                            25      28      31      34
            %cm3                            26      29      32      35
            %cm2                            27      30      33      36
            %5      16      17      18      -7      -8      -9      -10
            %6      19      20      21      -11     -12     -13     -14
            %4      22      23      24      -15     -16     -17     -18

            ds = my_dscc.concat({ds1, ds2}, 'along-rows')
            
            %expected ds schematic
            %id     rm1     rm2     rm3     a       b       c       d
            %cm2                            14      11      33      36
            %cm3                            15      12      32      35
            %1      4       5       -666    -2      -1      NaN     NaN
            %2      6       7       -666    -4      -3      NaN     NaN
            %3      8       9       -666    -6      -5      NaN     NaN
            %5      17      16      18      -7      -8      -9      -10
            %6      20      19      21      -11     -12     -13     -14
            %4      23      22      24      -15     -16     -17     -18

            expected_rhd = {'rm1', 'rm2', 'rm3'};
            expected_cid = {'a', 'b', 'c', 'd'};

            expected_chd = {'cm2', 'cm3'};
            expected_cdesc = {14, 15
                              11, 12
                              33, 32
                              36, 35};

            expected_rid = {'1', '2', '3', '5', '6', '4'};
            expected_rdesc = {4,  5, -666
                              6,  7, -666
                              8,  9, -666
                             17, 16, 18
                             20, 19, 21
                             23, 22, 24};

            expected_mat = [-2 -1 NaN NaN
                -4 -3 NaN NaN
                -6 -5 NaN NaN
                -7 -8 -9 -10
                -11 -12 -13 -14
                -15 -16 -17 -18];
            
            fprintf('test_concat testing rhd\n')
            ds1.rhd
            ds2.rhd
            ds.rhd
            testCase.verifyEqual(length(expected_rhd), length(ds.rhd))
            for ii = 1:length(expected_rhd)
                testCase.verifyTrue(strcmp(expected_rhd{ii}, ds.rhd{ii}))
            end

            fprintf('test_concat testing cid\n')
            ds1.cid
            ds2.cid
            ds.cid
            testCase.verifyEqual(length(expected_cid), length(ds.cid))
            for ii = 1:length(expected_cid)
                testCase.verifyTrue(strcmp(expected_cid{ii}, ds.cid{ii}))
            end

            fprintf('test_concat testing chd\n')
            ds1.chd
            ds2.chd
            ds.chd
            testCase.verifyEqual(length(expected_chd), length(ds.chd))
            for ii = 1:length(expected_chd)
                testCase.verifyTrue(strcmp(expected_chd{ii}, ds.chd{ii}))
            end

            fprintf('test_concat testing cdesc\n')
            ds1.cdesc
            ds2.cdesc
            ds.cdesc
            testCase.verifyEqual(cell2mat(expected_cdesc), cell2mat(ds.cdesc))

            fprintf('test_concat testing rid\n')
            ds1.rid
            ds2.rid
            ds.rid
            testCase.verifyEqual(length(expected_rid), length(ds.rid))
            for ii = 1:length(expected_rid)
                testCase.verifyTrue(strcmp(expected_rid{ii}, ds.rid{ii}))
            end

            fprintf('test_concat testing rdesc\n')
            ds1.rdesc
            ds2.rdesc
            ds.rdesc
            testCase.verifyEqual(cell2mat(expected_rdesc), cell2mat(ds.rdesc))

            fprintf('test_concat testing matrix\n')
            ds1.mat
            ds2.mat
            ds.mat
            testCase.verifyEqual(expected_mat, ds.mat)
        end

        function test_concat_along_columns(testCase)
            fprintf('test_concat_along_columns\n')

            my_dscc = mortar.util.DsConcatenate()

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
    
            %ds1 schematic
            %id     rm1     rm2     b       a
            %cm1                    10      13
            %cm2                    11      14
            %cm3                    12      15
            %1      4       5       -1      -2
            %2      6       7       -3      -4
            %3      8       9       -5      -6

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

            %ds2 schematic
            %id     rm2     rm1     rm3     c       d       f       e
            %cm4                            25      28      31      34
            %cm3                            26      29      32      35
            %cm2                            27      30      33      36
            %5      16      17      18      -7      -8      -9      -10
            %2      19      20      21      -11     -12     -13     -14
            %4      22      23      24      -15     -16     -17     -18

            ds = my_dscc.concat({ds1, ds2}, 'along-columns')
            
            %expected ds schematic
            %id     rm1     rm2     b       a       c       d       f       e
            %cm1                    10      13      -666    -666    -666    -666
            %cm2                    11      14      27      30      33      36
            %cm3                    12      15      26      29      32      35
            %cm4                    -666    -666    25      28      31      34
            %1      4       5       -1      -2      NaN     NaN     NaN     NaN
            %2      6       7       -3      -4      -11     -12     -13     -14
            %3      8       9       -5      -6      NaN     NaN     NaN     NaN
            %4      23      22      NaN     NaN     -15     -16     -17     -18
            %5      17      16      NaN     NaN     -7      -8      -9      -10

            expected_rhd = {'rm1', 'rm2'};
            expected_cid = {'b', 'a', 'c', 'd', 'f', 'e'};

            expected_chd = {'cm1', 'cm2', 'cm3', 'cm4'};
            expected_cdesc = {10,   11,   12, -666
                              13,   14,   15, -666
                              -666, 27,   26, 25
                              -666, 30,   29, 28
                              -666, 33,   32, 31
                              -666, 36,   35, 34};

            expected_rid = {'1', '2', '3', '4', '5'};
            expected_rdesc = {4,  5
                              6,  7
                              8,  9
                             23, 22
                             17, 16};

            expected_mat = [-1  -2  NaN NaN NaN NaN
                            -3  -4  -11 -12 -13 -14
                            -5  -6  NaN NaN NaN NaN
                            NaN NaN -15 -16 -17 -18
                            NaN NaN -7  -8  -9  -10];
            
            fprintf('test_concat testing rhd\n')
            ds1.rhd
            ds2.rhd
            ds.rhd
            testCase.verifyEqual(length(expected_rhd), length(ds.rhd))
            for ii = 1:length(expected_rhd)
                testCase.verifyTrue(strcmp(expected_rhd{ii}, ds.rhd{ii}))
            end

            fprintf('test_concat testing cid\n')
            ds1.cid
            ds2.cid
            ds.cid
            testCase.verifyEqual(length(expected_cid), length(ds.cid))
            for ii = 1:length(expected_cid)
                testCase.verifyTrue(strcmp(expected_cid{ii}, ds.cid{ii}))
            end

            fprintf('test_concat testing chd\n')
            ds1.chd
            ds2.chd
            ds.chd
            testCase.verifyEqual(length(expected_chd), length(ds.chd))
            for ii = 1:length(expected_chd)
                testCase.verifyTrue(strcmp(expected_chd{ii}, ds.chd{ii}))
            end

            fprintf('test_concat testing cdesc\n')
            ds1.cdesc
            ds2.cdesc
            ds.cdesc
            testCase.verifyEqual(cell2mat(expected_cdesc), cell2mat(ds.cdesc))

            fprintf('test_concat testing rid\n')
            ds1.rid
            ds2.rid
            ds.rid
            testCase.verifyEqual(length(expected_rid), length(ds.rid))
            for ii = 1:length(expected_rid)
                testCase.verifyTrue(strcmp(expected_rid{ii}, ds.rid{ii}))
            end

            fprintf('test_concat testing rdesc\n')
            ds1.rdesc
            ds2.rdesc
            ds.rdesc
            testCase.verifyEqual(cell2mat(expected_rdesc), cell2mat(ds.rdesc))

            fprintf('test_concat testing matrix\n')
            ds1.mat
            ds2.mat
            ds.mat
            testCase.verifyEqual(expected_mat, ds.mat)
        end
    end
end
