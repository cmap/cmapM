classdef TestGetTopN < matlab.unittest.TestCase
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        tolerance = 1e-6;
        testMatrixWithNaN = [1, 1;
                             NaN, NaN;
                             5, NaN;
                             -10, -5;
                             100, 200];
    end
    methods(TestMethodSetup)
        
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)        
        function testTwoTailedByColumn(testCase)
            X = randn(25, 10);
            N = 5;
            [srtx, isrt] = sort(X, 1, 'descend');
            exp_y = [srtx(1:N, :); srtx(end-N+1:end, :)];
            exp_iy = bsxfun(@plus, [isrt(1:N, :); isrt(end-N+1:end, :)],...
                        (0:size(X, 2)-1)*size(X, 1));
            [y, iy] = get_topn(X, N, 1, 'descend', true);
            testCase.verifyEqual(y, exp_y, 'absTol', testCase.tolerance);
            testCase.verifyEqual(iy, exp_iy, 'absTol', testCase.tolerance);                        
        end
        
        function testTwoTailedByRow(testCase)
            X = randn(10, 25);
            N = 5;
            [srtx, isrt] = sort(X, 2, 'descend');
            exp_y = [srtx(:, 1:N), srtx(:, end-N+1:end)];
            exp_iy = bsxfun(@plus, (1:size(X, 1))',...
                ([isrt(:, 1:N), isrt(:, end-N+1:end)]-1)*size(X, 1));
            [y, iy] = get_topn(X, N, 2, 'descend', true);
            testCase.verifyEqual(y, exp_y, 'absTol', testCase.tolerance);
            testCase.verifyEqual(iy, exp_iy, 'absTol', testCase.tolerance);                        
        end        
        
        function testOneTailedByColumnWithNaN(testCase)    
            % top 2 rows from each column
            exp_y = [100, 200;
                5, 1];
            exp_iy = [5, 10;
                3, 6];            
            [y, iy] = get_topn(testCase.testMatrixWithNaN, 2, 1, 'descend', false);
            testCase.verifyEqual(y, exp_y, 'absTol', testCase.tolerance);
            testCase.verifyEqual(iy, exp_iy, 'absTol', testCase.tolerance);
        end
        
        function testOneTailedByRowWithNaN(testCase)
            % top 2 rows from each column
            exp_y = [1
                     NaN
                     5
                     -5
                     200];
            exp_iy = [6
                      2
                      3
                      9
                      10];
            [y, iy] = get_topn(testCase.testMatrixWithNaN, 1, 2, 'descend', false);
            testCase.verifyEqual(y, exp_y, 'absTol', testCase.tolerance);
            testCase.verifyEqual(iy, exp_iy, 'absTol', testCase.tolerance);
        end

    end
end