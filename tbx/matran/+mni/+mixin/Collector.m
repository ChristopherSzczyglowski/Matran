classdef Collector < mni.mixin.Entity & mni.mixin.Dynamicable
    %Collector Handles a collection of data by assigning dynamic properties
    %each time a new object type is added to the collection.
    %
    % Detailed Description:
    %   - The 'AssignMethod' must return the object which will be assigned to the dynamic property.
    
    %Tracking the collection
    properties (SetAccess = private, Hidden = true)
        ItemNames = {};
    end
    properties (Dependent, Hidden = true)
        %Cellstr of class names for each object in the collection
        ItemClass
        %Cellstr of unique class names across all objects in the collection
        UniqueClass
        %Cellstr of item types for each object in the collection
        ItemType
        %Cellstr of unique types across all objects in the collection
        UniqueType
    end
    
    %Controlling the contents of the collection
    properties (SetAccess = protected)
        %Name of class which can be collected by this object
        CollectionClass       = 'mni.mixin.Entity';
        %Descriptor of the class which can be collected
        CollectionDescription = 'matran entity';
        %Method used to assign multiple sets of data to the same property
        AssignMethod          = @horzcat;
    end
    
    methods % set / get
        function val = get.ItemClass(obj)   %get.ItemClass
            val = cellfun(@(x) class(obj.(x)), obj.ItemNames, 'Unif', false);
        end
        function val = get.UniqueClass(obj) %get.UniqueClass
            val = unique(obj.ItemClass, 'stable');
        end
        function val = get.ItemType(obj)    %get.ItemType
            val = getEntityType(obj, obj.ItemClass);
        end
        function val = get.UniqueType(obj)  %get.UniqueType
            val = getEntityType(obj, obj.UniqueClass);
        end
    end
    
    methods (Sealed) % adding/removing/retrieving items from the collection
        function addItem(obj, item)
            %addItem Adds an item to the collection.
            %
            % Syntax:
            %   - Adding a single item to the collection:
            %       >> Bar = mni.bulk.Beam('CBAR', 50)
            %       >> addItem(obj, Bar);
            %   - Adding multiple items to the collection
            
            assert(numel(obj) == 1, ['Method ''addItem'' is not valid ', ...
                'for object arrays.']);
            if numel(item) > 1
                allClass = arrayfun(@class, item, 'Unif', false);
                if numel(unique(allClass)) > 1
                    error('Update code to heterogenous arrays');
                    %Loop through each different class and add the items
                    %arrayfun(@(i) addItem(obj, i), item);
                    %return
                end
            end
            if ~isa(item, obj.CollectionClass)
                warning(['Expected the %s object to be an instance ', ...
                    'of the %s class, instead it was of class %s']  , ...
                    obj.CollectionDescription, obj.CollectionClass, class(item));
                return
            end
            
            nam = get(item ,{'Name'});
            nam = unique(nam);
            if numel(nam) > 1
                error('Update code for heterogeneous arrays');
            end
            nam = nam{:};
            if isempty(nam)
                warning(['Unable to add the item of class %s to the ', ...
                    'collection as no name has been assigned.'], class(item));
                return
            end
            
            if isprop(obj, nam)
                obj.(nam)     = obj.AssignMethod([obj.(nam), item]);
            else
                addDynamicProp(obj, nam);
                obj.(nam)     = item;
                obj.ItemNames = [obj.ItemNames, {nam}];
            end
            
        end
        function item = getItem(obj, tok, bReturnObjectArray)
            %getItem Retrieves the handle to an item in the collection. 
            %
            % Detailed Description: 
            %   - Multiple items can be retrieved by passing in a cell-str
            %     of tokens. 
            %   - Items can be retrieved based on Class, Name, Type or a 
            %     combination of the three. 
            %   - If none of the tokens match then an empty array is 
            %     returned. 
            %
            % TODO - Consider whether we want to only select the unique
            % tokens or allow the user to search for duplicates.
            
            item = [];
            if nargin < 2
                return
            end
            if nargin < 3
                bReturnObjectArray = false;
            end
            if ~iscell(tok)
                tok = {tok};
            end
            if ~iscellstr(tok)
                return
            end
            
            item = cell(size(tok));
            
            names       = obj.ItemNames;
            [item, tok] = getItemFromCollection(obj, names, names, tok, item);
            if all(cellfun(@isempty, tok))
                if bReturnObjectArray
                    item = horzcat(item{:});
                end
                return
            end
            
            classes     = obj.ItemClass;
            [item, tok] = getItemFromCollection(obj, names, classes, tok, item);
            if all(cellfun(@isempty, tok))
                if bReturnObjectArray
                    item = horzcat(item{:});
                end
                return
            end
            
            types       = obj.ItemType;
            [item, tok] = getItemFromCollection(obj, names, types, tok, item);
            
            if bReturnObjectArray && all(cellfun(@isempty, tok))
                item = horzcat(item{:});
            end
            if ~all(cellfun(@isempty, tok))
                item = [];
            end
                        
            function [item, tok] = getItemFromCollection(obj, dyn_prop_names, list, tok, item)
                %getItemFromCollection Retrieves an item from the
                %collection using the index 'tok' which can be found in the
                %lookup table 'list'.
                %
                % N.B. The dynamic property names are used to actually
                % retrive the data. The mapping between 'dyn_prop_names'
                % and 'list' is direct.
                
                [idx_a, ia] = ismember(list, tok);
                idx_b       = ismember(tok, list(idx_a));
                item(idx_b) = get(obj, dyn_prop_names(idx_a));
                tok(idx_b)  = {''};
                %ind       = ia(idx_a);
                %item(ind) = get(obj, names(idx_a));
                %tok(ind)  = [];                
            end
        end
        function item = removeItem(obj, item)
            %removeItem TODO
        end
    end
    
end

