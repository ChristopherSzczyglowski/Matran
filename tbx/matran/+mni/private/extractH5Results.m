function [Results, UnknownResults] = extractH5Results(filename, logfcn)
%extractH5Results

Results        = mni.result.ResultSet;
UnknownResults = [];
ResultMask     = defineResultMask;

MetaGroup  = h5info(filename, '/NASTRAN/RESULT');
Results    = extractData(filename, MetaGroup, Results, ResultMask, logfcn, UnknownResults);

end

function Results =  extractData(filename, MetaGroup, Results, BulkDataMask, logfcn, UnknownBulk)
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
    names = {MetaGroup.Datasets.Name};
    for i = 1 : numel(names)

        cn = assignCardName(names{i}, allBulkNames);
        [bClass, str] = isMatranClass(cn, BulkDataMask);
        if ~bClass
            logfcn(sprintf('%-10s %-8s (%8s)', 'Skipped', names{i}, blanks(8)));
            UnknownBulk{end + 1} = sprintf( ...
                '%8s - %6s entry/entries', names{i}, 'n/a   ');
            continue
        end

        groupset  = strcat([MetaGroup.Name, '/'], names{i});
        IndexData = h5read(filename, ['/INDEX', groupset]);
        nCard     = numel(IndexData.DOMAIN_ID);
        
        logfcn(sprintf('%-10s %-8s (%8i)', 'Extracting', cn, nCard), true);  
        fcn        = str2func(str);
        ResultsObj = arrayfun(@(~) fcn(), 1 : nCard);
        
        assignH5ResultsData(ResultsObj, filename, groupset);
        %Add object to the model
        addItem(Results, ResultsObj);
    end
% else
%     [bClass, str] = isMatranClass(cn, BulkDataMask);
%     if bClass
%         %Get the remaining data below this group
%         h5Struct = readH5intoStruct(filename, MetaGroup);
%         logfcn(sprintf('%-10s %-8s (%8s)', 'Extracting',cn, blanks(8)), true);
%         %Build the object
%         fcn     = str2func(str);
%         BulkObj = fcn(); %(cn);
%         %Assign data
%         [bulkNames, bulkData] = parseH5DataGroup(BulkObj, h5Struct);
%         assignH5BulkData(BulkObj, bulkNames, bulkData);
%         %Add object to the model
%         addBulk(FEM, BulkObj);
%         %Remove this group from the list so that we don't get duplicates
%         metagroupNames(contains(metagroupNames, MetaGroup.Name)) = [];
%     else
%         logfcn(sprintf('%-10s %-8s (%8s)', 'Skipped', leaf, blanks(8)));
%         UnknownBulk{end + 1} = sprintf( ...
%             '%8s - %6s entry/entries', leaf, 'n/a   ');
%     end
end

%Recurse through groups
if ~isempty(metagroupNames)
    allMetagroupNames = {MetaGroup.Groups.Name};
    for iG = 1 : numel(metagroupNames)
        idx = ismember(allMetagroupNames, metagroupNames{iG});
        extractData(filename, MetaGroup.Groups(idx), Results, BulkDataMask, logfcn, UnknownBulk);
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

