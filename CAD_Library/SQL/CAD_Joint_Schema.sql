-- ============================================================
-- SQLite Schema for CAD_Joint JSON mapping
-- Generated from CAD_Library: CAD_Joint (extends CAD_Interface)
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- Mathematics Types
-- ============================================================

CREATE TABLE IF NOT EXISTS Point (
    PointID         TEXT PRIMARY KEY,
    IsWeightPoint   INTEGER NOT NULL DEFAULT 0,    -- bool
    MyType          INTEGER NOT NULL DEFAULT 0,    -- PointTypeEnum: 0=Cartesian, 1=Cylindrical, 2=Spherical, 3=Complex
    Is2D            INTEGER NOT NULL DEFAULT 0,    -- bool

    -- Cartesian
    X_Value                 REAL NOT NULL DEFAULT 0.0,
    Y_Value                 REAL NOT NULL DEFAULT 0.0,
    Z_Value_Cartesian       REAL NOT NULL DEFAULT 0.0,

    -- Cylindrical
    R_Value_Cylindrical     REAL NOT NULL DEFAULT 0.0,
    Theta_Value_Cylindrical REAL NOT NULL DEFAULT 0.0,
    Z_Value_Cylindrical     REAL NOT NULL DEFAULT 0.0,

    -- Spherical
    R_Value_Spherical       REAL NOT NULL DEFAULT 0.0,
    Theta_Value_Spherical   REAL NOT NULL DEFAULT 0.0,
    Phi_Value               REAL NOT NULL DEFAULT 0.0,

    -- GPS
    Longitude   REAL NOT NULL DEFAULT 0.0,
    Latitude    REAL NOT NULL DEFAULT 0.0,
    Altitude    REAL NOT NULL DEFAULT 0.0,

    -- Complex
    Real_Value      REAL NOT NULL DEFAULT 0.0,
    Complex_Value   REAL NOT NULL DEFAULT 0.0,

    -- References
    CurrentCoordinateSystemID   TEXT,
    CurrentConnectedPointID     TEXT,

    FOREIGN KEY (CurrentConnectedPointID) REFERENCES Point(PointID)
);

CREATE TABLE IF NOT EXISTS Vector (
    VectorID    TEXT PRIMARY KEY,
    Name        TEXT,
    IsKnotVector    INTEGER NOT NULL DEFAULT 0,    -- bool
    VectorType      INTEGER NOT NULL DEFAULT 0,    -- VectorTypeEnum: 0=Cartesian, 1=Cylindrical, 2=Spherical, 3=Polar

    -- Cartesian
    X_Value     REAL NOT NULL DEFAULT 0.0,
    Y_Value     REAL NOT NULL DEFAULT 0.0,
    Z_Value     REAL NOT NULL DEFAULT 0.0,

    -- Cylindrical
    Cyl_R       REAL NOT NULL DEFAULT 0.0,
    Cyl_Theta   REAL NOT NULL DEFAULT 0.0,
    L           REAL NOT NULL DEFAULT 0.0,

    -- Spherical
    Sph_R       REAL NOT NULL DEFAULT 0.0,
    Sph_Theta   REAL NOT NULL DEFAULT 0.0,
    Phi         REAL NOT NULL DEFAULT 0.0,

    -- Endpoint references
    StartPointID    TEXT,
    EndPointID      TEXT,

    -- Coordinate system references
    WorldCoordinateSystemID     TEXT,
    CurrentCoordinateSystemID   TEXT,

    FOREIGN KEY (StartPointID)  REFERENCES Point(PointID),
    FOREIGN KEY (EndPointID)    REFERENCES Point(PointID)
);

CREATE TABLE IF NOT EXISTS CoordinateSystem (
    CoordinateSystemID  TEXT PRIMARY KEY,
    Name                TEXT,
    MyType              INTEGER NOT NULL DEFAULT 0,    -- CoordinateSystemTypeEnum: 0=Cartesian, 1=Cylindrical, 2=Spherical, 3=Polar
    IsWCS               INTEGER NOT NULL DEFAULT 0,    -- bool
    Is2D                INTEGER NOT NULL DEFAULT 0,    -- bool

    OriginLocationPointID   TEXT,
    BaseVectorID            TEXT,

    FOREIGN KEY (OriginLocationPointID) REFERENCES Point(PointID),
    FOREIGN KEY (BaseVectorID)          REFERENCES Vector(VectorID)
);

