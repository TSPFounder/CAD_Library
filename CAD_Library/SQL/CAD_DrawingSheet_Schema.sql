-- ============================================================
-- SQLite Schema for CAD_DrawingSheet JSON mapping
-- Generated from CAD_Library: CAD_DrawingSheet (sealed class)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   CAD_Drawing, CAD_DrawingView, CAD_Dimension,
--   CAD_DrawingNote, CAD_ConstructionGeometry,
--   CAD_DrawingPMI, CAD_DrawingTable, CAD_BoM
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

CREATE TABLE IF NOT EXISTS CAD_DrawingView (
    DrawingViewID   TEXT PRIMARY KEY,
    Title           TEXT,
    ViewType        INTEGER NOT NULL DEFAULT 9
);

CREATE TABLE IF NOT EXISTS CAD_Dimension (
    DimensionID     TEXT PRIMARY KEY,
    Description     TEXT
);

CREATE TABLE IF NOT EXISTS CAD_DrawingNote (
    DrawingNoteID   TEXT PRIMARY KEY,
    NoteText        TEXT,
    MyNoteType      INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_ConstructionGeometry (
    ConstructionGeometryID  TEXT PRIMARY KEY,
    Name            TEXT,
    Version         TEXT NOT NULL DEFAULT '1.0',
    GeometryType    INTEGER NOT NULL DEFAULT 0,
    MyCAD_ModelID   TEXT
);

CREATE TABLE IF NOT EXISTS CAD_DrawingPMI (
    DrawingPMIID    TEXT PRIMARY KEY,
    Name            TEXT,
    Is3D            INTEGER NOT NULL DEFAULT 0,
    PmiType         INTEGER NOT NULL DEFAULT 4
);

CREATE TABLE IF NOT EXISTS CAD_DrawingTable (
    DrawingTableID  TEXT PRIMARY KEY,
    Name            TEXT
);

CREATE TABLE IF NOT EXISTS CAD_BoM (
    BoMID           TEXT PRIMARY KEY,
    BoMType         INTEGER
);

-- ============================================================
-- CAD_DrawingSheet  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingSheet (
    SheetID         TEXT PRIMARY KEY,

    -- Metadata
    SheetNumber     INTEGER NOT NULL DEFAULT 1,

    -- Size (reuses CAD_Drawing.DrawingSize enum)
    Size            INTEGER NOT NULL DEFAULT 4,
    -- DrawingSize: 0=E, 1=D, 2=C, 3=B, 4=A, 5=A1, 6=A2, 7=A3

    -- Orientation
    SheetOrientation INTEGER NOT NULL DEFAULT 0,
    -- Orientation: 0=Landscape, 1=Portrait

    -- Ownership
    MyDrawingID     TEXT,
    MyBoMID         TEXT,

    -- Current cursors
    CurrentDrawingViewID            TEXT,
    CurrentDimensionID              TEXT,
    CurrentDrawingNoteID            TEXT,
    CurrentConstructionGeometryID   TEXT,
    CurrentPMIID                    TEXT,
    CurrentDrawingTableID           TEXT,

    FOREIGN KEY (MyDrawingID)                  REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (MyBoMID)                      REFERENCES CAD_BoM(BoMID),
    FOREIGN KEY (CurrentDrawingViewID)         REFERENCES CAD_DrawingView(DrawingViewID),
    FOREIGN KEY (CurrentDimensionID)           REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CurrentDrawingNoteID)         REFERENCES CAD_DrawingNote(DrawingNoteID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID),
    FOREIGN KEY (CurrentPMIID)                 REFERENCES CAD_DrawingPMI(DrawingPMIID),
    FOREIGN KEY (CurrentDrawingTableID)        REFERENCES CAD_DrawingTable(DrawingTableID)
);

-- ============================================================
-- CAD_DrawingSheet collection junction tables
-- ============================================================

-- DrawingViews (IReadOnlyList<CAD_DrawingView>)
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_DrawingView (
    SheetID         TEXT NOT NULL,
    DrawingViewID   TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DrawingViewID),
    FOREIGN KEY (SheetID)       REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DrawingViewID) REFERENCES CAD_DrawingView(DrawingViewID)
);

-- Dimensions (IReadOnlyList<CAD_Dimension>)
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_Dimension (
    SheetID         TEXT NOT NULL,
    DimensionID     TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DimensionID),
    FOREIGN KEY (SheetID)       REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DimensionID)   REFERENCES CAD_Dimension(DimensionID)
);

-- DrawingNotes (IReadOnlyList<CAD_DrawingNote>)
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_DrawingNote (
    SheetID         TEXT NOT NULL,
    DrawingNoteID   TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DrawingNoteID),
    FOREIGN KEY (SheetID)       REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DrawingNoteID) REFERENCES CAD_DrawingNote(DrawingNoteID)
);

-- ConstructionGeometry (IReadOnlyList<CAD_ConstructionGeometery>)
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_ConstructionGeometry (
    SheetID                 TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, ConstructionGeometryID),
    FOREIGN KEY (SheetID)                REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- PMI (IReadOnlyList<CAD_DrawingPMI>)
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_PMI (
    SheetID         TEXT NOT NULL,
    DrawingPMIID    TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DrawingPMIID),
    FOREIGN KEY (SheetID)       REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DrawingPMIID)  REFERENCES CAD_DrawingPMI(DrawingPMIID)
);

