-- ============================================================
-- SQLite Schema for CAD_Surface JSON mapping
-- Generated from CAD_Library: CAD_Surface (extends Mathematics.Surface)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Segment, Mesh, CAD_Body
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

CREATE TABLE IF NOT EXISTS Segment (
    SegmentID       TEXT PRIMARY KEY,
    Name            TEXT,
    SegmentType     INTEGER NOT NULL DEFAULT 0,
    StartPointID    TEXT,
    EndPointID      TEXT,
    MidPointID      TEXT,
    ControlPointID  TEXT,
    Length          REAL NOT NULL DEFAULT 0.0,
    FOREIGN KEY (StartPointID)  REFERENCES Point(PointID),
    FOREIGN KEY (EndPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (MidPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (ControlPointID) REFERENCES Point(PointID)
);

-- Mesh (triangulated representation)
CREATE TABLE IF NOT EXISTS Mesh (
    MeshID          TEXT PRIMARY KEY,
    Name            TEXT,
    ID              TEXT,
    Version         TEXT,
    Volume          REAL,
    SurfaceArea     REAL,
    Area            REAL,
    PerimeterLength REAL,
    MySurfaceID     TEXT
    -- FK to Surface omitted to avoid circular reference
);

-- ============================================================
-- Shared CAD types (stubs)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Body (
    BodyID      TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    PartNumber  TEXT
);

-- ============================================================
-- CAD_Surface  (main table — flattens Mathematics.Surface base)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Surface (
    SurfaceID       TEXT PRIMARY KEY,          -- maps to ID property

    -- Identification
    Name            TEXT,
    Version         TEXT,
    Description     TEXT,

    -- Classification (own)
    SurfaceType     INTEGER NOT NULL DEFAULT 0,
    -- SurfaceTypeEnum:
    --   0=Plane, 1=Circle, 2=Ellipse, 3=Triangle, 4=Square,
    --   5=Rectangle, 6=Quadrilateral, 7=Polygon, 8=Cylinder,
    --   9=Cone, 10=Sphere, 11=Torus, 12=NURBS,
    --   13=TwoDMesh, 14=ThreeDMesh, 15=Other

    -- Inherited from Surface: primitive classification
    BasePrimitive   INTEGER NOT NULL DEFAULT 9,
    -- SurfacePrimitive:
    --   0=Circle, 1=Square, 2=Rectangle, 3=Triangle,
    --   4=Parallelogram, 5=Rhombus, 6=CylinderWall,
    --   7=Sphere, 8=PartialSphere, 9=Other

    -- Scalar data (own — nullable)
    Length          REAL,
    Area            REAL,
    Perimeter       REAL,

    -- Inherited from Surface: scalar data
    Base_Area           REAL NOT NULL DEFAULT 0.0,
    Base_PerimeterLength REAL NOT NULL DEFAULT 0.0,
    Base_Is2D           INTEGER NOT NULL DEFAULT 0,

    -- Ownership / relationships
    SourceSurfaceID TEXT,              -- reference to underlying analytic surface
    MyBodyID        TEXT,

    -- Mesh cursor (own, shadows base)
    CurrentMeshID   TEXT,

    FOREIGN KEY (MyBodyID)         REFERENCES CAD_Body(BodyID),
    FOREIGN KEY (CurrentMeshID)    REFERENCES Mesh(MeshID)
);

-- ============================================================
-- CAD_Surface collection junction tables
-- ============================================================

-- Meshes (own IReadOnlyList<Mesh>)
CREATE TABLE IF NOT EXISTS CAD_Surface_Mesh (
    SurfaceID   TEXT NOT NULL,
    MeshID      TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SurfaceID, MeshID),
    FOREIGN KEY (SurfaceID) REFERENCES CAD_Surface(SurfaceID),
    FOREIGN KEY (MeshID)    REFERENCES Mesh(MeshID)
);

-- Points (inherited List<Point>)
CREATE TABLE IF NOT EXISTS CAD_Surface_Point (
    SurfaceID   TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SurfaceID, PointID),
    FOREIGN KEY (SurfaceID) REFERENCES CAD_Surface(SurfaceID),
    FOREIGN KEY (PointID)   REFERENCES Point(PointID)
);

-- Segments (inherited List<Segment>)
CREATE TABLE IF NOT EXISTS CAD_Surface_Segment (
    SurfaceID   TEXT NOT NULL,
    SegmentID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SurfaceID, SegmentID),
    FOREIGN KEY (SurfaceID)  REFERENCES CAD_Surface(SurfaceID),
    FOREIGN KEY (SegmentID)  REFERENCES Segment(SegmentID)
);

