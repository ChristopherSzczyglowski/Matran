classdef Constraint < mni.bulk.BulkData
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
                'BulkProps'  , {'SID', 'G' , 'C', 'D'}   , ...
                'PropTypes'  , {'i'  , 'i' , 'r' , 'r' }, ...
                'PropDefault', {0    , 0   , 0   , 0   }, ...
                'IDProp'     , 'SID', ...
                'ListProp'   , {'G', 'C', 'D'}, ...
                'Connections', {'G', 'mni.bulk.Node', 'Nodes'});
            addBulkDataSet(obj, 'SPC1', ...
                'BulkProps'  , {'SID', 'C', 'G'}, ...
                'PropTypes'  , {'i'  , 'c', 'i'}, ...
                'PropDefault', {''   , '' ,''}  , ...
                'IDProp'     , 'SID' , ...
                'ListProp'   , {'G'} , ...
                'H5ListName' , {'ID'}, ...
                'Connections', {'G', 'mni.bulk.Node', 'Nodes'}, ...
                'SetMethod'  , {'C', @validateDOF});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % assigning data during import
        function [bulkNames, bulkData] = parseH5DataGroup(obj, h5Struct)
            %parseH5DataGroup Parse the data in the h5 data group
            %'h5Struct' and return the bulk names and data. 
            %
            % The list data can be specified in the 'G' field or in the
            % 'IDENTITY' field using the "THRU" notation.
            
            fNames = fieldnames(h5Struct);
            if ~any(ismember(fNames, {'SPC1_THRU', 'SPC1_G'}))
                error('Update code for new format.');
            end
            if numel(h5Struct.SPC1_G.IDENTITY.SID) > 1
                error('Update code to handle multiple datasets.');
            end   
            
            nGrps = numel(fNames);
            bn = cell(1, nGrps);
            bd = cell(1, nGrps);
            for ii = 1 : nGrps
                [bn{ii}, bd{ii}] = parseH5DataGroup@mni.bulk.BulkData( ...
                    obj, h5Struct.(fNames{ii}));
            end
            bd = vertcat(bd{:});
            bulkNames = bn{1};
            bulkData  = arrayfun(@(ii) horzcat(bd{:, ii}), ...
                1 : numel(bulkNames), 'Unif', false);
            
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