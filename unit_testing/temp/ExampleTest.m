classdef ExampleTest < matlab.unittest.TestCase
    properties
        SampleSize = 100;
    end

    properties (TestParameter) 
        seed = num2cell(randi(10^6,1,25));
    end
        
    methods(Test)
        function testMean(testCase,seed)
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.AbsoluteTolerance
            rng(seed)
            testCase.assertThat(mean(randn(1,testCase.SampleSize)),...
                IsEqualTo(0,'Within',AbsoluteTolerance(0.1)));
        end
    end
end