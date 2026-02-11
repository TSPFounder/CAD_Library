-- ============================================================
-- SQLite Schema for CAD_Interface JSON mapping
-- Generated from CAD_Library: CAD_Interface
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, CAD_Surface, CAD_Joint, CAD_Component
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

CREATE TABLE IF NOT EXISTS CAD_Surface (
    SurfaceID   TEXT PRIMARY KEY,
    Name        TEXT,
    SurfaceType INTEGER NOT NULL DEFAULT 0,
    Description TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Joint (
    JointID     TEXT PRIMARY KEY,
    Name        TEXT,
    JointType   INTEGER NOT NULL DEFAULT 0,
    ModelType   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Component (
    ComponentID TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    IsAssembly  INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- CAD_Interface  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Interface (
    InterfaceID     TEXT PRIMARY KEY,          -- maps to ID property

    -- Identification
    Name            TEXT,
    Version         TEXT,

    -- Classification
    InterfaceKind   INTEGER,
    -- InterfaceType (nullable):
    --   0=Joint, 1=ElectricalConnector, 2=Other

    -- Contact geometry cursors
    CurrentContactPointID       TEXT,
    CurrentContactSurfaceID     TEXT,

    -- Associations
    MyJointID           TEXT,
    BaseComponentID     TEXT,
    MatingComponentID   TEXT,

    FOREIGN KEY (CurrentContactPointID)   REFERENCES Point(PointID),
    FOREIGN KEY (CurrentContactSurfaceID) REFERENCES CAD_Surface(SurfaceID),
    FOREIGN KEY (MyJointID)               REFERENCES CAD_Joint(JointID),
    FOREIGN KEY (BaseComponentID)         REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (MatingComponentID)       REFERENCES CAD_Component(ComponentID)
);

-- ============================================================
-- CAD_Interface collection junction tables
-- ============================================================

-- MyContactPoints (List<Point>)
CREATE TABLE IF NOT EXISTS CAD_Interface_ContactPoint (
    InterfaceID TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (InterfaceID, PointID),
    FOREIGN KEY (InterfaceID) REFERENCES CAD_Interface(InterfaceID),
    FOREIGN KEY (PointID)     REFERENCES Point(PointID)
);

-- MyContactSurfaces (List<CAD_Surface>)
CREATE TABLE IF NOT EXISTS CAD_Interface_ContactSurface (
    InterfaceID TEXT NOT NULL,
    SurfaceID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (InterfaceID, SurfaceID),
    FOREIGN KEY (InterfaceID) REFERENCES CAD_Interface(InterfaceID),
    FOREIGN KEY (SurfaceID)   REFERENCES CAD_Surface(SurfaceID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_interface_name       ON CAD_Interface(Name);
CREATE INDEX IF NOT EXISTS idx_interface_version    ON CAD_Interface(Version);
CREATE INDEX IF NOT EXISTS idx_interface_kind       ON CAD_Interface(InterfaceKind);
CREATE INDEX IF NOT EXISTS idx_interface_joint      ON CAD_Interface(MyJointID);
CREATE INDEX IF NOT EXISTS idx_interface_base_comp  ON CAD_Interface(BaseComponentID);
CREATE INDEX IF NOT EXISTS idx_interface_mate_comp  ON CAD_Interface(MatingComponentID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: interface with type label and component info
CREATE VIEW IF NOT EXISTS v_CAD_Interface_Detail AS
SELECT
    i.InterfaceID,
    i.Name,
    i.Version,
    i.InterfaceKind,
    CASE i.InterfaceKind
        WHEN 0 THEN 'Joint'
        WHEN 1 THEN 'ElectricalConnector'
        WHEN 2 THEN 'Other'
        ELSE '(unspecified)'
    END AS InterfaceKindName,

    -- Joint
    j.Name      AS JointName,
    j.JointType AS JointType,

    -- Base component
    bc.Name     AS BaseComponentName,

    -- Mating component
    mc.Name     AS MatingComponentName,

    -- Contact point
    cp.X_Value  AS ContactPoint_X,
    cp.Y_Value  AS ContactPoint_Y,
    cp.Z_Value_Cartesian AS ContactPoint_Z,

    -- Collection counts
    (SELECT COUNT(*) FROM CAD_Interface_ContactPoint icp
     WHERE icp.InterfaceID = i.InterfaceID) AS ContactPointCount,
    (SELECT COUNT(*) FROM CAD_Interface_ContactSurface ics
     WHERE ics.InterfaceID = i.InterfaceID) AS ContactSurfaceCount

FROM CAD_Interface i
LEFT JOIN Point cp              ON i.CurrentContactPointID = cp.PointID
LEFT JOIN CAD_Joint j           ON i.MyJointID             = j.JointID
LEFT JOIN CAD_Component bc      ON i.BaseComponentID       = bc.ComponentID
LEFT JOIN CAD_Component mc      ON i.MatingComponentID     = mc.ComponentID;
