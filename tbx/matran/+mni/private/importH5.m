function  [MatranData, FileMeta] = importH5(filename, logfcn, varargin)
%importH5 Imports the Nastran bulk data and results from a HDF5 file and
%returns a heterogenous array of mni.mixin.Collector objects containing the
%data.
%
% Syntax:
%   - Import FE model and results data from MSC.Nastran HDF5 file (default)
%       >> MatranData = importH5(filename);
%     Can also be achieved with...
%       >> MatranData = importH5(filename, 'ImportMode', 'both')
%	- Import a FE model from a MSC.Nastran HDF5 file
%       >> FEModel  = importH5(filename, 'ImportMode', 'input_only')
%   - Import only the results data from a MSC.Nastran HDF5 file
%       >> ResultsSet = importH5(filename, 'ImportMode', 'result_only')
%
% Detailed Description:
%	- Only valid for MSC.Nastran formatted HDF5 files.
%   - The .h5 file is parsed before extracting any data to make sure that
%     the INPUT or RESULT groupsets are available in the file.
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

FileMeta  = [];
FEModel   = [];
ResultSet = [];

bExtractModel   = false;
bExtractResults = false;

if nargin < 2 || isempty(logfcn)
   logfcn = @logger; %default is to print to command window
end

p = inputParser;
addParameter(p, 'ImportMode', 'both', @(x)any(validatestring(x, {'input_only', 'result_only', 'both'})));
parse(p, varargin{:});
[~, ~, ext] = fileparts(filename);
assert(strcmp(ext, '.h5'), '''Filename'' must be the name of a .h5 file');

logfcn(sprintf('Beginning file read of file ''%s'' ...', filename));

%Prep the inputs
if any(strcmp(p.Results.ImportMode, {'both', 'input_only'}))
    bExtractModel = true;
end
if any(strcmp(p.Results.ImportMode, {'both', 'result_only'}))
    bExtractResults = true;    
end
    
if bExtractModel   && checkH5Groups(filename, 'INPUT')  %Import the model
    
    %Set up variables
    FEModel      = mni.bulk.FEModel;
    BulkDataMask = defineBulkMask;
    UnknownBulk  = {};
    
    %Import the data
    MetaGroup = h5info(filename, '/NASTRAN/INPUT');
    [FEModel, skippedCards] = extractData(filename, MetaGroup, FEModel, BulkDataMask, logfcn, UnknownBulk);
    
    %Format the meta data
    FileMeta.SkippedBulk = skippedCards;
    FileMeta.UnknownBulk = strtrim(cellfun(@(x) x(1 : strfind(x, '-') - 1), skippedCards, 'Unif', false));
    
else
    warning(['The h5 file ''%s'' did not contain any input data. ', ...
        'Make sure MDLPARAM HDF5 is set to either 0 or 1 in the ' , ...
        'run file.'], filename);
end
if bExtractResults && checkH5Groups(filename, 'RESULT') %Import the results
     [ResultSet, UnknownResults] = extractH5Results(filename, logfcn);
elseif bExtractResults
    warning(['The h5 file ''%s'' did not contain any results ', ...
        'data. Make sure MDLPARAM HDF5 is set to 0, 1, 2 or 3 ', ...
        'in the run file.'], filename);
end

MatranData = horzcat(FEModel, ResultSet);

end

function tf = checkH5Groups(h5Filename, tok)
%checkH5ForModelBulk Checks that the h5 file contains Nastran input data.

tf = false;

if nargin < 1
    tok = 'INPUT';
end
tok = validatestring(tok, {'INPUT', 'RESULT'});

%Peek inside the h5 file and make sure it has the group 'NASTRAN/INPUTS'
Meta = h5info(h5Filename);
if isempty(Meta.Groups)
    return
end
if ~ismember('/NASTRAN', {Meta.Groups.Name}) 
    return
end
nas_grp = Meta.Groups(ismember({Meta.Groups.Name}, '/NASTRAN'));
if ~ismember(['/NASTRAN/', tok], {nas_grp.Groups.Name})
    return
end
tf = true;

end

function [FEM, UnknownBulk] = extractData(filename, MetaGroup, FEM, BulkDataMask, logfcn, UnknownBulk)
%extractData Extracts the bulk data from the .h5 file and returns a finite
%element model.

allBulkNames = fieldnames(BulkDataMask);

%Keep track of the meta group names
if isempty(MetaGroup.Groups)
    metagroupNames = {};
else
    metagroupNames = {MetaGroup.Groups.Name};
end

%Check if the leaf defines a useable Matran class
leaf = MetaGroup.Name(max(strfind(MetaGroup.Name, '/')) + 1 : end);
cn   = assignCardName(leaf, allBulkNames);

%Check to see if we can extract any data
if isempty(cn) && ~isempty(MetaGroup.Datasets)
    %Look at the Datasets for possible bulk data names
    names = {MetaGroup.Datasets.Name};
    for i = 1 : numel(names) 
        %Get card name & Matran class
        cn = assignCardName(names{i}, allBulkNames);
        [bClass, str] = isMatranClass(cn, BulkDataMask);
        if ~bClass
            logfcn(sprintf('%-10s %-8s (%8s)', 'Skipped', names{i}, blanks(8)));
            UnknownBulk{end + 1} = sprintf( ...
            '%8s - %6s entry/entries', names{i}, 'n/a   ');
            continue
        end
        %Use built-in 'h5read' to extract data
        groupset = strcat([MetaGroup.Name, '/'], names{i});
        [bulkNames, bulkData, nCard] = mni.bulk.BulkData.parseH5Data(filename, groupset);   
        %Tell the user
        logfcn(sprintf('%-10s %-8s (%8i)', 'Extracting', cn, nCard), true);        
        %Initialise the object
        fcn     = str2func(str);
        BulkObj = fcn(cn, nCard);        
        %Assign the card data
        assignH5BulkData(BulkObj, bulkNames, bulkData);        
        %Add object to the model
        addItem(FEM, BulkObj);
    end
else
    [bClass, str] = isMatranClass(cn, BulkDataMask);
    if bClass 
        %Get the remaining data below this group
        h5Struct = readH5intoStruct(filename, MetaGroup);
        logfcn(sprintf('%-10s %-8s (%8s)', 'Extracting',cn, blanks(8)), true); 
        %Build the object
        fcn     = str2func(str);
        BulkObj = fcn(cn);
        %Assign data
        [bulkNames, bulkData] = parseH5DataGroup(BulkObj, h5Struct);
        assignH5BulkData(BulkObj, bulkNames, bulkData);  
        %Add object to the model
        addItem(FEM, BulkObj);           
        %Remove this group from the list so that we don't get duplicates
        metagroupNames(contains(metagroupNames, MetaGroup.Name)) = [];
    else
        logfcn(sprintf('%-10s %-8s (%8s)', 'Skipped', leaf, blanks(8)));
        UnknownBulk{end + 1} = sprintf( ...
            '%8s - %6s entry/entries', leaf, 'n/a   ');
    end
end

%Recurse through groups 
if ~isempty(metagroupNames)
    allMetagroupNames = {MetaGroup.Groups.Name};
    for iG = 1 : numel(metagroupNames)
        idx = ismember(allMetagroupNames, metagroupNames{iG});
        [FEM, UnknownBulk] = extractData(filename, MetaGroup.Groups(idx), FEM, BulkDataMask, logfcn, UnknownBulk);
    end
end

end

function cardName = assignCardName(token, allBulkNames)
%assignCardName Assigns the card name based on the name of the h5 group and
%the available bulk data names.
%
% If the token is an exact match with a bulk data name then this is the
% card name. If there is only a partial match then 'regexp' is used to find
% the string which has the most matching characters with one of the bulk
% data names.

cardName = '';

if ~any(strcmp(allBulkNames, token))
    
    %Search for partial matches
    idx = cellfun(@(x) contains(token, x), allBulkNames);
    partialMatch  = allBulkNames(idx);
    if isempty(partialMatch)
        return
    end
    nPartialMatch = numel(partialMatch);
    startInd = zeros(1, nPartialMatch);
    endInd   = zeros(1, nPartialMatch);
    for ii = 1 : nPartialMatch
        [startInd(ii), endInd(ii)] = regexp(token, partialMatch{ii});
    end
    
    %Select the token which has the most matching elements
    [~, matchIndex] = max(endInd);
    cardName = partialMatch{matchIndex};
    
else
    
    cardName = token;
    
end

end

function h5Struct = readH5intoStruct(filename, MetaGroup)

%If MetaGroup.DataSet is populated then extract data
if ~isempty(MetaGroup.Datasets)
    names = {MetaGroup.Datasets.Name};
    for i = 1 : numel(names)
        %Formulate 'groupset'
        groupset = strcat([MetaGroup.Name, '/'], names{i});
        %Use built-in 'h5read' to extract data
        h5Data          = h5read(filename, groupset);        
        h5Struct.(names{i}) = h5Data;
    end
end

%If MetaGroup.Groups is populated then ...
%... recursively loop through groups and find Datasets
if ~isempty(MetaGroup.Groups)
    gNames = formatGroupName({MetaGroup.Groups.Name});
    for iG = 1 : numel(MetaGroup.Groups)
        h5Struct.(gNames{iG}) = readH5intoStruct(filename, MetaGroup.Groups(iG));
    end
end

    function groupName = formatGroupName(groupString)
        %formatGroupName Grabs the final group name from the group set
        %string.
        
        groupName = cellfun(@(x) x(find(x == '/', 1, 'last') + 1 : end), ...
            groupString, 'Unif', false);
        
    end

end