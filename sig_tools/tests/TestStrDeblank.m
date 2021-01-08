classdef TestStrDeblank < matlab.unittest.TestCase
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
                    
        function testDefault(testCase)
            
            test_str = {' abc', 'bcd ', 'xyz'};
            exp_str = {'abc', 'bcd', 'xyz'};
            
            res_str = str_deblank(test_str);
            
            testCase.verifyEqual(res_str, exp_str, 'String mismatch');
        end

        function testLeading(testCase)
            
            test_str = {' abc', 'bcd ', 'xyz'};
            exp_str = {'abc', 'bcd ', 'xyz'};
            
            res_str = str_deblank(test_str, 'leading');
            
            testCase.verifyEqual(res_str, exp_str, 'String mismatch');
        end
        
        function testTraling(testCase)
            
            test_str = {' abc', 'bcd ', 'xyz'};
            exp_str = {' abc', 'bcd', 'xyz'};
            
            res_str = str_deblank(test_str, 'trailing');
            
            testCase.verifyEqual(res_str, exp_str, 'String mismatch');
        end
        
        
        
    end 
end