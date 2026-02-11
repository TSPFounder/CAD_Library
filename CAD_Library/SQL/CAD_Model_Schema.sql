-- ============================================================
-- SQLite Schema for CAD_Model JSON mapping
-- Generated from CAD_Library: CAD_Model
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, UnitOfMeasure, Segment,
--   CAD_Dimension, CAD_Parameter, CAD_ParameterValue, MathParameter
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- Shared Mathematics Types (IF NOT EXISTS — safe to re-run)
-- ============================================================

CREATE TABLE IF NOT EXISTS Point (
    PointID         TEXT PRIMARY KEY,
    IsWeightPoint   INTEGER NOT NULL DEFAULT 0,
    MyType          INTEGER NOT NULL DEFAULT 0,
    Is2D            INTEGER NOT NULL DEFAULT 0,
    X_Value                 REAL NOT NULL DEFAULT 0.0,
    Y_Value                 REAL NOT NULL DEFAULT 0.0,
    Z_Value_Cartesian       REAL NOT NULL DEFAULT 0.0,
    R_Value_Cylindrical     REAL NOT NULL DEFAULT 0.0,
    Theta_Value_Cylindrical REAL NOT NULL DEFAULT 0.0,
    Z_Value_Cylindrical     REAL NOT NULL DEFAULT 0.0,
    R_Value_Spherical       REAL NOT NULL DEFAULT 0.0,
    Theta_Value_Spherical   REAL NOT NULL DEFAULT 0.0,
    Phi_Value               REAL NOT NULL DEFAULT 0.0,
    Longitude               REAL NOT NULL DEFAULT 0.0,
    Latitude                REAL NOT NULL DEFAULT 0.0,
    Altitude                REAL NOT NULL DEFAULT 0.0,
    Real_Value              REAL NOT NULL DEFAULT 0.0,
    Complex_Value           REAL NOT NULL DEFAULT 0.0,
    CurrentCoordinateSystemID   TEXT,
    CurrentConnectedPointID     TEXT,
    FOREIGN KEY (CurrentConnectedPointID) REFERENCES Point(PointID)
);

CREATE TABLE IF NOT EXISTS Vector (
    VectorID        TEXT PRIMARY KEY,
    Name            TEXT,
    IsKnotVector    INTEGER NOT NULL DEFAULT 0,
    VectorType      INTEGER NOT NULL DEFAULT 0,
    X_Value         REAL NOT NULL DEFAULT 0.0,
    Y_Value         REAL NOT NULL DEFAULT 0.0,
    Z_Value         REAL NOT NULL DEFAULT 0.0,
    Cyl_R           REAL NOT NULL DEFAULT 0.0,
    Cyl_Theta       REAL NOT NULL DEFAULT 0.0,
    L               REAL NOT NULL DEFAULT 0.0,
    Sph_R           REAL NOT NULL DEFAULT 0.0,
    Sph_Theta       REAL NOT NULL DEFAULT 0.0,
    Phi             REAL NOT NULL DEFAULT 0.0,
    StartPointID    TEXT,
    EndPointID      TEXT,
    WorldCoordinateSystemID     TEXT,
    CurrentCoordinateSystemID   TEXT,
    FOREIGN KEY (StartPointID)  REFERENCES Point(PointID),
    FOREIGN KEY (EndPointID)    REFERENCES Point(PointID)
);

CREATE TABLE IF NOT EXISTS CoordinateSystem (
    CoordinateSystemID  TEXT PRIMARY KEY,
    Name                TEXT,
    MyType              INTEGER NOT NULL DEFAULT 0,
    IsWCS               INTEGER NOT NULL DEFAULT 0,
    Is2D                INTEGER NOT NULL DEFAULT 0,
    OriginLocationPointID   TEXT,
    BaseVectorID            TEXT,
    FOREIGN KEY (OriginLocationPointID) REFERENCES Point(PointID),
    FOREIGN KEY (BaseVectorID)          REFERENCES Vector(VectorID)
);

