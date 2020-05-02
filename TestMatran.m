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
    %           importFromTPLTextFile
    %           importFromTextFile
    %           importFromAutoH5File
    %       + Checking codebase
    %           constructBulk
    %           drawEmptyBulk
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
    % TODO - Add a test which runs every public method on a new object.
    % Should be no errors!
    % TODO - Get log file working
    
    %Importing
    properties (TestParameter) % model files
        %Files from the Nastran TPL for testing import from raw text file.
        TPLTextImportFiles = { ...
            '\doc\dynamics\bd03bar1.dat', ... %simple beam
            '\doc\dynamics\bd03car.dat' , ... %car frame model
            '\doc\dynamics\bd03fix.dat' , ... %test fixture
            'aero\ha75b.dat'            , ... %BAH jet transport PK flutter analysis
            'aero\ha76b.dat'            , ... %BAH jet transport enforced aileron displacement
            'aero\ha76c.dat'            , ... %BAH jet transport random gust 
            'aero\ha75f.dat'            , ... %NASA TN D-1824 PK flutter analysis
            'aero\ha145z.dat'}; %NASA TN D-1824 
        %Custom files which will be shipped with the repo
        TextImportFiles = { ...
            'uob_HARW\wing_model_R.bdf', ...                %HARW wing
            'uob_HARW_wide_field\sol_103_pod_fwd_pc.dat'};  %HARW wing (wide-field)       
        %Auto-generated .h5 files from the 'models' folder
        AutoH5Files = getH5files;
    end
    
    properties (TestParameter) % import parameters
        %Function handle to logging function
        LogFcn  = {@logger}; %, 'diary.txt'};
        %Toggle printing output 
        Verbose = {true, false};
    end
    properties (SetAccess = private)
        TestFigure
        UnknownBulk = {};
    end
    
    properties (Dependent)
        %Path to the Nastran TPL. User dependent via setpref/getpref
        PathToNastranTPL 
        %Unison of 'TPLTextImportFiles' and 'TextImportFiles'
        AllTextImportFiles
    end
    
    methods % set / get
        function set.TestFigure(obj, val)
            if isempty(obj.TestFigure)
                obj.TestFigure = val;
            else
                obj.TestFigure = [obj.TestFigure, val];
            end
        end
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
        function val = get.AllTextImportFiles(obj)
            val = getAllTextImportFiles(obj);
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
            
            sldiagviewer.diary
            
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
            % Detailed Description:
            %   - Uses a plugin to record additional data in the 'Details'
            %     structure of the TestResults object.
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
    
    %Test object methods 
    methods (Test)
        function drawEmptyBulk(obj)
            %drawEmptyBulk Checks that each bulk data object can be
            %drawn from a basic constructor call.
            
            obj.TestFigure = figure;
            hAx = axes('Parent', obj.TestFigure);
            
            %Get list of all bulk objects
            bulkClasses = obj.getBulkClasses;
            
            %Make an instance of each object with no inputs
            for ii = 1 : numel(bulkClasses)
                func = str2func(bulkClasses{ii});
                %Initiate with no inputs
                bulkObj = func();
                %Make sure we can draw it
                mc = metaclass(bulkObj);
                if ~ismember('drawElement', {mc.MethodList.Name})
                    continue
                end
                drawElement(bulkObj, hAx);
            end
        end
        function testDynamicable_isequal_self_empty(obj)
            
            %Check itself against itself
            DynA = mixin.Dynamicable;
            assert(isequal(DynA, DynA), '''isequal'' failed for same object');      
        end
        function testDynamicable_isequal_two_empty(obj)
            
            %Check itself against another empty
            DynA = mixin.Dynamicable;
            DynB = mixin.Dynamicable;            
            assert(isequal(DynA, DynB), '''isequal'' failed for two empties');            
        end
        function testDynamicable_isequal_bulk(obj)
            
            %Get list of all bulk objects
            bulkClasses = obj.getBulkClasses;
            
            %Make an instance of each object and check equality
            for ii = 1 : numel(bulkClasses)                
                func = str2func(bulkClasses{ii});                
                BulkA = func();
                BulkB = func();
                assert(isequal(BulkA, BulkB), sprintf(['''isequal'' ', ...
                    'failed for two empty bulk objects of class %s'] , ...
                    bulkClasses{ii})); 
            end
        end
    end

    %Importing
    methods (Test, ParameterCombination = 'exhaustive')
        function importFromTPLTextFile(obj, TPLTextImportFiles)
            %importFRomTPLTextFile Attempts to import a FE model from a
            %text file contained in the Nastran Test Problem Library (TPL).
            
            %If the location of the Test Problem Library is unset then quit
            TPLTextImportFiles = getFilePath(obj, TPLTextImportFiles, 'tpl');
            if isempty(TPLTextImportFiles)
                warning(['Update the ''PathToNastranTPL'' preference ', ...
                    'to access files in the Nastran Test Problem Library']);                
                return
            end
            
            importThenDraw(obj, TPLTextImportFiles);
        end
        function importFromTextFile(obj, TextImportFiles)
            %importFromTPLTextFile Attempts to import a FE model from a
            %text file using the standard Nastran input format.
            
            %Assume the file is contained in the 'models' directory
            TextImportFiles = getFilePath(obj, TextImportFiles, 'model');
            importThenDraw(obj, TextImportFiles);
        end        
        function importFromAutoH5File(obj, AutoH5Files)
            %importFromAutoH5File Attempts to import a FE model from a
            %MSC.Nastran HDF5 file.
            importThenDraw(obj, AutoH5Files);            
        end
        function importBdfAndH5ThenCompare(obj, AutoH5Files)
            %importBdfAndH5ThenCompare Attempts to import a FE model from a
            %text file from the TPL and the associated MSC.Nastran HDF5 
            %file, then compares the two FEMs for equality.
            
            %Get the corresponding bdf import file
            [~, nam, ~]  = fileparts(AutoH5Files);
            allTextFiles = obj.AllTextImportFiles;
            [~, txtNames, ~] = obj.getFileParts(allTextFiles);     
            idx = ismember(strcat(txtNames, '_temp'), nam);
            assert(nnz(idx) == 1, sprintf(['Unable to find the text '  , ...
                'import file that corresponds to the .h5 file ''%s''.'], ...
                AutoH5Files));
            txtFile = allTextFiles{idx};
            
            %Import then compare
            FEM_bdf = importThenDraw(obj, txtFile);            
            FEM_h5  = importThenDraw(obj, AutoH5Files);
            if ~isequal(FEM_bdf, FEM_h5)
                %If the FEMs are inequal it is likely 
                prp_bdf = FEM_bdf.BulkDataNames;
                prp_h5  = FEM_h5.BulkDataNames;
                prp_all = unique([prp_bdf, prp_h5]);
                idxH5  = ~ismember(prp_all, prp_h5);
                idxBDF = ~ismember(prp_all, prp_bdf);
                if any(idxH5) || any(idxBDF)
                    error('matlab:matran:unequal_FEM', ['The two FEMs are ', ...
                        'not equal.\n\n\tH5 file: %s\n\tBDF file: %s\n\n\t', ...
                        'Bulk not in the h5 file:\n\t- %s\n\n\t', ...
                        'Bulk not in the bdf file:\n\t- %s\n\n'], ...
                        AutoH5Files, txtFile, ...
                        strjoin(prp_all(idxH5) , ', '), ...
                        strjoin(prp_all(idxBDF), ', '));
                end
            end
        end
        function testImportParameters(obj, LogFcn, Verbose)
            %testImportParameters Tests the different import parameters for
            %the 'import_matran' function.
            
            h5Files  = obj.AutoH5Files;
            filename = h5Files{1};
            
            if ischar(LogFcn)
                fid = fopen(LogFcn, 'w');
                LogFcn = @(fid)logger([], [], [], fid);
                bClose = true;
            else
                bClose = false;
            end
            
            import_matran(filename, 'Verbose', Verbose, 'LogFcn', LogFcn);
            if bClose
                fclose(fid);
            end
        end
    end
    methods (TestMethodTeardown)
        function closeFigures(obj)
            if isa(obj.TestFigure, 'matlab.ui.Figure')
                close(obj.TestFigure);
            end
        end
    end
    methods % getFilePath
       function filename = getFilePath(obj, filename, type)
            %getFilePath Helper method for providing the full-file path
            %based on whether the file is part of the Nastran TPL or is
            %pacakged in the 'models' subdirectory.
            switch lower(type)
                case 'tpl'
                    loc = obj.PathToNastranTPL;
                    if isempty(loc)
                        filename = [];
                        return
                    end                    
                case 'model'
                    %loc = fileparts(matlab.desktop.editor.getActiveFilename);
                    loc = fileparts(mfilename('fullpath'));
                    loc = fullfile(loc, 'models');
                otherwise 
                    validatestring(filename, {'tpl', 'model'});
            end            
            filename = fullfile(loc, filename);
       end 
       function txtFiles = getAllTextImportFiles(obj, bSort)
           %getAllTextImportFiles Returns the complete list of the TPL and
           %MODEL import files.
           %
           % If 'bSort' = true the text import files are matched against
           % the list of .h5 files returned by 'getH5files'.
           
           if nargin < 2
               bSort = false;
           end
           tplFiles = getFilePath(obj, obj.TPLTextImportFiles, 'tpl');
           mdlFiles = getFilePath(obj, obj.TextImportFiles   , 'model');
           txtFiles = horzcat(tplFiles, mdlFiles);
           
           if bSort %Sort w.r.t h5 file list
               h5Files  = getH5files;
               %TODO - Run check to see what files are missing.
               assert(numel(txtFiles) == numel(h5Files), ['Expected '   , ...
                   'there to be the same number of .bdf and .h5 files. ', ...
                   'Make sure all text import cases have been run to '  , ...
                   'generate the corresponding .h5 files.']);
               %Get the name of each file and use it to sort the list
               [~, bdfNames, ~] = obj.getFileParts(txtFiles);
               [~, index]       = sort(bdfNames);
               txtFiles         = txtFiles(index);
           end
           
       end
    end
    methods (Access = private) % importThenDraw
        function FEM = importThenDraw(obj, filename)
            %importThenDraw Imports the model from the Nastran text file
            %'filename' and draws the model.
            
            FEM = import_matran(filename, 'Verbose', false);
            
            %obj.UnknownBulk = Meta.UnknownBulk;
            
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
    
    methods (Static)
        function [path, nam, ext] = getFileParts(files)
            %getFileParts Returns a cell-array of file paths, names and
            %extensions from a cell-array of fully-qualified files.
            ind_sep = cellfun(@(x) strfind(x, filesep), files, 'Unif', false);
            ind_ext = cellfun(@(x) strfind(x, '.')    , files, 'Unif', false);
            ind_sep(cellfun(@isempty, ind_sep)) = {0};
            ind_sep = cellfun(@max, ind_sep);
            ind_ext = cellfun(@max, ind_ext);
            path = arrayfun(@(ii) files{ii}(1 : ind_sep(ii)), ...
                1 : numel(ind_sep), 'Unif', false);
            nam  = arrayfun(@(ii) files{ii}(ind_sep(ii) + 1 : ind_ext(ii) - 1), ...
                1 : numel(ind_sep), 'Unif', false);
            ext  = arrayfun(@(ii) files{ii}(ind_ext(ii) : end), ...
                1 : numel(ind_sep), 'Unif', false);
        end
    end
    
end

function h5FileList = getH5files
%getH5files Get the list of .h5 files in the
%'models\auto_generated_h5_data' directory sorted in alphabetical order.

path = 'models\auto_generated_h5_data';
Contents = dir(path);
idx = endsWith({Contents.name}, '.h5');
h5FileList = fullfile(path, sort({Contents(idx).name}));

end
