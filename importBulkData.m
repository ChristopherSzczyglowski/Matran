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

%Print a summary of all the data contained in the file and any
%embedded files
summary = summarise(FEModel);
logfcn(sprintf('Extraction summary :\n'));
logfcn(sprintf(['The following cards have been extracted ', ...
    'successfully from the file ''%s'':\n\t%-s\n'], ...
    bulkFilename, sprintf('%s\n\t', summary{:})));
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
    combineBulkData(horzcat(FEM, data{:}));
end

%Combine data & diagnostics from INCLUDE data
% cellfun(@(x) addBulk(FEM , x), data    , 'Unif', false);
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

%project folder
prj = 'bulk';

BulkDataMask = defineBulkMask();

%Extract all card names and continuation entries (for indexing)
col1 = cellfun(@(x) x(1 : 8), BulkData, 'Unif', false);
%   - If a comma is present then remove data before the comma
idx  = contains(col1, ',');
ind_ = strfind(col1, ',');
col1(idx) = arrayfun(@(i) col1{i}(1 : ind_{i} - 1), find(idx), 'Unif', false);

%Find all unique names in the collection
%   - N.B. Uniqueness not guaranteed because of potential for
%          free-field bulk data cards.
idxCont   = cellfun(@(x) iscont(x), col1);
idxCont   = or(idxCont, ~isnan(str2double(col1))); %A free-field continuation can contain numeric data
col1      = strtrim(col1);
idx       = or(idxCont, contains(col1, '*')); %Got to account for card names with large-field format
cardNames = unique(col1(~idx), 'stable');     %Extract the data in the order it appears

%BUT, if the file has been written in free-field
%(comma-seperated) format the 'cardNames' may not be valid so
%we need to trim all text after (and including) the comma.
% idxComma = contains(cardNames, ',');
% indComma = strfind(cardNames , ','); %TODO : Investigate what is quicker. Could do cellfun(@isemtpy, ind) to get logical index 'idx'
% cardNames(idxComma) = arrayfun(@(i) cardNames{i}(1 : indComma{i} - 1), find(idxComma), 'Unif', false);
%   - Do the same for col1
% idx_ = and(contains(col1, ','), ~idx);
% ind_ = strfind(col1, ',');
% col1(idx_) = arrayfun(@(i) col1{i}(1 : ind_{i} - 1), find(idx_), 'Unif', false);
%Remove any numeric data that is in the first column due to free-field
%format
%cardNames = cardNames(isnan(str2double(cardNames)));

%Now get the actual unique names
cardNames = strtrim(unique(cardNames, 'stable'));
cardNames = cardNames(~cellfun(@isempty, cardNames));

%Loop through cards - create objects & populate properties
for iCard = 1 : numel(cardNames)
    
    cn = cardNames{iCard};
    
    %Find all cards of this type in the collection BUT do not
    %include continuation lines. We are searching for the first
    %line of the card.
    %idx = and(contains(col1, cn), ~idxCont);
    idx   = and(or(strcmp(col1, cn), strcmp(col1, [cn, '*'])), ~idxCont);
    %idx   = and(contains(col1, cn), ~idxCont);
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
        isWF  = contains(col1(idx), '*');
        if any(isWF)
            error('Update code for wide-field format');
        end
        %         set(card(isWF) , 'ColWidth', 16);
        %         set(card(~isWF), 'ColWidth', 8);
        
        %Set up character tokens for denoting progress
        nChar     = 50;  %total number of characters to denote 100%
        progChar  = repmat({''}, [1, nCard]);
        backspace = repmat({''}, [1, nCard]);
        incr      = floor(nCard / nChar);
        if incr == 0
            progress0 = '';
        else
            index        = [incr : incr : nCard];
            num          = numel(index);
            progress0    = ['[', repmat(' ', [1, num]), ']'];
            progressStr  = arrayfun(@(ii) ['[', pad(repmat('#', [1, ii]), num), ']'], 1 : num, 'Unif', false);
            backspaceStr =  {repmat('\b', [1, numel(progress0)])};
            backspace(index) = backspaceStr;
            progChar(index)  = progressStr;
        end
        
        BulkMeta = getBulkMeta(BulkObj);
        if isempty(BulkMeta.ListProp)
            extract_fcn = @assignCardData;
        else
            extract_fcn = @assignListCardData;
        end
                
        logfcn('       ', 0);
        logfcn(progress0, 0);
        %Extract data for each instance of the card
        for iCard = 1 : nCard %#ok<FXSET> 
            %Extract raw text data for this card and assign to the object
            [cardData, ~] = getCardData(BulkData, ind(iCard), col1);
            propData      = extractCardData(cardData);
            extract_fcn(BulkObj, propData, iCard, BulkMeta);
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
function propData = extractCardData(cardData)
%extractCardData Extracts raw text data from 'cardData' for a
%table-formatted MSC.Nastran card relating to the object 'obj'.
%
% Table-formatted cards can ony have one value per property so
% it is a simple matter of extracting the data based on the
% delimiter.
%   * Fixed-width - Delimited by columns of equal width -> Data
%                   can be extracted using 'textscan'.
%   * Free-Field - Delimited by commas -> Data can be extracted
%                  using strsplit.

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
        propData{iR} = temp(2 : end);
    end
    
    %Return a cell-vector
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

