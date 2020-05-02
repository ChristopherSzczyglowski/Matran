function [Parameters, BulkData] = extractParameters(BulkData, logfcn)
%extractParameters Extracts the parameters from the bulk data
%and returns the cell array 'BD' with all parameter lines
%removed.
%
% Syntax:
%	- Brief explanation of the syntax...
%
% Detailed Description:
%	- Detailed explanation of the function and how it works...
%
% See also: 
%
% References:
%	[1]. "Can quantum-mechanical description of physical reality be
%         considered complete?", A Einstein, Physical Review 47(10):777,
%         American Physical Society 1935, 0031-899X
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 01-May-2020 08:21:02
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 01-May-2020 08:21:02
%	- Initial function:
%
% <end_of_pre_formatted_H1>

if nargin < 2 || isempty(logfcn)
    logfcn = @(s) fprintf('');
end

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