-- ============================================================
-- CAD_SketchPlane
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_SketchPlane (
    SketchPlaneID       TEXT PRIMARY KEY,       -- synthetic key
    Name                TEXT,
    Version             TEXT,
    Path                TEXT,
    IsWorkplane         INTEGER NOT NULL DEFAULT 1,    -- bool
    GeometryType        INTEGER NOT NULL DEFAULT 0,    -- GeometryTypeEnum: 0=Cartesian,1=Spherical,2=Cylindrical
    FunctionalType      INTEGER NOT NULL DEFAULT 3,    -- FunctionalTypeEnum: 0=Interface,1=Section,2=GeometricBoundary,3=Feature,4=CoordinateSystemOrigin,5=Incremental

    -- Associations
    MyModelID               TEXT,
    MyCoordinateSystemID    TEXT,
    NormalVectorID          TEXT,
    CurrentSketchID         TEXT,

    FOREIGN KEY (MyCoordinateSystemID)  REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (NormalVectorID)        REFERENCES Vector(VectorID)
    -- FK to CAD_Sketch and CAD_Model added logically (forward references)
);

-- CAD_SketchPlane -> Sketches
CREATE TABLE IF NOT EXISTS CAD_SketchPlane_Sketch (
    SketchPlaneID   TEXT NOT NULL,
    SketchID        TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchPlaneID, SketchID),
    FOREIGN KEY (SketchPlaneID) REFERENCES CAD_SketchPlane(SketchPlaneID)
);

-- ============================================================
-- CAD_Station
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Station (
    StationID       TEXT PRIMARY KEY,          -- derived from ID property or generated
    Name            TEXT,
    ID              TEXT,                      -- the class's own ID property
    Version         TEXT,
    MyType          INTEGER NOT NULL DEFAULT 0,    -- StationTypeEnum: 0=Axial,1=Radial,2=Angular,3=Wing,4=Other

    -- Location values
    AxialLocation   REAL NOT NULL DEFAULT 0.0,
    RadialLocation  REAL NOT NULL DEFAULT 0.0,
    AngularLocation REAL NOT NULL DEFAULT 0.0,
    WingLocation    REAL NOT NULL DEFAULT 0.0,
    FloorLocation   REAL NOT NULL DEFAULT 0.0,

    -- Associations
    MyModelID           TEXT,
    CurrentSketchPlaneID TEXT,

    FOREIGN KEY (CurrentSketchPlaneID)  REFERENCES CAD_SketchPlane(SketchPlaneID)
    -- FK to CAD_Model deferred (forward reference)
);

-- CAD_Station -> SketchPlanes
CREATE TABLE IF NOT EXISTS CAD_Station_SketchPlane (
    StationID       TEXT NOT NULL,
    SketchPlaneID   TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (StationID, SketchPlaneID),
    FOREIGN KEY (StationID)     REFERENCES CAD_Station(StationID),
    FOREIGN KEY (SketchPlaneID) REFERENCES CAD_SketchPlane(SketchPlaneID)
);

-- ============================================================
-- CAD_Sketch
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Sketch (
    SketchID        TEXT PRIMARY KEY,
    Version         TEXT,
    IsTwoD          INTEGER NOT NULL DEFAULT 0,    -- bool

    -- Summary parameters (FKs to CAD_Parameter)
    AreaParameterID         TEXT,
    PerimeterLengthParameterID TEXT,

    -- Ownership
    MyModelID           TEXT,
    MySketchPlaneID     TEXT,

    -- Cursors
    CurrentPointID              TEXT,
    CurrentSegmentID            TEXT,
    PreviousSegmentID           TEXT,
    CurrentParameterID          TEXT,
    CurrentDimensionID          TEXT,
    CurrentConstraintID         TEXT,
    CurrentCoordinateSystemID   TEXT,
    BaseCoordinateSystemID      TEXT,

    FOREIGN KEY (MySketchPlaneID)           REFERENCES CAD_SketchPlane(SketchPlaneID),
    FOREIGN KEY (CurrentPointID)            REFERENCES Point(PointID),
    FOREIGN KEY (CurrentCoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (BaseCoordinateSystemID)    REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- CAD_Sketch collections
CREATE TABLE IF NOT EXISTS CAD_Sketch_Point (
    SketchID    TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, PointID, SortOrder),
    FOREIGN KEY (SketchID) REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (PointID)  REFERENCES Point(PointID)
);

CREATE TABLE IF NOT EXISTS CAD_Sketch_Segment (
    SketchID    TEXT NOT NULL,
    SegmentID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, SegmentID, SortOrder),
    FOREIGN KEY (SketchID) REFERENCES CAD_Sketch(SketchID)
);

