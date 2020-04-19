function writeIncludeStatement(fid, files)
%writeIncludeStatement Writes an INCLUDE entry in the file with ID 'fid'
%and referencing the file at file-path 'filename'.
%
% Syntax:
%	- Write an inlcude statement in a file
%       >> fid = fopen('myFile.dat', 'w');
%       >> writeInludeStatement(fid, 'thisIsMyIncludeFile.bdf');
%
% Detailed Description:
%	- Honours the 80 character character width limit for the Nastran input.
%   - The format of the INCLUDE statement is:
%     <--------72 char------->
%     INCLUDE 'longFilePath'
%   - The format for the INCLUDE statement when the
%     filepath is greater than 63 characters is:
%     <--------72 char------->
%     INCLUDE 'dir1\dir2\dir3
%              \dir4\dir5\...'
%   - The length of each line of the INCLUDE statment
%     cannot exceed 72 characters. If the length of the
%     file path is greater than 63 characters then it  must
%     be split over multiple lines.
%   - Where possible the file path will be split using the
%    '\' delimiter toseperate multiple lines.
%
% See also:
%
% References:
%	[1]. MSC.Nastran Quick Reference Guide.
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 15-Apr-2020 13:37:56
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 15-Apr-2020 13:37:56
%	- Initial function:
%
% <end_of_pre_formatted_H1>

if ~iscell(files)
    files = {files};
end
assert(fid ~= -1, 'Expected ''fid'' to be a valid file identifier.');
assert(iscellstr(files), ['Expected ''filenames'' to be a ', ...
    'cell-array of filenames.']); %#ok<ISCLSTR>

files(cellfun(@isempty, files)) = [];

for iF = 1 : numel(files)
    %Format the file path so it fits in the 72 character width for the
    %MSC.Nastran bulk data input file
    formattedFile = i_formatFilePath(files{iF});
    %Print the INCLUDE statement
    fprintf(fid, '%-s\n', formattedFile{:});
end

end

function newPath = i_formatFilePath(filePath)
%i_formatFilePath Returns the file path in a form that is
%suitable for printing with the MSC.Nastran INCLUDE
%statement

%Maximum number of characters after "INCLUDE" command
maxLineLength = 62;

pathLength = length(filePath);
%Check if filepath needs formatting
%   - if the '\' character is not present the file is in the local
%     directory and does not require any formatting
%   - if the length of the file path is less than < 63 characters
if ~ismember(filesep, filePath) || pathLength < 63
    newPath = {['INCLUDE ''%s''', filePath]};
    return
end

% how many continuation lines are required?
nLines = ceil(pathLength ./ maxLineLength) + 1;

% get subfolder strings
subFolders = strsplit(filePath, '\');

% define anonymous function for calculating length of each subfolder string
getFL = @(x)(cellfun(@(y)length(y), x) + [0, ones(1, length(x) - 1)]);

% check lengths to see if a single folder will fit the line
if any(getFL(subFolders) > maxLineLength)
    %Apply messy formatting
    %   - Just cut filepath at end of line
    nCharFinalLine = mod(pathLength, maxLineLength);
    interData   = filePath(1 : pathLength - nCharFinalLine);
    nInterLines = numel(interData)/maxLineLength;
    newPath     = cellstr(reshape(interData, [maxLineLength, nInterLines])');
    newPath{end+1} = filePath(pathLength - nCharFinalLine + 1 : end);
    %Set flag
    format = 'messy';
else
    %Use neat formatting
    %   - Cut each line at a filepath delimiter.
    
    % preallocate
    ind     = zeros(1, nLines);
    newPath = cell(1, nLines);
    
    % loop through each continuation and assemble part of the file path
    for iL = 1 : nLines
        % if no folders remain then exit the loop
        if isempty(subFolders)
            % remove any empty cells
            newPath(cellfun('isempty', newPath)) = [];
            break
        end
        % find length of remaining folders
        folderLength = getFL(subFolders);
        % find the most amount of data that can be put on each line
        temp = cumsum(folderLength);
        % how many folders should be included on this line?
        ind(iL) = find(temp < maxLineLength, 1, 'last');
        % assign data to the line
        newPath{iL} = strjoin(subFolders(1 : ind(iL)), '\');
        % assign remaining sub folders to 'subFolders'
        subFolders = subFolders(ind(iL) + 1 : end);
    end
    %Set flag
    format = 'neat';
end

% append the "INCLUDE '" string to the first line
newPath{1} = ['INCLUDE ''', newPath{1}];

%Define pad vector for each line
switch format
    case 'messy'
        padVec = {blanks(9)};
    case 'neat'
        padVec = {[blanks(9), '\']};
end

% pad lines 2 : end with 8 blanks to account for "INCLUDE '" on line 1
newPath(2 : end) = strcat(padVec, newPath(2 : end));

% add a terminating "'" to the final line
newPath{end} = [newPath{end}, ''''];

end
