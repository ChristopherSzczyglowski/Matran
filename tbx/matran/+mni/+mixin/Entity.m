classdef Entity < matlab.mixin.SetGet & matlab.mixin.Heterogeneous 
    %Entity Base-class for all objects in the Matran package.
    %
    % Detailed Description:
    %   - All classes are handle class.
    %   - All classes allow 'set/get' syntax via 'matlab.mixin.SetGet'.
    %   - All classes are heterogeneous.
    %
    % See also: handle
    %           matlab.mixin.SetGet
    %           matlab.mixin.Heterogeneous
    %
    % TODO - Set Name and Type to hidden
    
    %Identifying the object
    properties %(Hidden = true) 
        %Name of the object - Must be a valid variable name to be
        %compatible with the dynamicprops implementation.
        Name
    end
    properties %(Hidden = true, Dependent)
        %Type of the object - The last term in the package list
        Type
    end
    
    methods % set / get
        function set.Name(obj, val)
            assert(isvarname(val), ['Expected ''Name'' to be a valid ', ...
                'variable name as defined by ''isvarname''.']);
            obj.Name = val;
        end
        function val = get.Name(obj)
            val = obj.Name;
            if isempty(val)
                val = obj.Type;
            end
        end
        function val = get.Type(obj)
            cls = class(obj);
            n   = max(strfind(cls, '.'));
            if isempty(n)
                n = 0;
            end
            val = cls(n + 1 : end);
        end
    end
    
    methods (Sealed) % helper functions for heterogeneous arrays 
        function varargout = set(obj,varargin)
            [varargout{1:nargout}] = set@matlab.mixin.SetGet(obj,varargin{:});
        end        
        function varargout = get(obj,varargin)
            [varargout{1:nargout}] = get@matlab.mixin.SetGet(obj,varargin{:});
        end        
    end
    
end

