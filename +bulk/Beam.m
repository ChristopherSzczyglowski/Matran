classdef Beam < bulk.BulkData
    %Beam Describes a 1D element between 2 Nodes.
    %
    % The definition of the 'Beam' object matches that of the CBEAM bulk
    % data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'CBEAM' -> TODO
    %   - 'CBAR'
    %   - 'CROD'  -> TODO
    
    %Primary Properties
    properties
        %Identification number
        EID
        %
        PID
        %
        GA_GB
        %
        X
        %
        OFFT = {'GGG'};
    end
    
    properties (Constant)
        ValidOffsetToken = {'GGG'};
    end
    
    methods % set/get
        function set.EID(obj, val)
            obj.ID = val;
        end
        function set.PID(obj, val)
            validateID(obj, val, 'PID');
            obj.PID = val;
        end
        function set.GA_GB(obj, val)
            if isrow(val)
                val = repmat(val, [2, 1]);
            end
            validateID(obj, val, 'GA_GB');
            obj.GA_GB = val;
        end
        function set.X(obj, val)
            if isrow(val)
                val = repmat(val, [3, 1]);
            end
            validateattributes(val, {'numeric'}, {'2d', 'nrows', 3, 'finite', ...
                'nonnan', 'real'}, class(obj), 'X');
            obj.X = val;
        end
        function set.OFFT(obj, val)
            msg = sprintf(['Expected ''OFFT'' to be a cell array ', ...
                'of string with each element being one of the following '  , ...
                'tokens:\n\n\t- %s\n\n'], strjoin(obj.ValidOffsetToken, ', '));
            assert(iscellstr(val), msg); %#ok<ISCLSTR>
            assert(all(ismember(val, obj.ValidOffsetToken)), msg);
            obj.OFFT = val;
        end
        function val = get.EID(obj)
            val = obj.ID;
        end
    end
    
    methods % construction
        function obj = Beam(varargin)
                        
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CBAR', ...
                'BulkProps'  , {'EID', 'PID', 'GA_GB', 'X', 'OFFT'}, ...
                'BulkTypes'  , {'i'  , 'i'  , 'i'    , 'r', 'c'}   , ...
                'BulkDefault', {''   , ''   , ''     , '' , 'GGG'} , ...
                'PropMask'   , {'GA_GB', 2, 'X', 3}, ...
                'Connections', {'GA_GB', 'bulk.Node', 'Nodes'});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx)
            %drawElement Draws the beam objects as a line object between
            %the nodes and returns a single handle for all the beams in the
            %collection.
            
            xA = obj.Nodes.X(:, obj.NodesIndex(1, :));
            xB = obj.Nodes.X(:, obj.NodesIndex(2, :));        
            x  = padCoordsWithNaN([xA(1, :) ; xB(1, :)]);
            y  = padCoordsWithNaN([xA(2, :) ; xB(2, :)]);
            z  = padCoordsWithNaN([xA(3, :) ; xB(3, :)]);
            
            hg = line('XData', x, 'YData', y, 'ZData', z, ...
                'Parent'   , hAx, ...
                'LineStyle', '-', ...
                'LineWidth', 1  , ...
                'Color'    , 'k', ...
                'Tag'      , 'Beams');
            
        end
    end
    
end

