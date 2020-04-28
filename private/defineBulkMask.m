function BulkDataMask = defineBulkMask()
%defineBulkMask Defines the cross-references between bulk data types and
%bulk data objects.
%
% TODO - Make this generate programtically after the test.

BulkDataMask = struct();

BulkDataMask.CORD2R  = 'bulk.CoordSystem';
BulkDataMask.GRID    = 'bulk.Node';
BulkDataMask.SPOINT  = 'bulk.Node';
BulkDataMask.EPOINT  = 'bulk.Node';
BulkDataMask.CBAR    = 'bulk.Beam';
BulkDataMask.CBEAM   = 'bulk.Beam';
BulkDataMask.CROD    = 'bulk.Beam';
BulkDataMask.PBAR    = 'bulk.BeamProp';
BulkDataMask.PBEAM   = 'bulk.BeamProp';
BulkDataMask.PROD    = 'bulk.BeamProp';
BulkDataMask.PSHELL  = 'bulk.Property';
BulkDataMask.MAT1    = 'bulk.Material';
BulkDataMask.SPC     = 'bulk.Constraint';
BulkDataMask.SPC1    = 'bulk.Constraint';
BulkDataMask.CAERO1  = 'bulk.AeroPanel';
BulkDataMask.SPLINE1 = 'bulk.AeroelasticSpline';
BulkDataMask.SPLINE2 = 'bulk.AeroelasticSpline';
BulkDataMask.CQUAD4  = 'bulk.Shell';
BulkDataMask.CTRIA3  = 'bulk.Shell';
BulkDataMask.AEFACT  = 'bulk.List';
BulkDataMask.SET1    = 'bulk.List';
BulkDataMask.ASET1   = 'bulk.List';
BulkDataMask.PAERO1  = 'bulk.List';
BulkDataMask.FLFACT  = 'bulk.List';
BulkDataMask.TABDMP1 = 'bulk.List';
BulkDataMask.TABLED1 = 'bulk.List';
BulkDataMask.TABRND1 = 'bulk.List';
BulkDataMask.CONM1   = 'bulk.Mass';
BulkDataMask.CONM2   = 'bulk.Mass';
BulkDataMask.CMASS1  = 'bulk.ScalarElement';
BulkDataMask.CMASS2  = 'bulk.ScalarElement';
BulkDataMask.CMASS3  = 'bulk.ScalarElement';
BulkDataMask.CMASS4  = 'bulk.ScalarElement';
BulkDataMask.CELAS1  = 'bulk.ScalarElement';
BulkDataMask.CELAS2  = 'bulk.ScalarElement';
BulkDataMask.AERO    = 'bulk.AnalysisData';
BulkDataMask.EIGR    = 'bulk.AnalysisData';
BulkDataMask.EIGRL   = 'bulk.AnalysisData';
BulkDataMask.FLUTTER = 'bulk.AnalysisData';
BulkDataMask.FREQ1   = 'bulk.AnalysisData';
BulkDataMask.RANDPS  = 'bulk.AnalysisData';
BulkDataMask.MKAERO1 = 'bulk.AnalysisData';

end