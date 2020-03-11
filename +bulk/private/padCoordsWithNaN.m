function x = padCoordsWithNaN(x)
%%padCoordsWithNaN Accepts a matrix of [2, N] sets of coordinates which
%represent the coordinate of a series of lines from end-A to end-B and
%returns a single vector with all of the coordinates padded by NaN terms.
%
% Detailed Description:
%	- This function enables the plotting of line objects to be vectorised.
%
% See also:
%
%
% Author    : Christopher Szczyglowski Email     :
% chris.szczyglowski@gmail.com Timestamp : 08-Mar-2020 22:49:00
%
% Copyright (c) 2020 Christopher Szczyglowski All Rights Reserved
%
%
% Revision: 1.0 08-Mar-2020 22:49:00
%	- Initial function:
%
% <end_of_pre_formatted_H1>

%Convert to cell so we retain the pairs of coordinates in the
%correct order
x  = num2cell(x, 1);

%Preallocate
x_ = cell(1, 2 * numel(x));

%Assign the data and NaN terms
x_(1 : 2 : end - 1) = x;
x_(2 : 2 : end)     = {nan};

%Return a column vector
x = vertcat(x_{:});

end
