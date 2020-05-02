function varargout = import_matran(filename, varargin)
%import_matran Entry point function for importing data into the Matran
%framework.
%
% Syntax:
%   - Importing Matran data using 'uigetfile' to select file.
%       >> MatranData = import_matran();
%
%   - Importing Matran data using 'uigetfile' and using parameters
%       >> MatranData = import_matran([], 'Param1', val1, ...)
%
%	- Importing a FE model from text file (.bdf, .dat)
%       >> FEM = import_matran('models/uob_harw_R.bdf')
%
%   - Importing a FE model from a MSC.Nastran HDF5 file (.h5)
%       >> FEM = import_matran()
%
%   - Importing data and suppressing output to log
%       >> FEM = import_matran(..., 'Verbose', false);
%
%   - Importing data and providing a custom log function
%       >> fid = fopen('import_diary.txt', 'w');
%       >> log_fcn = @(str, bNewLine, bLiteral) fprintf(fid, '%s', str)
%       >> FEM = import_matran(..., 'LogFcn', log_fcn);
%
% Detailed Description:
%	- The import function is selected based on the extension of the file.
%
% See also: 
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 29-Apr-2020 20:46:17
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 29-Apr-2020 20:46:17
%	- Initial function:
%
% <end_of_pre_formatted_H1>
%
% TODO - Add a 'verbose' argument to allow silent import 

%type, descriptor, extensions, import function
prmpt = 'Select a file to import';
file_map = { ...
    {'Nastran bulk data files', 'Nastran h5 files'}, ...
    {{'.dat', '.bdf'}         , {'.h5'}}           , ...
    {@importBulkData          , @importH5} ; ...
    {''}, {{''}}, {}};

if nargin < 1 || isempty(filename)
   filename = []; 
end
[filename, import_fcn, log_fcn] = parse_inputs(prmpt, file_map, filename, varargin{:});

%Import the data
[MatranData, Meta] = import_fcn(filename, log_fcn);

%Do some additional actions based on the type of imported data
switch class(MatranData)    
    case 'bulk.FEModel'
        %Print summary
        printSummary(MatranData, 'LogFcn', log_fcn, 'RootFile', filename);
        if isempty(Meta.SkippedBulk)
            log_fcn('All bulk data entries were successfully extracted!');
        else
            log_fcn(sprintf(['The following cards have not been extracted ', ...
                'from the file ''%s'':\n\n\t%-s\n'], filename, ...
                sprintf('%s\n\t', Meta.SkippedBulk{:})));
        end
        %Make indices between bulk data objects
        makeIndices(MatranData);  
        %TODO - Construct node coordinates and transformation matrices, etc.
    otherwise
        
end

varargout{1} = MatranData;

end

function [filename, import_fcn, log_fcn] = parse_inputs(prmpt, file_map, filename, varargin)
%parse_inputs Checks the user inputs and returns the file name, import
%function handle and logging function handle.

if isempty(filename) %Ask the user
    exts   = cellfun(@(x) strcat('*', x), file_map{2}, 'Unif', false);
    str    = arrayfun(@(ii) sprintf('%s (%s)', file_map{1}{ii}, strjoin(strcat(exts{ii}, ','))), 1 : numel(file_map{1}), 'Unif', false);
    exts   = cellfun(@(x) strjoin(x, '; '), exts, 'Unif', false);
    [filename, filepath] = uigetfile([exts ; str]', prmpt);
    if isnumeric(filename) && isnumeric(filepath)
        return
    else
        filename = fullfile(filepath, filename);
    end
end

validateattributes(filename, {'char'}, {'row', 'nonempty'}, mfilename, 'filename');

%Check file exists and is of the correct type
listValidExt = horzcat(file_map{:, 2});
allValidExt  = horzcat(listValidExt{:});
assert(exist(filename, 'file') == 2, ['File ''%s'' does not exist. Check ', ...
    'the filename and try again.'], filename);
[~, ~, ext] = fileparts(filename);
assert(any(strcmp(ext, allValidExt)), ['Expected the file to have one ', ...
    'of the following extensions:\n\n\t%s'], strjoin(allValidExt, '\n\t'));

%Associate extension with a particular row in the map
nType    = size(file_map, 1);
idx_type = false(nType, 1);
for ii = 1 : nType
    temp = file_map{ii, 2};
    idx_type(ii) = any(contains(horzcat(temp{:}), ext));
end

%Find the import function that corresponds to this extension
idx_fcn = cellfun(@(ext_list) any(contains(ext_list, ext)), listValidExt);
import_fcn = file_map{idx_type, 3}{idx_fcn};

%Parse parameters
p = inputParser;
addParameter(p, 'LogFcn' , @logger, @(x)isa(x, 'function_handle'));
addParameter(p, 'Verbose', true   , @(x)validateattributes(x, {'logical'}, {'scalar'})); 
parse(p, varargin{:});

if p.Results.Verbose
    log_fcn = p.Results.LogFcn;
else
    log_fcn = @(s, a, b) fprintf(''); %dummy function 
end

end

