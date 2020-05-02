function BulkDataMask = defineBulkMask()
%defineBulkMask Defines the cross-references between bulk data types and
%bulk data objects.
%
% TODO - Make this generate programtically after the test.

BulkDataMask = struct();

BulkDataMask.CORD2R  = 'mni.bulk.CoordSystem';
BulkDataMask.GRID    = 'mni.bulk.Node';
BulkDataMask.SPOINT  = 'mni.bulk.Node';
BulkDataMask.EPOINT  = 'mni.bulk.Node';
BulkDataMask.CBAR    = 'mni.bulk.Beam';
BulkDataMask.CBEAM   = 'mni.bulk.Beam';
BulkDataMask.CROD    = 'mni.bulk.Beam';
BulkDataMask.PBAR    = 'mni.bulk.BeamProp';
BulkDataMask.PBEAM   = 'mni.bulk.BeamProp';
BulkDataMask.PROD    = 'mni.bulk.BeamProp';
BulkDataMask.PSHELL  = 'mni.bulk.Property';
BulkDataMask.MAT1    = 'mni.bulk.Material';
BulkDataMask.SPC     = 'mni.bulk.Constraint';
BulkDataMask.SPC1    = 'mni.bulk.Constraint';
BulkDataMask.CAERO1  = 'mni.bulk.AeroPanel';
BulkDataMask.SPLINE1 = 'mni.bulk.AeroelasticSpline';
BulkDataMask.SPLINE2 = 'mni.bulk.AeroelasticSpline';
BulkDataMask.CQUAD4  = 'mni.bulk.Shell';
BulkDataMask.CTRIA3  = 'mni.bulk.Shell';
BulkDataMask.AEFACT  = 'mni.bulk.List';
BulkDataMask.SET1    = 'mni.bulk.List';
BulkDataMask.ASET1   = 'mni.bulk.List';
BulkDataMask.PAERO1  = 'mni.bulk.List';
BulkDataMask.FLFACT  = 'mni.bulk.List';
BulkDataMask.TABDMP1 = 'mni.bulk.List';
BulkDataMask.TABLED1 = 'mni.bulk.List';
BulkDataMask.TABRND1 = 'mni.bulk.List';
BulkDataMask.CONM1   = 'mni.bulk.Mass';
BulkDataMask.CONM2   = 'mni.bulk.Mass';
BulkDataMask.CMASS1  = 'mni.bulk.ScalarElement';
BulkDataMask.CMASS2  = 'mni.bulk.ScalarElement';
BulkDataMask.CMASS3  = 'mni.bulk.ScalarElement';
BulkDataMask.CMASS4  = 'mni.bulk.ScalarElement';
BulkDataMask.CELAS1  = 'mni.bulk.ScalarElement';
BulkDataMask.CELAS2  = 'mni.bulk.ScalarElement';
BulkDataMask.AERO    = 'mni.bulk.AnalysisData';
BulkDataMask.EIGR    = 'mni.bulk.AnalysisData';
BulkDataMask.EIGRL   = 'mni.bulk.AnalysisData';
BulkDataMask.FLUTTER = 'mni.bulk.AnalysisData';
BulkDataMask.FREQ1   = 'mni.bulk.AnalysisData';
BulkDataMask.RANDPS  = 'mni.bulk.AnalysisData';
BulkDataMask.MKAERO1 = 'mni.bulk.AnalysisData';

end