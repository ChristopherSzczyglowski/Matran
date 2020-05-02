function rawFileData = readCharDataFromFile(filename, logfcn)
%readCharDataFromFile Reads the data from the file as literal text and
%return a cell-array where each element is a line in the file.
%
% Syntax:
%	- Extract the file data as text:
%       >> filename = 'mySampleFile.txt';
%       >> rawFileData = readCharDataFromFile(filename);
%   - Extract the file data and send diagnostics to a log function:
%       >> filename = 'mySampleFile.txt'
%       >> logfcn   = @(s) fprintf('%s\n', s)
%       >> rawFileData = readCharDataFromFile(filename, logfcn);
%
% Detailed Description:
%	- Extracts the data from the file whilst skipping comments 
%   - A comment is any line beginning with '$'.
%
% See also: 
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 19-Apr-2020 15:01:44
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 19-Apr-2020 15:01:45
%	- Initial function:
%
% <end_of_pre_formatted_H1>

if nargin < 2
   logfcn = @(s) fprintf(''); %dummy function
end

%Grab file identifier
fileID = fopen(filename, 'r');
assert(fileID ~= -1, ['Unable to open the file ''%s'' for reading. ', ...
    'Make sure the file name and path are correct.'] , filename);

logfcn(sprintf('Beginning file read of file ''%s'' ...', filename));

%Import all the data as a string
%   - Import literal text (including whitespace)
%   - Remove comments (any line beginning with '$')
rawFileData = textscan(fileID, '%s', ...
    'Delimiter'    , '\n' , ...
    'CommentStyle' , '$'  , ...
    'WhiteSpace'   , '');
rawFileData = rawFileData{1};

%Close the file
fclose(fileID);

%TODO - Check if all data has less than 80 characters

end