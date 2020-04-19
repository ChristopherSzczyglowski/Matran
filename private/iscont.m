function tf = iscont(str)
%iscont Checks if the character array 'str' denotes a
%continuation entry.
%
% Syntax:
%	- Brief explanation of the syntax...
%
% Detailed Description:
%	- A continuation entry is denoted by the charcter '*' or '+' in the
%     first 8 characters of 'str' or if str is an array of blanks.
%
% See also: 
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 19-Apr-2020 16:17:17
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 19-Apr-2020 16:17:17
%	- Initial function:
%
% <end_of_pre_formatted_H1>

tf = true;

n    = min(numel(str), 8);
str_ = str(1 : n);

if isempty(str_) 
    return
end
if isequal(str_(1), '*') || contains(str_, '+') || ...
        isequal(str_, blanks(n))
    return
end

tf = false;

end