-- Perimeter (inherited List<Segment> — perimeter edge loop)
CREATE TABLE IF NOT EXISTS CAD_Surface_Perimeter (
    SurfaceID   TEXT NOT NULL,
    SegmentID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SurfaceID, SegmentID),
    FOREIGN KEY (SurfaceID)  REFERENCES CAD_Surface(SurfaceID),
    FOREIGN KEY (SegmentID)  REFERENCES Segment(SegmentID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_surface_name         ON CAD_Surface(Name);
CREATE INDEX IF NOT EXISTS idx_surface_version      ON CAD_Surface(Version);
CREATE INDEX IF NOT EXISTS idx_surface_type         ON CAD_Surface(SurfaceType);
CREATE INDEX IF NOT EXISTS idx_surface_primitive    ON CAD_Surface(BasePrimitive);
CREATE INDEX IF NOT EXISTS idx_surface_body         ON CAD_Surface(MyBodyID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: surface with type labels, scalar data, and counts
CREATE VIEW IF NOT EXISTS v_CAD_Surface_Detail AS
SELECT
    s.SurfaceID,
    s.Name,
    s.Version,
    s.Description,
    s.SurfaceType,
    CASE s.SurfaceType
        WHEN 0  THEN 'Plane'         WHEN 1  THEN 'Circle'
        WHEN 2  THEN 'Ellipse'       WHEN 3  THEN 'Triangle'
        WHEN 4  THEN 'Square'        WHEN 5  THEN 'Rectangle'
        WHEN 6  THEN 'Quadrilateral' WHEN 7  THEN 'Polygon'
        WHEN 8  THEN 'Cylinder'      WHEN 9  THEN 'Cone'
        WHEN 10 THEN 'Sphere'        WHEN 11 THEN 'Torus'
        WHEN 12 THEN 'NURBS'         WHEN 13 THEN 'TwoDMesh'
        WHEN 14 THEN 'ThreeDMesh'    WHEN 15 THEN 'Other'
    END AS SurfaceTypeName,
    s.BasePrimitive,
    CASE s.BasePrimitive
        WHEN 0 THEN 'Circle'       WHEN 1 THEN 'Square'
        WHEN 2 THEN 'Rectangle'    WHEN 3 THEN 'Triangle'
        WHEN 4 THEN 'Parallelogram' WHEN 5 THEN 'Rhombus'
        WHEN 6 THEN 'CylinderWall' WHEN 7 THEN 'Sphere'
        WHEN 8 THEN 'PartialSphere' WHEN 9 THEN 'Other'
    END AS BasePrimitiveName,

    -- Scalar data
    s.Length,
    s.Area,
    s.Perimeter,
    s.Base_Is2D,

    -- Body
    b.Name  AS BodyName,

    -- Collection counts
    (SELECT COUNT(*) FROM CAD_Surface_Mesh sm
     WHERE sm.SurfaceID = s.SurfaceID) AS MeshCount,
    (SELECT COUNT(*) FROM CAD_Surface_Point sp
     WHERE sp.SurfaceID = s.SurfaceID) AS PointCount,
    (SELECT COUNT(*) FROM CAD_Surface_Segment ss
     WHERE ss.SurfaceID = s.SurfaceID) AS SegmentCount,
    (SELECT COUNT(*) FROM CAD_Surface_Perimeter spe
     WHERE spe.SurfaceID = s.SurfaceID) AS PerimeterSegmentCount

FROM CAD_Surface s
LEFT JOIN CAD_Body b ON s.MyBodyID = b.BodyID;

-- View: surfaces grouped by type
CREATE VIEW IF NOT EXISTS v_CAD_Surface_ByType AS
SELECT
    s.SurfaceType,
    CASE s.SurfaceType
        WHEN 0  THEN 'Plane'         WHEN 1  THEN 'Circle'
        WHEN 2  THEN 'Ellipse'       WHEN 3  THEN 'Triangle'
        WHEN 4  THEN 'Square'        WHEN 5  THEN 'Rectangle'
        WHEN 6  THEN 'Quadrilateral' WHEN 7  THEN 'Polygon'
        WHEN 8  THEN 'Cylinder'      WHEN 9  THEN 'Cone'
        WHEN 10 THEN 'Sphere'        WHEN 11 THEN 'Torus'
        WHEN 12 THEN 'NURBS'         WHEN 13 THEN 'TwoDMesh'
        WHEN 14 THEN 'ThreeDMesh'    WHEN 15 THEN 'Other'
    END AS SurfaceTypeName,
    COUNT(*) AS SurfaceCount
FROM CAD_Surface s
GROUP BY s.SurfaceType
ORDER BY s.SurfaceType;
