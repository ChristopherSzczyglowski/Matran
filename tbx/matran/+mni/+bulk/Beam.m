classdef Beam < mni.bulk.BulkData
    %Beam Describes a 1D element between 2 Nodes.
    %
    % The definition of the 'Beam' object matches that of the CBEAM bulk
    % data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'CBEAM'
    %   - 'CBAR'
    %   - 'CROD' 
    
    properties (Constant)
        ValidOffsetToken = {'GGG'};
    end
    
    methods % construction
        function obj = Beam(varargin)
                        
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CROD', ...
                'BulkProps'  , {'EID', 'PID', 'GA_GB'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i'    }, ...
                'PropDefault', {''   , ''   , ''     }, ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'GA_GB', 2}, ...
                'Connections', {'GA_GB', 'mni.bulk.Node', 'Nodes', 'PID', 'mni.bulk.BeamProp', 'Prop'}, ...
                'AttrList'   , {'GA_GB', {'nrows', 2}});
            addBulkDataSet(obj, 'CBAR', ...
                'BulkProps'  , {'EID', 'PID', 'GA_GB', 'X', 'OFFT'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i'    , 'r', 'c'}   , ...
                'PropDefault', {''   , ''   , ''     , '' , 'GGG'} , ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'GA_GB', 2, 'X', 3}, ...
                'Connections', {'GA_GB', 'mni.bulk.Node', 'Nodes', 'PID', 'mni.bulk.BeamProp', 'Prop'}, ...
                'AttrList'   , {'GA_GB', {'nrows', 2}, 'X', {'nrows', 3}}, ...
                'SetMethod'  , {'OFFT', @validateOFFT});
            addBulkDataSet(obj, 'CBEAM', ...
                'BulkProps'  , {'EID', 'PID', 'GA_GB', 'X', 'OFFT', 'PA', 'PB', 'WA', 'WB', 'SA_B'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i'    , 'r', 'c'   , 'c' , 'c' , 'r' , 'r' , 'i'}   , ...
                'PropDefault', {''   , ''   , ''     , '' , 'GGG' , ''  ,  '' , 0   , 0   , 0}     , ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'GA_GB', 2, 'X', 3, 'WA', 3, 'WB', 3, 'SA_B', 2}, ...
                'Connections', {'GA_GB', 'mni.bulk.Node', 'Nodes', 'PID', 'mni.bulk.BeamProp', 'Prop'} , ...
                'AttrList'   , {'GA_GB', {'nrows', 2}, 'X', {'nrows', 3}, 'WA', {'nrows', 3}   , ...
                'WB', {'nrows', 3}, 'SA_B', {'nrows', 2}}, ...
                'SetMethod'  , {'OFFT', @validateOFFT, 'PA', @validateDOF, 'PB', @validateDOF});
            varargin = parse(obj, varargin{:});
            preallocate(obj);
                        
        end
    end
    
    methods % assigning data during import
        function assignH5BulkData(obj, bulkNames, bulkData)
            %assignH5BulkData Assigns the object data during the import
            %from a .h5 file.
                        
            prpNames   = obj.CurrentBulkDataProps;
            
            %Index of matching bulk data names
            [~, ind]  = ismember(bulkNames, prpNames);
            [~, ind_] = ismember(prpNames, bulkNames);
            
            %Build the prop data 
            prpData  = cell(size(prpNames));            
            prpData(ind(ind ~= 0)) = bulkData(ind_(ind_ ~= 0));
            prpData{ismember(prpNames, 'GA_GB')}   = vertcat(bulkData{ismember(bulkNames, {'GA', 'GB'})});
            %N.B. 'FLAG' used in CBAR, 'F' in CBEAM
            %   - Makes absolutely no sense for the schema to use different
            %     names for what is essentially the same thing!!!!!
            if any(bulkData{ismember(bulkNames, {'FLAG', 'F'})} ~= 1) 
                error('Update code for unknown OFFSET flag');
            else
                prpData{ismember(prpNames, 'OFFT')}  = repmat({'GGG'}, [1, obj.NumBulk]);
            end            
            %Card specific
            switch obj.CardName
                case 'CBAR'
                    prpData{ismember(prpNames, 'X')}    = ...
                        vertcat(bulkData{ismember(bulkNames, {'X1', 'X2', 'X3'})});
                case 'CBEAM'
                    prpData{ismember(prpNames, 'SA_B')} = ...
                        vertcat(bulkData{ismember(bulkNames, {'SA', 'SB'})});
                    
            end
            
            assignH5BulkData@mni.bulk.BulkData(obj, prpNames, prpData)
        end
    end
    
    methods % validation
        function validateOFFT(obj, val, prpName, varargin)
            
            msg = sprintf(['Expected ''%s'' to be a cell array ', ...
                'of string with each element being one of the following '  , ...
                'tokens:\n\n\t- %s\n\n'], prpName, strjoin(obj.ValidOffsetToken, ', '));
            assert(iscellstr(val), msg); %#ok<ISCLSTR>
            assert(all(ismember(val, obj.ValidOffsetToken)), msg);
            obj.OFFT = val;

        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx)
            %drawElement Draws the beam objects as a line object between
            %the nodes and returns a single handle for all the beams in the
            %collection.
            
            hg = [];
            
            if isempty(obj.Nodes)
                return
            end
            
            coords = getDrawCoords(obj.Nodes, obj.DrawMode);            
            xA     = coords(:, obj.NodesIndex(1, :));
            xB     = coords(:, obj.NodesIndex(2, :));  
            
            hg = drawLines(xA, xB, hAx);
            
        end
    end
    
end

