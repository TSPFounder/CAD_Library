-- ============================================================
-- SQLite Schema for CAD_Library (class) JSON mapping
-- Generated from CAD_Library: CAD_Library (sealed class)
-- ============================================================
-- Note: This schema is for the CAD_Library *class* (content
-- library descriptor), not the CAD_Library project/namespace.
-- ============================================================
-- No external dependencies (simple POCO)
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- CAD_Library  (main table)
-- ============================================================

CREATE TABLE IF NOT EXISTS CAD_Library (
    LibraryID       TEXT PRIMARY KEY,          -- synthetic key

    -- Identification
    Name            TEXT,
    Description     TEXT,

    -- Locations
    LocalPath       TEXT,
    Url             TEXT,                      -- stored as string from Uri

    -- Derived flags (computed at insert/update time)
    HasLocalPath    INTEGER NOT NULL DEFAULT 0,    -- bool
    HasRemoteUrl    INTEGER NOT NULL DEFAULT 0,    -- bool
    IsConfigured    INTEGER NOT NULL DEFAULT 0     -- bool (name + at least one location)
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_library_name       ON CAD_Library(Name);
CREATE INDEX IF NOT EXISTS idx_library_configured ON CAD_Library(IsConfigured);

-- ============================================================
-- Views
-- ============================================================

-- Flat view: library with location status
CREATE VIEW IF NOT EXISTS v_CAD_Library_Detail AS
SELECT
    l.LibraryID,
    l.Name,
    l.Description,
    l.LocalPath,
    l.Url,
    l.HasLocalPath,
    l.HasRemoteUrl,
    l.IsConfigured,
    CASE
        WHEN l.HasLocalPath = 1 AND l.HasRemoteUrl = 1 THEN 'Local+Remote'
        WHEN l.HasLocalPath = 1 THEN 'LocalOnly'
        WHEN l.HasRemoteUrl = 1 THEN 'RemoteOnly'
        ELSE 'Unconfigured'
    END AS LocationStatus
FROM CAD_Library l;
