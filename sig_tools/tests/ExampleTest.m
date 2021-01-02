classdef ExampleTest < matlab.unittest.TestCase
    properties (Constant)
        my_constant_property = 'preface';
    end

    properties
        my_property = 4;
	another_property = [ExampleTest.my_constant_property ' ehllo'];
    end

    methods(TestMethodSetup)
        %setup conditions for the tests
    end
    
    methods(TestMethodTeardown)
        %cleanup after running the tests
    end

    methods(Test)
        function exampleTestObj = ExampleTest(arg)
	    exampleTestObj.another_property = upper(exampleTestObj.another_property);
        end

        function testOne(testCase)  % Test fails
            testCase.verifyEqual(5, 4, 'Testing 5==4')
        end
        function testTwo(testCase)  % Test passes
            testCase.verifyEqual(5, 5, 'Testing 5==5')
        end
        function testThree(testCase)  % test passes, uses a property
            testCase.verifyEqual(4, testCase.my_property, 'Testing 4 == my_property')
        end
	function testFour(testCase)
            testCase.verifyTrue(strcmp('PREFACE EHLLO', testCase.another_property), 'Testing constructor')
	end
    end
end
