-- ============================================================
-- SQLite Schema for CAD_DrawingNote JSON mapping
-- Generated from CAD_Library: CAD_DrawingNote
-- ============================================================
-- No external dependencies (simple POCO)
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- CAD_DrawingNote  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_DrawingNote (
    DrawingNoteID   TEXT PRIMARY KEY,

    -- Content
    NoteText        TEXT,

    -- Classification
    MyNoteType      INTEGER NOT NULL DEFAULT 0,
    -- NoteType:
    --   0=General, 1=Safety, 2=Process, 3=Material,
    --   4=Finish, 5=Reference, 6=Tolerance, 7=Other
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_drawnote_type ON CAD_DrawingNote(MyNoteType);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: notes with human-readable type
CREATE VIEW IF NOT EXISTS v_CAD_DrawingNote_Detail AS
SELECT
    dn.DrawingNoteID,
    dn.NoteText,
    dn.MyNoteType,
    CASE dn.MyNoteType
        WHEN 0 THEN 'General'
        WHEN 1 THEN 'Safety'
        WHEN 2 THEN 'Process'
        WHEN 3 THEN 'Material'
        WHEN 4 THEN 'Finish'
        WHEN 5 THEN 'Reference'
        WHEN 6 THEN 'Tolerance'
        WHEN 7 THEN 'Other'
    END AS NoteTypeName,
    CASE WHEN dn.NoteText IS NULL OR TRIM(dn.NoteText) = '' THEN 1 ELSE 0 END AS IsEmpty
FROM CAD_DrawingNote dn;

-- View: notes grouped by type
CREATE VIEW IF NOT EXISTS v_CAD_DrawingNote_ByType AS
SELECT
    dn.MyNoteType,
    CASE dn.MyNoteType
        WHEN 0 THEN 'General'
        WHEN 1 THEN 'Safety'
        WHEN 2 THEN 'Process'
        WHEN 3 THEN 'Material'
        WHEN 4 THEN 'Finish'
        WHEN 5 THEN 'Reference'
        WHEN 6 THEN 'Tolerance'
        WHEN 7 THEN 'Other'
    END AS NoteTypeName,
    COUNT(*) AS NoteCount
FROM CAD_DrawingNote dn
GROUP BY dn.MyNoteType
ORDER BY dn.MyNoteType;
