classdef Constraint < bulk.BulkData
    %Constraint Describes a constraint applied to a node.
    %
    % The definition of the 'Constraint' object matches that of the SPC1
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'SPC1'
    
    properties
        %SPC ID number
        SID
        %Degrees of freedom being constrained
        C
        %ID numbers of Nodes
        G
    end
    
    methods % set / get
        function set.SID(obj, val)
            validateID(obj, val, 'SID');
            obj.ID = val;
        end
        function set.C(obj, val)
           validateDOF(obj, val, 'C');
           obj.C = val;
        end
        function set.G(obj, val)
            obj.G = val;
        end
        function val = get.SID(obj)
            val = obj.ID;
        end
    end
    
    methods % construction
        function obj = Constraint(varargin)
                    
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'SPC1', ...
                'BulkProps'  , {'SID', 'C', 'G'}, ...
                'BulkTypes'  , {'i'  , 'c', 'i'}, ...
                'BulkDefault', {''   , '' ,''}  , ...
                'PropList'   , {'G'}, ...
                'Connections', {'G', 'bulk.Node', 'Nodes'});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx)
            %drawElement Draws the constraint objects as a discrete marker
            %at the specified nodes and returns a single handle for all the
            %beams in the collection.
            
            coords = obj.Nodes.X(:, obj.NodesIndex);
            
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

        end
    end
    
end  