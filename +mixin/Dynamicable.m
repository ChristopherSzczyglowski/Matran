classdef Dynamicable < dynamicprops
    %Dynamicable Describes an object that has dynamic properties.
    %
    % Syntax:
    %	- To add a dynamic property in a subclass method:
    %       >> prpName = 'myDynamicProp';
    %       >> addDynamicProp(obj, prpName)
    %   - To retrieve a dynamic property:
    %       >> prpName = 'myDynamicProp';
    %       >> DynProp = getDynamicProp(obj, prpName);
    %
    % Detailed Description:
    %	- When a dynamic property is added the handle of the
    %	  meta.dynamicproperty object is stored in the hidden property
    %	  'DynamicProps'. This allows the dynamic properties to be
    %	  interrogated at a future point without first obtaining the object
    %	  meta information.
    %
    % See also: dynamicprops
    %
    % References:
    %
    % Author    : Christopher Szczyglowski
    % Email     : chris.szczyglowski@gmail.com
    % Timestamp : 05-Mar-2020 10:43:34
    %
    % Copyright (c) 2020 Christopher Szczyglowski
    % All Rights Reserved
    %
    %
    % Revision: 1.0 05-Mar-2020 10:43:34
    %	- Initial function:
    %
    % <end_of_pre_formatted_H1> 
    
    properties (SetAccess = private, Hidden = true)
        %Handle of 'meta.DynamicProperty' objects
        DynamicProps
    end
    
    methods (Access = protected)
        function p = addDynamicProp(obj, prpName)
            %addDynamicProp Adds a dynamic property to the object and
            %stores a handle to the meta.dynamicproperty object in the
            %class property 'DynamicProps'.
            %
            % See also: dynamicprops.addprop
            %           meta.dynamicproperty
             
            p = [];
            
            if ~iscell(prpName)
                prpName = {prpName};
            end
            assert(all(cellfun(@isvarname, prpName)), ['The dynamic ', ...
                'property must be a valid variable name']);
            
            idx = cellfun(@(x) isprop(obj, x), prpName);
            if all(idx)
                return
            end
            prpName = prpName(~idx);

            p = cellfun(@(x) addprop(obj, x), prpName);
            
            if isempty(obj.DynamicProps)
                obj.DynamicProps = p;
            else
                obj.DynamicProps = [obj.DynamicProps, p];
            end
        end
        function p = getDynamicProp(obj, prpName)
            %getDynamicProp Returns the handle to the meta.dynamicProperty
            %object with name 'prpName'.
            
            p = [];
            if isempty(obj.DynamicProps)
                return
            end
            p = obj.DynamicProps(ismember({obj.DynamicProps.Name}, prpName)); 
        end
    end
    
end

