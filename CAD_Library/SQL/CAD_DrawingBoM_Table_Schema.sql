-- ============================================================
-- SQLite Schema for CAD_DrawingBoM_Table JSON mapping
-- Generated from CAD_Library: CAD_DrawingBoM_Table (extends CAD_DrawingElement)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, CAD_Drawing, CAD_ConstructionGeometry, CAD_Configuration,
--   SE_Table, SE_TableColumn, SE_TableRow
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
    TableID         TEXT,
    FOREIGN KEY (TableID) REFERENCES SE_Table(TableID)
);

CREATE TABLE IF NOT EXISTS SE_TableRow (
    TableRowID  TEXT PRIMARY KEY,
    TableID     TEXT,
    FOREIGN KEY (TableID) REFERENCES SE_Table(TableID)
);

-- ============================================================
-- CAD_DrawingBoM_Table  (main table — flattens CAD_DrawingElement base)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingBoM_Table (
    DrawingBoMTableID   TEXT PRIMARY KEY,      -- synthetic key

    -- Inherited from CAD_DrawingElement
    Name                TEXT,
    MyType              INTEGER NOT NULL DEFAULT 2,    -- DrawingElementType
    MyDrawingID         TEXT,
    CurrentConstructionGeometryID TEXT,

    -- Backing data table
    MyTableID           TEXT,

    -- Configuration
    CurrentConfigurationID  TEXT,

    -- Typed columns (SE_TableColumn references)
    ItemNumberColumnID      TEXT,
    PartNumberColumnID      TEXT,
    DrawingNumberColumnID   TEXT,
    RevisionColumnID        TEXT,
    QuantityColumnID        TEXT,
    DescriptionColumnID     TEXT,
    MaterialColumnID        TEXT,
    SpecificationColumnID   TEXT,

    -- Rows
    HeaderRowID         TEXT,
    PartRowID           TEXT,              -- last/active convenience row

    -- Metadata
    ChangeOrderID       TEXT,

    -- Placement on sheet
    MyLocationPointID   TEXT,

    FOREIGN KEY (MyDrawingID)                  REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID),
    FOREIGN KEY (MyTableID)                    REFERENCES SE_Table(TableID),
    FOREIGN KEY (CurrentConfigurationID)       REFERENCES CAD_Configuration(ConfigurationID),
    FOREIGN KEY (ItemNumberColumnID)           REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (PartNumberColumnID)           REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (DrawingNumberColumnID)        REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (RevisionColumnID)             REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (QuantityColumnID)             REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (DescriptionColumnID)          REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (MaterialColumnID)             REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (SpecificationColumnID)        REFERENCES SE_TableColumn(TableColumnID),
    FOREIGN KEY (HeaderRowID)                  REFERENCES SE_TableRow(TableRowID),
    FOREIGN KEY (PartRowID)                    REFERENCES SE_TableRow(TableRowID),
    FOREIGN KEY (MyLocationPointID)            REFERENCES Point(PointID)
);

-- ============================================================
-- CAD_DrawingBoM_Table collection junction tables
-- ============================================================

-- MyConfigurations (IReadOnlyList<CAD_Configuration>)
CREATE TABLE IF NOT EXISTS CAD_DrawingBoMTable_Configuration (
    DrawingBoMTableID   TEXT NOT NULL,
    ConfigurationID     TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingBoMTableID, ConfigurationID),
    FOREIGN KEY (DrawingBoMTableID) REFERENCES CAD_DrawingBoM_Table(DrawingBoMTableID),
    FOREIGN KEY (ConfigurationID)   REFERENCES CAD_Configuration(ConfigurationID)
);

-- MyBoMRows (IReadOnlyList<SE_TableRow>)
CREATE TABLE IF NOT EXISTS CAD_DrawingBoMTable_Row (
    DrawingBoMTableID   TEXT NOT NULL,
    TableRowID          TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingBoMTableID, TableRowID),
    FOREIGN KEY (DrawingBoMTableID) REFERENCES CAD_DrawingBoM_Table(DrawingBoMTableID),
    FOREIGN KEY (TableRowID)        REFERENCES SE_TableRow(TableRowID)
);

