function [FEModel, FileMeta] = importBulkData(bulkFilename)
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
%
% TODO - Look at whether we can take a sneak peak through all the files by
% only extracting the first 8 characters to understand file contents. Then
% we preallocate the objects and read the file in chunks instead of reading
% the whole file into the memory.

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

FileMeta.UnknownBulk = strtrim(cellfun(@(x) x(1 : strfind(x, '-') - 1), skippedCards, 'Unif', false));

%Build connections
makeIndices(FEModel);

%Print a summary 
printSummary(FEModel, 'LogFcn', logfcn, 'RootFile', filename);
if isempty(skippedCards)
    logfcn('All bulk data entries were successfully extracted!');
else
    logfcn(sprintf(['The following cards have not been extracted ', ...
        'from the file ''%s'':\n\n\t%-s\n'], bulkFilename, ...
        sprintf('%s\n\t', skippedCards{:})));
end

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
[~, ~, bd, unresolvedBulk] = splitInputFile(rawFileData, logfcn);

%Extract "NASTRAN SYSTEM" commands from Executive Control

%Extract Case Control data

%Extract "PARAM" from Bulk Data
[Parameters, bd] = extractParameters(bd, logfcn);

%Extract "INCLUDE" statements and corresponding file names
[IncludeFiles, bd] = extractIncludeFiles(bd, logfcn, filepath);

%Extract bulk data
[FEM, unknownBulk] = extractBulkData(bd, logfcn);

%Loop through INCLUDE files (recursively)
[data, leftover] = cellfun(@(x) importBulkDataFromFile(x, logfcn), ...
    IncludeFiles, 'Unif', false);

if ~isempty(data)
    logfcn(sprintf('Combining bulk data from file ''%s'' and any INCLUDE files...', bulkFilename));
    combine(horzcat(FEM, data{:}));
end

%Combine data & diagnostics from INCLUDE data
unknownBulk = [unknownBulk, cat(2, leftover{:})];

end

%Partitioning the Nastran input file
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

BulkDataMask = defineBulkMask();

%Extract all card names and continuation entries (for indexing)
col1 = cellfun(@(x) x(1 : min([numel(x), 8])), BulkData, 'Unif', false);
%   - If a comma is present then remove data before the comma
idx  = contains(col1, ',');
ind_ = strfind(col1, ',');
col1(idx) = arrayfun(@(i) col1{i}(1 : ind_{i} - 1), find(idx), 'Unif', false);
col1      = strtrim(col1);

%Find all unique names in the collection
%   - N.B. Uniqueness not guaranteed because of potential for
%          free-field bulk data cards.
idxCont   = or(cellfun(@(x) iscont(x), col1), ~isnan(str2double(col1))); %A free-field continuation can contain numeric data
cardNames = strtrim(unique(col1(~idxCont), 'stable'));      %Extract the data in the order it appears
cardNames = unique(strrep(cardNames, '*', ''), 'stable');   %Remove duplicates due to wide-field format
cardNames = cardNames(~cellfun(@isempty, cardNames));

%Loop through cards - create objects & populate properties
for iCard = 1 : numel(cardNames)
    
    cn = cardNames{iCard};
    
    %Find all cards of this type in the collection BUT do not
    %include continuation lines. We are searching for the first
    %line of the card.
    idx   = and(or(strcmp(col1, cn), strcmp(col1, [cn, '*'])), ~idxCont);
    ind   = find(idx == true);
    nCard = nnz(idx);
    
    if nCard == 0 %Catch
        continue
    end
        
    [bClass, str] = isMatranClass(cn, BulkDataMask);
        
    %If the class exists then we can import the data, if not, skip it
    if bClass
        
        %Tell the user
        logfcn(sprintf('%-10s %-8s (%8i)', 'Extracting', ...
            cn, nCard), 0);
        
        %Initialise the object
        fcn     = str2func(str);
        BulkObj = fcn(cn, nCard);

        %Set up character tokens for denoting progress
        nChar     = 50;  %total number of characters to denote 100%
        progChar  = repmat({''}, [1, nCard]);
        backspace = repmat({''}, [1, nCard]);
        incr      = nCard / nChar;
        if floor(incr) == 0
            progress0 = '';
        else
            index        = floor(incr : incr : nCard);
            index(end)   = nCard;
            num          = numel(index);
            progress0    = ['[', repmat(' ', [1, num]), ']'];
            progressStr  = arrayfun(@(ii) ['[', pad(repmat('#', [1, ii]), num), ']'], 1 : num, 'Unif', false);
            backspaceStr =  {repmat('\b', [1, numel(progress0)])};
            backspace(index) = backspaceStr;
            progChar(index)  = progressStr;
        end
        
        BulkMeta = getBulkMeta(BulkObj);
        
        switch cn %Function for parsing bulk data entry
            case 'PBEAM'
                extractFcn = @parsePBEAM;
            otherwise
                extractFcn = @parseBulkDataEntry;
        end
                
        logfcn('       ', 0);
        logfcn(progress0, 0);
        %Extract data for each instance of the card
        for iCard = 1 : nCard %#ok<FXSET> 
            %Extract raw text data for this card and assign to the object
            propData = extractFcn(BulkData, ind(iCard), col1);
            BulkObj.BulkAssignFunction(BulkObj, propData, iCard, BulkMeta);
            %Strip the previous progress string and write the new one
            logfcn(backspace{iCard}, 0, 1);
            logfcn(progChar{iCard} , 0);
        end
        logfcn('');
        
        %Add object to the model
        addBulk(FEM, BulkObj);
        
        clear card
        
    else
        
        %Make a note of it
        logfcn(sprintf('%-10s %-8s (%8i)', 'Skipped', ...
            cn, nCard));
        UnknownBulk{end + 1} = sprintf( ...
            '%8s - %6i entry/entries', cn, nCard);
        
    end
    
