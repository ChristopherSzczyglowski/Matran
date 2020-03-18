classdef FEModel < matlab.mixin.SetGet & mixin.Dynamicable
    %FEModel Describes a collection of bulk data objects to which results
    %sets can be attached to.
    %
    % Detailed Description:
    %   - 
        
    properties (SetAccess = private, Hidden = true)
        %Cell array of character vectors containing the names of the bulk
        %data properties added using the 'addBulk' method.
        BulkDataNames = {};
    end
    
    methods (Sealed) % managing a collection of bulk data
        function addBulk(obj, BulkObj)
            %addBulk Adds the 'BulkObj' to the FEModel as a dynamic
            %property.
            
            assert(isa(BulkObj, 'bulk.BulkData'), ['Expected the bulk ', ...
                'data object to be a subclass of the ''bulk.BulkData'' class.']);
            cn = BulkObj.CardName;
            if isempty(cn)
                return
            end
            
            if isprop(obj, cn)
                error('TODO - Update code for the case where we are adding bulk data that already has a dynamic property');
            end
            
            addDynamicProp(obj, cn);
            obj.(cn) = BulkObj;
            obj.BulkDataNames = [obj.BulkDataNames, {cn}];
            
        end
        function combineBulkData(obj)
            %combineBulkData Combines the bulk data from an array of
            %'bulk.FEModel' objects into a single model.
            
            if numel(obj) == 1
                return
            end
            
            bulkNames = obj.BulkDataNames;
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
                    addBulk(obj(1), NewObj);
                end
                set(obj(1).(nam), prpNames, prpVal);
            end
            
        end
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
                   idx = or(ismember(bulkNames, Con(iC).Type), ismember(bulkClass, Con(iC).Type));
                   if ~any(idx)
                        warning(['Unable to resolve connections for the ' , ...
                            '%s property in the %s object. No instances ' , ...
                            'of %s found in the FE Model. Make sure the ' , ...
                            '%s class has been defined in the +bulk ', ...
                            'package.'], Con(iC).DynProp, bulkNames{iB}, ...
                            Con(iC).Type, Con(iC).Type);
                         continue
                   end
                   assert(nnz(idx) == 1, ['Ambiguous match when resolving ', ...
                       'the indices for the %s property in the %s object. ', ...
                       'Check that the BulkDataStructure is correctly '    , ...
                       'defined in the class constructor.'], Con(iC).DynProp, bulkNames{iB});
                   data = bulkData{idx};
                   %Update handle reference 
                   obj.(bulkNames{iB}).(Con(iC).DynProp) = data;
                   %Set the index by searching for matching IDs
                   index = nan(size(obj.(bulkNames{iB}).(Con(iC).Prop)));
                   for ii = 1 : size(index, 1)
                       [~, index(ii, :)] = ismember(obj.( ...
                           bulkNames{iB}).(Con(iC).Prop)(ii, :), ....
                           obj.(bulkNames{iB}).(Con(iC).DynProp).ID);                       
%                        [~, index(ii, :), bb] = intersect( ...
%                            obj.(bulkNames{iB}).(Con(iC).DynProp).ID, ...
%                            obj.(bulkNames{iB}).(Con(iC).Prop)(ii, :));
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
            hg = vertcat(hg{:});
           
            legend(hAx, hg, get(hg, {'Tag'}), 'ItemHitFcn', @toggleVisible);
            axis(hAx, 'equal');
            
        end
    end
    
end

%Callbacks for UI
function toggleVisible(~, evt)
%toggleVisible Toggles the visibility of a graphic object.

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

