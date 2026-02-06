%% CreateCAD_JSON.m
% Creates JSON representations for all CAD classes in the CAD_Library
% These JSON files can be used to recreate objects in C#
%
% Usage:
%   CreateCAD_JSON()           - Creates all JSON and displays to console
%   CreateCAD_JSON(outputDir)  - Saves JSON files to specified directory

function CreateCAD_JSON(outputDir)
    if nargin < 1
        outputDir = '';
    end

    % Create all CAD class JSON structures
    jsonStructs = struct();

    jsonStructs.CAD_Dimension = createCAD_Dimension();
    jsonStructs.CAD_Parameter = createCAD_Parameter();
    jsonStructs.CAD_ParameterValue = createCAD_ParameterValue();
    jsonStructs.CAD_Model = createCAD_Model();
    jsonStructs.CAD_Part = createCAD_Part();
    jsonStructs.CAD_Feature = createCAD_Feature();
    jsonStructs.CAD_Sketch = createCAD_Sketch();
    jsonStructs.CAD_Assembly = createCAD_Assembly();
    jsonStructs.CAD_Drawing = createCAD_Drawing();
    jsonStructs.CAD_Body = createCAD_Body();
    jsonStructs.CAD_Station = createCAD_Station();
    jsonStructs.CAD_Constraint = createCAD_Constraint();
    jsonStructs.CAD_Interface = createCAD_Interface();
    jsonStructs.CAD_Joint = createCAD_Joint();
    jsonStructs.CAD_SketchPlane = createCAD_SketchPlane();
    jsonStructs.CAD_SketchElement = createCAD_SketchElement();
    jsonStructs.CAD_Surface = createCAD_Surface();
    jsonStructs.CAD_Hole = createCAD_Hole();
    jsonStructs.CAD_Component = createCAD_Component();
    jsonStructs.CAD_Configuration = createCAD_Configuration();
    jsonStructs.CAD_ConstructionGeometry = createCAD_ConstructionGeometry();
    jsonStructs.CAD_DrawingElement = createCAD_DrawingElement();
    jsonStructs.CAD_DrawingView = createCAD_DrawingView();
    jsonStructs.CAD_DrawingSheet = createCAD_DrawingSheet();
    jsonStructs.CAD_DrawingNote = createCAD_DrawingNote();
    jsonStructs.CAD_DrawingTable = createCAD_DrawingTable();
    jsonStructs.CAD_DrawingPMI = createCAD_DrawingPMI();
    jsonStructs.CAD_BoM = createCAD_BoM();
    jsonStructs.CAD_Library = createCAD_Library();
    jsonStructs.CAD_File = createCAD_File();
    jsonStructs.CAD_DrawingBoM_Table = createCAD_DrawingBoM_Table();

    % Output JSON for each class
    classNames = fieldnames(jsonStructs);
    for i = 1:length(classNames)
        className = classNames{i};
        jsonStr = jsonencode(jsonStructs.(className), 'PrettyPrint', true);

        fprintf('\n=== %s ===\n', className);
        fprintf('%s\n', jsonStr);

        % Save to file if output directory specified
        if ~isempty(outputDir)
            if ~exist(outputDir, 'dir')
                mkdir(outputDir);
            end
            filePath = fullfile(outputDir, [className '.json']);
            fid = fopen(filePath, 'w');
            fprintf(fid, '%s', jsonStr);
            fclose(fid);
            fprintf('Saved to: %s\n', filePath);
        end
    end
end

%% Helper function to create a Point structure
function point = createPoint(x, y, z)
    if nargin < 1, x = 0; end
    if nargin < 2, y = 0; end
    if nargin < 3, z = 0; end

    point = struct();
    point.X_Value = x;
    point.Y_Value = y;
    point.Z_Value_Cartesian = z;
end

%% Helper function to create a Vector structure
function vec = createVector(x, y, z)
    if nargin < 1, x = 0; end
    if nargin < 2, y = 0; end
    if nargin < 3, z = 0; end

    vec = struct();
    vec.X_Value = x;
    vec.Y_Value = y;
    vec.Z_Value = z;
    vec.VectorType = 0; % Cartesian
end