CREATE TABLE IF NOT EXISTS CAD_Sketch_ProfileSegment (
    SketchID    TEXT NOT NULL,
    SegmentID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, SegmentID, SortOrder),
    FOREIGN KEY (SketchID) REFERENCES CAD_Sketch(SketchID)
);

CREATE TABLE IF NOT EXISTS CAD_Sketch_CoordinateSystem (
    SketchID            TEXT NOT NULL,
    CoordinateSystemID  TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, CoordinateSystemID),
    FOREIGN KEY (SketchID)           REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- ============================================================
-- CAD_Feature
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Feature (
    FeatureID               TEXT PRIMARY KEY,      -- synthetic key
    Name                    TEXT,
    Version                 TEXT,
    GeometricFeatureType    INTEGER NOT NULL DEFAULT 0,
    -- GeometricFeatureTypeEnum: 0=Hole,1=Joint,2=Thread,3=Chamfer,4=Fillet,5=CounterBore,
    -- 6=CounterSink,7=Bead,8=Boss,9=Keyway,10=Leg,11=Arm,12=Mirror,13=Embossment,14=Rib,
    -- 15=RoundedSlot,16=Gusset,17=Taper,18=SquareSlot,19=Shell,20=Web,21=Tab,22=Coil,
    -- 23=Helicoil,24=RectangularPattern,25=CircularPattern,26=OtherPattern,27=Other

    -- Associations
    MyModelID               TEXT,
    OriginCSysID            TEXT,
    CurrentDimensionID      TEXT,
    CurrentFeatureID        TEXT,       -- self-referential (sub-feature cursor)
    CurrentCAD_SketchID     TEXT,
    CurrentCAD_StationID    TEXT,
    CurrentLibraryID        TEXT,

    FOREIGN KEY (OriginCSysID)          REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CurrentCAD_SketchID)   REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CurrentCAD_StationID)  REFERENCES CAD_Station(StationID),
    FOREIGN KEY (CurrentFeatureID)      REFERENCES CAD_Feature(FeatureID)
);

-- CAD_Feature -> ThreeDimOperations (List<Feature3DOperationEnum> stored as integers)
CREATE TABLE IF NOT EXISTS CAD_Feature_3DOperation (
    FeatureID   TEXT NOT NULL,
    Operation   INTEGER NOT NULL,      -- Feature3DOperationEnum: 0=Extrude,1=Revolve,2=Sweep,3=Loft
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, SortOrder),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID)
);

-- CAD_Feature -> MyDimensions
CREATE TABLE IF NOT EXISTS CAD_Feature_Dimension (
    FeatureID   TEXT NOT NULL,
    DimensionID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, DimensionID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID)
);

-- CAD_Feature -> Sketches
CREATE TABLE IF NOT EXISTS CAD_Feature_Sketch (
    FeatureID   TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, SketchID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

-- CAD_Feature -> Stations
CREATE TABLE IF NOT EXISTS CAD_Feature_Station (
    FeatureID   TEXT NOT NULL,
    StationID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, StationID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (StationID) REFERENCES CAD_Station(StationID)
);

-- CAD_Feature -> MyFeatures (sub-features, self-referential)
CREATE TABLE IF NOT EXISTS CAD_Feature_SubFeature (
    ParentFeatureID TEXT NOT NULL,
    ChildFeatureID  TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ParentFeatureID, ChildFeatureID),
    FOREIGN KEY (ParentFeatureID) REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (ChildFeatureID)  REFERENCES CAD_Feature(FeatureID)
);

-- CAD_Feature -> MyLibraries
CREATE TABLE IF NOT EXISTS CAD_Feature_Library (
    FeatureID   TEXT NOT NULL,
    LibraryID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, LibraryID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID)
);

