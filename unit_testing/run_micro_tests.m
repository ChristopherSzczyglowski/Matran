%% run_micro_tests
% Executes the unit tests which ensure basic functionality.
%
% Syntax:
%	- Run the tests
%       >> run_micro_tests
%
% Detailed Description:
%	-  Executes the unit tests which ensure basic functionality. 
%       + Test object construction
%       + Test object methods 
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

mc   = ?TestMatran;
dyn  = TestSuite.fromClass(mc, 'ProcedureName','*dynamicable*');
bulk = TestSuite.fromClass(mc, 'ProcedureName','*bulk*');

dyn  = dyn(startsWith({dyn.ProcedureName}  , 'dynamicable'));
bulk = bulk(startsWith({bulk.ProcedureName}, 'bulk'));

suite = [dyn, bulk];
TestResults  = run(suite);
ResultsTable = table(TestResults);
disp(ResultsTable)