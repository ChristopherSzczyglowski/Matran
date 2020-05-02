function [cardData, cardIndex] = getCardData(data, startIndex, col1)
%getCardData Extracts the MSC.Nastran bulk data for a given card from the
%cell array 'data'. The card begins at 'startIndex' and the card data is
%extracted by searching 'data' for the continuation entries relating to
%this card.
%
% Syntax:
%	- Brief explanation of the syntax...
%
% Detailed Description:
%	- Detailed explanation of the function and how it works...
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
% See also:
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 19-Apr-2020 16:11:29
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 19-Apr-2020 16:11:29
%	- Initial function:
%
% <end_of_pre_formatted_H1>

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

%Remove comments found partway through a line
commentInd = strfind(lineData, '$');
if ~isempty(commentInd)
    lineData = lineData(1 : commentInd - 1);
end

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
        
        %Check following lines for continuation entries
        while iscont(nextLine)
            %Check for data in column 10
            [nextLine, ~] = i_removeEndColumn(nextLine);
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
        index = find(ismember(col1, endCol));
        if isempty(index)
            break
            %error('Continuation entry is not in this file. Update code so we can search all other files as well');
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
            temp = strsplit(lineData, ',');
            if startsWith(temp{end}, '+')
                endCol = lineData{end};
            end
            if or( ...
                    ~contains(lineData, '*') && numel(temp) == 10, ...
                    contains(lineData, '*') && numel(temp) == 6)
                lineData = strjoin(temp(1 : end - 1), ',');
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
