classdef Node < bulk.BulkData
    %Node Describes a point in 3D-space for use in a finite element model.
    %
    % The definition of the 'Node' object matches that of the GRID bulk
    % data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'GRID'
    %   - 'SPOINT'
    
    %Primary Properties
    properties
        %Identification number
        GID
        %Definition coordinate system identification number
        CP = 0;
        %Coordinates of the node in the coordinate system defined by CP
        X = [0 ; 0 ; 0];
        %Output coordinate system identification number
        CD = 0;
        %Permanent single point constraints
        PS
        %Super element ID numbers
        SEID
    end
    
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
    
    methods % set / get
        function set.GID(obj, val)               %set.GID
            %set.GID Set method for the property 'GID'.
            %
            % Passes the value straight to the inherited 'ID' property
            % which will validate and store the ID number.
            obj.ID = val;
        end
        function set.CP(obj, val)                %set.CP
            validateID(obj, val, 'CP')
            obj.CP = val;
        end
        function set.X(obj, val)                 %set.X
            if isrow(val)
                val = repmat(val, [3, 1]);
            end
            validateattributes(val, {'numeric'}, {'2d', 'nrows', 3, ...
                'finite', 'real', 'nonnan'}, class(obj), 'X');
            obj.X = val;
        end
        function set.CD(obj, val)                %set.CD
            validateID(obj, val, 'CD')
            obj.CD = val;
        end
        function set.PS(obj, val)                %set.PS
            validateDOF(obj, val, 'PS');
            obj.PS = val;
        end
        function set.SEID(obj, val)              %set.SEID
           validateID(obj, val, 'SEID');
           obj.SEID = val;
        end
        function set.GlobalTranslation(obj, val) %set.GlobalTranslation
            validateattributes(val, {'numeric'}, {'column', 'numel', 3, ...
                'finite', 'real', 'nonnan'}, class(obj), 'GlobalTranslation');
            obj.GlobalTranslation = val;
        end
        function val = get.GID(obj)              %get.GID
            val = obj.ID;
        end
        function val = get.DrawCoords(obj)       %get.DrawCoords
            %get.DrawCoords Get method for the property 'DrawCoords'.
            
            val = [];
            
            if isempty(obj.X)
                return
            end
            
            %Pass it on
            val = obj.getDrawCoords(obj);
            
        end
    end
    
    methods % construction
        function obj = Node(varargin)
                        
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'GRID', ...
                'BulkProps'  , {'GID', 'CP', 'X', 'CD', 'PS', 'SEID'}, ...
                'BulkTypes'  , {'i'  , 'i' , 'r', 'i' , 'c' , 'i'}   , ...
                'BulkDefault', {''   , 0   , '' , 0   , ''  , 0 }    , ...
                'PropMask'   , {'X', 3});
            addBulkDataSet(obj, 'SPOINT', ...
                'BulkProps'  , {'ID'}, ...
                'BulkType'   , {'i'} , ...
                'BulkDefault', {''});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, ha, mode)
            %drawElement Draws the node objects as a discrete marker and
            %returns a single graphics handle for all the nodes in the
            %collection.
            %
            % Accepts a vector of objects.
            
            if nargin < 3
                mode = [];
            end
            
            coords = getDrawCoords(obj, mode);
            hg     = drawNodes(coords, ha);
            
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