-- ============================================================
-- CAD_Body (extends CAD_Feature — flattened into own table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Body (
    BodyID          TEXT PRIMARY KEY,
    Name            TEXT,
    Version         TEXT,
    PartNumber      TEXT,

    -- Inherited from CAD_Feature
    GeometricFeatureType    INTEGER NOT NULL DEFAULT 0,
    MyModelID               TEXT,
    OriginCSysID            TEXT,

    -- Cursors
    CurrentSketchID     TEXT,
    CurrentFeatureID    TEXT,

    FOREIGN KEY (OriginCSysID)      REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CurrentSketchID)   REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CurrentFeatureID)  REFERENCES CAD_Feature(FeatureID)
);

-- CAD_Body -> Sketches
CREATE TABLE IF NOT EXISTS CAD_Body_Sketch (
    BodyID      TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, SketchID),
    FOREIGN KEY (BodyID)    REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

-- CAD_Body -> Features
CREATE TABLE IF NOT EXISTS CAD_Body_Feature (
    BodyID      TEXT NOT NULL,
    FeatureID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, FeatureID),
    FOREIGN KEY (BodyID)    REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID)
);

-- ============================================================
-- MassProperties
-- ============================================================

CREATE TABLE IF NOT EXISTS MassProperties (
    MassPropertiesID    TEXT PRIMARY KEY,       -- synthetic key
    Mass                REAL NOT NULL DEFAULT 0.0,

    -- Center of gravity (FK to Point)
    CenterOfGravityPointID  TEXT,

    -- Ownership
    MyCAD_PartID                TEXT,
    CurrentCoordinateSystemID   TEXT,

    -- Inertia tensors stored as JSON blobs (3x3 matrices)
    PrincipalMomentsOfInertia_JSON  TEXT,       -- 3x3 matrix as JSON array
    CurrentMomentsOfInertia_JSON    TEXT,       -- 3x3 matrix as JSON array

    FOREIGN KEY (CenterOfGravityPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (CurrentCoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- MassProperties -> CoordinateSystems
CREATE TABLE IF NOT EXISTS MassProperties_CoordinateSystem (
    MassPropertiesID    TEXT NOT NULL,
    CoordinateSystemID  TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (MassPropertiesID, CoordinateSystemID),
    FOREIGN KEY (MassPropertiesID)  REFERENCES MassProperties(MassPropertiesID),
    FOREIGN KEY (CoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- MassProperties -> PrincipalDirections (3 Vectors)
CREATE TABLE IF NOT EXISTS MassProperties_PrincipalDirection (
    MassPropertiesID    TEXT NOT NULL,
    VectorID            TEXT NOT NULL,
    AxisIndex           INTEGER NOT NULL,      -- 0=X, 1=Y, 2=Z
    PRIMARY KEY (MassPropertiesID, AxisIndex),
    FOREIGN KEY (MassPropertiesID) REFERENCES MassProperties(MassPropertiesID),
    FOREIGN KEY (VectorID)         REFERENCES Vector(VectorID)
);

-- MassProperties -> MomentsHistory (audit trail of 3x3 matrices)
CREATE TABLE IF NOT EXISTS MassProperties_InertiaHistory (
    MassPropertiesID    TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    MatrixJSON          TEXT NOT NULL,         -- 3x3 matrix as JSON array
    PRIMARY KEY (MassPropertiesID, SortOrder),
    FOREIGN KEY (MassPropertiesID) REFERENCES MassProperties(MassPropertiesID)
);

-- ============================================================
-- CAD_Drawing
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Drawing (
    DrawingID       TEXT PRIMARY KEY,          -- synthetic key
    Title           TEXT,
    DrawingNumber   TEXT,
    Revision        TEXT,
    DrawingStandard INTEGER NOT NULL DEFAULT 0,    -- DrawingStandardEnum: 0=ANSI
    MyFormat        INTEGER NOT NULL DEFAULT 0,    -- DocFormatEnum: 0=CAD_File,1=DWG,2=PDF,3=PNG,4=JPG,5=Other
    MyDrawingSize   INTEGER NOT NULL DEFAULT 4,    -- DrawingSize: 0=E,1=D,2=C,3=B,4=A,5=A1,6=A2,7=A3

    -- Associations
    MyAssemblyID    TEXT,
    MyModelID       TEXT

    -- Cursor FKs (CurrentSheet, CurrentElement, etc.) are session state,
    -- stored as nullable TEXT columns referencing their respective tables
);

-- CAD_Drawing -> DrawingSheets
CREATE TABLE IF NOT EXISTS CAD_Drawing_Sheet (
    DrawingID   TEXT NOT NULL,
    SheetID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, SheetID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID)
);

-- CAD_Drawing -> Views
CREATE TABLE IF NOT EXISTS CAD_Drawing_View (
    DrawingID   TEXT NOT NULL,
    ViewID      TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, ViewID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID)
);

-- CAD_Drawing -> Parts
CREATE TABLE IF NOT EXISTS CAD_Drawing_Part (
    DrawingID   TEXT NOT NULL,
    PartID      TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, PartID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID)
);

-- CAD_Drawing -> Sketches
CREATE TABLE IF NOT EXISTS CAD_Drawing_Sketch (
    DrawingID   TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, SketchID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

-- CAD_Drawing -> Parameters
CREATE TABLE IF NOT EXISTS CAD_Drawing_Parameter (
    DrawingID       TEXT NOT NULL,
    MathParameterID TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, MathParameterID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID)
);

-- CAD_Drawing -> Dimensions
CREATE TABLE IF NOT EXISTS CAD_Drawing_Dimension (
    DrawingID   TEXT NOT NULL,
    DimensionID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, DimensionID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID)
);

-- ============================================================
-- CAD_Library (the class, not the assembly)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Library (
    LibraryID   TEXT PRIMARY KEY,              -- synthetic key
    Name        TEXT,
    Description TEXT,
    LocalPath   TEXT,
    Url         TEXT
);

-- ============================================================
-- CAD_Part
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Part (
    PartID          TEXT PRIMARY KEY,          -- synthetic key
    Name            TEXT,
    Version         TEXT,
    PartNumber      TEXT,
    Description     TEXT,

    -- Mass property references
    CurrentMassPropertiesID TEXT,
    MyMassPropertiesID      TEXT,              -- the always-present MassProperties instance
    CenterOfMassPointID     TEXT,

    -- Cursors
    CurrentModelID              TEXT,
    CurrentCoordinateSystemID   TEXT,
    CurrentSketchID             TEXT,
    CurrentFeatureID            TEXT,
    CurrentBodyID               TEXT,
    CurrentDrawingID            TEXT,
    CurrentDimensionID          TEXT,
    CurrentParameterID          TEXT,
    CurrentLibraryID            TEXT,
    CurrentInterfaceID          TEXT,
    MyAssemblyID                TEXT,

    FOREIGN KEY (CurrentMassPropertiesID)   REFERENCES MassProperties(MassPropertiesID),
    FOREIGN KEY (MyMassPropertiesID)        REFERENCES MassProperties(MassPropertiesID),
    FOREIGN KEY (CenterOfMassPointID)       REFERENCES Point(PointID),
    FOREIGN KEY (CurrentCoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CurrentSketchID)           REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CurrentFeatureID)          REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (CurrentBodyID)             REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (CurrentDrawingID)          REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (CurrentLibraryID)          REFERENCES CAD_Library(LibraryID)
);