-- DrawingTables (IReadOnlyList<CAD_DrawingTable>)
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_DrawingTable (
    SheetID         TEXT NOT NULL,
    DrawingTableID  TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DrawingTableID),
    FOREIGN KEY (SheetID)        REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DrawingTableID) REFERENCES CAD_DrawingTable(DrawingTableID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_sheet_number      ON CAD_DrawingSheet(SheetNumber);
CREATE INDEX IF NOT EXISTS idx_sheet_size        ON CAD_DrawingSheet(Size);
CREATE INDEX IF NOT EXISTS idx_sheet_orientation ON CAD_DrawingSheet(SheetOrientation);
CREATE INDEX IF NOT EXISTS idx_sheet_drawing     ON CAD_DrawingSheet(MyDrawingID);
CREATE INDEX IF NOT EXISTS idx_sheet_bom         ON CAD_DrawingSheet(MyBoMID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: sheet with drawing info and child counts
CREATE VIEW IF NOT EXISTS v_CAD_DrawingSheet_Detail AS
SELECT
    sh.SheetID,
    sh.SheetNumber,
    sh.Size,
    CASE sh.Size
        WHEN 0 THEN 'E'  WHEN 1 THEN 'D'  WHEN 2 THEN 'C'
        WHEN 3 THEN 'B'  WHEN 4 THEN 'A'  WHEN 5 THEN 'A1'
        WHEN 6 THEN 'A2' WHEN 7 THEN 'A3'
    END AS SizeName,
    sh.SheetOrientation,
    CASE sh.SheetOrientation
        WHEN 0 THEN 'Landscape'
        WHEN 1 THEN 'Portrait'
    END AS OrientationName,

    -- Drawing
    d.Title         AS DrawingTitle,
    d.DrawingNumber AS DrawingNumber,

    -- Child counts
    (SELECT COUNT(*) FROM CAD_DrawingSheet_DrawingView sdv
     WHERE sdv.SheetID = sh.SheetID) AS ViewCount,
    (SELECT COUNT(*) FROM CAD_DrawingSheet_Dimension sdm
     WHERE sdm.SheetID = sh.SheetID) AS DimensionCount,
    (SELECT COUNT(*) FROM CAD_DrawingSheet_DrawingNote sdn
     WHERE sdn.SheetID = sh.SheetID) AS NoteCount,
    (SELECT COUNT(*) FROM CAD_DrawingSheet_ConstructionGeometry scg
     WHERE scg.SheetID = sh.SheetID) AS ConstructionGeometryCount,
    (SELECT COUNT(*) FROM CAD_DrawingSheet_PMI spm
     WHERE spm.SheetID = sh.SheetID) AS PMICount,
    (SELECT COUNT(*) FROM CAD_DrawingSheet_DrawingTable sdt
     WHERE sdt.SheetID = sh.SheetID) AS TableCount

FROM CAD_DrawingSheet sh
LEFT JOIN CAD_Drawing d ON sh.MyDrawingID = d.DrawingID;

-- View: sheets with their drawing views
CREATE VIEW IF NOT EXISTS v_CAD_DrawingSheet_Views AS
SELECT
    sh.SheetID,
    sh.SheetNumber,
    sdv.SortOrder,
    dv.DrawingViewID,
    dv.Title        AS ViewTitle,
    dv.ViewType,
    CASE dv.ViewType
        WHEN 0 THEN 'OrthoTop'       WHEN 1 THEN 'OrthoFront'
        WHEN 2 THEN 'OrthoRightSide' WHEN 3 THEN 'OrthoBottom'
        WHEN 4 THEN 'OrthoBack'      WHEN 5 THEN 'OrthoLeftSide'
        WHEN 6 THEN 'Isometric'      WHEN 7 THEN 'CrossSection'
        WHEN 8 THEN 'Detail'         WHEN 9 THEN 'Other'
    END AS ViewTypeName
FROM CAD_DrawingSheet sh
JOIN CAD_DrawingSheet_DrawingView sdv ON sh.SheetID = sdv.SheetID
JOIN CAD_DrawingView dv               ON sdv.DrawingViewID = dv.DrawingViewID
ORDER BY sh.SheetNumber, sdv.SortOrder;

-- View: sheets with their notes
CREATE VIEW IF NOT EXISTS v_CAD_DrawingSheet_Notes AS
SELECT
    sh.SheetID,
    sh.SheetNumber,
    sdn.SortOrder,
    dn.DrawingNoteID,
    dn.NoteText,
    dn.MyNoteType,
    CASE dn.MyNoteType
        WHEN 0 THEN 'General'   WHEN 1 THEN 'Safety'
        WHEN 2 THEN 'Process'   WHEN 3 THEN 'Material'
        WHEN 4 THEN 'Finish'    WHEN 5 THEN 'Reference'
        WHEN 6 THEN 'Tolerance' WHEN 7 THEN 'Other'
    END AS NoteTypeName
FROM CAD_DrawingSheet sh
JOIN CAD_DrawingSheet_DrawingNote sdn ON sh.SheetID = sdn.SheetID
JOIN CAD_DrawingNote dn               ON sdn.DrawingNoteID = dn.DrawingNoteID
ORDER BY sh.SheetNumber, sdn.SortOrder;
