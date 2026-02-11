-- ============================================================
-- SQLite Schema for CAD_SketchPlane JSON mapping
-- Generated from CAD_Library: CAD_SketchPlane (sealed class)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, CAD_Model, CAD_Sketch
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

-- ============================================================
-- CAD_SketchPlane  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_SketchPlane (
    SketchPlaneID   TEXT PRIMARY KEY,          -- synthetic key

    -- Identification
    Name            TEXT,
    Version         TEXT,
    Path            TEXT,

    -- Flags / classification
    IsWorkplane     INTEGER NOT NULL DEFAULT 1,    -- bool (default true)
    GeometryType    INTEGER NOT NULL DEFAULT 0,
    -- GeometryTypeEnum: 0=Cartesian, 1=Spherical, 2=Cylindrical
    FunctionalType  INTEGER NOT NULL DEFAULT 3,
    -- FunctionalTypeEnum: 0=Interface, 1=Section, 2=GeometricBoundary,
    -- 3=Feature, 4=CoordinateSystemOrigin, 5=Incremental

    -- Ownership
    MyModelID               TEXT,

    -- Coordinate system (origin + axes defining the plane)
    MyCoordinateSystemID    TEXT,

    -- Normal vector (unit normal describing plane orientation)
    NormalVectorID          TEXT,

    -- Current sketch cursor
    CurrentSketchID         TEXT,

    FOREIGN KEY (MyModelID)             REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (MyCoordinateSystemID)  REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (NormalVectorID)        REFERENCES Vector(VectorID),
    FOREIGN KEY (CurrentSketchID)       REFERENCES CAD_Sketch(SketchID)
);

-- ============================================================
-- CAD_SketchPlane collection junction tables
-- ============================================================