-- CAD_Part -> collections
CREATE TABLE IF NOT EXISTS CAD_Part_Sketch (
    PartID      TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, SketchID),
    FOREIGN KEY (PartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

CREATE TABLE IF NOT EXISTS CAD_Part_Feature (
    PartID      TEXT NOT NULL,
    FeatureID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, FeatureID),
    FOREIGN KEY (PartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID)
);

CREATE TABLE IF NOT EXISTS CAD_Part_Body (
    PartID      TEXT NOT NULL,
    BodyID      TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, BodyID),
    FOREIGN KEY (PartID) REFERENCES CAD_Part(PartID),
    FOREIGN KEY (BodyID) REFERENCES CAD_Body(BodyID)
);

CREATE TABLE IF NOT EXISTS CAD_Part_Drawing (
    PartID      TEXT NOT NULL,
    DrawingID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, DrawingID),
    FOREIGN KEY (PartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID)
);

CREATE TABLE IF NOT EXISTS CAD_Part_Model (
    PartID      TEXT NOT NULL,
    ModelID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, ModelID),
    FOREIGN KEY (PartID) REFERENCES CAD_Part(PartID)
);

CREATE TABLE IF NOT EXISTS CAD_Part_CoordinateSystem (
    PartID              TEXT NOT NULL,
    CoordinateSystemID  TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, CoordinateSystemID),
    FOREIGN KEY (PartID)            REFERENCES CAD_Part(PartID),
    FOREIGN KEY (CoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

CREATE TABLE IF NOT EXISTS CAD_Part_Interface (
    PartID      TEXT NOT NULL,
    InterfaceID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, InterfaceID),
    FOREIGN KEY (PartID) REFERENCES CAD_Part(PartID)
);

