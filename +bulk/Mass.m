classdef Mass < bulk.BulkData
    %Mass Describes a mass element in the model which is associated with a
    %Node.
    %
    % Valid Bulk Data Types:
    %   - CONM1 
    %   - CONM2    
    
    methods % construction
        function obj = Mass(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CONM1' , ...
                'BulkProps'  , {'EID', 'G', 'CID', 'M11', 'M21', 'M22', ...
                'M31', 'M32', 'M33', 'M41', 'M42', 'M43', 'M44', 'M51', ...
                'M52', 'M53', 'M54', 'M55', 'M61', 'M62', 'M63', 'M64', ...
                'M65', 'M66'}, ...
                'PropTypes'  , [{'i', 'i', 'i'}, repmat({'r'}, [1, 21])], ...
                'PropDefault', [{'' , '' , 0  }, num2cell(zeros(1, 21))], ...
                'Connections', {'G', 'bulk.Node', 'Nodes', 'CID', 'bulk.CoordSystem', 'CoordSys'});
            addBulkDataSet(obj, 'CONM2', ...
                'BulkProps'  , {'EID', 'G', 'CID', 'M', 'X', 'I11', 'I21', 'I22', 'I31', 'I32', 'I33'}, ...
                'PropTypes'  , {'i'  , 'i', 'i'  , 'r', 'r', 'r'  , 'r'  , 'r'  , 'r'  , 'r'  , 'r'  }, ...
                'PropDefault', {''   , '' , 0    , 0  , 0  , 0    , 0    , 0    , 0    , 0    ,  0   }, ...
                'PropMask'   , {'X', 3}, ...
                'AttrList'   , {'X', {'nrows', 3}}, ...
                'Connections', {'G', 'bulk.Node', 'Nodes', 'CID', 'bulk.CoordSystem', 'CoordSys'});
                        
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx, varargin)
            
            p = inputParser;
            addParameter(p, 'AddOffset', true, @(x)validateattributes(x, {'logical'}, {'scalar'}));
            parse(p, varargin{:});
            
            hg = [];
                       
            if any(obj.CID)
                error('Update draw method for different offset systems.');
            end
            
            coords = getDrawCoords(obj.Nodes, obj.DrawMode);
            if isempty(coords)
                return
            end
            coords = coords(:, obj.NodesIndex);
            
            if p.Results.AddOffset && isprop(obj, 'X') %Add offset
                coords = coords + obj.X;
            end
            
            hg = drawNodes(coords, hAx, ...
                'Marker', '^', 'MarkerFaceColor', 'b', 'Tag', 'Mass');
            
        end
    end
    
end

