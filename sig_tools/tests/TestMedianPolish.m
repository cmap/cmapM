classdef TestMedianPolish < matlab.unittest.TestCase
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
        function testPolish(testCase)        
            x = [14, 15, 14; 7, 4, 7; 8, 2, 10; 15, 9, 10; 0, 2, 0];            
            [re, ce, ge, res] = median_polish(x);
            d = x - (bsxfun(@plus, re, ce) + ge + res);            
            testCase.verifyTrue(all(abs(d(:))<eps), 'Invalid median polish decomposition');      
        end              
    end 
end