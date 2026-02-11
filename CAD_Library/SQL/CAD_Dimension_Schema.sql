-- ============================================================
-- SQLite Schema for CAD_Dimension JSON mapping
-- Generated from CAD_Library: CAD_Dimension (extends CAD_DrawingElement)
-- ============================================================
-- Depends on shared tables from CAD_Joint_Schema.sql:
--   Point, Vector, CoordinateSystem
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- Shared Mathematics Types (IF NOT EXISTS — safe to re-run)
-- ============================================================

CREATE TABLE IF NOT EXISTS Point (
    PointID         TEXT PRIMARY KEY,
    IsWeightPoint   INTEGER NOT NULL DEFAULT 0,
    MyType          INTEGER NOT NULL DEFAULT 0,    -- PointTypeEnum: 0=Cartesian,1=Cylindrical,2=Spherical,3=Complex
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
    VectorID    TEXT PRIMARY KEY,
    Name        TEXT,
    IsKnotVector    INTEGER NOT NULL DEFAULT 0,
    VectorType      INTEGER NOT NULL DEFAULT 0,    -- VectorTypeEnum: 0=Cartesian,1=Cylindrical,2=Spherical,3=Polar
    X_Value     REAL NOT NULL DEFAULT 0.0,
    Y_Value     REAL NOT NULL DEFAULT 0.0,
    Z_Value     REAL NOT NULL DEFAULT 0.0,
    Cyl_R       REAL NOT NULL DEFAULT 0.0,
    Cyl_Theta   REAL NOT NULL DEFAULT 0.0,
    L           REAL NOT NULL DEFAULT 0.0,
    Sph_R       REAL NOT NULL DEFAULT 0.0,
    Sph_Theta   REAL NOT NULL DEFAULT 0.0,
    Phi         REAL NOT NULL DEFAULT 0.0,
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
-- SE_Library Types
-- ============================================================

CREATE TABLE IF NOT EXISTS UnitOfMeasure (
    UnitOfMeasureID TEXT PRIMARY KEY,       -- synthetic key (generated or derived from Name)
    Name            TEXT,
    Description     TEXT,
    SymbolName      TEXT,
    UnitValue       REAL NOT NULL DEFAULT 0.0,
    SystemOfUnits   INTEGER NOT NULL DEFAULT 0,    -- SystemOfUnitsEnum
    IsBaseUnit      INTEGER NOT NULL DEFAULT 0     -- bool
);

-- ============================================================
-- Mathematics.Segment
-- ============================================================

CREATE TABLE IF NOT EXISTS Segment (
    SegmentID       TEXT PRIMARY KEY,
    SegmentType     INTEGER NOT NULL DEFAULT 0,    -- SegmentTypeEnum (0=Line, etc.)
    IsEdge          INTEGER NOT NULL DEFAULT 0,    -- bool
    Length          REAL NOT NULL DEFAULT 0.0,

    -- Key points
    StartPointID    TEXT,
    EndPointID      TEXT,
    MidPointID      TEXT,
    FocalPoint1ID   TEXT,
    FocalPoint2ID   TEXT,
    VertexID        TEXT,

    -- Vector / CoordinateSystem
    CurrentVectorID         TEXT,
    MyCoordinateSystemID    TEXT,

    -- Linked segments
    PreviousSegmentID           TEXT,
    NextSegmentID               TEXT,
    CurrentConnectedSegmentID   TEXT,

    FOREIGN KEY (StartPointID)              REFERENCES Point(PointID),
    FOREIGN KEY (EndPointID)                REFERENCES Point(PointID),
    FOREIGN KEY (MidPointID)                REFERENCES Point(PointID),
    FOREIGN KEY (FocalPoint1ID)             REFERENCES Point(PointID),
    FOREIGN KEY (FocalPoint2ID)             REFERENCES Point(PointID),
    FOREIGN KEY (VertexID)                  REFERENCES Point(PointID),
    FOREIGN KEY (CurrentVectorID)           REFERENCES Vector(VectorID),
    FOREIGN KEY (MyCoordinateSystemID)      REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (PreviousSegmentID)         REFERENCES Segment(SegmentID),
    FOREIGN KEY (NextSegmentID)             REFERENCES Segment(SegmentID),
    FOREIGN KEY (CurrentConnectedSegmentID) REFERENCES Segment(SegmentID)
);

-- Segment -> Points (MyPoints collection)
CREATE TABLE IF NOT EXISTS Segment_Point (
    SegmentID   TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SegmentID, PointID),
    FOREIGN KEY (SegmentID) REFERENCES Segment(SegmentID),
    FOREIGN KEY (PointID)   REFERENCES Point(PointID)
);

