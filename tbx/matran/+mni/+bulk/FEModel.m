classdef FEModel < mni.mixin.Collector
    %FEModel Describes a collection of bulk data objects to which results
    %sets can be attached to.
    %
    % Detailed Description:
    %   -
    %
    % TODO - Add a method for tidying up the PBEAM/PBAR entries and
    % defining default values.
    
    properties (Dependent)
        %Names of the bulk data properties in the collection
        BulkDataNames 
    end
    
    methods % set / get
        function val = get.BulkDataNames(obj) %get.BulkDataNames
            val = obj.ItemNames;
        end
    end
    
    methods % construction
        function obj = FEModel
            
            %Update collection parameters
            obj.CollectionClass       = 'mni.bulk.BulkData';
            obj.CollectionDescription = 'bulk data';
            obj.AssignMethod          = @combine;
            
        end
    end
    
    methods (Sealed) % managing a collection of bulk data
        function makeIndices(obj)
            %makeIndices Builds the connections between different bulk data
            %objects in the model.
            %
            % Detailed Description:
            %    - In order for this method to work the 'BulkDataStructure'
            %      must be set correctly during the object constructor.
            %    -
            
            if isempty(obj.BulkDataNames)
                return
            end
            
            %What bulk data has been added?
            bulkNames = obj.BulkDataNames;
            bulkData  = get(obj, bulkNames);
            bulkClass = cellfun(@class, bulkData, 'Unif', false);
            for iB = 1 : numel(bulkNames)
                BDS = obj.(bulkNames{iB}).CurrentBulkDataStruct;
                Con = BDS.Connections;
                if isempty(Con)
                    %No connections defined then nothing to do
                    continue
                end
                nCon = numel(Con);
                for iC = 1 : nCon
                    type = Con(iC).Type; %type of bulk data that we are trying to connect to
                    %ID numbers which identify the connections to resolve
                    idNum = obj.(bulkNames{iB}).(Con(iC).Prop);
                    if iscell(idNum)
                        %List bulk will have a cell instead of array
                        %idNum = idNum{1};
                        idNum = horzcat(idNum{:});
                        idNum(idNum == 0) = [];
                    end
                    if ~any(idNum)
                        %Nothing to index!
                        continue
                    end
                    %Does the FEM contain this type of data?
                    idx = or(ismember(bulkNames, type), ismember(bulkClass, type));
                    if ~any(idx)
                        warning(['Unable to resolve connections for the ' , ...
                            '%s property in the %s object. No instances ' , ...
                            'of %s found in the FE Model. Make sure the ' , ...
                            '%s class has been defined in the +bulk ', ...
                            'package.'], Con(iC).DynProp, bulkNames{iB}, ...
                            Con(iC).Type, Con(iC).Type);
                        continue
                    end
                    %If we have mutliple instances of this bulk data type
                    %then we need to find the one that contains the ID num
                    index = find(idx);
                    idx   = cellfun(@(o) any(ismember(o.ID, idNum)), bulkData(idx));
                    if ~any(idx)
                        warning(['Unable to resolve the indices for the '  , ...
                            '%s property in the %s object. Could not '     , ...
                            'find the ID numbers related to the %s object ', ...
                            'in the model bulk data collection.'], ...
                            Con(iC).DynProp, bulkNames{iB}, Con(iC).Type);
                        continue
                    end
                    assert(nnz(idx) == 1, ['Ambiguous match when resolving ', ...
                        'the indices for the %s property in the %s object. ', ...
                        'Check that the BulkDataStructure is correctly '    , ...
                        'defined in the class constructor.'], Con(iC).DynProp, bulkNames{iB});
                    data = bulkData{index(idx)};
                    %Update handle reference
                    obj.(bulkNames{iB}).(Con(iC).DynProp) = data;
                    %Set the index by searching for matching IDs
                    index = nan(size(idNum));
                    for ii = 1 : size(index, 1)
                        [~, index(ii, :)] = ismember(idNum(ii, :), ....
                            obj.(bulkNames{iB}).(Con(iC).DynProp).ID);
                    end
                    obj.(bulkNames{iB}).([Con(iC).DynProp, 'Index']) = index;
                end
            end
            
        end
        function summary = summarise(obj)
            %summarise Generates a summary of all of the bulk data objects
            %in the model.
            
            summary = {};
            
            if isempty(obj.BulkDataNames)
                return
            end
            
            bulkNames = obj.BulkDataNames;
            
            %Summarise...
            summary = cell(1, numel(bulkNames));
            for iT = 1 : numel(bulkNames)
                summary{iT} = sprintf( ...
                    '%8s - %6i entry/entries', bulkNames{iT}, obj.(bulkNames{iT}).NumBulk);
            end
            
        end
        function printSummary(obj, varargin)
           %printSummary Prints a summary of the model.
           %
           % Syntax:
           %    - Print a summary of the model to the command window
           %        >> printSummary(obj)
           %    - Print a summary of the model to the command window and
           %      provide a reference to the parent file where the data was
           %      imported from.
           %        >> printSummary(obj, 'RootFile', 'sample_file.bdf');
           %    - Print a summary of the model to an external file by
           %      providing a file identifier.
           %        >> fid = fopen('file.txt', 'w');
           %        >> printSummary(obj, 'FileID', fid);
           %    - Print a summary of the model using a user supplied log
           %      function.
           %        >> log_fcn = @(s) fprintf(fid, '%s', s);
           %        >> printSummary(obj, 'LogFcn', log_fcn);
           %
           % Parameters:
           %    'RootFile' - Name of a file containing the model data.
           %    'FileID'   - Valid file identifier for writing data.
           %    'LogFcn'   - Function handle for writing the data.
           
           p = inputParser;
           addParameter(p, 'RootFile', '', @(x)validateattributes(x, ...
               {'char'}, {'row'}));
           addParameter(p, 'FileID'  , [], @(x)validateattributes(x, ...
               {'numeric'}, {'scalar', 'positive', 'finite', 'real', 'nonnan'}));
           addParameter(p, 'LogFcn'  , [], @(x) isa(x, 'function_handle')); 
           parse(p, varargin{:});
           
           log_fcn = p.Results.LogFcn;
           fid     = p.Results.FileID;
           file    = p.Results.RootFile;
           
           if isempty(log_fcn)
               if isempty(fid)
                   log_fcn = @(s) fprintf(s);       % command window
               else
                   log_fcn = @(s) fprintf(fid, s);  % external file
               end
           end
                      
           summary = summarise(obj);
           
           if isempty(file) %Print tailored summary message
               log_fcn(sprintf('Model contents:\n\n'));
               log_fcn(sprintf('\t%-s\n', sprintf('%s\n\t', summary{:})));
           else
               log_fcn(sprintf('Extraction summary:\n'));
               log_fcn(sprintf(['The following cards have been extracted ', ...
                   'successfully from the file ''%s'':\n\t%-s\n'], ...
                   file, sprintf('%s\n\t', summary{:})));
           end           

        end
    end
    methods
        function combine(obj)
            %combine Combines the bulk data from an array of
            %'mni.bulk.FEModel' objects into a single model.
            
            if numel(obj) == 1
                return
            end
            
            bulkNames = unique(horzcat(obj.BulkDataNames));
            if isempty(bulkNames)
                return
            end
            
            %Combine each set of bulk data
            for iB = 1 : numel(bulkNames)
                %Get the bulk data for this type from each model
                nam      = bulkNames{iB};
                data     = get(obj(isprop(obj, nam)), {nam});
                BulkObj  = horzcat(data{:});
                prpNames = BulkObj(1).CurrentBulkDataProps;
                %Get the bulk data from each FEModel and combine
                prpVal   = get(BulkObj, prpNames);
                prpVal   = arrayfun(@(ii) horzcat(prpVal{:, ii}), ...
                    1 : numel(prpNames), 'Unif', false);
                %If the main FEModel does not have this bulk data object
                %then make a new instance of the model
                if ~isprop(obj(1), bulkNames{iB})
                    fcn    = str2func(class(BulkObj));
                    NewObj = fcn(nam, numel(prpVal{1}));
                    addItem(obj(1), NewObj);
                end
                set(obj(1).(nam), prpNames, prpVal);
            end
            
        end
    end
    
    methods % visualisation
        function hg = draw(obj, hAx)
            %draw Method for plotting the content of a FEModel.
            
            hg = [];
            
            assert(numel(obj) == 1, 'Method ''draw'' is not valid of object arrays.');
            if isempty(obj.BulkDataNames)
                warning('No bulk data found in the FEM. Returning an empty array.');
                return
            end
            
            if nargin < 2 || isempty(hAx)
                hF  = figure('Name', 'Finite Element Model');
                hAx = axes('Parent',hF, 'NextPlot', 'add', 'Box', 'on');
                xlabel(hAx, 'X');
                ylabel(hAx, 'Y');
                zlabel(hAx, 'Z');
            end
            validateattributes(hAx, {'matlab.graphics.axis.Axes'}, {'scalar'}, class(obj), 'hAx');
            
            %Run 'drawElement' method for each bulk object in the model
            bulkNames = obj.BulkDataNames;
            hg = cell(1, numel(bulkNames));
            for iB = 1 : numel(bulkNames)
                hg{iB} = drawElement(obj.(bulkNames{iB}), hAx);
            end
            hg = horzcat(hg{:})';
            
            legend(hAx, hg, get(hg, {'Tag'}), 'ItemHitFcn', @cbToggleVisible);
            axis(hAx, 'equal');
            
        end
    end
    
end

%Callbacks for UI
function cbToggleVisible(~, evt)
%cbToggleVisible Toggles the visibility of a graphic object when it is
%clicked in the legend.

if ~isprop(evt.Peer, 'Visible')
    return
end

switch evt.Peer.Visible
    case 'on'
        evt.Peer.Visible = 'off';
    case 'off'
        evt.Peer.Visible = 'on';
end
end

