-- ============================================================
-- SQLite Schema for CAD_Body JSON mapping
-- Generated from CAD_Library: CAD_Body (extends CAD_Feature)
-- ============================================================
-- CAD_Body inherits all CAD_Feature properties and adds its
-- own identification (Name, Version, PartNumber) and its own
-- Sketches / Features collections (shadowing the base class).
-- The JSON output from ToJson() includes BOTH base and derived.
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, Segment, CAD_Model,
--   CAD_Sketch, CAD_Station, CAD_Library (class),
--   CAD_Dimension, CAD_Feature
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
-- Shared CAD types (stubs — full definitions in their own schemas)
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

-- ============================================================
-- CAD_Body  (main table — flattens CAD_Feature base + CAD_Body)
-- ============================================================
-- The JSON serialization includes all properties from both
-- CAD_Feature (base) and CAD_Body (derived). Some properties
-- are shadowed (Name, Version, Sketches, Features); the table
-- captures the effective serialized shape.
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Body (
    BodyID          TEXT PRIMARY KEY,          -- synthetic key

    -- -------------------------------------------------------
    -- CAD_Body own identification (shadows base Name/Version)
    -- -------------------------------------------------------
    Name            TEXT,
    Version         TEXT,
    PartNumber      TEXT,

    -- -------------------------------------------------------
    -- Inherited from CAD_Feature
    -- -------------------------------------------------------
    GeometricFeatureType    INTEGER NOT NULL DEFAULT 0,
    -- GeometricFeatureTypeEnum (see CAD_Feature_Schema.sql for full listing)

    -- Model & coordinate system
    MyModelID       TEXT,
    OriginCSysID    TEXT,

    -- -------------------------------------------------------
    -- CAD_Body own cursors
    -- -------------------------------------------------------
    CurrentSketchID     TEXT,                  -- Body's own CurrentSketch
    CurrentFeatureID    TEXT,                  -- Body's own CurrentFeature

    -- -------------------------------------------------------
    -- Inherited CAD_Feature cursors (from base class)
    -- These may differ from the Body-level cursors above
    -- when the base class state diverges.
    -- -------------------------------------------------------
    Base_CurrentDimensionID     TEXT,
    Base_CurrentFeatureID       TEXT,          -- CAD_Feature.CurrentFeature
    Base_CurrentCAD_SketchID    TEXT,          -- CAD_Feature.CurrentCAD_Sketch
    Base_CurrentCAD_StationID   TEXT,
    Base_CurrentLibraryID       TEXT,

    FOREIGN KEY (MyModelID)                 REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (OriginCSysID)              REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CurrentSketchID)           REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CurrentFeatureID)          REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (Base_CurrentDimensionID)   REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (Base_CurrentFeatureID)     REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (Base_CurrentCAD_SketchID)  REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (Base_CurrentCAD_StationID) REFERENCES CAD_Station(StationID),
    FOREIGN KEY (Base_CurrentLibraryID)     REFERENCES CAD_Library(LibraryID)
);

-- ============================================================
-- CAD_Body own collection junction tables
-- ============================================================

-- Sketches (Body's own IReadOnlyList<CAD_Sketch>)
CREATE TABLE IF NOT EXISTS CAD_Body_Sketch (
    BodyID      TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, SketchID),
    FOREIGN KEY (BodyID)    REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

-- Features (Body's own IReadOnlyList<CAD_Feature>)
CREATE TABLE IF NOT EXISTS CAD_Body_Feature (
    BodyID      TEXT NOT NULL,
    FeatureID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, FeatureID),
    FOREIGN KEY (BodyID)    REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID)
);

-- ============================================================
-- Inherited CAD_Feature collection junction tables
-- (from the base class — serialized alongside Body's own)
-- ============================================================

-- ThreeDimOperations (inherited List<Feature3DOperationEnum>)
CREATE TABLE IF NOT EXISTS CAD_Body_3DOperation (
    BodyID      TEXT NOT NULL,
    Operation   INTEGER NOT NULL,
    -- Feature3DOperationEnum: 0=Extrude,1=Revolve,2=Sweep,3=Loft
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, SortOrder),
    FOREIGN KEY (BodyID) REFERENCES CAD_Body(BodyID)
);

-- MyDimensions (inherited List<Dimension>)
CREATE TABLE IF NOT EXISTS CAD_Body_Dimension (
    BodyID      TEXT NOT NULL,
    DimensionID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, DimensionID),
    FOREIGN KEY (BodyID)      REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
);

-- Base Sketches (inherited List<CAD_Sketch> from CAD_Feature.Sketches)
CREATE TABLE IF NOT EXISTS CAD_Body_BaseSketch (
    BodyID      TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, SketchID),
    FOREIGN KEY (BodyID)    REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

