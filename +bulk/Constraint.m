classdef Constraint < bulk.BulkData
    %Constraint Describes a constraint applied to a node.
    %
    % The definition of the 'Constraint' object matches that of the SPC1
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'SPC'
    %   - 'SPC1'
            
    methods % construction
        function obj = Constraint(varargin)
                    
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'SPC', ...
                'BulkProps'  , {'SID', 'G', 'C', 'D'}   , ...
                'PropTypes'  , {'i'  , 'i' , 'r' , 'r' }, ...
                'PropDefault', {0    , 0   , 0   , 0   }, ...
                'IDProp'     , 'SID', ...
                'ListProp'   , {'G', 'C', 'D'}, ...
                'Connections', {'G', 'bulk.Node', 'Nodes'});
            addBulkDataSet(obj, 'SPC1', ...
                'BulkProps'  , {'SID', 'C', 'G'}, ...
                'PropTypes'  , {'i'  , 'c', 'i'}, ...
                'PropDefault', {''   , '' ,''}  , ...
                'IDProp'     , 'SID', ...
                'ListProp'   , {'G'}, ...
                'Connections', {'G', 'bulk.Node', 'Nodes'}, ...
                'SetMethod'  , {'C', @validateDOF});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % assigning data during import
        function assignH5BulkData(obj, bulkNames, bulkData)
            %assignH5BulkData Assigns the object data during the import
            %from a .h5 file.
                        
            prpNames   = obj.CurrentBulkDataProps;
            
            %Index of matching bulk data names
            [~, ind]  = ismember(bulkNames, prpNames);
            [~, ind_] = ismember(prpNames, bulkNames);
            
            %Build the prop data 
            prpData  = cell(size(prpNames));            
            prpData(ind(ind ~= 0)) = bulkData(ind_(ind_ ~= 0));            
            switch obj.CardName                
                case 'SPC1'
                    if any(contains(bulkNames, {'FIRST', 'SECOND'}))
                        %Card is using "THRU" command to specify list
                        prpData{ismember(prpNames, 'G')} = ...
                            bulkData{ismember(bulkNames, 'FIRST')} : ...
                            bulkData{ismember(bulkNames, 'SECOND')};
                    else
                        error('Check code');
                    end                   
            end                        
            assignH5BulkData@bulk.BulkData(obj, prpNames, prpData)
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx)
            %drawElement Draws the constraint objects as a discrete marker
            %at the specified nodes and returns a single handle for all the
            %beams in the collection.
            
            hg = [];
            
            if isempty(obj.Nodes)
                return
            end
            
            coords = obj.Nodes.X(:, obj.NodesIndex);
            
            switch obj.CardName
                case 'SPC'
                    txt = obj.C;
                case 'SPC1'
                    txt = arrayfun(@(ii) repmat(obj.C(ii), [1, numel(obj.G{ii})]), ...
                        1 : numel(obj.C), 'Unif', false);
                    txt = horzcat(txt{:});
                otherwise
                    error('Update draw method for new constraint cards.');
            end
            
            hg  = line(hAx, ...
                'XData', coords(1, :), ...
                'YData', coords(2, :), ...
                'ZData', coords(3, :), ...
                'LineStyle'      , 'none' , ...
                'Marker'         , '^'    , ...
                'MarkerFaceColor', 'c'    , ...
                'MarkerEdgeColor', 'k'    , ...
                'Tag'            , 'Constraints', ...
                'SelectionHighlight', 'off');
            if numel(txt) < 50
                if isnumeric(txt)
                    txt = cellstr(num2str(txt'));
                end
                hT = text(hAx, ...
                    coords(1, :), coords(2, :), coords(3, :), txt, ...
                    'Color'              , hg.MarkerFaceColor, ...
                    'VerticalAlignment'  , 'top', ...
                    'HorizontalAlignment', 'left', ...
                    'Tag'                , 'Constraint DOFs');
            end
            
        end
    end
    
end  