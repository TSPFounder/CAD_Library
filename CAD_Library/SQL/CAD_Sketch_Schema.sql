-- ============================================================
-- SQLite Schema for CAD_Sketch JSON mapping
-- Generated from CAD_Library: CAD_Sketch
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, Segment, CAD_Model,
--   CAD_SketchPlane, CAD_Parameter, CAD_Dimension,
--   CAD_Constraint, CAD_SketchElement, Primitive
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

CREATE TABLE IF NOT EXISTS Segment (
    SegmentID       TEXT PRIMARY KEY,
    SegmentType     INTEGER NOT NULL DEFAULT 0,
    IsEdge          INTEGER NOT NULL DEFAULT 0,
    Length          REAL NOT NULL DEFAULT 0.0,
    StartPointID    TEXT,
    EndPointID      TEXT,
    MidPointID      TEXT,
    FocalPoint1ID   TEXT,
    FocalPoint2ID   TEXT,
    VertexID        TEXT,
    CurrentVectorID         TEXT,
    MyCoordinateSystemID    TEXT,
    PreviousSegmentID       TEXT,
    NextSegmentID           TEXT,
    CurrentConnectedSegmentID TEXT,
    FOREIGN KEY (StartPointID)  REFERENCES Point(PointID),
    FOREIGN KEY (EndPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (MidPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (CurrentVectorID) REFERENCES Vector(VectorID),
    FOREIGN KEY (MyCoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- ============================================================
-- Shared CAD types (stubs — full definitions in their own schemas)
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

CREATE TABLE IF NOT EXISTS CAD_SketchPlane (
    SketchPlaneID       TEXT PRIMARY KEY,
    Name                TEXT,
    Version             TEXT,
    Path                TEXT,
    IsWorkplane         INTEGER NOT NULL DEFAULT 1,
    GeometryType        INTEGER NOT NULL DEFAULT 0,
    FunctionalType      INTEGER NOT NULL DEFAULT 3,
    MyModelID           TEXT,
    MyCoordinateSystemID TEXT,
    NormalVectorID      TEXT,
    CurrentSketchID     TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Parameter (
    Id      TEXT PRIMARY KEY,
    Name    TEXT,
    Description TEXT,
    Comments    TEXT,
    MyParameterType INTEGER NOT NULL DEFAULT 0,
    ValueID     TEXT,
    MyUnitsID   TEXT,
    ExpressionText  TEXT,
    SolidWorksParameterName     TEXT,
    Fusion360ParameterName      TEXT,
    CurrentDimensionID      TEXT,
    CurrentModelID          TEXT,
    CurrentMathParameterID  TEXT,
    DesignTableID           TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Dimension (
    DimensionID     TEXT PRIMARY KEY,
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 1,
    MyDrawingID     TEXT,
    Description     TEXT,
    IsOrdinate      INTEGER NOT NULL DEFAULT 0,
    CenterPointID           TEXT,
    LeaderLineEndPointID    TEXT,
    LeaderLineBendPointID   TEXT,
    DimensionPointID        TEXT,
    ReferencePointID        TEXT,
    MyModelID       TEXT,
    MySegmentID     TEXT,
    DimensionNominalValue       REAL NOT NULL DEFAULT 0.0,
    DimensionUpperLimitValue    REAL NOT NULL DEFAULT 0.0,
    DimensionLowerLimitValue    REAL NOT NULL DEFAULT 0.0,
    MyDimensionType             INTEGER NOT NULL DEFAULT 0,
    EngineeringUnitID   TEXT,
    CurrentParameterID  TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Feature (
    FeatureID               TEXT PRIMARY KEY,
    Name                    TEXT,
    Version                 TEXT,
    GeometricFeatureType    INTEGER NOT NULL DEFAULT 0,
    MyModelID               TEXT,
    OriginCSysID            TEXT,
    CurrentDimensionID      TEXT,
    CurrentFeatureID        TEXT,
    CurrentCAD_SketchID     TEXT,
    CurrentCAD_StationID    TEXT,
    CurrentLibraryID        TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Constraint (
    ConstraintID    TEXT PRIMARY KEY,
    Name            TEXT,
    ID              TEXT,
    Description     TEXT,
    Type            INTEGER NOT NULL DEFAULT 16,
    CurrentFeatureID    TEXT,
    PreviousFeatureID   TEXT,
    CurrentModelID      TEXT
);

CREATE TABLE IF NOT EXISTS CAD_SketchElement (
    SketchElementID TEXT PRIMARY KEY,
    Name            TEXT,
    Version         TEXT,
    Path            TEXT,
    ElementType     INTEGER NOT NULL DEFAULT 0,
    IsWorkElement   INTEGER NOT NULL DEFAULT 0,
    CurrentPointID  TEXT,
    StartPointID    TEXT,
    EndPointID      TEXT,
    MidPointID      TEXT,
    ControlPointID  TEXT,
    CurrentPrimitiveID TEXT
);

-- ============================================================
-- TwoDGeometry (Mathematics)
-- ============================================================

CREATE TABLE IF NOT EXISTS TwoDGeometry (
    TwoDGeometryID      TEXT PRIMARY KEY,      -- derived from GeometryID or generated
    GeometryID          TEXT,                  -- the class's own ID property
    GeometryType        INTEGER,               -- GeometryTypeEnum: 0=Line,1=Arc,2=Circle,3=Triangle,4=Rectangle,5=Quadratic,6=Spline
    IsClosed            INTEGER NOT NULL DEFAULT 0,    -- bool
    IsConstructionGeometry INTEGER NOT NULL DEFAULT 0, -- bool

    -- Coordinate system
    MyCoordinateSystemID TEXT,

    -- Point cursors
    CurrentPointID  TEXT,
    NextPointID     TEXT,
    PreviousPointID TEXT,
    CenterPointID   TEXT,

    -- Segment cursors
    CurrentSegmentID    TEXT,
    NextSegmentID       TEXT,
    PreviousSegmentID   TEXT,

    FOREIGN KEY (MyCoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (CurrentPointID)    REFERENCES Point(PointID),
    FOREIGN KEY (NextPointID)       REFERENCES Point(PointID),
    FOREIGN KEY (PreviousPointID)   REFERENCES Point(PointID),
    FOREIGN KEY (CenterPointID)     REFERENCES Point(PointID),
    FOREIGN KEY (CurrentSegmentID)  REFERENCES Segment(SegmentID),
    FOREIGN KEY (NextSegmentID)     REFERENCES Segment(SegmentID),
    FOREIGN KEY (PreviousSegmentID) REFERENCES Segment(SegmentID)
);

-- TwoDGeometry -> MyPoints
CREATE TABLE IF NOT EXISTS TwoDGeometry_Point (
    TwoDGeometryID  TEXT NOT NULL,
    PointID         TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (TwoDGeometryID, PointID, SortOrder),
    FOREIGN KEY (TwoDGeometryID) REFERENCES TwoDGeometry(TwoDGeometryID),
    FOREIGN KEY (PointID)        REFERENCES Point(PointID)
);

-- TwoDGeometry -> MySegments
CREATE TABLE IF NOT EXISTS TwoDGeometry_Segment (
    TwoDGeometryID  TEXT NOT NULL,
    SegmentID       TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (TwoDGeometryID, SegmentID, SortOrder),
    FOREIGN KEY (TwoDGeometryID) REFERENCES TwoDGeometry(TwoDGeometryID),
    FOREIGN KEY (SegmentID)      REFERENCES Segment(SegmentID)
);

-- ============================================================
-- CAD_Sketch  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Sketch (
    SketchID        TEXT PRIMARY KEY,

    -- Identification
    Version         TEXT,

    -- Flags
    IsTwoD          INTEGER NOT NULL DEFAULT 0,    -- bool

    -- Summary parameters (FKs to CAD_Parameter)
    AreaParameterID             TEXT,
    PerimeterLengthParameterID  TEXT,

    -- Ownership
    MyModelID       TEXT,
    MySketchPlaneID TEXT,

    -- Cursors: points / segments
    CurrentPointID      TEXT,
    CurrentSegmentID    TEXT,
    PreviousSegmentID   TEXT,

    -- Cursors: sketch sub-objects
    CurrentSketchElemID     TEXT,
    CurrentParameterID      TEXT,
    CurrentDimensionID      TEXT,
    CurrentConstraintID     TEXT,

    -- Cursors: coordinate systems
    CurrentCoordinateSystemID   TEXT,
    BaseCoordinateSystemID      TEXT,

    FOREIGN KEY (AreaParameterID)            REFERENCES CAD_Parameter(Id),
    FOREIGN KEY (PerimeterLengthParameterID) REFERENCES CAD_Parameter(Id),
    FOREIGN KEY (MyModelID)                  REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (MySketchPlaneID)            REFERENCES CAD_SketchPlane(SketchPlaneID),
    FOREIGN KEY (CurrentPointID)             REFERENCES Point(PointID),
    FOREIGN KEY (CurrentSegmentID)           REFERENCES Segment(SegmentID),
    FOREIGN KEY (PreviousSegmentID)          REFERENCES Segment(SegmentID),
    FOREIGN KEY (CurrentSketchElemID)        REFERENCES CAD_SketchElement(SketchElementID),
    FOREIGN KEY (CurrentParameterID)         REFERENCES CAD_Parameter(Id),
    FOREIGN KEY (CurrentDimensionID)         REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CurrentConstraintID)        REFERENCES CAD_Constraint(ConstraintID),
    FOREIGN KEY (CurrentCoordinateSystemID)  REFERENCES CoordinateSystem(CoordinateSystemID),
    FOREIGN KEY (BaseCoordinateSystemID)     REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- ============================================================
-- CAD_Sketch collection junction tables
-- ============================================================

-- MyPoints (List<Point>)
CREATE TABLE IF NOT EXISTS CAD_Sketch_Point (
    SketchID    TEXT NOT NULL,
    PointID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, PointID, SortOrder),
    FOREIGN KEY (SketchID) REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (PointID)  REFERENCES Point(PointID)
);

-- MySegments (List<Segment>)
CREATE TABLE IF NOT EXISTS CAD_Sketch_Segment (
    SketchID    TEXT NOT NULL,
    SegmentID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, SegmentID, SortOrder),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (SegmentID) REFERENCES Segment(SegmentID)
);

-- MyProfile (List<Segment>)
CREATE TABLE IF NOT EXISTS CAD_Sketch_ProfileSegment (
    SketchID    TEXT NOT NULL,
    SegmentID   TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, SegmentID, SortOrder),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (SegmentID) REFERENCES Segment(SegmentID)
);

-- My2DGeometry (List<TwoDGeometry>)
CREATE TABLE IF NOT EXISTS CAD_Sketch_TwoDGeometry (
    SketchID        TEXT NOT NULL,
    TwoDGeometryID  TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, TwoDGeometryID),
    FOREIGN KEY (SketchID)       REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (TwoDGeometryID) REFERENCES TwoDGeometry(TwoDGeometryID)
);

-- MyCoordinateSystems (List<CoordinateSystem>)
CREATE TABLE IF NOT EXISTS CAD_Sketch_CoordinateSystem (
    SketchID            TEXT NOT NULL,
    CoordinateSystemID  TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, CoordinateSystemID),
    FOREIGN KEY (SketchID)           REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CoordinateSystemID) REFERENCES CoordinateSystem(CoordinateSystemID)
);

-- MySketchElements (List<CAD_SketchElement>)
CREATE TABLE IF NOT EXISTS CAD_Sketch_SketchElement (
    SketchID        TEXT NOT NULL,
    SketchElementID TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, SketchElementID),
    FOREIGN KEY (SketchID)        REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (SketchElementID) REFERENCES CAD_SketchElement(SketchElementID)
);

-- MyParameters (List<CAD_Parameter>)
CREATE TABLE IF NOT EXISTS CAD_Sketch_Parameter (
    SketchID    TEXT NOT NULL,
    ParameterID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, ParameterID),
    FOREIGN KEY (SketchID)    REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (ParameterID) REFERENCES CAD_Parameter(Id)
);

-- MyDimensions (List<CAD_Dimension>)
CREATE TABLE IF NOT EXISTS CAD_Sketch_Dimension (
    SketchID    TEXT NOT NULL,
    DimensionID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, DimensionID),
    FOREIGN KEY (SketchID)    REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
);

