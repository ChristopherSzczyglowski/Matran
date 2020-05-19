classdef (Abstract) MetaData < mni.mixin.Entity
    %MetaData Describes the meta data for a single results case.
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
    %	[1]. MSC.Nastran Getting Started Guide
    %
    % Author    : Christopher Szczyglowski
    % Email     : chris.szczyglowski@gmail.com
    % Timestamp : 14-May-2020 22:52:45
    %
    % Copyright (c) 2020 Christopher Szczyglowski
    % All Rights Reserved
    %
    %
    % Revision: 1.0 14-May-2020 22:52:45
    %	- Initial function:
    %
    % <end_of_pre_formatted_H1>
    
    %Types of results
    properties
        ResultsType = '';
    end
    properties (SetAccess = protected)
        AvailableResultsTypes = struct('Type', {}, 'Description', {});
    end    
    
    %Identifying the subcase
    properties
        SubcaseNumber
        Step
        AnalysisNumber
        Time_Freq_EigReal
        EigImaginary
        Mode
        DesignCycle
        Random
        SuperElementNumber
        AFPM
        TRMC
        INSTANCE
        MODULE
    end
    
    properties (Dependent)
        Eigenvalue
    end
    
    properties (Constant, Hidden)
        DomainFieldMap = { ...
            'SUBCASE'       , 'SubcaseNumber'      ; ...
            'STEP'          , 'Step'               ; ...
            'ANALYSIS'      , 'AnalysisNumber'     ; ...
            'TIME_FREQ_EIGR', 'Time_Freq_EigReal'  ; ....
            'EIGI'          , 'EigImaginary'       ; ...
            'MODE'          , 'Mode'               ; ...
            'DESIGN_CYCLE'  , 'DesignCycle'        ; ...
            'RANDOM'        , 'Random'             ; ...
            'SE'            , 'SuperElementNumber' ; ...
            'AFPM'          , 'AFPM'               ; ...
            'TRMC'          , 'TRMC'               ; ...
            'INSTANCE'      , 'INSTANCE'           ; ...
            'MODULE'        , 'MODULE'};
    end
    
    methods (Access = protected)
        function addResultsType(obj, type, descr)
            %addResultsType
            %
            %
            
            error('Update code');
        end
    end
    
    methods % assigning h5 data during import
        function [ResultData, lb, ub] = assignH5ResultsData(obj, filename, groupset)
            %assignH5ResultsData Assigns the domain data to each object and
            %returns the results data and the bounds for indexing.   
            %
            % We cannot do the results data assignment here as there is not
            % an exact match between the object properties and the
            % fieldnames in the H5 file.
            
            IndexData  = h5read(filename, ['/INDEX', groupset]);
            assert(numel(obj) == numel(IndexData.DOMAIN_ID), ['Expected ', ...
                'the number of Subcase objects to matchn the number of ' , ...
                'unique domains at groupset ''%s''.', groupset]);

            lb = IndexData.POSITION + 1;
            ub = IndexData.POSITION + IndexData.LENGTH;
            
            ResultData   = h5read(filename, groupset);
            DomainStruct = h5read(filename, '/NASTRAN/RESULT/DOMAINS');
            
            domainData   = struct2cell(DomainStruct);
            domainData   = double(horzcat(domainData{:})); %to allow post-processing
            domainFields = fieldnames(DomainStruct);
            domainIDs    = unique(ResultData.DOMAIN_ID);
            domNames     = obj(1).DomainFieldMap(:, 1);
            prpNames     = obj(1).DomainFieldMap(:, 2);
            
            idx_id     = ismember(domainData(:, 1), domainIDs);
            idx_prp    = ismember(domainFields, domNames);
            domainData = domainData(idx_id, idx_prp);
            
            assert(nnz(idx_id) == numel(obj), ['Expected the number ', ...
                'of unique domains to equal the number of objects in ', ...
                'groupset ''%s''.'], groupset);
            arrayfun(@(ii) set(obj, prpNames(ii), num2cell(domainData(:, ii))), 1 : numel(prpNames));
            
        end    
    end
    
end
