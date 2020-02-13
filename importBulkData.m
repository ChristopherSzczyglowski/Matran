function FEModel = importBulkData(bulkFilename)
%importBulkData Imports the Nastran bulk data from a ASCII text file and
%returns a 'bulk.FEModel' object containing the data.
%
% Syntax:
%	- Brief explanation of the syntax...
%
% Detailed Description:
%	- Detailed explanation of the function and how it works...
%
% References:
%	[1]. "Can quantum-mechanical description of physical reality be
%         considered complete?", A Einstein, Physical Review 47(10):777,
%         American Physical Society 1935, 0031-899X
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 13-Feb-2020 16:32:33
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 13-Feb-2020 16:32:33
%	- Initial function:
%
% <end_of_pre_formatted_H1>

FEModel = [];
logfcn  = @(s) fprintf('%s\n', s);

validExt = {'.dat', '.bdf'};

%Prompt user if no file is provided
if nargin == 0
    exts   = strjoin(strcat('*', validExt), ';');
    str    = sprintf('Nastran bulk data files (%s)', strjoin(strcat('*', validExt), ','));
    prompt = 'Select a Nastran bulk data file';
    [bulkFilename, filepath] = uigetfile({exts, str}, prompt);
    if isnumeric(bulkFilename) && isnumeric(filepath)
        return
    else
        bulkFilename = fullfile(filepath, bulkFilename);
    end
end

%Validate
assert(exist(bulkFilename, 'file') == 2, ['File ''%s'' does not exist. Check ', ...
    'the filename and try again.'], bulkFilename);
[~, ~, ext] = fileparts(bulkFilename);
assert(any(strcmp(ext, validExt)), ['Expected the file extension to be ', ...
    'one of the following:\n\n\t%s'], strjoin(validExt, '\n\t'));
filepath = fileparts(bulkFilename);

%Get raw text from the file
rawFileData = readCharDataFromFile(bulkFilename, logfcn);

%Split into Executive Control, Case Control and Bulk Data
[EC, CC, BD] = splitInputFile(rawFileData, logfcn);

%Extract "NASTRAN SYSTEM" commands from Executive Control

%Extract Case Control data

%Extract "PARAM" from Bulk Data
[Parameters, BD] = extractParameters(BD, logfcn);

%Extract "INCLUDE" statements and corresponding file names
[IncludeFiles, BD] = extractIncludeFiles(BD, logfcn, filepath);

%Extract bulk data
[FEM, UnknownBulk] = extractBulkData(BD, logfcn);

%Loop through INCLUDE files (recursively)
[data, aerodata, leftover] = cellfun(@(x) i_import_msc_txt(obj, x, logfcn), ...
    IncludeFiles, 'Unif', false);

if ~isempty(data) || ~isempty(aerodata)
    logfcn(sprintf('Combining bulk data in file ''%s''.', filename));
end

%Combine data & diagnostics from INCLUDE data
cellfun(@(x) addBulk(FEM , x), data    , 'Unif', false);
cellfun(@(x) addBulk(AFEM, x), aerodata, 'Unif', false);
UnknownBulk = [UnknownBulk, cat(2, leftover{:})];

end

function rawFileData = readCharDataFromFile(filename, logfcn)
%readCharDataFromFile Reads the data from the file as literal text.

%Grab file identifier
fileID = fopen(filename, 'r');
assert(fileID ~= -1, ['Unable to open the file ''%s'' for reading. ', ...
    'Make sure the file name and path are correct.'] , filename);

logfcn(sprintf('Beginning file read of file ''%s'' ...', filename));

%Import all the data as a string
%   - Import literal text (including whitespace)
%   - Remove comments (any line beginning with '$')
%   - TODO : Need to be able to parse lines that have comments part way
rawFileData = textscan(fileID, '%s', ...
    'Delimiter'    , '\n' , ...
    'CommentStyle' , '$'  , ...
    'WhiteSpace'   , '');
rawFileData = rawFileData{1};

%Close the file
fclose(fileID);

%TODO - Check if all data has less than 80 characters

end

function [execControl, caseControl, bulkData] = splitInputFile(data, logfcn)
%splitInputFile Splits the cell-string data in 'data' into
%three segments: 'Executive Control', 'Case Control' & 'Bulk
%Data'.
%
% The 'Executive Control' and 'Case Control' are split by the
% keyword "CEND"
%
% The 'Case Control' and 'Bulk Data' are split by the keyword
% "BEGIN BULK"

