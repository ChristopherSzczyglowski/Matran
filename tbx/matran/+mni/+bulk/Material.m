classdef Material < mni.bulk.BulkData
    %Material Describes the properties of a bulk.Beam object.
    %
    % The definition of the 'BeamProp' object matches that of the PBEAM
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'MAT1'

    methods % construction
        function obj = Material(varargin)
                
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'MAT1', ...
                'BulkProps'  , {'MID', 'E', 'G', 'NU', 'RHO', 'A', 'TREF', 'GE', 'ST', 'SC', 'SS', 'MCSID'}, ...
                'PropTypes'  , {'i'  , 'r', 'r', 'r' , 'r'  , 'r', 'r'   , 'r' , 'r' , 'r' , 'r' , 'i'}    , ...
                'PropDefault', {''   , 0  , 0  , 0   , 0    , 0  , 0     , 0   , 0   , 0   , 0   , 0}      , ...
                'IDProp'     , 'MID', ...
                'AttrList'   , {'E', {'nonnegative'}, 'G', {'nonnegative'}, 'NU',  {'>', -1, '<', 0.5}     , ...
                'RHO', {'nonnegative'}, 'ST', {'nonnegative'}, 'SC', {'nonnegative'}, 'SS', {'nonnegative'}});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
end

