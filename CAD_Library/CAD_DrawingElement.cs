
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Base class for elements that can appear on a CAD drawing
    /// (views, dimensions, notes, construction geometry, etc.).
    /// </summary>
    public class CAD_DrawingElement
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum DrawingElementType
        {
            DrawingView = 0,
            Dimension,
            Table,
            BoM,
            PMI,
            ConstructionGeometry,
            Note,
            Other
        }

        // -----------------------------
        // Constructor
        // -----------------------------
        public CAD_DrawingElement()
        {
            MyConstructionGeometry = new List<CAD_ConstructionGeometery>();
        }

        // -----------------------------
        // Identification
        // -----------------------------
        /// <summary>Display name of the drawing element.</summary>
        public string? Name { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        /// <summary>Element classification.</summary>
        public DrawingElementType MyType { get; set; }

        // -----------------------------
        // Owned & Owning Objects
        // -----------------------------
        /// <summary>Owning drawing (if any).</summary>
        public CAD_Drawing? MyDrawing { get; set; }

        // -----------------------------
        // Construction Geometry
        // -----------------------------
        /// <summary>The currently active construction geometry (if any).</summary>
        public CAD_ConstructionGeometery? CurrentConstructionGeometry { get; set; }

        /// <summary>All construction geometry associated with this element.</summary>
        public List<CAD_ConstructionGeometery> MyConstructionGeometry { get; set; }

        // -----------------------------
        // Helpers (optional)
        // -----------------------------
        /// <summary>Adds a construction geometry item.</summary>
        public void AddConstructionGeometry(CAD_ConstructionGeometery geom)
        {
            if (geom is null) throw new ArgumentNullException(nameof(geom));
            MyConstructionGeometry.Add(geom);
            CurrentConstructionGeometry ??= geom;
        }

        /// <summary>Clears all construction geometry and current selection.</summary>
        public void ClearConstructionGeometry()
        {
            MyConstructionGeometry.Clear();
            CurrentConstructionGeometry = null;
        }

        public override string ToString()
            => $"DrawingElement(Name={Name ?? "<null>"}, Type={MyType}, CG Count={MyConstructionGeometry.Count})";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_DrawingElement? FromJson(string json) => JsonConvert.DeserializeObject<CAD_DrawingElement>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingElement"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingElement_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingElement? FromSql(SQLiteConnection connection, string drawingElementId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(drawingElementId)) throw new ArgumentException("Drawing element ID must not be empty.", nameof(drawingElementId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_DrawingElement row
            // ----------------------------------------------------------
            const string query =
                "SELECT DrawingElementID, Name, MyType, MyDrawingID, CurrentConstructionGeometryID " +
                "FROM CAD_DrawingElement WHERE DrawingElementID = @id;";

            CAD_DrawingElement? element = null;
            string? drawingId = null;
            string? curCgId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", drawingElementId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                element = new CAD_DrawingElement
                {
                    Name = reader["Name"] as string,
                    MyType = (DrawingElementType)Convert.ToInt32(reader["MyType"])
                };

                drawingId = reader["MyDrawingID"] as string;
                curCgId = reader["CurrentConstructionGeometryID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyDrawing
            // ----------------------------------------------------------
            if (drawingId != null)
            {
                element.MyDrawing = LoadDrawing(connection, drawingId);
            }

            // ----------------------------------------------------------
            // 3. Load MyConstructionGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingElement_ConstructionGeometry", "DrawingElementID", drawingElementId, "ConstructionGeometryID",
                id =>
                {
                    var cg = LoadConstructionGeometry(connection, id);
                    if (cg != null)
                    {
                        element.MyConstructionGeometry.Add(cg);
                        if (id == curCgId) element.CurrentConstructionGeometry = cg;
                    }
                });

            // If CurrentConstructionGeometry wasn't in the junction table, load it directly
            if (curCgId != null && element.CurrentConstructionGeometry == null)
            {
                element.CurrentConstructionGeometry = LoadConstructionGeometry(connection, curCgId);
            }

            return element;
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
    }
}
