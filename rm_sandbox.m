%rm_snadbox Tears down the development environment for the Matran sandbox.
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 04-Jul-2020 06:49:59
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 04-Jul-2020 06:49:59
%	- Initial function:
%
% <end_of_pre_formatted_H1>

%Where are we?
loc = mfilename('fullpath');
sandbox_loc = fileparts(loc);

%Development tools
rmpath(fullfile(sandbox_loc, 'dev_tools'));
rmpath(fullfile(sandbox_loc, 'unit_testing'));

%Matran code
rmpath(fullfile(sandbox_loc, 'tbx', 'matran'));