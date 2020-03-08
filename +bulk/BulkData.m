classdef BulkData < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & mixin.Dynamicable
    %BulkData Base-class of all bulk data objects.
    
    %Visualisation
    properties
        %Defines whether the model will be drawn in a deformed or
        %undeformed state.
        DrawMode = 'undeformed';
    end
    
    %Identifying the object
    properties (Hidden = true)
        %Everything has an ID number
        ID
        %Initial counter for the FE object ID numbers. No object will be
        %assigned an ID number lower than this when using the method
        %'assignIDnumbers' in the 'awi.fe.FEModel' object.
        ID0 = 1000;
    end
    
    %FE data
    properties (SetAccess = private)
        %Name of the MSC.Nastran bulk data entry
        CardName
        %Properties related to the bulk data entry
        BulkDataProps = struct('BulkName', {}, 'BulkProps', {}, 'PropTypes', {}, 'PropDefault', {}, 'PropMask', {}, 'Connections', {});
        %Number of bulk data entries in this object
        NumBulk
    end
    properties (Dependent)
        %List of valid bulk data names
        ValidBulkNames
        %Structure containing current bulk data meta
        CurrentBulkDataStruct
        %Current list of bulk data properties
        CurrentBulkDataProps
        %Current list of bulk data formats
        CurrentBulkDataTypes
        %Current list of bulk data default values
        CurrentBulkDataDefaults
    end
    
    methods % set / get
        function set.DrawMode(obj, val)                 %set.DrawMode
            %set.DrawMode Set method for the property 'DrawMode'.
            validatestring(val, {'undeformed', 'deformed'}, class(obj), 'DrawMode');
            obj.DrawMode = lower(val);
        end
        function set.ID(obj, val)                       %set.ID
            %set.ID Set method for the property 'ID'.
            validateID(obj, val, 'ID');
            obj.ID = val;
        end
        function val = get.ValidBulkNames(obj)          %get.ValidBulkNames
            val = {obj.BulkDataProps.BulkName};
        end
        function val = get.CurrentBulkDataStruct(obj)   %get.CurrentBulkDataStruct
           val = [];
            if isempty(obj.CardName) || isempty(obj.BulkDataProps)
                return
            end
            idx = ismember(obj.ValidBulkNames, obj.CardName);
            val = obj.BulkDataProps(idx); 
        end
        function val = get.CurrentBulkDataProps(obj)    %get.CurrentBulkDataProps
            val = [];
            if isempty(obj.CardName) || isempty(obj.BulkDataProps)
                return
            end
            idx = ismember(obj.ValidBulkNames, obj.CardName);
            val = obj.BulkDataProps(idx).BulkProps;
        end
        function val = get.CurrentBulkDataTypes(obj)    %get.CurrentBulkDataTypes
            val = [];
            if isempty(obj.CardName) || isempty(obj.BulkDataProps)
                return
            end
            idx     = ismember(obj.ValidBulkNames, obj.CardName);
            val     = obj.BulkDataProps(idx).PropTypes;
        end
        function val = get.CurrentBulkDataDefaults(obj) %get.CurrentBulkDataDefaults
            val = [];
            if isempty(obj.CardName) || isempty(obj.BulkDataProps)
                return
            end
            idx = ismember(obj.ValidBulkNames, obj.CardName);
            val = obj.BulkDataProps(idx).PropDefault;
        end
    end
        
    methods (Sealed, Access = protected) % handling bulk data sets
        function addBulkDataSet(obj, bulkName, varargin)
            %addBulkDataSet Defines a new set of bulk data entries.
            
            p = inputParser;
            addRequired(p , 'bulkName'   , @ischar);
            addParameter(p, 'BulkProps'  , [], @iscellstr);
            addParameter(p, 'BulkTypes'  , [], @iscellstr);
            addParameter(p, 'BulkDefault', [], @iscell);
            addParameter(p, 'PropMask'   , [], @iscell);
            addParameter(p, 'PropList'   , [], @iscellstr);
            addParameter(p, 'Connections', [], @iscell);
            parse(p, bulkName, varargin{:});
            
            prpNames   = p.Results.BulkProps;
            prpTypes   = p.Results.BulkTypes;
            prpDefault = p.Results.BulkDefault;
            if isempty(prpNames) || isempty(prpTypes) || isempty(prpDefault)
                error(['Must specify the ''BulkProps'', ''BulkType'' and ', ...
                    '''BulkDefault'' in order to add a complete ', ...
                    '''BulkDataProp'' entry.']);
            end
            n = [numel(prpNames), numel(prpTypes), numel(prpDefault)];
            assert(all(diff(n) == 0), ['The number of ''BulkProps'', ', ...
                '''PropTypes'' and ''PropDefault'' must be the same.']);
            propMask = p.Results.PropMask;
            propList = p.Results.PropList;
            
            %Parse
            if ~isempty(propMask)
                assert(rem(numel(propMask), 2) == 0, ['Expected the ', ...
                    '''BulkMask'' to be a cell array of name/value pairs.']);
                nam = propMask(1 : 2 : end);
                val = propMask(2 : 2 : end);
                idx = cellfun(@(x) isprop(obj, x), nam);
                assert(all(idx), ['All properties referred to in ' , ...
                    '''PropMask'' must be a valid property of the ', ...
                    '%s object. The following propertes were not found', ...
                    '\n\n\t%s\n'], class(obj), strjoin(prpNames(~idx), ', '));
                arrayfun(@(ii) validateattributes(val{ii}, {'numeric'}, ...
                    {'scalar', 'integer', 'positive'}, class(obj)), 1 : numel(val));
            end
            idx = cellfun(@(x) isprop(obj, x), prpNames);
            assert(all(idx), ['All ''BulkProps'' must be a valid property ', ...
                'of the %s object. The following propertes were not ', ...
                'found\n\n\t%s\n'], class(obj), strjoin(prpNames(~idx), ', '));
            
            if ~isempty(propList)
                idx = cellfun(@(x) isprop(obj, x), propList);
                assert(all(idx), ['All properties referred to in ' , ...
                    '''PropList'' must be a valid property of the ', ...
                    '%s object. The following propertes were not found', ...
                    '\n\n\t%s\n'], class(obj), strjoin(propList(~idx), ', '));
            end
            
            %Deal with 'Connections'
            con = p.Results.Connections;
            if isempty(con)
                Connections = [];
            else
                                
                assert(mod(numel(con), 3) == 0, ['Expected the ''Connections'' ' , ...
                    'parameter to be a cell-array with number of elements equal ', ...
                    'to a multiple of 3.']);
                
                %Add the dynamic properties
                bulkProp = con(1 : 3 : end);
                bulkType = con(2 : 3 : end);
                dynProps = con(3 : 3 : end);
                cellfun(@(x) addDynamicProp(obj, x), dynProps);
                cellfun(@(x) addDynamicProp(obj, [x, 'Index']), dynProps);
                
                Connections = struct('Prop', bulkProp, 'Type', bulkType, 'DynProp', dynProps);
                
            end
            
            BDS = struct( ...
                'BulkName'   , bulkName    , ...
                'BulkProps'  , {prpNames}  , ....
                'PropTypes'  , {prpTypes}  , ...
                'PropDefault', {prpDefault}, ...
                'PropMask'   , {propMask}  , ...
                'PropList'   , {propList}  , ...
                'Connections', Connections);
            
            if isempty(obj.BulkDataProps)
                obj.BulkDataProps = BDS;
            else
                obj.BulkDataProps = [obj.BulkDataProps, BDS];
            end
            
        end
        function argOut = parse(obj, varargin)
            %parse Checks the inputs to the class/subclass constructor.
            %
            % Required Inputs:
            %   - 'bulkName': Name of the bulk data type (e.g. GRID, CBAR)
            %
            % Optional Inputs:
            %   - 'bulkName': Name of the bulk data type (e.g. GRID, CBAR)
            %       Default = obj.BulkDataProps(1).BulkName;
            %   - 'nBulk': Number of bulk data entries expected.
            %       Default = 1
                        
            %Check user has defined the BulkDatProps
            msg = sprintf(['Expected the constructor of the %s class to ', ...
                'define the ''BulkDataProps'' of the object. Define some ', ...
                'bulk data sets using the ''addBulkDataSet'' method.'], class(obj));
            vn  = obj.ValidBulkNames;
            assert(~isempty(vn), msg);
            
            %Define default input
            if isempty(varargin)
                assert(~isempty(obj.BulkDataProps), msg);
                varargin{1} = obj.BulkDataProps(1).BulkName;
            end
            bulkName = varargin{1};
            
            %Parse the 'bulkName'
            assert(ischar(varargin{1}), ['Expected the first argument to ', ...
                'the class constructor to be the name of the bulk data type.']);    
            idx = ismember(vn, bulkName);
            assert(nnz(idx) == 1, ['The ''CardName'' must match one ', ...
                '(and only one) of the following tokens:\n\n\t%s\n\n', ...
                'For a list of valid options type ''help %s''.']     , ...
                strjoin(vn, ', '), class(obj));
            
            %Parse the number of bulk data entries
            if numel(varargin) < 2
                varargin{2} = 1;
            end
            nBulk = varargin{2};
            validateattributes(nBulk, {'numeric'}, {'scalar', 'integer', ...
                'finite', 'real', 'positive'}, class(obj), 'NumBulk');
            
            obj.CardName = bulkName;
            obj.NumBulk  = nBulk;
            
            varargin([1, 2]) = [];
            argOut = varargin;
            
        end
        function preallocate(obj)
            %preallocate Preallocates the various object properties based
            %on the 'NumBulk' and 'CardName' options.
            
            vn  = obj.ValidBulkNames;
            idx = ismember(vn, obj.CardName);
            assert(nnz(idx) == 1, ['The ''CardName'' must match one ', ...
                '(and only one) of the following tokens:\n\n\t%s\n\n', ...
                'For a list of valid options type ''help %s''.']     , ...
                strjoin(vn, ', '), class(obj));
            BulkDataInfo = obj.BulkDataProps(idx);
            
            nb = obj.NumBulk;
            
            %Real or integer ('r' or 'i') are stored as vectors
            idxNum  = ismember(BulkDataInfo.PropTypes, {'r', 'i'});
            set(obj, BulkDataInfo.BulkProps(idxNum), repmat({zeros(1, nb)}, [1, nnz(idxNum)]));
            
            %Char data ('c') are stored as cell-strings
            idxChar = ismember(BulkDataInfo.PropTypes, {'c'});
            charVal = cellfun(@(x) repmat({x}, [1, nb]), BulkDataInfo.PropDefault(idxChar), 'Unif', false);
            set(obj, BulkDataInfo.BulkProps(idxChar), charVal);
            
        end
    end
    
    methods % interacting with .bdf files
        function extractCardData(obj, cardData, index)
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
            
            if numel(obj) > 1
                error(['Function ''extractCardData'' cannot handle ' , ...
                    'object arrays. Check code to see why an object ', ...
                    'array has been passed to this function.']);
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
            
            %Assign data to the object
            assignCardData(obj, propData, index);
            
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
                
                %Return cell array
                propData = cellstr(propStr);
                if ~isempty(endData)
                    propData = [propData ; cellstr(endData)];
                end
                
            end
            
        end
    end
    
    methods (Access = protected) % assigning data during import
        function assignCardData(obj, propData, index)
            %assignCardData Assigns the card data for the object by
            %converting the raw text input to numeric/char as necessary.
            %
            % FIXME - This is probably overly complex but I'm hoping it
            % will be a one size fits all solution...
            %
            % TODO - Move the definition of the card format outside the
            % function and pass in as an argument. (Remember this function
            % is called in a loop!!)
            
            %Expand card to have full 8 columns of data
            %   - avoids lots of if/elseif statements
            nProp    = numel(propData);
            propData = [propData ; repmat({''}, [8 - nProp, 1])];
            
            %Get bulk data names, format & default values
            %   - TODO: Move this outside of the function
            dataNames   = obj.CurrentBulkDataProps;
            dataFormat  = obj.CurrentBulkDataTypes;
            dataDefault = obj.CurrentBulkDataDefaults;
            
            %Check for masked props and update card format
            idx     = ismember(obj.ValidBulkNames, obj.CardName);
            prpMask = obj.BulkDataProps(idx).PropMask;
            prpName = obj.BulkDataProps(idx).BulkProps;
            indices = ones(1, numel(prpName));
            if ~isempty(prpMask)
                dataFormat  = i_repeatMaskedValues(dataFormat , prpName, prpMask);
                dataDefault = i_repeatMaskedValues(dataDefault, prpName, prpMask);
                %Update indices
                indices(ismember(prpName, prpMask(1 : 2 : end))) = horzcat(prpMask{2 : 2 : end});
            end
            ub = cumsum(indices);
            lb = ub - indices + 1;
            
            dataFormat = horzcat(dataFormat{:});
            
            %Convert integer & real data to numeric data
            numIndex   = or(dataFormat == 'i', dataFormat == 'r');
            numData    = str2double(propData(numIndex));
            numDefault = dataDefault(numIndex);
            prpDefault = dataDefault(~numIndex);
            
            %Allocate defaults
            idxNan            = isnan(numData);
            numData(idxNan)   = vertcat(numDefault{idxNan});
            prpData           = propData(~numIndex);
            idxEmpty          = cellfun(@isempty, prpData);
            prpData(idxEmpty) = prpDefault(idxEmpty);
            
            %Replace original prop data
            propData(numIndex)  = num2cell(numData);
            propData(~numIndex) = prpData;
            propData(~numIndex) = cellfun(@(x) {x}, propData(~numIndex), 'Unif', false);
            
            %Assign data
            for ii = 1 : numel(lb)
                obj.(dataNames{ii})(:, index) = vertcat(propData{lb(ii) : ub(ii)});
            end
            
            function newval = i_repeatMaskedValues(val, prpName, prpMask)
                %i_repeatMaskedValues Repeats the masked values to return
                %the correct number of entries which matches the data in
                %the .bdf
                
                nam_ = prpMask(1 : 2 : end);
                idx_ = ismember(prpName, nam_);
                
                val(~idx_) = cellfun(@(x) {{x}}, val(~idx_));
                val(idx_)  = cellfun(@(x) ...
                    repmat(val(ismember(prpName, x)), ...
                    [1, prpMask{find(ismember(nam_, x)) * 2}]), nam_, 'Unif', false);
                
                newval = horzcat(val{:});
                
            end
            
        end
        function assignCardData_old(obj, propData, index)
            %assignCardData
            
            error('Update code to check this runs');
            
            %Determine which properties have been extracted
            nProp      = numel(propData);
            cardProps  = obj.CurrentBulkDataProps;
            cardFormat = obj.CurrentBulkDataTypes;
            cardProps  = cardProps(1  : nProp);
            format     = cardFormat(1 : nProp);
            
            %Convert integer & real data to numeric data
            numIndex = or(format == 'i', format == 'r');
            numData  = str2double(propData(numIndex));
            
            %Check for 'NaN' and set as empty matrix.
            nanIdx   = isnan(numData);
            numData  = num2cell(numData);
            numData(nanIdx)    = {[]};
            propData(numIndex) = numData;
            
            %Assign properties to the object
            set(obj, cardProps, propData);
            
        end
    end
    
    methods (Sealed, Access = protected) % handling bulk data sets
        function addBulkDataSet(obj, bulkName, varargin)
            %addBulkDataSet Defines a new set of bulk data entries.
            
            p = inputParser;
            addRequired(p , 'bulkName'   , @ischar);
            addParameter(p, 'BulkProps'  , [], @iscellstr);
            addParameter(p, 'BulkTypes'  , [], @iscellstr);
            addParameter(p, 'BulkDefault', [], @iscell);
            addParameter(p, 'PropMask'   , [], @iscell);
            addParameter(p, 'Connections', [], @iscell);
            parse(p, bulkName, varargin{:});
            
            prpNames   = p.Results.BulkProps;
            prpTypes   = p.Results.BulkTypes;
            prpDefault = p.Results.BulkDefault;
            if isempty(prpNames) || isempty(prpTypes) || isempty(prpDefault)
                error(['Must specify the ''BulkProps'', ''BulkType'' and ', ...
                    '''BulkDefault'' in order to add a complete ', ...
                    '''BulkDataProp'' entry.']);
            end
            n = [numel(prpNames), numel(prpTypes), numel(prpDefault)];
            assert(all(diff(n) == 0), ['The number of ''BulkProps'', ', ...
                '''PropTypes'' and ''PropDefault'' must be the same.']);
            propMask = p.Results.PropMask;
            
            %Parse
            if ~isempty(propMask)
                assert(rem(numel(propMask), 2) == 0, ['Expected the ', ...
                    '''BulkMask'' to be a cell array of name/value pairs.']);
                nam = propMask(1 : 2 : end);
                val = propMask(2 : 2 : end);
                idx = cellfun(@(x) isprop(obj, x), nam);
                assert(all(idx), ['All properties referred to in ' , ...
                    '''PropMask'' must be a valid property of the ', ...
                    '%s object. The following propertes were not found', ...
                    '\n\n\t%s\n'], class(obj), strjoin(prpNames(~idx), ', '));
                arrayfun(@(ii) validateattributes(val{ii}, {'numeric'}, ...
                    {'scalar', 'integer', 'positive'}, class(obj)), 1 : numel(val));
            end
            idx = cellfun(@(x) isprop(obj, x), prpNames);
            assert(all(idx), ['All ''BulkProps'' must be a valid property ', ...
                'of the %s object. The following propertes were not ', ...
                'found\n\n\t%s\n'], class(obj), strjoin(prpNames(~idx), ', '));
            
            %Deal with 'Connections'
            con = p.Results.Connections;
            if isempty(con)
                Connections = [];
            else
                                
                assert(mod(numel(con), 3) == 0, ['Expected the ''Connections'' ' , ...
                    'parameter to be a cell-array with number of elements equal ', ...
                    'to a multiple of 3.']);
                
                %Add the dynamic properties
                bulkProp = con(1 : 3 : end);
                bulkType = con(2 : 3 : end);
                dynProps = con(3 : 3 : end);
                cellfun(@(x) addDynamicProp(obj, x), dynProps);
                cellfun(@(x) addDynamicProp(obj, [x, 'Index']), dynProps);
                
                Connections = struct('Prop', bulkProp, 'Type', bulkType, 'DynProp', dynProps);
                
            end
            
            BDS = struct( ...
                'BulkName'   , bulkName  , ...
                'BulkProps'  , {prpNames}, ....
                'PropTypes'  , {prpTypes}, ...
                'PropDefault', {prpDefault}, ...
                'PropMask'   , {propMask}  , ...
                'Connections', Connections);
            
            if isempty(obj.BulkDataProps)
                obj.BulkDataProps = BDS;
            else
                obj.BulkDataProps = [obj.BulkDataProps, BDS];
            end
            
        end
        function preallocate(obj)
            %preallocate Preallocates the various object properties based
            %on the 'NumBulk' and 'CardName' options.
            
            vn  = obj.ValidBulkNames;
            idx = ismember(vn, obj.CardName);
            assert(nnz(idx) == 1, ['The ''CardName'' must match one ', ...
                '(and only one) of the following tokens:\n\n\t%s\n\n', ...
                'For a list of valid options type ''help %s''.']     , ...
                strjoin(vn, ', '), class(obj));
            BulkDataInfo = obj.BulkDataProps(idx);
            
            nb = obj.NumBulk;
            
            %Real or integer ('r' or 'i') are stored as vectors
            idxNum  = ismember(BulkDataInfo.PropTypes, {'r', 'i'});
            set(obj, BulkDataInfo.BulkProps(idxNum), repmat({zeros(1, nb)}, [1, nnz(idxNum)]));
            
            %Char data ('c') are stored as cell-strings
            idxChar = ismember(BulkDataInfo.PropTypes, {'c'});
            charVal = cellfun(@(x) repmat({x}, [1, nb]), BulkDataInfo.PropDefault(idxChar), 'Unif', false);
            set(obj, BulkDataInfo.BulkProps(idxChar), charVal);
            
        end
    end
    
    methods (Sealed) % validation
        function validateID(obj, val, prpName)       %validateID
            if isempty(val)
                return
            end
            validateattributes(val, {'numeric'}, {'integer', '2d', ...
                'real', 'nonnan', 'nonnegative'}, class(obj), prpName);
        end
        function validateDOF(obj, val, prpName)      %validateDOF
            %validateDOF Checks that 'val' is a valid Degree-of-Freedom
            %(DOF) entry.
            %
            % In MSC.Nastran a DOF is defined as any non-repeating
            % combination of the numbers [1,2,3,4,5,6].
            
            assert(iscell(val), ['Expected ''%s'' to be a cell-array ', ...
                'of DOF identifiers, e.g. ''123456''.']);
            if all(cellfun(@isempty, val)) %If it is empty then nothing to check
                return
            end
            
            if ischar(val) %Check for character input
                valString = val;
                val       = str2double(val);
            else
                %Convert value to a string as it is easier to validate
                valString = num2str(val);
            end
            
            %First level of validation to check correct type and attributes
            validateattributes(val, {'numeric'}, {'scalar', 'integer', ...
                'nonnan', 'finite', 'real'}, class(obj), prpName);
            
            %Second level of validation to check that 'val' is a valid SPC
            
            %Have more than 6 characters been provided?
            if numel(valString) > 6
                throwME_SPC(obj, valString, prpName);
            end
            
            %Has a negative number been provided?
            %if any(contains(cellstr(valString')', '-'))
            if any(cellfun(@(x) ~isempty(x), strfind(cellstr(valString')', '-')))
                throwME_SPC(obj, valString, prpName);
            end
            
            %Get individual numbers
            valVector = str2num(valString'); %#ok<ST2NM>
            
            %Are there any numbers outside the range [1 : 6]?
            if any(valVector < 0) || any(valVector > 6)
                throwME_SPC(obj, valString, prpName);
            end
            
            %Have any numbers been repeated twice?
            
            function throwME_SPC(obj, val, paramName)
                %throwME_SPC Throws an MException object containing the
                %error message for a badly formatted SPC entry.
                
                %Generate ME object.
                %                 ME = MException('matlab:awi:BadSPC', ['Value ''%s'' for ', ...
                %                     'the property ''%s.%s'' in the object %s does not '  , ...
                %                     'define a valid Single Point Constraint (SPC).\n\n'  , ...
                %                     'An SPC must be defined using the integers 1 '       , ...
                %                     'through to 6 and can only have a maximum of 6 '     , ...
                %                     'numbers. Negative numbers are not allowed.\n\n\t'   , ...
                %                     'For example, ''123456'' is a valid SPC but '        , ...
                %                     '''10984'' is not.\n\nFor further information see  ' , ...
                %                     'the MSC.Nastran Quick Reference Guide.'], ...
                %                     val, class(obj), paramName, obj.NameTypeID);
                %
                ME = MException('matlab:ALENA:BadSPC', ['Value ''%s'' ', ...
                    'does not define a valid Single Point Constraint (SPC).\n\n', ...
                    'A SPC must be defined using the integers 1 '       , ...
                    'through to 6 and can only have a maximum of 6 '     , ...
                    'numbers. Negative numbers are not allowed.\n\n\t'   , ...
                    'For example, ''123456'' is a valid SPC but '        , ...
                    '''10984'' is not.\n\nFor further information see ' , ...
                    'the MSC.Nastran Quick Reference Guide.'], ...
                    val);
                
                %Throw the ME to the user.
                throwAsCaller(ME);
            end
            
        end
        function validateBeamProp(obj, val, prpName) %validateBeamProp
            %validateBeamProp Checks that the values of the beam property
            %with name 'prpName' matches the expected format.
            %
            % Each beam property is expected to be a 2 element column
            % vector of real numbers.
            
            validateattributes(val, {'numeric'}, {'column', 'numel', 2, ...
                'nonempty', 'finite', 'real', 'nonnan'}, class(obj), prpName);
        end
        function validateLabel(obj, val, prpName)    %validateLabel
            %validateLabel Checks that the value of the label with property
            %name 'prpName' matches the expected format.
            %
            % Each label must be a character row vector of less than 8
            % characters.
            validateattributes(val, {'char'}, {'row', 'nonempty'}, ...
                class(obj), prpName);
            assert(numel(val) < 9, sprintf(['The label ''%s'' must ', ...
                'have less than 9 characters'], prpName));
        end
    end
    
    methods (Sealed) % helper functions for heterogeneous arrays 
        function varargout = set(obj,varargin)
            [varargout{1:nargout}] = set@matlab.mixin.SetGet(obj,varargin{:});
        end        
        function varargout = get(obj,varargin)
            [varargout{1:nargout}] = get@matlab.mixin.SetGet(obj,varargin{:});
        end        
    end
    
    methods (Access = protected) % helper functions for visualisation
        function x = padCoordsWithNaN(~, x)
            %padCoordsWithNaN Accepts a matrix of [2, N] sets of
            %coordinates which represent the coordinate of a series of
            %lines from end-A to end-B and returns a single vector with all
            %of the coordinates padded by NaN terms.
            %
            % This function enables the plotting of line objects to be
            % vectorised.
            
            %Convert to cell so we retain the pairs of coordinates in the
            %correct order
            x  = num2cell(x, 1);
            
            %Preallocate
            x_ = cell(1, 2 * numel(x));
            
            %Assign the data and NaN terms
            x_(1 : 2 : end - 1) = x;
            x_(2 : 2 : end)     = {nan};
            
            %Return a column vector
            x = vertcat(x_{:});
            
        end
    end
    
    methods % visualisation
        function hg = drawElement(~, ~)
            %drawElement Plots the object in the parent graphics object
            %specified by 'ht'.
            %
            % Default method just returns an empty matrix.
            
            hg = [];
            
        end
    end
    
end

