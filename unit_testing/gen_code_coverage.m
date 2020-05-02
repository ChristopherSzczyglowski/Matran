%% genCodeCoverage 
% Generates a code coverage report and obtains the product dependencies for
% the package.
%
% Syntax:
%	- Generate the code coverage report and return the product list.
%       >> genCodeCoverage;
%
% Detailed Description:
%	-  Generates a code coverage report and obtains the product
%	   dependencies for the package by running the test framework in
%	   'TestMatran.m'.
%
% See also: matlab.unittest.plugins.CodeCoveragePlugin
%           matlab.codetools.requiredFilesAndProducts
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 08-Mar-2020 15:18:58
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 08-Mar-2020 15:18:58
%	- Initial function:
%
% <end_of_pre_formatted_H1>

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.CodeCoveragePlugin

%Generate the code coverage report
suite  = TestSuite.fromClass(?TestMatran);
runner = TestRunner.withTextOutput;
runner.addPlugin(CodeCoveragePlugin.forFolder(pwd));
TestResult = runner.run(suite);

%Get the package dependencies
[fList, pList] = matlab.codetools.requiredFilesAndProducts('TestMatran.m');
