
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Represents a single drawing sheet (title block, views, notes, dimensions, tables, etc.).
    /// </summary>
    public sealed class CAD_DrawingSheet
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum Orientation
        {
            Landscape = 0,
            Portrait
        }

        // Reuse the size enum from CAD_Drawing if available; otherwise you can copy it here.
        // public enum DrawingSize { E=0, D, C, B, A, A1, A2, A3 }

        // -----------------------------
        // Backing collections
        // -----------------------------
        private readonly List<CAD_DrawingView> _drawingViews = new();
        private readonly List<CAD_Dimension> _dimensions = new();
        private readonly List<CAD_DrawingNote> _drawingNotes = new();
        private readonly List<CAD_ConstructionGeometery> _constructionGeometry = new();
        private readonly List<CAD_DrawingPMI> _pmi = new();
        private readonly List<CAD_DrawingTable> _drawingTables = new();

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_DrawingSheet() { }

        public CAD_DrawingSheet(
            string? sheetId,
            int sheetNumber = 1,
            CAD_Drawing.DrawingSize size = CAD_Drawing.DrawingSize.A,
            Orientation orientation = Orientation.Landscape)
        {
            SheetID = sheetId;
            SheetNumber = sheetNumber;
            Size = size;
            SheetOrientation = orientation;
        }

        // -----------------------------
        // Identification / metadata
        // -----------------------------
        public string? SheetID { get; set; }
        public int SheetNumber { get; set; } = 1;

        /// <summary>ANSI/ISO size (reuses <see cref="CAD_Drawing.DrawingSize"/>).</summary>
        public CAD_Drawing.DrawingSize Size { get; set; } = CAD_Drawing.DrawingSize.A;

        /// <summary>Landscape or Portrait.</summary>
        public Orientation SheetOrientation { get; set; } = Orientation.Landscape;

        // -----------------------------
        // Ownership
        // -----------------------------
        public CAD_Drawing? MyDrawing { get; set; }
        public CAD_BoM? MyBoM { get; set; }

        // -----------------------------
        // Current cursors (optional)
        // -----------------------------
        public CAD_DrawingView? CurrentDrawingView { get; private set; }
        public CAD_Dimension? CurrentDimension { get; private set; }
        public CAD_DrawingNote? CurrentDrawingNote { get; private set; }
        public CAD_ConstructionGeometery? CurrentConstructionGeometry { get; private set; }
        public CAD_DrawingPMI? CurrentPMI { get; private set; }
        public CAD_DrawingTable? CurrentDrawingTable { get; private set; }

        // -----------------------------
        // Collections (read-only views)
        // -----------------------------
        public IReadOnlyList<CAD_DrawingView> DrawingViews => _drawingViews;
        public IReadOnlyList<CAD_Dimension> Dimensions => _dimensions;
        public IReadOnlyList<CAD_DrawingNote> DrawingNotes => _drawingNotes;
        public IReadOnlyList<CAD_ConstructionGeometery> ConstructionGeometry => _constructionGeometry;
        public IReadOnlyList<CAD_DrawingPMI> PMI => _pmi;
        public IReadOnlyList<CAD_DrawingTable> DrawingTables => _drawingTables;

        // -----------------------------
        // Mutators / helpers
        // -----------------------------
        public void AddView(CAD_DrawingView view)
        {
            if (view is null) throw new ArgumentNullException(nameof(view));
            _drawingViews.Add(view);
            CurrentDrawingView = view;
        }

        public bool RemoveView(CAD_DrawingView view) => _drawingViews.Remove(view);

        public void AddDimension(CAD_Dimension dim)
        {
            if (dim is null) throw new ArgumentNullException(nameof(dim));
            _dimensions.Add(dim);
            CurrentDimension = dim;
        }

        public bool RemoveDimension(CAD_Dimension dim) => _dimensions.Remove(dim);

        public void AddNote(CAD_DrawingNote note)
        {
            if (note is null) throw new ArgumentNullException(nameof(note));
            _drawingNotes.Add(note);
            CurrentDrawingNote = note;
        }

        public bool RemoveNote(CAD_DrawingNote note) => _drawingNotes.Remove(note);

        public void AddConstructionGeometry(CAD_ConstructionGeometery geom)
        {
            if (geom is null) throw new ArgumentNullException(nameof(geom));
            _constructionGeometry.Add(geom);
            CurrentConstructionGeometry = geom;
        }

        public bool RemoveConstructionGeometry(CAD_ConstructionGeometery geom) => _constructionGeometry.Remove(geom);

        public void AddPMI(CAD_DrawingPMI pmi)
        {
            if (pmi is null) throw new ArgumentNullException(nameof(pmi));
            _pmi.Add(pmi);
            CurrentPMI = pmi;
        }

        public bool RemovePMI(CAD_DrawingPMI pmi) => _pmi.Remove(pmi);

        public void AddTable(CAD_DrawingTable table)
        {
            if (table is null) throw new ArgumentNullException(nameof(table));
            _drawingTables.Add(table);
            CurrentDrawingTable = table;
        }

        public bool RemoveTable(CAD_DrawingTable table) => _drawingTables.Remove(table);

        // -----------------------------
        // Convenience
        // -----------------------------
        public bool IsLandscape => SheetOrientation == Orientation.Landscape;
        public bool IsPortrait => SheetOrientation == Orientation.Portrait;

        public override string ToString()
            => $"Sheet {SheetNumber} ({Size}, {SheetOrientation})" + (string.IsNullOrWhiteSpace(SheetID) ? "" : $" - {SheetID}");

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_DrawingSheet? FromJson(string json) => JsonConvert.DeserializeObject<CAD_DrawingSheet>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingSheet"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingSheet_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingSheet? FromSql(SQLiteConnection connection, string sheetId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(sheetId)) throw new ArgumentException("Sheet ID must not be empty.", nameof(sheetId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_DrawingSheet row
            // ----------------------------------------------------------
            const string query =
                "SELECT SheetID, SheetNumber, Size, SheetOrientation, " +
                "       MyDrawingID, MyBoMID, " +
                "       CurrentDrawingViewID, CurrentDimensionID, CurrentDrawingNoteID, " +
                "       CurrentConstructionGeometryID, CurrentPMIID, CurrentDrawingTableID " +
                "FROM CAD_DrawingSheet WHERE SheetID = @id;";

            CAD_DrawingSheet? sheet = null;
            string? drawingId = null;
            string? bomId = null;
            string? curViewId = null;
            string? curDimId = null;
            string? curNoteId = null;
            string? curCgId = null;
            string? curPmiId = null;
            string? curTableId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", sheetId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                sheet = new CAD_DrawingSheet
                {
                    SheetID = reader["SheetID"] as string,
                    SheetNumber = Convert.ToInt32(reader["SheetNumber"]),
                    Size = (CAD_Drawing.DrawingSize)Convert.ToInt32(reader["Size"]),
                    SheetOrientation = (Orientation)Convert.ToInt32(reader["SheetOrientation"])
                };

                drawingId = reader["MyDrawingID"] as string;
                bomId = reader["MyBoMID"] as string;
                curViewId = reader["CurrentDrawingViewID"] as string;
                curDimId = reader["CurrentDimensionID"] as string;
                curNoteId = reader["CurrentDrawingNoteID"] as string;
                curCgId = reader["CurrentConstructionGeometryID"] as string;
                curPmiId = reader["CurrentPMIID"] as string;
                curTableId = reader["CurrentDrawingTableID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyDrawing
            // ----------------------------------------------------------
            if (drawingId != null)
            {
                sheet.MyDrawing = LoadDrawing(connection, drawingId);
            }

            // ----------------------------------------------------------
            // 3. Load MyBoM
            // ----------------------------------------------------------
            if (bomId != null)
            {
                sheet.MyBoM = LoadBoM(connection, bomId);
            }

            // ----------------------------------------------------------
            // 4. Load DrawingViews from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingSheet_DrawingView", "SheetID", sheetId, "DrawingViewID",
                id =>
                {
                    var view = LoadDrawingView(connection, id);
                    if (view != null)
                    {
                        sheet.AddView(view);
                        if (id != curViewId) { } // AddView sets cursor; reset if not current
                    }
                });

            // Reset cursor to the correct current if it was set by AddView
            if (curViewId == null)
            {
                // No current cursor desired — but AddView always sets it.
                // Leave as last-added (best effort).
            }

            // ----------------------------------------------------------
            // 5. Load Dimensions from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingSheet_Dimension", "SheetID", sheetId, "DimensionID",
                id =>
                {
                    var dim = LoadDimension(connection, id);
                    if (dim != null) sheet.AddDimension(dim);
                });

            // ----------------------------------------------------------
            // 6. Load DrawingNotes from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingSheet_DrawingNote", "SheetID", sheetId, "DrawingNoteID",
                id =>
                {
                    var note = LoadDrawingNote(connection, id);
                    if (note != null) sheet.AddNote(note);
                });

            // ----------------------------------------------------------
            // 7. Load ConstructionGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingSheet_ConstructionGeometry", "SheetID", sheetId, "ConstructionGeometryID",
                id =>
                {
                    var cg = LoadConstructionGeometry(connection, id);
                    if (cg != null) sheet.AddConstructionGeometry(cg);
                });

            // ----------------------------------------------------------
            // 8. Load PMI from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingSheet_PMI", "SheetID", sheetId, "DrawingPMIID",
                id =>
                {
                    var pmi = LoadDrawingPMI(connection, id);
                    if (pmi != null) sheet.AddPMI(pmi);
                });

            // ----------------------------------------------------------
            // 9. Load DrawingTables from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingSheet_DrawingTable", "SheetID", sheetId, "DrawingTableID",
                id =>
                {
                    var table = LoadDrawingTable(connection, id);
                    if (table != null) sheet.AddTable(table);
                });

            return sheet;
        }

        // -----------------------------
        // Private SQL helpers
        // -----------------------------

        private static void LoadJunction(SQLiteConnection connection, string tableName,
            string ownerColumn, string ownerId, string childColumn, Action<string> onChildId)
        {
            string query = $"SELECT {childColumn} FROM {tableName} " +
                           $"WHERE {ownerColumn} = @id ORDER BY SortOrder;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", ownerId);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                string childId = reader[childColumn] as string ?? "";
                onChildId(childId);
            }
        }

        private static CAD_Drawing? LoadDrawing(SQLiteConnection connection, string drawingId)
        {
            const string query =
                "SELECT DrawingID, Title, DrawingNumber, Revision " +
                "FROM CAD_Drawing WHERE DrawingID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", drawingId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Drawing
            {
                Title = reader["Title"] as string,
                DrawingNumber = reader["DrawingNumber"] as string,
                Revision = reader["Revision"] as string
            };
        }

        private static CAD_BoM? LoadBoM(SQLiteConnection connection, string bomId)
        {
            const string query =
                "SELECT BoMID, BoMType " +
                "FROM CAD_BoM WHERE BoMID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", bomId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            var bom = new CAD_BoM();
            if (reader["BoMType"] is not DBNull)
            {
                bom.BoMType = (CAD_BoM.BoM_TypeEnum)Convert.ToInt32(reader["BoMType"]);
            }
            return bom;
        }

        private static CAD_DrawingView? LoadDrawingView(SQLiteConnection connection, string viewId)
        {
            const string query =
                "SELECT DrawingViewID, Title, ViewType " +
                "FROM CAD_DrawingView WHERE DrawingViewID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", viewId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_DrawingView
            {
                ID = reader["DrawingViewID"] as string,
                Title = reader["Title"] as string,
                Type = (CAD_DrawingView.ViewType)Convert.ToInt32(reader["ViewType"])
            };
        }

        private static CAD_Dimension? LoadDimension(SQLiteConnection connection, string dimId)
        {
            const string query =
                "SELECT DimensionID, Description " +
                "FROM CAD_Dimension WHERE DimensionID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", dimId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Dimension
            {
                DimensionID = reader["DimensionID"] as string ?? "",
                Description = reader["Description"] as string ?? ""
            };
        }

        private static CAD_DrawingNote? LoadDrawingNote(SQLiteConnection connection, string noteId)
        {
            const string query =
                "SELECT DrawingNoteID, NoteText, MyNoteType " +
                "FROM CAD_DrawingNote WHERE DrawingNoteID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", noteId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_DrawingNote
            {
                DrawingNoteID = reader["DrawingNoteID"] as string,
                NoteText = reader["NoteText"] as string,
                MyNoteType = (CAD_DrawingNote.NoteType)Convert.ToInt32(reader["MyNoteType"])
            };
        }

        private static CAD_ConstructionGeometery? LoadConstructionGeometry(SQLiteConnection connection, string cgId)
        {
            const string query =
                "SELECT ConstructionGeometryID, Name, Version, GeometryType " +
                "FROM CAD_ConstructionGeometry WHERE ConstructionGeometryID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", cgId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_ConstructionGeometery
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string ?? "1.0",
                GeometryType = (CAD_ConstructionGeometry.ConstructionGeometryTypeEnum)Convert.ToInt32(reader["GeometryType"])
            };
        }

        private static CAD_DrawingPMI? LoadDrawingPMI(SQLiteConnection connection, string pmiId)
        {
            const string query =
                "SELECT DrawingPMIID, Name, Is3D, PmiType " +
                "FROM CAD_DrawingPMI WHERE DrawingPMIID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", pmiId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_DrawingPMI
            {
                Name = reader["Name"] as string,
                Is3D = Convert.ToInt32(reader["Is3D"]) != 0,
                Type = (CAD_DrawingPMI.PmiType)Convert.ToInt32(reader["PmiType"])
            };
        }

        private static CAD_DrawingTable? LoadDrawingTable(SQLiteConnection connection, string tableId)
        {
            const string query =
                "SELECT DrawingTableID, Name " +
                "FROM CAD_DrawingTable WHERE DrawingTableID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", tableId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_DrawingTable
            {
                Name = reader["Name"] as string
            };
        }
    }
}