%Remove empty lines
data = data(~cellfun(@(x) isempty(x), data));

%Logical indexing
idx_EC = contains(data, 'CEND');
idx_BD = contains(data, 'BEGIN BULK');

%Linear indexing
indEC = find(idx_EC == true);
indBD = find(idx_BD == true);

%Check for occurence of 'BEGIN BULK'
if ~any(idx_BD) %If not found, assume all is bulk
    execControl = {};
    caseControl = {};
    bulkData    = data;
    logfcn(['Did not find tokens ''CEND'' or ''BEGIN BULK''. ', ...
        'Assuming all file contents are bulk data.']);
    return
end

%Grab the data
execControl = data(1 : indEC - 1);
caseControl = data(indEC + 1 : indBD - 1);
bulkData    = data(indBD + 1 : end);

%Remove "ENDDATA" from the BulkData cell array
bulkData(contains(bulkData, 'ENDDATA')) = [];

logfcn(['Input data split into ''Executive Control'', ', ...
    '''Case Control'' and ''Bulk Data'' sections.']);

end

function [Parameters, BulkData] = extractParameters(BulkData, logfcn)
%extractParameters Extracts the parameters from the bulk data
%and returns the cell array 'BD' with all parameter lines
%removed.

%Find "PARAM" & "MDLPRM" in the input file
idx_PARAM  = contains(BulkData, 'PARAM');
idx_MDLPRM = contains(BulkData, 'MDLPRM');

%Extract the name-value data for each parameter
Parameters.PARAM  = i_extractParamValue(BulkData(idx_PARAM) , logfcn);
Parameters.MDLPRM = i_extractParamValue(BulkData(idx_MDLPRM), logfcn);

%Remove all parameters from 'BulkData'
BulkData = BulkData(~or(idx_PARAM, idx_MDLPRM));

    function paramOut = i_extractParamValue(paramData, logfcn)
        %extractParamValue Extracts the parameter name and value
        %from each line in 'paramData'.
        
        if isempty(paramData) %Escape route
            paramOut = [];
            return
        end
        
        %Preallocate
        name  = cell(size(paramData));
        value = cell(size(paramData));
        
        for i = 1 : numel(paramData)
            if contains(paramData{i}, ',') %Define delimiter
                delim = ',';
            else
                delim = ' ';
            end
            %Split the string
            temp = strsplit(paramData{i}, delim);
            %Assign to name/value
            name{i}  = temp{2};
            value{i} = temp{3};
        end
        %Convert to structure
        paramOut = cell2struct(value, name);
        
        %Inform progress
        logfcn(sprintf('Extracted the following parameters:'));
        logfcn(sprintf('\t- %s\n', name{:}));
        
    end

end

function [IncludeFiles, BulkData] = extractIncludeFiles(BulkData, logfcn, parentPath)
%extractIncludeFiles Extracts the path to any files containing
%data that is included in the bulk data.

%Find all lines containing "INCLUDE"
idx = contains(BulkData, 'INCLUDE');
ind = find(idx == true);

%Preallocate
IncludeIndex = cell(size(ind));
IncludeFiles = cell(size(ind));

if isempty(ind) %Escape route
    return
end

for iFile = 1 : numel(ind) %Extract path to the included file
    
    error('Check code still runs correctly');
    
    %Extract all data related to the "INCLUDE" card
    [cardData, IncludeIndex{iFile}] = mni.Entity.getCardData(BulkData, ind(iFile));
    
    %Remove blanks and combine into one string
    filename = strtrim(cardData);
    filename = cat(2, filename{:});
    
    %Remove speech marks (if present)
    filename(strfind(filename, '"'))  = '';
    filename(strfind(filename, '''')) = '';
    
    %Remove "INCLUDE" keyword
    filename = filename(9 : end);
    
    %Check if absolute or relative path
    [path, ~, ~] = fileparts(filename);
    
    %Relative path will have an empty 'path' variable
    %   -> append with the current directory
    if isempty(path)
        filename = fullfile(parentPath, filename);
    end
    
    %Assign to cell array
    IncludeFiles{iFile} = filename;
    
end

%Remove all lines from 'BulkData' relating to INCLUDE
BulkData(cat(2, IncludeIndex{:})) = [];

%Inform progress
logfcn(sprintf('Found the following included files:'));
logfcn(sprintf('\t- %s\n', IncludeFiles{:}));

end

function [FEM, UnknownBulk] = extractBulkData(BulkData, logfcn)
%extractBulk Extracts the bulk data from the cell array
%'BulkData' and returns a collection of bulk data and
%aerodynamic bulk data as well as a cell array summarising the
%bulk data that has been skipped.

%Inform the user
logfcn('Extracting bulk data...');

%Preallocate
FEM = bulk.FEModel(); 
UnknownBulk = {};

%project folder
prj = 'bulk';

%Extract all card names and continuation entries (for indexing)
col1 = cellfun(@(x) x(1 : 8), BulkData, 'Unif', false);

%Find all unique names in the collection
%   - N.B. Uniqueness not guaranteed because of potential for
%          free-field bulk data cards.
idxCont   = cellfun(@(x) iscont(x), col1);
col1      = strtrim(col1);
idx       = or(idxCont, contains(col1, '*')); %Got to account for card names with large-field format
%             cardNames = unique(strtrim(col1(~idx)), 'stable'); %TODO - Is this quicker without 'stable'?
cardNames = unique(col1(~idx), 'stable');

%BUT, if the file has been written in free-field
%(comma-seperated) format the 'cardNames' may not be valid so
%we need to trim all text after (and including) the comma.
idx = contains(cardNames, ',');
ind = strfind(cardNames , ','); %TODO : Investigate what is quicker. Could do cellfun(@isemtpy, ind) to get logical index 'idx'
cardNames(idx) = arrayfun(@(i) cardNames{i}(1 : ind{i} - 1), find(idx), 'Unif', false);

%Now get the actual unique names
cardNames = unique(cardNames, 'stable'); %TODO - Is this quicker without 'stable'?

%Loop through cards - create objects & populate properties
for iCard = 1 : numel(cardNames)
    
    cn = cardNames{iCard};
    
    %Find all cards of this type in the collection BUT do not
    %include continuation lines. We are searching for the first
    %line of the card.
    idx = and(contains(col1, cn), ~idxCont);
    %                 idx   = and(or(strcmp(col1, cn), strcmp(col1, [cn, '*'])), ~idxCont);
    %                 idx   = and(contains(col1, cn), ~idxCont);
    ind   = find(idx == true);
    nCard = nnz(idx);
    
    if nCard == 0 %Catch
        continue
    end
    
    %Initialise the card
    str = [prj, '.', cn];
    if exist(str, 'class')
        
        %Tell the user
        logfcn(sprintf('%-10s %-8s (%8i)', 'Extracting', ...
            cn, nCard));
        
        %Initialise the object
        fcn = str2func(str);
        card = arrayfun(@(i) fcn(), 1 : nCard, 'Unif', false);
        card = horzcat(card{:});
        %card(nCard) = fcn();
        
        %Check that the card is a valid bulk data object
        validateBulk(card);
        
        %Which cards are wide-field format?
        isWF  = contains(col1(idx), '*');
        set(card(isWF) , 'ColWidth', 16);
        set(card(~isWF), 'ColWidth', 8);
        
        %Loop through each instance of 'card' in 'BulkData'
        for iObj = 1 : nCard %extract properties
            %TODO - Update 'getCardData' so that it just
            %returns the cell array of data and doesn't set the
            %data. Do the setting outside the loop.
            %Extract raw text data for this card
            [cardData, ~] = mni.Entity.getCardData(BulkData, ind(iObj));
            %Extract values from raw text data and assign to
            %the object
            extractCardData(card(iObj), cardData);
        end
        
        %Add object to the model
        if isa(card, 'mni.bulk.AeroBulkData')
            addBulk(AFEM, card);
        else
            addBulk(FEM, card);
        end
        
        clear card
        
    else
        
        %Tell the user - TODO : Decide whether we need to tell
        %the user about the number of cards that are skipped...
        logfcn(sprintf('%-10s %-8s (%8i)', 'Skipped', ...
            cn, nCard));
        
        %Make a note of it
        UnknownBulk{end + 1} = sprintf( ...
            '%8s - %6i entry/entries', cn, nCard); %#ok<AGROW>
        
    end
end
end

function tf = iscont(str)
%iscont Checks if the character array 'str' denotes a
%continuation entry.
%
% A continuation entry is denoted by the charcter '*' or '+' in
% the first 8 characters of 'str' or if str is an array of
% blanks.

if isequal(str(1), '*') || contains(str(1:8), '+') || ...
        isequal(str(1:8), blanks(8))
    tf = true;
else
    tf = false;
end

end

