-- ============================================================
-- SQLite Schema for CAD_DrawingPMI JSON mapping
-- Generated from CAD_Library: CAD_DrawingPMI (sealed, extends CAD_DrawingElement)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   CAD_Drawing, CAD_ConstructionGeometry
-- ============================================================

PRAGMA foreign_keys = ON;

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
-- CAD_DrawingPMI  (main table — flattens CAD_DrawingElement base)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingPMI (
    DrawingPMIID    TEXT PRIMARY KEY,          -- synthetic key

    -- Inherited from CAD_DrawingElement
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 4,    -- DrawingElementType (set to 4=PMI)
    MyDrawingID     TEXT,
    CurrentConstructionGeometryID TEXT,

    -- Own properties
    Is3D            INTEGER NOT NULL DEFAULT 0,    -- bool: 3D context vs 2D drawing-only
    PmiType         INTEGER NOT NULL DEFAULT 4,
    -- PmiType:
    --   0=Gdt, 1=Welding, 2=Hole, 3=SurfaceFinish, 4=Other

    FOREIGN KEY (MyDrawingID)                  REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- CAD_DrawingPMI collection junction tables
-- ============================================================

-- MyConstructionGeometry (inherited List<CAD_ConstructionGeometery>)
CREATE TABLE IF NOT EXISTS CAD_DrawingPMI_ConstructionGeometry (
    DrawingPMIID            TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingPMIID, ConstructionGeometryID),
    FOREIGN KEY (DrawingPMIID)           REFERENCES CAD_DrawingPMI(DrawingPMIID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_drawpmi_name     ON CAD_DrawingPMI(Name);
CREATE INDEX IF NOT EXISTS idx_drawpmi_type     ON CAD_DrawingPMI(PmiType);
CREATE INDEX IF NOT EXISTS idx_drawpmi_is3d     ON CAD_DrawingPMI(Is3D);
CREATE INDEX IF NOT EXISTS idx_drawpmi_drawing  ON CAD_DrawingPMI(MyDrawingID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: PMI with type label and drawing info
CREATE VIEW IF NOT EXISTS v_CAD_DrawingPMI_Detail AS
SELECT
    pmi.DrawingPMIID,
    pmi.Name,
    pmi.Is3D,
    CASE pmi.Is3D WHEN 1 THEN '3D' ELSE '2D' END AS DimensionContext,
    pmi.PmiType,
    CASE pmi.PmiType
        WHEN 0 THEN 'GD&T'
        WHEN 1 THEN 'Welding'
        WHEN 2 THEN 'Hole'
        WHEN 3 THEN 'SurfaceFinish'
        WHEN 4 THEN 'Other'
    END AS PmiTypeName,

    -- Drawing
    d.Title         AS DrawingTitle,
    d.DrawingNumber AS DrawingNumber,

    -- Construction geometry count
    (SELECT COUNT(*) FROM CAD_DrawingPMI_ConstructionGeometry pcg
     WHERE pcg.DrawingPMIID = pmi.DrawingPMIID) AS ConstructionGeometryCount

FROM CAD_DrawingPMI pmi
LEFT JOIN CAD_Drawing d ON pmi.MyDrawingID = d.DrawingID;

-- View: PMI grouped by type and context
CREATE VIEW IF NOT EXISTS v_CAD_DrawingPMI_Summary AS
SELECT
    pmi.PmiType,
    CASE pmi.PmiType
        WHEN 0 THEN 'GD&T'
        WHEN 1 THEN 'Welding'
        WHEN 2 THEN 'Hole'
        WHEN 3 THEN 'SurfaceFinish'
        WHEN 4 THEN 'Other'
    END AS PmiTypeName,
    SUM(CASE WHEN pmi.Is3D = 1 THEN 1 ELSE 0 END) AS Count3D,
    SUM(CASE WHEN pmi.Is3D = 0 THEN 1 ELSE 0 END) AS Count2D,
    COUNT(*) AS TotalCount
FROM CAD_DrawingPMI pmi
GROUP BY pmi.PmiType
ORDER BY pmi.PmiType;
