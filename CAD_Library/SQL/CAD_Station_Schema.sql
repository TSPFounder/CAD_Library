-- ============================================================
-- SQLite Schema for CAD_Station JSON mapping
-- Generated from CAD_Library: CAD_Station (sealed class)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, CAD_Model, CAD_SketchPlane
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

CREATE TABLE IF NOT EXISTS CAD_SketchPlane (
    SketchPlaneID   TEXT PRIMARY KEY,
    Name            TEXT,
    Version         TEXT,
    Path            TEXT,
    IsWorkplane     INTEGER NOT NULL DEFAULT 1,
    GeometryType    INTEGER NOT NULL DEFAULT 0,
    FunctionalType  INTEGER NOT NULL DEFAULT 3,
    MyModelID               TEXT,
    MyCoordinateSystemID    TEXT,
    NormalVectorID          TEXT,
    CurrentSketchID         TEXT,
    FOREIGN KEY (MyModelID)             REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (MyCoordinateSystemID)  REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (NormalVectorID)        REFERENCES Vector(VectorID)
);

-- ============================================================
-- CAD_Station  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Station (
    StationID       TEXT PRIMARY KEY,          -- maps to ID property

    -- Identification
    Name            TEXT,
    Version         TEXT,

    -- Station classification & type
    MyType          INTEGER NOT NULL DEFAULT 0,
    -- StationTypeEnum: 0=Axial, 1=Radial, 2=Angular, 3=Wing, 4=Other

    -- Location values
    AxialLocation   REAL NOT NULL DEFAULT 0.0,
    RadialLocation  REAL NOT NULL DEFAULT 0.0,
    AngularLocation REAL NOT NULL DEFAULT 0.0,
    WingLocation    REAL NOT NULL DEFAULT 0.0,
    FloorLocation   REAL NOT NULL DEFAULT 0.0,

    -- Ownership
    MyModelID               TEXT,

    -- Current sketch plane cursor
    CurrentSketchPlaneID    TEXT,

    FOREIGN KEY (MyModelID)            REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (CurrentSketchPlaneID) REFERENCES CAD_SketchPlane(SketchPlaneID)
);

-- ============================================================
-- CAD_Station collection junction tables
-- ============================================================

-- MySketchPlanes (IReadOnlyList<CAD_SketchPlane>)
CREATE TABLE IF NOT EXISTS CAD_Station_SketchPlane (
    StationID       TEXT NOT NULL,
    SketchPlaneID   TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (StationID, SketchPlaneID),
    FOREIGN KEY (StationID)     REFERENCES CAD_Station(StationID),
    FOREIGN KEY (SketchPlaneID) REFERENCES CAD_SketchPlane(SketchPlaneID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_station_name         ON CAD_Station(Name);
CREATE INDEX IF NOT EXISTS idx_station_version      ON CAD_Station(Version);
CREATE INDEX IF NOT EXISTS idx_station_type         ON CAD_Station(MyType);
CREATE INDEX IF NOT EXISTS idx_station_model        ON CAD_Station(MyModelID);
CREATE INDEX IF NOT EXISTS idx_station_axial        ON CAD_Station(AxialLocation);
CREATE INDEX IF NOT EXISTS idx_station_radial       ON CAD_Station(RadialLocation);
CREATE INDEX IF NOT EXISTS idx_station_angular      ON CAD_Station(AngularLocation);
CREATE INDEX IF NOT EXISTS idx_station_wing         ON CAD_Station(WingLocation);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: CAD_Station with model info and sketch plane count
CREATE VIEW IF NOT EXISTS v_CAD_Station_Detail AS
SELECT
    s.StationID,
    s.Name,
    s.Version,
    s.MyType,
    CASE s.MyType
        WHEN 0 THEN 'Axial'
        WHEN 1 THEN 'Radial'
        WHEN 2 THEN 'Angular'
        WHEN 3 THEN 'Wing'
        WHEN 4 THEN 'Other'
    END AS StationTypeName,
    s.AxialLocation,
    s.RadialLocation,
    s.AngularLocation,
    s.WingLocation,
    s.FloorLocation,

    -- Primary location value based on type
    CASE s.MyType
        WHEN 0 THEN s.AxialLocation
        WHEN 1 THEN s.RadialLocation
        WHEN 2 THEN s.AngularLocation
        WHEN 3 THEN s.WingLocation
        ELSE NULL
    END AS PrimaryLocation,

    -- Model
    m.Name              AS ModelName,
    m.CAD_AppName       AS ModelApp,

    -- Current sketch plane
    sp.Name             AS CurrentSketchPlaneName,
    sp.FunctionalType   AS CurrentSketchPlaneFuncType,

    -- Sketch plane count
    (SELECT COUNT(*) FROM CAD_Station_SketchPlane ssp WHERE ssp.StationID = s.StationID) AS SketchPlaneCount

FROM CAD_Station s
LEFT JOIN CAD_Model m           ON s.MyModelID            = m.ModelID
LEFT JOIN CAD_SketchPlane sp    ON s.CurrentSketchPlaneID = sp.SketchPlaneID;

-- View: Stations grouped by type
CREATE VIEW IF NOT EXISTS v_CAD_Station_ByType AS
SELECT
    s.MyType,
    CASE s.MyType
        WHEN 0 THEN 'Axial'
        WHEN 1 THEN 'Radial'
        WHEN 2 THEN 'Angular'
        WHEN 3 THEN 'Wing'
        WHEN 4 THEN 'Other'
    END AS StationTypeName,
    COUNT(*)            AS StationCount,
    MIN(CASE s.MyType
        WHEN 0 THEN s.AxialLocation
        WHEN 1 THEN s.RadialLocation
        WHEN 2 THEN s.AngularLocation
        WHEN 3 THEN s.WingLocation
    END) AS MinLocation,
    MAX(CASE s.MyType
        WHEN 0 THEN s.AxialLocation
        WHEN 1 THEN s.RadialLocation
        WHEN 2 THEN s.AngularLocation
        WHEN 3 THEN s.WingLocation
    END) AS MaxLocation,
    SUM((SELECT COUNT(*) FROM CAD_Station_SketchPlane ssp WHERE ssp.StationID = s.StationID)) AS TotalSketchPlanes
FROM CAD_Station s
GROUP BY s.MyType
ORDER BY s.MyType;

-- View: Station -> SketchPlanes with plane details
CREATE VIEW IF NOT EXISTS v_CAD_Station_SketchPlanes AS
SELECT
    s.StationID,
    s.Name              AS StationName,
    s.MyType            AS StationType,
    ssp.SortOrder,
    sp.SketchPlaneID,
    sp.Name             AS PlaneName,
    sp.IsWorkplane,
    sp.GeometryType,
    sp.FunctionalType
FROM CAD_Station s
JOIN CAD_Station_SketchPlane ssp ON s.StationID     = ssp.StationID
JOIN CAD_SketchPlane sp          ON ssp.SketchPlaneID = sp.SketchPlaneID
ORDER BY s.StationID, ssp.SortOrder;
