function  [FEModel, FileMeta] = importH5(h5Filename)
%importH5 Imports the Nastran bulk data from a HDF5 file and returns a 
%'bulk.FEModel' object containing the data.
%
% Syntax:
%	- Import a model from a MSC.Nastran HDF5 file (.h5)
%       >> h5Filename = 'myImportFile.h5'
%       >> FEModel = importH5(h5Filename)
%
% Detailed Description:
%	- Only valid for MSC.Nastran formatted HDF5 files.
%
% See also: 
%
% References:
%	[1]. MSC.Nastran Reference Manual - "The Nastran HDF5 Result Database
%   (NH5RDB)"
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 28-Apr-2020 13:15:58
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 28-Apr-2020 13:15:59
%	- Initial function:
%
% <end_of_pre_formatted_H1>

FEModel  = [];
FileMeta = []; %TODO - Change this to record any unrecognised bulk data
logfcn   = @logger;

%Prompt user if no file is provided
if nargin == 0
    [h5Filename, filepath] = uigetfile({'*.h5', 'HDF5 file'}, 'Select a file') ;
    if isnumeric(h5Filename) && isnumeric(filepath)
        return
    else
        h5Filename = fullfile(filepath, h5Filename);
    end
end

%Validate
assert(exist(h5Filename, 'file') == 2, ['File ''%s'' does not exist. Check ', ...
    'the filename and try again.'], h5Filename);
[~, ~, ext] = fileparts(h5Filename);
assert(strcmp(ext, '.h5'), '''Filename'' must be the name of a .h5 file');
assert(checkH5ForModelBulk(h5Filename), sprintf(['The h5 file ''%s'' did ', ...
    'not contain any input data. Make sure MDLPARAM HDF5 is set to '      , ...
    'either 0 or 1 in the run file.'], h5Filename));

FEModel      = bulk.FEModel;
BulkDataMask = defineBulkMask;

%Traverse the hierachy
MetaGroup = h5info(h5Filename);     
FEModel   = extractData(h5Filename, MetaGroup, FEModel, BulkDataMask, logfcn);

%Build connections
makeIndices(FEModel);

%Print a summary of all the data contained in the file and any
%embedded files
summary = summarise(FEModel);
logfcn(sprintf('Extraction summary :\n'));
logfcn(sprintf(['The following cards have been extracted ', ...
    'successfully from the file ''%s'':\n\t%-s\n'], ...
    h5Filename, sprintf('%s\n\t', summary{:})));
% if isempty(skippedCards)
%     logfcn('All bulk data entries were successfully extracted!');
% else
%     logfcn(sprintf(['The following cards have not been extracted ', ...
%         'from the file ''%s'':\n\n\t%-s\n'], h5Filename, ...
%         sprintf('%s\n\t', skippedCards{:})));
% end

end

function tf = checkH5ForModelBulk(h5Filename)
%checkH5ForModelBulk Checks that the h5 file contains Nastran input data.

tf = false;

%Peek inside the h5 file and make sure it has the group 'NASTRAN/INPUTS'
Meta = h5info(h5Filename);
if isempty(Meta.Groups)
    return
end
if ~ismember('/NASTRAN', {Meta.Groups.Name}) 
    return
end
nas_grp = Meta.Groups(ismember({Meta.Groups.Name}, '/NASTRAN'));
if ~ismember('/NASTRAN/INPUT', {nas_grp.Groups.Name})
    return
end
tf = true;

end

function FEM = extractData(filename, MetaGroup, FEM, BulkDataMask, logfcn)
%findDataSet Extracts all the data from the .h5 file 'filename' into a
%Matlab structure which preserves the .h5 data hierachy.
%
% Assumptions:
%   - Assume that a structure with a non-empty 'Datasets' field is a root
%     structure. The structure above this one is the parent containing the
%     group name.

%project folder
prj = 'bulk';

%If MetaGroup.DataSet is populated then extract data
if ~isempty(MetaGroup.Datasets)
    names = {MetaGroup.Datasets.Name};
    names = names(isfield(BulkDataMask, names));
    %Loop through any bulk data sets that are part of the mask
    for i = 1 : numel(names)
        
        cn = names{i};
        
        %Initialise the card
        str = [prj, '.', cn];
        
        %Check it exists, if not, check the mask for a synonym class.
        if exist(str, 'class') ~= 8
            bClass = false;
            if isfield(BulkDataMask, cn)
                str = BulkDataMask.(cn);
                bClass = true;
            end
        end        
        if ~bClass
            continue
        end
        
        %Use built-in 'h5read' to extract data
        groupset   = strcat([MetaGroup.Name, '/'], names{i});        
        BulkStruct = h5read(filename, groupset);          
        bulkNames  = fieldnames(BulkStruct)';
        bulkData   = struct2cell(BulkStruct)'; %MUST BE A ROW VECTOR TO USE 'set(obj, ...)'
        
        %Strip DOMAIN_ID (if present)
        idx = ismember(bulkNames, 'DOMAIN_ID');
        bulkNames(idx) = [];
        bulkData(idx)  = [];        
        
        %Convert char data to cell-str
        idxChar = cellfun(@ischar, bulkData);        
        bulkData(idxChar) = cellfun(@(x) cellstr(x'), bulkData(idxChar), 'Unif', false);                  
        
        %Determine number of cards
        n = cellfun(@length, bulkData(not(cellfun(@ischar, bulkData))));
        if any(diff(n) == 0)
            nCard = mode(n);
        else
            nCard = n(1); 
        end
        
        %Transpose data where nRows == nCard   
        idxMismatch = (cellfun(@(x) size(x, 1), bulkData) == nCard);
        bulkData(idxMismatch)  = cellfun(@transpose, bulkData(idxMismatch), 'Unif', false);
         
        %Tell the user
        logfcn(sprintf('%-10s %-8s (%8i)', 'Extracting', ...
            cn, nCard), true);
        
        %Initialise the object
        fcn     = str2func(str);
        BulkObj = fcn(cn, nCard);
        
        %Assign the card data
        assignH5BulkData(BulkObj, bulkNames, bulkData);
        
        %Add object to the model
        addBulk(FEM, BulkObj);
        
    end
end

%Recurse through groups 
if ~isempty(MetaGroup.Groups) 
    for iG = 1 : numel(MetaGroup.Groups)
        FEM = extractData(filename, MetaGroup.Groups(iG), FEM, BulkDataMask, logfcn);
    end
end

end
