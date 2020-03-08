classdef AeroPanel < bulk.BulkData
    %AeroPanel Describes a collection of aerodynamic panels.
    %
    % The definition of the 'AeroPanel' object matches that of the CAERO1
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'CAERO1'
    
    %Primary properties
    properties
        %Element ID number
        EID
        %Property ID number 
        PID
        %Identification number of aerodynamic coordinate system
        CP
        %Number of spanwise boxes
        NSPAN
        %Number of chordwise boxes
        NCHORD
        %ID number of AEFACT entry for defining spanwise boxes
        LSPAN
        %ID number of AEFACT entry for defining chordwise boxes
        LCHORD
        %ID number of interference group
        IGID
        %Coordinates of point 1 in the aerodynamc coordinate system
        X1
        %Chord length from point 1-2
        X12
        %Coordinates of point 4 in the aerodynamic coordinate system
        X4
        %Chord length from point 4-3
        X43      
    end
    
    methods % set / get
        function set.EID(obj, val)
            obj.ID = val;
        end
        function set.PID(obj, val)
           validateID(obj, val, 'PID');
           obj.PID = val;
        end
        function set.CP(obj, val)
            validateID(obj, val, 'CP');
            obj.CP = val;
        end
        function set.NSPAN(obj, val)
            validateID(obj, val, 'NSPAN');
            obj.NSPAN = val;
        end
        function set.NCHORD(obj, val)
            validateID(obj, val, 'NCHORD');
            obj.NCHORD = val;
        end
        function set.LSPAN(obj, val)
           validateID(obj, val, 'LSPAN');
           obj.LSPAN = val;
        end
        function set.LCHORD(obj, val)
           validateID(obj, val, 'LCHORD');
           obj.LCHORD = val;
        end
        function set.IGID(obj, val)
           validateID(obj, val, 'IGID');
           obj.IGID = val;
        end
        function set.X1(obj, val)
            if isrow(val)
                val = repmat(val, [3, 1]);
            end
            validateReal(obj, val, 'X1', {'nrows', 3});
            obj.X1 = val;
        end
        function set.X12(obj, val)
            validateReal(obj, val, 'X12');
            obj.X12 = val;
        end
        function set.X4(obj, val)
            if isrow(val)
                val = repmat(val, [3, 1]);
            end
            validateReal(obj, val, 'X4', {'nrows', 3});
            obj.X4 = val;
        end
        function set.X43(obj, val)
            validateReal(obj, val, 'X43');
            obj.X43 = val;
        end
        function val = get.EID(obj)
            val = obj.ID;
        end
    end
    
    methods % construction
        function obj = AeroPanel(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CAERO1', ...
                'BulkProps'  , {'EID', 'PID', 'CP', 'NSPAN', 'NCHORD', 'LSPAN', 'LCHORD', 'IGID', 'X1', 'X12', 'X4', 'X43'}, ...
                'BulkTypes'  , {'i'  , 'i'  , 'i' , 'r'    , 'r'     , 'i'    , 'i'     , 'i'   , 'r' , 'r'  , 'r' , 'i'}  , ...
                'BulkDefault', {''   , ''   , 0   , 0      , 0       , 0      , 0       , 0     , ''  , 0    , ''  , 0}    , ...
                'PropMask'   , {'X1', 3, 'X4', 3});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx)
            %drawElement Draws the AeroPanel object as a single patch
            %object and returns a single graphics handle for all AeroPanels
            %in the collection.
            
            hg = [];
            
            warning('Update drawElement method for AeroPanel object.');
            
        end
    end
    
end

