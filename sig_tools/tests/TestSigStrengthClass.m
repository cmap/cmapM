classdef TestSigStrengthClass< matlab.unittest.TestCase
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
        
        function testAdjustZS(testCase)
            % test zs adjustment
            zs = randn(5,10);
            nrep = randsample(1:4, 10, true)';
            adj_zs = mortar.compute.SigStrength.adjustZscore(zs, nrep);
            
            for ii=1:size(zs, 2)
                testCase.assertEqual(adj_zs(:,ii),...
                    zs(:,ii)*sqrt(nrep(ii)),...
                    'AbsTol', testCase.tolerance);
            end
        end
        
        function testAdjustZSNegative(testCase)
            % test failure if nrep is negative
            zs = randn(5,10);
            nrep = -randsample(1:4, 10, true)';
            failed = true;
            try
                adj_zs = mortar.compute.SigStrength.adjustZscore(zs, nrep);
            catch e
                failed = true;
            end           
            testCase.assertTrue(failed);
        end
    end
end




