-- ============================================================
-- SQLite Schema for CAD_Component JSON mapping
-- Generated from CAD_Library: CAD_Component (extends CAD_Part)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, CAD_Part, CAD_Sketch,
--   CAD_Joint, Parameter
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

CREATE TABLE IF NOT EXISTS Vector (
    VectorID        TEXT PRIMARY KEY,
    Name            TEXT,
    IsKnotVector    INTEGER NOT NULL DEFAULT 0,
    VectorType      INTEGER NOT NULL DEFAULT 0,
    X_Value         REAL NOT NULL DEFAULT 0.0,
    Y_Value         REAL NOT NULL DEFAULT 0.0,
    Z_Value         REAL NOT NULL DEFAULT 0.0,
    Cyl_R           REAL NOT NULL DEFAULT 0.0,
    Cyl_Theta       REAL NOT NULL DEFAULT 0.0,
    L               REAL NOT NULL DEFAULT 0.0,
    Sph_R           REAL NOT NULL DEFAULT 0.0,
    Sph_Theta       REAL NOT NULL DEFAULT 0.0,
    Phi             REAL NOT NULL DEFAULT 0.0,
    StartPointID    TEXT,
    EndPointID      TEXT,
    WorldCoordinateSystemID     TEXT,
    CurrentCoordinateSystemID   TEXT,
    FOREIGN KEY (StartPointID)  REFERENCES Point(PointID),
    FOREIGN KEY (EndPointID)    REFERENCES Point(PointID)
);

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

CREATE TABLE IF NOT EXISTS CAD_Sketch (
    SketchID    TEXT PRIMARY KEY,
    Version     TEXT,
    IsTwoD      INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Joint (
    JointID     TEXT PRIMARY KEY,
    Name        TEXT,
    JointType   INTEGER NOT NULL DEFAULT 0,
    ModelType   INTEGER NOT NULL DEFAULT 0
);

-- Refactored Parameter (distinct from CAD_Parameter)
CREATE TABLE IF NOT EXISTS MathParameter (
    ParameterID TEXT PRIMARY KEY,
    Name        TEXT,
    Description TEXT,
    ParameterType INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- CAD_Component  (main table — extends CAD_Part; own properties only)
-- ============================================================
-- NOTE: CAD_Part already has its own schema (CAD_Part_Schema.sql).
-- This table stores Component-specific properties only.
-- Inherited Part data lives in the CAD_Part table; join on MyPartID
-- or use the flattened view below.
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Component (
    ComponentID     TEXT PRIMARY KEY,          -- synthetic key

    -- Identification (own, shadows base)
    Name            TEXT,
    Version         TEXT,
    Path            TEXT,

    -- Data
    WeightParameterID   TEXT,                  -- Parameter for weight value

    -- Flags
    IsAssembly              INTEGER NOT NULL DEFAULT 0,
    IsConfigurationItem     INTEGER NOT NULL DEFAULT 0,

    -- Component hierarchy
    WBS_Level       INTEGER NOT NULL DEFAULT 0,

    -- Association to underlying Part
    MyPartID        TEXT,

    FOREIGN KEY (WeightParameterID) REFERENCES MathParameter(ParameterID),
    FOREIGN KEY (MyPartID)          REFERENCES CAD_Part(PartID)
);

-- ============================================================
-- CAD_Component collection junction tables
-- ============================================================

-- MomentsOfInertia (List<Parameter>)
CREATE TABLE IF NOT EXISTS CAD_Component_MomentOfInertia (
    ComponentID     TEXT NOT NULL,
    ParameterID     TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ComponentID, ParameterID),
    FOREIGN KEY (ComponentID)  REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (ParameterID)  REFERENCES MathParameter(ParameterID)
);

-- PrincipleDirections (List<Vector>)
CREATE TABLE IF NOT EXISTS CAD_Component_PrincipleDirection (
    ComponentID     TEXT NOT NULL,
    VectorID        TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ComponentID, VectorID),
    FOREIGN KEY (ComponentID)  REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (VectorID)     REFERENCES Vector(VectorID)
);

-- MySketches (List<CAD_Sketch>)
CREATE TABLE IF NOT EXISTS CAD_Component_Sketch (
    ComponentID     TEXT NOT NULL,
    SketchID        TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ComponentID, SketchID),
    FOREIGN KEY (ComponentID)  REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (SketchID)     REFERENCES CAD_Sketch(SketchID)
);

-- MyJoints (List<CAD_Joint>)
CREATE TABLE IF NOT EXISTS CAD_Component_Joint (
    ComponentID     TEXT NOT NULL,
    JointID         TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ComponentID, JointID),
    FOREIGN KEY (ComponentID)  REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (JointID)      REFERENCES CAD_Joint(JointID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_component_name       ON CAD_Component(Name);
CREATE INDEX IF NOT EXISTS idx_component_version    ON CAD_Component(Version);
CREATE INDEX IF NOT EXISTS idx_component_assembly   ON CAD_Component(IsAssembly);
CREATE INDEX IF NOT EXISTS idx_component_config     ON CAD_Component(IsConfigurationItem);
CREATE INDEX IF NOT EXISTS idx_component_wbs        ON CAD_Component(WBS_Level);
CREATE INDEX IF NOT EXISTS idx_component_part       ON CAD_Component(MyPartID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: component with part info and collection counts
CREATE VIEW IF NOT EXISTS v_CAD_Component_Detail AS
SELECT
    c.ComponentID,
    c.Name,
    c.Version,
    c.Path,
    c.IsAssembly,
    c.IsConfigurationItem,
    c.WBS_Level,

    -- Weight parameter
    w.Name      AS WeightParamName,

    -- Underlying Part
    p.Name      AS PartName,
    p.PartNumber AS PartNumber,

    -- Collection counts
    (SELECT COUNT(*) FROM CAD_Component_MomentOfInertia cmi
     WHERE cmi.ComponentID = c.ComponentID) AS MomentOfInertiaCount,
    (SELECT COUNT(*) FROM CAD_Component_PrincipleDirection cpd
     WHERE cpd.ComponentID = c.ComponentID) AS PrincipleDirectionCount,
    (SELECT COUNT(*) FROM CAD_Component_Sketch css
     WHERE css.ComponentID = c.ComponentID) AS SketchCount,
    (SELECT COUNT(*) FROM CAD_Component_Joint cjj
     WHERE cjj.ComponentID = c.ComponentID) AS JointCount

FROM CAD_Component c
LEFT JOIN MathParameter w   ON c.WeightParameterID = w.ParameterID
LEFT JOIN CAD_Part p        ON c.MyPartID          = p.PartID;

-- View: components with their joints
CREATE VIEW IF NOT EXISTS v_CAD_Component_Joints AS
SELECT
    c.ComponentID,
    c.Name              AS ComponentName,
    cj.SortOrder,
    j.JointID,
    j.Name              AS JointName,
    j.JointType
FROM CAD_Component c
JOIN CAD_Component_Joint cj ON c.ComponentID = cj.ComponentID
JOIN CAD_Joint j            ON cj.JointID    = j.JointID
ORDER BY c.ComponentID, cj.SortOrder;
