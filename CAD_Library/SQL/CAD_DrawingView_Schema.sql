-- ============================================================
-- SQLite Schema for CAD_DrawingView JSON mapping
-- Generated from CAD_Library: CAD_DrawingView (extends CAD_DrawingElement)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, CAD_Drawing,
--   CAD_ConstructionGeometry, Quadrilateral
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

-- Quadrilateral (4 vertices, 4 edges, midpoint)
CREATE TABLE IF NOT EXISTS Quadrilateral (
    QuadrilateralID TEXT PRIMARY KEY,
    Vertex1ID       TEXT,
    Vertex2ID       TEXT,
    Vertex3ID       TEXT,
    Vertex4ID       TEXT,
    Edge1ID         TEXT,
    Edge2ID         TEXT,
    Edge3ID         TEXT,
    Edge4ID         TEXT,
    MidPointID      TEXT,
    FOREIGN KEY (Vertex1ID)  REFERENCES Point(PointID),
    FOREIGN KEY (Vertex2ID)  REFERENCES Point(PointID),
    FOREIGN KEY (Vertex3ID)  REFERENCES Point(PointID),
    FOREIGN KEY (Vertex4ID)  REFERENCES Point(PointID),
    FOREIGN KEY (Edge1ID)    REFERENCES Segment(SegmentID),
    FOREIGN KEY (Edge2ID)    REFERENCES Segment(SegmentID),
    FOREIGN KEY (Edge3ID)    REFERENCES Segment(SegmentID),
    FOREIGN KEY (Edge4ID)    REFERENCES Segment(SegmentID),
    FOREIGN KEY (MidPointID) REFERENCES Point(PointID)
);

-- ============================================================
-- Shared CAD types (stubs)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Drawing (
    DrawingID       TEXT PRIMARY KEY,
    Title           TEXT,
    DrawingNumber   TEXT,
    Revision        TEXT
);

CREATE TABLE IF NOT EXISTS CAD_ConstructionGeometry (
    ConstructionGeometryID  TEXT PRIMARY KEY,
    Name            TEXT,
    Version         TEXT NOT NULL DEFAULT '1.0',
    GeometryType    INTEGER NOT NULL DEFAULT 0,
    MyCAD_ModelID   TEXT
);

-- ============================================================
-- CAD_DrawingView  (main table — flattens CAD_DrawingElement base)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingView (
    DrawingViewID   TEXT PRIMARY KEY,          -- maps to ID property

    -- Inherited from CAD_DrawingElement
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 0,    -- DrawingElementType (set to 0=DrawingView)
    MyDrawingID     TEXT,
    CurrentConstructionGeometryID TEXT,

    -- Own properties
    Title           TEXT,
    Description     TEXT,

    -- View classification
    ViewType        INTEGER NOT NULL DEFAULT 9,
    -- ViewType:
    --   0=OrthoTop, 1=OrthoFront, 2=OrthoRightSide,
    --   3=OrthoBottom, 4=OrthoBack, 5=OrthoLeftSide,
    --   6=Isometric, 7=CrossSection, 8=Detail, 9=Other

    -- Geometry
    CenterPointID       TEXT,                  -- center point on sheet
    ViewRectangleID     TEXT,                  -- bounding rectangle on sheet

    FOREIGN KEY (MyDrawingID)                  REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID),
    FOREIGN KEY (CenterPointID)                REFERENCES Point(PointID),
    FOREIGN KEY (ViewRectangleID)              REFERENCES Quadrilateral(QuadrilateralID)
);

-- ============================================================
-- CAD_DrawingView collection junction tables
-- ============================================================

-- MyConstructionGeometry (inherited List<CAD_ConstructionGeometery>)
CREATE TABLE IF NOT EXISTS CAD_DrawingView_ConstructionGeometry (
    DrawingViewID           TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingViewID, ConstructionGeometryID),
    FOREIGN KEY (DrawingViewID)          REFERENCES CAD_DrawingView(DrawingViewID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_drawview_name      ON CAD_DrawingView(Name);
CREATE INDEX IF NOT EXISTS idx_drawview_title     ON CAD_DrawingView(Title);
CREATE INDEX IF NOT EXISTS idx_drawview_type      ON CAD_DrawingView(ViewType);
CREATE INDEX IF NOT EXISTS idx_drawview_drawing   ON CAD_DrawingView(MyDrawingID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: drawing view with center point and rectangle info
CREATE VIEW IF NOT EXISTS v_CAD_DrawingView_Detail AS
SELECT
    dv.DrawingViewID,
    dv.Name,
    dv.Title,
    dv.Description,
    dv.ViewType,
    CASE dv.ViewType
        WHEN 0 THEN 'OrthoTop'
        WHEN 1 THEN 'OrthoFront'
        WHEN 2 THEN 'OrthoRightSide'
        WHEN 3 THEN 'OrthoBottom'
        WHEN 4 THEN 'OrthoBack'
        WHEN 5 THEN 'OrthoLeftSide'
        WHEN 6 THEN 'Isometric'
        WHEN 7 THEN 'CrossSection'
        WHEN 8 THEN 'Detail'
        WHEN 9 THEN 'Other'
    END AS ViewTypeName,

    -- Center point
    cp.X_Value  AS Center_X,
    cp.Y_Value  AS Center_Y,
    cp.Z_Value_Cartesian AS Center_Z,

    -- Drawing
    d.Title         AS DrawingTitle,
    d.DrawingNumber AS DrawingNumber,

    -- Construction geometry count
    (SELECT COUNT(*) FROM CAD_DrawingView_ConstructionGeometry dvcg
     WHERE dvcg.DrawingViewID = dv.DrawingViewID) AS ConstructionGeometryCount

FROM CAD_DrawingView dv
LEFT JOIN Point cp          ON dv.CenterPointID = cp.PointID
LEFT JOIN CAD_Drawing d     ON dv.MyDrawingID   = d.DrawingID;

-- View: drawing views grouped by type
CREATE VIEW IF NOT EXISTS v_CAD_DrawingView_ByType AS
SELECT
    dv.ViewType,
    CASE dv.ViewType
        WHEN 0 THEN 'OrthoTop'
        WHEN 1 THEN 'OrthoFront'
        WHEN 2 THEN 'OrthoRightSide'
        WHEN 3 THEN 'OrthoBottom'
        WHEN 4 THEN 'OrthoBack'
        WHEN 5 THEN 'OrthoLeftSide'
        WHEN 6 THEN 'Isometric'
        WHEN 7 THEN 'CrossSection'
        WHEN 8 THEN 'Detail'
        WHEN 9 THEN 'Other'
    END AS ViewTypeName,
    COUNT(*) AS ViewCount
FROM CAD_DrawingView dv
GROUP BY dv.ViewType
ORDER BY dv.ViewType;
