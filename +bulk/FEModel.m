classdef FEModel < matlab.mixin.SetGet & mixin.Dynamicable
    %FEModel Describes a collection of bulk data objects to which results
    %sets can be attached to.
    %
    % Detailed Description:
    %   - 
            
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
            
            addDynamicProp(obj, cn);
            obj.(cn) = BulkObj;
            
        end
        function makeIndices(obj)
           %makeIndices Builds the connections between different bulk data
           %objects in the model.   
           %
           % Detailed Description: 
           %    - In order for this method to work the 'BulkDataStructure'
           %      must be set correctly during the object constructor.
           %    - 
           
           if isempty(obj.DynamicProps)
               return
           end
           
           %What bulk data has been added?
           bulkNames = {obj.DynamicProps.Name};
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
                       [~, index(ii, :), ~] = intersect( ...
                           obj.(bulkNames{iB}).(Con(iC).DynProp).ID, ...
                           obj.(bulkNames{iB}).(Con(iC).Prop)(ii, :));
                   end
                   obj.(bulkNames{iB}).([Con(iC).DynProp, 'Index']) = index;
               end
           end
           
        end
        function summary = summarise(obj)
            %summarise Generates a summary of all of the bulk data objects
            %in the model.
            
            summary = {};
            
            if isempty(obj.DynamicProps)
                return
            end
            
            propNames = {obj.DynamicProps.Name};
                        
            %Summarise...
            summary = cell(1, numel(propNames));
            for iT = 1 : numel(propNames)
                summary{iT} = sprintf( ...
                    '%8s - %6i entry/entries', propNames{iT}, obj.(propNames{iT}).NumBulk);
            end
            
        end
    end
    
    methods % visualisation
        function hg = draw(obj, hAx) 
            %draw Method for plotting the content of a FEModel.
            
            if nargin < 2
                hF  = figure('Name', 'Finite Element Model');
                hAx = axes('Parent',hF, 'NextPlot', 'add', 'Box', 'on');
                xlabel(hAx, 'X');
                ylabel(hAx, 'Y');
                zlabel(hAx, 'Z');
            end
            validateattributes(hAx, {'matlab.graphics.axis.Axes'}, {'scalar'}, class(obj), 'hAx');
            
            %Run 'drawElement' method for each bulk object in the model
            bulkNames = {obj.DynamicProps.Name};
            hg = cell(1, numel(bulkNames));
            for iB = 1 : numel(bulkNames)
                hg{iB} = drawElement(obj.(bulkNames{iB}), hAx);
            end
            hg = vertcat(hg{:});
           
            legend(hAx, hg, {hg.Tag}, 'ItemHitFcn', @toggleVisible);
            
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

