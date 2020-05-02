function runNastran(datfile, varargin)
%runNastran Runs the MSC.Nastran executable with the filename
%specified by 'datfile'.
%
% Syntax:
%	- Run the Nastran analysis specified by the run file 'datfile'.
%       >> datFile = 'mySampleDatFile.dat'
%       >> runNastran(datFile)
%
% Detailed Description:
%   - The 'system' command is used to run Nastran.
%   - Must change the current directory to the local directory
%     of the .dat file otherwise the output files will be sent
%     to the current working directory.
%   - The 'system' command does not wait for the program to
%     finish. Instead, we pause Matlab and wait for the
%     analysis to end.
%   - Whilst the .f06 is being checked for the end statement,
%     it is also parsed for FATAL errors.
%
% See also:
%
% References:
%	[1]. MSC.Nastran Quick Reference Guide
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 19-Apr-2020 14:21:32
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 19-Apr-2020 14:21:32
%	- Initial function:
%
% <end_of_pre_formatted_H1>

p = inputParser;
addParameter(p, 'F06MaxWait', 10, @(x)validateattributes(x, {'numeric'}, {'scalar', 'positive', 'finite', 'real', 'nonnan'}));
parse(p, varargin{:});

f06MaxWait = p.Results.F06MaxWait;

%Remember where the analysis is being invoked from
this_dir = pwd;
bFinish  = false;

%Get the path to the MSC.Nastran executable
nastran_exe = getNastranExe;
if isempty(nastran_exe)
    warning(['Path to Nastran executable was not found. Exiting ', ...
        '''runNastran'' without executing the analysis.'])
    return
end

%Set up file information
[path, nam, ext] = fileparts(datfile);

%Run MSC.Nastran - TODO: Add 'scratch' options as input
cd(path)
cmd = strjoin({nastran_exe, datfile, 'scratch=yes'}, ' ');
system(cmd);

%Define name of .f06 file
f06name = [lower(nam), '.f06'];

%Monitor progress?
% switch p.Results.MonitorProgress
%     case 'Default'
logFcn = @(f06Line, Data) i_checkForFatal(f06Line, Data);
Data = [];
%     case 'Nonlinear'
%         logFcn = @(f06Line, Data) i_displayNonlinearConvergence(f06Line, Data);
%         hF     = figure('Name', 'Nonlinear Solution Sequency Progress');
%         hAx(1) = axes('Parent', hF, 'NextPlot', 'add');
%         Data   = struct( ...
%             'SolutionData'        , struct('NLIter', zeros(21, 1)), ...
%             'GraphicsHandles'     , [hF, hAx], ...
%             'ExtractIterationData', false);
% end


%Check the .f06 for "FATAL ERROR" and "END OF JOB"
while ~bFinish
    %Start a timer
    t0 = tic;
    t  = 0;
    %Pause Matlab until the .f06 is generated
    while isempty(dir(f06name))
        if t > f06MaxWait
            break
        end
        pause(0.01);
        t = toc(t0);
    end
    %Once the .f06 exists open the file and search for keywords
    if isempty(dir(f06name))
        cd(this_dir);
        error(['MSC.Nastran failed to start the analysis.', ...
            '\n\n\t-%-12s: %s\n\t-%-12s: %s\n\n'], 'File', ...
            [name, ext], 'Directory', path);
    else
        fid = fopen(f06name, 'r');
        while feof(fid) ~= 1
            f06Line = fgets(fid);
            [bFinish, bFatal, Data] = logFcn(f06Line, Data);
            if bFatal
                fclose(fid);
                diary off
                error(['* * * FATAL ERROR HAS OCCURED IN ', ...
                    'THE FILE %s * * *'], fullfile(path, f06name));
            end
            if bFinish
                break
            end
        end
        fclose(fid);
    end
end


    function [bFinish, bFatal, Data] = i_checkForFatal(f06Line, Data)
        %i_checkForFatal Checks the f06Line for fatal errors and
        %the end of the analysis.
        
        bFinish = false;
        bFatal  = false;
        
        if f06Line == -1
            return
        end
        
        %Check for fatal error
        if contains(f06Line, 'FATAL MESSAGE')
            %SOL 200 has a specific line that contains a
            %FATAL error. Check this is not that.
            if ~contains(f06Line, 'IF THE FLAG IS FATAL')
                bFatal = true;
            end
        end
        
        %Check for end of .f06 file
        if contains(f06Line, '* * * END OF JOB * * *')
            bFinish = 1;
        end
        
    end

%Return to the invoking directory
cd(this_dir);

end

function val = getNastranExe()
%getNastranExe Returns the path to the Nastran executable. Uses 'getpref'
%if the preference is already set and asks the user to specify the pref if
%it does not exist.

val = [];

%Use 'setpref'/'getpref'
if ispref('matran', 'nastran_exe')
    val = getpref('matran', 'nastran_exe');
    return
end

[name, path] = uigetfile({'*.exe', 'Executable File (*.exe)'}, ...
    ['Select the MSC.Nastran executable file ', ...
    '(e.g. \...\nastranw.exe)']);

if isnumeric(name) || isnumeric(path)
    return
end

%Check the path for spaces - Enclose with ""
folders = strsplit(path, filesep);
idx     = cellfun(@(x) any(strfind(x, ' ')), folders);
folders(idx) = cellfun(@(x) ['"', x, '"'], folders(idx), 'Unif', false);
path    = strjoin(folders, filesep);
val     = fullfile(path, name);

%Update the preferences
setpref('matran', 'nastran_exe', val);

end