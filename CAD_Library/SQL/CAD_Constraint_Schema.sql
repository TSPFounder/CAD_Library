-- ============================================================
-- SQLite Schema for CAD_Constraint JSON mapping
-- Generated from CAD_Library: CAD_Constraint (sealed class)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   CAD_Feature, CAD_Model
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

CREATE TABLE IF NOT EXISTS CAD_Feature (
    FeatureID   TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    GeometricFeatureType INTEGER NOT NULL DEFAULT 0,
    MyModelID   TEXT,
    FOREIGN KEY (MyModelID) REFERENCES CAD_Model(ModelID)
);

-- ============================================================
-- CAD_Constraint  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Constraint (
    ConstraintID    TEXT PRIMARY KEY,          -- maps to ID property

    -- Identification
    Name            TEXT,
    Description     TEXT,

    -- Classification
    Type            INTEGER NOT NULL DEFAULT 16,
    -- ConstraintType:
    --   0=Horizontal, 1=Vertical, 2=Distance, 3=Coincident,
    --   4=Tangent, 5=Angle, 6=Equal, 7=Parallel,
    --   8=Perpendicular, 9=Fixed, 10=Midpoint, 11=Midplane,
    --   12=Concentric, 13=Collinear, 14=Symmetry,
    --   15=Curvature, 16=Other

    -- Owned & Owning Objects
    CurrentFeatureID    TEXT,
    PreviousFeatureID   TEXT,
    CurrentModelID      TEXT,

    FOREIGN KEY (CurrentFeatureID)  REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (PreviousFeatureID) REFERENCES CAD_Feature(FeatureID),
    FOREIGN KEY (CurrentModelID)    REFERENCES CAD_Model(ModelID)
);

-- ============================================================
-- CAD_Constraint collection junction tables
-- ============================================================

-- Features (IReadOnlyList<CAD_Feature>)
CREATE TABLE IF NOT EXISTS CAD_Constraint_Feature (
    ConstraintID    TEXT NOT NULL,
    FeatureID       TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ConstraintID, FeatureID),
    FOREIGN KEY (ConstraintID) REFERENCES CAD_Constraint(ConstraintID),
    FOREIGN KEY (FeatureID)    REFERENCES CAD_Feature(FeatureID)
);

-- Models (IReadOnlyList<CAD_Model>)
CREATE TABLE IF NOT EXISTS CAD_Constraint_Model (
    ConstraintID    TEXT NOT NULL,
    ModelID         TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ConstraintID, ModelID),
    FOREIGN KEY (ConstraintID) REFERENCES CAD_Constraint(ConstraintID),
    FOREIGN KEY (ModelID)      REFERENCES CAD_Model(ModelID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_constraint_name       ON CAD_Constraint(Name);
CREATE INDEX IF NOT EXISTS idx_constraint_type       ON CAD_Constraint(Type);
CREATE INDEX IF NOT EXISTS idx_constraint_cur_feat   ON CAD_Constraint(CurrentFeatureID);
CREATE INDEX IF NOT EXISTS idx_constraint_prev_feat  ON CAD_Constraint(PreviousFeatureID);
CREATE INDEX IF NOT EXISTS idx_constraint_model      ON CAD_Constraint(CurrentModelID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: constraint with type label and feature/model info
CREATE VIEW IF NOT EXISTS v_CAD_Constraint_Detail AS
SELECT
    c.ConstraintID,
    c.Name,
    c.Description,
    c.Type,
    CASE c.Type
        WHEN 0  THEN 'Horizontal'    WHEN 1  THEN 'Vertical'
        WHEN 2  THEN 'Distance'      WHEN 3  THEN 'Coincident'
        WHEN 4  THEN 'Tangent'       WHEN 5  THEN 'Angle'
        WHEN 6  THEN 'Equal'         WHEN 7  THEN 'Parallel'
        WHEN 8  THEN 'Perpendicular' WHEN 9  THEN 'Fixed'
        WHEN 10 THEN 'Midpoint'      WHEN 11 THEN 'Midplane'
        WHEN 12 THEN 'Concentric'    WHEN 13 THEN 'Collinear'
        WHEN 14 THEN 'Symmetry'      WHEN 15 THEN 'Curvature'
        WHEN 16 THEN 'Other'
    END AS ConstraintTypeName,

    -- Current feature
    cf.Name     AS CurrentFeatureName,
    cf.GeometricFeatureType AS CurrentFeatureGeoType,

    -- Previous feature
    pf.Name     AS PreviousFeatureName,

    -- Current model
    m.Name      AS CurrentModelName,

    -- Collection counts
    (SELECT COUNT(*) FROM CAD_Constraint_Feature cft
     WHERE cft.ConstraintID = c.ConstraintID) AS FeatureCount,
    (SELECT COUNT(*) FROM CAD_Constraint_Model cmm
     WHERE cmm.ConstraintID = c.ConstraintID) AS ModelCount

FROM CAD_Constraint c
LEFT JOIN CAD_Feature cf    ON c.CurrentFeatureID  = cf.FeatureID
LEFT JOIN CAD_Feature pf    ON c.PreviousFeatureID = pf.FeatureID
LEFT JOIN CAD_Model m       ON c.CurrentModelID    = m.ModelID;

-- View: constraints grouped by type
CREATE VIEW IF NOT EXISTS v_CAD_Constraint_ByType AS
SELECT
    c.Type,
    CASE c.Type
        WHEN 0  THEN 'Horizontal'    WHEN 1  THEN 'Vertical'
        WHEN 2  THEN 'Distance'      WHEN 3  THEN 'Coincident'
        WHEN 4  THEN 'Tangent'       WHEN 5  THEN 'Angle'
        WHEN 6  THEN 'Equal'         WHEN 7  THEN 'Parallel'
        WHEN 8  THEN 'Perpendicular' WHEN 9  THEN 'Fixed'
        WHEN 10 THEN 'Midpoint'      WHEN 11 THEN 'Midplane'
        WHEN 12 THEN 'Concentric'    WHEN 13 THEN 'Collinear'
        WHEN 14 THEN 'Symmetry'      WHEN 15 THEN 'Curvature'
        WHEN 16 THEN 'Other'
    END AS ConstraintTypeName,
    COUNT(*) AS ConstraintCount
FROM CAD_Constraint c
GROUP BY c.Type
ORDER BY c.Type;
