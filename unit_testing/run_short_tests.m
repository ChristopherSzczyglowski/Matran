%% run_short_tests
%Short explanation of the function...
%
% Syntax:
%	- Run short tests
%       >> run_short_tests
%
% Detailed Description:
%	- Runs all import tests except those which use large files
%   - Also runs the micro tests in 'run_micro_tests'.
% 
% See also: 
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 02-May-2020 14:57:05
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 02-May-2020 14:57:05
%	- Initial function:
%
% <end_of_pre_formatted_H1>

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.selectors.HasParameter;
import matlab.unittest.selectors.HasProcedureName;

import_suite = TestSuite.fromClass(?TestMatran, 'ProcedureName','*import*');

%Filter tests with large import files
large_bdf = fullfile(fileparts(matlab.desktop.editor.getActiveFilename), ...
    '\models\auto_generated_h5_data\bd03fix_temp.h5');
import_suite = import_suite.selectIf(~HasParameter( ...
    'Property', 'TPLTextImportFiles', 'Value', '\doc\dynamics\bd03fix.dat'));
import_suite = import_suite.selectIf(~HasParameter( ...
    'Property', 'AutoH5Files', 'Value', large_bdf));

TR_ = run(import_suite);

run_micro_tests;
TestResults = [TR_, TestResults];
ResultsTable = table(TestResults);
disp(ResultsTable)