end

end

%Reading text data as bulk data
function propData = parseBulkDataEntry(BulkData, index, col1)
%parseBulkDataEntry Finds all lines in the file that contain data for this
%card and splits the data into sets of bulk data values.

[cardData, ~] = getCardData(BulkData, index, col1);
propData      = extractCardData(cardData);            

end
function propData = parsePBEAM(BulkData, index, col1)
%parsePBEAM Finds all lines in the file that contain data for a PBEAM card
%and splits the data into set of bulk data values. 
%
% N.B. A seperate function is required because the PBEAM is extremely
% tricky to deal with

%TODO - Update this so we return a normal propdata but we always ensure it
%has 48 elements (e.g. 6 rows of 8 sets of data)

[cardData, ~] = getCardData(BulkData, index, col1);
if ~any(contains(cardData, ','))
    error('Check code');
end
propData = extractCardData(cardData, true);

%Find beam stations - Only retain x_xL = [0, 1]
idx           = cellfun(@(x) any(contains(x, {'YES', 'YESA', 'NO'})), propData);
if nnz(idx) > 1
    warning('Unable to handle PBEAM entries with more than one beam station. Update the code.');
end
beamInd       = find(idx);
beamInd       = [beamInd ; beamInd + 1];
idxEndStation = cellfun(@(x) str2double(x{2}) == 1, propData(idx));
indRemove     = beamInd(:, ~idxEndStation);
propData(indRemove(:)) = [];

%Pad each row to have 8 sets of data
propData = cellfun(@(x) [x, repmat({''}, [1, 8 - numel(x)])], propData, 'Unif', false);

end
function propData = extractCardData(cardData, bRetainRows)
%extractCardData Splits the raw character data into individual values based
%on how the data is delimited.
%
%   * Fixed-width - Delimited by columns of equal width -> Data
%                   can be extracted using 'textscan'.
%   * Free-Field - Delimited by commas -> Data can be extracted
%                  using strsplit.

if nargin < 2
    bRetainRows = false;
end

%Read data from the character array
if any(contains(cardData, ','))
    %Free-Field
    
    nRow     = numel(cardData);
    propData = cell(size(cardData));
    
    %Read each row using 'strsplit'
    for iR = 1 : nRow
        %Delimit the data
        temp = strsplit(cardData{iR}, ',');
        %Assume the first entry is the card name or the
        %continuation entry
        if isnan(str2double(temp{1}))
            propData{iR} = temp(2 : end);
        else
            propData{iR} = temp;
        end
    end
    
    nCols = cellfun(@numel, propData);
    
    %Return a cell-array
    propData = horzcat(propData{:});
    
else
    %Fixed-Width
    
    n = numel(cardData);
    
    %Determine column width
    cw      = repmat(8, [n, 1]);
    idx     = contains(cardData, '*');
    cw(idx) = 16;
    
    %Remove the first column of the card data
    cardData = cellfun(@(x) x(9 : end), cardData, 'Unif', false);
    
    if all(idx) || nnz(idx) == 0
        %All one column width
        
        %Convert cell array to character array
        strData = cat(2, cardData{:});
        
        %Reshape using column width
        propData = i_splitDataByColWidth(strData, cw(1));
        
    else
        error('Check this code');
        %Mixed column widths - Loop through
        propData = cell(1, n);
        for ii = 1 : n
            propData{ii} = obj.splitDataByColWidth(cardData{ii}, cw(ii));
        end
        propData = vertcat(propData{:});
    end
    
end

%Strip blank spaces so we can parse data regardless of indentation
propData = strtrim(propData);

%Check for scientific notation without 'E'
propData = i_parseScientificFormat(propData, '+');
propData = i_parseScientificFormat(propData, '-');

if bRetainRows %Recover row format
    ub = cumsum(nCols);
    lb = [1, ub(1 : end - 1) + 1];
    propData = arrayfun(@(ii) propData(lb(ii) : ub(ii)), 1 : numel(lb), 'Unif', false);
end

    function propData = i_splitDataByColWidth(strData, colWidth)
        %i_splitDataByColWidth Splits the character array 'strData'
        %into a cell string array of character vectors with maximum
        %length 'colWidth'.
        %
        % This function is used to delimit the literal text data from a
        % MSC.Nastran bulk data entry. It is assumed that columns 1 &
        % 10 (i.e. characters 1-8 and 73-80) have been removed from
        % each line.
        %
        % 'strData' is the concatenation of each line of the bulk data
        % card with columns 1 and 10 removed.
        
        nChar = numel(strData);           %How many characters?
        nRem  = mod(nChar, colWidth) - 1; %Anything left over after?
        nData = floor(nChar / colWidth);  %How many properties?
        
        %Reshape
        dataStr = strData(1 : (nData * colWidth));
        endData = strData(end - nRem  : end);
        propStr = reshape(dataStr, [colWidth, nData])';
        
        if isempty(propStr)
            propData = [];
        else
            %Return cell array            
            propData = cellstr(propStr);
        end
        
        if ~isempty(endData)
            propData = [propData ; cellstr(endData)];
        end
        
    end

    function propData = i_parseScientificFormat(propData, tok)
        %i_parseScientificFormat Replaces any '-' or '+' data with 'E+' and
        %'E-' respectively. 
        %
        % Does not replace these tokens if they appear at the start of the
        % line. e.g. denoting a negative number instead of using scientific
        % format.
        idx_ = and(and(contains(propData, tok), ~contains(propData, 'E')),~startsWith(propData, tok));
        propData(idx_) = strrep(propData(idx_), tok, ['E', tok]);
    end

end
