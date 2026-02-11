-- ============================================================
-- SQLite Schema for CAD_Hole JSON mapping
-- Generated from CAD_Library: CAD_Hole (extends CAD_Feature)
-- Also includes: Thread (extends CAD_Feature)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, CAD_Model, CAD_Feature,
--   CAD_Dimension, CAD_Parameter, CAD_Sketch, CAD_Station,
--   CAD_Library (class)
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

-- ============================================================
-- Shared CAD types (stubs)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Model (
    ModelID     TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    Description TEXT,
    FilePath    TEXT,
    CAD_AppName INTEGER NOT NULL DEFAULT 0,
    ModelType   INTEGER NOT NULL DEFAULT 0,
    FileType    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Feature (
    FeatureID   TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    GeometricFeatureType INTEGER NOT NULL DEFAULT 0,
    MyModelID   TEXT,
    FOREIGN KEY (MyModelID) REFERENCES CAD_Model(ModelID)
);

CREATE TABLE IF NOT EXISTS CAD_Dimension (
    DimensionID     TEXT PRIMARY KEY,
    Description     TEXT,
    MyDimensionType INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Parameter (
    ParameterID TEXT PRIMARY KEY,
    Name        TEXT,
    Description TEXT,
    MyParameterType INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Sketch (
    SketchID    TEXT PRIMARY KEY,
    Version     TEXT,
    IsTwoD      INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Station (
    StationID   TEXT PRIMARY KEY,
    Name        TEXT,
    MyType      INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Library (
    LibraryID   TEXT PRIMARY KEY,
    Name        TEXT,
    Description TEXT
);

-- ============================================================
-- Thread  (extends CAD_Feature — flattened)
-- ============================================================

CREATE TABLE IF NOT EXISTS Thread (
    ThreadID        TEXT PRIMARY KEY,          -- synthetic key

    -- Inherited from CAD_Feature
    Name            TEXT,
    Version         TEXT,
    GeometricFeatureType INTEGER NOT NULL DEFAULT 0,
    -- (see CAD_Feature_Schema.sql for 28-value enum)
    MyModelID       TEXT,
    OriginPointID   TEXT,
    CurrentDimensionID  TEXT,
    CurrentFeatureID    TEXT,
    CurrentSketchID     TEXT,
    CurrentStationID    TEXT,
    CurrentLibraryID    TEXT,

    -- Own properties
    Designation             TEXT,
    ThreadClass             TEXT,
    MaterialSpecification   TEXT,
    SurfaceFinish           TEXT,

    -- Flags
    IsInternal          INTEGER NOT NULL DEFAULT 0,
    IsFine              INTEGER NOT NULL DEFAULT 0,
    IsMultithreaded     INTEGER NOT NULL DEFAULT 0,
    IsReverseThreaded   INTEGER NOT NULL DEFAULT 0,
    IsMetric            INTEGER NOT NULL DEFAULT 0,
    IsSquare            INTEGER NOT NULL DEFAULT 0,

    -- Thread starts
    Starts              INTEGER NOT NULL DEFAULT 1,

    -- Standard
    ThreadStandard      INTEGER NOT NULL DEFAULT 0,
    -- ThreadStandardEnum:
    --   0=UN (Unified National), 1=UNR (UN Rounded),
    --   2=M (Metric), 3=MR (Metric Rounded), 4=Other

    -- Dimension references
    MajorDiameterID     TEXT,
    PitchDiameterID     TEXT,
    MinorDiameterID     TEXT,
    PitchID             TEXT,
    EngagementLengthID  TEXT,
    CrestTruncationID   TEXT,
    RootRadiusID        TEXT,

    -- Feature references
    ChamferFeatureID    TEXT,
    ReliefFeatureID     TEXT,

    -- Coating
    CoatingThickness    REAL,

    FOREIGN KEY (MyModelID)            REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (OriginPointID)        REFERENCES Point(PointID),
    FOREIGN KEY (CurrentDimensionID)   REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CurrentFeatureID)     REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (CurrentSketchID)      REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CurrentStationID)     REFERENCES CAD_Station(StationID),
    FOREIGN KEY (CurrentLibraryID)     REFERENCES CAD_Library(LibraryID),
    FOREIGN KEY (MajorDiameterID)      REFERENCES CAD_Parameter(ParameterID),
    FOREIGN KEY (PitchDiameterID)      REFERENCES CAD_Parameter(ParameterID),
    FOREIGN KEY (MinorDiameterID)      REFERENCES CAD_Parameter(ParameterID),
    FOREIGN KEY (PitchID)              REFERENCES CAD_Parameter(ParameterID),
    FOREIGN KEY (EngagementLengthID)   REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CrestTruncationID)    REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (RootRadiusID)         REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (ChamferFeatureID)     REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (ReliefFeatureID)      REFERENCES CAD_Feature(FeatureID)
);

-- Thread inherits Feature collection junctions (reuse names from CAD_Feature_Schema)
-- MyDimensions, MyFeatures, Sketches, Stations, Libraries, ThreeDimOperations
CREATE TABLE IF NOT EXISTS Thread_Dimension (
    ThreadID        TEXT NOT NULL,
    DimensionID     TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ThreadID, DimensionID),
    FOREIGN KEY (ThreadID)    REFERENCES Thread(ThreadID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
);

CREATE TABLE IF NOT EXISTS Thread_SubFeature (
    ThreadID            TEXT NOT NULL,
    SubFeatureID        TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ThreadID, SubFeatureID),
    FOREIGN KEY (ThreadID)      REFERENCES Thread(ThreadID),
    FOREIGN KEY (SubFeatureID)  REFERENCES CAD_Feature(FeatureID)
);

-- ============================================================
-- CAD_Hole  (main table — flattens CAD_Feature base)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Hole (
    HoleID          TEXT PRIMARY KEY,          -- synthetic key

    -- Inherited from CAD_Feature
    Name            TEXT,
    Version         TEXT,
    GeometricFeatureType INTEGER NOT NULL DEFAULT 0,
    MyModelID       TEXT,
    OriginPointID   TEXT,

    -- Inherited cursors
    Base_CurrentDimensionID TEXT,
    Base_CurrentFeatureID   TEXT,
    Base_CurrentSketchID    TEXT,
    Base_CurrentStationID   TEXT,
    Base_CurrentLibraryID   TEXT,

    -- General dimensions
    NominalDiameterID       TEXT,
    NominalDepthID          TEXT,
    NominalTaperAngleID     TEXT,
    CenterPointID           TEXT,

    -- CounterSink dimensions
    CounterSinkAngleID      TEXT,
    CounterSinkDepthID      TEXT,

    -- CounterBore dimensions
    CounterBoreOuterDiameterID TEXT,
    CounterBoreDepthID      TEXT,

    -- Keyway
    HasKeyway               INTEGER NOT NULL DEFAULT 0,
    MyKeywayFeatureID       TEXT,

    -- Threads
    HasThreads              INTEGER NOT NULL DEFAULT 0,
    CurrentThreadID         TEXT,

    -- Feature / Sketch associations
    MyFeatureID             TEXT,
    MySketchID              TEXT,

    FOREIGN KEY (MyModelID)                REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (OriginPointID)            REFERENCES Point(PointID),
    FOREIGN KEY (Base_CurrentDimensionID)  REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (Base_CurrentFeatureID)    REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (Base_CurrentSketchID)     REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (Base_CurrentStationID)    REFERENCES CAD_Station(StationID),
    FOREIGN KEY (Base_CurrentLibraryID)    REFERENCES CAD_Library(LibraryID),
    FOREIGN KEY (NominalDiameterID)        REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (NominalDepthID)           REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (NominalTaperAngleID)      REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CenterPointID)            REFERENCES Point(PointID),
    FOREIGN KEY (CounterSinkAngleID)       REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CounterSinkDepthID)       REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CounterBoreOuterDiameterID) REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CounterBoreDepthID)       REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (MyKeywayFeatureID)        REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (CurrentThreadID)          REFERENCES Thread(ThreadID),
    FOREIGN KEY (MyFeatureID)              REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (MySketchID)               REFERENCES CAD_Sketch(SketchID)
);