CREATE TABLE IF NOT EXISTS CAD_Part_MassProperties (
    PartID              TEXT NOT NULL,
    MassPropertiesID    TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, MassPropertiesID),
    FOREIGN KEY (PartID)            REFERENCES CAD_Part(PartID),
    FOREIGN KEY (MassPropertiesID)  REFERENCES MassProperties(MassPropertiesID)
);

-- CAD_Part -> Station collections (4 typed lists)
CREATE TABLE IF NOT EXISTS CAD_Part_Station (
    PartID          TEXT NOT NULL,
    StationID       TEXT NOT NULL,
    StationCategory TEXT NOT NULL,             -- 'Axial','Radial','Angular','Wing'
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, StationID, StationCategory),
    FOREIGN KEY (PartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (StationID) REFERENCES CAD_Station(StationID)
);

-- ============================================================
-- CAD_BoM (extends CAD_DrawingElement)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_BoM (
    BoMID       TEXT PRIMARY KEY,
    -- Inherited from CAD_DrawingElement
    Name        TEXT,
    MyType      INTEGER NOT NULL DEFAULT 3,    -- DrawingElementType.BoM = 3
    MyDrawingID TEXT,

    -- CAD_BoM specific
    BoMType                 INTEGER,           -- BoM_TypeEnum: 0=Design,1=Manufacturing,2=Estimating,3=Other (nullable)
    CurrentConfigurationID  TEXT,
    DrawingBoMTableID       TEXT,              -- FK to CAD_DrawingBoM_Table if defined

    FOREIGN KEY (MyDrawingID)               REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (CurrentConfigurationID)    REFERENCES CAD_Configuration(ConfigurationID)
);

-- CAD_BoM -> Configurations
CREATE TABLE IF NOT EXISTS CAD_BoM_Configuration (
    BoMID           TEXT NOT NULL,
    ConfigurationID TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BoMID, ConfigurationID),
    FOREIGN KEY (BoMID)           REFERENCES CAD_BoM(BoMID),
    FOREIGN KEY (ConfigurationID) REFERENCES CAD_Configuration(ConfigurationID)
);

-- ============================================================
-- CAD_Configuration
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Configuration (
    ConfigurationID TEXT PRIMARY KEY,          -- derived from ID property or generated
    Name            TEXT,
    Description     TEXT,
    ID              TEXT,                      -- the class's own ID property
    Revision        TEXT,

    -- Associations
    CurrentPartID       TEXT,
    CurrentPartRowID    TEXT,                  -- FK to SE_TableRow if defined
    MyAssemblyID        TEXT,

    FOREIGN KEY (CurrentPartID) REFERENCES CAD_Part(PartID)
);

-- ============================================================
-- SE_System (referenced by CAD_Model.MySystem)
-- ============================================================

CREATE TABLE IF NOT EXISTS SE_System (
    SE_SystemID         TEXT PRIMARY KEY,
    Name                TEXT,
    Version             TEXT,
    Description         TEXT,
    ID                  TEXT,
    SystemCategoryName  TEXT,
    SystemType          INTEGER NOT NULL DEFAULT 4,    -- SystemTypeEnum: 0=SoS,1=SoI,2=Subsystem,3=ConfigurationItem,4=Other
    WBS_Level           INTEGER NOT NULL DEFAULT 0,
    IsPurchasedPart     INTEGER NOT NULL DEFAULT 0,    -- bool
    MyAssemblyID        TEXT
);

