-- ============================================================
-- SQLite Schema for CAD_BoM JSON mapping
-- Generated from CAD_Library: CAD_BoM (extends CAD_DrawingElement)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   CAD_Drawing, CAD_ConstructionGeometry, CAD_Configuration,
--   CAD_DrawingBoM_Table
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

CREATE TABLE IF NOT EXISTS CAD_Configuration (
    ConfigurationID TEXT PRIMARY KEY,
    Name            TEXT,
    Description     TEXT,
    Revision        TEXT,
    CurrentPartID       TEXT,
    CurrentPartRowID    TEXT,
    MyAssemblyID        TEXT
);

CREATE TABLE IF NOT EXISTS CAD_DrawingBoM_Table (
    DrawingBoMTableID   TEXT PRIMARY KEY,
    Name                TEXT,
    MyDrawingID         TEXT,
    MyTableID           TEXT
);

-- ============================================================
-- CAD_BoM  (main table — flattens CAD_DrawingElement base)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_BoM (
    BoMID           TEXT PRIMARY KEY,          -- synthetic key

    -- Inherited from CAD_DrawingElement
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 3,    -- DrawingElementType (set to 3=BoM)
    MyDrawingID     TEXT,
    CurrentConstructionGeometryID TEXT,

    -- Own properties
    BoMType         INTEGER,
    -- BoM_TypeEnum (nullable):
    --   0=Design, 1=Manufacturing, 2=Estimating, 3=Other

    -- Configuration
    CurrentConfigurationID  TEXT,

    -- BoM-dedicated drawing table
    DrawingBoMTableID       TEXT,

    FOREIGN KEY (MyDrawingID)                  REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID),
    FOREIGN KEY (CurrentConfigurationID)       REFERENCES CAD_Configuration(ConfigurationID),
    FOREIGN KEY (DrawingBoMTableID)            REFERENCES CAD_DrawingBoM_Table(DrawingBoMTableID)
);

-- ============================================================
-- CAD_BoM collection junction tables
-- ============================================================

-- Configurations (IReadOnlyList<CAD_Configuration>)
CREATE TABLE IF NOT EXISTS CAD_BoM_Configuration (
    BoMID               TEXT NOT NULL,
    ConfigurationID     TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BoMID, ConfigurationID),
    FOREIGN KEY (BoMID)             REFERENCES CAD_BoM(BoMID),
    FOREIGN KEY (ConfigurationID)   REFERENCES CAD_Configuration(ConfigurationID)
);

-- MyConstructionGeometry (inherited List<CAD_ConstructionGeometery>)
CREATE TABLE IF NOT EXISTS CAD_BoM_ConstructionGeometry (
    BoMID                   TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (BoMID, ConstructionGeometryID),
    FOREIGN KEY (BoMID)                  REFERENCES CAD_BoM(BoMID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_bom_name       ON CAD_BoM(Name);
CREATE INDEX IF NOT EXISTS idx_bom_type       ON CAD_BoM(BoMType);
CREATE INDEX IF NOT EXISTS idx_bom_drawing    ON CAD_BoM(MyDrawingID);
CREATE INDEX IF NOT EXISTS idx_bom_config     ON CAD_BoM(CurrentConfigurationID);
CREATE INDEX IF NOT EXISTS idx_bom_bomtable   ON CAD_BoM(DrawingBoMTableID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: BoM with type label, drawing info, and configuration count
CREATE VIEW IF NOT EXISTS v_CAD_BoM_Detail AS
SELECT
    b.BoMID,
    b.Name,
    b.BoMType,
    CASE b.BoMType
        WHEN 0 THEN 'Design'
        WHEN 1 THEN 'Manufacturing'
        WHEN 2 THEN 'Estimating'
        WHEN 3 THEN 'Other'
        ELSE '(unspecified)'
    END AS BoMTypeName,

    -- Drawing
    d.Title         AS DrawingTitle,
    d.DrawingNumber AS DrawingNumber,

    -- Current configuration
    cfg.Name        AS CurrentConfigName,
    cfg.Revision    AS CurrentConfigRevision,

    -- BoM table
    bt.Name         AS DrawingBoMTableName,

    -- Configuration count
    (SELECT COUNT(*) FROM CAD_BoM_Configuration bc
     WHERE bc.BoMID = b.BoMID) AS ConfigurationCount

FROM CAD_BoM b
LEFT JOIN CAD_Drawing d             ON b.MyDrawingID            = d.DrawingID
LEFT JOIN CAD_Configuration cfg     ON b.CurrentConfigurationID = cfg.ConfigurationID
LEFT JOIN CAD_DrawingBoM_Table bt   ON b.DrawingBoMTableID      = bt.DrawingBoMTableID;

-- View: BoMs grouped by type
CREATE VIEW IF NOT EXISTS v_CAD_BoM_ByType AS
SELECT
    b.BoMType,
    CASE b.BoMType
        WHEN 0 THEN 'Design'
        WHEN 1 THEN 'Manufacturing'
        WHEN 2 THEN 'Estimating'
        WHEN 3 THEN 'Other'
        ELSE '(unspecified)'
    END AS BoMTypeName,
    COUNT(*) AS BoMCount,
    SUM((SELECT COUNT(*) FROM CAD_BoM_Configuration bc WHERE bc.BoMID = b.BoMID)) AS TotalConfigurations
FROM CAD_BoM b
GROUP BY b.BoMType
ORDER BY b.BoMType;
