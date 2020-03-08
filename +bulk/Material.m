classdef Material < bulk.BulkData
    %Material Describes the properties of a bulk.Beam object.
    %
    % The definition of the 'BeamProp' object matches that of the PBEAM
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'PBEAM' -> TODO
    %   - 'PBAR'
    %   - 'PROD'  -> TODO
    
    properties
        %Material ID number
        MID
        %Youngs Modulus
        E
        %Shear Modulus
        G
        %Poisson's ratio
        NU
        %Material density
        RHO
        %Thermal expansion coefficient
        A
        %Reference temperature
        TREF
        %Structural element damping coefficient
        GE
        %Stress limit for tension
        ST
        %Stress limit for compression
        SC
        %Stress limit for shear
        SS
        %Material coordinate system identification number
        MCSID
    end
    
    methods % set / get
        function set.MID(obj, val)
            obj.ID = val;
        end
        function set.E(obj, val)
            validateReal(obj, val, 'E', {'nonnegative'});
            obj.E = val;
        end
        function set.G(obj, val)
            validateReal(obj, val, 'E', {'nonnegative'});
            obj.G = val;
        end
        function set.NU(obj, val)
            validateattributes(val, {'numeric'}, {'2d', 'nonnan', ...
                'finite', 'real', '>', -1, '<', 0.5}, class(obj), 'NU');
            obj.NU = val;
        end
        function set.RHO(obj, val)
            validateReal(obj, val, 'E', {'nonnegative'});
            obj.RHO = val;
        end
        function set.A(obj, val)
            validateReal(obj, val, 'A');
            obj.A = val;
        end
        function set.TREF(obj, val)
            validateReal(obj, val, 'TREF');
            obj.TREF = val;
        end
        function set.GE(obj, val)
            validateReal(obj, val, 'GE');
            obj.GE = val;
        end
        function set.ST(obj, val)
            validateReal(obj, val, 'ST', {'nonnegative'});
            obj.ST = val;
        end
        function set.SC(obj, val)
            validateReal(obj, val, 'SC', {'nonnegative'});
            obj.SC = val;
        end
        function set.SS(obj, val)
            validateReal(obj, val, 'SS', {'nonnegative'});
            obj.SS = val;
        end
        function val = get.MID(obj)
            val = obj.ID;
        end
    end
    
    methods % construction
        function obj = Material(varargin)
                
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'MAT1', ...
                'BulkProps'  , {'MID', 'E', 'G', 'NU', 'RHO', 'A', 'TREF', 'GE', 'ST', 'SC', 'SS', 'MCSID'}, ...
                'BulkTypes'  , {'i'  , 'r', 'r', 'r' , 'r'  , 'r', 'r'   , 'r' , 'r' , 'r' , 'r' , 'i'}    , ...
                'BulkDefault', {''   , 0  , 0  , 0   , 0    , 0  , 0     , 0   , 0   , 0   , 0   , 0});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
end

