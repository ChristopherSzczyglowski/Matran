classdef List < bulk.BulkData
    %List Describes a set of bulk data that can have an arbitrary number of
    %data points.
    %
    % TODO - Change preallocation so list data preallocates as a cell
    % instead of a real.
    
    methods % construction
        function obj = List(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'AEFACT', ...
                'BulkProps'  , {'SID', 'Di'}, ...
                'PropTypes'  , {'i'  , 'r'} , ...
                'PropDefault', {''   , '' } , ...
                'ListProp'   , {'Di'});
            addBulkDataSet(obj, 'SET1', ...
                'BulkProps'  , {'SID', 'Gi'}, ...
                'PropTypes'  , {'i'  , 'r'} , ...
                'PropDefault', {''   , '' } , ...
                'ListProp'   , {'Gi'});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
            
        end
    end
    
    methods % assigning data during import
        function assignCardData(obj, propData, index, BulkMeta)
            %assignCardData
            
            %Index the list
            aNames    = BulkMeta.Names;
            aFormat   = BulkMeta.Format;
            listNames = obj.CurrentBulkDataStruct.PropList;
            ind       = find(contains(aNames, listNames) == true);
            
            %Grab variable names
            b4List = aNames(1 : ind(1) - 1);
            nb4    = numel(b4List);
            if numel(aNames) > ind(end) %Is there any data after the list?
                error('Update code to extract bulk data after a list');
                afterList = aNames(ind(end) + 1 : end);
                nAfter = numel(afterList);
            end            
            
            %Parse the data before the list starts
            dat     = propData(1 : nb4);
            strData = propData(nb4 + 1 : end);
            
            %Convert to correct data types
            idx = or(aFormat(1 : nb4) == 'i', aFormat(1 : nb4) == 'r');
            dat(idx) = num2cell(str2double(dat(idx)));
            set(obj, b4List, dat);    %Assign to the object
            
            %Parse the list data
            propData = i_parseListData(strData, obj.CardName);            
            
            function propData = i_parseListData(strData, nam)
                %i_parseListData Converts all the data in 'strData' into
                %type double. If the keywork 'THRU' is found then it is
                %replaced by the intermediate numbers.
                %
                % TODO - Update this so it can handle lists of strings.
                
                strData(cellfun(@isempty, strData)) = [];
                
                %Convert to numeric data & check for NaN (e.g. char data)
                propData = str2double(strData);                
                idx_     = isnan(propData);
                propData = num2cell(propData);
                
                %Populate intermediate ID numbers
                if any(idx_)
                                        
                    %Check for "THRU" keyword
                    nanData = strData(idx_);
                    
                    %Tell the user if we can't handle it
                    if any(~contains(nanData, 'THRU'))
                        error(['Unhandled text data in the element %s. ', ...
                            'The following words were unable to be ', ...
                            'parsed\n\t%s'], nam, ...
                            sprintf('%s\n\t', nanData{:}))
                    end
                    
                    %Use linear indexing
                    ind_ = find(idx_ == true);
                    
                    %Populate intermediate terms
                    for i = 1 : numel(nanData)
                        propData{ind_} = ((propData{ind_ - 1} + 1) : ...
                            1 : (propData{ind_ + 1} - 1));
                    end
                end
                
            end
                       
            %Split into sets of 'numel(listVar)'
            nListVar = numel(listNames);
            if nListVar > 1
                error('Check code runs and use row vectors not column vectors.');
            end
            propData = [propData{:}];
            nData    = numel(propData);
            propData = reshape(propData, [nData / nListVar, nListVar]);
            propData = num2cell(propData, 1);
            
            %Assign to object
            set(obj, listNames, propData);
                        
        end
    end
    
end

