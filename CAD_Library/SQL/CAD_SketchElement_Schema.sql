-- ============================================================
-- SQLite Schema for CAD_SketchElement JSON mapping
-- Generated from CAD_Library: CAD_SketchElement (sealed class)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Primitive
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

-- Primitive (2D/3D geometric primitive)
CREATE TABLE IF NOT EXISTS Primitive (
    PrimitiveID     TEXT PRIMARY KEY,
    TwoDType        INTEGER NOT NULL DEFAULT 0,
    -- TwoDPrimitive: 0=Point, 1=Line, 2=Circle, 3=Arc, 4=Ellipse,
    --   5=Polygon, 6=Rectangle, 7=Triangle, 8=Spline, 9=Parabola,
    --   10=Hyperbola, 11=Other
    ThreeDType      INTEGER NOT NULL DEFAULT 0,
    -- ThreeDPrimitive: 0=Sphere, 1=Cylinder, 2=Cone, 3=Torus,
    --   4=Box, 5=Pyramid, 6=Prism, 7=Other
    CurrentPointID  TEXT,
    CurrentSegmentID TEXT,
    FOREIGN KEY (CurrentPointID)   REFERENCES Point(PointID),
    FOREIGN KEY (CurrentSegmentID) REFERENCES Segment(SegmentID)
);