-- Base Stations (inherited List<CAD_Station>)
CREATE TABLE IF NOT EXISTS CAD_Body_Station (
    BodyID      TEXT NOT NULL,
    StationID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, StationID),
    FOREIGN KEY (BodyID)    REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (StationID) REFERENCES CAD_Station(StationID)
);

-- Base MyFeatures (inherited self-referential List<CAD_Feature>)
CREATE TABLE IF NOT EXISTS CAD_Body_BaseSubFeature (
    BodyID          TEXT NOT NULL,
    ChildFeatureID  TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, ChildFeatureID),
    FOREIGN KEY (BodyID)          REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (ChildFeatureID)  REFERENCES CAD_Feature(FeatureID)
);

-- Base MyLibraries (inherited List<CAD_Library>)
CREATE TABLE IF NOT EXISTS CAD_Body_Library (
    BodyID      TEXT NOT NULL,
    LibraryID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BodyID, LibraryID),
    FOREIGN KEY (BodyID)    REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (LibraryID) REFERENCES CAD_Library(LibraryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_body_name            ON CAD_Body(Name);
CREATE INDEX IF NOT EXISTS idx_body_version         ON CAD_Body(Version);
CREATE INDEX IF NOT EXISTS idx_body_part_number     ON CAD_Body(PartNumber);
CREATE INDEX IF NOT EXISTS idx_body_feature_type    ON CAD_Body(GeometricFeatureType);
CREATE INDEX IF NOT EXISTS idx_body_model           ON CAD_Body(MyModelID);
CREATE INDEX IF NOT EXISTS idx_body_origin          ON CAD_Body(OriginCSysID);
CREATE INDEX IF NOT EXISTS idx_body_cur_sketch      ON CAD_Body(CurrentSketchID);
CREATE INDEX IF NOT EXISTS idx_body_cur_feature     ON CAD_Body(CurrentFeatureID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: CAD_Body with model, origin, and child counts for
-- both its own collections and inherited base-class collections
CREATE VIEW IF NOT EXISTS v_CAD_Body_Detail AS
SELECT
    b.BodyID,
    b.Name,
    b.Version,
    b.PartNumber,
    b.GeometricFeatureType,
    CASE b.GeometricFeatureType
        WHEN 0  THEN 'Hole'            WHEN 1  THEN 'Joint'
        WHEN 2  THEN 'Thread'          WHEN 3  THEN 'Chamfer'
        WHEN 4  THEN 'Fillet'          WHEN 5  THEN 'CounterBore'
        WHEN 6  THEN 'CounterSink'     WHEN 7  THEN 'Bead'
        WHEN 8  THEN 'Boss'            WHEN 9  THEN 'Keyway'
        WHEN 10 THEN 'Leg'             WHEN 11 THEN 'Arm'
        WHEN 12 THEN 'Mirror'          WHEN 13 THEN 'Embossment'
        WHEN 14 THEN 'Rib'             WHEN 15 THEN 'RoundedSlot'
        WHEN 16 THEN 'Gusset'          WHEN 17 THEN 'Taper'
        WHEN 18 THEN 'SquareSlot'      WHEN 19 THEN 'Shell'
        WHEN 20 THEN 'Web'             WHEN 21 THEN 'Tab'
        WHEN 22 THEN 'Coil'            WHEN 23 THEN 'Helicoil'
        WHEN 24 THEN 'RectangularPattern'
        WHEN 25 THEN 'CircularPattern'
        WHEN 26 THEN 'OtherPattern'    WHEN 27 THEN 'Other'
    END AS FeatureTypeName,

    -- Model
    m.Name                  AS ModelName,
    m.CAD_AppName           AS ModelApp,
    CASE m.CAD_AppName
        WHEN 0 THEN 'Fusion360'    WHEN 1 THEN 'Solidworks'
        WHEN 2 THEN 'Blender'      WHEN 3 THEN 'UnReal4'
        WHEN 4 THEN 'UnReal5'      WHEN 5 THEN 'Unity'
        WHEN 6 THEN 'Other'
    END AS ModelAppText,

    -- Origin coordinate system
    cs.Name                 AS OriginCSysName,
    op.X_Value              AS Origin_X,
    op.Y_Value              AS Origin_Y,
    op.Z_Value_Cartesian    AS Origin_Z,

    -- Current sketch / feature cursors
    csk.SketchID            AS CurrentSketchID,
    cf.Name                 AS CurrentFeatureName,

    -- Body's own collection counts
    (SELECT COUNT(*) FROM CAD_Body_Sketch   bs  WHERE bs.BodyID = b.BodyID) AS SketchCount,
    (SELECT COUNT(*) FROM CAD_Body_Feature  bf  WHERE bf.BodyID = b.BodyID) AS FeatureCount,

    -- Inherited base-class collection counts
    (SELECT COUNT(*) FROM CAD_Body_3DOperation   b3d WHERE b3d.BodyID = b.BodyID) AS ThreeDOpCount,
    (SELECT COUNT(*) FROM CAD_Body_Dimension     bd  WHERE bd.BodyID  = b.BodyID) AS DimensionCount,
    (SELECT COUNT(*) FROM CAD_Body_BaseSketch    bbs WHERE bbs.BodyID = b.BodyID) AS BaseSketchCount,
    (SELECT COUNT(*) FROM CAD_Body_Station       bst WHERE bst.BodyID = b.BodyID) AS StationCount,
    (SELECT COUNT(*) FROM CAD_Body_BaseSubFeature bsf WHERE bsf.BodyID = b.BodyID) AS BaseSubFeatureCount,
    (SELECT COUNT(*) FROM CAD_Body_Library       bl  WHERE bl.BodyID  = b.BodyID) AS LibraryCount

FROM CAD_Body b
LEFT JOIN CAD_Model m           ON b.MyModelID              = m.ModelID
LEFT JOIN CoordinateSystem cs   ON b.OriginCSysID           = cs.CoordinateSystemID
LEFT JOIN Point op              ON cs.OriginLocationPointID = op.PointID
LEFT JOIN CAD_Sketch csk        ON b.CurrentSketchID        = csk.SketchID
LEFT JOIN CAD_Feature cf        ON b.CurrentFeatureID       = cf.FeatureID;

-- View: Body features in order
CREATE VIEW IF NOT EXISTS v_CAD_Body_Features AS
SELECT
    b.BodyID,
    b.Name              AS BodyName,
    b.PartNumber,
    bf.SortOrder,
    f.FeatureID,
    f.Name              AS FeatureName,
    f.GeometricFeatureType,
    CASE f.GeometricFeatureType
        WHEN 0  THEN 'Hole'            WHEN 1  THEN 'Joint'
        WHEN 2  THEN 'Thread'          WHEN 3  THEN 'Chamfer'
        WHEN 4  THEN 'Fillet'          WHEN 5  THEN 'CounterBore'
        WHEN 6  THEN 'CounterSink'     WHEN 7  THEN 'Bead'
        WHEN 8  THEN 'Boss'            WHEN 9  THEN 'Keyway'
        WHEN 10 THEN 'Leg'             WHEN 11 THEN 'Arm'
        WHEN 12 THEN 'Mirror'          WHEN 13 THEN 'Embossment'
        WHEN 14 THEN 'Rib'             WHEN 15 THEN 'RoundedSlot'
        WHEN 16 THEN 'Gusset'          WHEN 17 THEN 'Taper'
        WHEN 18 THEN 'SquareSlot'      WHEN 19 THEN 'Shell'
        WHEN 20 THEN 'Web'             WHEN 21 THEN 'Tab'
        WHEN 22 THEN 'Coil'            WHEN 23 THEN 'Helicoil'
        WHEN 24 THEN 'RectangularPattern'
        WHEN 25 THEN 'CircularPattern'
        WHEN 26 THEN 'OtherPattern'    WHEN 27 THEN 'Other'
    END AS FeatureTypeName,
    f.Version           AS FeatureVersion
FROM CAD_Body b
JOIN CAD_Body_Feature bf ON b.BodyID      = bf.BodyID
JOIN CAD_Feature f       ON bf.FeatureID  = f.FeatureID
ORDER BY b.BodyID, bf.SortOrder;

-- View: Body sketches in order
CREATE VIEW IF NOT EXISTS v_CAD_Body_Sketches AS
SELECT
    b.BodyID,
    b.Name          AS BodyName,
    b.PartNumber,
    bs.SortOrder,
    s.SketchID,
    s.Version       AS SketchVersion,
    s.IsTwoD,
    sp.Name         AS SketchPlaneName
FROM CAD_Body b
JOIN CAD_Body_Sketch bs     ON b.BodyID         = bs.BodyID
JOIN CAD_Sketch s           ON bs.SketchID       = s.SketchID
LEFT JOIN CAD_SketchPlane sp ON s.MySketchPlaneID = sp.SketchPlaneID
ORDER BY b.BodyID, bs.SortOrder;

-- View: Body 3D operations in order (inherited from CAD_Feature)
CREATE VIEW IF NOT EXISTS v_CAD_Body_3DOperations AS
SELECT
    b.BodyID,
    b.Name          AS BodyName,
    b3d.SortOrder,
    b3d.Operation,
    CASE b3d.Operation
        WHEN 0 THEN 'Extrude'
        WHEN 1 THEN 'Revolve'
        WHEN 2 THEN 'Sweep'
        WHEN 3 THEN 'Loft'
    END AS OperationName
FROM CAD_Body b
JOIN CAD_Body_3DOperation b3d ON b.BodyID = b3d.BodyID
ORDER BY b.BodyID, b3d.SortOrder;