-- Segment -> WeightPoints
CREATE TABLE IF NOT EXISTS Segment_WeightPoint (
    SegmentID   TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SegmentID, PointID),
    FOREIGN KEY (SegmentID) REFERENCES Segment(SegmentID),
    FOREIGN KEY (PointID)   REFERENCES Point(PointID)
);

-- Segment -> Vectors (MyVectors collection)
CREATE TABLE IF NOT EXISTS Segment_Vector (
    SegmentID   TEXT NOT NULL,
    VectorID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SegmentID, VectorID),
    FOREIGN KEY (SegmentID) REFERENCES Segment(SegmentID),
    FOREIGN KEY (VectorID)  REFERENCES Vector(VectorID)
);

-- Segment -> ConnectedSegments
CREATE TABLE IF NOT EXISTS Segment_ConnectedSegment (
    SegmentID           TEXT NOT NULL,
    ConnectedSegmentID  TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SegmentID, ConnectedSegmentID),
    FOREIGN KEY (SegmentID)          REFERENCES Segment(SegmentID),
    FOREIGN KEY (ConnectedSegmentID) REFERENCES Segment(SegmentID)
);

-- ============================================================
-- CAD_Model (referenced by CAD_Dimension.MyModel)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Model (
    ModelID     TEXT PRIMARY KEY,               -- synthetic key
    Name        TEXT,
    Version     TEXT,
    Description TEXT,
    FilePath    TEXT,
    CAD_AppName INTEGER NOT NULL DEFAULT 0,     -- CAD_AppEnum: 0=Fusion360,1=Solidworks,2=Blender,3=UnReal4,4=UnReal5,5=Unity,6=Other
    ModelType   INTEGER NOT NULL DEFAULT 0,     -- CAD_ModelTypeEnum: 0=Component,1=Assembly,2=Drawing,3=Mesh,4=Body,5=Other
    FileType    INTEGER NOT NULL DEFAULT 0      -- CAD_FileTypeEnum: 0=f3d,1=f3z,...,15=other
);

-- ============================================================
-- CAD_DrawingElement (base class of CAD_Dimension)
-- Flattened into CAD_Dimension table below
-- ============================================================

-- ============================================================
-- CAD_Dimension  (main table — CAD_DrawingElement + CAD_Dimension)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Dimension (
    -- Primary key
    DimensionID     TEXT PRIMARY KEY,

    -- CAD_DrawingElement fields
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 1,    -- DrawingElementType: 0=DrawingView,1=Dimension,2=Table,3=BoM,4=PMI,5=ConstructionGeometry,6=Note,7=Other
    MyDrawingID     TEXT,                          -- FK to CAD_Drawing (if table exists)

    -- CAD_Dimension identification
    Description     TEXT,
    IsOrdinate      INTEGER NOT NULL DEFAULT 0,    -- bool

    -- Geometry / locating points (FKs to Point table)
    CenterPointID           TEXT,
    LeaderLineEndPointID    TEXT,
    LeaderLineBendPointID   TEXT,
    DimensionPointID        TEXT,
    ReferencePointID        TEXT,

    -- Associations
    MyModelID       TEXT,
    MySegmentID     TEXT,

    -- Dimension values
    DimensionNominalValue       REAL NOT NULL DEFAULT 0.0,
    DimensionUpperLimitValue    REAL NOT NULL DEFAULT 0.0,
    DimensionLowerLimitValue    REAL NOT NULL DEFAULT 0.0,
    MyDimensionType             INTEGER NOT NULL DEFAULT 0,    -- DimensionType: 0=Length,1=Diameter,2=Radius,3=Angle,4=Distance,5=Ordinal,6=Other

    -- Engineering unit
    EngineeringUnitID   TEXT,

    -- Current parameter reference
    CurrentParameterID  TEXT,

    FOREIGN KEY (CenterPointID)         REFERENCES Point(PointID),
    FOREIGN KEY (LeaderLineEndPointID)  REFERENCES Point(PointID),
    FOREIGN KEY (LeaderLineBendPointID) REFERENCES Point(PointID),
    FOREIGN KEY (DimensionPointID)      REFERENCES Point(PointID),
    FOREIGN KEY (ReferencePointID)      REFERENCES Point(PointID),
    FOREIGN KEY (MyModelID)             REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (MySegmentID)           REFERENCES Segment(SegmentID),
    FOREIGN KEY (EngineeringUnitID)     REFERENCES UnitOfMeasure(UnitOfMeasureID),
    FOREIGN KEY (CurrentParameterID)    REFERENCES CAD_Parameter(Id)
);

