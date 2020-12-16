classdef TestPlotSc < matlab.unittest.TestCase
    properties
    end

    methods(TestMethodSetup)
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        function test(testCase)
	    ss = [1.1 2.2 3.3];
	    cc = [0.1 0.2 0.3];
	    gp = ['a'
	          'b'
		  'c'];
            topn = 100;

	    %these varargin values are set to be type single to reproduce an intermittent error
	    %in which a single value is provided and parse_args does not convert it to a double
	    %precision causing the "text" method in plot_sc to fail
	    varargin = {'ss_cutoff', single(6), 'cc_cutoff', single(0.25), 'xlim', single([-1, 1]), ...
	        'ylim', single([0, 20])};

            [h, quad] = plot_sc(ss, cc, gp, topn, varargin);

            testCase.verifyEqual(3, quad.n);
	    testCase.verifyEqual(true, ~isempty(h));
        end
    end 
end

