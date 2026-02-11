-- ============================================================
-- SQLite Schema for CAD_DrawingElement JSON mapping
-- Generated from CAD_Library: CAD_DrawingElement (base class)
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
-- CAD_DrawingElement  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingElement (
    DrawingElementID    TEXT PRIMARY KEY,      -- synthetic key

    -- Identification
    Name                TEXT,

    -- Classification
    MyType              INTEGER NOT NULL DEFAULT 0,
    -- DrawingElementType:
    --   0=DrawingView, 1=Dimension, 2=Table, 3=BoM,
    --   4=PMI, 5=ConstructionGeometry, 6=Note, 7=Other

    -- Ownership
    MyDrawingID                 TEXT,

    -- Current construction geometry cursor
    CurrentConstructionGeometryID TEXT,

    FOREIGN KEY (MyDrawingID)                  REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- CAD_DrawingElement collection junction tables
-- ============================================================

-- MyConstructionGeometry (List<CAD_ConstructionGeometery>)
CREATE TABLE IF NOT EXISTS CAD_DrawingElement_ConstructionGeometry (
    DrawingElementID        TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingElementID, ConstructionGeometryID),
    FOREIGN KEY (DrawingElementID)       REFERENCES CAD_DrawingElement(DrawingElementID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_drawelem_name    ON CAD_DrawingElement(Name);
CREATE INDEX IF NOT EXISTS idx_drawelem_type    ON CAD_DrawingElement(MyType);
CREATE INDEX IF NOT EXISTS idx_drawelem_drawing ON CAD_DrawingElement(MyDrawingID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: drawing element with type label and drawing info
CREATE VIEW IF NOT EXISTS v_CAD_DrawingElement_Detail AS
SELECT
    de.DrawingElementID,
    de.Name,
    de.MyType,
    CASE de.MyType
        WHEN 0 THEN 'DrawingView'
        WHEN 1 THEN 'Dimension'
        WHEN 2 THEN 'Table'
        WHEN 3 THEN 'BoM'
        WHEN 4 THEN 'PMI'
        WHEN 5 THEN 'ConstructionGeometry'
        WHEN 6 THEN 'Note'
        WHEN 7 THEN 'Other'
    END AS ElementTypeName,

    -- Drawing
    d.Title         AS DrawingTitle,
    d.DrawingNumber AS DrawingNumber,

    -- Construction geometry count
    (SELECT COUNT(*) FROM CAD_DrawingElement_ConstructionGeometry dec
     WHERE dec.DrawingElementID = de.DrawingElementID) AS ConstructionGeometryCount

FROM CAD_DrawingElement de
LEFT JOIN CAD_Drawing d ON de.MyDrawingID = d.DrawingID;

-- View: elements grouped by type
CREATE VIEW IF NOT EXISTS v_CAD_DrawingElement_ByType AS
SELECT
    de.MyType,
    CASE de.MyType
        WHEN 0 THEN 'DrawingView'
        WHEN 1 THEN 'Dimension'
        WHEN 2 THEN 'Table'
        WHEN 3 THEN 'BoM'
        WHEN 4 THEN 'PMI'
        WHEN 5 THEN 'ConstructionGeometry'
        WHEN 6 THEN 'Note'
        WHEN 7 THEN 'Other'
    END AS ElementTypeName,
    COUNT(*) AS ElementCount
FROM CAD_DrawingElement de
GROUP BY de.MyType
ORDER BY de.MyType;