-- ============================================================
-- CAD_Model  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Model (
    ModelID     TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    Description TEXT,
    FilePath    TEXT,

    -- Enumerations
    CAD_AppName INTEGER NOT NULL DEFAULT 0,    -- CAD_AppEnum: 0=Fusion360,1=Solidworks,2=Blender,3=UnReal4,4=UnReal5,5=Unity,6=Other
    ModelType   INTEGER NOT NULL DEFAULT 0,    -- CAD_ModelTypeEnum: 0=Component,1=Assembly,2=Drawing,3=Mesh,4=Body,5=Other
    FileType    INTEGER NOT NULL DEFAULT 0,    -- CAD_FileTypeEnum: 0=f3d,...,15=other

    -- Cursor references
    CurrentStationID    TEXT,
    CurrentSketchID     TEXT,
    CurrentFeatureID    TEXT,
    CurrentPartID       TEXT,
    CurrentDrawingID    TEXT,
    CurrentAssemblyID   TEXT,

    -- Associations
    MySystemID  TEXT,
    MyBoMID     TEXT,

    FOREIGN KEY (CurrentStationID)  REFERENCES CAD_Station(StationID),
    FOREIGN KEY (CurrentSketchID)   REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CurrentFeatureID)  REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (CurrentPartID)     REFERENCES CAD_Part(PartID),
    FOREIGN KEY (CurrentDrawingID)  REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (MySystemID)        REFERENCES SE_System(SE_SystemID),
    FOREIGN KEY (MyBoMID)           REFERENCES CAD_BoM(BoMID)
    -- CurrentAssemblyID FK deferred (forward reference to CAD_Assembly)
);

-- ============================================================
-- CAD_Model collection junction tables
-- ============================================================

-- CAD_Model -> MyStations
CREATE TABLE IF NOT EXISTS CAD_Model_Station (
    ModelID     TEXT NOT NULL,
    StationID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ModelID, StationID),
    FOREIGN KEY (ModelID)   REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (StationID) REFERENCES CAD_Station(StationID)
);

-- CAD_Model -> MySketches
CREATE TABLE IF NOT EXISTS CAD_Model_Sketch (
    ModelID     TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ModelID, SketchID),
    FOREIGN KEY (ModelID)  REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (SketchID) REFERENCES CAD_Sketch(SketchID)
);

-- CAD_Model -> MyFeatures
CREATE TABLE IF NOT EXISTS CAD_Model_Feature (
    ModelID     TEXT NOT NULL,
    FeatureID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ModelID, FeatureID),
    FOREIGN KEY (ModelID)   REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID)
);

-- CAD_Model -> MyParts
CREATE TABLE IF NOT EXISTS CAD_Model_Part (
    ModelID     TEXT NOT NULL,
    PartID      TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ModelID, PartID),
    FOREIGN KEY (ModelID) REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (PartID)  REFERENCES CAD_Part(PartID)
);

-- CAD_Model -> MyDrawings
CREATE TABLE IF NOT EXISTS CAD_Model_Drawing (
    ModelID     TEXT NOT NULL,
    DrawingID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ModelID, DrawingID),
    FOREIGN KEY (ModelID)   REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID)
);

