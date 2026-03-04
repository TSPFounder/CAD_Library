
using System;
using System.Data;
using System.Data.SQLite;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Product & Manufacturing Information (PMI) placed on a drawing (2D or 3D).
    /// </summary>
    public sealed class CAD_DrawingPMI : CAD_DrawingElement
    {
        public enum PmiType
        {
            Gdt = 0,
            Welding,
            Hole,
            SurfaceFinish,
            Other
        }

        /// <summary>True if this PMI is attached in 3D context; otherwise 2D drawing-only.</summary>
        public bool Is3D { get; set; }

        /// <summary>Kind of PMI (GD&T, welding, etc.).</summary>
        public PmiType Type { get; set; } = PmiType.Other;

        public CAD_DrawingPMI()
        {
            MyType = DrawingElementType.PMI;
        }

        /// <summary>Create a 2D PMI of the given type.</summary>
        public static CAD_DrawingPMI Create2D(PmiType type) => new() { Is3D = false, Type = type };

        /// <summary>Create a 3D PMI of the given type.</summary>
        public static CAD_DrawingPMI Create3D(PmiType type) => new() { Is3D = true, Type = type };

        public override string ToString() => $"{(Is3D ? "3D" : "2D")} PMI ({Type})";

        // JSON Serialization
        public new string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static new CAD_DrawingPMI? FromJson(string json) => JsonConvert.DeserializeObject<CAD_DrawingPMI>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingPMI"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingPMI_Schema.sql</c>.
        /// </summary>
        public static new CAD_DrawingPMI? FromSql(SQLiteConnection connection, string pmiId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(pmiId)) throw new ArgumentException("PMI ID must not be empty.", nameof(pmiId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_DrawingPMI row
            // ----------------------------------------------------------
            const string query =
                "SELECT DrawingPMIID, Name, MyType, MyDrawingID, CurrentConstructionGeometryID, " +
                "       Is3D, PmiType " +
                "FROM CAD_DrawingPMI WHERE DrawingPMIID = @id;";

            CAD_DrawingPMI? pmi = null;
            string? drawingId = null;
            string? curCgId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", pmiId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                pmi = new CAD_DrawingPMI
                {
                    Name = reader["Name"] as string,
                    MyType = (DrawingElementType)Convert.ToInt32(reader["MyType"]),
                    Is3D = Convert.ToInt32(reader["Is3D"]) != 0,
                    Type = (PmiType)Convert.ToInt32(reader["PmiType"])
                };

                drawingId = reader["MyDrawingID"] as string;
                curCgId = reader["CurrentConstructionGeometryID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyDrawing
            // ----------------------------------------------------------
            if (drawingId != null)
            {
                pmi.MyDrawing = LoadDrawing(connection, drawingId);
            }

            // ----------------------------------------------------------
            // 3. Load MyConstructionGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingPMI_ConstructionGeometry", "DrawingPMIID", pmiId, "ConstructionGeometryID",
                id =>
                {
                    var cg = LoadConstructionGeometry(connection, id);
                    if (cg != null)
                    {
                        pmi.MyConstructionGeometry.Add(cg);
                        if (id == curCgId) pmi.CurrentConstructionGeometry = cg;
                    }
                });

            if (curCgId != null && pmi.CurrentConstructionGeometry == null)
            {
                pmi.CurrentConstructionGeometry = LoadConstructionGeometry(connection, curCgId);
            }

            return pmi;
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