-- MyConstructionGeometry (inherited List<CAD_ConstructionGeometery>)
CREATE TABLE IF NOT EXISTS CAD_DrawingBoMTable_ConstructionGeometry (
    DrawingBoMTableID       TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingBoMTableID, ConstructionGeometryID),
    FOREIGN KEY (DrawingBoMTableID)      REFERENCES CAD_DrawingBoM_Table(DrawingBoMTableID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_bomtable_name       ON CAD_DrawingBoM_Table(Name);
CREATE INDEX IF NOT EXISTS idx_bomtable_drawing    ON CAD_DrawingBoM_Table(MyDrawingID);
CREATE INDEX IF NOT EXISTS idx_bomtable_table      ON CAD_DrawingBoM_Table(MyTableID);
CREATE INDEX IF NOT EXISTS idx_bomtable_config     ON CAD_DrawingBoM_Table(CurrentConfigurationID);
CREATE INDEX IF NOT EXISTS idx_bomtable_changeord  ON CAD_DrawingBoM_Table(ChangeOrderID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: BoM table with column names, row counts, and location
CREATE VIEW IF NOT EXISTS v_CAD_DrawingBoMTable_Detail AS
SELECT
    bt.DrawingBoMTableID,
    bt.Name,
    bt.ChangeOrderID,

    -- Drawing
    d.Title             AS DrawingTitle,
    d.DrawingNumber     AS DrawingNumber,

    -- Backing table
    t.Name              AS BackingTableName,

    -- Configuration
    cfg.Name            AS CurrentConfigName,

    -- Column names
    ic.ColumnName AS ItemNumberColName,
    pc.ColumnName AS PartNumberColName,
    dc.ColumnName AS DrawingNumberColName,
    rc.ColumnName AS RevisionColName,
    qc.ColumnName AS QuantityColName,
    dsc.ColumnName AS DescriptionColName,
    mc.ColumnName AS MaterialColName,
    sc.ColumnName AS SpecificationColName,

    -- Location
    lp.X_Value          AS Location_X,
    lp.Y_Value          AS Location_Y,
    lp.Z_Value_Cartesian AS Location_Z,

    -- Row count
    (SELECT COUNT(*) FROM CAD_DrawingBoMTable_Row br
     WHERE br.DrawingBoMTableID = bt.DrawingBoMTableID) AS RowCount,

    -- Configuration count
    (SELECT COUNT(*) FROM CAD_DrawingBoMTable_Configuration bc
     WHERE bc.DrawingBoMTableID = bt.DrawingBoMTableID) AS ConfigurationCount

FROM CAD_DrawingBoM_Table bt
LEFT JOIN CAD_Drawing d             ON bt.MyDrawingID            = d.DrawingID
LEFT JOIN SE_Table t                ON bt.MyTableID              = t.TableID
LEFT JOIN CAD_Configuration cfg     ON bt.CurrentConfigurationID = cfg.ConfigurationID
LEFT JOIN SE_TableColumn ic         ON bt.ItemNumberColumnID     = ic.TableColumnID
LEFT JOIN SE_TableColumn pc         ON bt.PartNumberColumnID     = pc.TableColumnID
LEFT JOIN SE_TableColumn dc         ON bt.DrawingNumberColumnID  = dc.TableColumnID
LEFT JOIN SE_TableColumn rc         ON bt.RevisionColumnID       = rc.TableColumnID
LEFT JOIN SE_TableColumn qc         ON bt.QuantityColumnID       = qc.TableColumnID
LEFT JOIN SE_TableColumn dsc        ON bt.DescriptionColumnID    = dsc.TableColumnID
LEFT JOIN SE_TableColumn mc         ON bt.MaterialColumnID       = mc.TableColumnID
LEFT JOIN SE_TableColumn sc         ON bt.SpecificationColumnID  = sc.TableColumnID
LEFT JOIN Point lp                  ON bt.MyLocationPointID      = lp.PointID;
