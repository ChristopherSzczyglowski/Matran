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
    
    methods (Access = protected) % add/remove dynamic properties
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
            idx = cellfun(@isvarname, prpName);
            assert(all(idx), sprintf(['The dynamic property must be a ' , ...
                'valid variable name. The following names did not pass ', ...
                '''isvarname'':\n\n\t%s\n'], strjoin(prpName, ', ')));
            
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
            if ~ischar(prpName) || ~iscellstr(prpName)
                warning(['Expected ''prpName'' to be a variable name ', ...
                    'or a cell-string of variable names.']);
                    return
            end
            p = obj.DynamicProps(ismember({obj.DynamicProps.Name}, prpName)); 
        end
    end
        
    methods % overloaded methods for dynamic object implementation
        function tf = isequal(objA, objB)
            %isequal Checks whether the two objects have the same contents.
                        
            if eq(objA, objB) %Use superclass method
                tf = true;
                return
            else
                tf = false;
            end
            
            if ~strcmp(class(objA), class(objB))% check class
                return
            end
            propA = properties(objA);
            propB = properties(objB);
            if ~isequal(propA, propB) % check property names
                return
            end
            if isempty(propA) && isempty(propB)
                tf = true;
                return
            end
            
            %Check top-level values
%             valA = get(objA, propA);
%             valB = get(objB, propB);
%             if isequal(valA, valB)
%                 tf = true;
%                 return
%             end
            
            %Check values in every property
            idx = arrayfun(@(ii) isequal( ...
                objA.(propA{ii}), objB.(propB{ii})), 1 : numel(propA));
            tf = all(idx);
                
        end
    end
    
end

