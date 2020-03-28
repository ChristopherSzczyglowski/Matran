classdef CoordSystem < bulk.BulkData
    %CoordSystem Describes a rectangular coordinate system.
    %
    % The definition of the 'CoordSys' object matches that of the CORD2R
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'CORD1R' TODO
    %   - 'CORD2R'
    
    methods % construction
        function obj = CoordSystem(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CORD2R', ...
                'BulkProps'  , {'CID', 'RID', 'A', 'B', 'C'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'r', 'r', 'r'}, ...
                'PropDefault', {''   , 0    , 0  , 0  , 0  }, ...
                'Connections', {'RID', 'bulk.CoordSystem', 'InputCoordSys'}, ...
                'PropMask'   , {'A', 3, 'B', 3, 'C', 3}, ...
                'AttrList'   , {'A', {'nrows', 3}, 'B', {'nrows', 3}, 'C', {'nrows', 3}});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods (Sealed)
        function rMatrix = getRotationMatrix(obj)
            %getRotationMatrix Calculates the 3x3 rotation matrix for each
            %coordinate system.
            
            rMatrix = [];
            
            switch obj.CardName
                case 'CORD2R'
                    a = [obj.A];
                    b = [obj.B];
                    c = [obj.C];
                    
                    eZ = b - a;
                    AC = c - a;                    
                    eY = cross(eZ, AC);
                    eX = cross(eY, eZ);
                    
                    %Ensure unit vectors
                    eX = eX ./ repmat(sqrt(sum(eX.^2, 1)), [3, 1]);
                    eY = eY ./ repmat(sqrt(sum(eY.^2, 1)), [3, 1]);
                    eZ = eZ ./ repmat(sqrt(sum(eZ.^2, 1)), [3, 1]);
                                       
                    rMatrix = [ ...
                        permute(eX, [1, 3, 2]), ...
                        permute(eY, [1, 3, 2]), ...
                        permute(eZ, [1, 3, 2])];
                    
                otherwise
                    warning('Update code for new coordinate system type.');
            end
            
        end
        function originCoords = getOrigin(obj)
            %getOrigin Calculates the (x,y,z) coordinates of the origin of
            %the coordinates system in the local frame.
            
            originCoords = zeros(3, 1);
            
            if any(obj.RID ~= 0)
                warning('Update code to handle coordinate systems defined in a local frame.');
            end            
        end
    end
    
    methods % visualiation
        function hg = drawElement(obj, hAx)
            
            hg = [];
            
            %Calculate the origin and rotation matrix
            r = getRotationMatrix(obj);
            o = getOrigin(obj);
            
            if isempty(r)
                return
            end
            
            %Construct coordinates of eX, eY, eZ vectors
            eX = squeeze(r(:, 1, :));
            eY = squeeze(r(:, 2, :));
            eZ = squeeze(r(:, 3, :));
            oX = o + eX;
            oY = o + eY;
            oZ = o + eZ;
                        
            %Plot
            hg    = gobjects(1, 3);
            hg(1) = drawLines(o, oX, hAx, 'Color', [0, 1, 0], 'LineWidth', 2, 'Tag', 'Coord System X');
            hg(2) = drawLines(o, oY, hAx, 'Color', [0, 0, 1], 'LineWidth', 2, 'Tag', 'Coord System Y');
            hg(3) = drawLines(o, oZ, hAx, 'Color', [1, 0, 0], 'LineWidth', 2, 'Tag', 'Coord System Z');
                                              
            %Add text annotation for CID numbers            
            text(o(1, :), o(2, :), o(3, :), ...
                strtrim(cellstr(num2str([obj.CID]'))'), ...
                'Color'   , 'black', ...
                'FontSize', 12     , ...
                'Parent'  , hAx);
            
            %Add text labels for x,y,z axes            
            text(oX(1, :), oX(2, :), oX(3, :), 'X', ...
                'Parent'  , hAx    , ...
                'Color'   , get(hg(1), 'Color'), ...
                'FontSize', 12);
            text(oY(1, :), oY(2, :), oY(3, :), 'Y', ...
                'Parent'  , hAx   , ...
                'Color'   , get(hg(2), 'Color'), ...
                'FontSize', 12);
            text(oZ(1, :), oZ(2, :), oZ(3, :), 'Z', ...
                'Parent'  , hAx   , ...
                'Color'   , get(hg(3), 'Color'), ...
                'FontSize', 12);
            
        end
    end
    
end

