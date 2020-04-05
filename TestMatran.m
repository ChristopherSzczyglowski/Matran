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
    %       + Checking codebase
    %           constructBulk
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
    %
    %
    
    %Importing
    properties (TestParameter)
        %Files from the Nastran TPL for testing import from raw text file.
        TPLTextImportFiles = { ...
            '\doc\dynamics\bd03bar1.dat', ... %simple beam
            '\doc\dynamics\bd03car.dat' , ... %car frame model
            '\doc\dynamics\bd03fix.dat' , ... %test fixture
            'aero\ha75b.dat'            , ... %BAH jet transport PK flutter analysis
            'aero\ha76b.dat'            , ... %BAH jet transport enforced aileron displacement
            'aero\ha76c.dat'            , ... %BAH jet transport random gust 
            'aero\ha75f.dat'            , ... %NASA TN D-1824 PK flutter analysis
            '\aero\ha145z.dat'}; %NASA TN D-1824 
        TextImportFiles = { ...
            'uob_HARW\wing_model_R.bdf'}; %HARW wing
    end
    properties (SetAccess = private)
        TestFigure
        UnknownBulk = {};
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
                if isnumeric(val)
                    val = [];
                else
                    setpref('matran', 'PathToNastranTPL', val);
                end
            end
        end        
    end
    
    methods % construction
        function obj = TestMatran(varargin)
            
            p = inputParser;
            addParameter(p, 'CheckBulkCoverage', false, @(x)validateattributes(x, {'logical'}, {'scalar'}));
            parse(p, varargin{:});
            
            if p.Results.CheckBulkCoverage
                checkBulkCoverage(obj);
            end
            
        end
    end
    
    methods % helper methods for executing tests
        function TestResults = runSomeTests(obj, testNames)
            %runSomeTests Runs all tests whose procedure name matches the
            %tokens in 'testNames'.
            
            if nargin < 2 %run all tests
                testNames = getTestNames(obj);
            end
            %#ok<*ISCLSTR>
            obj.parseTestNames(testNames);
            
            TestSuite   = getTestSuite(obj, testNames);
            TestResults = run(TestSuite);
        end
        function TestSuite = getTestSuite(obj, testNames)
            %getTestSuite Returns an array of 'matlab.unittest.Test'
            %objects with procedure name matching 'testNames'.
            
            if nargin < 2 %run all tests
                testNames = getTestNames(obj);
            end
            obj.parseTestNames(testNames);
            
            TestSuite  = matlab.unittest.TestSuite.fromClass(metaclass(obj));
            idx        = contains({TestSuite.ProcedureName}, testNames);
            TestSuite  = TestSuite(idx);
        end
        function testNames = getTestNames(obj)
            %getTestNames Returns a cell-string containing the names of all
            %test methods in the class.
            
            mc        = metaclass(obj);
            tdx       = arrayfun(@(x)isprop(x, 'Test') && x.Test, mc.MethodList);
            testNames = {mc.MethodList(tdx).Name};
        end
    end
    methods (Static)
        function parseTestNames(testNames)
            assert(iscellstr(testNames), ['Expected ''testNames'' to ', ...
                'be a cell-array containing the names of test proceudres.']);
        end
    end
    
    %% Executing multiple tests
    
    methods % checking bulk data coverage
        function checkBulkCoverage(obj)
            %checkBulkCoverage Runs all tests that involve importing bulk
            %data from input files and returns a list of all bulk data
            %types that were not recognised.
            %
            % See also: https://www.mathworks.com/help/matlab/matlab_prog/write-plugin-to-add-data-to-test-results.html
            
            return
            
            tn = getTestNames(obj);
            tn = tn(contains(tn, 'import'));
            TS = getTestSuite(obj, tn);
            
            Runner = matlab.unittest.TestRunner.withNoPlugins;
            Runner.addPlugin(DetailsRecordingPlugin)
            
            TR = Runner.run(TS);
            
        end
        function val = getUniqueUnknownBulk(obj)
            blk = {obj.UnknownBulk};
            val = unique(horzcat(blk{:}));
        end
    end
    
    %% Tests
    
    %Test bulk class construction
    methods (Test)
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
    methods (Static)
        function bulkClasses = getBulkClasses
            %getBulkClasses Returns a list of all bulk data classes in the
            %+bulk package.
            
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
    
    %Importing
    methods (Test)
        function importFromTPLTextFile(obj, TPLTextImportFiles)
            %importFRomTPLTextFile Attempts to import a FE model from a
            %text file contained in the Nastran Test Problem Library (TPL).
            
            %If the location of the Test Problem Library is unset then quit
            tpl = obj.PathToNastranTPL;
            if isempty(tpl)
                return
            end
            
            importThenDraw(obj, fullfile(tpl, TPLTextImportFiles))
        end
        function importFromTextFile(obj, TextImportFiles)
            %importFRomTPLTextFile Attempts to import a FE model from a
            %text file using the standard Nastran input format.
            
            %Assume the file is contained in the 'models' directory
            importThenDraw(obj, fullfile(pwd, 'models', TextImportFiles));
        end
    end
    methods (TestMethodTeardown)
        function closeFigures(obj)
            if isa(obj.TestFigure, 'matlab.ui.Figure')
                close(obj.TestFigure);
            end
        end
    end
    methods (Access = private)
        function importThenDraw(obj, filename)
            %importThenDraw Imports the model from the Nastran text file
            %'filename' and draws the model.
            
            [FEM, Meta]  = importBulkData(filename);
            
            obj.UnknownBulk = Meta.UnknownBulk;
            
            hg = draw(FEM);
            
            %Stash the figure
            hF = ancestor(hg, 'figure');
            if iscell(hF)
                hF = unique(vertcat(hF{:}));
            end
            if isempty(hF)
                hF = gcf;
            end
            obj.TestFigure = hF;
        end
    end
    
end
