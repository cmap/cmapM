classdef TestScaleMatrix < matlab.unittest.TestCase
    % Tests for the scale_matrix function
    % To match the R scale function
    % https://www.rdocumentation.org/packages/base/versions/3.4.3/topics/scale

    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        tolerance = 1e-6;
        assets = [];
    end
    methods(TestMethodSetup)
        function setupMatrix(testCase)
            x = reshape(1:10, 5, 2);
            testCase.assets = struct('x', x);
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        
        function testDefault(testCase)
            % center and scale, the default
            x = testCase.assets.x;
            ctst = scale_matrix(x);
            ctst_expect = [-1.2649111, -1.2649111;...
                -0.6324555, -0.6324555;...
                0,  0;...
                0.6324555,  0.6324555;...
                1.2649111,  1.2649111];
            testCase.verifyEqual(ctst, ctst_expect, 'absTol', testCase.tolerance);
        end
        
        function testCTST(testCase)
            % Center and scale
            x = testCase.assets.x;
            ctst = scale_matrix(x, true, true);
            % expected result
            ctst_expect = [-1.2649111, -1.2649111;...
                -0.6324555, -0.6324555;...
                0,  0;...
                0.6324555,  0.6324555;...
                1.2649111,  1.2649111];
            testCase.verifyEqual(ctst, ctst_expect, 'absTol', testCase.tolerance);
        end
        
        function testCTSF(testCase)
            % Center but dont scale
            x = testCase.assets.x;
            ctsf = scale_matrix(x, true, false);
            % expected result
            ctsf_expect = repmat((-2:2)', 1, 2);
            testCase.verifyEqual(ctsf, ctsf_expect, 'absTol', testCase.tolerance);
        end
        
        function testCFST(testCase)
            % Dont center but scale
            x = testCase.assets.x;
            cfst = scale_matrix(x, false, true);
            cfst_expect = [0.2696799 0.6605783;...
                0.5393599 0.7706746;...
                0.8090398 0.8807710;...
                1.0787198 0.9908674;...
                1.3483997 1.1009638];
            testCase.verifyEqual(cfst, cfst_expect, 'absTol', testCase.tolerance);
        end
        
        function testCFSF(testCase)
            % Do nothing
            x = testCase.assets.x;
            cfsf = scale_matrix(x, false, false);
            testCase.verifyEqual(cfsf, x, 'absTol', testCase.tolerance);
        end
        
    end
end