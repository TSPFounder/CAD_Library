-- ============================================================
-- SQLite Schema for CAD_Drawing JSON mapping
-- Generated from CAD_Library: CAD_Drawing
-- ============================================================
-- Depends on shared tables from prior schemas:
--   Point, Vector, CoordinateSystem, Segment, CAD_Model,
--   CAD_Assembly, CAD_Sketch, CAD_Part, CAD_Feature,
--   CAD_Dimension, MathParameter, CAD_Configuration,
--   CAD_BoM, CAD_ConstructionGeometry, UnitOfMeasure,
--   SE_Table, Quadrilateral
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- Shared types (IF NOT EXISTS — safe to re-run)
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

CREATE TABLE IF NOT EXISTS CAD_Assembly (
    AssemblyID          TEXT PRIMARY KEY,
    Name                TEXT,
    Version             TEXT,
    Description         TEXT,
    IsSubAssembly       INTEGER NOT NULL DEFAULT 0,
    IsConfigurationItem INTEGER NOT NULL DEFAULT 0,
    MyPositionPointID   TEXT,
    MyOrientationVectorID TEXT,
    CurrentCSID         TEXT,
    CurrentComponentID  TEXT,
    PreviousComponentID TEXT,
    NextComponentID     TEXT,
    MyModelID           TEXT,
    CurrentConfigurationID TEXT,
    MyPartID            TEXT,
    CurrentInterfaceID  TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Sketch (
    SketchID    TEXT PRIMARY KEY,
    Version     TEXT,
    IsTwoD      INTEGER NOT NULL DEFAULT 0,
    AreaParameterID         TEXT,
    PerimeterLengthParameterID TEXT,
    MyModelID               TEXT,
    MySketchPlaneID         TEXT,
    CurrentPointID          TEXT,
    CurrentSegmentID        TEXT,
    PreviousSegmentID       TEXT,
    CurrentParameterID      TEXT,
    CurrentDimensionID      TEXT,
    CurrentConstraintID     TEXT,
    CurrentCoordinateSystemID TEXT,
    BaseCoordinateSystemID  TEXT
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
    CurrentModelID          TEXT,
    CurrentCoordinateSystemID TEXT,
    CurrentSketchID         TEXT,
    CurrentFeatureID        TEXT,
    CurrentBodyID           TEXT,
    CurrentDrawingID        TEXT,
    CurrentDimensionID      TEXT,
    CurrentParameterID      TEXT,
    MyAssemblyID            TEXT,
    CurrentLibraryID        TEXT,
    CurrentInterfaceID      TEXT
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

CREATE TABLE IF NOT EXISTS MathParameter (
    MathParameterID     TEXT PRIMARY KEY,
    Name                TEXT,
    PartNumber          TEXT,
    Description         TEXT,
    Comments            TEXT,
    MyParameterType     INTEGER NOT NULL DEFAULT 0,
    SolidWorksParameterName     TEXT,
    Fusion360ParameterName      TEXT,
    CurrentDimensionID  TEXT,
    CurrentModelID      TEXT,
    MyUnitsID           TEXT,
    DesignTableID       TEXT,
    ExpressionText      TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Configuration (
    ConfigurationID TEXT PRIMARY KEY,
    Name            TEXT,
    Description     TEXT,
    ID              TEXT,
    Revision        TEXT,
    CurrentPartID   TEXT,
    CurrentPartRowID TEXT,
    MyAssemblyID    TEXT
);

CREATE TABLE IF NOT EXISTS SE_Table (
    SE_TableID                  TEXT PRIMARY KEY,
    Name                        TEXT,
    ID                          TEXT,
    MyTableType                 INTEGER NOT NULL DEFAULT 0,
    CurrentFigureNumber         INTEGER NOT NULL DEFAULT 0,
    VerticalReadDirectionDown   INTEGER NOT NULL DEFAULT 1,
    HorizontalReadDirectonRtL   INTEGER NOT NULL DEFAULT 1,
    HasHeader                   INTEGER NOT NULL DEFAULT 0,
    NumRows                     INTEGER NOT NULL DEFAULT 0,
    NumColumns                  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Quadrilateral (
    QuadrilateralID TEXT PRIMARY KEY,
    Name            TEXT,
    Description     TEXT,
    Vertex1PointID  TEXT,
    Vertex2PointID  TEXT,
    Vertex3PointID  TEXT,
    Vertex4PointID  TEXT,
    FOREIGN KEY (Vertex1PointID) REFERENCES Point(PointID),
    FOREIGN KEY (Vertex2PointID) REFERENCES Point(PointID),
    FOREIGN KEY (Vertex3PointID) REFERENCES Point(PointID),
    FOREIGN KEY (Vertex4PointID) REFERENCES Point(PointID)
);

-- ============================================================
-- CAD_ConstructionGeometry
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_ConstructionGeometry (
    ConstructionGeometryID  TEXT PRIMARY KEY,   -- synthetic key
    Name                    TEXT,
    Version                 TEXT NOT NULL DEFAULT '1.0',
    GeometryType            INTEGER NOT NULL DEFAULT 0,
    -- ConstructionGeometryTypeEnum: 0=Point,1=Line,2=Plane,3=Circle

    -- Ownership
    MyCAD_ModelID   TEXT,

    FOREIGN KEY (MyCAD_ModelID) REFERENCES CAD_Model(ModelID)
);

-- ============================================================
-- CAD_DrawingElement (base table — for RevisionTable and DrawingElements)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingElement (
    DrawingElementID    TEXT PRIMARY KEY,       -- synthetic key
    Name                TEXT,
    MyType              INTEGER NOT NULL DEFAULT 7,
    -- DrawingElementType: 0=DrawingView,1=Dimension,2=Table,3=BoM,
    -- 4=PMI,5=ConstructionGeometry,6=Note,7=Other

    MyDrawingID     TEXT,

    -- Current construction geometry
    CurrentConstructionGeometryID TEXT,

    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- CAD_DrawingElement -> MyConstructionGeometry
CREATE TABLE IF NOT EXISTS CAD_DrawingElement_ConstructionGeometry (
    DrawingElementID        TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingElementID, ConstructionGeometryID),
    FOREIGN KEY (DrawingElementID)      REFERENCES CAD_DrawingElement(DrawingElementID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- CAD_DrawingView (extends CAD_DrawingElement)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingView (
    DrawingViewID   TEXT PRIMARY KEY,
    -- Inherited from CAD_DrawingElement
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 0,    -- DrawingElementType.DrawingView = 0
    MyDrawingID     TEXT,
    CurrentConstructionGeometryID TEXT,

    -- CAD_DrawingView specific
    ID              TEXT,
    Title           TEXT,
    Description     TEXT,
    ViewType        INTEGER NOT NULL DEFAULT 9,
    -- ViewType: 0=OrthoTop,1=OrthoFront,2=OrthoRightSide,3=OrthoBottom,
    -- 4=OrthoBack,5=OrthoLeftSide,6=Isometric,7=CrossSection,8=Detail,9=Other

    CenterPointID       TEXT,
    ViewRectangleID     TEXT,

    FOREIGN KEY (CenterPointID)     REFERENCES Point(PointID),
    FOREIGN KEY (ViewRectangleID)   REFERENCES Quadrilateral(QuadrilateralID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- CAD_DrawingNote
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingNote (
    DrawingNoteID   TEXT PRIMARY KEY,
    NoteText        TEXT,
    MyNoteType      INTEGER NOT NULL DEFAULT 0,
    -- NoteType: 0=General,1=Safety,2=Process,3=Material,
    -- 4=Finish,5=Reference,6=Tolerance,7=Other
    CONSTRAINT chk_note_type CHECK (MyNoteType BETWEEN 0 AND 7)
);

-- ============================================================
-- CAD_DrawingPMI (extends CAD_DrawingElement)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingPMI (
    DrawingPMI_ID   TEXT PRIMARY KEY,
    -- Inherited from CAD_DrawingElement
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 4,    -- DrawingElementType.PMI = 4
    MyDrawingID     TEXT,
    CurrentConstructionGeometryID TEXT,

    -- CAD_DrawingPMI specific
    Is3D            INTEGER NOT NULL DEFAULT 0,    -- bool
    PmiType         INTEGER NOT NULL DEFAULT 4,
    -- PmiType: 0=Gdt,1=Welding,2=Hole,3=SurfaceFinish,4=Other

    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- SE_TableColumn (referenced by CAD_DrawingTable)
-- ============================================================

CREATE TABLE IF NOT EXISTS SE_TableColumn (
    SE_TableColumnID    TEXT PRIMARY KEY,       -- synthetic key
    ColumnName          TEXT,
    Description         TEXT,
    ColumnIndex         INTEGER NOT NULL DEFAULT 0,
    SE_TableID          TEXT,
    FOREIGN KEY (SE_TableID) REFERENCES SE_Table(SE_TableID)
);

-- ============================================================
-- CAD_DrawingTable (extends CAD_DrawingElement)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingTable (
    DrawingTableID  TEXT PRIMARY KEY,
    -- Inherited from CAD_DrawingElement
    Name            TEXT,
    MyType          INTEGER NOT NULL DEFAULT 2,    -- DrawingElementType.Table = 2
    MyDrawingID     TEXT,
    CurrentConstructionGeometryID TEXT,

    -- Title block column references
    DrawingNumberColumnID   TEXT,
    DrawingTitleColumnID    TEXT,
    DrawingStandardColumnID TEXT,
    DrawingSizeColumnID     TEXT,
    ReleaseDateColumnID     TEXT,
    PartNumberColumnID      TEXT,
    NextAssemblyColumnID    TEXT,
    RevisionColumnID        TEXT,

    -- Backing table
    TableID                 TEXT,

    -- Configuration
    CurrentConfigurationID  TEXT,

    FOREIGN KEY (DrawingNumberColumnID)   REFERENCES SE_TableColumn(SE_TableColumnID),
    FOREIGN KEY (DrawingTitleColumnID)    REFERENCES SE_TableColumn(SE_TableColumnID),
    FOREIGN KEY (DrawingStandardColumnID) REFERENCES SE_TableColumn(SE_TableColumnID),
    FOREIGN KEY (DrawingSizeColumnID)     REFERENCES SE_TableColumn(SE_TableColumnID),
    FOREIGN KEY (ReleaseDateColumnID)     REFERENCES SE_TableColumn(SE_TableColumnID),
    FOREIGN KEY (PartNumberColumnID)      REFERENCES SE_TableColumn(SE_TableColumnID),
    FOREIGN KEY (NextAssemblyColumnID)    REFERENCES SE_TableColumn(SE_TableColumnID),
    FOREIGN KEY (RevisionColumnID)        REFERENCES SE_TableColumn(SE_TableColumnID),
    FOREIGN KEY (TableID)                 REFERENCES SE_Table(SE_TableID),
    FOREIGN KEY (CurrentConfigurationID)  REFERENCES CAD_Configuration(ConfigurationID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- CAD_DrawingTable -> Configurations
CREATE TABLE IF NOT EXISTS CAD_DrawingTable_Configuration (
    DrawingTableID  TEXT NOT NULL,
    ConfigurationID TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingTableID, ConfigurationID),
    FOREIGN KEY (DrawingTableID)  REFERENCES CAD_DrawingTable(DrawingTableID),
    FOREIGN KEY (ConfigurationID) REFERENCES CAD_Configuration(ConfigurationID)
);

-- ============================================================
-- CAD_BoM (extends CAD_DrawingElement)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_BoM (
    BoMID       TEXT PRIMARY KEY,
    Name        TEXT,
    MyType      INTEGER NOT NULL DEFAULT 3,
    MyDrawingID TEXT,
    BoMType     INTEGER,
    CurrentConfigurationID  TEXT,
    DrawingBoMTableID       TEXT,
    FOREIGN KEY (CurrentConfigurationID) REFERENCES CAD_Configuration(ConfigurationID)
);

-- ============================================================
-- CAD_DrawingSheet
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingSheet (
    SheetID             TEXT PRIMARY KEY,
    SheetNumber         INTEGER NOT NULL DEFAULT 1,
    Size                INTEGER NOT NULL DEFAULT 4,
    -- DrawingSize: 0=E,1=D,2=C,3=B,4=A,5=A1,6=A2,7=A3
    SheetOrientation    INTEGER NOT NULL DEFAULT 0,
    -- Orientation: 0=Landscape,1=Portrait

    -- Ownership
    MyDrawingID     TEXT,
    MyBoMID         TEXT,

    -- Cursors
    CurrentDrawingViewID            TEXT,
    CurrentDimensionID              TEXT,
    CurrentDrawingNoteID            TEXT,
    CurrentConstructionGeometryID   TEXT,
    CurrentPMI_ID                   TEXT,
    CurrentDrawingTableID           TEXT,

    FOREIGN KEY (MyBoMID)                       REFERENCES CAD_BoM(BoMID),
    FOREIGN KEY (CurrentDrawingViewID)          REFERENCES CAD_DrawingView(DrawingViewID),
    FOREIGN KEY (CurrentDimensionID)            REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CurrentDrawingNoteID)          REFERENCES CAD_DrawingNote(DrawingNoteID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID),
    FOREIGN KEY (CurrentPMI_ID)                 REFERENCES CAD_DrawingPMI(DrawingPMI_ID),
    FOREIGN KEY (CurrentDrawingTableID)         REFERENCES CAD_DrawingTable(DrawingTableID)
);

-- CAD_DrawingSheet -> DrawingViews
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_View (
    SheetID         TEXT NOT NULL,
    DrawingViewID   TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DrawingViewID),
    FOREIGN KEY (SheetID)       REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DrawingViewID) REFERENCES CAD_DrawingView(DrawingViewID)
);

-- CAD_DrawingSheet -> Dimensions
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_Dimension (
    SheetID     TEXT NOT NULL,
    DimensionID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DimensionID),
    FOREIGN KEY (SheetID)     REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
);

-- CAD_DrawingSheet -> DrawingNotes
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_Note (
    SheetID         TEXT NOT NULL,
    DrawingNoteID   TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DrawingNoteID),
    FOREIGN KEY (SheetID)       REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DrawingNoteID) REFERENCES CAD_DrawingNote(DrawingNoteID)
);

-- CAD_DrawingSheet -> ConstructionGeometry
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_ConstructionGeometry (
    SheetID                 TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, ConstructionGeometryID),
    FOREIGN KEY (SheetID)                REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- CAD_DrawingSheet -> PMI
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_PMI (
    SheetID         TEXT NOT NULL,
    DrawingPMI_ID   TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DrawingPMI_ID),
    FOREIGN KEY (SheetID)       REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DrawingPMI_ID) REFERENCES CAD_DrawingPMI(DrawingPMI_ID)
);

-- CAD_DrawingSheet -> DrawingTables
CREATE TABLE IF NOT EXISTS CAD_DrawingSheet_Table (
    SheetID         TEXT NOT NULL,
    DrawingTableID  TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (SheetID, DrawingTableID),
    FOREIGN KEY (SheetID)        REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (DrawingTableID) REFERENCES CAD_DrawingTable(DrawingTableID)
);

-- ============================================================
-- CAD_Drawing  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Drawing (
    DrawingID       TEXT PRIMARY KEY,

    -- Identification
    Title           TEXT,
    DrawingNumber   TEXT,
    Revision        TEXT,

    -- Data
    DrawingStandard INTEGER NOT NULL DEFAULT 0,    -- DrawingStandardEnum: 0=ANSI
    MyFormat        INTEGER NOT NULL DEFAULT 0,    -- DocFormatEnum: 0=CAD_File,1=DWG,2=PDF,3=PNG,4=JPG,5=Other
    MyDrawingSize   INTEGER NOT NULL DEFAULT 4,    -- DrawingSize: 0=E,1=D,2=C,3=B,4=A,5=A1,6=A2,7=A3

    -- Cursors
    CurrentCAD_DrawingSheetID   TEXT,
    CurrentElementID            TEXT,
    RevisionTableID             TEXT,              -- CAD_DrawingElement used as revision table
    CurrentSketchID             TEXT,
    CurrentViewID               TEXT,
    CurrentPartID               TEXT,
    CurrentParameterID          TEXT,
    CurrentDimensionID          TEXT,
    CurrentConstructionGeometryID TEXT,

    -- Associations
    MyAssemblyID    TEXT,
    MyModelID       TEXT,

    FOREIGN KEY (CurrentCAD_DrawingSheetID) REFERENCES CAD_DrawingSheet(SheetID),
    FOREIGN KEY (CurrentElementID)          REFERENCES CAD_DrawingElement(DrawingElementID),
    FOREIGN KEY (RevisionTableID)           REFERENCES CAD_DrawingElement(DrawingElementID),
    FOREIGN KEY (CurrentSketchID)           REFERENCES CAD_Sketch(SketchID),
    FOREIGN KEY (CurrentViewID)             REFERENCES CAD_DrawingView(DrawingViewID),
    FOREIGN KEY (CurrentPartID)             REFERENCES CAD_Part(PartID),
    FOREIGN KEY (CurrentParameterID)        REFERENCES MathParameter(MathParameterID),
    FOREIGN KEY (CurrentDimensionID)        REFERENCES CAD_Dimension(DimensionID),
    FOREIGN KEY (CurrentConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID),
    FOREIGN KEY (MyAssemblyID)              REFERENCES CAD_Assembly(AssemblyID),
    FOREIGN KEY (MyModelID)                 REFERENCES CAD_Model(ModelID)
);

-- ============================================================
-- CAD_Drawing collection junction tables
-- ============================================================

-- MyDrawingSheets (List<CAD_DrawingSheet>)
CREATE TABLE IF NOT EXISTS CAD_Drawing_Sheet (
    DrawingID   TEXT NOT NULL,
    SheetID     TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, SheetID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (SheetID)   REFERENCES CAD_DrawingSheet(SheetID)
);

-- DrawingElements (List<CAD_DrawingElement>)
CREATE TABLE IF NOT EXISTS CAD_Drawing_Element (
    DrawingID           TEXT NOT NULL,
    DrawingElementID    TEXT NOT NULL,
    SortOrder           INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, DrawingElementID),
    FOREIGN KEY (DrawingID)        REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (DrawingElementID) REFERENCES CAD_DrawingElement(DrawingElementID)
);

-- MyCAD_Sketches (List<CAD_Sketch>)
CREATE TABLE IF NOT EXISTS CAD_Drawing_Sketch (
    DrawingID   TEXT NOT NULL,
    SketchID    TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, SketchID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (SketchID)  REFERENCES CAD_Sketch(SketchID)
);

-- MyViews (List<CAD_DrawingView>)
CREATE TABLE IF NOT EXISTS CAD_Drawing_View (
    DrawingID       TEXT NOT NULL,
    DrawingViewID   TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, DrawingViewID),
    FOREIGN KEY (DrawingID)     REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (DrawingViewID) REFERENCES CAD_DrawingView(DrawingViewID)
);

