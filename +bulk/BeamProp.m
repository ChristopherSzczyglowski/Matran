classdef BeamProp < bulk.BulkData
    %BeamProp Describes the properties of a bulk.Beam object.
    %
    % The definition of the 'BeamProp' object matches that of the PBEAM
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'PBEAM' -> TODO
    %   - 'PBAR'
    %   - 'PROD'  -> TODO
    
    %Primary properties
    properties
        %Property ID number
        PID
        %Material ID number
        MID
        %Cross-sectional area
        A
        %Second moment of area about plane 1-1
        I1
        %Second moment of area about plane 2-2
        I2
        %Polar second moment of area
        J
        %Non-structural mass per unit length
        NSM
        %Stress recovery coefficient 1 (x2)
        C
        %Stress recovery coefficient 2 (x2)
        D
        %Stress recovery coefficient 3 (x2)
        E
        %Stress recovery coefficient 4 (x2)
        F
        %Area factor for shear (x2)
        K
        %Second moment of area about plane 1-2 
        I12
    end
    
    methods % set / get
        function set.PID(obj, val)
           obj.ID = val; 
        end
        function set.MID(obj, val)
            validateID(obj, val, 'MID');
            obj.MID = val;
        end
        function set.A(obj, val)
            validateBeamProp(obj, val, 'A');
            obj.A = val;
        end
        function set.I1(obj, val)
            validateBeamProp(obj, val, 'I1');
            obj.I1 = val;
        end
        function set.I2(obj, val)
            validateBeamProp(obj, val, 'I2');
            obj.I2 = val;
        end
        function set.J(obj, val)
            validateBeamProp(obj, val, 'J');
            obj.J = val;
        end
        function set.NSM(obj, val)
            validateBeamProp(obj, val, 'NSM');
            obj.NSM = val;
        end
        function set.C(obj, val)
           if isrow(val)
                val = repmat(val, [2, 1]);
           end 
            validateBeamProp(obj, val, 'C');
            obj.C = val;
        end
        function set.D(obj, val)
           if isrow(val)
                val = repmat(val, [2, 1]);
           end 
            validateBeamProp(obj, val, 'D');
            obj.D = val;
        end
        function set.E(obj, val)
           if isrow(val)
                val = repmat(val, [2, 1]);
           end 
            validateBeamProp(obj, val, 'E');
            obj.E = val;
        end
        function set.F(obj, val)
           if isrow(val)
                val = repmat(val, [2, 1]);
           end 
            validateBeamProp(obj, val, 'f');
            obj.F = val;
        end
        function set.K(obj, val)
           if isrow(val)
                val = repmat(val, [2, 1]);
           end 
            validateBeamProp(obj, val, 'K');
            obj.K = val;
        end
        function val = get.PID(obj)
            val = obj.ID;
        end        
    end
    
    methods % constructor
        function obj = BeamProp(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'PBAR', ...
                'BulkProps'  , {'PID', 'MID', 'A', 'I1', 'I2', 'J', 'NSM', 'C', 'D', 'E', 'F', 'K', 'I12'}, ...
                'BulkTypes'  , {'i'  , 'i'  , 'r', 'r' , 'r' , 'r', 'r'  , 'r', 'r', 'r', 'r', 'r', 'r'}  , ...
                'BulkDefault', {''   , ''   , 0  , 0   , 0   , 0  , 0    , 0  , 0  , 0  , 0  , 0  , 0}    , ...
                'PropMask'   , {'C', 2, 'D', 2, 'E', 2, 'F', 2, 'K', 2}, ...
                'Connections', {'MID', 'bulk.Material', 'Materials'});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
end

