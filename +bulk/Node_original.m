classdef Node < awi.fe.FEBaseClass
    %Node Describes a point in 3D-space for use in a finite element model.
    %
    % The definition of the 'Node' object matches that of the GRID bulk 
    % data type from MSC.Nastran.    
    
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
    end
    
    %Store a reference to the 'awi.fe' objects
    properties (Hidden = true)
        %Handle to the 'awi.fe.CoordSys' object that defines the output
        %coordinate system
        OutputCoordSys = [];
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
            validateattributes(val, {'numeric'}, {'column', 'numel', 3, ...
                'finite', 'real', 'nonnan'}, class(obj), 'X');
            obj.X = val;
        end
        function set.CD(obj, val)                %set.CD
            validateID(obj, val, 'CD')
            obj.CD = val;
        end
        function set.OutputCoordSys(obj, val)    %set.OutputCoordSys
            %set.OutputCoordSys Set method for the property 'OutputCoordSys'.
            %
            % 'OutputCoordSys' must be a scalar instance of 'awi.fe.CoordSys'.
            validateattributes(val, {'awi.fe.CoordSys'}, {'scalar', ...
                'nonempty'}, class(obj), 'OutputCoordSys');
            obj.OutputCoordSys = val;
        end
        function set.GlobalTranslation(obj, val) %set.GlobalTranslation
            validateattributes(val, {'numeric'}, {'column', 'numel', 3, ...
                'finite', 'real', 'nonnan'}, class(obj), 'GlobalTranslation');
            obj.GlobalTranslation = val;
        end
        function val = get.GID(obj)              %get.GID
            val = obj.ID;
        end
        function val = get.CD(obj)               %get.CD
            %get.CD Get method for the property 'CD'.
            %
            % If the object has been assigned a handle to its
            % 'awi.fe.CoordSys' object then always use their ID numbers,
            % else use CD.
            
            if isempty(obj.OutputCoordSys)
                val = obj.CD;
            else
                val = obj.OutputCoordSys.CID;
            end
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
        function obj = Node
            
            %Make a note of the property names
            addFEProp(obj, 'GID', 'CP', 'X', 'CD');
            
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
    
    methods % writing data in MSC.Nastran format
        function writeToFile(obj, fid, bComment)
            %writeToFile Write the data for the 'awi.fe.Node' object into a
            %text file using the format of the MSC.Nastran 'GRID' bulk data
            %entry. 
            %
            % The following assumptions are made:
            %   * The PS and SEID properties are omitted. i.e. There are no
            %   permanenent single point constraints and all nodes are
            %   assumed to belong to the same super element.            
            
            %By default, do not close the file
            bClose = false;
                        
            if nargin < 2 %Ask the user for the file
                fName  = awi.fe.FEBaseClass.getBulkDataFile;
                bClose = true;
                fid    = fopen(fName, 'w');                
            end
            
            if nargin < 3 %Comments by standard
                bComment = true;
            end
                        
            if bComment %Helpful comments?
                comment = ['GRID : Defines the location of a '     , ...
                    'geometric grid point, the directions of its ' , ...
                    'displacement, and its permanent single-point ', ...
                    'constraints.'];
                awi.fe.FEBaseClass.writeComment(comment, fid);  
            end
            
            awi.fe.FEBaseClass.writeColumnDelimiter(fid, 'large');    
            
            %Split up the coordinates            
            coords = [obj.X];
            X1 = num2cell(coords(1, :));
            X2 = num2cell(coords(2, :));
            X3 = num2cell(coords(3, :));
            
            %Card name
            nam   = repmat({'GRID*'}  , [1, numel(X1)]);
            blnks = repmat({['*', blanks(7)]}, [1, numel(X1)]);
            
            %Set up the format for printing
            data = [nam ; {obj.ID} ; {obj.CP} ; X1 ; X2 ; blnks ; X3 ; {obj.CD}];
            
            %Write in 16-character column width as standard
            format = [ ...
                '%-8s%-16i%-16i%#-16.8g%#-16.8g\r\n', ...
                '%-8s%#-16.8g%#-16i\r\n'];
            
            %Write the data to the file
            fprintf(fid, format, data{:});
            
            if bClose %Close the file?
                fclose(fid);
            end
            
        end
    end
    
end