%Logging the progress
function logger(str, bNewLine, bLiteral)
%logger Presents the import display to the user.

if nargin < 2
    bNewLine = true;
end
if nargin < 3
    bLiteral = false;
end

%Add an EoL
if bNewLine
    esc = '\n';
else
    esc = '';
end

%Allow escape characters
if bLiteral
    fprintf([str, esc]);
else
    fprintf(['%s', esc], str);
end

end

% Defining the mask (TODO - Move this out of here. Make it generate
% automatically as part of the testing process)
function BulkDataMask = defineBulkMask()
%defineBulkMask Defines the cross-references between bulk data types and
%bulk data objects.
%
% TODO - Make this generate programtically after the test.

BulkDataMask = struct();

BulkDataMask.CORD2R  = 'bulk.CoordSystem';
BulkDataMask.GRID    = 'bulk.Node';
BulkDataMask.SPOINT  = 'bulk.Node';
BulkDataMask.CBAR    = 'bulk.Beam';
BulkDataMask.CBEAM   = 'bulk.Beam';
% BulkDataMask.CROD   = 'bulk.Beam';
BulkDataMask.PBAR    = 'bulk.BeamProp';
% BulkDataMask.PBEAM   = 'bulk.BeamProp';
BulkDataMask.PROD    = 'bulk.BeamProp';
BulkDataMask.PSHELL  = 'bulk.Property';
BulkDataMask.MAT1    = 'bulk.Material';
BulkDataMask.SPC1    = 'bulk.Constraint';
BulkDataMask.CAERO1  = 'bulk.AeroPanel';
BulkDataMask.SPLINE1 = 'bulk.AeroelasticSpline';
BulkDataMask.SPLINE2 = 'bulk.AeroelasticSpline';
BulkDataMask.CQUAD4  = 'bulk.Shell';
BulkDataMask.CTRIA3  = 'bulk.Shell';
BulkDataMask.AEFACT  = 'bulk.List';
BulkDataMask.SET1    = 'bulk.List';
% BulkDataMask.ASET1   = 'bulk.List';
BulkDataMask.PAERO1  = 'bulk.List';
BulkDataMask.FLFACT  = 'bulk.List';
BulkDataMask.TABDMP1 = 'bulk.List';
BulkDataMask.TABLED1 = 'bulk.List';
BulkDataMask.TABRND1 = 'bulk.List';
BulkDataMask.CONM1   = 'bulk.Mass';
BulkDataMask.CONM2   = 'bulk.Mass';
BulkDataMask.CMASS1  = 'bulk.ScalarElement';
BulkDataMask.CMASS2  = 'bulk.ScalarElement';
BulkDataMask.CMASS3  = 'bulk.ScalarElement';
BulkDataMask.CMASS4  = 'bulk.ScalarElement';
BulkDataMask.CELAS1  = 'bulk.ScalarElement';
BulkDataMask.CELAS2  = 'bulk.ScalarElement';
BulkDataMask.AERO    = 'bulk.AnalysisData';
BulkDataMask.EIGR    = 'bulk.AnalysisData';
BulkDataMask.EIGRL   = 'bulk.AnalysisData';
BulkDataMask.FLUTTER = 'bulk.AnalysisData';
BulkDataMask.FREQ1   = 'bulk.AnalysisData';

end

