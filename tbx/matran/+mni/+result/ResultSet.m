classdef ResultSet < mni.mixin.Collector
    %ResultSet Collector for results objects.
    %
    %
    % See also: mni.mixin.Collector
    
    properties (Dependent)
        %Name of the result sets attached to this object
        ResultNames
    end
    
    methods % set/get
        function val = get.ResultNames(obj) %get.ResultNames
            val = obj.ItemNames;
        end
    end
    
    methods % import post-processing
        function processResultsData(obj, FEModel)
            %processResultsData
            
            validateattributes(FEModel, {'mni.bulk.FEModel'}, {'scalar'}, ...
                'convertToBasic', 'FEModel');
            
            NodalRes = getItem(obj, 'Nodal', true);
            if ~isempty(NodalRes)
                convertToBasic(NodalRes, FEModel);
            end
            
        end
    end
    
end

