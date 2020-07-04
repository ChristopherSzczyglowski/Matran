classdef Nodal < mni.result.MetaData
%Nodal Describes a results quantity which is defined in all six degrees of
%freedom of a Node.
%
% Syntax:
%	- Brief explanation of the syntax...
%
% Detailed Description:
%	- Detailed explanation of the function and how it works...
%
% See also: 
%
% References:
%	[1]. MSC.Nastran Getting Started User Guide.
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 14-May-2020 22:51:00
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 14-May-2020 22:51:00
%	- Initial function:
%
% <end_of_pre_formatted_H1>

    %Results data
    properties
        %ID number of the node
        ID = nan;
        %Translation of the node in the local coordinate system
        Translation = zeros(3, 1);
        %Rotation of the node in the local coordinate system
        Rotation = zeros(3, 1);       
    end        
    properties (SetAccess = protected)
        %Translation in the MSC.Nastran Basic coordinate system
        BasicTranslation
        %Rotation in the MSC.Nastran Basic coordinate system
        BasicRotation
    end
    
    methods % set / get
        function set.ID(obj, val)           %ID
            validateattributes(val, {'numeric'}, {'row'}, class(obj), 'ID');
            obj.ID = val;
        end
        function set.Translation(obj, val)  %Translation
            validateattributes(val, {'numeric'}, {'2d', 'nrows', 3}, ...
                class(obj), 'Translation');
            obj.Translation = val;
        end
        function set.Rotation(obj, val)     %Rotation
            validateattributes(val, {'numeric'}, {'2d', 'nrows', 3}, ...
                class(obj), 'Rotation');
            obj.Rotation = val;
        end
    end
        
    methods % assigning h5 data during import
        function assignH5ResultsData(obj, filename, groupset)
            %assignH5ResultsData
            
            [ResultData, lb, ub] = assignH5ResultsData@mni.result.MetaData(obj, filename, groupset);
            
            for ii = 1 : numel(lb)
                ind = lb(ii) : ub(ii);
                obj(ii).ID          = ResultData.ID(ind)';
                obj(ii).Translation = [ ...
                    ResultData.X(ind), ResultData.Y(ind), ResultData.Z(ind)]';
                obj(ii).Rotation    = [ ...
                    ResultData.RX(ind), ResultData.RY(ind), ResultData.RZ(ind)]';
            end
        end
    end
    
    methods (Sealed) %convertToBasic
        function convertToBasic(obj, FEModel)
            %convertToBasic Converts any nodal results quantities from the
            %local coordinate system into the basic coordinate system.
            %
            % TODO - Add logger here to show progress of transforming
            % coordinate systems.
            
            bValid = not(any(any([ ...
                cellfun(@isempty, get(obj, {'Translation'})), ...
                cellfun(@isempty, get(obj, {'Translation'})), ...
                cellfun(@(x) all(isnan(x)), get(obj, {'ID'}))])));            
            if ~bValid
                return
            end
            
            validateattributes(FEModel, {'mni.bulk.FEModel'}, {'scalar'}, ...
                'convertToBasic', 'FEModel');
            
            Nodes    = getItem(FEModel, 'GRID', true);
            CoordSys = getItem(FEModel, 'mni.bulk.CoordSystem', true);
            if isempty(Nodes)   
                i_print_warn(FEModel, 'Node');
                return
            end
            if isempty(CoordSys)
                i_print_warn(FEModel, 'CoordSys');
               return 
            end
            
            function i_print_warn(FEM, type)
                warning(['Unable to convert results data to basic '    , ...
                    'coordinate system as the FEModel ''%s'' does not ', ...
                    'have any %s objects.'], FEM.Name, type);
            end
            
            %If there are no non-basic coordinate systems then we have nothing to do                    
            if ~any(Nodes.CD)
                return
            end
            
            uid   = unique([obj.ID]);        %nodes with results
            idxID = ismember(Nodes.ID, uid); %model nodes with results          
            cid   = Nodes.CD(Nodes.CD(idxID) ~=0);
                        
            rmat = getRotationMatrix(CoordSys);
            assert(~isempty(rmat), ['Unable to convert displacements ', ...
                'to basic coordinate system as the rotation matrix '  , ...
                'could not be calculated.']);
            
            for ii = 1 : numel(obj)
                trans = num2cell(obj(ii).Translation, 1);
                rot   = num2cell(obj(ii).Rotation   , 1);
                cid_  = Nodes.CD(Nodes.ID == obj(ii).ID);
                ucid_ = unique(cid_(cid_ ~= 0));
                for jj = 1 : numel(ucid_)                    
                    idx_res = cid_ == ucid_(jj);
                    rmat_   = rmat(:, :, cid == ucid_(jj));
                    t_basic = rmat_ * horzcat(trans{idx_res});
                    r_basic = rmat_ * horzcat(rot{idx_res});
                    trans(idx_res) = num2cell(t_basic, 1);
                    rot(idx_res)   = num2cell(r_basic, 1);
                end
                obj(ii).BasicTranslation = horzcat(trans{:});
                obj(ii).BasicRotation    = horzcat(rot{:});
            end
            
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx, FEModel)
            %drawElement 
            %
            % TODO - Need an option to draw a new graphics object or select
            % existing graphics data and update (X,Y,Z) data
            
            hg = [];
            
            if numel(obj) > 1
                error('''drawElemenet'' is not suitable for object arrays.');
            end           
            if isempty(hAx)
                hF  = figure('Name', 'Finite Element Model');
                hAx = axes('Parent', hF, 'NextPlot', 'add', 'Box', 'on');
                xlabel(hAx, 'X');
                ylabel(hAx, 'Y');
                zlabel(hAx, 'Z');
            end
            validateattributes(hAx, {'matlab.graphics.axis.Axes'}, {'scalar'}, class(obj), 'hAx');
            validateattributes(FEModel, {'mni.bulk.FEModel'}, {'scalar'}, ...
                'drawElement', 'FEModel');
            
            Nodes = getItem(FEModel, 'GRID', true);
            if isempty(Nodes)
                return
            end
            
            hNode = findobj(hAx, 'Tag', 'Nodes');
            if isempty(hNode)
                hNode = drawElement(Nodes, hAx);
            end

            coords = ...
                Nodes.X(:, ismember(Nodes.ID, obj.ID)) + ...
                obj.BasicTranslation; % * scale_factor
            
            %Only adjust the data in the results
            %id = getbulkID(obj, hg);
            %idx = ismember(id, obj.ID);
            xd = hNode.XData;
            yd = hNode.YData;
            zd = hNode.ZData;            
%             xd(idx) = coords(1, :);
%             yd(idx) = coords(2, :);
%             zd(idx) = coords(3, :);            
            xd = coords(1, :);
            yd = coords(2, :);
            zd = coords(3, :);            
            
            set(hNode, 'XData', xd, 'YData', yd, 'ZData', zd);
            
        end
    end
    
end
