-- ============================================================
-- SQLite Schema for CAD_Configuration JSON mapping
-- Generated from CAD_Library: CAD_Configuration
-- ============================================================
-- Depends on shared tables from prior schemas:
--   CAD_Part, CAD_Assembly, SE_TableRow
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- Shared CAD types (stubs)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Part (
    PartID      TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    PartNumber  TEXT,
    Description TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Assembly (
    AssemblyID  TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    Description TEXT,
    IsSubAssembly       INTEGER NOT NULL DEFAULT 0,
    IsConfigurationItem INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- Shared SE_Library types (stubs)
-- ============================================================

CREATE TABLE IF NOT EXISTS SE_Table (
    TableID     TEXT PRIMARY KEY,
    Name        TEXT,
    Description TEXT
);

CREATE TABLE IF NOT EXISTS SE_TableRow (
    TableRowID  TEXT PRIMARY KEY,
    TableID     TEXT,
    FOREIGN KEY (TableID) REFERENCES SE_Table(TableID)
);

-- ============================================================
-- CAD_Configuration  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Configuration (
    ConfigurationID TEXT PRIMARY KEY,          -- maps to ID property

    -- Identification
    Name            TEXT,
    Description     TEXT,
    Revision        TEXT,

    -- Owned & Owning Objects
    CurrentPartID       TEXT,
    CurrentPartRowID    TEXT,          -- SE_TableRow reference
    MyAssemblyID        TEXT,

    FOREIGN KEY (CurrentPartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (CurrentPartRowID) REFERENCES SE_TableRow(TableRowID),
    FOREIGN KEY (MyAssemblyID)     REFERENCES CAD_Assembly(AssemblyID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_config_name       ON CAD_Configuration(Name);
CREATE INDEX IF NOT EXISTS idx_config_revision   ON CAD_Configuration(Revision);
CREATE INDEX IF NOT EXISTS idx_config_part       ON CAD_Configuration(CurrentPartID);
CREATE INDEX IF NOT EXISTS idx_config_assembly   ON CAD_Configuration(MyAssemblyID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: configuration with part and assembly info
CREATE VIEW IF NOT EXISTS v_CAD_Configuration_Detail AS
SELECT
    c.ConfigurationID,
    c.Name,
    c.Description,
    c.Revision,

    -- Part
    p.Name          AS PartName,
    p.PartNumber    AS PartNumber,
    p.Version       AS PartVersion,

    -- Assembly
    a.Name          AS AssemblyName,
    a.Version       AS AssemblyVersion,
    a.IsSubAssembly AS IsSubAssembly

FROM CAD_Configuration c
LEFT JOIN CAD_Part p        ON c.CurrentPartID = p.PartID
LEFT JOIN CAD_Assembly a    ON c.MyAssemblyID  = a.AssemblyID;