%% CAD_Dimension
function obj = createCAD_Dimension()
    obj = struct();
    obj.DimensionID = 'DIM_001';
    obj.Description = 'Sample dimension';
    obj.IsOrdinate = false;
    obj.CenterPoint = createPoint(10, 20, 0);
    obj.LeaderLineEndPoint = createPoint(15, 25, 0);
    obj.LeaderLineBendPoint = createPoint(12, 22, 0);
    obj.DimensionPoint = createPoint(10, 20, 0);
    obj.ReferencePoint = createPoint(0, 0, 0);
    obj.DimensionNominalValue = 25.4;
    obj.DimensionUpperLimitValue = 25.5;
    obj.DimensionLowerLimitValue = 25.3;
    obj.MyDimensionType = 0; % Length
    obj.Name = 'Dimension_001';
    obj.MyType = 1; % Dimension
end

%% CAD_Parameter
function obj = createCAD_Parameter()
    obj = struct();
    obj.Name = 'Length';
    obj.Id = 'PARAM_001';
    obj.Description = 'Part length parameter';
    obj.Comments = 'Primary dimension';
    obj.MyParameterType = 0; % Double
    obj.SolidWorksParameterName = 'D1@Sketch1';
    obj.Fusion360ParameterName = 'Length';
end

%% CAD_ParameterValue
function obj = createCAD_ParameterValue()
    obj = struct();
    obj.ValueType = 0; % Double
    obj.DoubleValue = 100.5;
end

%% CAD_Model
function obj = createCAD_Model()
    obj = struct();
    obj.Name = 'MyModel';
    obj.Version = '1.0';
    obj.Description = 'Sample CAD model';
    obj.FilePath = 'C:\Models\MyModel.sldprt';
    obj.CAD_AppName = 1; % SolidWorks
    obj.ModelType = 0; % Component
    obj.FileType = 2; % sldprt
    obj.MyStations = {};
    obj.MySketches = {};
    obj.MyFeatures = {};
    obj.MyParts = {};
    obj.MyDrawings = {};
    obj.MyAssemblies = {};
end

%% CAD_Part
function obj = createCAD_Part()
    obj = struct();
    obj.Name = 'Bracket';
    obj.Version = '1.0';
    obj.PartNumber = 'BKT-001';
    obj.Description = 'Mounting bracket';
    obj.CenterOfMass = createPoint(25, 12.5, 5);
    obj.MySketches = {};
    obj.MyFeatures = {};
    obj.MyBodies = {};
    obj.MyDrawings = {};
    obj.MyDimensions = {};
    obj.MyParameters = {};
    obj.MyCoordinateSystems = {};
    obj.MyInterfaces = {};
    obj.AxialStations = {};
    obj.RadialStations = {};
    obj.AngularStations = {};
    obj.WingStations = {};
end

%% CAD_Feature
function obj = createCAD_Feature()
    obj = struct();
    obj.Name = 'Extrude1';
    obj.Version = '1.0';
    obj.GeometricFeatureType = 0; % Hole
    obj.ThreeDimOperations = {0}; % Extrude
    obj.MyDimensions = {};
    obj.Sketches = {};
    obj.Stations = {};
    obj.MyFeatures = {};
    obj.MyLibraries = {};
end

%% CAD_Sketch
function obj = createCAD_Sketch()
    obj = struct();
    obj.SketchID = 'Sketch1';
    obj.Version = '1.0';
    obj.IsTwoD = true;
    obj.MyPoints = {createPoint(0,0,0), createPoint(100,0,0), createPoint(100,50,0), createPoint(0,50,0)};
    obj.MySegments = {};
    obj.MyProfile = {};
    obj.My2DGeometry = {};
    obj.MyCoordinateSystems = {};
    obj.MySketchElements = {};
    obj.MyParameters = {};
    obj.MyDimensions = {};
    obj.MyConstraints = {};
end

%% CAD_Assembly
function obj = createCAD_Assembly()
    obj = struct();
    obj.Name = 'MainAssembly';
    obj.Version = '1.0';
    obj.Description = 'Top level assembly';
    obj.IsSubAssembly = false;
    obj.IsConfigurationItem = true;
    obj.MyPosition = createPoint(0, 0, 0);
    obj.MyOrientation = createVector(0, 0, 1);
    obj.MyCoordinateSystems = {};
    obj.MyComponents = {};
    obj.MyConfigurations = {};
    obj.MissionRequirements = {};
    obj.SystemRequirements = {};
    obj.MyInterfaces = {};
    obj.AxialStations = {};
    obj.RadialStations = {};
    obj.AngularStations = {};
    obj.WingStations = {};
end

