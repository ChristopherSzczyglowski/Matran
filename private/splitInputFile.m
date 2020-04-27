function [execControl, caseControl, bulkData, unresolvedBulk] = splitInputFile(data, logfcn)
%splitInputFile Splits the contents of a Nastran file into 'execControl',
%'caseControl' and 'bulkData'.
%
% Syntax:
%	- Split the Nastran input file using the file path as the starting
%	  point:
%       >> filename = 'myTestFile.dat';
%       >> [ec, cc, bd, extra] = splitInputFile(filename)
%   - Split the Nastran input file by passing in the file contents:
%       >> filename      = 'myTestFile.dat';
%       >> file_contents = readCharDataFromFile(filename);
%       >> [ec, cc, bd, extra] = splitInputFile(file_contents);
%   - Using a log function to output diagnostics
%       >> log_fcn  = @(s) fprintf('%s\n', s)
%       >> filename = 'myTestFile.dat';
%       >> [ec, cc, bd, extra] = splitInputFile(filename, log_fcn)
%
% Detailed Description:
%	- 'execControl' and 'caseControl' are split by the keyword "CEND".
%   - 'caseControl' and 'bulkData' are split by the keyword "BEGIN BULK".
%
% See also: 
%
% References:
%	[1]. MSC.Nastran Getting Started User Guide
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 19-Apr-2020 15:09:54
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 19-Apr-2020 15:09:54
%	- Initial function:
%
% <end_of_pre_formatted_H1>

if nargin < 2
   logfcn = @(s) fprintf(''); %dummy function
end
if ischar(data) && exist(data, 'file') == 2 %Go from a file
    data = readCharDataFromFile(data);
end    
assert(iscellstr(data), 'Expected ''data'' to be a cell-array of strings.'); %#ok<ISCLSTR>

%Remove empty lines
%data = data(~cellfun(@(x) isempty(x), data));

%Logical indexing
idx_EC = contains(data, 'CEND');
idx_BD = contains(data, 'BEGIN BULK');

%Linear indexing
indEC = find(idx_EC == true);
indBD = find(idx_BD == true);

%Check for occurence of 'BEGIN BULK'
if ~any(idx_BD) %If not found, assume all is bulk
    execControl = {};
    caseControl = {};
    [bulkData, unresolvedBulk] = i_parseBulkData(data);
    logfcn(['Did not find tokens ''CEND'' or ''BEGIN BULK''. ', ...
        'Assuming all file contents are bulk data.']);
    return
end

%Grab the data
execControl = data(1 : indEC - 1);
caseControl = data(indEC + 1 : indBD - 1);
bulkData    = data(indBD + 1 : end);

%Remove "ENDDATA" from the BulkData cell array
bulkData(contains(bulkData, 'ENDDATA')) = [];

[bulkData, unresolvedBulk] = i_parseBulkData(bulkData);

logfcn(['Input data split into ''Executive Control'', ', ...
    '''Case Control'' and ''Bulk Data'' sections.']);

    function [bulkData, unresolvedBulk] = i_parseBulkData(bulkData)
        %i_parseBulkData Stashes any line that have less than 8 characters
        %in the variable 'unresolvedBulk' and retains only the lines that
        %have 8 characters or more.
        %
        % N.B. Any line that has less than 8 characters is likely to be a
        % system command.
        nChar = cellfun(@numel, bulkData);
        idx = and(nChar < 8, nChar > 1);
        unresolvedBulk = bulkData(idx);
        bulkData       = bulkData(~idx);        
    end

end