-- ============================================================
-- CAD_Hole collection junction tables
-- ============================================================

-- MyThreads (List<Thread>)
CREATE TABLE IF NOT EXISTS CAD_Hole_Thread (
    HoleID      TEXT NOT NULL,
    ThreadID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (HoleID, ThreadID),
    FOREIGN KEY (HoleID)   REFERENCES CAD_Hole(HoleID),
    FOREIGN KEY (ThreadID) REFERENCES Thread(ThreadID)
);

-- Inherited from CAD_Feature: MyDimensions
CREATE TABLE IF NOT EXISTS CAD_Hole_Dimension (
    HoleID          TEXT NOT NULL,
    DimensionID     TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (HoleID, DimensionID),
    FOREIGN KEY (HoleID)      REFERENCES CAD_Hole(HoleID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
);

-- Inherited: MyFeatures (sub-features)
CREATE TABLE IF NOT EXISTS CAD_Hole_SubFeature (
    HoleID          TEXT NOT NULL,
    SubFeatureID    TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (HoleID, SubFeatureID),
    FOREIGN KEY (HoleID)        REFERENCES CAD_Hole(HoleID),
    FOREIGN KEY (SubFeatureID)  REFERENCES CAD_Feature(FeatureID)
);

-- Inherited: Sketches
CREATE TABLE IF NOT EXISTS CAD_Hole_Sketch (
    HoleID      TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (HoleID, SketchID),
    FOREIGN KEY (HoleID)    REFERENCES CAD_Hole(HoleID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

-- Inherited: Stations
CREATE TABLE IF NOT EXISTS CAD_Hole_Station (
    HoleID      TEXT NOT NULL,
    StationID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (HoleID, StationID),
    FOREIGN KEY (HoleID)     REFERENCES CAD_Hole(HoleID),
    FOREIGN KEY (StationID)  REFERENCES CAD_Station(StationID)
);

-- Inherited: Libraries
CREATE TABLE IF NOT EXISTS CAD_Hole_Library (
    HoleID      TEXT NOT NULL,
    LibraryID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (HoleID, LibraryID),
    FOREIGN KEY (HoleID)    REFERENCES CAD_Hole(HoleID),
    FOREIGN KEY (LibraryID) REFERENCES CAD_Library(LibraryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_hole_name        ON CAD_Hole(Name);
CREATE INDEX IF NOT EXISTS idx_hole_version     ON CAD_Hole(Version);
CREATE INDEX IF NOT EXISTS idx_hole_model       ON CAD_Hole(MyModelID);
CREATE INDEX IF NOT EXISTS idx_hole_keyway      ON CAD_Hole(HasKeyway);
CREATE INDEX IF NOT EXISTS idx_hole_threads     ON CAD_Hole(HasThreads);

CREATE INDEX IF NOT EXISTS idx_thread_name      ON Thread(Name);
CREATE INDEX IF NOT EXISTS idx_thread_standard  ON Thread(ThreadStandard);
CREATE INDEX IF NOT EXISTS idx_thread_internal  ON Thread(IsInternal);
CREATE INDEX IF NOT EXISTS idx_thread_metric    ON Thread(IsMetric);
CREATE INDEX IF NOT EXISTS idx_thread_model     ON Thread(MyModelID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: hole with all dimension values and thread info
CREATE VIEW IF NOT EXISTS v_CAD_Hole_Detail AS
SELECT
    h.HoleID,
    h.Name,
    h.Version,
    h.HasKeyway,
    h.HasThreads,

    -- Center point
    cp.X_Value  AS Center_X,
    cp.Y_Value  AS Center_Y,
    cp.Z_Value_Cartesian AS Center_Z,

    -- Model
    m.Name      AS ModelName,

    -- Current thread
    t.Designation       AS ThreadDesignation,
    t.ThreadStandard    AS ThreadStandard,
    CASE t.ThreadStandard
        WHEN 0 THEN 'UN'  WHEN 1 THEN 'UNR'
        WHEN 2 THEN 'M'   WHEN 3 THEN 'MR'
        WHEN 4 THEN 'Other'
    END AS ThreadStandardName,
    t.IsInternal        AS ThreadIsInternal,
    t.IsMetric          AS ThreadIsMetric,
    t.Starts            AS ThreadStarts,

    -- Thread count
    (SELECT COUNT(*) FROM CAD_Hole_Thread ht
     WHERE ht.HoleID = h.HoleID) AS ThreadCount,

    -- Dimension count (inherited)
    (SELECT COUNT(*) FROM CAD_Hole_Dimension hd
     WHERE hd.HoleID = h.HoleID) AS DimensionCount,

    -- Sub-feature count
    (SELECT COUNT(*) FROM CAD_Hole_SubFeature hsf
     WHERE hsf.HoleID = h.HoleID) AS SubFeatureCount

FROM CAD_Hole h
LEFT JOIN Point cp          ON h.CenterPointID   = cp.PointID
LEFT JOIN CAD_Model m       ON h.MyModelID        = m.ModelID
LEFT JOIN Thread t          ON h.CurrentThreadID   = t.ThreadID;

-- Flat view: thread detail
CREATE VIEW IF NOT EXISTS v_Thread_Detail AS
SELECT
    t.ThreadID,
    t.Name,
    t.Designation,
    t.ThreadClass,
    t.MaterialSpecification,
    t.SurfaceFinish,
    t.IsInternal,
    t.IsFine,
    t.IsMultithreaded,
    t.IsReverseThreaded,
    t.IsMetric,
    t.IsSquare,
    t.Starts,
    t.ThreadStandard,
    CASE t.ThreadStandard
        WHEN 0 THEN 'UN'  WHEN 1 THEN 'UNR'
        WHEN 2 THEN 'M'   WHEN 3 THEN 'MR'
        WHEN 4 THEN 'Other'
    END AS ThreadStandardName,
    t.CoatingThickness,

    -- Model
    m.Name AS ModelName

FROM Thread t
LEFT JOIN CAD_Model m ON t.MyModelID = m.ModelID;