%% CAD_Drawing
function obj = createCAD_Drawing()
    obj = struct();
    obj.Title = 'Bracket Drawing';
    obj.DrawingNumber = 'DWG-001';
    obj.Revision = 'A';
    obj.DrawingStandard = 0; % ANSI
    obj.MyFormat = 0; % CAD_File
    obj.MyDrawingSize = 4; % A
    obj.MyDrawingSheets = {};
    obj.DrawingElements = {};
    obj.MyCAD_Sketches = {};
    obj.MyViews = {};
    obj.MyParts = {};
    obj.MyParameters = {};
    obj.MyDimensions = {};
    obj.MyConstructionGeometry = {};
end

%% CAD_Body
function obj = createCAD_Body()
    obj = struct();
    obj.Name = 'SolidBody1';
    obj.Version = '1.0';
    obj.PartNumber = 'BODY-001';
    obj.Sketches = {};
    obj.Features = {};
    obj.ThreeDimOperations = {};
end

%% CAD_Station
function obj = createCAD_Station()
    obj = struct();
    obj.Name = 'Station_100';
    obj.ID = 'STA_001';
    obj.Version = '1.0';
    obj.MyType = 0; % Axial
    obj.AxialLocation = 100.0;
    obj.RadialLocation = 0.0;
    obj.AngularLocation = 0.0;
    obj.WingLocation = 0.0;
    obj.FloorLocation = 0.0;
    obj.MySketchPlanes = {};
end

%% CAD_Constraint
function obj = createCAD_Constraint()
    obj = struct();
    obj.Name = 'Horizontal1';
    obj.ID = 'CON_001';
    obj.Description = 'Horizontal constraint on line';
    obj.Type = 0; % Horizontal
    obj.Features = {};
    obj.Models = {};
end

%% CAD_Interface
function obj = createCAD_Interface()
    obj = struct();
    obj.Name = 'MountingInterface';
    obj.ID = 'INT_001';
    obj.Version = '1.0';
    obj.InterfaceKind = 0; % Joint
    obj.MyContactPoints = {createPoint(0,0,0), createPoint(50,0,0)};
    obj.MyContactSurfaces = {};
end

%% CAD_Joint
function obj = createCAD_Joint()
    obj = struct();
    obj.Name = 'RevoluteJoint1';
    obj.ID = 'JNT_001';
    obj.Version = '1.0';
    obj.JointType = 1; % Revolute
    obj.ModelType = 1; % Fusion360
    obj.IncludedComponents = {};
end

%% CAD_SketchPlane
function obj = createCAD_SketchPlane()
    obj = struct();
    obj.Name = 'FrontPlane';
    obj.Version = '1.0';
    obj.Path = '/Planes/Front';
    obj.IsWorkplane = true;
    obj.GeometryType = 0; % Cartesian
    obj.FunctionalType = 3; % Feature
    obj.Sketches = {};
end

%% CAD_SketchElement
function obj = createCAD_SketchElement()
    obj = struct();
    obj.Name = 'Line1';
    obj.Version = '1.0';
    obj.Path = '/Sketch1/Line1';
    obj.ElementType = 4; % Line
    obj.IsWorkElement = false;
    obj.StartPoint = createPoint(0, 0, 0);
    obj.EndPoint = createPoint(100, 0, 0);
    obj.Points = {};
    obj.Primitives = {};
end

%% CAD_Surface
function obj = createCAD_Surface()
    obj = struct();
    obj.Name = 'TopFace';
    obj.ID = 'SURF_001';
    obj.Version = '1.0';
    obj.Description = 'Top planar surface';
    obj.SurfaceType = 0; % Plane
    obj.Length = 100.0;
    obj.Area = 5000.0;
    obj.Perimeter = 300.0;
    obj.Meshes = {};
end

%% CAD_Hole
function obj = createCAD_Hole()
    obj = struct();
    obj.Name = 'Hole1';
    obj.Version = '1.0';
    obj.GeometricFeatureType = 0; % Hole
    obj.NominalDiameter = createCAD_Dimension();
    obj.NominalDiameter.DimensionNominalValue = 10.0;
    obj.NominalDiameter.MyDimensionType = 1; % Diameter
    obj.NominalDepth = createCAD_Dimension();
    obj.NominalDepth.DimensionNominalValue = 25.0;
    obj.NominalDepth.MyDimensionType = 0; % Length
    obj.NominalTaperAngle = createCAD_Dimension();
    obj.NominalTaperAngle.DimensionNominalValue = 0.0;
    obj.NominalTaperAngle.MyDimensionType = 3; % Angle
    obj.CenterPoint = createPoint(50, 25, 0);
    obj.HasKeyway = false;
    obj.HasThreads = false;
    obj.MyThreads = {};
