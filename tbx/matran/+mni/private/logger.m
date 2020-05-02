function logger(str, bNewLine, bLiteral)
%logger Presents the import display to the user by printing to the command
%window
%
% Syntax:
%	- Print a string to the command window and do not go to a new line:
%       >> logger('Hello World');%
%   - Print a string to the command window and add EOL
%       >> logger('Hello World', true);
%   - Print a string to the command window and allow escape characters
%       >> logger('This is an EOL character: \n', true, false);
%
% Detailed Description:
%	- 
%
% See also: fprintf
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 28-Apr-2020 15:19:15
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 28-Apr-2020 15:19:15
%	- Initial function:
%
% <end_of_pre_formatted_H1>

if nargin < 2
    bNewLine = true;
end
if nargin < 3
    bLiteral = false;
end

%Add an EoL
if bNewLine
    esc = '\n';
else
    esc = '';
end

%Allow escape characters
if bLiteral
    fprintf([str, esc]);
else
    fprintf(['%s', esc], str);
end

end
