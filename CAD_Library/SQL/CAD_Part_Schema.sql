-- ============================================================
-- SQLite Schema for CAD_Part JSON mapping
-- Generated from CAD_Library: CAD_Part
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, Segment, CAD_Model,
--   CAD_Assembly, CAD_Sketch, CAD_Feature, CAD_Drawing,
--   CAD_Station, CAD_SketchPlane, CAD_Library (class),
--   CAD_Interface, MassProperties, CAD_Dimension,
--   MathParameter, CAD_Parameter, CAD_ParameterValue,
--   UnitOfMeasure
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

CREATE TABLE IF NOT EXISTS Segment (
    SegmentID       TEXT PRIMARY KEY,
    SegmentType     INTEGER NOT NULL DEFAULT 0,
    IsEdge          INTEGER NOT NULL DEFAULT 0,
    Length          REAL NOT NULL DEFAULT 0.0,
    StartPointID    TEXT,
    EndPointID      TEXT,
    MidPointID      TEXT,
    FocalPoint1ID   TEXT,
    FocalPoint2ID   TEXT,
    VertexID        TEXT,
    CurrentVectorID         TEXT,
    MyCoordinateSystemID    TEXT,
    PreviousSegmentID       TEXT,
    NextSegmentID           TEXT,
    CurrentConnectedSegmentID TEXT,
    FOREIGN KEY (StartPointID)  REFERENCES Point(PointID),
    FOREIGN KEY (EndPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (MidPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (CurrentVectorID) REFERENCES Vector(VectorID),
    FOREIGN KEY (MyCoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- ============================================================
-- Shared CAD types (stubs — full definitions in their own schema files)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Model (
    ModelID     TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    Description TEXT,
    FilePath    TEXT,
    CAD_AppName INTEGER NOT NULL DEFAULT 0,
    ModelType   INTEGER NOT NULL DEFAULT 0,
    FileType    INTEGER NOT NULL DEFAULT 0,
    CurrentStationID    TEXT,
    CurrentSketchID     TEXT,
    CurrentFeatureID    TEXT,
    CurrentPartID       TEXT,
    CurrentDrawingID    TEXT,
    CurrentAssemblyID   TEXT,
    MySystemID  TEXT,
    MyBoMID     TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Assembly (
    AssemblyID          TEXT PRIMARY KEY,
    Name                TEXT,
    Version             TEXT,
    Description         TEXT,
    IsSubAssembly       INTEGER NOT NULL DEFAULT 0,
    IsConfigurationItem INTEGER NOT NULL DEFAULT 0,
    MyPositionPointID   TEXT,
    MyOrientationVectorID TEXT,
    CurrentCSID         TEXT,
    CurrentComponentID  TEXT,
    PreviousComponentID TEXT,
    NextComponentID     TEXT,
    MyModelID           TEXT,
    CurrentConfigurationID TEXT,
    MyPartID            TEXT,
    CurrentInterfaceID  TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Sketch (
    SketchID        TEXT PRIMARY KEY,
    Version         TEXT,
    IsTwoD          INTEGER NOT NULL DEFAULT 0,
    AreaParameterID         TEXT,
    PerimeterLengthParameterID TEXT,
    MyModelID               TEXT,
    MySketchPlaneID         TEXT,
    CurrentPointID          TEXT,
    CurrentSegmentID        TEXT,
    PreviousSegmentID       TEXT,
    CurrentParameterID      TEXT,
    CurrentDimensionID      TEXT,
    CurrentConstraintID     TEXT,
    CurrentCoordinateSystemID TEXT,
    BaseCoordinateSystemID  TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Feature (
    FeatureID               TEXT PRIMARY KEY,
    Name                    TEXT,
    Version                 TEXT,
    GeometricFeatureType    INTEGER NOT NULL DEFAULT 0,
    MyModelID               TEXT,
    OriginCSysID            TEXT,
    CurrentDimensionID      TEXT,
    CurrentFeatureID        TEXT,
    CurrentCAD_SketchID     TEXT,
    CurrentCAD_StationID    TEXT,
    CurrentLibraryID        TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Body (
    BodyID          TEXT PRIMARY KEY,
    Name            TEXT,
    Version         TEXT,
    PartNumber      TEXT,
    GeometricFeatureType    INTEGER NOT NULL DEFAULT 0,
    MyModelID               TEXT,
    OriginCSysID            TEXT,
    CurrentSketchID         TEXT,
    CurrentFeatureID        TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Drawing (
    DrawingID       TEXT PRIMARY KEY,
    Title           TEXT,
    DrawingNumber   TEXT,
    Revision        TEXT,
    DrawingStandard INTEGER NOT NULL DEFAULT 0,
    MyFormat        INTEGER NOT NULL DEFAULT 0,
    MyDrawingSize   INTEGER NOT NULL DEFAULT 4,
    MyAssemblyID    TEXT,
    MyModelID       TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Station (
    StationID       TEXT PRIMARY KEY,
    Name            TEXT,
    ID              TEXT,
    Version         TEXT,
    MyType          INTEGER NOT NULL DEFAULT 0,
    AxialLocation   REAL NOT NULL DEFAULT 0.0,
    RadialLocation  REAL NOT NULL DEFAULT 0.0,
    AngularLocation REAL NOT NULL DEFAULT 0.0,
    WingLocation    REAL NOT NULL DEFAULT 0.0,
    FloorLocation   REAL NOT NULL DEFAULT 0.0,
    MyModelID       TEXT,
    CurrentSketchPlaneID TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Library (
    LibraryID   TEXT PRIMARY KEY,
    Name        TEXT,
    Description TEXT,
    LocalPath   TEXT,
    Url         TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Interface (
    InterfaceID     TEXT PRIMARY KEY,
    Name            TEXT,
    ID              TEXT,
    Version         TEXT,
    InterfaceKind   INTEGER,
    CurrentContactPointID       TEXT,
    CurrentContactSurfaceID     TEXT,
    MyJointID           TEXT,
    BaseComponentID     TEXT,
    MatingComponentID   TEXT
);

CREATE TABLE IF NOT EXISTS MassProperties (
    MassPropertiesID            TEXT PRIMARY KEY,
    Mass                        REAL NOT NULL DEFAULT 0.0,
    CenterOfGravityPointID      TEXT,
    MyCAD_PartID                TEXT,
    CurrentCoordinateSystemID   TEXT,
    PrincipalMomentsOfInertia_JSON  TEXT,
    CurrentMomentsOfInertia_JSON    TEXT,
    FOREIGN KEY (CenterOfGravityPointID) REFERENCES Point(PointID),
    FOREIGN KEY (CurrentCoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

CREATE TABLE IF NOT EXISTS UnitOfMeasure (
    UnitOfMeasureID TEXT PRIMARY KEY,
    Name            TEXT,
    Description     TEXT,
    SymbolName      TEXT,
    UnitValue       REAL NOT NULL DEFAULT 0.0,
    SystemOfUnits   INTEGER NOT NULL DEFAULT 0,
    IsBaseUnit      INTEGER NOT NULL DEFAULT 0
);

-- Dimension (the refactored class used by CAD_Part.MyDimensions)
CREATE TABLE IF NOT EXISTS CAD_Dimension (
    DimensionID     TEXT PRIMARY KEY,
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 1,
    MyDrawingID     TEXT,
    Description     TEXT,
    IsOrdinate      INTEGER NOT NULL DEFAULT 0,
    CenterPointID           TEXT,
    LeaderLineEndPointID    TEXT,
    LeaderLineBendPointID   TEXT,
    DimensionPointID        TEXT,
    ReferencePointID        TEXT,
    MyModelID       TEXT,
    MySegmentID     TEXT,
    DimensionNominalValue       REAL NOT NULL DEFAULT 0.0,
    DimensionUpperLimitValue    REAL NOT NULL DEFAULT 0.0,
    DimensionLowerLimitValue    REAL NOT NULL DEFAULT 0.0,
    MyDimensionType             INTEGER NOT NULL DEFAULT 0,
    EngineeringUnitID   TEXT,
    CurrentParameterID  TEXT
);

-- MathParameter (the refactored Parameter class used by CAD_Part.MyParameters)
CREATE TABLE IF NOT EXISTS MathParameter (
    MathParameterID     TEXT PRIMARY KEY,
    Name                TEXT,
    PartNumber          TEXT,
    Description         TEXT,
    Comments            TEXT,
    MyParameterType     INTEGER NOT NULL DEFAULT 0,
    SolidWorksParameterName     TEXT,
    Fusion360ParameterName      TEXT,
    CurrentDimensionID  TEXT,
    CurrentModelID      TEXT,
    MyUnitsID           TEXT,
    DesignTableID       TEXT,
    ExpressionText      TEXT
);

-- ============================================================
-- CAD_Constraint (referenced by CAD_Sketch, relevant to Part context)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Constraint (
    ConstraintID    TEXT PRIMARY KEY,          -- derived from ID property or generated
    Name            TEXT,
    ID              TEXT,                      -- the class's own ID property
    Description     TEXT,
    Type            INTEGER NOT NULL DEFAULT 16,
    -- ConstraintType: 0=Horizontal,1=Vertical,2=Distance,3=Coincident,4=Tangent,
    -- 5=Angle,6=Equal,7=Parallel,8=Perpendicular,9=Fixed,10=Midpoint,11=Midplane,
    -- 12=Concentric,13=Collinear,14=Symmetry,15=Curvature,16=Other

    -- Associations
    CurrentFeatureID    TEXT,
    PreviousFeatureID   TEXT,
    CurrentModelID      TEXT,

    FOREIGN KEY (CurrentFeatureID)  REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (PreviousFeatureID) REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (CurrentModelID)    REFERENCES CAD_Model(ModelID)
);

-- CAD_Constraint -> Features
CREATE TABLE IF NOT EXISTS CAD_Constraint_Feature (
    ConstraintID    TEXT NOT NULL,
    FeatureID       TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ConstraintID, FeatureID),
    FOREIGN KEY (ConstraintID) REFERENCES CAD_Constraint(ConstraintID),
    FOREIGN KEY (FeatureID)    REFERENCES CAD_Feature(FeatureID)
);

-- CAD_Constraint -> Models
CREATE TABLE IF NOT EXISTS CAD_Constraint_Model (
    ConstraintID    TEXT NOT NULL,
    ModelID         TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ConstraintID, ModelID),
    FOREIGN KEY (ConstraintID) REFERENCES CAD_Constraint(ConstraintID),
    FOREIGN KEY (ModelID)      REFERENCES CAD_Model(ModelID)
);

-- ============================================================
-- CAD_SketchElement
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_SketchElement (
    SketchElementID TEXT PRIMARY KEY,          -- synthetic key
    Name            TEXT,
    Version         TEXT,
    Path            TEXT,
    ElementType     INTEGER NOT NULL DEFAULT 0,
    -- SketchElemTypeEnum: 0=StartPoint,1=EndPoint,2=MidPoint,3=ControlPoint,
    -- 4=Line,5=Rectangle,6=Circle,7=Parabola,8=Ellipse,9=Contour,10=Arc,
    -- 11=Spline,12=Slot,13=BreakLine,14=Centerline,15=Centerpoint,
    -- 16=WorkPoint,17=WorkLine
    IsWorkElement   INTEGER NOT NULL DEFAULT 0,    -- bool

    -- Named points
    CurrentPointID  TEXT,
    StartPointID    TEXT,
    EndPointID      TEXT,
    MidPointID      TEXT,
    ControlPointID  TEXT,

    -- Current primitive reference
    CurrentPrimitiveID TEXT,

    FOREIGN KEY (CurrentPointID)  REFERENCES Point(PointID),
    FOREIGN KEY (StartPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (EndPointID)      REFERENCES Point(PointID),
    FOREIGN KEY (MidPointID)      REFERENCES Point(PointID),
    FOREIGN KEY (ControlPointID)  REFERENCES Point(PointID)
);

-- CAD_SketchElement -> Points
CREATE TABLE IF NOT EXISTS CAD_SketchElement_Point (
    SketchElementID TEXT NOT NULL,
    PointID         TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchElementID, PointID, SortOrder),
    FOREIGN KEY (SketchElementID) REFERENCES CAD_SketchElement(SketchElementID),
    FOREIGN KEY (PointID)         REFERENCES Point(PointID)
);

-- ============================================================
-- Primitive (Mathematics)
-- ============================================================

CREATE TABLE IF NOT EXISTS Primitive (
    PrimitiveID     TEXT PRIMARY KEY,          -- synthetic key
    Name            TEXT,
    Version         TEXT,
    Is2D            INTEGER NOT NULL DEFAULT 0,    -- bool
    TwoDType        INTEGER NOT NULL DEFAULT 8,    -- TwoDPrimitiveTypeEnum: 0=Square,...,8=Other
    ThreeDType      INTEGER NOT NULL DEFAULT 7,    -- ThreeDPrimitiveTypeEnum: 0=Sphere,...,7=Other

    -- Point cursors
    CurrentPointID  TEXT,
    NextPointID     TEXT,
    PreviousPointID TEXT,
    CenterPointID   TEXT,

    -- Segment cursors
    CurrentSegmentID    TEXT,
    NextSegmentID       TEXT,
    PreviousSegmentID   TEXT,

    FOREIGN KEY (CurrentPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (NextPointID)       REFERENCES Point(PointID),
    FOREIGN KEY (PreviousPointID)   REFERENCES Point(PointID),
    FOREIGN KEY (CenterPointID)     REFERENCES Point(PointID),
    FOREIGN KEY (CurrentSegmentID)  REFERENCES Segment(SegmentID),
    FOREIGN KEY (NextSegmentID)     REFERENCES Segment(SegmentID),
    FOREIGN KEY (PreviousSegmentID) REFERENCES Segment(SegmentID)
);

-- Primitive -> MyPoints
CREATE TABLE IF NOT EXISTS Primitive_Point (
    PrimitiveID TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PrimitiveID, PointID, SortOrder),
    FOREIGN KEY (PrimitiveID) REFERENCES Primitive(PrimitiveID),
    FOREIGN KEY (PointID)     REFERENCES Point(PointID)
);

-- Primitive -> Vertices
CREATE TABLE IF NOT EXISTS Primitive_Vertex (
    PrimitiveID TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PrimitiveID, PointID, SortOrder),
    FOREIGN KEY (PrimitiveID) REFERENCES Primitive(PrimitiveID),
    FOREIGN KEY (PointID)     REFERENCES Point(PointID)
);

-- Primitive -> MySegments
CREATE TABLE IF NOT EXISTS Primitive_Segment (
    PrimitiveID TEXT NOT NULL,
    SegmentID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PrimitiveID, SegmentID, SortOrder),
    FOREIGN KEY (PrimitiveID) REFERENCES Primitive(PrimitiveID),
    FOREIGN KEY (SegmentID)   REFERENCES Segment(SegmentID)
);

-- CAD_SketchElement -> Primitives
CREATE TABLE IF NOT EXISTS CAD_SketchElement_Primitive (
    SketchElementID TEXT NOT NULL,
    PrimitiveID     TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchElementID, PrimitiveID),
    FOREIGN KEY (SketchElementID) REFERENCES CAD_SketchElement(SketchElementID),
    FOREIGN KEY (PrimitiveID)     REFERENCES Primitive(PrimitiveID)
);

-- ============================================================
-- Quadrilateral (Mathematics — used by CAD_DrawingView)
-- ============================================================

CREATE TABLE IF NOT EXISTS Quadrilateral (
    QuadrilateralID TEXT PRIMARY KEY,
    Name            TEXT,
    Description     TEXT,
    Vertex1PointID  TEXT,
    Vertex2PointID  TEXT,
    Vertex3PointID  TEXT,
    Vertex4PointID  TEXT,
    FOREIGN KEY (Vertex1PointID) REFERENCES Point(PointID),
    FOREIGN KEY (Vertex2PointID) REFERENCES Point(PointID),
    FOREIGN KEY (Vertex3PointID) REFERENCES Point(PointID),
    FOREIGN KEY (Vertex4PointID) REFERENCES Point(PointID)
);

-- ============================================================
-- CAD_Part  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Part (
    PartID          TEXT PRIMARY KEY,          -- synthetic key
    Name            TEXT,
    Version         TEXT,
    PartNumber      TEXT,
    Description     TEXT,

    -- Mass properties
    CurrentMassPropertiesID TEXT,
    MyMassPropertiesID      TEXT,              -- the always-present MassProperties instance
    CenterOfMassPointID     TEXT,

    -- Model cursor
    CurrentModelID  TEXT,

    -- Coordinate system cursor
    CurrentCoordinateSystemID TEXT,

    -- Sketch cursor
    CurrentSketchID TEXT,

    -- Feature cursor
    CurrentFeatureID TEXT,

    -- Body cursor
    CurrentBodyID   TEXT,

    -- Drawing cursor
    CurrentDrawingID TEXT,

    -- Dimension cursor
    CurrentDimensionID TEXT,

    -- Parameter cursor
    CurrentParameterID TEXT,

    -- Assembly reference
    MyAssemblyID    TEXT,

    -- Library cursor
    CurrentLibraryID TEXT,

    -- Interface cursor
    CurrentInterfaceID TEXT,

    FOREIGN KEY (CurrentMassPropertiesID)   REFERENCES MassProperties(MassPropertiesID),
    FOREIGN KEY (MyMassPropertiesID)        REFERENCES MassProperties(MassPropertiesID),
    FOREIGN KEY (CenterOfMassPointID)       REFERENCES Point(PointID),
    FOREIGN KEY (CurrentModelID)            REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (CurrentCoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CurrentSketchID)           REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CurrentFeatureID)          REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (CurrentBodyID)             REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (CurrentDrawingID)          REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (CurrentDimensionID)        REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CurrentParameterID)        REFERENCES MathParameter(MathParameterID),
    FOREIGN KEY (MyAssemblyID)              REFERENCES CAD_Assembly(AssemblyID),
    FOREIGN KEY (CurrentLibraryID)          REFERENCES CAD_Library(LibraryID),
    FOREIGN KEY (CurrentInterfaceID)        REFERENCES CAD_Interface(InterfaceID)
);

-- ============================================================
-- CAD_Part collection junction tables
-- ============================================================

-- MySketches (List<CAD_Sketch>)
CREATE TABLE IF NOT EXISTS CAD_Part_Sketch (
    PartID      TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, SketchID),
    FOREIGN KEY (PartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

-- MyFeatures (List<CAD_Feature>)
CREATE TABLE IF NOT EXISTS CAD_Part_Feature (
    PartID      TEXT NOT NULL,
    FeatureID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, FeatureID),
    FOREIGN KEY (PartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID)
);

-- MyBodies (List<CAD_Body>)
CREATE TABLE IF NOT EXISTS CAD_Part_Body (
    PartID      TEXT NOT NULL,
    BodyID      TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, BodyID),
    FOREIGN KEY (PartID) REFERENCES CAD_Part(PartID),
    FOREIGN KEY (BodyID) REFERENCES CAD_Body(BodyID)
);

-- MyDrawings (List<CAD_Drawing>)
CREATE TABLE IF NOT EXISTS CAD_Part_Drawing (
    PartID      TEXT NOT NULL,
    DrawingID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, DrawingID),
    FOREIGN KEY (PartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID)
);

-- MyDimensions (List<Dimension>)
CREATE TABLE IF NOT EXISTS CAD_Part_Dimension (
    PartID      TEXT NOT NULL,
    DimensionID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, DimensionID),
    FOREIGN KEY (PartID)      REFERENCES CAD_Part(PartID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
);

-- MyParameters (List<Parameter>)
CREATE TABLE IF NOT EXISTS CAD_Part_Parameter (
    PartID          TEXT NOT NULL,
    MathParameterID TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, MathParameterID),
    FOREIGN KEY (PartID)          REFERENCES CAD_Part(PartID),
    FOREIGN KEY (MathParameterID) REFERENCES MathParameter(MathParameterID)
);

-- MyModels (List<CAD_Model>)
CREATE TABLE IF NOT EXISTS CAD_Part_Model (
    PartID      TEXT NOT NULL,
    ModelID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, ModelID),
    FOREIGN KEY (PartID)  REFERENCES CAD_Part(PartID),
    FOREIGN KEY (ModelID) REFERENCES CAD_Model(ModelID)
);

-- MyCoordinateSystems (List<CoordinateSystem>)
CREATE TABLE IF NOT EXISTS CAD_Part_CoordinateSystem (
    PartID              TEXT NOT NULL,
    CoordinateSystemID  TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, CoordinateSystemID),
    FOREIGN KEY (PartID)             REFERENCES CAD_Part(PartID),
    FOREIGN KEY (CoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- MyInterfaces (List<CAD_Interface>)
CREATE TABLE IF NOT EXISTS CAD_Part_Interface (
    PartID      TEXT NOT NULL,
    InterfaceID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, InterfaceID),
    FOREIGN KEY (PartID)      REFERENCES CAD_Part(PartID),
    FOREIGN KEY (InterfaceID) REFERENCES CAD_Interface(InterfaceID)
);

-- MyLibraries (List<CAD_Library>)
CREATE TABLE IF NOT EXISTS CAD_Part_Library (
    PartID      TEXT NOT NULL,
    LibraryID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, LibraryID),
    FOREIGN KEY (PartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (LibraryID) REFERENCES CAD_Library(LibraryID)
);

-- MyMassPropertiesList (List<MassProperties>)
CREATE TABLE IF NOT EXISTS CAD_Part_MassProperties (
    PartID              TEXT NOT NULL,
    MassPropertiesID    TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PartID, MassPropertiesID),
    FOREIGN KEY (PartID)            REFERENCES CAD_Part(PartID),
    FOREIGN KEY (MassPropertiesID)  REFERENCES MassProperties(MassPropertiesID)
);

-- Station collections (4 typed lists unified with category discriminator)
-- AxialStations, RadialStations, AngularStations, WingStations
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
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_part_name            ON CAD_Part(Name);
CREATE INDEX IF NOT EXISTS idx_part_number          ON CAD_Part(PartNumber);
CREATE INDEX IF NOT EXISTS idx_part_version         ON CAD_Part(Version);
CREATE INDEX IF NOT EXISTS idx_part_assembly        ON CAD_Part(MyAssemblyID);
CREATE INDEX IF NOT EXISTS idx_part_cur_model       ON CAD_Part(CurrentModelID);
CREATE INDEX IF NOT EXISTS idx_part_cur_sketch      ON CAD_Part(CurrentSketchID);
CREATE INDEX IF NOT EXISTS idx_part_cur_feature     ON CAD_Part(CurrentFeatureID);
CREATE INDEX IF NOT EXISTS idx_part_cur_body        ON CAD_Part(CurrentBodyID);
CREATE INDEX IF NOT EXISTS idx_part_cur_drawing     ON CAD_Part(CurrentDrawingID);
CREATE INDEX IF NOT EXISTS idx_part_cur_dim         ON CAD_Part(CurrentDimensionID);
CREATE INDEX IF NOT EXISTS idx_part_cur_param       ON CAD_Part(CurrentParameterID);
CREATE INDEX IF NOT EXISTS idx_part_cur_library     ON CAD_Part(CurrentLibraryID);
CREATE INDEX IF NOT EXISTS idx_part_mass_props      ON CAD_Part(MyMassPropertiesID);
CREATE INDEX IF NOT EXISTS idx_constraint_type      ON CAD_Constraint(Type);
CREATE INDEX IF NOT EXISTS idx_constraint_name      ON CAD_Constraint(Name);
CREATE INDEX IF NOT EXISTS idx_sketchelem_type      ON CAD_SketchElement(ElementType);
CREATE INDEX IF NOT EXISTS idx_primitive_2d_type    ON Primitive(TwoDType);
CREATE INDEX IF NOT EXISTS idx_primitive_3d_type    ON Primitive(ThreeDType);
CREATE INDEX IF NOT EXISTS idx_quad_name            ON Quadrilateral(Name);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: CAD_Part with mass, model info, and child counts
CREATE VIEW IF NOT EXISTS v_CAD_Part_Detail AS
SELECT
    p.PartID,
    p.Name,
    p.Version,
    p.PartNumber,
    p.Description,

    -- Mass properties
    mp.Mass,
    cog.X_Value             AS CenterOfMass_X,
    cog.Y_Value             AS CenterOfMass_Y,
    cog.Z_Value_Cartesian   AS CenterOfMass_Z,

    -- Current model info
    m.Name                  AS CurrentModelName,
    m.CAD_AppName           AS CurrentModelApp,
    CASE m.CAD_AppName
        WHEN 0 THEN 'Fusion360'
        WHEN 1 THEN 'Solidworks'
        WHEN 2 THEN 'Blender'
        WHEN 3 THEN 'UnReal4'
        WHEN 4 THEN 'UnReal5'
        WHEN 5 THEN 'Unity'
        WHEN 6 THEN 'Other'
    END AS CurrentModelAppText,

    -- Assembly
    asm.Name                AS AssemblyName,

    -- Child counts
    (SELECT COUNT(*) FROM CAD_Part_Sketch    ps  WHERE ps.PartID  = p.PartID) AS SketchCount,
    (SELECT COUNT(*) FROM CAD_Part_Feature   pf  WHERE pf.PartID  = p.PartID) AS FeatureCount,
    (SELECT COUNT(*) FROM CAD_Part_Body      pb  WHERE pb.PartID  = p.PartID) AS BodyCount,
    (SELECT COUNT(*) FROM CAD_Part_Drawing   pd  WHERE pd.PartID  = p.PartID) AS DrawingCount,
    (SELECT COUNT(*) FROM CAD_Part_Dimension pdm WHERE pdm.PartID = p.PartID) AS DimensionCount,
    (SELECT COUNT(*) FROM CAD_Part_Parameter pp  WHERE pp.PartID  = p.PartID) AS ParameterCount,
    (SELECT COUNT(*) FROM CAD_Part_Model     pm  WHERE pm.PartID  = p.PartID) AS ModelCount,
    (SELECT COUNT(*) FROM CAD_Part_Interface pi  WHERE pi.PartID  = p.PartID) AS InterfaceCount,
    (SELECT COUNT(*) FROM CAD_Part_Library   pl  WHERE pl.PartID  = p.PartID) AS LibraryCount,
    (SELECT COUNT(*) FROM CAD_Part_CoordinateSystem pcs WHERE pcs.PartID = p.PartID) AS CoordSysCount,
    (SELECT COUNT(*) FROM CAD_Part_Station   pst WHERE pst.PartID = p.PartID AND pst.StationCategory = 'Axial')   AS AxialStationCount,
    (SELECT COUNT(*) FROM CAD_Part_Station   pst WHERE pst.PartID = p.PartID AND pst.StationCategory = 'Radial')  AS RadialStationCount,
    (SELECT COUNT(*) FROM CAD_Part_Station   pst WHERE pst.PartID = p.PartID AND pst.StationCategory = 'Angular') AS AngularStationCount,
    (SELECT COUNT(*) FROM CAD_Part_Station   pst WHERE pst.PartID = p.PartID AND pst.StationCategory = 'Wing')    AS WingStationCount

FROM CAD_Part p
LEFT JOIN MassProperties mp     ON p.MyMassPropertiesID    = mp.MassPropertiesID
LEFT JOIN Point cog             ON p.CenterOfMassPointID   = cog.PointID
LEFT JOIN CAD_Model m           ON p.CurrentModelID        = m.ModelID
LEFT JOIN CAD_Assembly asm      ON p.MyAssemblyID          = asm.AssemblyID;

-- View: Part dimensions with tolerance info
CREATE VIEW IF NOT EXISTS v_CAD_Part_Dimensions AS
SELECT
    p.PartID,
    p.Name              AS PartName,
    p.PartNumber,
    pdm.SortOrder,
    d.DimensionID,
    d.Name              AS DimensionName,
    d.MyDimensionType,
    CASE d.MyDimensionType
        WHEN 0 THEN 'Length'
        WHEN 1 THEN 'Diameter'
        WHEN 2 THEN 'Radius'
        WHEN 3 THEN 'Angle'
        WHEN 4 THEN 'Distance'
        WHEN 5 THEN 'Ordinal'
        WHEN 6 THEN 'Other'
    END AS DimensionTypeName,
    d.DimensionNominalValue,
    d.DimensionUpperLimitValue,
    d.DimensionLowerLimitValue,
    (d.DimensionUpperLimitValue - d.DimensionNominalValue)  AS PlusTolerance,
    (d.DimensionNominalValue - d.DimensionLowerLimitValue)  AS MinusTolerance,
    u.Name              AS UnitName,
    u.SymbolName        AS UnitSymbol
FROM CAD_Part p
JOIN CAD_Part_Dimension pdm ON p.PartID       = pdm.PartID
JOIN CAD_Dimension d        ON pdm.DimensionID = d.DimensionID
LEFT JOIN UnitOfMeasure u   ON d.EngineeringUnitID = u.UnitOfMeasureID
ORDER BY p.PartID, pdm.SortOrder;

-- View: Part features with type labels
CREATE VIEW IF NOT EXISTS v_CAD_Part_Features AS
SELECT
    p.PartID,
    p.Name          AS PartName,
    pf.SortOrder,
    f.FeatureID,
    f.Name          AS FeatureName,
    f.GeometricFeatureType,
    CASE f.GeometricFeatureType
        WHEN 0  THEN 'Hole'        WHEN 1  THEN 'Joint'
        WHEN 2  THEN 'Thread'      WHEN 3  THEN 'Chamfer'
        WHEN 4  THEN 'Fillet'      WHEN 5  THEN 'CounterBore'
        WHEN 6  THEN 'CounterSink' WHEN 7  THEN 'Bead'
        WHEN 8  THEN 'Boss'        WHEN 9  THEN 'Keyway'
        WHEN 10 THEN 'Leg'         WHEN 11 THEN 'Arm'
        WHEN 12 THEN 'Mirror'      WHEN 13 THEN 'Embossment'
        WHEN 14 THEN 'Rib'         WHEN 15 THEN 'RoundedSlot'
        WHEN 16 THEN 'Gusset'      WHEN 17 THEN 'Taper'
        WHEN 18 THEN 'SquareSlot'  WHEN 19 THEN 'Shell'
        WHEN 20 THEN 'Web'         WHEN 21 THEN 'Tab'
        WHEN 22 THEN 'Coil'        WHEN 23 THEN 'Helicoil'
        WHEN 24 THEN 'RectangularPattern' WHEN 25 THEN 'CircularPattern'
        WHEN 26 THEN 'OtherPattern' WHEN 27 THEN 'Other'
    END AS FeatureTypeName
FROM CAD_Part p
JOIN CAD_Part_Feature pf ON p.PartID      = pf.PartID
JOIN CAD_Feature f       ON pf.FeatureID  = f.FeatureID
ORDER BY p.PartID, pf.SortOrder;
