classdef AeroPanel < bulk.BulkData
    %AeroPanel Describes a collection of aerodynamic panels.
    %
    % The definition of the 'AeroPanel' object matches that of the CAERO1
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'CAERO1'
    
    methods % construction
        function obj = AeroPanel(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CAERO1', ...
                'BulkProps'  , {'EID', 'PID', 'CP', 'NSPAN', 'NCHORD', 'LSPAN', 'LCHORD', 'IGID', 'X1', 'X12', 'X4', 'X43'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i' , 'i'    , 'i'     , 'i'    , 'i'     , 'i'   , 'r' , 'r'  , 'r' , 'r'}  , ...
                'PropDefault', {''   , ''   , 0   , 0      , 0       , 0      , 0       , 0     , ''  , 0    , ''  , 0}    , ...
                'PropMask'   , {'X1', 3, 'X4', 3} , ...
                'AttrList'   , {'X1', {'nrows', 3}, 'X4', {'nrows', 3}});
            
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