-- Sketches (IReadOnlyList<CAD_Sketch>)
CREATE TABLE IF NOT EXISTS CAD_SketchPlane_Sketch (
    SketchPlaneID   TEXT NOT NULL,
    SketchID        TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchPlaneID, SketchID),
    FOREIGN KEY (SketchPlaneID) REFERENCES CAD_SketchPlane(SketchPlaneID),
    FOREIGN KEY (SketchID)      REFERENCES CAD_Sketch(SketchID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_sketchplane_name         ON CAD_SketchPlane(Name);
CREATE INDEX IF NOT EXISTS idx_sketchplane_version      ON CAD_SketchPlane(Version);
CREATE INDEX IF NOT EXISTS idx_sketchplane_geom_type    ON CAD_SketchPlane(GeometryType);
CREATE INDEX IF NOT EXISTS idx_sketchplane_func_type    ON CAD_SketchPlane(FunctionalType);
CREATE INDEX IF NOT EXISTS idx_sketchplane_workplane    ON CAD_SketchPlane(IsWorkplane);
CREATE INDEX IF NOT EXISTS idx_sketchplane_model        ON CAD_SketchPlane(MyModelID);
CREATE INDEX IF NOT EXISTS idx_sketchplane_csys         ON CAD_SketchPlane(MyCoordinateSystemID);
CREATE INDEX IF NOT EXISTS idx_sketchplane_normal       ON CAD_SketchPlane(NormalVectorID);
CREATE INDEX IF NOT EXISTS idx_sketchplane_cur_sketch   ON CAD_SketchPlane(CurrentSketchID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: CAD_SketchPlane with coordinate system origin,
-- normal vector components, model info, and sketch count
CREATE VIEW IF NOT EXISTS v_CAD_SketchPlane_Detail AS
SELECT
    sp.SketchPlaneID,
    sp.Name,
    sp.Version,
    sp.Path,
    sp.IsWorkplane,
    sp.GeometryType,
    CASE sp.GeometryType
        WHEN 0 THEN 'Cartesian'
        WHEN 1 THEN 'Spherical'
        WHEN 2 THEN 'Cylindrical'
    END AS GeometryTypeName,
    sp.FunctionalType,
    CASE sp.FunctionalType
        WHEN 0 THEN 'Interface'
        WHEN 1 THEN 'Section'
        WHEN 2 THEN 'GeometricBoundary'
        WHEN 3 THEN 'Feature'
        WHEN 4 THEN 'CoordinateSystemOrigin'
        WHEN 5 THEN 'Incremental'
    END AS FunctionalTypeName,

    -- Model
    m.Name                  AS ModelName,
    m.CAD_AppName           AS ModelApp,
    CASE m.CAD_AppName
        WHEN 0 THEN 'Fusion360'    WHEN 1 THEN 'Solidworks'
        WHEN 2 THEN 'Blender'      WHEN 3 THEN 'UnReal4'
        WHEN 4 THEN 'UnReal5'      WHEN 5 THEN 'Unity'
        WHEN 6 THEN 'Other'
    END AS ModelAppText,

    -- Coordinate system
    cs.Name                 AS CSysName,
    cs.MyType               AS CSysType,
    CASE cs.MyType
        WHEN 0 THEN 'Cartesian'
        WHEN 1 THEN 'Cylindrical'
        WHEN 2 THEN 'Spherical'
        WHEN 3 THEN 'Polar'
    END AS CSysTypeName,
    cs.IsWCS                AS CSysIsWCS,

    -- Origin point coordinates
    op.X_Value              AS Origin_X,
    op.Y_Value              AS Origin_Y,
    op.Z_Value_Cartesian    AS Origin_Z,

    -- Normal vector components
    nv.X_Value              AS Normal_X,
    nv.Y_Value              AS Normal_Y,
    nv.Z_Value              AS Normal_Z,

    -- Current sketch
    csk.SketchID            AS CurrentSketchID,
    csk.Version             AS CurrentSketchVersion,
    csk.IsTwoD              AS CurrentSketchIs2D,

    -- Sketch count
    (SELECT COUNT(*) FROM CAD_SketchPlane_Sketch sps WHERE sps.SketchPlaneID = sp.SketchPlaneID) AS SketchCount

FROM CAD_SketchPlane sp
LEFT JOIN CAD_Model m           ON sp.MyModelID             = m.ModelID
LEFT JOIN CoordinateSystem cs   ON sp.MyCoordinateSystemID  = cs.CoordinateSystemID
LEFT JOIN Point op              ON cs.OriginLocationPointID = op.PointID
LEFT JOIN Vector nv             ON sp.NormalVectorID        = nv.VectorID
LEFT JOIN CAD_Sketch csk        ON sp.CurrentSketchID       = csk.SketchID;

-- View: SketchPlane -> Sketches with sketch details
CREATE VIEW IF NOT EXISTS v_CAD_SketchPlane_Sketches AS
SELECT
    sp.SketchPlaneID,
    sp.Name             AS PlaneName,
    sp.FunctionalType,
    CASE sp.FunctionalType
        WHEN 0 THEN 'Interface'
        WHEN 1 THEN 'Section'
        WHEN 2 THEN 'GeometricBoundary'
        WHEN 3 THEN 'Feature'
        WHEN 4 THEN 'CoordinateSystemOrigin'
        WHEN 5 THEN 'Incremental'
    END AS FunctionalTypeName,
    sps.SortOrder,
    s.SketchID,
    s.Version           AS SketchVersion,
    s.IsTwoD,
    -- Sketch child counts for quick overview
    (SELECT COUNT(*) FROM CAD_Sketch_Point      skp WHERE skp.SketchID = s.SketchID)  AS PointCount,
    (SELECT COUNT(*) FROM CAD_Sketch_Segment    sks WHERE sks.SketchID = s.SketchID)  AS SegmentCount,
    (SELECT COUNT(*) FROM CAD_Sketch_Constraint skc WHERE skc.SketchID = s.SketchID)  AS ConstraintCount,
    (SELECT COUNT(*) FROM CAD_Sketch_Dimension  skd WHERE skd.SketchID = s.SketchID)  AS DimensionCount
FROM CAD_SketchPlane sp
JOIN CAD_SketchPlane_Sketch sps ON sp.SketchPlaneID = sps.SketchPlaneID
JOIN CAD_Sketch s               ON sps.SketchID     = s.SketchID
ORDER BY sp.SketchPlaneID, sps.SortOrder;

-- View: All sketch planes grouped by functional type
CREATE VIEW IF NOT EXISTS v_CAD_SketchPlane_ByFunctionalType AS
SELECT
    sp.FunctionalType,
    CASE sp.FunctionalType
        WHEN 0 THEN 'Interface'
        WHEN 1 THEN 'Section'
        WHEN 2 THEN 'GeometricBoundary'
        WHEN 3 THEN 'Feature'
        WHEN 4 THEN 'CoordinateSystemOrigin'
        WHEN 5 THEN 'Incremental'
    END AS FunctionalTypeName,
    COUNT(*)            AS PlaneCount,
    SUM(CASE WHEN sp.IsWorkplane = 1 THEN 1 ELSE 0 END) AS WorkplaneCount,
    SUM((SELECT COUNT(*) FROM CAD_SketchPlane_Sketch sps WHERE sps.SketchPlaneID = sp.SketchPlaneID)) AS TotalSketchCount
FROM CAD_SketchPlane sp
GROUP BY sp.FunctionalType
ORDER BY sp.FunctionalType;
