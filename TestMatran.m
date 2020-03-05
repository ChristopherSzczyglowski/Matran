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
    %
    % See also: matlab.unittest.TestCase
    %
    % References:
    %	[1]. "Can quantum-mechanical description of physical reality be
    %         considered complete?", A Einstein, Physical Review 47(10):777,
    %         American Physical Society 1935, 0031-899X
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
        TextImportFiles = {'C:\Program Files\MSC.Software\MSC_Nastran_Documentation\20180\tpl\doc\dynamics\bd03bar1.dat'};
    end
    
    methods (Test)
        function importFromTextFile(obj, TextImportFiles)
            FEM = importBulkData(TextImportFiles);
            draw(FEM);
        end
    end
    
end
