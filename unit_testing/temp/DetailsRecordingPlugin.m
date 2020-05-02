classdef DetailsRecordingPlugin < matlab.unittest.plugins.TestRunnerPlugin
    properties (Constant, Access = private)
        ActField = 'ActualValue';
        ExpField = 'ExpectedValue';
    end
    
    methods (Access = protected)
        function runSession(plugin,pluginData)
            resultDetails = pluginData.ResultDetails;
            resultDetails.append(plugin.ActField,{})
            resultDetails.append(plugin.ExpField,{})
            runSession@matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
        end
        
        function fixture = createSharedTestFixture(plugin, pluginData)
            fixture = createSharedTestFixture@...
                matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            resultDetails = pluginData.ResultDetails;
            fixture.addlistener('AssertionPassed',...
                @(~,evd)plugin.reactToAssertion(evd,resultDetails));
            fixture.addlistener('AssertionFailed',...
                @(~,evd)plugin.reactToAssertion(evd,resultDetails));
        end
        
        function testCase = createTestClassInstance(plugin,pluginData)
            testCase = createTestClassInstance@...
                matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
            resultDetails = pluginData.ResultDetails;
            testCase.addlistener('AssertionPassed',...
                @(~,evd)plugin.reactToAssertion(evd,resultDetails));
            testCase.addlistener('AssertionFailed',...
                @(~,evd)plugin.reactToAssertion(evd,resultDetails));
        end
        
        function testCase = createTestMethodInstance(plugin,pluginData)
            testCase = createTestMethodInstance@...
                matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
            resultDetails = pluginData.ResultDetails;
            testCase.addlistener('AssertionPassed',...
                @(~,evd)plugin.reactToAssertion(evd,resultDetails));
            testCase.addlistener('AssertionFailed',...
                @(~,evd)plugin.reactToAssertion(evd,resultDetails));
        end
    end
    
    methods (Access = private)
        function reactToAssertion(plugin,evd,resultDetails)
            if ~isa(evd.Constraint,'matlab.unittest.constraints.IsEqualTo')
                return
            end
            resultDetails.append(plugin.ActField,{evd.ActualValue})
            resultDetails.append(plugin.ExpField,{evd.Constraint.Expected})
        end
    end
end