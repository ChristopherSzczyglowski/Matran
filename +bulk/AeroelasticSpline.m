classdef AeroelasticSpline < bulk.BulkData
    %AeroelasticSpline
    
    methods % construction
        function obj = AeroelasticSpline(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'SPLINE1', ...
                'BulkProps'  , {'EID', 'CAERO', 'BOX1', 'BOX2', 'SETG', 'DZ', 'METHOD', 'USAGE', 'NELEM', 'MELEM'}, ...
                'PropTypes'  , {'i'  , 'i'    , 'i'   , 'i'   , 'i'   ,  'r', 'c'   , 'c'    , 'r'    , 'r'}    , ...
                'PropDefault', {''   , ''     , ''    , ''    , ''    , 0   , 'IPS' , 'BOTH' , 10     , 10}     , ...
                'IDProp'     , 'EID', ...
                'Connections', {'CAERO', 'bulk.AeroPanel', 'AeroPanel', 'SETG', 'bulk.List', 'StrucNode'});
            addBulkDataSet(obj, 'SPLINE2', ...
                'BulkProps'  , {'EID', 'CAERO', 'ID1', 'ID2', 'SETG', 'DZ', 'DTOR', 'CID', 'DTHX', 'DTHY', 'USAGE'}, ...
                'PropTypes'  , {'i'  , 'i'    , 'i'  , 'i'  , 'i'   , 'r' , 'r'   , 'i'  , 'r'   , 'r'   , 'c'    }, ...
                'PropDefault', {0    , 0      , 0    , 0    , 0     , 0   , 1     , 0    , 'r'   , 'r'   , 'BOTH' }, ...
                'IDProp'     , 'EID', ... 
                'Connections', {'CAERO', 'bulk.AeroPanel', 'AeroPanel', 'SETG', 'bulk.List', 'StrucNode', 'CID', 'bulk.CoordSystem', 'CoordSystem'})
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx)
            
            hg = [];
            
            if isempty(obj.AeroPanel)
                return
            end
            
            %Grab the panel data
            PanelData = getPanelData(obj.AeroPanel);
            if isempty(PanelData) || any(cellfun(@isempty, {PanelData.Coords}))
                return
            end
            
            switch obj.CardName
                case 'SPLINE1'
                    id1 = obj.BOX1;
                    id2 = obj.BOX2;
                case 'SPLINE2'
                    id1 = obj.ID1;
                    id2 = obj.ID2;
                otherwise
                    error('Update the draw method for new spline card.');
            end
            
            %Get panel numbers of splines
            panelIDs = arrayfun(@(ii) id1(ii) : id2(ii), 1 : obj.NumBulk, 'Unif', false);
            panelIDs = horzcat(panelIDs{:});
            idx      = ismember(PanelData.IDs, panelIDs);
            
            %Arrange vertex coordinates for vectorised plotting
            x = PanelData.Coords(idx, 1 : 4, 1)';
            y = PanelData.Coords(idx, 1 : 4, 2)';
            z = PanelData.Coords(idx, 1 : 4, 3)';
            
            %Plot
            hg = patch(hAx, x, y, z, ...
                'Tag'      , 'Splined Aero Panels', ...
                'FaceColor', 'c');
            plot3(hAx, ...
                PanelData.Centre(:, 1), PanelData.Centre(:, 2), PanelData.Centre(:, 3), ...
                'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g');
        end
    end
    
end

