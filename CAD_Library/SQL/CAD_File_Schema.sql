-- ============================================================
-- SQLite Schema for CAD_File JSON mapping
-- Generated from CAD_Library: CAD_File (extends Applications.AppFile)
-- ============================================================
-- Depends on shared tables from prior schemas:
--   CAD_Model, CAD_Part, CAD_Drawing, CAD_DrawingElement,
--   CAD_Configuration
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

CREATE TABLE IF NOT EXISTS CAD_Part (
    PartID      TEXT PRIMARY KEY,
    Name        TEXT,
    Version     TEXT,
    PartNumber  TEXT,
    Description TEXT
);

CREATE TABLE IF NOT EXISTS CAD_Drawing (
    DrawingID       TEXT PRIMARY KEY,
    Title           TEXT,
    DrawingNumber   TEXT,
    Revision        TEXT
);

CREATE TABLE IF NOT EXISTS CAD_DrawingElement (
    DrawingElementID    TEXT PRIMARY KEY,
    Name                TEXT,
    MyType              INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS CAD_Configuration (
    ConfigurationID TEXT PRIMARY KEY,
    Name            TEXT,
    Description     TEXT,
    Revision        TEXT,
    CurrentPartID       TEXT,
    CurrentPartRowID    TEXT,
    MyAssemblyID        TEXT
);

-- ============================================================
-- CAD_File  (main table — flattens AppFile base)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_File (
    FileID          TEXT PRIMARY KEY,          -- synthetic key

    -- Inherited from AppFile
    AppFile_Path        TEXT,
    AppFile_Name        TEXT,
    AppFile_Extension   TEXT,
    AppFile_Version     TEXT,
    AppFile_URI         TEXT,
    -- AppFile.Application stored as JSON blob (complex type)
    AppFile_ApplicationJSON TEXT,
    -- AppFile.Section (List<string>) stored as JSON array
    AppFile_SectionsJSON    TEXT,

    -- Own identification / metadata
    DisplayName     TEXT,
    FileVersion     TEXT,                      -- Version object as string

    -- Classification
    FileType        INTEGER NOT NULL DEFAULT 15,
    -- CAD_FileTypeEnum:
    --   0=stp, 1=igs, 2=stl, 3=3dm, 4=obj, 5=fbx,
    --   6=dxf, 7=dwg, 8=sat, 9=x_t, 10=x_b,
    --   11=sldprt, 12=sldasm, 13=slddrw, 14=f3d, 15=other

    SourceApplication   INTEGER NOT NULL DEFAULT 6,
    -- CAD_AppEnum:
    --   0=Fusion360, 1=Solidworks, 2=Blender, 3=UnReal4,
    --   4=UnReal5, 5=Unity, 6=Other

    -- File info
    FileSizeBytes       INTEGER,
    LastModifiedUtc     TEXT,                  -- ISO 8601 string

    -- Location state
    LocationState       INTEGER NOT NULL DEFAULT 0,
    -- FileLocationState:
    --   0=Unknown, 1=LocalOnly, 2=RemoteOnly, 3=Synchronized

    -- Locations
    LocalPath           TEXT,
    RemoteUri           TEXT,

    -- Derived flags (computed)
    HasLocalCopy        INTEGER NOT NULL DEFAULT 0,
    HasRemoteCopy       INTEGER NOT NULL DEFAULT 0,

    -- Ownership
    OwningModelID       TEXT,
    OwningPartID        TEXT,
    OwningDrawingID     TEXT,
    SourceElementID     TEXT,

    FOREIGN KEY (OwningModelID)   REFERENCES CAD_Model(ModelID),
    FOREIGN KEY (OwningPartID)    REFERENCES CAD_Part(PartID),
    FOREIGN KEY (OwningDrawingID) REFERENCES CAD_Drawing(DrawingID),
    FOREIGN KEY (SourceElementID) REFERENCES CAD_DrawingElement(DrawingElementID)
);

-- ============================================================
-- CAD_File collection junction tables
-- ============================================================

-- Configurations (IReadOnlyList<CAD_Configuration>)
CREATE TABLE IF NOT EXISTS CAD_File_Configuration (
    FileID          TEXT NOT NULL,
    ConfigurationID TEXT NOT NULL,
    SortOrder       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (FileID, ConfigurationID),
    FOREIGN KEY (FileID)           REFERENCES CAD_File(FileID),
    FOREIGN KEY (ConfigurationID)  REFERENCES CAD_Configuration(ConfigurationID)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_file_displayname     ON CAD_File(DisplayName);
CREATE INDEX IF NOT EXISTS idx_file_filetype        ON CAD_File(FileType);
CREATE INDEX IF NOT EXISTS idx_file_sourceapp       ON CAD_File(SourceApplication);
CREATE INDEX IF NOT EXISTS idx_file_locstate        ON CAD_File(LocationState);
CREATE INDEX IF NOT EXISTS idx_file_model           ON CAD_File(OwningModelID);
CREATE INDEX IF NOT EXISTS idx_file_part            ON CAD_File(OwningPartID);
CREATE INDEX IF NOT EXISTS idx_file_drawing         ON CAD_File(OwningDrawingID);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: file with all labels and ownership info
CREATE VIEW IF NOT EXISTS v_CAD_File_Detail AS
SELECT
    f.FileID,
    f.DisplayName,
    f.FileVersion,
    f.FileType,
    CASE f.FileType
        WHEN 0  THEN 'stp'     WHEN 1  THEN 'igs'
        WHEN 2  THEN 'stl'     WHEN 3  THEN '3dm'
        WHEN 4  THEN 'obj'     WHEN 5  THEN 'fbx'
        WHEN 6  THEN 'dxf'     WHEN 7  THEN 'dwg'
        WHEN 8  THEN 'sat'     WHEN 9  THEN 'x_t'
        WHEN 10 THEN 'x_b'     WHEN 11 THEN 'sldprt'
        WHEN 12 THEN 'sldasm'  WHEN 13 THEN 'slddrw'
        WHEN 14 THEN 'f3d'     WHEN 15 THEN 'other'
    END AS FileTypeName,
    f.SourceApplication,
    CASE f.SourceApplication
        WHEN 0 THEN 'Fusion360'    WHEN 1 THEN 'Solidworks'
        WHEN 2 THEN 'Blender'      WHEN 3 THEN 'UnReal4'
        WHEN 4 THEN 'UnReal5'      WHEN 5 THEN 'Unity'
        WHEN 6 THEN 'Other'
    END AS SourceAppName,
    f.FileSizeBytes,
    f.LastModifiedUtc,
    f.LocationState,
    CASE f.LocationState
        WHEN 0 THEN 'Unknown'
        WHEN 1 THEN 'LocalOnly'
        WHEN 2 THEN 'RemoteOnly'
        WHEN 3 THEN 'Synchronized'
    END AS LocationStateName,
    f.LocalPath,
    f.RemoteUri,

    -- Ownership
    m.Name      AS OwningModelName,
    p.Name      AS OwningPartName,
    p.PartNumber AS OwningPartNumber,
    d.Title     AS OwningDrawingTitle,

    -- Configuration count
    (SELECT COUNT(*) FROM CAD_File_Configuration fc
     WHERE fc.FileID = f.FileID) AS ConfigurationCount

FROM CAD_File f
LEFT JOIN CAD_Model m       ON f.OwningModelID   = m.ModelID
LEFT JOIN CAD_Part p        ON f.OwningPartID    = p.PartID
LEFT JOIN CAD_Drawing d     ON f.OwningDrawingID = d.DrawingID;

-- View: files grouped by type and application
CREATE VIEW IF NOT EXISTS v_CAD_File_ByType AS
SELECT
    f.FileType,
    CASE f.FileType
        WHEN 0  THEN 'stp'     WHEN 1  THEN 'igs'
        WHEN 2  THEN 'stl'     WHEN 3  THEN '3dm'
        WHEN 4  THEN 'obj'     WHEN 5  THEN 'fbx'
        WHEN 6  THEN 'dxf'     WHEN 7  THEN 'dwg'
        WHEN 8  THEN 'sat'     WHEN 9  THEN 'x_t'
        WHEN 10 THEN 'x_b'     WHEN 11 THEN 'sldprt'
        WHEN 12 THEN 'sldasm'  WHEN 13 THEN 'slddrw'
        WHEN 14 THEN 'f3d'     WHEN 15 THEN 'other'
    END AS FileTypeName,
    f.SourceApplication,
    CASE f.SourceApplication
        WHEN 0 THEN 'Fusion360' WHEN 1 THEN 'Solidworks'
        WHEN 2 THEN 'Blender'   WHEN 3 THEN 'UnReal4'
        WHEN 4 THEN 'UnReal5'   WHEN 5 THEN 'Unity'
        WHEN 6 THEN 'Other'
    END AS SourceAppName,
    COUNT(*) AS FileCount,
    SUM(COALESCE(f.FileSizeBytes, 0)) AS TotalSizeBytes
FROM CAD_File f
GROUP BY f.FileType, f.SourceApplication
ORDER BY f.FileType, f.SourceApplication;