-- Back-references now that CoordinateSystem exists
-- (SQLite doesn't support ALTER TABLE ADD CONSTRAINT, so these are documented logically)
-- Point.CurrentCoordinateSystemID  -> CoordinateSystem.CoordinateSystemID
-- Vector.WorldCoordinateSystemID   -> CoordinateSystem.CoordinateSystemID
-- Vector.CurrentCoordinateSystemID -> CoordinateSystem.CoordinateSystemID

-- Junction: CoordinateSystem <-> Vectors
CREATE TABLE IF NOT EXISTS CoordinateSystem_Vector (
    CoordinateSystemID  TEXT NOT NULL,
    VectorID            TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (CoordinateSystemID, VectorID),
    FOREIGN KEY (CoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (VectorID)           REFERENCES Vector(VectorID)
);

-- Junction: Point <-> connected Points
CREATE TABLE IF NOT EXISTS Point_ConnectedPoint (
    PointID             TEXT NOT NULL,
    ConnectedPointID    TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PointID, ConnectedPointID),
    FOREIGN KEY (PointID)           REFERENCES Point(PointID),
    FOREIGN KEY (ConnectedPointID)  REFERENCES Point(PointID)
);

-- Junction: Point <-> CoordinateSystems
CREATE TABLE IF NOT EXISTS Point_CoordinateSystem (
    PointID             TEXT NOT NULL,
    CoordinateSystemID  TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (PointID, CoordinateSystemID),
    FOREIGN KEY (PointID)           REFERENCES Point(PointID),
    FOREIGN KEY (CoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- ============================================================
-- CAD Types
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Surface (
    ID          TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    Description TEXT,
    SurfaceType INTEGER NOT NULL DEFAULT 0,    -- SurfaceTypeEnum: 0=Plane,1=Circle,2=Ellipse,...,15=Other
    Length      REAL,
    Area        REAL,
    Perimeter   REAL,
    MyBodyID    TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Component (
    ComponentID             TEXT PRIMARY KEY,  -- synthetic key (Name + Version or generated)
    Name                    TEXT,
    Version                 TEXT,
    Path                    TEXT,
    IsAssembly              INTEGER NOT NULL DEFAULT 0,    -- bool
    IsConfigurationItem     INTEGER NOT NULL DEFAULT 0,    -- bool
    WBS_Level               INTEGER NOT NULL DEFAULT 0
);

-- Junction: CAD_Component <-> PrincipleDirections (Vector)
CREATE TABLE IF NOT EXISTS CAD_Component_PrincipleDirection (
    ComponentID TEXT NOT NULL,
    VectorID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ComponentID, VectorID),
    FOREIGN KEY (ComponentID) REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (VectorID)    REFERENCES Vector(VectorID)
);

-- ============================================================
-- CAD_Joint  (main table — combines CAD_Interface + CAD_Joint)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Joint (
    -- Primary key (use the class ID property, or generate one)
    ID      TEXT PRIMARY KEY,

    -- Identification (CAD_Joint / CAD_Interface)
    Name    TEXT,
    Version TEXT,

    -- CAD_Joint-specific data
    JointType           INTEGER NOT NULL DEFAULT 0,    -- JointTypeEnum: 0=Rigid,1=Revolute,2=Slider,3=Cylindrical,4=PinSlot,5=Planar,6=InPlane,7=Ball,8=LeadScrew,9=Other
    ModelType            INTEGER NOT NULL DEFAULT 1,    -- CAD_ModelTypeEnum: 0=SolidWorks,1=Fusion360,2=MechanicalDesktop,3=Simscape,4=STEP,5=STL,6=FBX
    DegreesOfFreedom    INTEGER NOT NULL DEFAULT 0,    -- computed from JointType, stored for query convenience

    -- Locating coordinate system
    MyCoordinateSystemID TEXT,

    -- CAD_Interface fields
    InterfaceKind               INTEGER,       -- InterfaceType enum: 0=Joint,1=ElectricalConnector,2=Other (nullable)
    CurrentContactPointID       TEXT,
    CurrentContactSurfaceID     TEXT,

    -- Interface associations
    MyJointID           TEXT,      -- self-referential (CAD_Interface.MyJoint)
    BaseComponentID     TEXT,
    MatingComponentID   TEXT,

    FOREIGN KEY (MyCoordinateSystemID)      REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CurrentContactPointID)     REFERENCES Point(PointID),
    FOREIGN KEY (CurrentContactSurfaceID)   REFERENCES CAD_Surface(ID),
    FOREIGN KEY (MyJointID)                 REFERENCES CAD_Joint(ID),
    FOREIGN KEY (BaseComponentID)           REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (MatingComponentID)         REFERENCES CAD_Component(ComponentID)
);

-- ============================================================
-- Junction Tables for CAD_Joint collections
-- ============================================================

-- CAD_Joint.IncludedComponents (List<CAD_Component>)
CREATE TABLE IF NOT EXISTS CAD_Joint_IncludedComponent (
    JointID     TEXT NOT NULL,
    ComponentID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (JointID, ComponentID),
    FOREIGN KEY (JointID)     REFERENCES CAD_Joint(ID),
    FOREIGN KEY (ComponentID) REFERENCES CAD_Component(ComponentID)
);

-- CAD_Interface.MyContactPoints (List<Point>)
CREATE TABLE IF NOT EXISTS CAD_Joint_ContactPoint (
    JointID     TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (JointID, PointID),
    FOREIGN KEY (JointID) REFERENCES CAD_Joint(ID),
    FOREIGN KEY (PointID) REFERENCES Point(PointID)
);

-- CAD_Interface.MyContactSurfaces (List<CAD_Surface>)
CREATE TABLE IF NOT EXISTS CAD_Joint_ContactSurface (
    JointID     TEXT NOT NULL,
    SurfaceID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (JointID, SurfaceID),
    FOREIGN KEY (JointID)   REFERENCES CAD_Joint(ID),
    FOREIGN KEY (SurfaceID) REFERENCES CAD_Surface(ID)
);

-- ============================================================
-- Indexes for common query patterns
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_joint_name          ON CAD_Joint(Name);
CREATE INDEX IF NOT EXISTS idx_joint_type          ON CAD_Joint(JointType);
CREATE INDEX IF NOT EXISTS idx_joint_model_type    ON CAD_Joint(ModelType);
CREATE INDEX IF NOT EXISTS idx_joint_csys          ON CAD_Joint(MyCoordinateSystemID);
CREATE INDEX IF NOT EXISTS idx_joint_base_comp     ON CAD_Joint(BaseComponentID);
CREATE INDEX IF NOT EXISTS idx_joint_mating_comp   ON CAD_Joint(MatingComponentID);
CREATE INDEX IF NOT EXISTS idx_component_name      ON CAD_Component(Name);
CREATE INDEX IF NOT EXISTS idx_surface_type        ON CAD_Surface(SurfaceType);

-- ============================================================
-- Views for convenient JSON-round-trip queries
-- ============================================================

-- Flat view joining a joint with its coordinate system origin
CREATE VIEW IF NOT EXISTS v_CAD_Joint_Detail AS
SELECT
    j.ID,
    j.Name,
    j.Version,
    j.JointType,
    CASE j.JointType
        WHEN 0 THEN 'Rigid'
        WHEN 1 THEN 'Revolute'
        WHEN 2 THEN 'Slider'
        WHEN 3 THEN 'Cylindrical'
        WHEN 4 THEN 'PinSlot'
        WHEN 5 THEN 'Planar'
        WHEN 6 THEN 'InPlane'
        WHEN 7 THEN 'Ball'
        WHEN 8 THEN 'LeadScrew'
        WHEN 9 THEN 'Other'
    END AS JointTypeName,
    j.ModelType,
    CASE j.ModelType
        WHEN 0 THEN 'SolidWorks'
        WHEN 1 THEN 'Fusion360'
        WHEN 2 THEN 'MechanicalDesktop'
        WHEN 3 THEN 'Simscape'
        WHEN 4 THEN 'STEP'
        WHEN 5 THEN 'STL'
        WHEN 6 THEN 'FBX'
    END AS ModelTypeName,
    j.DegreesOfFreedom,
    j.InterfaceKind,
    cs.CoordinateSystemID   AS CSys_ID,
    cs.Name                 AS CSys_Name,
    p.X_Value               AS CSys_Origin_X,
    p.Y_Value               AS CSys_Origin_Y,
    p.Z_Value_Cartesian     AS CSys_Origin_Z,
    bc.Name                 AS BaseComponentName,
    mc.Name                 AS MatingComponentName
FROM CAD_Joint j
LEFT JOIN CoordinateSystem cs  ON j.MyCoordinateSystemID    = cs.CoordinateSystemID
LEFT JOIN Point p              ON cs.OriginLocationPointID  = p.PointID
LEFT JOIN CAD_Component bc     ON j.BaseComponentID         = bc.ComponentID
LEFT JOIN CAD_Component mc     ON j.MatingComponentID       = mc.ComponentID;
