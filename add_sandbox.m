%add_sandbox Sets up the development environment for the Matran sandbox.
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
% Revision: 2.0 02-May-2020 12:36:00
%   - Changed to script and updated package folders to add to path.
% 
%
% <end_of_pre_formatted_H1>

%Where are we?
loc = mfilename('fullpath');
sandbox_loc = fileparts(loc);

%Add the development tools
addpath(fullfile(sandbox_loc, 'dev_tools'));
addpath(fullfile(sandbox_loc, 'unit_testing'));

%Add the Matran code
addpath(fullfile(sandbox_loc, 'tbx', 'matran'));