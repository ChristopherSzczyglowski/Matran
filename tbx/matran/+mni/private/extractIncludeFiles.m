function [IncludeFiles, BulkData] = extractIncludeFiles(BulkData, logfcn, parentPath)
%extractIncludeFiles Extracts the path to any files containing
%data that is included in the bulk data.
%
% Syntax:
%	- Brief explanation of the syntax...
%
% Detailed Description:
%	- Detailed explanation of the function and how it works...
%
% See also: 
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 19-Apr-2020 16:03:13
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 19-Apr-2020 16:03:13
%	- Initial function:
%
% <end_of_pre_formatted_H1>

assert(iscellstr(BulkData), ['Expected ''bulkData'' to be a cell-array ', ...
    'of strings describing the bulk data in a Nastran input file.']); %#ok<ISCLSTR>
if nargin < 2 || isempty(logfcn)
    logfcn = @(s) fprintf('');
end
if nargin < 3
    parentPath = '';
end

%Find all lines containing "INCLUDE"
idx = contains(BulkData, 'INCLUDE');
ind = find(idx == true);

%Preallocate
IncludeIndex = cell(size(ind));
IncludeFiles = cell(size(ind));

if isempty(ind) %Escape route
    return
end

for iFile = 1 : numel(ind) %Extract path to the included file
    
    %Extract all data related to the "INCLUDE" card
    [cardData, IncludeIndex{iFile}] = getCardData(BulkData, ind(iFile));
    
    %Remove blanks and combine into one string
    filename = strtrim(cardData);
    filename = cat(2, filename{:});
    
    %Remove speech marks (if present)
    filename(strfind(filename, '"'))  = '';
    filename(strfind(filename, '''')) = '';
    
    %Remove "INCLUDE" keyword
    filename = filename(9 : end);
    
    %Check if absolute or relative path
    [path, ~, ~] = fileparts(filename);
    
    %Relative path will have an empty 'path' variable
    %   -> append with the current directory
    if isempty(path)
        filename = fullfile(parentPath, filename);
    end
    
    %Assign to cell array
    IncludeFiles{iFile} = filename;
    
end

%Remove all lines from 'BulkData' relating to INCLUDE
BulkData(cat(2, IncludeIndex{:})) = [];

%Inform progress
logfcn(sprintf('Found the following included files:'));
logfcn(sprintf('\t- %s\n', IncludeFiles{:}));

end
