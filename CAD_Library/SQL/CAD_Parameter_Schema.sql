-- ============================================================
-- SQLite Schema for CAD_Parameter JSON mapping
-- Generated from CAD_Library: CAD_Parameter (sealed class)
-- ============================================================
-- Depends on shared tables from CAD_Joint_Schema.sql / CAD_Dimension_Schema.sql:
--   Point, Vector, CoordinateSystem, UnitOfMeasure, CAD_Model, Segment,
--   CAD_Dimension
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- Shared tables (IF NOT EXISTS — safe to re-run alongside other schemas)
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

CREATE TABLE IF NOT EXISTS UnitOfMeasure (
    UnitOfMeasureID TEXT PRIMARY KEY,
    Name            TEXT,
    Description     TEXT,
    SymbolName      TEXT,
    UnitValue       REAL NOT NULL DEFAULT 0.0,
    SystemOfUnits   INTEGER NOT NULL DEFAULT 0,
    IsBaseUnit      INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Model (
    ModelID     TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    Description TEXT,
    FilePath    TEXT,
    CAD_AppName INTEGER NOT NULL DEFAULT 0,
    ModelType   INTEGER NOT NULL DEFAULT 0,
    FileType    INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- CAD_ParameterValue
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_ParameterValue (
    ParameterValueID    TEXT PRIMARY KEY,       -- synthetic key (generated)

    -- Type discriminator
    ValueType           INTEGER NOT NULL DEFAULT 0,
    -- ParameterValueTypeEnum: 0=Double,1=Single,2=Int16,3=Int32,4=Int64,5=Boolean,6=String,7=Object

    -- Typed value columns (only the column matching ValueType is populated)
    DoubleValue         REAL,
    SingleValue         REAL,
    Int16Value          INTEGER,
    Int32Value          INTEGER,
    Int64Value          INTEGER,
    BooleanValue        INTEGER,       -- 0/1
    StringValue         TEXT,
    ObjectValue         TEXT,          -- JSON blob for arbitrary objects

    -- Back-reference to owning parameter
    ParameterID         TEXT,

    FOREIGN KEY (ParameterID) REFERENCES CAD_Parameter(Id)
);

-- ============================================================
-- SE_Table (referenced by CAD_Parameter.DesignTable)
-- ============================================================

CREATE TABLE IF NOT EXISTS SE_Table (
    SE_TableID                  TEXT PRIMARY KEY,
    Name                        TEXT,
    ID                          TEXT,
    MyTableType                 INTEGER NOT NULL DEFAULT 0,    -- TableType enum
    CurrentFigureNumber         INTEGER NOT NULL DEFAULT 0,
    VerticalReadDirectionDown   INTEGER NOT NULL DEFAULT 1,    -- bool
    HorizontalReadDirectonRtL   INTEGER NOT NULL DEFAULT 1,    -- bool
    HasHeader                   INTEGER NOT NULL DEFAULT 0,    -- bool
    NumRows                     INTEGER NOT NULL DEFAULT 0,
    NumColumns                  INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- Mathematics.Parameter (referenced by CAD_Parameter.CurrentMathParameter)
-- This is the "refactored" Parameter class from the CAD namespace
-- ============================================================

CREATE TABLE IF NOT EXISTS MathParameter (
    MathParameterID     TEXT PRIMARY KEY,       -- derived from PartNumber or generated
    Name                TEXT,
    PartNumber          TEXT,
    Description         TEXT,
    Comments            TEXT,
    MyParameterType     INTEGER NOT NULL DEFAULT 0,    -- ParameterType: 0=Double,1=Integer,2=String,3=Vector,4=Other
    SolidWorksParameterName     TEXT,
    Fusion360ParameterName      TEXT,

    -- Associations
    CurrentDimensionID  TEXT,
    CurrentModelID      TEXT,
    MyUnitsID           TEXT,
    DesignTableID       TEXT,
    ExpressionText      TEXT,          -- serialized System.Linq.Expressions.Expression

    FOREIGN KEY (CurrentDimensionID)    REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CurrentModelID)        REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (MyUnitsID)             REFERENCES UnitOfMeasure(UnitOfMeasureID),
    FOREIGN KEY (DesignTableID)         REFERENCES SE_Table(SE_TableID)
);

-- MathParameter -> Dimensions
CREATE TABLE IF NOT EXISTS MathParameter_Dimension (
    MathParameterID TEXT NOT NULL,
    DimensionID     TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (MathParameterID, DimensionID),
    FOREIGN KEY (MathParameterID) REFERENCES MathParameter(MathParameterID),
    FOREIGN KEY (DimensionID)     REFERENCES CAD_Dimension(DimensionID)
);

-- MathParameter -> Models
CREATE TABLE IF NOT EXISTS MathParameter_Model (
    MathParameterID TEXT NOT NULL,
    ModelID         TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (MathParameterID, ModelID),
    FOREIGN KEY (MathParameterID) REFERENCES MathParameter(MathParameterID),
    FOREIGN KEY (ModelID)         REFERENCES CAD_Model(ModelID)
);

-- MathParameter -> DependencyParameters (self-referential)
CREATE TABLE IF NOT EXISTS MathParameter_Dependency (
    MathParameterID     TEXT NOT NULL,
    DependsOnParameterID TEXT NOT NULL,
    PRIMARY KEY (MathParameterID, DependsOnParameterID),
    FOREIGN KEY (MathParameterID)      REFERENCES MathParameter(MathParameterID),
    FOREIGN KEY (DependsOnParameterID) REFERENCES MathParameter(MathParameterID)
);

-- MathParameter -> DependentParameters (inverse; maintained via trigger or app code)
CREATE TABLE IF NOT EXISTS MathParameter_Dependent (
    MathParameterID         TEXT NOT NULL,
    DependentParameterID    TEXT NOT NULL,
    PRIMARY KEY (MathParameterID, DependentParameterID),
    FOREIGN KEY (MathParameterID)       REFERENCES MathParameter(MathParameterID),
    FOREIGN KEY (DependentParameterID)  REFERENCES MathParameter(MathParameterID)
);

-- ============================================================
-- CAD_Parameter  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Parameter (
    -- Primary key
    Id      TEXT PRIMARY KEY,

    -- Identification
    Name            TEXT,
    Description     TEXT,
    Comments        TEXT,

    -- Core data
    MyParameterType INTEGER NOT NULL DEFAULT 0,    -- ParameterType: 0=Double,1=Integer,2=String,3=Vector,4=Other

    -- Value (FK to CAD_ParameterValue)
    ValueID         TEXT,

    -- Units
    MyUnitsID       TEXT,

    -- Expression (System.Linq.Expressions.Expression serialized as text)
    ExpressionText  TEXT,

    -- CAD app bindings
    SolidWorksParameterName     TEXT,
    Fusion360ParameterName      TEXT,

    -- Associations (single references)
    CurrentDimensionID      TEXT,
    CurrentModelID          TEXT,
    CurrentMathParameterID  TEXT,
    DesignTableID           TEXT,

    FOREIGN KEY (ValueID)                   REFERENCES CAD_ParameterValue(ParameterValueID),
    FOREIGN KEY (MyUnitsID)                 REFERENCES UnitOfMeasure(UnitOfMeasureID),
    FOREIGN KEY (CurrentDimensionID)        REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CurrentModelID)            REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (CurrentMathParameterID)    REFERENCES MathParameter(MathParameterID),
    FOREIGN KEY (DesignTableID)             REFERENCES SE_Table(SE_TableID)
);

-- ============================================================
-- Junction Tables for CAD_Parameter collections
-- ============================================================

-- CAD_Parameter.MyDimensions (List<CAD_Dimension>)
CREATE TABLE IF NOT EXISTS CAD_Parameter_Dimension (
    ParameterID TEXT NOT NULL,
    DimensionID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ParameterID, DimensionID),
    FOREIGN KEY (ParameterID) REFERENCES CAD_Parameter(Id),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
);