-- ============================================================
-- CAD_SketchElement  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_SketchElement (
    SketchElementID TEXT PRIMARY KEY,          -- synthetic key

    -- Identification
    Name            TEXT,
    Version         TEXT,
    Path            TEXT,

    -- Classification
    ElementType     INTEGER NOT NULL DEFAULT 0,
    -- SketchElemTypeEnum:
    --   0=StartPoint, 1=EndPoint, 2=MidPoint, 3=ControlPoint,
    --   4=Line, 5=Rectangle, 6=Circle, 7=Parabola,
    --   8=Ellipse, 9=Contour, 10=Arc, 11=Spline,
    --   12=Slot, 13=BreakLine, 14=Centerline, 15=Centerpoint,
    --   16=WorkPoint, 17=WorkLine

    -- Flags
    IsWorkElement   INTEGER NOT NULL DEFAULT 0,    -- bool

    -- Geometry (named point references)
    CurrentPointID      TEXT,
    StartPointID        TEXT,
    EndPointID          TEXT,
    MidPointID          TEXT,
    ControlPointID      TEXT,

    -- Primitive reference
    CurrentPrimitiveID  TEXT,

    FOREIGN KEY (CurrentPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (StartPointID)      REFERENCES Point(PointID),
    FOREIGN KEY (EndPointID)        REFERENCES Point(PointID),
    FOREIGN KEY (MidPointID)        REFERENCES Point(PointID),
    FOREIGN KEY (ControlPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (CurrentPrimitiveID) REFERENCES Primitive(PrimitiveID)
);

-- ============================================================
-- CAD_SketchElement collection junction tables
-- ============================================================

-- Points (IReadOnlyList<Point>)
CREATE TABLE IF NOT EXISTS CAD_SketchElement_Point (
    SketchElementID TEXT NOT NULL,
    PointID         TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchElementID, PointID),
    FOREIGN KEY (SketchElementID) REFERENCES CAD_SketchElement(SketchElementID),
    FOREIGN KEY (PointID)         REFERENCES Point(PointID)
);

-- Primitives (IReadOnlyList<Primitive>)
CREATE TABLE IF NOT EXISTS CAD_SketchElement_Primitive (
    SketchElementID TEXT NOT NULL,
    PrimitiveID     TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchElementID, PrimitiveID),
    FOREIGN KEY (SketchElementID) REFERENCES CAD_SketchElement(SketchElementID),
    FOREIGN KEY (PrimitiveID)     REFERENCES Primitive(PrimitiveID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_sketchelem_name      ON CAD_SketchElement(Name);
CREATE INDEX IF NOT EXISTS idx_sketchelem_version   ON CAD_SketchElement(Version);
CREATE INDEX IF NOT EXISTS idx_sketchelem_type      ON CAD_SketchElement(ElementType);
CREATE INDEX IF NOT EXISTS idx_sketchelem_work      ON CAD_SketchElement(IsWorkElement);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: sketch element with type label and point coordinates
CREATE VIEW IF NOT EXISTS v_CAD_SketchElement_Detail AS
SELECT
    se.SketchElementID,
    se.Name,
    se.Version,
    se.Path,
    se.ElementType,
    CASE se.ElementType
        WHEN 0  THEN 'StartPoint'   WHEN 1  THEN 'EndPoint'
        WHEN 2  THEN 'MidPoint'     WHEN 3  THEN 'ControlPoint'
        WHEN 4  THEN 'Line'         WHEN 5  THEN 'Rectangle'
        WHEN 6  THEN 'Circle'       WHEN 7  THEN 'Parabola'
        WHEN 8  THEN 'Ellipse'      WHEN 9  THEN 'Contour'
        WHEN 10 THEN 'Arc'          WHEN 11 THEN 'Spline'
        WHEN 12 THEN 'Slot'         WHEN 13 THEN 'BreakLine'
        WHEN 14 THEN 'Centerline'   WHEN 15 THEN 'Centerpoint'
        WHEN 16 THEN 'WorkPoint'    WHEN 17 THEN 'WorkLine'
    END AS ElementTypeName,
    se.IsWorkElement,

    -- Start point
    sp.X_Value AS Start_X, sp.Y_Value AS Start_Y, sp.Z_Value_Cartesian AS Start_Z,

    -- End point
    ep.X_Value AS End_X, ep.Y_Value AS End_Y, ep.Z_Value_Cartesian AS End_Z,

    -- Mid point
    mp.X_Value AS Mid_X, mp.Y_Value AS Mid_Y, mp.Z_Value_Cartesian AS Mid_Z,

    -- Collection counts
    (SELECT COUNT(*) FROM CAD_SketchElement_Point sep
     WHERE sep.SketchElementID = se.SketchElementID) AS PointCount,
    (SELECT COUNT(*) FROM CAD_SketchElement_Primitive spr
     WHERE spr.SketchElementID = se.SketchElementID) AS PrimitiveCount

FROM CAD_SketchElement se
LEFT JOIN Point sp ON se.StartPointID = sp.PointID
LEFT JOIN Point ep ON se.EndPointID   = ep.PointID
LEFT JOIN Point mp ON se.MidPointID   = mp.PointID;

-- View: sketch elements grouped by type
CREATE VIEW IF NOT EXISTS v_CAD_SketchElement_ByType AS
SELECT
    se.ElementType,
    CASE se.ElementType
        WHEN 0  THEN 'StartPoint'   WHEN 1  THEN 'EndPoint'
        WHEN 2  THEN 'MidPoint'     WHEN 3  THEN 'ControlPoint'
        WHEN 4  THEN 'Line'         WHEN 5  THEN 'Rectangle'
        WHEN 6  THEN 'Circle'       WHEN 7  THEN 'Parabola'
        WHEN 8  THEN 'Ellipse'      WHEN 9  THEN 'Contour'
        WHEN 10 THEN 'Arc'          WHEN 11 THEN 'Spline'
        WHEN 12 THEN 'Slot'         WHEN 13 THEN 'BreakLine'
        WHEN 14 THEN 'Centerline'   WHEN 15 THEN 'Centerpoint'
        WHEN 16 THEN 'WorkPoint'    WHEN 17 THEN 'WorkLine'
    END AS ElementTypeName,
    COUNT(*) AS ElementCount,
    SUM(CASE WHEN se.IsWorkElement = 1 THEN 1 ELSE 0 END) AS WorkElementCount
FROM CAD_SketchElement se
GROUP BY se.ElementType
ORDER BY se.ElementType;
