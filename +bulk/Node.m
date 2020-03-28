classdef Node < bulk.BulkData
    %Node Describes a point in 3D-space for use in a finite element model.
    %
    % The definition of the 'Node' object matches that of the GRID bulk
    % data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'GRID'
    %   - 'SPOINT'
    
    %Store results data
    properties (Hidden = true)
        GlobalTranslation = [0 ; 0 ; 0];
        LocalTranslation  = [0 ; 0 ; 0];
    end
    
    %Visualisation
    properties (Hidden, Dependent)
        %Coordinates for drawing
        DrawCoords
    end
    
    methods % construction
        function obj = Node(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'GRID', ...
                'BulkProps'  , {'GID', 'CP', 'X', 'CD', 'PS', 'SEID'}, ...
                'PropTypes'  , {'i'  , 'i' , 'r', 'i' , 'c' , 'i'}   , ...
                'PropDefault', {''   , 0   , 0  , 0   , ''  , 0 }    , ...
                'Connections', {'CP', 'bulk.CoordSystem', 'InputCoordSys', 'CD', 'bulk.CoordSystem', 'OutputCoordSys'}, ...
                'PropMask'   , {'X', 3}, ...
                'AttrList'   , {'X', {'nrows', 3}}, ...
                'SetMethod'  , {'PS', @validateDOF});
            addBulkDataSet(obj, 'SPOINT', ...
                'BulkProps'  , {'ID'}, ...
                'PropType'   , {'i'} , ...
                'PropDefault', {''});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx, mode)
            %drawElement Draws the node objects as a discrete marker and
            %returns a single graphics handle for all the nodes in the
            %collection.
            
            if strcmp(obj.CardName, 'SPOINT')
                error('Update the Node draw method to plot scalar points at the origin');
            end
            
            if nargin < 3
                mode = [];
            end
            
            coords = getDrawCoords(obj, mode);
            hg     = drawNodes(coords, hAx);
            
        end
        function X = getDrawCoords(obj, mode)
            %getDrawCoords Returns the coordinates of the node in the
            %global (MSC.Nastran Basic) coordinate system based on the
            %current 'DrawMode' of the object.
            %
            % Accepts object arrays.
            
            if nargin < 2
                mode = [];
            end
            
            if isprop(obj, 'CP')
                cp = obj.CP;
                if any(cp ~= 0)
                    error('Update code to return coordinates from a different coordinate system');
                end
            end
            
            %Assume the worst
            X = nan(3, numel(obj));
            
            %Check if the object has any undeformed data
            X_  = {obj.X};
            idx = cellfun(@isempty, X_);
            if any(idx)
                warning(['Some ''awi.fe.Node'' objects do not have '   , ...
                    'any coordinate data. Update these objects before ', ...
                    'attempting to draw the model.']);
                return
            end
            X = horzcat(X_{:});
            
            %If the user wants the undeformed model then there is nothing
            %else to do
            if strcmp(mode, 'undeformed')
                return
            end
            
            %If we get this far then we need to add the displacements...
            
            idx = ismember(get(obj, {'DrawMode'}), 'deformed');
            
            %Check displacements have been defined
            dT  = {obj(idx).GlobalTranslation};
            if isempty(dT) || any(cellfun(@isempty, dT))
                if strcmp(mode, 'deformed')
                    warning(['Some ''awi.fe.Node'' objects do not have '   , ...
                        'any deformation data, returning undeformed model.', ...
                        'Update these objects before attempting to draw '  , ...
                        'the model.']);
                end
                return
            end
            dT = horzcat(dT{:});
            
            %Simple
            X(:, idx) = X(:, idx) + dT;
            
        end
    end
    
end
