function [bClass, className] = isMatranClass(cardName, BulkDataMask)
%isMatranClass Checks whether the bulk data name 'cardName' matches a
%Matran bulk data class and returns a scalar logical and the name of the
%matching class if a match is found.
%
% Syntax:
%   - Check for a known class name
%       >> [bClass, className] = isMatranClass('mni.Beam')
%           true, 'mni.Beam'
%   - Check using the name of a bulk data type
%       >> [bClass, className] = isMatranClass('CBAR')
%           true, 'mni.Beam'
%
% Detailed Description:
%	- Checks for an exact match with exist(cardName, 'class')
%   - If the card name is not a classname then the BulkDataMask iss earched
%     for a match.
%
% See also: defineBulkMask
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 29-Apr-2020 10:15:46
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 29-Apr-2020 10:15:46
%	- Initial function:
%
% <end_of_pre_formatted_H1>

bClass    = false;
className = cardName;
if isempty(cardName)
    return
end
if nargin < 2
    BulkDataMask = defineBulkMask;
end

prj = 'mni.bulk'; % project folder

%Initialise the card
class_str = lower(cardName);
class_str(1) = upper(class_str(1));
className = [prj, '.', class_str];

%Check it exists, if not, check the mask for a synonym class.
if exist(className, 'class') == 8
    bClass = true;
elseif isfield(BulkDataMask, cardName)
    className = BulkDataMask.(cardName);
    bClass = true;
else
    className = '';
end

end
