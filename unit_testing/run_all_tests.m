%% run_all_tests
%Runs all tests in the TestMatran class. 
%
% Syntax:
%	- Run all tests in the TestMatran class.
%       >> run_all_tests
%
% Detailed Description:
%	- Runs everything.
%
% See also: 
%
% References:
%	[1].
%
% Author    : Christopher Szczyglowsk
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 02-May-2020 15:10:39
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 02-May-2020 15:10:39
%	- Initial function:
%
% <end_of_pre_formatted_H1>
import matlab.unittest.TestSuite
import matlab.unittest.TestRunner

suite        = TestSuite.fromClass(?TestMatran);
TestResults  = run(suite);
ResultsTable = table(TestResults);
disp(ResultsTable)