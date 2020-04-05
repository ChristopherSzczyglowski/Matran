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
                'Connections', {'PID', 'PAERO1','AeroBody', 'LSPAN', 'AEFACT', 'SpanDivision', 'LCHORD', 'AEFACT', 'ChordDivision'}, ...
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
            
            %Grab the panel data      
            PanelData = getPanelData(obj);             
            if isempty(PanelData)
                return
            end
            
            %Arrange vertex coordinates for vectorised plotting
            x = PanelData.Coords(:, 1 : 4, 1)';
            y = PanelData.Coords(:, 1 : 4, 2)';
            z = PanelData.Coords(:, 1 : 4, 3)';
            
            %Plot
            hg = patch(hAx, x, y, z, ...
                'Tag'      , 'Aero Panels', ...
                'FaceColor', [201, 201, 201] / 255);
            
        end
    end
    
    methods % helper functions 
        function PanelData = getPanelData(obj)
            %getPanelData Calculates the panel coordinates.
                                  
            PanelData = repmat(struct('Coords', [], 'Centre', []), [1, obj.NumBulk]);
            
            if isempty(PanelData)
                return
            end
            
            %Parse
            if any(obj.CP ~= 0)
                error('Update code for new aero coordinate system.');
            end
            if any(cellfun(@isempty, get(obj, {'X1', 'X12', 'X4', 'X43'})))
                warning('Panel vertices could not be defined.');
                return
            end
            if any(all([obj.NSPAN == 0 ; obj.LSPAN == 0]))
                warning(['Panel increments in spanwise direction ', ...
                    'could not be defined.']);
                return
            end
            if any(all([obj.NCHORD == 0 ; obj.LCHORD == 0]))
                warning(['Panel increments in chordwise direction ', ...
                    'could not be defined.']);
                return
            end
            
            %Loop through the data and generate panel coordinates
            for ii = 1 : obj.NumBulk
                
                %Get the corner coordinates
                xC = [ ...
                    [obj.X1(1, ii) ; obj.X1(1, ii) + obj.X12(ii)], ...
                    [obj.X4(1, ii) ; obj.X4(1, ii) + obj.X43(ii)]];
                yC = [ ...
                    [obj.X1(2, ii) ; obj.X1(2, ii)], ...
                    [obj.X4(2, ii) ; obj.X4(2, ii)]];
                zC = [ ...
                    [obj.X1(3, ii) ; obj.X1(3, ii)], ...
                    [obj.X4(3, ii) ; obj.X4(3, ii)]];  
                
                %Get the panel divisions
                if obj.LSPAN(ii) == 0
                    dSpan   = 1 / obj.NSPAN(ii);
                    etaSpan = unique([0 : dSpan :  1, 1]);
                else
                    etaSpan = obj.SpanDivision.Di{obj.SpanDivisionIndex(ii)};
                end                
                if obj.LCHORD(ii)== 0
                    dChord   = 1 / obj.NCHORD(ii);
                    etaChord = unique([0 : dChord : 1, 1]);                   
                else
                    etaChord = obj.ChordDivision.Di{obj.ChordDivisionIndex(ii)};
                end                                
                if iscolumn(etaSpan) || iscolumn(etaChord)
                    error('Why is this happening?'); %TODO remove this once we know this will never happen                   
                end
                                
                %Panel coordinates
                [xDat, yDat, zDat] = i_chordwisePanelCoords(xC, yC, zC, etaSpan, etaChord);
                
                %Define panels [5, nPanel, 3]
                PanelData(ii).Coords = i_panelVerticies(xDat, yDat, zDat, etaChord, etaSpan);
                
                %Calculate centre of panel
                PanelData(ii).Centre  = permute(mean(PanelData(ii).Coords(:, 1 : 4, :), 2), [1, 3, 2]);
                
            end
                        
            function [xDat, yDat, zDat] = i_chordwisePanelCoords(x, y, z, etaSpan, etaChord)
                %i_chordwisePanelCoords : Defines the (x,y,z) coordinates
                %of each panel corner. Should return 3 matricies (X,Y,Z) of
                %size [2, nSpanPanels + 1]
                
                nSpanPoints  = numel(etaSpan);
                nChordPoints = numel(etaChord);
                
                %Difference in x & y & z across panel
                dX = diff(x, [], 2);
                dY = diff(y, [], 2);
                dZ = diff(z, [], 2);
                
                %Chordwise lines -- plotted at intermediate locations,
                %therefore new x and z values are required!
                X = repmat(x(:, 1), [1, nSpanPoints]) + dX * etaSpan;
                Y = repmat(y(:, 1), [1, nSpanPoints]) + dY * etaSpan;
                Z = repmat(z(:, 1), [1, nSpanPoints]) + dZ * etaSpan;
                
                %Coordinates of each panel vertex
                xDat = X(1, :) + (diff(X)' * etaChord)';
                yDat = repmat(Y(1, :), [nChordPoints, 1]);
                zDat = repmat(Z(1, :), [nChordPoints, 1]);
                
            end
          
            function panel = i_panelVerticies(xDat, yDat, zDat, etaChord, etaSpan)
                %TODO - Vectorise this!
                
                nChord = numel(etaChord) - 1; 
                nSpan  = numel(etaSpan) - 1;
                
                %Preallocate
                panel = zeros(5, nChord * nSpan, 3);
                
                k = 1;                  % counter for the panel ID
                for j = 1 : nSpan       % <-- loop through spanwise points
                    for i = 1 : nChord  % <-- loop through chordwise points
                        % panel x-coordinates
                        panel(1, k, 1) = xDat(i    , j);
                        panel(2, k, 1) = xDat(i + 1, j);
                        panel(3, k, 1) = xDat(i + 1, j + 1);
                        panel(4, k, 1) = xDat(i    , j + 1);
                        panel(5, k, 1) = xDat(i    , j);
                        % panel y-coordinates
                        panel(1, k, 2) = yDat(i    , j);
                        panel(2, k, 2) = yDat(i + 1, j);
                        panel(3, k, 2) = yDat(i + 1, j + 1);
                        panel(4, k, 2) = yDat(i    , j + 1);
                        panel(5, k, 2) = yDat(i    , j);
                        % panel z-coordinates
                        panel(1, k, 3) = zDat(i    , j);
                        panel(2, k, 3) = zDat(i + 1, j);
                        panel(3, k, 3) = zDat(i + 1, j + 1);
                        panel(4, k, 3) = zDat(i    , j + 1);
                        panel(5, k, 3) = zDat(i    , j);
                        % next counter
                        k = k + 1;
                    end
                end
                
                panel = permute(panel, [2, 1, 3]);
                
            end
            
            %Define panel numbers
            pn = arrayfun(@(ii) obj.EID(ii) + [0 : size(PanelData(ii).Centre, 1) - 1], ...
                1 : numel(PanelData), 'Unif', false);
            pn = horzcat(pn{:})';
            
            %Combine into a single set 
            PanelData = struct( ...
                'Coords', vertcat(PanelData.Coords), ...
                'Centre', vertcat(PanelData.Centre), ...
                'IDs'   , pn);
                                
        end
    end
    
end

