-- ============================================================
-- SQLite Schema for CAD_Assembly JSON mapping
-- Generated from CAD_Library: CAD_Assembly
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, CAD_Model, CAD_Part,
--   CAD_Component, CAD_Configuration, CAD_Interface, CAD_Station,
--   CAD_SketchPlane, CAD_Sketch, CAD_Feature, CAD_Drawing,
--   CAD_Body, MassProperties, CAD_Library
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- Shared types (IF NOT EXISTS — safe when running all schemas together)
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

CREATE TABLE IF NOT EXISTS CAD_Component (
    ComponentID             TEXT PRIMARY KEY,
    Name                    TEXT,
    Version                 TEXT,
    Path                    TEXT,
    IsAssembly              INTEGER NOT NULL DEFAULT 0,
    IsConfigurationItem     INTEGER NOT NULL DEFAULT 0,
    WBS_Level               INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Configuration (
    ConfigurationID TEXT PRIMARY KEY,
    Name            TEXT,
    Description     TEXT,
    ID              TEXT,
    Revision        TEXT,
    CurrentPartID       TEXT,
    CurrentPartRowID    TEXT,
    MyAssemblyID        TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Interface (
    InterfaceID     TEXT PRIMARY KEY,          -- synthetic key
    Name            TEXT,
    ID              TEXT,
    Version         TEXT,
    InterfaceKind   INTEGER,                   -- InterfaceType: 0=Joint,1=ElectricalConnector,2=Other

    -- Contact geometry
    CurrentContactPointID       TEXT,
    CurrentContactSurfaceID     TEXT,

    -- Associations
    MyJointID           TEXT,
    BaseComponentID     TEXT,
    MatingComponentID   TEXT,

    FOREIGN KEY (CurrentContactPointID) REFERENCES Point(PointID),
    FOREIGN KEY (BaseComponentID)       REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (MatingComponentID)     REFERENCES CAD_Component(ComponentID)
);

-- CAD_Interface -> MyContactPoints
CREATE TABLE IF NOT EXISTS CAD_Interface_ContactPoint (
    InterfaceID TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (InterfaceID, PointID),
    FOREIGN KEY (InterfaceID) REFERENCES CAD_Interface(InterfaceID),
    FOREIGN KEY (PointID)     REFERENCES Point(PointID)
);

-- CAD_Interface -> MyContactSurfaces
CREATE TABLE IF NOT EXISTS CAD_Interface_ContactSurface (
    InterfaceID TEXT NOT NULL,
    SurfaceID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (InterfaceID, SurfaceID),
    FOREIGN KEY (InterfaceID) REFERENCES CAD_Interface(InterfaceID)
);

CREATE TABLE IF NOT EXISTS CAD_Station (
    StationID       TEXT PRIMARY KEY,
    Name            TEXT,
    ID              TEXT,
    Version         TEXT,
    MyType          INTEGER NOT NULL DEFAULT 0,
    AxialLocation   REAL NOT NULL DEFAULT 0.0,
    RadialLocation  REAL NOT NULL DEFAULT 0.0,
    AngularLocation REAL NOT NULL DEFAULT 0.0,
    WingLocation    REAL NOT NULL DEFAULT 0.0,
    FloorLocation   REAL NOT NULL DEFAULT 0.0,
    MyModelID           TEXT,
    CurrentSketchPlaneID TEXT
);

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

CREATE TABLE IF NOT EXISTS CAD_Part (
    PartID      TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    PartNumber  TEXT,
    Description TEXT,
    CurrentMassPropertiesID TEXT,
    MyMassPropertiesID      TEXT,
    CenterOfMassPointID     TEXT,
    CurrentModelID              TEXT,
    CurrentCoordinateSystemID   TEXT,
    CurrentSketchID             TEXT,
    CurrentFeatureID            TEXT,
    CurrentBodyID               TEXT,
    CurrentDrawingID            TEXT,
    CurrentDimensionID          TEXT,
    CurrentParameterID          TEXT,
    CurrentLibraryID            TEXT,
    CurrentInterfaceID          TEXT,
    MyAssemblyID                TEXT
);

-- ============================================================
-- Requirement types (referenced by CAD_Assembly)
-- ============================================================

CREATE TABLE IF NOT EXISTS MissionRequirement (
    MissionRequirementID    TEXT PRIMARY KEY,   -- synthetic key
    -- Inherits from SRS_Requirement (base properties)
    Name                    TEXT,
    Description             TEXT,
    RequirementType         INTEGER,           -- RequirementTypeEnum: 0=Functional,1=Constraint,2=Environment,3=Interface,4=Performance,5=Physical,6=Cost
    -- External document bindings stored as path/reference strings
    WorkbookPath            TEXT,
    RequirementsDocPath     TEXT
);

CREATE TABLE IF NOT EXISTS SystemRequirement (
    SystemRequirementID     TEXT PRIMARY KEY,   -- synthetic key
    -- Inherits from SRS_Requirement
    Name                    TEXT,
    Description             TEXT,
    WorkbookPath            TEXT,
    RequirementsDocPath     TEXT
);

-- ============================================================
-- CAD_Assembly  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Assembly (
    AssemblyID  TEXT PRIMARY KEY,               -- synthetic key

    -- Identification
    Name            TEXT,
    Version         TEXT,
    Description     TEXT,

    -- Flags
    IsSubAssembly       INTEGER NOT NULL DEFAULT 0,    -- bool
    IsConfigurationItem INTEGER NOT NULL DEFAULT 0,    -- bool

    -- Pose (position & orientation)
    MyPositionPointID   TEXT,
    MyOrientationVectorID TEXT,

    -- Coordinate systems
    CurrentCSID     TEXT,

    -- Component cursors
    CurrentComponentID      TEXT,
    PreviousComponentID     TEXT,
    NextComponentID         TEXT,

    -- Model
    MyModelID   TEXT,

    -- Configuration cursor
    CurrentConfigurationID  TEXT,

    -- Part
    MyPartID    TEXT,

    -- Interface cursor
    CurrentInterfaceID  TEXT,

    FOREIGN KEY (MyPositionPointID)     REFERENCES Point(PointID),
    FOREIGN KEY (MyOrientationVectorID) REFERENCES Vector(VectorID),
    FOREIGN KEY (CurrentCSID)           REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CurrentComponentID)    REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (PreviousComponentID)   REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (NextComponentID)       REFERENCES CAD_Component(ComponentID),
    FOREIGN KEY (MyModelID)             REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (CurrentConfigurationID) REFERENCES CAD_Configuration(ConfigurationID),
    FOREIGN KEY (MyPartID)              REFERENCES CAD_Part(PartID),
    FOREIGN KEY (CurrentInterfaceID)    REFERENCES CAD_Interface(InterfaceID)
);

-- ============================================================
-- CAD_Assembly collection junction tables
-- ============================================================

-- MyCoordinateSystems
CREATE TABLE IF NOT EXISTS CAD_Assembly_CoordinateSystem (
    AssemblyID          TEXT NOT NULL,
    CoordinateSystemID  TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (AssemblyID, CoordinateSystemID),
    FOREIGN KEY (AssemblyID)        REFERENCES CAD_Assembly(AssemblyID),
    FOREIGN KEY (CoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- MyComponents
CREATE TABLE IF NOT EXISTS CAD_Assembly_Component (
    AssemblyID  TEXT NOT NULL,
    ComponentID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (AssemblyID, ComponentID),
    FOREIGN KEY (AssemblyID)  REFERENCES CAD_Assembly(AssemblyID),
    FOREIGN KEY (ComponentID) REFERENCES CAD_Component(ComponentID)
);

-- MyConfigurations
CREATE TABLE IF NOT EXISTS CAD_Assembly_Configuration (
    AssemblyID      TEXT NOT NULL,
    ConfigurationID TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (AssemblyID, ConfigurationID),
    FOREIGN KEY (AssemblyID)      REFERENCES CAD_Assembly(AssemblyID),
    FOREIGN KEY (ConfigurationID) REFERENCES CAD_Configuration(ConfigurationID)
);

-- MissionRequirements
CREATE TABLE IF NOT EXISTS CAD_Assembly_MissionRequirement (
    AssemblyID              TEXT NOT NULL,
    MissionRequirementID    TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (AssemblyID, MissionRequirementID),
    FOREIGN KEY (AssemblyID)            REFERENCES CAD_Assembly(AssemblyID),
    FOREIGN KEY (MissionRequirementID)  REFERENCES MissionRequirement(MissionRequirementID)
);

-- SystemRequirements
CREATE TABLE IF NOT EXISTS CAD_Assembly_SystemRequirement (
    AssemblyID              TEXT NOT NULL,
    SystemRequirementID     TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (AssemblyID, SystemRequirementID),
    FOREIGN KEY (AssemblyID)            REFERENCES CAD_Assembly(AssemblyID),
    FOREIGN KEY (SystemRequirementID)   REFERENCES SystemRequirement(SystemRequirementID)
);

-- MyInterfaces
CREATE TABLE IF NOT EXISTS CAD_Assembly_Interface (
    AssemblyID  TEXT NOT NULL,
    InterfaceID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (AssemblyID, InterfaceID),
    FOREIGN KEY (AssemblyID)  REFERENCES CAD_Assembly(AssemblyID),
    FOREIGN KEY (InterfaceID) REFERENCES CAD_Interface(InterfaceID)
);

-- Station collections (4 typed lists combined with a category discriminator)
CREATE TABLE IF NOT EXISTS CAD_Assembly_Station (
    AssemblyID      TEXT NOT NULL,
    StationID       TEXT NOT NULL,
    StationCategory TEXT NOT NULL,             -- 'Axial','Radial','Angular','Wing'
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (AssemblyID, StationID, StationCategory),
    FOREIGN KEY (AssemblyID) REFERENCES CAD_Assembly(AssemblyID),
    FOREIGN KEY (StationID)  REFERENCES CAD_Station(StationID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_assembly_name            ON CAD_Assembly(Name);
CREATE INDEX IF NOT EXISTS idx_assembly_model           ON CAD_Assembly(MyModelID);
CREATE INDEX IF NOT EXISTS idx_assembly_part            ON CAD_Assembly(MyPartID);
CREATE INDEX IF NOT EXISTS idx_assembly_config          ON CAD_Assembly(CurrentConfigurationID);
CREATE INDEX IF NOT EXISTS idx_assembly_is_sub          ON CAD_Assembly(IsSubAssembly);
CREATE INDEX IF NOT EXISTS idx_assembly_position        ON CAD_Assembly(MyPositionPointID);
CREATE INDEX IF NOT EXISTS idx_mission_req_name         ON MissionRequirement(Name);
CREATE INDEX IF NOT EXISTS idx_system_req_name          ON SystemRequirement(Name);
CREATE INDEX IF NOT EXISTS idx_interface_name           ON CAD_Interface(Name);
CREATE INDEX IF NOT EXISTS idx_interface_kind           ON CAD_Interface(InterfaceKind);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: CAD_Assembly with pose, model info, and child counts
CREATE VIEW IF NOT EXISTS v_CAD_Assembly_Detail AS
SELECT
    a.AssemblyID,
    a.Name,
    a.Version,
    a.Description,
    a.IsSubAssembly,
    a.IsConfigurationItem,

    -- Pose
    pos.X_Value             AS Position_X,
    pos.Y_Value             AS Position_Y,
    pos.Z_Value_Cartesian   AS Position_Z,
    ori.X_Value             AS Orientation_X,
    ori.Y_Value             AS Orientation_Y,
    ori.Z_Value             AS Orientation_Z,

    -- Current coordinate system
    cs.Name                 AS CurrentCSysName,

    -- Model info
    m.Name                  AS ModelName,
    m.CAD_AppName           AS ModelApp,
    CASE m.CAD_AppName
        WHEN 0 THEN 'Fusion360'
        WHEN 1 THEN 'Solidworks'
        WHEN 2 THEN 'Blender'
        WHEN 3 THEN 'UnReal4'
        WHEN 4 THEN 'UnReal5'
        WHEN 5 THEN 'Unity'
        WHEN 6 THEN 'Other'
    END AS ModelAppText,

    -- Current configuration
    cfg.Name                AS CurrentConfigName,

    -- Part info
    p.Name                  AS PartName,
    p.PartNumber            AS PartNumber,

    -- Component cursors
    cc.Name                 AS CurrentComponentName,
    pc.Name                 AS PreviousComponentName,
    nc.Name                 AS NextComponentName,

    -- Child counts
    (SELECT COUNT(*) FROM CAD_Assembly_Component       ac  WHERE ac.AssemblyID  = a.AssemblyID) AS ComponentCount,
    (SELECT COUNT(*) FROM CAD_Assembly_Configuration   acf WHERE acf.AssemblyID = a.AssemblyID) AS ConfigurationCount,
    (SELECT COUNT(*) FROM CAD_Assembly_Interface       ai  WHERE ai.AssemblyID  = a.AssemblyID) AS InterfaceCount,
    (SELECT COUNT(*) FROM CAD_Assembly_MissionRequirement amr WHERE amr.AssemblyID = a.AssemblyID) AS MissionReqCount,
    (SELECT COUNT(*) FROM CAD_Assembly_SystemRequirement  asr WHERE asr.AssemblyID = a.AssemblyID) AS SystemReqCount,
    (SELECT COUNT(*) FROM CAD_Assembly_CoordinateSystem acs WHERE acs.AssemblyID = a.AssemblyID) AS CoordSysCount,
    (SELECT COUNT(*) FROM CAD_Assembly_Station ast WHERE ast.AssemblyID = a.AssemblyID AND ast.StationCategory = 'Axial')   AS AxialStationCount,
    (SELECT COUNT(*) FROM CAD_Assembly_Station ast WHERE ast.AssemblyID = a.AssemblyID AND ast.StationCategory = 'Radial')  AS RadialStationCount,
    (SELECT COUNT(*) FROM CAD_Assembly_Station ast WHERE ast.AssemblyID = a.AssemblyID AND ast.StationCategory = 'Angular') AS AngularStationCount,
    (SELECT COUNT(*) FROM CAD_Assembly_Station ast WHERE ast.AssemblyID = a.AssemblyID AND ast.StationCategory = 'Wing')    AS WingStationCount

FROM CAD_Assembly a
LEFT JOIN Point pos              ON a.MyPositionPointID     = pos.PointID
LEFT JOIN Vector ori             ON a.MyOrientationVectorID = ori.VectorID
LEFT JOIN CoordinateSystem cs    ON a.CurrentCSID           = cs.CoordinateSystemID
LEFT JOIN CAD_Model m            ON a.MyModelID             = m.ModelID
LEFT JOIN CAD_Configuration cfg  ON a.CurrentConfigurationID = cfg.ConfigurationID
LEFT JOIN CAD_Part p             ON a.MyPartID              = p.PartID
LEFT JOIN CAD_Component cc       ON a.CurrentComponentID    = cc.ComponentID
LEFT JOIN CAD_Component pc       ON a.PreviousComponentID   = pc.ComponentID
LEFT JOIN CAD_Component nc       ON a.NextComponentID       = nc.ComponentID;

-- View: Assembly component list with component details
CREATE VIEW IF NOT EXISTS v_CAD_Assembly_Components AS
SELECT
    a.AssemblyID,
    a.Name          AS AssemblyName,
    ac.SortOrder,
    c.ComponentID,
    c.Name          AS ComponentName,
    c.Version       AS ComponentVersion,
    c.Path          AS ComponentPath,
    c.IsAssembly    AS ComponentIsAssembly,
    c.WBS_Level     AS ComponentWBS
FROM CAD_Assembly a
JOIN CAD_Assembly_Component ac ON a.AssemblyID = ac.AssemblyID
JOIN CAD_Component c           ON ac.ComponentID = c.ComponentID
ORDER BY a.AssemblyID, ac.SortOrder;

-- View: Assembly station breakdown by category
CREATE VIEW IF NOT EXISTS v_CAD_Assembly_Stations AS
SELECT
    a.AssemblyID,
    a.Name              AS AssemblyName,
    ast.StationCategory,
    ast.SortOrder,
    s.StationID,
    s.Name              AS StationName,
    s.MyType            AS StationType,
    s.AxialLocation,
    s.RadialLocation,
    s.AngularLocation,
    s.WingLocation,
    s.FloorLocation
FROM CAD_Assembly a
JOIN CAD_Assembly_Station ast ON a.AssemblyID = ast.AssemblyID
JOIN CAD_Station s            ON ast.StationID = s.StationID
ORDER BY a.AssemblyID, ast.StationCategory, ast.SortOrder;
