classdef TestFastCorr < matlab.unittest.TestCase
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        tolerance = 1e-6;
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testPearsonXY(testCase)
            % bivariate, compare with native implementation
            x = rand(100, 5);
            y = rand(100, 5);
            r1 = fastcorr(x, y);
            r2 = corr(x, y);            
            testCase.verifyEqual(r1, r2, 'absTol', testCase.tolerance);
        end
        
        function testPearsonXX(testCase)
            % univariate, compare with native implementation
            x = rand(100, 1);
            r1 = fastcorr(x);
            r2 = corr(x);
            testCase.verifyEqual(r1, r2, 'absTol', testCase.tolerance);
        end
        
        function testPearsonStd(testCase)
            % standardized input
            x = rand(100, 1);
            zx = zscore(x);
            r1 = fastcorr(zx, 'type', 'pearson', 'is_standardized', true);
            r2 = fastcorr(x, 'type', 'pearson', 'is_standardized', false);
            testCase.verifyEqual(r1, r2, 'absTol', testCase.tolerance);
        end
        
        function testSpearmanXY(testCase)
            
            x = rand(100, 1);
            y = rand(100, 1);
            r1 = fastcorr(x, y, 'type', 'spearman');
            r2 = corr(x, y, 'type', 'spearman');            
            testCase.verifyEqual(r1, r2, 'absTol', testCase.tolerance);
        end
                
        function testSpearmanXX(testCase)
            x = rand(100, 1);
            r1 = fastcorr(x, 'type', 'spearman');
            r2 = corr(x, 'type', 'spearman');            
            testCase.verifyEqual(r1, r2, 'absTol', testCase.tolerance);
        end
        
         function testSpearmanStd(testCase)
            x = rand(100, 1);
            zx = zscore(x);
            r1 = fastcorr(zx, 'type', 'spearman', 'is_standardized', true);
            r2 = fastcorr(x, 'type', 'spearman', 'is_standardized', false);
            testCase.verifyEqual(r1, r2, 'absTol', testCase.tolerance);
        end
                      
    end 
end