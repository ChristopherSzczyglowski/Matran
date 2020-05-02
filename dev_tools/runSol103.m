function runSol103(bulkDataFiles)
%runSol103 Executes a Solution 103 (Normal Modes) analysis in MSC.Nastran
%for the models contained in 'runFiles' and requests the HDF5 output.
%
% Syntax:
%	- Run the default models in the 'TestMatran' class.
%       >> runSol103
%   - Run a specified set of models
%       >> modelBulk = {'myModelBulk.bdf', 'myOtherModelBulk.bdf'}
%       >> runSol103(modelBulk)
%
% Detailed Description:
%	- This function is used to generate HDF5 files for testing the import
%	  process.
%
% See also: 
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 15-Apr-2020 12:17:52
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 15-Apr-2020 12:17:52
%	- Initial function:
%
% <end_of_pre_formatted_H1>

%Parse
if nargin < 1
   TM = TestMatran;
   bulkDataFiles = getAllTextImportFiles(TM);
   clear TM 
end
if ~iscell(bulkDataFiles)
    bulkDataFiles = {bulkDataFiles};
end
idx = cellfun(@(x) exist(x, 'file'), bulkDataFiles) == 2;
assert(all(idx), sprintf(['The following files could not be found:', ...
    '\n\t%s\n\nUnable to run Sol 103 analysis.\n'], strjoin(bulkDataFiles(~idx), '\n')));
clear idx

%Run the analysis for each file in turn
%   - Check each file and make a temp file with only the bulk data in
%   - Write a SOL 103 run file
%   - Run the Nastran analysis
for ii = 1 : numel(bulkDataFiles)
    tempBulk = getNewFilename(bulkDataFiles{ii});    
    %Don't run the analysis if the .f06 already exists
    [path, nam, ~] = fileparts(tempBulk);
    if exist(fullfile(path, [lower(nam), '.f06']), 'file') == 2 %Analysis already run? 
        %TODO - Check for FATAL
        continue
    end
    %Write the temp bulk file
    [tempBulk, Parameters] = makeTempBulkDataFile(bulkDataFiles{ii});
    %Write the SOL 103 run file
    runfile  = writeSol103(tempBulk, Parameters);
    %Execute Nastran analysis and wait for it to return
    runNastran(runfile);
end

end

function runFile = writeSol103(filename, Parameters)
%writeSol103 Writes the SOL 103 run file for the bulk data in 'filename'.

methodID = 123;

loc         = getModelDirectory;
[~, nam, ~] = fileparts(filename);
runFile     = fullfile(loc, [nam, '.dat']);

fid = fopen(runFile, 'w');
assert(fid ~= -1, sprintf('Unable to open file ''%s'' for writing.', nam));
fprintf(fid, 'SOL 103\r\n');
fprintf(fid, 'DISPLACEMENT = ALL\n');
fprintf(fid, 'METHOD = %i\r\n', methodID);
fprintf(fid, 'BEGINBULK\r\n');
%Don't write parameters again if they are already in the temp bulk file
%   - Causes a FATAL error in the .f06
if isfield(Parameters, 'PARAM')
    if ~isfield(Parameters.PARAM, 'BAILOUT')
        fprintf(fid, 'PARAM, BAILOUT, -1\n');
    end
end
if isfield(Parameters, 'MDLPRM')
    if ~isfield(Parameters.MDLPRM, 'HDF5')
        fprintf(fid, 'MDLPRM, HDF5, 1\r\n');
    end
end
fprintf(fid, '%-8s%-8i%-8.1f%-8s%-8i\r\n', 'EIGRL', methodID, 0, blanks(8), 20); %request first 20 modes
writeIncludeStatement(fid, filename);
fprintf(fid, 'ENDDATA');
fclose(fid);

end
function bulkFile = getNewFilename(filename)
%getNewFilename Returns the full-file path to the new run file that will be
%generated in the run-folder which is a subfolder of the 'models'
%directory.
[~, nam, ~] = fileparts(filename);
newloc      = getModelDirectory;
bulkFile    = fullfile(newloc, [nam, '_temp.bdf']);
end
function [bulkFiles, Parameters] = makeTempBulkDataFile(filename)
%makeTempBulkDataFile Extracts the bulk data from the Nastran input file
%'filename' and writes it into a temporary file in the analysis directory.

%Get the full-file path of the new run file
bulkFiles = getNewFilename(filename);

%Stash the folder of the orignal file as we will need it to correctly
%reference any INCLUDE files.
[loc, ~, ~] = fileparts(filename);

%Grab the bulk data, parameters & any include files
[~, ~, bd, ~]      = splitInputFile(filename);
[Parameters, ~]    = extractParameters(bd, []);
[includeFiles, bd] = extractIncludeFiles(bd, [], loc);

%Write the bulk data to a new file
fid = fopen(bulkFiles, 'w');
fprintf(fid, '%s\n', bd{:});
writeIncludeStatement(fid, includeFiles);
fclose(fid);

end
function loc = getModelDirectory
%getModelDirectory Returns the path to the folder where the Nastran run
%file will be written.;
loc = fullfile(fileparts(mfilename('fullpath')), 'models', 'auto_generated_h5_data');
end
