import matlab.unittest.TestSuite
import matlab.unittest.TestRunner

suite = TestSuite.fromClass(?ExampleTest);

runner = TestRunner.withNoPlugins;

runner.addPlugin(DetailsRecordingPlugin)
result = runner.run(suite);