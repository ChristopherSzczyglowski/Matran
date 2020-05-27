%% run_micro_tests
% Executes the unit tests which ensure basic functionality.
%
% Syntax:
%	- Run the tests
%       >> run_micro_tests
%
% Detailed Description:
%	-  Executes the unit tests which ensure basic functionality. 
%       + Object construction (Matran/bulk/dynamicable)
%       + Object methods (get, isequal, addItem)
%
% See also: matlab.unittest.TestSuite
%           matlab.unittest.TestRunner
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 02-May-2020 14:42:06
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 02-May-2020 14:42:06
%	- Initial function:
%
% <end_of_pre_formatted_H1>

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner

tests = TestSuite.fromClass(?TestMatran);
names = {tests.ProcedureName};
idx = any([ ...
    startsWith(names, 'dynamicable') ; ...
    startsWith(names, 'bulk')        ; ...
    startsWith(names, 'obj')         ; ...
    startsWith(names, 'collector')]);
suite = tests(idx);

TestResults  = run(suite);
ResultsTable = table(TestResults);
disp(ResultsTable)