-- MyParts (List<CAD_Part>)
CREATE TABLE IF NOT EXISTS CAD_Drawing_Part (
    DrawingID   TEXT NOT NULL,
    PartID      TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, PartID),
    FOREIGN KEY (DrawingID) REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (PartID)    REFERENCES CAD_Part(PartID)
);

-- MyParameters (List<Parameter>)
CREATE TABLE IF NOT EXISTS CAD_Drawing_Parameter (
    DrawingID       TEXT NOT NULL,
    MathParameterID TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, MathParameterID),
    FOREIGN KEY (DrawingID)       REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (MathParameterID) REFERENCES MathParameter(MathParameterID)
);

-- MyDimensions (List<Dimension>)
CREATE TABLE IF NOT EXISTS CAD_Drawing_Dimension (
    DrawingID   TEXT NOT NULL,
    DimensionID TEXT NOT NULL,
    SortOrder   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, DimensionID),
    FOREIGN KEY (DrawingID)   REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (DimensionID) REFERENCES CAD_Dimension(DimensionID)
);

-- MyConstructionGeometry (List<CAD_ConstructionGeometery>)
CREATE TABLE IF NOT EXISTS CAD_Drawing_ConstructionGeometry (
    DrawingID               TEXT NOT NULL,
    ConstructionGeometryID  TEXT NOT NULL,
    SortOrder               INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (DrawingID, ConstructionGeometryID),
    FOREIGN KEY (DrawingID)              REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (ConstructionGeometryID) REFERENCES CAD_ConstructionGeometry(ConstructionGeometryID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_drawing_title            ON CAD_Drawing(Title);
CREATE INDEX IF NOT EXISTS idx_drawing_number           ON CAD_Drawing(DrawingNumber);
CREATE INDEX IF NOT EXISTS idx_drawing_revision         ON CAD_Drawing(Revision);
CREATE INDEX IF NOT EXISTS idx_drawing_format           ON CAD_Drawing(MyFormat);
CREATE INDEX IF NOT EXISTS idx_drawing_size             ON CAD_Drawing(MyDrawingSize);
CREATE INDEX IF NOT EXISTS idx_drawing_model            ON CAD_Drawing(MyModelID);
CREATE INDEX IF NOT EXISTS idx_drawing_assembly         ON CAD_Drawing(MyAssemblyID);
CREATE INDEX IF NOT EXISTS idx_sheet_drawing            ON CAD_DrawingSheet(MyDrawingID);
CREATE INDEX IF NOT EXISTS idx_sheet_number             ON CAD_DrawingSheet(SheetNumber);
CREATE INDEX IF NOT EXISTS idx_view_type                ON CAD_DrawingView(ViewType);
CREATE INDEX IF NOT EXISTS idx_view_drawing             ON CAD_DrawingView(MyDrawingID);
CREATE INDEX IF NOT EXISTS idx_note_type                ON CAD_DrawingNote(MyNoteType);
CREATE INDEX IF NOT EXISTS idx_pmi_type                 ON CAD_DrawingPMI(PmiType);
CREATE INDEX IF NOT EXISTS idx_pmi_is3d                 ON CAD_DrawingPMI(Is3D);
CREATE INDEX IF NOT EXISTS idx_cg_type                  ON CAD_ConstructionGeometry(GeometryType);
CREATE INDEX IF NOT EXISTS idx_cg_model                 ON CAD_ConstructionGeometry(MyCAD_ModelID);
CREATE INDEX IF NOT EXISTS idx_dt_table                 ON CAD_DrawingTable(TableID);
CREATE INDEX IF NOT EXISTS idx_dt_config                ON CAD_DrawingTable(CurrentConfigurationID);
CREATE INDEX IF NOT EXISTS idx_element_type             ON CAD_DrawingElement(MyType);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: CAD_Drawing with model/assembly info and child counts
CREATE VIEW IF NOT EXISTS v_CAD_Drawing_Detail AS
SELECT
    d.DrawingID,
    d.Title,
    d.DrawingNumber,
    d.Revision,
    d.DrawingStandard,
    CASE d.DrawingStandard
        WHEN 0 THEN 'ANSI'
    END AS DrawingStandardText,
    d.MyFormat,
    CASE d.MyFormat
        WHEN 0 THEN 'CAD_File'
        WHEN 1 THEN 'DWG'
        WHEN 2 THEN 'PDF'
        WHEN 3 THEN 'PNG'
        WHEN 4 THEN 'JPG'
        WHEN 5 THEN 'Other'
    END AS FormatText,
    d.MyDrawingSize,
    CASE d.MyDrawingSize
        WHEN 0 THEN 'E'  WHEN 1 THEN 'D'  WHEN 2 THEN 'C'
        WHEN 3 THEN 'B'  WHEN 4 THEN 'A'  WHEN 5 THEN 'A1'
        WHEN 6 THEN 'A2' WHEN 7 THEN 'A3'
    END AS DrawingSizeText,

    -- Model
    m.Name          AS ModelName,
    m.CAD_AppName   AS ModelApp,

    -- Assembly
    asm.Name        AS AssemblyName,

    -- Child counts
    (SELECT COUNT(*) FROM CAD_Drawing_Sheet  ds  WHERE ds.DrawingID  = d.DrawingID) AS SheetCount,
    (SELECT COUNT(*) FROM CAD_Drawing_Element de WHERE de.DrawingID  = d.DrawingID) AS ElementCount,
    (SELECT COUNT(*) FROM CAD_Drawing_Sketch dsk WHERE dsk.DrawingID = d.DrawingID) AS SketchCount,
    (SELECT COUNT(*) FROM CAD_Drawing_View   dv  WHERE dv.DrawingID  = d.DrawingID) AS ViewCount,
    (SELECT COUNT(*) FROM CAD_Drawing_Part   dp  WHERE dp.DrawingID  = d.DrawingID) AS PartCount,
    (SELECT COUNT(*) FROM CAD_Drawing_Parameter dpr WHERE dpr.DrawingID = d.DrawingID) AS ParameterCount,
    (SELECT COUNT(*) FROM CAD_Drawing_Dimension ddm WHERE ddm.DrawingID = d.DrawingID) AS DimensionCount,
    (SELECT COUNT(*) FROM CAD_Drawing_ConstructionGeometry dcg WHERE dcg.DrawingID = d.DrawingID) AS ConstructionGeomCount

FROM CAD_Drawing d
LEFT JOIN CAD_Model m       ON d.MyModelID    = m.ModelID
LEFT JOIN CAD_Assembly asm  ON d.MyAssemblyID = asm.AssemblyID;

-- View: Drawing sheets with their views
CREATE VIEW IF NOT EXISTS v_CAD_Drawing_SheetViews AS
SELECT
    d.DrawingID,
    d.Title             AS DrawingTitle,
    d.DrawingNumber,
    s.SheetID,
    s.SheetNumber,
    CASE s.Size
        WHEN 0 THEN 'E'  WHEN 1 THEN 'D'  WHEN 2 THEN 'C'
        WHEN 3 THEN 'B'  WHEN 4 THEN 'A'  WHEN 5 THEN 'A1'
        WHEN 6 THEN 'A2' WHEN 7 THEN 'A3'
    END AS SheetSize,
    CASE s.SheetOrientation
        WHEN 0 THEN 'Landscape'
        WHEN 1 THEN 'Portrait'
    END AS Orientation,
    sv.SortOrder        AS ViewOrder,
    v.DrawingViewID,
    v.Title             AS ViewTitle,
    v.ViewType,
    CASE v.ViewType
        WHEN 0 THEN 'OrthoTop'       WHEN 1 THEN 'OrthoFront'
        WHEN 2 THEN 'OrthoRightSide' WHEN 3 THEN 'OrthoBottom'
        WHEN 4 THEN 'OrthoBack'      WHEN 5 THEN 'OrthoLeftSide'
        WHEN 6 THEN 'Isometric'      WHEN 7 THEN 'CrossSection'
        WHEN 8 THEN 'Detail'         WHEN 9 THEN 'Other'
    END AS ViewTypeName,
    cp.X_Value          AS ViewCenter_X,
    cp.Y_Value          AS ViewCenter_Y,
    cp.Z_Value_Cartesian AS ViewCenter_Z
FROM CAD_Drawing d
JOIN CAD_Drawing_Sheet ds       ON d.DrawingID      = ds.DrawingID
JOIN CAD_DrawingSheet s         ON ds.SheetID        = s.SheetID
LEFT JOIN CAD_DrawingSheet_View sv ON s.SheetID      = sv.SheetID
LEFT JOIN CAD_DrawingView v     ON sv.DrawingViewID  = v.DrawingViewID
LEFT JOIN Point cp              ON v.CenterPointID   = cp.PointID
ORDER BY d.DrawingID, s.SheetNumber, sv.SortOrder;

-- View: Drawing notes grouped by sheet and type
CREATE VIEW IF NOT EXISTS v_CAD_Drawing_Notes AS
SELECT
    d.DrawingID,
    d.DrawingNumber,
    s.SheetID,
    s.SheetNumber,
    sn.SortOrder,
    n.DrawingNoteID,
    n.MyNoteType,
    CASE n.MyNoteType
        WHEN 0 THEN 'General'    WHEN 1 THEN 'Safety'
        WHEN 2 THEN 'Process'    WHEN 3 THEN 'Material'
        WHEN 4 THEN 'Finish'     WHEN 5 THEN 'Reference'
        WHEN 6 THEN 'Tolerance'  WHEN 7 THEN 'Other'
    END AS NoteTypeName,
    n.NoteText
FROM CAD_Drawing d
JOIN CAD_Drawing_Sheet ds       ON d.DrawingID      = ds.DrawingID
JOIN CAD_DrawingSheet s         ON ds.SheetID        = s.SheetID
JOIN CAD_DrawingSheet_Note sn   ON s.SheetID         = sn.SheetID
JOIN CAD_DrawingNote n          ON sn.DrawingNoteID  = n.DrawingNoteID
ORDER BY d.DrawingID, s.SheetNumber, sn.SortOrder;
