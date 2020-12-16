classdef TestMergeTwo < matlab.unittest.TestCase
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
        function print_dataset(g)
            fprintf('mat:  ')
            g.mat
            fprintf('cid:  ')
            g.cid
            fprintf('rid:  ')
            g.rid
            fprintf('rhd:  ')
            g.rhd
            fprintf('rdesc:  ')
            g.rdesc
            fprintf('chd:  ')
            g.chd
            fprintf('cdesc:  ')
            g.cdesc
        end

        function [cid1, cid2, rid, g1, g2] = buildDatasetsForHappyAlongColumnMerge()
            cid1 = {'a', 'b', 'c'};
            rid = {'1', '3', '2'};
            rdesc = {4; 5; 6};
            rhd = {'pr_my_rhd'};
            chd = {'my_chd'};
            cdesc = {'g', 'h', 'f'};
            g1 = mkgctstruct(rand(length(rid), length(cid1)), 'cid', cid1, 'rid', rid, 'rhd', rhd, 'rdesc', rdesc, ...
                'chd', chd, 'cdesc', cdesc);
            fprintf('g1:  ')
            TestMergeTwo.print_dataset(g1)

            cid2 = {'d', 'e'};
            cdesc2 = {'i', 'j'};
            g2 = mkgctstruct(rand(length(rid), length(cid2)), 'cid', cid2, 'rid', rid(3:-1:1), 'rhd', rhd, 'rdesc', rdesc(3:-1:1), ...
                'chd', chd, 'cdesc', cdesc2);
            fprintf('g2:  ')
            TestMergeTwo.print_dataset(g2)
        end

        function verifyHappyAlongColumnMerge(testCase, cid1, cid2, rid, g1, g2, merge_result)
            fprintf('merge_result:  ')
            TestMergeTwo.print_dataset(merge_result)

            N_cid1 = length(cid1);
            N_cid2 = length(cid2);
            expected_num_cols = N_cid1 + N_cid2;
            expected_num_rows = length(rid);

            testCase.verifyEqual(expected_num_cols, size(merge_result.mat, 2), 'result did not have expected number of columns')
            testCase.verifyEqual(expected_num_rows, size(merge_result.mat, 1), 'result did not have expected number of rows')

            [~, sort_ord_mr_rid] = sort(merge_result.rid);
            [~, sort_ord_rid1] = sort(g1.rid);
            comparison = g1.mat(sort_ord_rid1,:) == merge_result.mat(sort_ord_mr_rid, 1:length(cid1));
            comparison = comparison(:);
            testCase.verifyEqual(length(comparison), sum(comparison), 'expected values from the 1st merging matrix were not found at the expected location within the result matrix')

            [~, sort_ord_rid2] = sort(g2.rid);
            comparison = g2.mat(sort_ord_rid2, :) == merge_result.mat(sort_ord_mr_rid, (length(cid1)+1):end);
            comparison = comparison(:);
            testCase.verifyEqual(length(comparison), sum(comparison), 'expected values from 2nd merging matrix were not found at the expected location within the result matrix')

            comparison = cell2mat(g1.rdesc(sort_ord_rid1)) ==  cell2mat(merge_result.rdesc(sort_ord_mr_rid));
            comparison = comparison(:);
            testCase.verifyEqual(length(comparison), sum(comparison), 'expected rdesc from 1st dataset does not match rdesc in merge result')

            testCase.verifyTrue(all(strcmp(g1.cid, merge_result.cid(1:N_cid1))), 'expected first cids of result dataset to match cids of first input dataset')
            testCase.verifyTrue(all(strcmp(g2.cid, merge_result.cid((N_cid1+1):end))), 'expected last cids of result dataset to match cids of second input dataset')

            comparison = strcmp(g1.cdesc, merge_result.cdesc(1:N_cid1, :));
            comparison = comparison(:);
            testCase.verifyTrue(all(comparison), 'expected first cdesc entries of result dataset to match cdesc entries of first input dataset')

            comparison = strcmp(g2.cdesc, merge_result.cdesc((N_cid1+1):end, :));
            comparison = comparison(:);
            testCase.verifyTrue(all(comparison), 'expected last cdesc entries of result dataset to match cdesc entries of second input dataset')
        end

        function [g1, g2] = buildDatasetsForHappyAlongRowMerge()
            cid = {'a', 'c', 'b'};
            rid1 = {'1', '2', '3'};
            cdesc = {4; 5; 6};
            chd = {'my_chd'};
            rhd = {'my_rhd'};
            rdesc = {'d', 'e', 'f'};
            g1 = mkgctstruct(rand(length(rid1), length(cid)), 'cid', cid, 'rid', rid1, 'chd', chd, 'cdesc', cdesc, ...
                'rhd', rhd, 'rdesc', rdesc);
            fprintf('g1:  ')
            TestMergeTwo.print_dataset(g1)

            rid2 = {'4', '5'};
            rdesc2 = {'g', 'h'};
            g2 = mkgctstruct(rand(length(rid2), length(cid)), 'cid', cid(3:-1:1), 'rid', rid2, 'chd', chd, 'cdesc', cdesc(3:-1:1), ...
                'rhd', rhd, 'rdesc', rdesc2);
            fprintf('g2:  ')
            TestMergeTwo.print_dataset(g2)
        end

        function verifyHappyAlongRowMerge(testCase, g1, g2, merge_result)
            fprintf('merge_result:  ')
            TestMergeTwo.print_dataset(merge_result)

            expected_num_cols = length(g1.cid);
            N_rid1 = length(g1.rid);
            N_rid2 = length(g2.rid);
            expected_num_rows = N_rid1 + N_rid2;

            testCase.verifyEqual(expected_num_cols, size(merge_result.mat, 2), 'result did not have expected number of columns')
            testCase.verifyEqual(expected_num_rows, size(merge_result.mat, 1), 'result did not have expected number of rows')

            [~, sort_ord_mr_cid] = sort(merge_result.cid);
            [~, sort_ord_cid1] = sort(g1.cid);
            comparison = g1.mat(:, sort_ord_cid1) == merge_result.mat(1:N_rid1, sort_ord_mr_cid);
            comparison = comparison(:);
            testCase.verifyEqual(length(comparison), sum(comparison), 'expected values from the 1st merging matrix were not found at the expected location within the result matrix')

            [~, sort_ord_cid2] = sort(g2.cid);
            comparison = g2.mat(:, sort_ord_cid2) == merge_result.mat((length(g1.rid)+1):end, sort_ord_mr_cid);
            comparison = comparison(:);
            testCase.verifyEqual(length(comparison), sum(comparison), 'expected values from 2nd merging matrix were not found at the expected location within the result matrix')

            comparison = cell2mat(g1.cdesc(sort_ord_cid1)) == cell2mat(merge_result.cdesc(sort_ord_mr_cid));
            comparison = comparison(:);
            testCase.verifyEqual(length(comparison), sum(comparison), 'expected cdesc from 1st dataset does not match cdesc in merged result')

            testCase.verifyTrue(all(strcmp(g1.rid, merge_result.rid(1:N_rid1))), 'expected first rids of result dataset to match rids of first input dataset')
            testCase.verifyTrue(all(strcmp(g2.rid, merge_result.rid((N_rid1+1):end))), 'expected last rids of result dataset to match rids of second input dataset')

            comparison = strcmp(g1.rdesc, merge_result.rdesc(1:N_rid1, :));
            comparison = comparison(:);
            testCase.verifyTrue(all(comparison), 'expected first rdesc entries of result dataset to match rdesc entries of first input dataset')

            comparison = strcmp(g2.rdesc, merge_result.rdesc((N_rid1+1):end, :));
            comparison = comparison(:);
            testCase.verifyTrue(all(comparison), 'expected last rdesc entries of result dataset to match rdesc entries of second input dataset')
        end

        function [g1, g2] = buildDatasetsForUnhappyAlongColumnsMerge()
            cid1 = {'a', 'b', 'c'};
            rid1 = {'1', '2', '3'};
            g1 = mkgctstruct(rand(length(rid1), length(cid1)), 'cid', cid1, 'rid', rid1);

            cid2 = {'d', 'e'};
            rid2 = {'2', '3'};
            g2 = mkgctstruct(rand(length(rid2), length(cid2)), 'cid', cid2, 'rid', rid2);
        end

        function [g1, g2] = buildDatasetsForUnhappyAlongRowsMerge()
            cid1 = {'a', 'b', 'c'};
            rid1 = {'1', '2', '3'};
            g1 = mkgctstruct(rand(length(rid1), length(cid1)), 'cid', cid1, 'rid', rid1);

            cid2 = {'a', 'c'};
            rid2 = {'4', '5'};
            g2 = mkgctstruct(rand(length(rid2), length(cid2)), 'cid', cid2, 'rid', rid2);
        end
    end

    methods(Test)
        function testAutoDetermineAlongColumns(testCase)
            fprintf('testAutoDetermineAlongColumns\n')

            [cid1, cid2, rid, g1, g2] = TestMergeTwo.buildDatasetsForHappyAlongColumnMerge();
            
            r = merge_two(g1, g2, 'merge_direction', 'auto-determine');

            TestMergeTwo.verifyHappyAlongColumnMerge(testCase, cid1, cid2, rid, g1, g2, r);
        end

        function testAutoDetermineAlongRows(testCase)
            fprintf('testAutoDetermineAlongRows\n')

            [g1, g2] = TestMergeTwo.buildDatasetsForHappyAlongRowMerge();

            r = merge_two(g1, g2, 'merge_direction', 'auto-determine');

            TestMergeTwo.verifyHappyAlongRowMerge(testCase, g1, g2, r);
        end

        function testAutoDetermineMismatchRidsCausesException(testCase)
            fprintf('testAutoDetermineMismatchRidsCausesException\n')

            [g1, g2] = TestMergeTwo.buildDatasetsForUnhappyAlongColumnsMerge();

            testCase.verifyError(@()merge_two(g1, g2, 'merge_direction', 'auto-determine'), 'merge_two:cannotDetermineMergeDirection')
        end

        function testAutoDetermineMismatchCidsCausesException(testCase)
            fprintf('testAutoDetermineMismatchCidsCausesException\n')

            [g1, g2] = TestMergeTwo.buildDatasetsForUnhappyAlongRowsMerge();

            testCase.verifyError(@()merge_two(g1, g2, 'merge_direction', 'auto-determine'), 'merge_two:cannotDetermineMergeDirection')
        end

        function testAlongColumns(testCase)
            fprintf('testAlongColumns\n')

            [cid1, cid2, rid, g1, g2] = TestMergeTwo.buildDatasetsForHappyAlongColumnMerge();

            r = merge_two(g1, g2, 'merge_direction', 'along-columns');

            TestMergeTwo.verifyHappyAlongColumnMerge(testCase, cid1, cid2, rid, g1, g2, r);
        end

        function testAlongColumnsMismatchRidsCausesException(testCase)
            fprintf('testAlongColumnsMismatchRidsCausesException\n')

            [g1, g2] = TestMergeTwo.buildDatasetsForUnhappyAlongColumnsMerge();

            testCase.verifyError(@()merge_two(g1, g2, 'merge_direction', 'along-columns'), 'merge_two:cannotMergeAlongColumns')
        end

        function testAlongRows(testCase)
            fprintf('testAlongRows\n')

            [g1, g2] = TestMergeTwo.buildDatasetsForHappyAlongRowMerge();

            r = merge_two(g1, g2, 'merge_direction', 'along-rows');

            TestMergeTwo.verifyHappyAlongRowMerge(testCase, g1, g2, r);
        end

        function testAlongRowsMismatchCidsCausesException(testCase)
            fprintf('testAlongRowsMismatchCidsCausesException\n')

            [g1, g2] = TestMergeTwo.buildDatasetsForUnhappyAlongRowsMerge();

            testCase.verifyError(@()merge_two(g1, g2, 'merge_direction', 'along-rows'), 'merge_two:cannotMergeAlongRows')
        end
    end
end
