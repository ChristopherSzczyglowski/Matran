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
%
% TODO - Change this to an entity object

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
    
end
