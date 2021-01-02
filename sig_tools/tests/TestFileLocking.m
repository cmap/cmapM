classdef TestFileLocking < matlab.unittest.TestCase
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
                    
        function testLockUnlockSequence(testCase)
            
            test_lockfile=tempname;
            
            st=lock(test_lockfile);
            testCase.verifyTrue(abs(st-1)<eps, 'Lock not obtained');
            
            st=lock(test_lockfile);
            testCase.verifyTrue(abs(st)<eps, 'Lock did not fail on previously locked file');
            
            st=unlock(test_lockfile);
            testCase.verifyTrue(abs(st-1)<eps, 'Could not unlock');
            
            st=unlock(test_lockfile);
            testCase.verifyTrue(abs(st)<eps, 'Unlock did not fail on previously unlocked file');
           
        end

    end 
end