-- CAD_Parameter.MyMathParameters (List<Parameter>)
CREATE TABLE IF NOT EXISTS CAD_Parameter_MathParameter (
    ParameterID     TEXT NOT NULL,
    MathParameterID TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ParameterID, MathParameterID),
    FOREIGN KEY (ParameterID)     REFERENCES CAD_Parameter(Id),
    FOREIGN KEY (MathParameterID) REFERENCES MathParameter(MathParameterID)
);

-- CAD_Parameter.MyModels (List<CAD_Model>)
CREATE TABLE IF NOT EXISTS CAD_Parameter_Model (
    ParameterID TEXT NOT NULL,
    ModelID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (ParameterID, ModelID),
    FOREIGN KEY (ParameterID) REFERENCES CAD_Parameter(Id),
    FOREIGN KEY (ModelID)     REFERENCES CAD_Model(ModelID)
);

-- CAD_Parameter.DependencyParameters (List<CAD_Parameter>) — self-referential
CREATE TABLE IF NOT EXISTS CAD_Parameter_Dependency (
    ParameterID         TEXT NOT NULL,
    DependsOnParameterID TEXT NOT NULL,
    PRIMARY KEY (ParameterID, DependsOnParameterID),
    FOREIGN KEY (ParameterID)           REFERENCES CAD_Parameter(Id),
    FOREIGN KEY (DependsOnParameterID)  REFERENCES CAD_Parameter(Id)
);

