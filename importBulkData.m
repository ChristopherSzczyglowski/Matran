function FEModel = importBulkData(bulkFilename)
%importBulkData Imports the Nastran bulk data from a ASCII text file and
%returns a 'bulk.FEModel' object containing the data.
%
% Syntax:
%	- Import a model from a text file (.bdf, .dat)
%       >> bulkFilename = 'myImportFile.bdf';
%       >> FEModel = importBulkData(bulkFilename);
%
% Detailed Description:
%	- Supports INCLUDE statements (in the entry point file and any nested
%	  INCLUDE files).
%
% References:
%	[1]. Nastran Getting Started Guide.
%   [2]. Nastran Quick Reference Guide.
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

FEModel  = [];
logfcn   = @logger;
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

%Import the data and return the 'bulk.FEModel' object
[FEModel, skippedCards] = importBulkDataFromFile(bulkFilename, logfcn);

%Build connections
makeIndices(FEModel);

%Print a summary of all the data contained in the file and any
%embedded files
summary = summarise(FEModel);
logfcn(sprintf('Extraction summary :\n'));
logfcn(sprintf(['The following cards have been extracted ', ...
    'successfully from the file ''%s'':\n\t%-s\n'], ...
    bulkFilename, sprintf('%s\n\t', summary{:})));
logfcn(sprintf(['The following cards have not been extracted ', ...
    'from the file ''%s'':\n\n\t%-s\n'], bulkFilename, ...
    sprintf('%s\n\t', skippedCards{:})));

end

%Master function (recursive)

function [FEM, unknownBulk] = importBulkDataFromFile(bulkFilename, logfcn)
%importBulkDataFromFile Imports the bulk data from the file and returns an
%instance of the 'bulk.FEModel' class.

filepath = fileparts(bulkFilename);
if isempty(filepath)
    filepath = pwd;
end

%Get raw text from the file
rawFileData = readCharDataFromFile(bulkFilename, logfcn);

%Split into Executive Control, Case Control and Bulk Data
[~, CC, BD, unresolvedBulk] = splitInputFile(rawFileData, logfcn);

%Extract "NASTRAN SYSTEM" commands from Executive Control

%Extract Case Control data

%Extract "PARAM" from Bulk Data
[Parameters, BD] = extractParameters(BD, logfcn);

%Extract "INCLUDE" statements and corresponding file names
[IncludeFiles, BD] = extractIncludeFiles(BD, logfcn, filepath);

%Extract bulk data
[FEM, unknownBulk] = extractBulkData(BD, logfcn);

%Loop through INCLUDE files (recursively)
[data, leftover] = cellfun(@(x) importBulkDataFromFile(x, logfcn), ...
    IncludeFiles, 'Unif', false);

if ~isempty(data)
    logfcn(sprintf('Combining bulk data in file ''%s''.', filename));
    error('Update code to handle case with INCLUDE files.');
end

%Combine data & diagnostics from INCLUDE data
% cellfun(@(x) addBulk(FEM , x), data    , 'Unif', false);
unknownBulk = [unknownBulk, cat(2, leftover{:})];

end

%Reading raw text from file

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

%Partitioning the Nastran input file

function [execControl, caseControl, bulkData, unresolvedBulk] = splitInputFile(data, logfcn)
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
    [bulkData, unresolvedBulk] = i_parseBulkData(data);
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

[bulkData, unresolvedBulk] = i_parseBulkData(bulkData);

