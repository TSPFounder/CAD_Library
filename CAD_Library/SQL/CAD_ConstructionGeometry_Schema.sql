-- ============================================================
-- SQLite Schema for CAD_ConstructionGeometry JSON mapping
-- Generated from CAD_Library: CAD_ConstructionGeometry
-- (includes CAD_ConstructionGeometery backwards-compat shim)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   CAD_Model
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- Shared CAD types (stubs)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Model (
    ModelID     TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    Description TEXT,
    FilePath    TEXT,
    CAD_AppName INTEGER NOT NULL DEFAULT 0,
    ModelType   INTEGER NOT NULL DEFAULT 0,
    FileType    INTEGER NOT NULL DEFAULT 0,
    CurrentStationID    TEXT,
    CurrentSketchID     TEXT,
    CurrentFeatureID    TEXT,
    CurrentPartID       TEXT,
    CurrentDrawingID    TEXT,
    CurrentAssemblyID   TEXT,
    MySystemID  TEXT,
    MyBoMID     TEXT
);

-- ============================================================
-- CAD_ConstructionGeometry  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_ConstructionGeometry (
    ConstructionGeometryID  TEXT PRIMARY KEY,  -- synthetic key

    -- Identification
    Name            TEXT,
    Version         TEXT NOT NULL DEFAULT '1.0',

    -- Classification
    GeometryType    INTEGER NOT NULL DEFAULT 0,
    -- ConstructionGeometryTypeEnum:
    --   0=Point, 1=Line, 2=Plane, 3=Circle

    -- Ownership
    MyCAD_ModelID   TEXT,

    FOREIGN KEY (MyCAD_ModelID) REFERENCES CAD_Model(ModelID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_cg_name      ON CAD_ConstructionGeometry(Name);
CREATE INDEX IF NOT EXISTS idx_cg_version   ON CAD_ConstructionGeometry(Version);
CREATE INDEX IF NOT EXISTS idx_cg_type      ON CAD_ConstructionGeometry(GeometryType);
CREATE INDEX IF NOT EXISTS idx_cg_model     ON CAD_ConstructionGeometry(MyCAD_ModelID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: construction geometry with model info
CREATE VIEW IF NOT EXISTS v_CAD_ConstructionGeometry_Detail AS
SELECT
    cg.ConstructionGeometryID,
    cg.Name,
    cg.Version,
    cg.GeometryType,
    CASE cg.GeometryType
        WHEN 0 THEN 'Point'
        WHEN 1 THEN 'Line'
        WHEN 2 THEN 'Plane'
        WHEN 3 THEN 'Circle'
    END AS GeometryTypeName,

    -- Model
    m.Name          AS ModelName,
    m.CAD_AppName   AS ModelApp,
    CASE m.CAD_AppName
        WHEN 0 THEN 'Fusion360'    WHEN 1 THEN 'Solidworks'
        WHEN 2 THEN 'Blender'      WHEN 3 THEN 'UnReal4'
        WHEN 4 THEN 'UnReal5'      WHEN 5 THEN 'Unity'
        WHEN 6 THEN 'Other'
    END AS ModelAppText

FROM CAD_ConstructionGeometry cg
LEFT JOIN CAD_Model m ON cg.MyCAD_ModelID = m.ModelID;

-- View: construction geometry grouped by type
CREATE VIEW IF NOT EXISTS v_CAD_ConstructionGeometry_ByType AS
SELECT
    cg.GeometryType,
    CASE cg.GeometryType
        WHEN 0 THEN 'Point'
        WHEN 1 THEN 'Line'
        WHEN 2 THEN 'Plane'
        WHEN 3 THEN 'Circle'
    END AS GeometryTypeName,
    COUNT(*) AS ItemCount
FROM CAD_ConstructionGeometry cg
GROUP BY cg.GeometryType
ORDER BY cg.GeometryType;
