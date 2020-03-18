classdef TestMatran < matlab.unittest.TestCase
    %TestMatran Unit test class for the MatTran package.
    %
    % Syntax:
    %   - Run all unit tests.
    %       >> TC = TestMatran;
    %       >> TestResults = run(TC);
    %
    % Detailed Description:
    %	- Available tests:
    %       + Importing models
    %           ImportFromTPLTextFile
    %   - To run the test 'ImportFromTPLTextFile' the user must set the
    %     preference 'PathToNastranTPL' on their local user profile. This 
    %     can  be done via:
    %       >> setpref('matran', 'PathToNastranTPL', <pathToTPL>);
    %   The TPL is typically found at
    %       C:\Program Files\MSC.Software\MSC_Nastran_Documentation\20180\tpl
    %   where "20180" is the version number.
    %
    % See also: matlab.unittest.TestCase
    %
    % References:
    %	[1]. MSC.Nastran Quick Reference Guide
    %
    % Author    : Christopher Szczyglowski
    % Email     : chris.szczyglowski@gmail.com
    % Timestamp : 04-Mar-2020 13:30:37
    %
    % Copyright (c) 2020 Christopher Szczyglowski
    % All Rights Reserved
    %
    %
    % Revision: 1.0 04-Mar-2020 13:30:37
    %	- Initial function:
    %
    % <end_of_pre_formatted_H1>
    
    properties (TestParameter)
        %Files from the Nastran TPL for testing import from raw text file.
        TPLTextImportFiles = { ...
            '\doc\dynamics\bd03bar1.dat', ... %simple beam
            '\doc\dynamics\bd03car.dat' , ... %car frame model
            '\doc\dynamics/bd03fix.dat' , ... %test fixture
            'aero\ha75b.dat'}; %airplane
    end
    
    properties (Dependent)
        %Path to the Nastran TPL. User dependent via setpref/getpref
        PathToNastranTPL
    end
    
    methods % set / get
        function val = get.PathToNastranTPL(~)
            if ispref('matran', 'PathToNastranTPL')
                val = getpref('matran', 'PathToNastranTPL');
            else
                val = uigetdir('C:\Program Files', 'Please select the folder location of the Nastran Test Problem Library');
                setpref('matran', 'PathToNastranTPL', val);
            end
        end
    end
    
    methods (Test) % test bulk class construction
        function constructBulk(obj)
            %constructBulk Checks that each bulk data object can be
            %constructed with different levels of input.
            
            nBulk = 10;
            
            %Get list of all bulk objects
            bulkClasses = obj.getBulkClasses;
            
            %Make an instance of each object with no inputs
            for ii = 1 : numel(bulkClasses)
                func = str2func(bulkClasses{ii});
                %Initiate with no inputs
                bulkObj = func();
                if ~isa(bulkObj, 'bulk.BulkData')
                    func();
                    continue
                end
                %Check each bulk data type
                vn = bulkObj.ValidBulkNames;
                for jj = 1 : numel(vn)
                    func(vn{jj});        %one input
                    func(vn{jj}, nBulk); %two inputs
                end
            end
            
        end
    end
    
    methods (Test) % importing
        function importFromTPLTextFile(obj, TPLTextImportFiles)
            %importFRomTPLTextFile Attempts to import a FE model from a
            %text file contained in the Nastran Test Problem Library (TPL).
            
            file = fullfile(obj.PathToNastranTPL, TPLTextImportFiles);
            FEM  = importBulkData(file);
            draw(FEM);
        end
    end
    
    methods (Static) % helper functions
        function bulkClasses = getBulkClasses
            
            %Get location of the +bulk folder
            loc = fullfile(fileparts(mfilename('fullpath')), '+bulk');
            
            %Find all classes in the +bulk package folder
            contents = dir(loc);
            
            fNames = cell(1, numel(contents));
            for ii = 1 : numel(fNames)
                [~, fNames{ii}, ~] = fileparts(contents(ii).name);
            end
            fNames = strcat('bulk.', fNames);
            val = cellfun(@(x) exist(x, 'class'), fNames);
            bulkClasses = fNames(val ~= 0);
            
            assert(~isempty(bulkClasses), ['No classes found in the ', ...
                '+bulk package folder. Check the codebase.']);
            
        end
    end
    
end
