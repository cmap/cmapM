classdef TestGrpSize2Idx < matlab.unittest.TestCase
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
            sz = [2, 4, 1, 3];
            ngroup = length(sz);
            nmember = sum(sz);
            idx = grpsize2idx(sz);
            testCase.verifyEqual(length(idx), nmember, 'Length mismatch');
            testCase.verifyEqual(unique(idx), (1:ngroup)', 'group index mismatch');
        end

        function testCustomValues(testCase)
            sz = [2; 4; 1; 3];
            vals = [10; 15; -10; 5];
            ngroup = length(sz);
            nmember = sum(sz);
            idx = grpsize2idx(sz, vals);
            testCase.verifyEqual(length(idx), nmember, 'Length mismatch');
            testCase.verifyEqual(unique(idx), unique(vals), 'group index mismatch');
        end

                      
    end 
end