-- CAD_Model -> MyAssemblies
CREATE TABLE IF NOT EXISTS CAD_Model_Assembly (
    ModelID     TEXT NOT NULL,
    AssemblyID  TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ModelID, AssemblyID),
    FOREIGN KEY (ModelID) REFERENCES CAD_Model(ModelID)
    -- FK to CAD_Assembly deferred
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_model_name           ON CAD_Model(Name);
CREATE INDEX IF NOT EXISTS idx_model_app            ON CAD_Model(CAD_AppName);
CREATE INDEX IF NOT EXISTS idx_model_type           ON CAD_Model(ModelType);
CREATE INDEX IF NOT EXISTS idx_model_file_type      ON CAD_Model(FileType);
CREATE INDEX IF NOT EXISTS idx_model_filepath       ON CAD_Model(FilePath);
CREATE INDEX IF NOT EXISTS idx_model_system         ON CAD_Model(MySystemID);
CREATE INDEX IF NOT EXISTS idx_station_name         ON CAD_Station(Name);
CREATE INDEX IF NOT EXISTS idx_station_type         ON CAD_Station(MyType);
CREATE INDEX IF NOT EXISTS idx_sketch_model         ON CAD_Sketch(MyModelID);
CREATE INDEX IF NOT EXISTS idx_feature_type         ON CAD_Feature(GeometricFeatureType);
CREATE INDEX IF NOT EXISTS idx_feature_model        ON CAD_Feature(MyModelID);
CREATE INDEX IF NOT EXISTS idx_part_name            ON CAD_Part(Name);
CREATE INDEX IF NOT EXISTS idx_part_number          ON CAD_Part(PartNumber);
CREATE INDEX IF NOT EXISTS idx_drawing_number       ON CAD_Drawing(DrawingNumber);
CREATE INDEX IF NOT EXISTS idx_drawing_title        ON CAD_Drawing(Title);
CREATE INDEX IF NOT EXISTS idx_body_name            ON CAD_Body(Name);
CREATE INDEX IF NOT EXISTS idx_body_part_number     ON CAD_Body(PartNumber);
CREATE INDEX IF NOT EXISTS idx_config_name          ON CAD_Configuration(Name);
CREATE INDEX IF NOT EXISTS idx_sketchplane_name     ON CAD_SketchPlane(Name);
CREATE INDEX IF NOT EXISTS idx_bom_type             ON CAD_BoM(BoMType);
CREATE INDEX IF NOT EXISTS idx_library_name         ON CAD_Library(Name);
CREATE INDEX IF NOT EXISTS idx_se_system_name       ON SE_System(Name);

-- ============================================================
-- View: CAD_Model detail with counts of child collections
-- ============================================================

CREATE VIEW IF NOT EXISTS v_CAD_Model_Detail AS
SELECT
    m.ModelID,
    m.Name,
    m.Version,
    m.Description,
    m.FilePath,
    m.CAD_AppName,
    CASE m.CAD_AppName
        WHEN 0 THEN 'Fusion360'
        WHEN 1 THEN 'Solidworks'
        WHEN 2 THEN 'Blender'
        WHEN 3 THEN 'UnReal4'
        WHEN 4 THEN 'UnReal5'
        WHEN 5 THEN 'Unity'
        WHEN 6 THEN 'Other'
    END AS CAD_AppNameText,
    m.ModelType,
    CASE m.ModelType
        WHEN 0 THEN 'Component'
        WHEN 1 THEN 'Assembly'
        WHEN 2 THEN 'Drawing'
        WHEN 3 THEN 'Mesh'
        WHEN 4 THEN 'Body'
        WHEN 5 THEN 'Other'
    END AS ModelTypeText,
    m.FileType,
    (SELECT COUNT(*) FROM CAD_Model_Station  ms WHERE ms.ModelID = m.ModelID) AS StationCount,
    (SELECT COUNT(*) FROM CAD_Model_Sketch   mk WHERE mk.ModelID = m.ModelID) AS SketchCount,
    (SELECT COUNT(*) FROM CAD_Model_Feature  mf WHERE mf.ModelID = m.ModelID) AS FeatureCount,
    (SELECT COUNT(*) FROM CAD_Model_Part     mp WHERE mp.ModelID = m.ModelID) AS PartCount,
    (SELECT COUNT(*) FROM CAD_Model_Drawing  md WHERE md.ModelID = m.ModelID) AS DrawingCount,
    (SELECT COUNT(*) FROM CAD_Model_Assembly ma WHERE ma.ModelID = m.ModelID) AS AssemblyCount,
    sys.Name AS SystemName,
    bom.BoMType
FROM CAD_Model m
LEFT JOIN SE_System sys ON m.MySystemID = sys.SE_SystemID
LEFT JOIN CAD_BoM bom   ON m.MyBoMID    = bom.BoMID;
