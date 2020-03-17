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
    
    properties (Constant)
        ValidOffsetToken = {'GGG'};
    end
    
    methods % construction
        function obj = Beam(varargin)
                        
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CBAR', ...
                'BulkProps'  , {'EID', 'PID', 'GA_GB', 'X', 'OFFT'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i'    , 'r', 'c'}   , ...
                'PropDefault', {''   , ''   , ''     , '' , 'GGG'} , ...
                'PropMask'   , {'GA_GB', 2, 'X', 3}, ...
                'Connections', {'GA_GB', 'bulk.Node', 'Nodes', 'PID', 'bulk.BeamProp', 'Prop'}     , ...
                'AttrList'   , {'GA_GB', {'nrows', 2}, 'X', {'nrows', 3}}, ...
                'SetMethod'  , {'OFFT', @validateOFFT});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % validation
        function validateOFFT(obj, val, prpName, varargin)
            
            msg = sprintf(['Expected ''%s'' to be a cell array ', ...
                'of string with each element being one of the following '  , ...
                'tokens:\n\n\t- %s\n\n'], prpName, strjoin(obj.ValidOffsetToken, ', '));
            assert(iscellstr(val), msg); %#ok<ISCLSTR>
            assert(all(ismember(val, obj.ValidOffsetToken)), msg);
            obj.OFFT = val;

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