-- CAD_Parameter.DependentParameters (List<CAD_Parameter>) — inverse self-referential
CREATE TABLE IF NOT EXISTS CAD_Parameter_Dependent (
    ParameterID         TEXT NOT NULL,
    DependentParameterID TEXT NOT NULL,
    PRIMARY KEY (ParameterID, DependentParameterID),
    FOREIGN KEY (ParameterID)           REFERENCES CAD_Parameter(Id),
    FOREIGN KEY (DependentParameterID)  REFERENCES CAD_Parameter(Id)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_param_name           ON CAD_Parameter(Name);
CREATE INDEX IF NOT EXISTS idx_param_type           ON CAD_Parameter(MyParameterType);
CREATE INDEX IF NOT EXISTS idx_param_cur_dim        ON CAD_Parameter(CurrentDimensionID);
CREATE INDEX IF NOT EXISTS idx_param_cur_model      ON CAD_Parameter(CurrentModelID);
CREATE INDEX IF NOT EXISTS idx_param_cur_math       ON CAD_Parameter(CurrentMathParameterID);
CREATE INDEX IF NOT EXISTS idx_param_units          ON CAD_Parameter(MyUnitsID);
CREATE INDEX IF NOT EXISTS idx_param_design_table   ON CAD_Parameter(DesignTableID);
CREATE INDEX IF NOT EXISTS idx_param_sw_name        ON CAD_Parameter(SolidWorksParameterName);
CREATE INDEX IF NOT EXISTS idx_param_f360_name      ON CAD_Parameter(Fusion360ParameterName);
CREATE INDEX IF NOT EXISTS idx_paramval_type        ON CAD_ParameterValue(ValueType);
CREATE INDEX IF NOT EXISTS idx_paramval_owner       ON CAD_ParameterValue(ParameterID);
CREATE INDEX IF NOT EXISTS idx_mathparam_name       ON MathParameter(Name);
CREATE INDEX IF NOT EXISTS idx_se_table_name        ON SE_Table(Name);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: CAD_Parameter with its value and unit resolved
CREATE VIEW IF NOT EXISTS v_CAD_Parameter_Detail AS
SELECT
    p.Id,
    p.Name,
    p.Description,
    p.Comments,
    p.MyParameterType,
    CASE p.MyParameterType
        WHEN 0 THEN 'Double'
        WHEN 1 THEN 'Integer'
        WHEN 2 THEN 'String'
        WHEN 3 THEN 'Vector'
        WHEN 4 THEN 'Other'
    END AS ParameterTypeName,
    pv.ValueType,
    CASE pv.ValueType
        WHEN 0 THEN 'Double'
        WHEN 1 THEN 'Single'
        WHEN 2 THEN 'Int16'
        WHEN 3 THEN 'Int32'
        WHEN 4 THEN 'Int64'
        WHEN 5 THEN 'Boolean'
        WHEN 6 THEN 'String'
        WHEN 7 THEN 'Object'
    END AS ValueTypeName,
    COALESCE(
        CAST(pv.DoubleValue  AS TEXT),
        CAST(pv.SingleValue  AS TEXT),
        CAST(pv.Int16Value   AS TEXT),
        CAST(pv.Int32Value   AS TEXT),
        CAST(pv.Int64Value   AS TEXT),
        CASE pv.BooleanValue WHEN 1 THEN 'True' WHEN 0 THEN 'False' END,
        pv.StringValue,
        pv.ObjectValue
    ) AS DisplayValue,
    u.Name          AS UnitName,
    u.SymbolName    AS UnitSymbol,
    p.SolidWorksParameterName,
    p.Fusion360ParameterName,
    p.ExpressionText,
    d.DimensionID   AS CurrentDimensionID,
    d.Name          AS CurrentDimensionName,
    m.Name          AS CurrentModelName
FROM CAD_Parameter p
LEFT JOIN CAD_ParameterValue pv ON p.ValueID                = pv.ParameterValueID
LEFT JOIN UnitOfMeasure u       ON p.MyUnitsID              = u.UnitOfMeasureID
LEFT JOIN CAD_Dimension d       ON p.CurrentDimensionID     = d.DimensionID
LEFT JOIN CAD_Model m           ON p.CurrentModelID         = m.ModelID;

-- View: Parameter dependency graph (both directions)
CREATE VIEW IF NOT EXISTS v_CAD_Parameter_DependencyGraph AS
SELECT
    dep.ParameterID         AS SourceParameterID,
    ps.Name                 AS SourceParameterName,
    dep.DependsOnParameterID AS TargetParameterID,
    pt.Name                 AS TargetParameterName,
    'depends_on'            AS Direction
FROM CAD_Parameter_Dependency dep
JOIN CAD_Parameter ps ON dep.ParameterID          = ps.Id
JOIN CAD_Parameter pt ON dep.DependsOnParameterID = pt.Id
UNION ALL
SELECT
    d.ParameterID           AS SourceParameterID,
    ps2.Name                AS SourceParameterName,
    d.DependentParameterID  AS TargetParameterID,
    pt2.Name                AS TargetParameterName,
    'depended_on_by'        AS Direction
FROM CAD_Parameter_Dependent d
JOIN CAD_Parameter ps2 ON d.ParameterID          = ps2.Id
JOIN CAD_Parameter pt2 ON d.DependentParameterID = pt2.Id;
