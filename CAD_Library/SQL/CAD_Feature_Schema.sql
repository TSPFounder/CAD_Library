-- ============================================================
-- SQLite Schema for CAD_Feature JSON mapping
-- Generated from CAD_Library: CAD_Feature
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, Segment, CAD_Model,
--   CAD_Sketch, CAD_Station, CAD_Library (class),
--   CAD_Dimension (Dimension class)
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

-- Dimension (the refactored class used by CAD_Feature.MyDimensions)
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

-- ============================================================
-- CAD_Feature  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Feature (
    FeatureID               TEXT PRIMARY KEY,      -- synthetic key

    -- Identification
    Name                    TEXT,
    Version                 TEXT,

    -- Data
    GeometricFeatureType    INTEGER NOT NULL DEFAULT 0,
    -- GeometricFeatureTypeEnum:
    --  0=Hole           1=Joint          2=Thread        3=Chamfer
    --  4=Fillet         5=CounterBore    6=CounterSink   7=Bead
    --  8=Boss           9=Keyway        10=Leg          11=Arm
    -- 12=Mirror        13=Embossment    14=Rib          15=RoundedSlot
    -- 16=Gusset        17=Taper         18=SquareSlot   19=Shell
    -- 20=Web           21=Tab           22=Coil         23=Helicoil
    -- 24=RectangularPattern  25=CircularPattern
    -- 26=OtherPattern  27=Other

    -- Associations
    MyModelID               TEXT,
    OriginCSysID            TEXT,              -- Origin coordinate system

    -- Cursors
    CurrentDimensionID      TEXT,
    CurrentFeatureID        TEXT,              -- self-referential (sub-feature cursor)
    CurrentCAD_SketchID     TEXT,
    CurrentCAD_StationID    TEXT,
    CurrentLibraryID        TEXT,

    FOREIGN KEY (MyModelID)             REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (OriginCSysID)          REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CurrentDimensionID)    REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CurrentFeatureID)      REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (CurrentCAD_SketchID)   REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CurrentCAD_StationID)  REFERENCES CAD_Station(StationID),
    FOREIGN KEY (CurrentLibraryID)      REFERENCES CAD_Library(LibraryID)
);

-- ============================================================
-- CAD_Feature collection junction tables
-- ============================================================

-- ThreeDimOperations (List<Feature3DOperationEnum> — stored as integers)
CREATE TABLE IF NOT EXISTS CAD_Feature_3DOperation (
    FeatureID   TEXT NOT NULL,
    Operation   INTEGER NOT NULL,
    -- Feature3DOperationEnum: 0=Extrude,1=Revolve,2=Sweep,3=Loft
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, SortOrder),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID)
);

-- MyDimensions (List<Dimension>)
CREATE TABLE IF NOT EXISTS CAD_Feature_Dimension (
    FeatureID   TEXT NOT NULL,
    DimensionID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, DimensionID),
    FOREIGN KEY (FeatureID)   REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
);

-- Sketches (List<CAD_Sketch>)
CREATE TABLE IF NOT EXISTS CAD_Feature_Sketch (
    FeatureID   TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, SketchID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

-- Stations (List<CAD_Station>)
CREATE TABLE IF NOT EXISTS CAD_Feature_Station (
    FeatureID   TEXT NOT NULL,
    StationID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, StationID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (StationID) REFERENCES CAD_Station(StationID)
);

-- MyFeatures (List<CAD_Feature> — self-referential sub-features)
CREATE TABLE IF NOT EXISTS CAD_Feature_SubFeature (
    ParentFeatureID TEXT NOT NULL,
    ChildFeatureID  TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ParentFeatureID, ChildFeatureID),
    FOREIGN KEY (ParentFeatureID) REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (ChildFeatureID)  REFERENCES CAD_Feature(FeatureID)
);

