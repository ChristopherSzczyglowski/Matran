classdef FEBaseClass < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %FEBaseClass Base-class of all Finite Element (FE) objects in the
    %package 'awi.fe'.
    
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
    
    %Tracking the object's finite element data
    properties (SetAccess = protected, Hidden)
        %Container for tracking the names of the properties related to the
        %'awi.mixin.FEable' implementation.
        PropNames = {};
        %Name of the MSC.Nastran bulk data card that is the equivalent of
        %the 'awi.fe' object.
        CardName  = '';
    end    
    properties (Dependent)
        %Logical flag for telling the user if the object has any data
        HasFEData
    end
    
    methods % set / get
        function set.DrawMode(obj, val)         %set.DrawMode
           %set.DrawMode Set method for the property 'DrawMode'.           
           validatestring(val, {'undeformed', 'deformed'}, class(obj), 'DrawMode');
           obj.DrawMode = lower(val);           
        end        
        function set.ID0(obj, val)        %set.ID0
            %set.ID0 Set method for the property 'ID0'.
            validateID(obj, val, 'ID0');
            obj.ID0 = val;
        end
        function set.ID(obj, val)         %set.ID
            %set.ID Set method for the property 'ID'.
            validateID(obj, val, 'ID');
            obj.ID = val;
        end
        function val = get.HasFEData(obj) %get.HasFEData
            
            %Pass it on ...
            val = checkContents(obj);
            
        end
    end
    
    methods (Sealed) % handling FE data
        function addFEProp(obj, varargin)
            %addFEProp Makes a record of the property names related to the
            %'awi.mixin.FEable' implementation.
            
            %Make sure that varargin is a cell array of strings
            assert(iscellstr(varargin), ['Expected the finite ', ...
                'element property names to be characters']); %#ok<ISCLSTR>
            
            %TODO - Check that they are valid properties
            
            %Make a note of it
            obj.PropNames = [obj.PropNames, varargin];
        end
        function newObj = consolidateFEData(obj, varargin)
            %consolidateFEData Combines the data in each property specified
            %by 'PropNames' in the objects 'obj' and 'varargin'.
            
            %Verify all additional inputs are the correct class
            cls = class(obj);
            idx = cellfun(@(x) ~isa(x, cls), varargin);
            if any(idx)
                error('Cannot consolidate FE entities that are of different types');
            end
            items = horzcat(varargin{:});
            
            %Remove any FE objects which have no FE data
            if ~isempty(items)
                idx_hasData = [items.HasFEData];
                items       = items(idx_hasData);
            end
            
            if isempty(items) %Account for the case with no matching class
                newObj = obj;
                return
            end
            
            %Create a new object which will contain the consolidated data
            f      = str2func(class(obj));
            newObj = f();
            
            %Loop through each FE property and combine the data
            for i = 1 : numel(obj.PropNames)
                prp = obj.PropNames{i};
                newObj.(prp) = [obj.(prp), [items.(prp)]];
            end
            
        end
    end
    
    methods % checkContents
        function tf = checkContents(obj, tok)
            %checkContents Checks if the properties defined by 'obj.PropNames'
            %return true when queried by 'HasFEData'.
            
            if nargin < 2
                tok = obj.PropNames;
            end
            
            %For an array, do each in turn. Return scalar value
            if numel(obj) > 1
                tf = arrayfun(@(o) ~checkContents(o, tok), obj);
                tf = ~any(tf);
                return
            end
            
            %Get status of each property
            idx = cellfun(@(x) isempty(x), get(obj, tok));
            
            %If every property is empty then the object is classed as empty
            if nnz(idx) == numel(idx)
                tf = false;
            else
                tf = true;
            end
        end
    end
    
    methods (Sealed) % validation
        function validateID(obj, val, prpName)       %validateID
            if isempty(val)
                return
            end
            validateattributes(val, {'numeric'}, {'integer', 'row', ...
                'real', 'nonnan', 'nonnegative'}, class(obj), prpName);
        end
        function validateDOF(obj, val, prpName)      %validateDOF
            %validateDOF Checks that 'val' is a valid Degree-of-Freedom
            %(DOF) entry.
            %
            % In MSC.Nastran a DOF is defined as any non-repeating
            % combination of the numbers [1,2,3,4,5,6].
            
            if isempty(val) %If it is empty then nothing to check
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
    
    methods % exporting/writing the FE model to a file
        function writeToFile(~, ~, ~)
            %writeToFile Base function for writing FE data to a file. Must
            %be overridden at the subclass level.
            
            %             error(['The method ''writeToFile'' is expected to be '  , ...
            %                 'overridden at the subclass level. Check the class ', ...
            %                 'definitions for the ''%s'' class and ensure that ' , ...
            %                 'this method is over-ridden.'], class(obj));
        end        
    end
    
    methods (Static) % helper functions for writing MSC.Nastran bulk data
        function fName = getBulkDataFile(fileSpec, title)
            %getBulkDataFile Returns the path to a text file for writing
            %the bulk data into.
            
            if nargin < 1
                fileSpec = {'*.bdf;*.dat;*.txt' ; ...
                'MSC.Nastran bulk data files (*.bdf,*.dat,*.txt)'};
            end
            if nargin < 2
                title = 'Select a text file to write the bulk data into';
            end
            
            %Ask the user
            [nam, dn] = uigetfile(fileSpec, title);
            
            %Anything?
            if isnumeric(nam) || isnumeric(dn)
                fName = [];
            else
                fName = fullfile(dn, nam);
            end
            
        end
        function fmt = getFormatSpec(data, colWidth, nCol)
            
            rtFmt = ['%-', num2str(colWidth), '.', num2str(colWidth-6), 'e'];
            rsFmt = ['%-', num2str(colWidth), '.', num2str(colWidth-3), 'f'];
            rnFmt = ['%#-', num2str(colWidth),'.', num2str(colWidth-5), 'g'];
            
            fmt = cell(size(data));
            
            rsInd = abs(data) < 1;
            rnInd = ~rsInd;
            
            fmt(rsInd) = {rsFmt};
            fmt(rnInd) = {rnFmt};
            
            nLines = ceil(numel(data) / nCol);
            
            if nLines == 1
                fmt = [cat(2, fmt{:}), '\r\n'];
            else
                fmt = reshape(fmt, nCol, nLines)';
                EoL = repmat({'\r\n'}, size(fmt, 1), 1); %end of line
                fmt = [fmt, EoL];
                fmt = cat(2, fmt{:});
            end
            
        end             
        function writeComment(str, fid)
            %writeComment Write a comment with data 'str' into the file
            %with identifier 'fid'. The comment will be split over multiple
            %lines so that it conforms to the 80 character width of
            %MSC.Nastran bulk data files.
            
        end
        function writeColumnDelimiter(fid, fieldType)
            %writeColumnDelimiter Writes a string into the file with
            %identifier 'fid' which shows the column width based on the
            %value of 'fieldType'.
            
            if nargin < 2 %Default to large-field format
                fieldType = 'large';
            end
            
            validatestring(fieldType, {'large', 'normal', '8', '16'});
            
            switch fieldType
                case {'large', '16'}
                    fprintf(fid, '$.1.....2...............3...............4...............5...............6.......\r\n');
                case {'normal', '8'}
                    fprintf(fid, '$.1.....2.......3.......4.......5.......6.......7.......8.......9.......10......\r\n');
            end
            
        end
        function writeHeading(fid, text)
            %writeHeading Writes the 'text' in FEMAP heading style.
            
            fprintf(fid, '$\n');
            fprintf(fid, '$ %s\n', text);
            fprintf(fid, ['$ ' repmat('*', [1, 78]) '\n']);
            
        end
        function writeSubHeading(fid, text)
            %writeSubHeading : Writes the 'text' in the FEMAP subheading
            %style            
            
            fprintf(fid, ['$ ' repmat('-', [1, 78]) '\n']);
            fprintf(fid, sprintf('$ %s\n', text));
            fprintf(fid, ['$ ' repmat('-', [1, 78]) '\n']);
            
        end
        function writeListDataCard(fid, cardName, Card, listVar, dataType, varargin)
            %writeListDataCard Writes the data from a `list-formatted' bulk
            %data entry into the file with identifier 'fid'.
                        
            % .bdf format data
            if isempty(varargin)
                colWidth = 8;
            else
                colWidth = varargin{1};
            end
            nCol = (64 ./ colWidth);    % <-- number of columns available for printing data on each line
                        
            % assume the data is all numeric and are just integers
            if nargin < 5
                dataType = 'i';
            end
            
            %% grab all list data
            colNames = Card.PropNames;
            cardData = get(Card, colNames);
            listData = cardData(ismember(colNames, listVar));
            
            %Check the amount of data is consistent
            nListData = cellfun(@(x) numel(x), listData);
            if range(nListData) ~= 0
                error('The amount of data in each list data must be consistent.');
            end
            if isempty(nListData)
                nListData = 0;
            else
                nListData = nListData(1);
            end
            
            %% format the list data
            
            % how many list variables are there?
            nListVar = numel(listVar);
            
            % Number of complete sets that can be printed per line
            nSetPerLine = floor(nCol / nListVar);
            
            % location of list variable in data names
            [~, loc] = ismember(listVar{1}, colNames);
            
            % number of data columns to be written before list variable
            nColBeforeList = loc - 1;
            
            % number of columns remaining on the first line for list data
            nColRem = nCol - nColBeforeList;
            
            %number of complete sets we can print on the first line
            nSetRem = floor(nColRem ./ nListVar);
            
            % grab the data on the first line
            if (nListData * nListVar) <= nColRem
                line1Data  = cellfun(@(x) x, listData, 'Unif', false);
                extraData  = cell(nListVar, 1);
                nExtraData = 0;
            else
                line1Data = cellfun(@(x) x(1 : nSetRem), listData, 'Unif', false);
                extraData = cellfun(@(x) x(nSetRem + 1 : end), listData, 'Unif', false);
                nExtraData = nListData - nSetRem;
            end
            
            % additional data to be printed
            % nExtraLine = ceil(nExtraData / nSetPerLine); % number of extra lines required
            nEntryEnd = mod(nExtraData, nSetPerLine);    % number of entries on the final line
            
            %Grab the non-list data, intermediate data and the data for the final line
            nonListData = cardData(1 : nColBeforeList)';
            idx         = cellfun(@ischar, nonListData);
            nonListData(idx) = cellfun(@str2double, nonListData(idx), 'Unif', false);
            nonListData = cell2mat(nonListData);  % --> assume all data is numeric
            intData     = cellfun(@(x) x(1 : end-nEntryEnd), extraData, 'Unif', false);
            endData     = cellfun(@(x) x(nExtraData - nEntryEnd + 1 : end), extraData, 'Unif', false);
            
            %% write data to the file
            switch dataType
                case 'i'
                    strFormat = ['%-', num2str(colWidth), 'i'];
                    line1Format = strFormat;
                case 'r'
                    if colWidth == 16
                        strFormat   = ['%#-', num2str(colWidth),'.', num2str(colWidth-5), 'g'];
                        line1Format = ['%#-', num2str(colWidth),'.', num2str(colWidth-5), 'g'];
                    else
                        strFormat   = '%#-8.3f';
                        line1Format = '%-8.5f';
                    end
            end
            
            if colWidth == 16
                cardName = [cardName, '*'];
            end
            
            % write first line
            dat = cat(1, line1Data{:});
            % fmmt = getFormatSpec(dat, colWidth, nCol);
            fprintf(fid, '%-8s%s%s\r\n', cardName, ...
                sprintf(['%-', num2str(colWidth), 'i'], nonListData), ...  %<-- Assume that the non-list data is integer valued
                sprintf(line1Format, dat(:)));
            
            % write intermediate data
            dat = cat(1, intData{:});
            % fmmt = getFormatSpec(dat, colWidth, nCol);
            if colWidth == 16
                fmt = ['*', blanks(7), repmat(strFormat, [1, nListVar * nSetPerLine]), '\r\n'];
            else
                fmt = [blanks(8), repmat(strFormat, [1, nListVar * nSetPerLine]), '\r\n'];
            end
            if ~isempty(dat)
                fprintf(fid, fmt, dat(:));
            end
            
            % write data for the final line
            dat = cat(1, endData{:});
            % fmmt = getFormatSpec(dat, colWidth, nCol);
            if colWidth == 16
                fmt = ['*', blanks(7), repmat(strFormat, [1, nListVar * nSetPerLine]), '\r\n'];
            else
                fmt = [blanks(8), repmat(strFormat, [1, nEntryEnd * nListVar]), '\r\n'];
            end
            if ~isempty(dat)
                fprintf(fid, fmt, dat(:));
                fprintf(fid, '\r\n');
            end
        end      
        function writeSuperpositionList(fid, cardName, id, s0, si, listID)
            %writeSuperpositionList Writes the data for a superposition
            %list bulk data type (e.g. MASSSET, LOAD, etc.).
            
            if numel(si) ~= numel(listID) %Escape route
                return
            end
            
            %Set up data for vectorised writing
            blnks = {blanks(8)};
            nData = numel(listID);
            if nData > 2
                line1 = listID(1 : 3);
                Si1   = si(1 : 3);
            else
                line1 = listID(1 : end);
                Si1   = si(1 : end);
            end
            rem    = nData - 3;
            nLines = ceil(rem / 4);
            if nLines > 1
                ub       = 3 + (nLines - 1) * 4;
                lineData = listID(4 : ub);
                SiData   = si(4 : ub);
                lineEnd  = listID(ub + 1 : end);
                SiEnd    = si(ub + 1 : end);
                ub    = cumsum(repmat(8, [1, nLines - 1]));
                lb    = [1, ub(1 : end - 1) + 1];
            else
                lineData = [];
                SiData   = [];
                lineEnd  = listID(4 : end);
                SiEnd    = si(4 : end);
                ub = numel(lineData) * 2;
                lb = 1;
            end
            
            %First line
            data  = [id ; s0];
            data1 = [Si1 ; line1];
            data  = [{cardName} ; num2cell(data) ; num2cell(data1(:))];
            
            %Intermediate lines - pad with blanks
            dataN = [SiData ; lineData];
            dataN = dataN(:);
            dataN = arrayfun(@(i) num2cell(dataN(lb(i) : ub(i))), 1 : nLines - 1, 'Unif', false);
            dataN = [dataN ; repmat(blnks, [1, nLines - 1])];
            dataN = vertcat(dataN{:});
            
            %Final line
            dataEnd = [SiEnd ; lineEnd];
            dataEnd = num2cell(dataEnd(:));
            
            %Format for printing
            data = [data ; blnks ; dataN ; dataEnd ];
            fmt  = [ ...
                '%-8s%-8i%#-8.4g', ...
                repmat('%#-8.4g%-8i', [1, numel(line1)]), '\r\n', ...
                repmat('%-8s%#-8.4g%-8i%#-8.4g%-8i%#-8.4g%-8i%#-8.4g%-8i\r\n', [1, nLines - 1]), ...
                '%-8s', repmat('%#-8.4g%-8i', [1, numel(lineEnd)]), '\r\n'];
            
            %Print it
            fprintf(fid, fmt, data{:});
            
        end
        function writeNastranHeaderFile(fName, varargin)
            %writeNastranHeaderFile Writes the header file for a
            %MSC.Nastran analysis.
            %
            % Parameter inputs:
            %
            %   * 'IncludeFiles' : A cell array of filenames which denote
            %   the bulk data files that are to be included in the header
            %   using 'INCLUDE' statements.
            %
            %   * 'Solution' : The solution number of the MSC.Nastran
            %   solution sequence that will be entered into the Executive
            %   Control statement.
            %
            %   * 'NModes' : Number of modes retained in the normal modes
            %   solution.
            %
            %   * 'MaxFreq' : Cutoff frequency for normal modes
 
            
            %Check if the user has provided a single include file as a
            %character vector instead of a cellstr
            index = find(ismember(varargin(1 : 2 : end), 'IncludeFiles'));
            if ~isempty(index) && ~iscell(varargin{2 * index})
                varargin{2 * index} = {varargin{2 * index}};                
            end
            
            %Parse inputs
            if nargin < 1
                fName = getBulkDataFile( ...
                    {'*.dat' ; 'MSC.Nastran header files'}, ...
                    'Select a header file');
                if isempty(fName) %Anything?
                    return
                end
            end
            idx = contains(varargin(1 : 2 : end), 'MaxFreq');
            if any(idx) && isempty(varargin{find(idx) * 2})
                attr = {};
            else
                attr = {'scalar', 'positive'};
            end
            p = inputParser;
            addParameter(p, 'IncludeFiles', [], @iscellstr);
            addParameter(p, 'Solution'    , [], @(x)validateSolNumber(x));
            addParameter(p, 'NModes'      , 20, @(x)validateattributes(x, {'numeric'}, {'integer', 'scalar'} , 'writeNastranHeaderFile', 'NModes'));
            addParameter(p, 'MaxFreq'     , [], @(x)validateattributes(x, {'numeric'}, attr, 'writeNastranHeaderFile', 'MaxFreq'));
            parse(p, varargin{:});            
            function validateSolNumber(sol)
                %validateSolNumber Checks that the value of 'sol' matches
                %one of the allowable values.
                
                validSol    = [101 ; 103];
                validSolStr = strjoin(cellstr(num2str(validSol)));
                
                if ischar(sol)
                    sol = str2double(sol);
                end
                
                assert(numel(sol) == 1, 'Expected there to be only one solution number');
                
                assert(any(ismember(sol, validSol)), sprintf(['Expected ', ...
                    'the solution number to match one of the following ' , ...
                    'values:\n\n\t%s\n'], validSolStr));
                
            end
            
            %Write the header file...
            fid = fopen(fName, 'w');
            
            %Executive Control
            awi.fe.FEBaseClass.writeHeading(fid, 'E X E C U T I V E  C O N T R O L');
            fprintf(fid, 'SOL %i\r\n', p.Results.Solution);
            fprintf(fid, 'ECHOOFF         $ SUPPRESSES THE ECHO OF EXECUTIVE CONTROL\r\n');
            fprintf(fid, 'CEND\r\n');
            
            %Case Control
            awi.fe.FEBaseClass.writeHeading(fid, 'C A S E  C O N T R O L');     
            awi.fe.FEBaseClass.writeSubHeading(fid, 'O U T P U T  O P T I O N S');
            fprintf(fid, 'LINE = 99999999   $ SPECIFIES THE NUMBER OF LINES PER PRINTED PAGE\r\n');
            fprintf(fid, 'ECHO = NONE       $ SUPPRESSES THE ECHO OF BULK DATA\r\n');
            awi.fe.FEBaseClass.writeSubHeading(fid, 'O U T P U T  Q U A N T I T I E S');
            switch p.Results.Solution
                
                case 101
                    
                case 103
                    %Request displacements, summary and energy as standard
                    fprintf(fid, 'DISP(PRINT)             = ALL $ OUTPUT ALL DISPLACEMENTS\r\n');
                    fprintf(fid, 'MEFFMASS(PRINT,SUMMARY) = YES $ OUTPUT MODAL EFFECTIVE MASS\r\n');
                    fprintf(fid, 'ESE(PLOT)               = ALL $ OUTPUT ELEMENT STRAIN ENERGY\r\n');
                    fprintf(fid, 'GPKE(NOPRINT)           = ALL $ OUTPUT GRID POINT KINETIC ENERGY\r\n');
                    awi.fe.FEBaseClass.writeSubHeading(fid, 'S U B C A S E S')
                    fMax = p.Results.MaxFreq;
                    NMode = p.Results.NModes;
                    if isempty(fMax)
                        EigenCard = struct('SID', 117, 'V1', 0, 'V2', []  , 'ND',NMode);
                    else
                        EigenCard = struct('SID', 117, 'V1', 0, 'V2', fMax, 'ND', NMode);
                    end
                    fprintf(fid, 'METHOD = %i\r\n', EigenCard.SID);                    
                    
                otherwise
                    
            end
            
            %Bulk Data
            awi.fe.FEBaseClass.writeHeading(fid, 'B E G I N  B U L K');
            fprintf(fid, 'BEGIN BULK\r\n');
            %Request HDF5 & OP2 output as standard
            fprintf(fid, 'MDLPRM,HDF5,1\r\nPARAM,POST,1\r\n');
            %Request Grid Point Weight Generator (GPWG)
            fprintf(fid, 'PARAM,GRDPNT,0\r\n');
            %Anticipate mechanisms because of the presence of joints
            fprintf(fid, 'PARAM,BAILOUT,-1\r\n');
            switch p.Results.Solution
                
                case 101 %Static
                    
                case 103 %Normal modes
                    if isempty(fMax)
                        fprintf(fid, '%-8s%-8i%#-8.3g%-8s%-8i\r\n', ...
                            'EIGRL', EigenCard.SID, EigenCard.V1, blanks(8), ...
                            EigenCard.ND);                       
                    else
                         fprintf(fid, '%-8s%-8i%#-8.3g%#-8.3g\r\n', ...
                            'EIGRL', EigenCard.SID, EigenCard.V1, EigenCard.V2);
                    end
                    
                otherwise
                    
            end
            
            %Additional bulk data files
            if ~isempty(p.Results.IncludeFiles)
                awi.fe.FEBaseClass.writeSubHeading(fid, 'I N C L U D E  F I L E S');
                awi.fe.FEBaseClass.writeIncludeStatement(fid, p.Results.IncludeFiles);
            end
            
            %End of file
            fprintf(fid, 'ENDDATA\r\n');
            
            %Close the file
            fclose(fid);
            
        end
        function writeIncludeStatement(fid, filenames, varargin)
            %writeIncludeStatement: Writes the MSC. Nastran command to include the .bdf
            %files specified in 'filenames' into the .dat file given by 'fid'
            %
            % Inputs :
            %   - Required :
            %       + 'fid'       : File identified for the MSC. Nastran input file
            %                       (should be a .dat file)
            %       + 'filenames' : Cell array containing the names of the files to be
            %                       included
            %   - Optional :
            %       + 'ext' : File extension to be added to each filename
            %
            
            validExt = {'.bdf', '.dat', '.txt', '.inc', '.pch'};
            
            p = inputParser;
            addRequired(p , 'fid'      , @(x)isa(x, 'double'));
            addRequired(p , 'filenames', @iscellstr);
            addOptional(p , 'ext'      , [], @(x)any(validatestring(ext, validExt)));
            addParameter(p, 'FullyQualifiedPath', true, @(x)validateattributes(x, {'logical'}, {'scalar'}));
            parse(p, fid, filenames, varargin{:});
            
            files  = p.Results.filenames;
            nFiles = numel(files);
            
            if ~p.Results.FullyQualifiedPath %Strip the directory?
                fp = cell(nFiles, 3);
                for ii = 1 : nFiles
                    [fp{ii, 1}, fp{ii, 2}, fp{ii, 3}] = fileparts(files{ii});
                end
                files = strcat(fp(:, 2), fp(:, 3));
            end
            
            %Stip empties
            files(cellfun(@isempty, files)) = [];
            
            for iF = 1 : numel(files)
                file = files{iF};
                % check file extension
                % check if file has an extension
                if ~isempty(strfind(file, '.'))
                    % file has an extension! Is it the correct format?
                    temp = strsplit(file, '.');
                    validatestring(['.', temp{end}], validExt);
                    clear temp
                elseif ~isempty(strfind(file, '.')) && isempty(p.Results.ext)
                    % no extension in the filename and no extension provided
                    % ---> throw error
                    error(['Please provide a file extension for the files by ', ...
                        'either including it directly in the filename or '    , ...
                        'using the "ext"  optional input to %s'], mfilename);
                else
                    % no extension in the filename but extension provided
                    % --> use the provided file extension (input already checked)
                    file = [file, p.Results.ext];
                end
                % format the file path so it fits in the 72 character width for the
                % MSC.Nastran bulk data input file
                formattedFile = i_formatFilePath(file);
                % print the INCLUDE statement
                fprintf(p.Results.fid, '%-s\n', formattedFile{:});
            end
            
            function newPath = i_formatFilePath(filePath)
                %i_formatFilePath Returns the file path in a form that is
                %suitable for printing with the MSC.Nastran INCLUDE
                %statement
                %
                % Inputs :
                %   - 'filePath' : File path to be formatted
                % Outputs :
                %   - 'newPath' : Formatted file path
                %
                % Detailed Explanation :
                %   - The format of the INCLUDE statement is:
                %     <--------72 char-------> 
                %     INCLUDE 'longFilePath'
                %   - The format for the INCLUDE statement when the
                %     filepath is greater than 63 characters is:
                %     <--------72 char-------> 
                %     INCLUDE 'dir1\dir2\dir3
                %              \dir4\dir5\...'
                %   - The length of each line of the INCLUDE statment
                %     cannot exceed 72 characters. If the length of the
                %     file path is greater than 63 characters then it  must
                %     be split over multiple lines.
                %   - Where possible the file path will be split using the
                %    '\' delimiter toseperate multiple lines.
                
                %Maximum number of characters after "INCLUDE" command
                maxLineLength = 62; 
                
                pathLength = length(filePath);
                % check if filepath needs formatting
                %   - if the '\' character is not present the file is in the local
                %     directory and does not require any formatting
                %   - if the length of the file path is less than < 63 characters
                if ~ismember('\', filePath) || pathLength < 63
                    newPath = {sprintf('INCLUDE ''%s''', filePath)};
                    return
                end
                
                % how many continuation lines are required?
                nLines = ceil(pathLength ./ maxLineLength) + 1;
                
                % get subfolder strings
                subFolders = strsplit(filePath, '\');
                
                % define anonymous function for calculating length of each subfolder string
                getFL = @(x)(cellfun(@(y)length(y), x) + [0, ones(1, length(x) - 1)]);
                
                % check lengths to see if a single folder will fit the line
                if any(getFL(subFolders) > maxLineLength)
                    %Apply messy formatting
                    %   - Just cut filepath at end of line
                    nCharFinalLine = mod(pathLength, maxLineLength);
                    interData   = filePath(1 : pathLength - nCharFinalLine);
                    nInterLines = numel(interData)/maxLineLength;
                    newPath     = cellstr(reshape(interData, [maxLineLength, nInterLines])');
                    newPath{end+1} = filePath(pathLength - nCharFinalLine + 1 : end);
                    %Set flag
                    format = 'messy';
                else
                    %Use neat formatting
                    %   - Cut each line at a filepath delimiter.
                    
                    % preallocate
                    ind     = zeros(1, nLines);
                    newPath = cell(1, nLines);
                    
                    % loop through each continuation and assemble part of the file path
                    for iL = 1 : nLines
                        % if no folders remain then exit the loop
                        if isempty(subFolders)
                            % remove any empty cells
                            newPath(cellfun('isempty', newPath)) = [];
                            break
                        end
                        % find length of remaining folders
                        folderLength = getFL(subFolders);
                        % find the most amount of data that can be put on each line
                        temp = cumsum(folderLength);
                        % how many folders should be included on this line?
                        ind(iL) = find(temp < maxLineLength, 1, 'last');
                        % assign data to the line
                        newPath{iL} = strjoin(subFolders(1 : ind(iL)), '\');
                        % assign remaining sub folders to 'subFolders'
                        subFolders = subFolders(ind(iL) + 1 : end);
                    end
                    %Set flag
                    format = 'neat';
                end
                
                % append the "INCLUDE '" string to the first line
                newPath{1} = ['INCLUDE ''', newPath{1}];
                
                %Define pad vector for each line
                switch format
                    case 'messy'
                        padVec = {blanks(9)};
                    case 'neat'
                        padVec = {[blanks(9), '\']};
                end
                
                % pad lines 2 : end with 8 blanks to account for "INCLUDE '" on line 1
                newPath(2 : end) = strcat(padVec, newPath(2 : end));
                
                % add a terminating "'" to the final line
                newPath{end} = [newPath{end}, ''''];
                
            end
            
        end           
    end
    
    methods (Access = protected) %helper functions for visualisation
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

