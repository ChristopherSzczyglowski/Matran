function setupMatran
%setupMatran Adds the parent folder to the path so that the Matran packages
%can be run without installing Matran as a package.
%
% Syntax:
%	- Add the parent folder to the path:
%       >> setupMatran
%
% Detailed Description:
%	- Detailed explanation of the function and how it works...
%
% See also: addpath
%
% References:
%	[1].
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 08-Mar-2020 16:04:00
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 08-Mar-2020 16:04:00
%	- Initial function:
%
% <end_of_pre_formatted_H1>

%Where are we?
loc = mfilename('fullpath');

%Matran folder is two levels aboove
matran_loc = fileparts(fileparts(loc));

%Add to the path but not all subfolders
addpath(matran_loc);

end
