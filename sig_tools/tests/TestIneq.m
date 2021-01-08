classdef TestIneq < matlab.unittest.TestCase
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
        %% Tests for the weightedGini method
        % Unweighted Gini tests
        function testUnWeightedGiniMultiple(testCase)
            n = randsample(5000, 100);
            ntest = length(n);            
            for ii=1:ntest
                exp_value = (1-1/n(ii))/3;
                x = (1:n(ii))';
                test_value = mortar.compute.Inequality.weightedGini(x);
                testCase.verifyEqual(test_value, exp_value, 'absTol', testCase.tolerance);
            end
        end
        
        % Weighted Gini tests
        function testWeightedGiniMultiple(testCase)
            n = randsample(5000, 100);
            ntest = length(n);            
            for ii=1:ntest
                exp_value = 0.2*(n(ii)-1)*(n(ii)+2)/(n(ii)*(n(ii)+1));
                x = (1:n(ii))';
                w = x;
                test_value = mortar.compute.Inequality.weightedGini(x, w);
                testCase.verifyEqual(test_value, exp_value, 'absTol', testCase.tolerance);
            end
        end      
        
        function testWeightedGiniReference(testCase)
            x = [3; 1; 7; 2; 5];
            w = [1; 2; 3; 4; 5];
            exp_value = 0.2983050847;
            test_value = mortar.compute.Inequality.weightedGini(x, w);
            testCase.verifyEqual(test_value, exp_value, 'absTol', testCase.tolerance);
        end
        
        function testUnWeightedGiniReference(testCase)
            exp_value = 0.25;
            test_value = mortar.compute.Inequality.weightedGini([0.25; 0.75]);            
            testCase.verifyEqual(test_value, exp_value, 'absTol', testCase.tolerance);
        end   
        
        function testUnWeightedGiniEquality(testCase)
            % test of equality
            exp_value = 0;
            test_value = mortar.compute.Inequality.weightedGini(ones(5, 1));
            testCase.verifyEqual(test_value, exp_value, 'absTol', testCase.tolerance);
        end
        
        %% Tests for ineq method
        function testGiniColumnVec(testCase)
            import mortar.compute.Inequality
            % single column vector with NaN
            x = [541; 1463; 2445; 3438; 4437; 5401; 6392; 8304; 11904; 22261; nan];
            % R result:  0.4620911
            gc = Inequality.ineq(x, 'type', 'gini');
            testCase.verifyEqual(gc, 0.4620911, 'absTol', testCase.tolerance);                 
        end
        
        function testGiniMatrixByColumn(testCase)
            import mortar.compute.Inequality
            % matrix with missing values            
            x1 = [541; 1463; 2445; 3438; 4437; 5401; 6392; 8304; 11904; 22261; nan];
            x2 = [541; nan; 2445; 3438; 4437; 5401; 6392; 8304; 11904; 22261; nan];
            x = [x1, x2];
            exp_result = [0.4620911; 0.4331769];
            gc = Inequality.ineq(x, 'type', 'gini');
            testCase.verifyEqual(gc, exp_result, 'absTol', testCase.tolerance);
        end
        
        function testGiniMatrixByRow(testCase)
            import mortar.compute.Inequality
            % matrix with missing values            
            x1 = [541; 1463; 2445; 3438; 4437; 5401; 6392; 8304; 11904; 22261; nan];
            x2 = [541; nan; 2445; 3438; 4437; 5401; 6392; 8304; 11904; 22261; nan];
            x = [x1, x2]';
            exp_result = [0.4620911; 0.4331769];
            gc = Inequality.ineq(x, 'type', 'gini', 'dim', 2);
            testCase.verifyEqual(gc, exp_result, 'absTol', testCase.tolerance);
        end

        function testGiniEqualProportion(testCase)
            import mortar.compute.Inequality
            % Equal proportion of values
            x = [ones(5,1); zeros(5,1)];
            exp_result = 0.5;
            gc = Inequality.ineq(x, 'type', 'gini');
            testCase.verifyEqual(gc, exp_result, 'absTol', testCase.tolerance);
        end
        
        function testGiniEqualValues(testCase)
            import mortar.compute.Inequality
            % Equal values
            x = ones(10,1);
            exp_result = 0;
            gc = Inequality.ineq(x, 'type', 'gini');
            testCase.verifyEqual(gc, exp_result, 'absTol', testCase.tolerance);
        end
        
        
        function testAktinsonMatrixByColumn(testCase)
            import mortar.compute.Inequality
            % matrix with missing values
            x1 = [541; 1463; 2445; 3438; 4437; 5401; 6392; 8304; 11904; 22261; nan];
            x2 = [541; nan; 2445; 3438; 4437; 5401; 6392; 8304; 11904; 22261; nan];
            x = [x1, x2];
            exp_result = [0.1796591; 0.1620009];
            gc = Inequality.ineq(x, 'type', 'atkinson');
            exp_result2 = [0.3518251; 0.3273538];
            gc2 = Inequality.ineq(x, 'type', 'atkinson', 'parameter', 1);
            testCase.verifyEqual(gc, exp_result, 'absTol', testCase.tolerance);
            testCase.verifyEqual(gc2, exp_result2, 'absTol', testCase.tolerance);
        end
        
        
        function testAtkinsonEqualProportion(testCase)
            import mortar.compute.Inequality
            % Equal proportion of values
            x = [ones(5,1); zeros(5,1)];
            exp_result = 0.5;
            gc = Inequality.ineq(x, 'type', 'atkinson');
            testCase.verifyEqual(gc, exp_result, 'absTol', testCase.tolerance);
        end
        
        function testAtkinsonEqualValues(testCase)
            import mortar.compute.Inequality
            % Equal values
            x = ones(10,1);
            exp_result = 0;
            gc = Inequality.ineq(x, 'type', 'atkinson');
            testCase.verifyEqual(gc, exp_result, 'absTol', testCase.tolerance);
        end
        
    end 
end