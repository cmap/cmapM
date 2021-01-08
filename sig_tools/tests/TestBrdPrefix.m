classdef TestBrdPrefix < matlab.unittest.TestCase
    properties (Constant)
    end

    properties
    end

    methods(TestMethodSetup)
        %setup conditions for the tests
    end
    
    methods(TestMethodTeardown)
        %cleanup after running the tests
    end

    methods(Static)
    end

    methods(Test)
        function testJustBrds(testCase)
            fprintf('testJustBrds\n')
            r = brd_prefix({'BRD-K12345678-910-11-1', 'BRD-K21314151-617-18-1'})
            testCase.verifyTrue(all(strcmp('BRD-K12345678', r{1})))
            testCase.verifyTrue(all(strcmp('BRD-K21314151', r{2})))
        end

        function testBrdsAndNonBrd(testCase)
            fprintf('testBrdsAndNonBrd\n')
            r = brd_prefix({'BRD-K12345678-910-11-1', 'BRD-K21314151-617-18-1', 'GSK98761', 'hellow world'})
            testCase.verifyTrue(all(strcmp('BRD-K12345678', r{1})))
            testCase.verifyTrue(all(strcmp('BRD-K21314151', r{2})))
            testCase.verifyTrue(all(strcmp('GSK98761', r{3})))
            testCase.verifyTrue(all(strcmp('hellow world', r{4})))
        end

        function testJustNonBrds(testCase)
            fprintf('testJustNonBrds\n')
            r = brd_prefix({'GSK98761', 'hellow world'})
            testCase.verifyTrue(all(strcmp('GSK98761', r{1})))
            testCase.verifyTrue(all(strcmp('hellow world', r{2})))
        end
    end
end