logfcn(['Input data split into ''Executive Control'', ', ...
    '''Case Control'' and ''Bulk Data'' sections.']);

    function [bulkData, unresolvedBulk] = i_parseBulkData(bulkData)
        %i_parseBulkData Stashes any line that have less than 8 characters
        %in the variable 'unresolvedBulk' and retains only the lines that
        %have 8 characters or more.
        %
        %
        % N.B. Any line that has less than 8 characters is ikely to be a
        % system command.
        idx = (cellfun(@numel, bulkData) < 8);
        unresolvedBulk = bulkData(idx);
        bulkData       = bulkData(~idx);
        
    end

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

BulkDataMask = defineBulkMask();

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
    
    %Check it exists, if not, check the mask for a synonym class.
    if exist(str, 'class') ~= 8
        bClass = false;
        if isfield(BulkDataMask, cn)
            str = BulkDataMask.(cn);
            bClass = true;
        end
    end
    
    %If the class exists then we can import the data, if not, skip it
    if bClass
        
        %Tell the user
        logfcn(sprintf('%-10s %-8s (%8i)', 'Extracting', ...
            cn, nCard), 0);
        
        %Initialise the object
        fcn     = str2func(str);
        BulkObj = fcn(cn, nCard);
        
        %Which cards are wide-field format?
%         isWF  = contains(col1(idx), '*');
%         set(card(isWF) , 'ColWidth', 16);
%         set(card(~isWF), 'ColWidth', 8);
        
        %Set up character tokens for denoting progress
        nChar    = 50;  %total number of characters to denote 100%
        progChar = repmat({''}, [1, nCard]);
        incr     = ceil(nCard / nChar);
        if incr ~= 1
            index           = 1 : incr : nCard;
            progChar(index) = {'#'};          
        end
        
        logfcn('       ', 0);
        %Extract raw text data for this card and assign to the object
        for iCard = 1 : nCard %#ok<FXSET> %extract properties
            [cardData, ~] = getCardData(BulkData, ind(iCard));
            extractCardData(BulkObj, cardData, iCard);
            logfcn(progChar{iCard}, 0);
        end
        logfcn('');

        %Add object to the model        
        addBulk(FEM, BulkObj);
        
        clear card
        
    else
        
        %Tell the user - TODO : Decide whether we need to tell
        %the user about the number of cards that are skipped...
        logfcn(sprintf('%-10s %-8s (%8i)', 'Skipped', ...
            cn, nCard));
        
        %Make a note of it
        UnknownBulk{end + 1} = sprintf( ...
            '%8s - %6i entry/entries', cn, nCard); 
        
    end
    
end

end

%Reading text data as bulk data

function [cardData, cardIndex] = getCardData(data, startIndex)
%getCardData Extracts the MSC.Nastran bulk data for a given card from the
%cell array 'data'. The card begins at 'startIndex' and the card data is
%extracted by searching 'data' for the continuation entries relating to
%this card.
%
% Inputs
%   - 'data'       : Cell array of character arrays containing the raw text
%                    output from the text file that is being read.
%   - 'startIndex' : Index number relating to cell entry in 'data' that
%                    contains the first line of the bulk data card. This is
%                    the line where the function will begin extracting
%                    data.
% Outputs
%   - 'cardData'  : Cell array containing the entries from 'data' that
%                   relate to the card described on data(startIndex).
%   - 'cardIndex' : Index number of all the entries extracted from 'data'.
%
% TODO : Add in check for a continuation entry in column 10. This will be
%        specific key that must be searched for in column 1 of the file.

%How many lines in the data set?
nLines = numel(data);

%Check for rubbish input
if startIndex > nLines
    cardData = {};
    return
end

%Grab card data
lineData  = data{startIndex};
cardIndex = startIndex;

%Check for data in column 10
[cardData{1}, endCol] = i_removeEndColumn(lineData);

%If 'endCol' is empty then the card is not using continuation
%entries in column 10 to identify the data.
%   -> Read next line until we find new data
if isempty(endCol)
    
    %Define next index number
    nextIndex = startIndex + 1;
    
    %Check if we have reached the end of the file
    if nextIndex <= nLines
        
        %Grab data from next line
        nextLine = data{nextIndex};
        
        %Check for data in column 10
        [nextLine, endCol] = i_removeEndColumn(nextLine);
        
        %Check following lines for continuation entries
        while iscont(nextLine)
            %Append to 'cardData' and update counter
            cardIndex = [cardIndex, nextIndex]; %#ok<*AGROW>
            cardData  = [cardData, {nextLine}];
            nextIndex = nextIndex + 1;
            if nextIndex > nLines
                return
            end
            nextLine  = data{nextIndex};
        end
        
    end
    
else
    %If 'endCol' is NOT empty then the card is using
    %continuation entries in column 10 to identify the data.
    %   -> Search the data for the continuation key
    
    %Keep going until there are no more continuations to read
    while ~isempty(endCol)
        
        %Find the continuation line
        %   - Can be anywhere in the file
        index = find(contains(data, endCol));
        if isempty(index)
            error('Continuation entry is not in this file. Update code so we can search all other files as well');
        end
        
        %Remove lines we already know about
        index(index == startIndex) = [];
        
        %Should only be one line that starts with this
        %continuation...
        assert(numel(index) == 1, 'Non-unique continuation entry found');
        
        %Grab card data & update index numbers
        lineData           = data{index};
        cardIndex(end + 1) = index;
        startIndex         = index;
        
        %Check for data in column 10
        [cardData{end + 1}, endCol] = i_removeEndColumn(lineData);
        
    end
    
end

    function [lineData, endCol] = i_removeEndColumn(lineData)
        %i_removeEndColumn If the character array 'lineData' has
        %more than 72 characters then this function trims any
        %additional characters and returns them in the variable
        %'endCol'. The first 72 (or fewer) characters are returned
        %in the variable 'lineData'.
        
        %Sensible default
        endCol = '';
        
        %Check for free-field
        if contains(lineData, ',')
            %Search for continuation token
            ind = strfind(lineData(2:end), '+');
            if ~isempty(ind)
                endCol   = strtrim(lineData(ind + 1 : end));
                lineData = lineData(1 : ind - 1); %Skip the comma!
            end
            return
        end
        
        %If the line does not go to 72 characters then no change
        if numel(lineData) < 73
            return
        end
        
        endCol   = strtrim(lineData(73 : end));
        lineData = lineData(1  : 72);
        
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

%Logging the progress
function logger(str, bNewLine)
%logger Presents the import display to the user.

if nargin < 2
    bNewLine = true;
end

if bNewLine
    esc = '\n';
else
    esc = '';
end

fprintf(['%s', esc], str);

end

% Defining the mask (TODO - Move this out of here. Make it generate
% automatically as part of the testing process)

function BulkDataMask = defineBulkMask()
%defineBulkMask Defines the cross-references between bulk data types and
%bulk data objects.
%
% TODO - Make this generate programtically after the test.

BulkDataMask = struct();

BulkDataMask.GRID   = 'bulk.Node';
BulkDataMask.SPOINT = 'bulk.Node';
BulkDataMask.CBAR   = 'bulk.Beam';
BulkDataMask.CBEAM  = 'bulk.Beam';
BulkDataMask.CROD   = 'bulk.Beam';
BulkDataMask.PBAR   = 'bulk.BeamProp';
BulkDataMask.PBEAM  = 'bulk.BeamProp';
BulkDataMask.PROD   = 'bulk.BeamProp';
BulkDataMask.MAT1   = 'bulk.Material';
BulkDataMask.SPC1   = 'bulk.Constraint';
BulkDataMask.CAERO1 = 'bulk.AeroPanel';

end