end

%% CAD_Component
function obj = createCAD_Component()
    obj = struct();
    obj.Name = 'Fastener';
    obj.Version = '1.0';
    obj.Path = '/Assembly/Fastener';
    obj.IsAssembly = false;
    obj.IsConfigurationItem = false;
    obj.WBS_Level = 3;
    obj.MomentsOfInertia = {};
    obj.PrincipleDirections = {};
    obj.MySketches = {};
    obj.MyJoints = {};
end

%% CAD_Configuration
function obj = createCAD_Configuration()
    obj = struct();
    obj.Name = 'Default';
    obj.Description = 'Default configuration';
    obj.ID = 'CFG_001';
    obj.Revision = 'A';
end

%% CAD_ConstructionGeometry
function obj = createCAD_ConstructionGeometry()
    obj = struct();
    obj.Name = 'CenterLine1';
    obj.Version = '1.0';
    obj.GeometryType = 1; % Line
end

%% CAD_DrawingElement
function obj = createCAD_DrawingElement()
    obj = struct();
    obj.Name = 'Element1';
    obj.MyType = 0; % DrawingView
    obj.MyConstructionGeometry = {};
end

%% CAD_DrawingView
function obj = createCAD_DrawingView()
    obj = struct();
    obj.ID = 'VIEW_001';
    obj.Title = 'Front View';
    obj.Description = 'Front orthographic view';
    obj.Type = 1; % OrthoFront
    obj.CenterPoint = createPoint(200, 150, 0);
    obj.Name = 'FrontView';
    obj.MyType = 0; % DrawingView
    obj.MyConstructionGeometry = {};
end

%% CAD_DrawingSheet
function obj = createCAD_DrawingSheet()
    obj = struct();
    obj.SheetID = 'SHEET_001';
    obj.SheetNumber = 1;
    obj.Size = 4; % A
    obj.SheetOrientation = 0; % Landscape
    obj.DrawingViews = {};
    obj.Dimensions = {};
    obj.DrawingNotes = {};
    obj.ConstructionGeometry = {};
    obj.PMI = {};
    obj.DrawingTables = {};
end

%% CAD_DrawingNote
function obj = createCAD_DrawingNote()
    obj = struct();
    obj.DrawingNoteID = 'NOTE_001';
    obj.NoteText = 'ALL DIMENSIONS IN MILLIMETERS';
    obj.MyNoteType = 0; % General
end

%% CAD_DrawingTable
function obj = createCAD_DrawingTable()
    obj = struct();
    obj.Name = 'TitleBlock';
    obj.MyType = 2; % Table
    obj.Configurations = {};
    obj.MyConstructionGeometry = {};
end

%% CAD_DrawingPMI
function obj = createCAD_DrawingPMI()
    obj = struct();
    obj.Name = 'GDT_001';
    obj.Is3D = false;
    obj.Type = 0; % Gdt
    obj.MyType = 4; % PMI
    obj.MyConstructionGeometry = {};
end

%% CAD_BoM
function obj = createCAD_BoM()
    obj = struct();
    obj.Name = 'BillOfMaterials';
    obj.BoMType = 0; % Design
    obj.Configurations = {};
    obj.MyType = 3; % BoM
    obj.MyConstructionGeometry = {};
end

%% CAD_Library
function obj = createCAD_Library()
    obj = struct();
    obj.Name = 'StandardParts';
    obj.Description = 'Standard parts library';
    obj.LocalPath = 'C:\CADLibraries\StandardParts';
    obj.Url = 'https://example.com/libraries/standard';
end

%% CAD_File
function obj = createCAD_File()
    obj = struct();
    obj.DisplayName = 'BracketAssembly';
    obj.FileType = 3; % sldasm
    obj.SourceApplication = 1; % SolidWorks
    obj.FileSizeBytes = 1024000;
    obj.LastModifiedUtc = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    obj.LocationState = 2; % Synchronized
    obj.LocalPath = 'C:\Projects\BracketAssembly.sldasm';
    obj.Configurations = {};
end

%% CAD_DrawingBoM_Table
function obj = createCAD_DrawingBoM_Table()
    obj = struct();
    obj.Name = 'BoMTable';
    obj.ChangeOrderID = 'ECO-001';
    obj.MyLocation = createPoint(50, 250, 0);
    obj.MyConfigurations = {};
    obj.MyBoMRows = {};
    obj.MyType = 2; % Table
    obj.MyConstructionGeometry = {};
end