-- MyConstraints (List<CAD_Constraint>)
CREATE TABLE IF NOT EXISTS CAD_Sketch_Constraint (
    SketchID        TEXT NOT NULL,
    ConstraintID    TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SketchID, ConstraintID),
    FOREIGN KEY (SketchID)      REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (ConstraintID)  REFERENCES CAD_Constraint(ConstraintID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_sketch_version       ON CAD_Sketch(Version);
CREATE INDEX IF NOT EXISTS idx_sketch_model         ON CAD_Sketch(MyModelID);
CREATE INDEX IF NOT EXISTS idx_sketch_plane         ON CAD_Sketch(MySketchPlaneID);
CREATE INDEX IF NOT EXISTS idx_sketch_is2d          ON CAD_Sketch(IsTwoD);
CREATE INDEX IF NOT EXISTS idx_sketch_cur_point     ON CAD_Sketch(CurrentPointID);
CREATE INDEX IF NOT EXISTS idx_sketch_cur_seg       ON CAD_Sketch(CurrentSegmentID);
CREATE INDEX IF NOT EXISTS idx_sketch_cur_elem      ON CAD_Sketch(CurrentSketchElemID);
CREATE INDEX IF NOT EXISTS idx_sketch_cur_param     ON CAD_Sketch(CurrentParameterID);
CREATE INDEX IF NOT EXISTS idx_sketch_cur_dim       ON CAD_Sketch(CurrentDimensionID);
CREATE INDEX IF NOT EXISTS idx_sketch_cur_constr    ON CAD_Sketch(CurrentConstraintID);
CREATE INDEX IF NOT EXISTS idx_sketch_cur_csys      ON CAD_Sketch(CurrentCoordinateSystemID);
CREATE INDEX IF NOT EXISTS idx_sketch_base_csys     ON CAD_Sketch(BaseCoordinateSystemID);
CREATE INDEX IF NOT EXISTS idx_2dgeom_type          ON TwoDGeometry(GeometryType);
CREATE INDEX IF NOT EXISTS idx_2dgeom_csys          ON TwoDGeometry(MyCoordinateSystemID);
CREATE INDEX IF NOT EXISTS idx_2dgeom_closed        ON TwoDGeometry(IsClosed);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: CAD_Sketch with model/plane info and child counts
CREATE VIEW IF NOT EXISTS v_CAD_Sketch_Detail AS
SELECT
    s.SketchID,
    s.Version,
    s.IsTwoD,

    -- Sketch plane info
    sp.Name                 AS SketchPlaneName,
    sp.FunctionalType       AS SketchPlaneFuncType,
    CASE sp.FunctionalType
        WHEN 0 THEN 'Interface'
        WHEN 1 THEN 'Section'
        WHEN 2 THEN 'GeometricBoundary'
        WHEN 3 THEN 'Feature'
        WHEN 4 THEN 'CoordinateSystemOrigin'
        WHEN 5 THEN 'Incremental'
    END AS SketchPlaneFuncTypeName,

    -- Model info
    m.Name                  AS ModelName,
    m.CAD_AppName           AS ModelApp,

    -- Summary parameters
    ap.Name                 AS AreaParamName,
    pp.Name                 AS PerimeterParamName,

    -- Base coordinate system
    bcs.Name                AS BaseCSysName,

    -- Child counts
    (SELECT COUNT(*) FROM CAD_Sketch_Point          sp2  WHERE sp2.SketchID  = s.SketchID) AS PointCount,
    (SELECT COUNT(*) FROM CAD_Sketch_Segment        ss   WHERE ss.SketchID   = s.SketchID) AS SegmentCount,
    (SELECT COUNT(*) FROM CAD_Sketch_ProfileSegment sps  WHERE sps.SketchID  = s.SketchID) AS ProfileSegmentCount,
    (SELECT COUNT(*) FROM CAD_Sketch_TwoDGeometry   stg  WHERE stg.SketchID  = s.SketchID) AS TwoDGeometryCount,
    (SELECT COUNT(*) FROM CAD_Sketch_CoordinateSystem scs WHERE scs.SketchID = s.SketchID) AS CoordSysCount,
    (SELECT COUNT(*) FROM CAD_Sketch_SketchElement  sse  WHERE sse.SketchID  = s.SketchID) AS SketchElementCount,
    (SELECT COUNT(*) FROM CAD_Sketch_Parameter      spr  WHERE spr.SketchID  = s.SketchID) AS ParameterCount,
    (SELECT COUNT(*) FROM CAD_Sketch_Dimension      sd   WHERE sd.SketchID   = s.SketchID) AS DimensionCount,
    (SELECT COUNT(*) FROM CAD_Sketch_Constraint     sc   WHERE sc.SketchID   = s.SketchID) AS ConstraintCount

FROM CAD_Sketch s
LEFT JOIN CAD_SketchPlane sp    ON s.MySketchPlaneID        = sp.SketchPlaneID
LEFT JOIN CAD_Model m           ON s.MyModelID              = m.ModelID
LEFT JOIN CAD_Parameter ap      ON s.AreaParameterID        = ap.Id
LEFT JOIN CAD_Parameter pp      ON s.PerimeterLengthParameterID = pp.Id
LEFT JOIN CoordinateSystem bcs  ON s.BaseCoordinateSystemID = bcs.CoordinateSystemID;

-- View: Sketch segments in order with start/end coordinates
CREATE VIEW IF NOT EXISTS v_CAD_Sketch_Segments AS
SELECT
    s.SketchID,
    s.Version       AS SketchVersion,
    ss.SortOrder,
    seg.SegmentID,
    seg.SegmentType,
    seg.Length      AS SegmentLength,
    sp.X_Value      AS Start_X,
    sp.Y_Value      AS Start_Y,
    sp.Z_Value_Cartesian AS Start_Z,
    ep.X_Value      AS End_X,
    ep.Y_Value      AS End_Y,
    ep.Z_Value_Cartesian AS End_Z
FROM CAD_Sketch s
JOIN CAD_Sketch_Segment ss  ON s.SketchID       = ss.SketchID
JOIN Segment seg            ON ss.SegmentID      = seg.SegmentID
LEFT JOIN Point sp          ON seg.StartPointID  = sp.PointID
LEFT JOIN Point ep          ON seg.EndPointID    = ep.PointID
ORDER BY s.SketchID, ss.SortOrder;

-- View: Sketch constraints with type labels
CREATE VIEW IF NOT EXISTS v_CAD_Sketch_Constraints AS
SELECT
    s.SketchID,
    sc.SortOrder,
    c.ConstraintID,
    c.Name          AS ConstraintName,
    c.Type          AS ConstraintType,
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
    c.Description
FROM CAD_Sketch s
JOIN CAD_Sketch_Constraint sc ON s.SketchID     = sc.SketchID
JOIN CAD_Constraint c         ON sc.ConstraintID = c.ConstraintID
ORDER BY s.SketchID, sc.SortOrder;

-- View: Sketch dimensions with tolerance info
CREATE VIEW IF NOT EXISTS v_CAD_Sketch_Dimensions AS
SELECT
    s.SketchID,
    sd.SortOrder,
    d.DimensionID,
    d.Name              AS DimensionName,
    d.MyDimensionType,
    CASE d.MyDimensionType
        WHEN 0 THEN 'Length'    WHEN 1 THEN 'Diameter'
        WHEN 2 THEN 'Radius'   WHEN 3 THEN 'Angle'
        WHEN 4 THEN 'Distance' WHEN 5 THEN 'Ordinal'
        WHEN 6 THEN 'Other'
    END AS DimensionTypeName,
    d.DimensionNominalValue,
    d.DimensionUpperLimitValue,
    d.DimensionLowerLimitValue,
    (d.DimensionUpperLimitValue - d.DimensionNominalValue)  AS PlusTolerance,
    (d.DimensionNominalValue - d.DimensionLowerLimitValue)  AS MinusTolerance
FROM CAD_Sketch s
JOIN CAD_Sketch_Dimension sd ON s.SketchID     = sd.SketchID
JOIN CAD_Dimension d         ON sd.DimensionID = d.DimensionID
ORDER BY s.SketchID, sd.SortOrder;