-- MyLibraries (List<CAD_Library>)
CREATE TABLE IF NOT EXISTS CAD_Feature_Library (
    FeatureID   TEXT NOT NULL,
    LibraryID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FeatureID, LibraryID),
    FOREIGN KEY (FeatureID) REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (LibraryID) REFERENCES CAD_Library(LibraryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_feature_name         ON CAD_Feature(Name);
CREATE INDEX IF NOT EXISTS idx_feature_version      ON CAD_Feature(Version);
CREATE INDEX IF NOT EXISTS idx_feature_type         ON CAD_Feature(GeometricFeatureType);
CREATE INDEX IF NOT EXISTS idx_feature_model        ON CAD_Feature(MyModelID);
CREATE INDEX IF NOT EXISTS idx_feature_origin       ON CAD_Feature(OriginCSysID);
CREATE INDEX IF NOT EXISTS idx_feature_cur_dim      ON CAD_Feature(CurrentDimensionID);
CREATE INDEX IF NOT EXISTS idx_feature_cur_feat     ON CAD_Feature(CurrentFeatureID);
CREATE INDEX IF NOT EXISTS idx_feature_cur_sketch   ON CAD_Feature(CurrentCAD_SketchID);
CREATE INDEX IF NOT EXISTS idx_feature_cur_station  ON CAD_Feature(CurrentCAD_StationID);
CREATE INDEX IF NOT EXISTS idx_feature_cur_lib      ON CAD_Feature(CurrentLibraryID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: CAD_Feature with model/origin info and child counts
CREATE VIEW IF NOT EXISTS v_CAD_Feature_Detail AS
SELECT
    f.FeatureID,
    f.Name,
    f.Version,
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

    -- Current sketch
    sk.SketchID             AS CurrentSketchID,

    -- Current station
    st.Name                 AS CurrentStationName,
    st.MyType               AS CurrentStationType,

    -- Current sub-feature
    sf.Name                 AS CurrentSubFeatureName,

    -- Child counts
    (SELECT COUNT(*) FROM CAD_Feature_3DOperation f3d WHERE f3d.FeatureID = f.FeatureID) AS ThreeDOpCount,
    (SELECT COUNT(*) FROM CAD_Feature_Dimension   fd  WHERE fd.FeatureID  = f.FeatureID) AS DimensionCount,
    (SELECT COUNT(*) FROM CAD_Feature_Sketch      fs  WHERE fs.FeatureID  = f.FeatureID) AS SketchCount,
    (SELECT COUNT(*) FROM CAD_Feature_Station     fst WHERE fst.FeatureID = f.FeatureID) AS StationCount,
    (SELECT COUNT(*) FROM CAD_Feature_SubFeature  fsf WHERE fsf.ParentFeatureID = f.FeatureID) AS SubFeatureCount,
    (SELECT COUNT(*) FROM CAD_Feature_Library     fl  WHERE fl.FeatureID  = f.FeatureID) AS LibraryCount

FROM CAD_Feature f
LEFT JOIN CAD_Model m           ON f.MyModelID              = m.ModelID
LEFT JOIN CoordinateSystem cs   ON f.OriginCSysID           = cs.CoordinateSystemID
LEFT JOIN Point op              ON cs.OriginLocationPointID = op.PointID
LEFT JOIN CAD_Sketch sk         ON f.CurrentCAD_SketchID    = sk.SketchID
LEFT JOIN CAD_Station st        ON f.CurrentCAD_StationID   = st.StationID
LEFT JOIN CAD_Feature sf        ON f.CurrentFeatureID       = sf.FeatureID;

-- View: Feature dimensions with tolerance info
CREATE VIEW IF NOT EXISTS v_CAD_Feature_Dimensions AS
SELECT
    f.FeatureID,
    f.Name              AS FeatureName,
    f.GeometricFeatureType,
    fd.SortOrder,
    d.DimensionID,
    d.Name              AS DimensionName,
    d.MyDimensionType,
    CASE d.MyDimensionType
        WHEN 0 THEN 'Length'    WHEN 1 THEN 'Diameter'
        WHEN 2 THEN 'Radius'   WHEN 3 THEN 'Angle'
        WHEN 4 THEN 'Distance' WHEN 5 THEN 'Ordinal'
        WHEN 6 THEN 'Other'
    END AS DimensionTypeName,
    d.DimensionNominalValue,
    d.DimensionUpperLimitValue,
    d.DimensionLowerLimitValue,
    (d.DimensionUpperLimitValue - d.DimensionNominalValue)  AS PlusTolerance,
    (d.DimensionNominalValue - d.DimensionLowerLimitValue)  AS MinusTolerance
FROM CAD_Feature f
JOIN CAD_Feature_Dimension fd ON f.FeatureID    = fd.FeatureID
JOIN CAD_Dimension d          ON fd.DimensionID = d.DimensionID
ORDER BY f.FeatureID, fd.SortOrder;

-- View: Feature 3D operations in order
CREATE VIEW IF NOT EXISTS v_CAD_Feature_3DOperations AS
SELECT
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
    f3d.SortOrder,
    f3d.Operation,
    CASE f3d.Operation
        WHEN 0 THEN 'Extrude'
        WHEN 1 THEN 'Revolve'
        WHEN 2 THEN 'Sweep'
        WHEN 3 THEN 'Loft'
    END AS OperationName
FROM CAD_Feature f
JOIN CAD_Feature_3DOperation f3d ON f.FeatureID = f3d.FeatureID
ORDER BY f.FeatureID, f3d.SortOrder;

-- View: Feature sub-feature hierarchy (one level)
CREATE VIEW IF NOT EXISTS v_CAD_Feature_SubFeatures AS
SELECT
    pf.FeatureID        AS ParentFeatureID,
    pf.Name             AS ParentFeatureName,
    pf.GeometricFeatureType AS ParentFeatureType,
    fsf.SortOrder,
    cf.FeatureID        AS ChildFeatureID,
    cf.Name             AS ChildFeatureName,
    cf.GeometricFeatureType AS ChildFeatureType,
    CASE cf.GeometricFeatureType
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
    END AS ChildFeatureTypeName,
    cf.Version          AS ChildFeatureVersion
FROM CAD_Feature pf
JOIN CAD_Feature_SubFeature fsf ON pf.FeatureID     = fsf.ParentFeatureID
JOIN CAD_Feature cf             ON fsf.ChildFeatureID = cf.FeatureID
ORDER BY pf.FeatureID, fsf.SortOrder;

-- Recursive CTE: Full feature tree traversal (all depth levels)
CREATE VIEW IF NOT EXISTS v_CAD_Feature_Tree AS
WITH RECURSIVE feature_tree AS (
    -- Anchor: top-level features (those not appearing as a child in CAD_Feature_SubFeature)
    SELECT
        f.FeatureID,
        f.Name,
        f.GeometricFeatureType,
        f.FeatureID AS RootFeatureID,
        0           AS Depth,
        f.Name      AS TreePath
    FROM CAD_Feature f
    WHERE f.FeatureID NOT IN (
        SELECT ChildFeatureID FROM CAD_Feature_SubFeature
    )

    UNION ALL

    -- Recursive: children at each level
    SELECT
        cf.FeatureID,
        cf.Name,
        cf.GeometricFeatureType,
        ft.RootFeatureID,
        ft.Depth + 1,
        ft.TreePath || ' > ' || cf.Name
    FROM feature_tree ft
    JOIN CAD_Feature_SubFeature fsf ON ft.FeatureID       = fsf.ParentFeatureID
    JOIN CAD_Feature cf             ON fsf.ChildFeatureID = cf.FeatureID
)
SELECT * FROM feature_tree
ORDER BY RootFeatureID, Depth, FeatureID;