-- CAD_Dimension -> MyParameters (List<CAD_Parameter>)
CREATE TABLE IF NOT EXISTS CAD_Dimension_Parameter (
    DimensionID TEXT NOT NULL,
    ParameterID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DimensionID, ParameterID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (ParameterID) REFERENCES CAD_Parameter(Id)
);

-- CAD_DrawingElement -> MyConstructionGeometry (List<CAD_ConstructionGeometery>)
-- Junction for construction geometry inherited from the base class
CREATE TABLE IF NOT EXISTS CAD_Dimension_ConstructionGeometry (
    DimensionID             TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DimensionID, ConstructionGeometryID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
    -- FK to CAD_ConstructionGeometry table omitted; add when that table is defined
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_dim_name         ON CAD_Dimension(Name);
CREATE INDEX IF NOT EXISTS idx_dim_type         ON CAD_Dimension(MyDimensionType);
CREATE INDEX IF NOT EXISTS idx_dim_model        ON CAD_Dimension(MyModelID);
CREATE INDEX IF NOT EXISTS idx_dim_segment      ON CAD_Dimension(MySegmentID);
CREATE INDEX IF NOT EXISTS idx_dim_unit         ON CAD_Dimension(EngineeringUnitID);
CREATE INDEX IF NOT EXISTS idx_dim_cur_param    ON CAD_Dimension(CurrentParameterID);
CREATE INDEX IF NOT EXISTS idx_segment_type     ON Segment(SegmentType);
CREATE INDEX IF NOT EXISTS idx_uom_name         ON UnitOfMeasure(Name);

-- ============================================================
-- View: Flat dimension detail with tolerance and origin info
-- ============================================================

CREATE VIEW IF NOT EXISTS v_CAD_Dimension_Detail AS
SELECT
    d.DimensionID,
    d.Name,
    d.Description,
    d.IsOrdinate,
    d.MyDimensionType,
    CASE d.MyDimensionType
        WHEN 0 THEN 'Length'
        WHEN 1 THEN 'Diameter'
        WHEN 2 THEN 'Radius'
        WHEN 3 THEN 'Angle'
        WHEN 4 THEN 'Distance'
        WHEN 5 THEN 'Ordinal'
        WHEN 6 THEN 'Other'
    END AS DimensionTypeName,
    d.DimensionNominalValue,
    d.DimensionUpperLimitValue,
    d.DimensionLowerLimitValue,
    (d.DimensionUpperLimitValue - d.DimensionNominalValue)  AS PlusTolerance,
    (d.DimensionNominalValue   - d.DimensionLowerLimitValue) AS MinusTolerance,
    u.Name          AS UnitName,
    u.SymbolName    AS UnitSymbol,
    cp.X_Value      AS Center_X,
    cp.Y_Value      AS Center_Y,
    cp.Z_Value_Cartesian AS Center_Z,
    m.Name          AS ModelName,
    m.CAD_AppName   AS ModelApp
FROM CAD_Dimension d
LEFT JOIN UnitOfMeasure u   ON d.EngineeringUnitID  = u.UnitOfMeasureID
LEFT JOIN Point cp          ON d.CenterPointID       = cp.PointID
LEFT JOIN CAD_Model m       ON d.MyModelID           = m.ModelID;
