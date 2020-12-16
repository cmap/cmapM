classdef TestCosineSimilarity < matlab.unittest.TestCase
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
        
        function testTwoColumnVectors(testCase)
            vec1 = [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]';
            vec2 = [0, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0]';
            % 0.2357023, R-2.14.0 cosine function from lsa package
            exp_s = 0.2357023;
            s = cosine_similarity(vec1, vec2);
            testCase.verifyEqual(s, exp_s, 'absTol', testCase.tolerance);
        end
        
        function testMatrixXX(testCase)
            vec1 = [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]';
            vec2 = [0, 0, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0]';
            m = [vec1, vec2];
            exp_s = [1, 0.2357023; 0.2357023, 1];
            s = cosine_similarity(m);
            testCase.verifyEqual(s, exp_s, 'absTol', testCase.tolerance);
        end
        
        function testSingleVsDuplicated(testCase)
            % standardized input
            x = rand(100, 5);
            s1 = cosine_similarity(x);
            s2 = cosine_similarity(x, x);
            testCase.verifyEqual(s1, s2, 'absTol', testCase.tolerance);
        end
        
        function testZeroMag(testCase)
            vec1 = [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]';
            vec2 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]';
            s = cosine_similarity(vec1, vec2);
            testCase.verifyTrue(isnan(s));
        end
        
        function testCompareToPDist(testCase)
            ntrial = 100;
            max_samp = 20;
            max_feature = 10;
            % features x samples
            for ii=1:ntrial
                nf = max(randi(max_feature, 1), 5);
                x = rand(nf, randi(max_samp, 1));
                y = rand(nf, randi(max_samp, 1));
                ref = squareform(1-pdist([x, y]', 'cosine'));
                exp_s = ref(1:size(x, 2), size(x,2)+1:end);
                s = cosine_similarity(x, y);
                err = rmse(s, exp_s);
                if err>1e-8
                    dbg(1, 'RMSE: %f', err)
                    disp(x)
                    disp(y)
                end
                testCase.verifyEqual(s, exp_s, 'absTol', testCase.tolerance);
            end
        end        
    end
end