-- ============================================================
-- SQLite Schema for CAD_DrawingTable JSON mapping
-- Generated from CAD_Library: CAD_DrawingTable (sealed, extends CAD_DrawingElement)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   CAD_Drawing, CAD_ConstructionGeometry, CAD_Configuration,
--   SE_Table, SE_TableColumn
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

-- ============================================================
-- Shared SE_Library types (stubs)
-- ============================================================

CREATE TABLE IF NOT EXISTS SE_Table (
    TableID     TEXT PRIMARY KEY,
    Name        TEXT,
    Description TEXT
);

CREATE TABLE IF NOT EXISTS SE_TableColumn (
    TableColumnID   TEXT PRIMARY KEY,
    ColumnName      TEXT,
    ID              TEXT,
    Description     TEXT,
    ColumnType      INTEGER NOT NULL DEFAULT 0,
    -- ColumnTypeEnum: 0=String, 1=Integer, 2=Boolean,
    --   3=Double, 4=Single, 5=DateTime, 6=Object, 7=Other
    TableID         TEXT,
    FOREIGN KEY (TableID) REFERENCES SE_Table(TableID)
);

-- ============================================================
-- CAD_DrawingTable  (main table — flattens CAD_DrawingElement base)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingTable (
    DrawingTableID  TEXT PRIMARY KEY,          -- synthetic key

    -- Inherited from CAD_DrawingElement
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 2,    -- DrawingElementType (set to 2=Table)
    MyDrawingID     TEXT,
    CurrentConstructionGeometryID TEXT,

    -- Title block columns (SE_TableColumn references)
    DrawingNumberColumnID   TEXT,
    DrawingTitleColumnID    TEXT,
    DrawingStandardColumnID TEXT,
    DrawingSizeColumnID     TEXT,
    ReleaseDateColumnID     TEXT,
    PartNumberColumnID      TEXT,
    NextAssemblyColumnID    TEXT,
    RevisionColumnID        TEXT,

    -- Backing data table
    TableID                 TEXT,

    -- Configuration
    CurrentConfigurationID  TEXT,

    FOREIGN KEY (MyDrawingID)                  REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID),
    FOREIGN KEY (DrawingNumberColumnID)        REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (DrawingTitleColumnID)         REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (DrawingStandardColumnID)      REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (DrawingSizeColumnID)          REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (ReleaseDateColumnID)          REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (PartNumberColumnID)           REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (NextAssemblyColumnID)         REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (RevisionColumnID)             REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (TableID)                      REFERENCES SE_Table(TableID),
    FOREIGN KEY (CurrentConfigurationID)       REFERENCES CAD_Configuration(ConfigurationID)
);

-- ============================================================
-- CAD_DrawingTable collection junction tables
-- ============================================================

-- Configurations (List<CAD_Configuration>)
CREATE TABLE IF NOT EXISTS CAD_DrawingTable_Configuration (
    DrawingTableID      TEXT NOT NULL,
    ConfigurationID     TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingTableID, ConfigurationID),
    FOREIGN KEY (DrawingTableID)   REFERENCES CAD_DrawingTable(DrawingTableID),
    FOREIGN KEY (ConfigurationID)  REFERENCES CAD_Configuration(ConfigurationID)
);

-- MyConstructionGeometry (inherited List<CAD_ConstructionGeometery>)
CREATE TABLE IF NOT EXISTS CAD_DrawingTable_ConstructionGeometry (
    DrawingTableID          TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingTableID, ConstructionGeometryID),
    FOREIGN KEY (DrawingTableID)         REFERENCES CAD_DrawingTable(DrawingTableID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_drawtable_name      ON CAD_DrawingTable(Name);
CREATE INDEX IF NOT EXISTS idx_drawtable_drawing   ON CAD_DrawingTable(MyDrawingID);
CREATE INDEX IF NOT EXISTS idx_drawtable_table     ON CAD_DrawingTable(TableID);
CREATE INDEX IF NOT EXISTS idx_drawtable_config    ON CAD_DrawingTable(CurrentConfigurationID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: drawing table with column names and configuration info
CREATE VIEW IF NOT EXISTS v_CAD_DrawingTable_Detail AS
SELECT
    dt.DrawingTableID,
    dt.Name,

    -- Drawing
    d.Title         AS DrawingTitle,
    d.DrawingNumber AS DrawingDrawingNumber,

    -- Column names (from SE_TableColumn)
    dn_col.ColumnName  AS DrawingNumberColName,
    dt_col.ColumnName  AS DrawingTitleColName,
    ds_col.ColumnName  AS DrawingStandardColName,
    sz_col.ColumnName  AS DrawingSizeColName,
    rd_col.ColumnName  AS ReleaseDateColName,
    pn_col.ColumnName  AS PartNumberColName,
    na_col.ColumnName  AS NextAssemblyColName,
    rv_col.ColumnName  AS RevisionColName,

    -- Backing table
    t.Name          AS BackingTableName,

    -- Configuration
    cfg.Name        AS CurrentConfigName,
    cfg.Revision    AS CurrentConfigRevision,

    -- Configuration count
    (SELECT COUNT(*) FROM CAD_DrawingTable_Configuration dtc
     WHERE dtc.DrawingTableID = dt.DrawingTableID) AS ConfigurationCount

FROM CAD_DrawingTable dt
LEFT JOIN CAD_Drawing d             ON dt.MyDrawingID             = d.DrawingID
LEFT JOIN SE_TableColumn dn_col     ON dt.DrawingNumberColumnID   = dn_col.TableColumnID
LEFT JOIN SE_TableColumn dt_col     ON dt.DrawingTitleColumnID    = dt_col.TableColumnID
LEFT JOIN SE_TableColumn ds_col     ON dt.DrawingStandardColumnID = ds_col.TableColumnID
LEFT JOIN SE_TableColumn sz_col     ON dt.DrawingSizeColumnID     = sz_col.TableColumnID
LEFT JOIN SE_TableColumn rd_col     ON dt.ReleaseDateColumnID     = rd_col.TableColumnID
LEFT JOIN SE_TableColumn pn_col     ON dt.PartNumberColumnID      = pn_col.TableColumnID
LEFT JOIN SE_TableColumn na_col     ON dt.NextAssemblyColumnID    = na_col.TableColumnID
LEFT JOIN SE_TableColumn rv_col     ON dt.RevisionColumnID        = rv_col.TableColumnID
LEFT JOIN SE_Table t                ON dt.TableID                 = t.TableID
LEFT JOIN CAD_Configuration cfg     ON dt.CurrentConfigurationID  = cfg.ConfigurationID;
