-- ============================================================
-- SQLite Schema for MassProperties JSON mapping
-- Generated from CAD_Library: MassProperties
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, CAD_Part
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

CREATE TABLE IF NOT EXISTS CoordinateSystem (
    CoordinateSystemID  TEXT PRIMARY KEY,
    Name                TEXT,
    MyType              INTEGER NOT NULL DEFAULT 0,
    IsWCS               INTEGER NOT NULL DEFAULT 0,
    Is2D                INTEGER NOT NULL DEFAULT 0,
    OriginLocationPointID   TEXT,
    BaseVectorID            TEXT,
    FOREIGN KEY (OriginLocationPointID) REFERENCES Point(PointID),
    FOREIGN KEY (BaseVectorID)          REFERENCES Vector(VectorID)
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

-- ============================================================
-- MassProperties  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS MassProperties (
    MassPropertiesID    TEXT PRIMARY KEY,      -- synthetic key

    -- Ownership
    MyCAD_PartID        TEXT,

    -- Scalar data
    Mass                REAL NOT NULL DEFAULT 0.0,

    -- Coordinate system cursor
    CurrentCoordinateSystemID   TEXT,

    -- Center of gravity
    CenterOfGravityPointID      TEXT,

    -- Inertia tensors (3x3 matrices — stored as JSON TEXT)
    PrincipalMomentsOfInertiaJSON   TEXT,      -- JSON 3x3 matrix
    CurrentMomentsOfInertiaJSON     TEXT,      -- JSON 3x3 matrix

    FOREIGN KEY (MyCAD_PartID)              REFERENCES CAD_Part(PartID),
    FOREIGN KEY (CurrentCoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CenterOfGravityPointID)    REFERENCES Point(PointID)
);

-- ============================================================
-- MassProperties collection junction tables
-- ============================================================

-- CoordinateSystems (IReadOnlyList<CoordinateSystem>)
CREATE TABLE IF NOT EXISTS MassProperties_CoordinateSystem (
    MassPropertiesID    TEXT NOT NULL,
    CoordinateSystemID  TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (MassPropertiesID, CoordinateSystemID),
    FOREIGN KEY (MassPropertiesID)  REFERENCES MassProperties(MassPropertiesID),
    FOREIGN KEY (CoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- MyMomentsOfInertia (IReadOnlyList<Matrix> — historical snapshots)
-- Matrices stored as JSON TEXT blobs
CREATE TABLE IF NOT EXISTS MassProperties_InertiaHistory (
    MassPropertiesID    TEXT NOT NULL,
    SnapshotOrder       INTEGER NOT NULL DEFAULT 0,
    MatrixJSON          TEXT NOT NULL,         -- JSON 3x3 matrix
    PRIMARY KEY (MassPropertiesID, SnapshotOrder),
    FOREIGN KEY (MassPropertiesID) REFERENCES MassProperties(MassPropertiesID)
);

-- PrincipalDirections (IReadOnlyList<Vector> — exactly 3: X, Y, Z)
CREATE TABLE IF NOT EXISTS MassProperties_PrincipalDirection (
    MassPropertiesID    TEXT NOT NULL,
    VectorID            TEXT NOT NULL,
    AxisIndex           INTEGER NOT NULL,      -- 0=X, 1=Y, 2=Z
    PRIMARY KEY (MassPropertiesID, AxisIndex),
    FOREIGN KEY (MassPropertiesID) REFERENCES MassProperties(MassPropertiesID),
    FOREIGN KEY (VectorID)         REFERENCES Vector(VectorID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_massprops_part    ON MassProperties(MyCAD_PartID);
CREATE INDEX IF NOT EXISTS idx_massprops_csys    ON MassProperties(CurrentCoordinateSystemID);
CREATE INDEX IF NOT EXISTS idx_massprops_cog     ON MassProperties(CenterOfGravityPointID);
CREATE INDEX IF NOT EXISTS idx_massprops_mass    ON MassProperties(Mass);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: mass properties with CoG coordinates and principal directions
CREATE VIEW IF NOT EXISTS v_MassProperties_Detail AS
SELECT
    mp.MassPropertiesID,
    mp.Mass,

    -- Part
    p.Name          AS PartName,
    p.PartNumber    AS PartNumber,

    -- Coordinate system
    cs.Name         AS CoordinateSystemName,
    cs.MyType       AS CSysType,
    CASE cs.MyType
        WHEN 0 THEN 'Cartesian'
        WHEN 1 THEN 'Cylindrical'
        WHEN 2 THEN 'Spherical'
        WHEN 3 THEN 'Polar'
    END AS CSysTypeName,

    -- Center of gravity
    cog.X_Value     AS CoG_X,
    cog.Y_Value     AS CoG_Y,
    cog.Z_Value_Cartesian AS CoG_Z,

    -- Principal direction X
    pdx.X_Value     AS PrinDir_X_VecX,
    pdx.Y_Value     AS PrinDir_X_VecY,
    pdx.Z_Value     AS PrinDir_X_VecZ,

    -- Principal direction Y
    pdy.X_Value     AS PrinDir_Y_VecX,
    pdy.Y_Value     AS PrinDir_Y_VecY,
    pdy.Z_Value     AS PrinDir_Y_VecZ,

    -- Principal direction Z
    pdz.X_Value     AS PrinDir_Z_VecX,
    pdz.Y_Value     AS PrinDir_Z_VecY,
    pdz.Z_Value     AS PrinDir_Z_VecZ,

    -- Inertia tensors (raw JSON)
    mp.PrincipalMomentsOfInertiaJSON,
    mp.CurrentMomentsOfInertiaJSON,

    -- Counts
    (SELECT COUNT(*) FROM MassProperties_CoordinateSystem mcs
     WHERE mcs.MassPropertiesID = mp.MassPropertiesID) AS CoordinateSystemCount,
    (SELECT COUNT(*) FROM MassProperties_InertiaHistory mih
     WHERE mih.MassPropertiesID = mp.MassPropertiesID) AS InertiaSnapshotCount

FROM MassProperties mp
LEFT JOIN CAD_Part p            ON mp.MyCAD_PartID              = p.PartID
LEFT JOIN CoordinateSystem cs   ON mp.CurrentCoordinateSystemID = cs.CoordinateSystemID
LEFT JOIN Point cog             ON mp.CenterOfGravityPointID    = cog.PointID
LEFT JOIN MassProperties_PrincipalDirection pdx_j
    ON mp.MassPropertiesID = pdx_j.MassPropertiesID AND pdx_j.AxisIndex = 0
LEFT JOIN Vector pdx ON pdx_j.VectorID = pdx.VectorID
LEFT JOIN MassProperties_PrincipalDirection pdy_j
    ON mp.MassPropertiesID = pdy_j.MassPropertiesID AND pdy_j.AxisIndex = 1
LEFT JOIN Vector pdy ON pdy_j.VectorID = pdy.VectorID
LEFT JOIN MassProperties_PrincipalDirection pdz_j
    ON mp.MassPropertiesID = pdz_j.MassPropertiesID AND pdz_j.AxisIndex = 2
LEFT JOIN Vector pdz ON pdz_j.VectorID = pdz.VectorID;
