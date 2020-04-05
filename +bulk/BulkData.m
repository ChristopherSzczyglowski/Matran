classdef BulkData < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & mixin.Dynamicable
    %BulkData Base-class of all bulk data objects.
    %
    % TODO: Think about how to handle bulk data types where a particular
    % row/column can have a different property name depending on the data
    % type. e.g. 'CQUAD4'
    % TODO: Think about adding another option to the BulkDataStructure
    % which allows a bulk property to have a list of allowable characters,
    % e.g. MASS, MAX, POINT for the EIGRL card
    
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
    end
    
    %FE data
    properties (SetAccess = private)
        %Name of the MSC.Nastran bulk data entry
        CardName
        %Properties related to the bulk data entry
        BulkDataProps = struct( ...
            'BulkName'   , {}, 'BulkProps', {}, 'PropTypes', {}, ...
            'PropDefault', {}, 'PropMask' , {}, 'ListProp' , {}, ...
            'Connections', {}, 'AttrList' , {}, 'SetMethod', {});
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
    properties (Dependent, Hidden = true)
       %Current list of bulk data formats excluding 'b entries
        CurrentBulkDataTypes_ 
    end
    
    %Dynamic props
    properties (Hidden = true, SetAccess = private)
        %Name of the dynamic property being set by the
        %'PreSet'/'Set'/'PostSet' listener chain
        DynPropBeingSet
        %Structure containing a record of the most recent pre-set values
        %for the object dynamic properties.
        PreSetVal = struct();
        %Logical flag for indicating whether the current dynamic property
        %has failed a validation case.
        DynPropDirty = false;
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
        function val = get.CurrentBulkDataTypes_(obj)   %get.CurrentBulkDataTypes_
            val = obj.CurrentBulkDataTypes;
            if isempty(val)
                return
            end
            val = val(~ismember(val, 'b'));
        end
    end
        
    methods (Sealed, Access = protected) % handling bulk data sets
        function addBulkDataSet(obj, bulkName, varargin)
            %addBulkDataSet Defines a new set of bulk data entries.
                      
            p = inputParser;
            addRequired(p , 'bulkName'   , @ischar);
            addParameter(p, 'BulkProps'  , [], @iscellstr);
            addParameter(p, 'PropTypes'  , [], @iscellstr);
            addParameter(p, 'PropDefault', [], @iscell);
            addParameter(p, 'PropMask'   , [], @iscell);
            addParameter(p, 'ListProp'   , {}, @iscellstr);
            addParameter(p, 'Connections', [], @iscell);
            addParameter(p, 'AttrList'   , [], @iscell);
            addParameter(p, 'SetMethod'  , [], @iscell);
            parse(p, bulkName, varargin{:});
            
            prpNames   = p.Results.BulkProps;
            prpTypes   = p.Results.PropTypes;
            prpDefault = p.Results.PropDefault;
            if isempty(prpNames) || isempty(prpTypes) || isempty(prpDefault)
                error(['Must specify the ''BulkProps'', ''BulkType'' and ', ...
                    '''BulkDefault'' in order to add a complete ', ...
                    '''BulkDataProp'' entry.']);
            end
            prpTypes_ = prpTypes(~ismember(prpTypes, 'b'));
            n = [numel(prpNames), numel(prpTypes_), numel(prpDefault)];
            assert(all(diff(n) == 0), ['The number of ''BulkProps'', ', ...
                '''PropTypes'' and ''PropDefault'' must be the same.']);                   
            
            %Check for valid variable names
            idx = cellfun(@isvarname, prpNames);
            assert(all(idx), ['All properties defined in ''BulkProps'' must ', ...
                'be valid variable names. The following property names did ' , ...
                'not pass this assertion:\n\n\t%s\n'], strjoin(prpNames(~idx), ', '));            
            
            %Deal with masked properties
            propMask = p.Results.PropMask;               
            if ~isempty(propMask)
                assert(rem(numel(propMask), 2) == 0, ['Expected the ', ...
                    '''PropMask'' to be a cell array of name/value pairs.']);
                nam = propMask(1 : 2 : end);
                val = propMask(2 : 2 : end);
                idx = cellfun(@isvarname, nam);
                assert(all(idx), ['All properties defined in ''BulkProps'' must ', ...
                    'be valid variable names. The following property names did ' , ...
                    'not pass this assertion:\n\n\t%s\n'], strjoin(nam(idx), ', '));
                idx = ismember(nam, prpNames);
                assert(all(idx), ['All masked property names ', ...
                    'must match one (and only one) of the entries in ''BulkProps''. ', ...
                    'The following masked properties were not found in ''BulkProps'':', ...
                    '\n\n\t%s\n'], strjoin(nam(idx), ', '));                
                arrayfun(@(ii) validateattributes(val{ii}, {'numeric'}, ...
                    {'scalar', 'integer', 'positive'}, class(obj)), 1 : numel(val));
            end
            
            %Deal with list properties
            propList = p.Results.ListProp;
            if ~isempty(propList)
                idx = ismember(propList, prpNames);
                assert(all(idx), ['All properties referred to in '      , ...
                    '''PropList'' must match one (and only one) of the ', ...
                    'entries in ''BulkProps''. The following list '     , ...
                    'properties were not found in ''BulkProps'':\n\n\t%s\n'], ...
                    strjoin(propList(idx), ', '));
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
                %addDynamicProp(obj, dynProps);
                %addDynamicProp(obj, strcat(dynProps, 'Index'));
                
                Connections = struct('Prop', bulkProp, 'Type', bulkType, 'DynProp', dynProps);                
            end
            
            %Deal with attribute list
            attrList = p.Results.AttrList;
            if ~isempty(attrList)
                assert(rem(numel(attrList), 2) == 0, ['Expected the ', ...
                    '''AttrList'' to be a cell array of name/value pairs.']);
                nam = attrList(1 : 2 : end);
                val = attrList(2 : 2 : end);
                idx = cellfun(@isvarname, nam);
                assert(all(idx), ['All properties defined in ''AttrList'' must ', ...
                    'be valid variable names. The following property names did ' , ...
                    'not pass this assertion:\n\n\t%s\n'], strjoin(nam(idx), ', '));
                idx = ismember(nam, prpNames);
                assert(all(idx), ['All attribute property names ', ...
                    'must match one (and only one) of the entries in ''BulkProps''. ', ...
                    'The following attribute properties were not found in ''BulkProps'':', ...
                    '\n\n\t%s\n'], strjoin(nam(idx), ', '));
                assert(all(cellfun(@iscell, val)), ['Each entry in '      , ...
                    'the ''AttrList'' must be a cell-array of attribute ' , ...
                    'name/values. See ''help validateattributes'' for a ' , ...
                    'list of valid attributes.']);
            end
            
            %Deal with bespoke set methods
            setMethod = p.Results.SetMethod;
            if ~isempty(setMethod)
                assert(rem(numel(setMethod), 2) == 0, ['Expected the ', ...
                    '''AttrList'' to be a cell array of name/value pairs.']);
                nam = setMethod(1 : 2 : end);
                val = setMethod(2 : 2 : end);
                idx = cellfun(@isvarname, nam);
                assert(all(idx), ['All properties defined in ''SetMethod'' must ', ...
                    'be valid variable names. The following property names did ' , ...
                    'not pass this assertion:\n\n\t%s\n'], strjoin(nam(idx), ', '));
                idx = ismember(nam, prpNames);
                assert(all(idx), ['All set method property names ', ...
                    'must match one (and only one) of the entries in ''BulkProps''. ', ...
                    'The following set method properties were not found in ''BulkProps'':', ...
                    '\n\n\t%s\n'], strjoin(nam(idx), ', '));
                idx = cellfun(@(x) isa(x, 'function_handle'), val);
                assert(all(idx), ['All set methods should be function ', ...
                    'handles. The following set methods did not meet this ', ...
                    'criteria:\n\n\t%s\n'], strjoin(nam(idx)));
            end
            
            %Stash a record in the object
            BDS = struct( ...
                'BulkName'   , bulkName    , ...
                'BulkProps'  , {prpNames}  , ....
                'PropTypes'  , {prpTypes}  , ...
                'PropDefault', {prpDefault}, ...
                'PropMask'   , {propMask}  , ...
                'PropList'   , {propList}  , ...
                'Connections', Connections , ...
                'AttrList'   , {attrList}  , ...
                'SetMethod'  , {setMethod});            
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
            
            %Add dynamic properties. We do this at this point so that only
            %the properties for the desired 'BulkType' are generated.
            prpNames = BulkDataInfo.BulkProps;
            assert(all(cellfun(@isvarname, prpNames)), ['All ''BulkProps'' ', ...
                'must be a valid variable name. i.e. Must satisfy the ', ...
                'function @isvarname']);
            dProp = addDynamicProp(obj, prpNames);
            
            %Add the dynamic properties associated with 'Connections'
            if ~isempty(BulkDataInfo.Connections)
                dynProps = {BulkDataInfo.Connections.DynProp};
                addDynamicProp(obj, dynProps);
                addDynamicProp(obj, strcat(dynProps, 'Index'));
            end
            
            %Hack the set methods for the dynamic properties using
            %combination of 'PreSet' & 'PostSet' listeners and a custom set
            %method. This allows us to control the validation of the
            %dynamic properties and ensure the object remains valid.
            %
            % Also, add a get method for the first property as it is a
            % reference to the ID property of the superclass.
            if ~isempty(dProp)
                [dProp.SetObservable] = deal(true);
                [dProp.SetMethod]     = deal(@cbStashDynPropVal);
                dProp(1).GetMethod    = @cbGetBulkDataID;
                addlistener(obj, dProp, 'PreSet' , @cbStashDynPropName);
                addlistener(obj, dProp, 'PostSet', @cbValidateDynProp);
            end
            
            nb = obj.NumBulk;
            
            %Grab the prop types but strip blank ('b') entries so we can
            %index the other propery attributes
            prpTypes = obj.CurrentBulkDataTypes_;
            
            %Real or integer ('r' or 'i') are stored as vectors
            idxNum = ismember(prpTypes, {'r', 'i'});
            numVal = repmat({zeros(1, nb)}, [1, nnz(idxNum)]);
            %   - Repeat any masked properties
            for i = 1 :  numel(BulkDataInfo.PropMask) / 2
                idx = ismember(prpNames(idxNum), BulkDataInfo.PropMask((2 * i) - 1));
                numVal{idx} = repmat(numVal{idx}, [BulkDataInfo.PropMask{2 * i}, 1]);
            end
            if ~isempty(BulkDataInfo.PropList)
                idxList         = ismember(BulkDataInfo.BulkProps(idxNum), BulkDataInfo.PropList);
                numVal(idxList) = cellfun(@num2cell, numVal(idxList), 'Unif', false);
            end
            %   - List properties are preallocated as cells
            set(obj, BulkDataInfo.BulkProps(idxNum), numVal);
            
            %Char data ('c') are stored as cell-strings
            idxChar = ismember(prpTypes, {'c'});
            charVal = cellfun(@(x) repmat({x}, [1, nb]), BulkDataInfo.PropDefault(idxChar), 'Unif', false);
            set(obj, BulkDataInfo.BulkProps(idxChar), charVal);
            
        end
    end
    
    methods % assigning data during import
        function assignCardData(obj, propData, index, BulkMeta)
            %assignCardData Assigns the card data for the object by
            %converting the raw text input to numeric/char as necessary.
            %
            % Detailed Description:
            %   - This function is called in a loop during the method for
            %     importing bulk data from a text file (.bdf, .dat). The
            %     variable 'index' indicates which element of the object
            %     bulk data will be assigned during this function.
            %
            % FIXME - This is probably overly complex but I'm hoping it
            % will be a one size fits all solution...
            %
            % TODO - Move the definition of the card format outside the
            % function and pass in as an argument. (Remember this function
            % is called in a loop!!)
            
            %Get bulk data names, format & default values
            dataNames   = BulkMeta.Names;
            dataFormat  = BulkMeta.Format;
            dataDefault = BulkMeta.Default;
            lb = BulkMeta.Bounds(1, :);
            ub = BulkMeta.Bounds(2, :);
                        
            %Expand card to have full columns of data
            %   - avoids lots of if/elseif statements
            nProp    = numel(propData);
            propData = [propData(:) ; repmat({''}, [numel(dataFormat) - nProp, 1])];
            
            %Remove any blank elements
            idx = dataFormat == 'b';
            propData(idx)   = [];
            dataFormat(idx) = '';
            
            %Check for scientific notation without 'E'
            idx = and(contains(propData, '+'), ~contains(propData, 'E'));
            propData(idx) = strrep(propData(idx), '+', 'E+');
            
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

        end
        function assignListCardData(obj, propData, index, BulkMeta)
            %assignCardData
            
            %Index the list
            dataNames  = BulkMeta.Names;
            dataFormat = BulkMeta.Format;
            lb         = BulkMeta.Bounds(1, :);
            ub         = BulkMeta.Bounds(2, :);
            listNames  = BulkMeta.ListProp;
            ind        = find(contains(dataNames, listNames) == true);
            
            %Grab variable names
            b4List = dataNames(1 : ind(1) - 1);
            nb4    = numel(b4List);
            if numel(dataNames) > ind(end) %Is there any data after the list?
                afterList = dataNames(ind(end) + 1 : end);
                nAfter    = numel(afterList);
            else
                nAfter = 0;
            end            
                 
            %Pass this subset on to the normal data parsing method
            BulkMeta_ = struct( ...
                'Names'  , {dataNames(1 : nb4)} , ...
                'Format' , {dataFormat(1 : nb4)}, ...
                'Default', {BulkMeta.Default(1 : nb4)}, ...
                'Bounds' , [lb(1 : nb4) ; ub(1 : nb4)]);
            assignCardData(obj,  propData(1 : nb4), index, BulkMeta_);
            
%             %Convert to correct data types
%             idx       = or(dataFormat(1 : nb4) == 'i', dataFormat(1 : nb4) == 'r');
%             dat(idx)  = num2cell(str2double(dat(idx)));
%             dat(~idx) = cellfun(@(x) {x}, dat(~idx), 'Unif', false);
%             %set(obj, b4List, dat);
%             for ii = 1 : numel(b4List) %Assign to the object
%                 obj.(dataNames{ii})(:, index) = vertcat(dat{lb(ii) : ub(ii)});
%             end

            %Parse the list data
            strData = propData(nb4 + 1 : end - nAfter);
            endData = propData(end - nAfter + 1 : end);

            %Remove blanks (Needed for all TABLE bulk data entries)
            strData = strData(~cellfun(@isempty, strData));

            if isempty(strData) %Escape route
                return
            end

            %Parse the list data
            propData = i_parseListData(strData, obj.CardName);

            function propData = i_parseListData(strData, nam)
                %i_parseListData Converts all the data in 'strData' into
                %type double. If the keywork 'THRU' is found then it is
                %replaced by the intermediate numbers.
                %
                % TODO - Update this so it can handle lists of strings.
                
                %Strip 'ENDT' from the list if it is present
                strData(contains(strData, 'ENDT')) = [];
                
                %Convert to numeric data & check for NaN (e.g. char data)
                propData = str2double(strData)';
                idx_     = isnan(propData);
                                
                %Populate intermediate ID numbers
                if any(idx_)
                    
                    propData = num2cell(propData);
                    
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
                    propData = [propData{:}];
                end
                
            end
            
            %Split into sets of 'numel(listVar)'
            nListVar = numel(listNames);  
            if nListVar > 1
                propData = arrayfun(@(ii) propData(ii : nListVar : end), 1 : nListVar, 'Unif', false);
            else
                propData = num2cell(propData, 2);
            end
            
            %Assign to object
            for ii = 1 : numel(listNames)
               obj.(listNames{ii}){index} = propData{ii}; 
            end
                        
        end    
        function BulkMeta = getBulkMeta(obj)
            %getBulkMeta Returns the meta information for this bulk data
            %entry based on the current card name.
            
            CBDS = obj.CurrentBulkDataStruct;
            
            %Get bulk data names, format & default values
            names   = CBDS.BulkProps;
            format  = CBDS.PropTypes;
            default = CBDS.PropDefault;
            
            %Check for masked props and update card format
            mask = CBDS.PropMask;
            indices = ones(1, numel(names));
            if ~isempty(mask)
                format  = i_repeatMaskedValues(format , names, mask);
                default = i_repeatMaskedValues(default, names, mask);
                %Update indices
                indices(ismember(names, mask(1 : 2 : end))) = horzcat(mask{2 : 2 : end});
            end
            ub = cumsum(indices);
            lb = ub - indices + 1;
            
            format = horzcat(format{:});
            
            BulkMeta = struct('Names', {names}, 'Format', format, ...
                'Default', {default}, 'Bounds', [lb ; ub], ...
                'ListProp', {CBDS.PropList}); 
            
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
    end
        
    methods (Sealed) % validation
        function validateID(obj, val, prpName, varargin)    %validateID
            if isempty(val)
                return
            end
            if iscell(val)
                cellfun(@(x) validateID(obj, x, prpName), val)
                return
            end
            validateattributes(val, {'numeric'}, {'integer', '2d', ...
                'real', 'nonnan', 'nonnegative'}, class(obj), prpName);
        end
        function validateDOF(obj, val, prpName, varargin)   %validateDOF
            %validateDOF Checks that 'val' is a valid Degree-of-Freedom
            %(DOF) entry.
            %
            % In MSC.Nastran a DOF is defined as any non-repeating
            % combination of the numbers [1,2,3,4,5,6].
            
            assert(iscell(val), ['Expected ''%s'' to be a cell-array ', ...
                'of DOF identifiers, e.g. ''123456''.'], prpName);
            idx = cellfun(@isempty, val);
            if all(idx) %If it is empty then nothing to check
                return
            end
            
            %Only retain the non-empty data
            val = val(~idx);
            
            idxChar      = cellfun(@ischar, val);
            val(idxChar) = cellfun(@str2double, val(idxChar), 'Unif', false);
            valNum       = horzcat(val{:});
            valString    = cellfun(@num2str, val, 'Unif', false);
                  
            %NaN will only be present if bad char data has been provided
            if any(isnan(valNum))
                throwME_SPC;
            end
            
            %First level of validation to check correct type and attributes
            validateattributes(valNum(~isnan(valNum)), {'numeric'}, {'row', 'integer', ...
                'nonnan', 'finite', 'real'}, class(obj), prpName);
            
            %Second level of validation to check that 'val' is a valid SPC
            
            %Have more than 6 characters been provided?
            if any(cellfun(@numel, valString) > 6)
                throwME_SPC;
            end
            
            %Has a negative number been provided?
            %if any(contains(cellstr(valString')', '-'))
            if any(cellfun(@(x) ~isempty(x), strfind(cellstr(valString')', '-')))
                throwME_SPC;
            end
                        
            %Are there any numbers outside the range [1 : 6]?
            if any(contains(valString, {'0', '7', '8', '9'}))
                throwME_SPC;
            end
            
            %TODO - Have any numbers been repeated twice?
            
            function throwME_SPC
                %throwME_SPC Throws an MException object containing the
                %error message for a badly formatted SPC entry.
                
                %Generate ME object.
                ME = MException('matlab:Matran:BadSPC', ['Value ', ...
                    'does not define a valid Single Point Constraint (SPC).\n\n', ...
                    'A SPC must be defined using the integers 1 '       , ...
                    'through to 6 and can only have a maximum of 6 '     , ...
                    'numbers. Negative numbers are not allowed.\n\n\t'   , ...
                    'For example, ''123456'' is a valid SPC but '        , ...
                    '''10984'' is not.\n\nFor further information see ' , ...
                    'the MSC.Nastran Quick Reference Guide.']);
                
                %Throw the ME to the user.
                throwAsCaller(ME);
            end
            
        end
        function validateReal(obj, val, prpName, extraargs) %validateReal
            %validateReal Checks that 'val' is a matrix of real numbers
            
            if nargin < 4
                extraargs = [];
            end
            if iscell(val)
                cellfun(@(x) validateReal(obj, x, prpName, extraargs), val)
                return
            end
            validateattributes(val, {'numeric'}, [{'2d', 'real', ...
                'finite', 'nonnan'}, extraargs], class(obj), prpName);
        end
        function validateLabel(obj, val, prpName, varargin) %validateLabel
            %validateLabel Checks that the value of the label with property
            %name 'prpName' matches the expected format.
            %
            % Each label must be a character row vector of less than 8
            % characters.
            assert(iscellstr(val), ['The property ''%s'' must be a ', ...
                'cell-array of strings'], prpName); %#ok<*ISCLSTR>
            assert(all(cellfun(@numel, val) < 9), ['Each element of the ', ...
                'property ''%s'' must be 8 characters or less.'], prpName);
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

%Dynamic property callbacks
function cbStashDynPropName(src, evt)
%cbStashDynPropName PreSet callback for dynamic properties related to the
%current bulk data set.
%
% Stashes a copy of the dynamic property name that is currently being
% activated by the 'PreSet' property listener.

%Make sure we keep a record of the current dynamic property being set
evt.AffectedObject.DynPropBeingSet = src.Name;

end
function cbStashDynPropVal(obj, val)
%cbStashDynPropVal Set method for the dynamic properties related to the
%current bulk data set.
%
% Stashes a copy of the dynamic property value whilst it is being set.
% This allows us to capture the value and restore it later if it fails the
% validation case.

%Which property?
nam = obj.DynPropBeingSet;

%Stash the old value, but only if the object is not dirty!
if ~obj.DynPropDirty
    obj.PreSetVal.(nam) = obj.(nam);
end

%Allow the new value to pass, will be checked by 'PostSet' listener
%
% If it is the first property in the bulk data entry then it is a mask for
% the 'ID' property.
if strcmp(nam, obj.CurrentBulkDataProps{1})
    obj.ID = val;
else
    obj.(nam) = val;
end

end
function cbValidateDynProp(src, evt)
%cbValidateDynProp PostSet listener for dynamic properties related to the
%current bulk data set.
%
% Executes the validation function for the dynamic property value and
% captures any errors. If the property fails the validation case then the
% pre-set value is restored.

map = { ...
    'i', @validateID   ; ...
    'r', @validateReal ; ...
    'c', @validateLabel};
    
BulkObj = evt.AffectedObject;
prpName = src.Name;
val     = BulkObj.(prpName);

%Which validation method to use?
idx = ismember(BulkObj.CurrentBulkDataProps, prpName);
tok = BulkObj.CurrentBulkDataTypes_{idx};
func = map{ismember(map(:, 1), tok), 2};

%Additional attributes?
attr = BulkObj.CurrentBulkDataStruct.AttrList;
idx  = ismember(attr(1 : 2 : end), prpName);
if any(idx)
    extra_attr = attr{find(idx) * 2};
else
    extra_attr = {};
end

%Check if this property has a bespoke method?
setMethod = BulkObj.CurrentBulkDataStruct.SetMethod;
idx = ismember(setMethod(1 : 2 : end), prpName);
if any(idx)
    func = setMethod{find(idx) * 2};
end

%Run it
try
    func(BulkObj, val, prpName, extra_attr);
catch ME
    %If it fails then restore the previous value...
    %...BUT we need to mark the 
    BulkObj.DynPropDirty = true;
    BulkObj.(prpName) = BulkObj.PreSetVal.(prpName);
    BulkObj.DynPropDirty = false;
    throwAsCaller(ME);
end

end
function val = cbGetBulkDataID(obj)
%cbGetBulkDataID Retrieves the value from the underlying ID property.
val = obj.ID;
end