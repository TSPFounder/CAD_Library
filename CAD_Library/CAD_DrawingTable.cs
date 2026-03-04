
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Documents;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Title block / metadata table placed on a drawing.
    /// </summary>
    public sealed class CAD_DrawingTable : CAD_DrawingElement
    {
        // -----------------------------
        // Columns (commonly seen in title blocks)
        // -----------------------------
        public SE_TableColumn? DrawingNumber { get; set; }
        public SE_TableColumn? DrawingTitle { get; set; }
        public SE_TableColumn? DrawingStandard { get; set; }
        public SE_TableColumn? DrawingSize { get; set; }
        public SE_TableColumn? ReleaseDate { get; set; }
        public SE_TableColumn? PartNumber { get; set; }
        public SE_TableColumn? NextAssembly { get; set; }
        public SE_TableColumn? Revision { get; set; }

        // -----------------------------
        // Ownership / associations
        // -----------------------------
        /// <summary>The backing data table rendered on the drawing.</summary>
        public SE_Table? Table { get; set; }

        /// <summary>Active configuration selecting which values/rows appear.</summary>
        public CAD_Configuration? CurrentConfiguration { get; set; }

        /// <summary>Available configurations for this table.</summary>
        public List<CAD_Configuration> Configurations { get; } = new();

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_DrawingTable()
        {
            MyType = DrawingElementType.Table;
        }

        // -----------------------------
        // Helpers
        // -----------------------------
        /// <summary>
        /// Returns a concise display string using DrawingNumber → DrawingTitle when available.
        /// </summary>
        public override string ToString()
        {
            var num = DrawingNumber?.ColumnName ?? DrawingNumber?.Description ?? "N/A";
            var title = DrawingTitle?.ColumnName ?? DrawingTitle?.Description ?? "";
            return string.IsNullOrWhiteSpace(title) ? $"Table [{num}]" : $"Table [{num}] — {title}";
        }

        /// <summary>
        /// Convenience to set the core title-block fields at once.
        /// </summary>
        public void SetCore(
            SE_TableColumn? drawingNumber = null,
            SE_TableColumn? drawingTitle = null,
            SE_TableColumn? revision = null)
        {
            if (drawingNumber is not null) DrawingNumber = drawingNumber;
            if (drawingTitle is not null) DrawingTitle = drawingTitle;
            if (revision is not null) Revision = revision;
        }

        // JSON Serialization
        public new string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static new CAD_DrawingTable? FromJson(string json) => JsonConvert.DeserializeObject<CAD_DrawingTable>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingTable"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingTable_Schema.sql</c>.
        /// </summary>
        public static new CAD_DrawingTable? FromSql(SQLiteConnection connection, string drawingTableId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(drawingTableId)) throw new ArgumentException("Drawing table ID must not be empty.", nameof(drawingTableId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_DrawingTable row
            // ----------------------------------------------------------
            const string query =
                "SELECT DrawingTableID, Name, MyType, MyDrawingID, CurrentConstructionGeometryID, " +
                "       DrawingNumberColumnID, DrawingTitleColumnID, DrawingStandardColumnID, " +
                "       DrawingSizeColumnID, ReleaseDateColumnID, PartNumberColumnID, " +
                "       NextAssemblyColumnID, RevisionColumnID, " +
                "       TableID, CurrentConfigurationID " +
                "FROM CAD_DrawingTable WHERE DrawingTableID = @id;";

            CAD_DrawingTable? table = null;
            string? drawingId = null;
            string? curCgId = null;
            string? drawingNumberColId = null;
            string? drawingTitleColId = null;
            string? drawingStandardColId = null;
            string? drawingSizeColId = null;
            string? releaseDateColId = null;
            string? partNumberColId = null;
            string? nextAssemblyColId = null;
            string? revisionColId = null;
            string? tableId = null;
            string? curConfigId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", drawingTableId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                table = new CAD_DrawingTable
                {
                    Name = reader["Name"] as string,
                    MyType = (DrawingElementType)Convert.ToInt32(reader["MyType"])
                };

                drawingId = reader["MyDrawingID"] as string;
                curCgId = reader["CurrentConstructionGeometryID"] as string;
                drawingNumberColId = reader["DrawingNumberColumnID"] as string;
                drawingTitleColId = reader["DrawingTitleColumnID"] as string;
                drawingStandardColId = reader["DrawingStandardColumnID"] as string;
                drawingSizeColId = reader["DrawingSizeColumnID"] as string;
                releaseDateColId = reader["ReleaseDateColumnID"] as string;
                partNumberColId = reader["PartNumberColumnID"] as string;
                nextAssemblyColId = reader["NextAssemblyColumnID"] as string;
                revisionColId = reader["RevisionColumnID"] as string;
                tableId = reader["TableID"] as string;
                curConfigId = reader["CurrentConfigurationID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyDrawing
            // ----------------------------------------------------------
            if (drawingId != null)
            {
                table.MyDrawing = LoadDrawing(connection, drawingId);
            }

            // ----------------------------------------------------------
            // 3. Load 8 SE_TableColumn references
            // ----------------------------------------------------------
            if (drawingNumberColId != null) table.DrawingNumber = LoadTableColumn(connection, drawingNumberColId);
            if (drawingTitleColId != null) table.DrawingTitle = LoadTableColumn(connection, drawingTitleColId);
            if (drawingStandardColId != null) table.DrawingStandard = LoadTableColumn(connection, drawingStandardColId);
            if (drawingSizeColId != null) table.DrawingSize = LoadTableColumn(connection, drawingSizeColId);
            if (releaseDateColId != null) table.ReleaseDate = LoadTableColumn(connection, releaseDateColId);
            if (partNumberColId != null) table.PartNumber = LoadTableColumn(connection, partNumberColId);
            if (nextAssemblyColId != null) table.NextAssembly = LoadTableColumn(connection, nextAssemblyColId);
            if (revisionColId != null) table.Revision = LoadTableColumn(connection, revisionColId);

            // ----------------------------------------------------------
            // 4. Load backing SE_Table
            // ----------------------------------------------------------
            if (tableId != null)
            {
                table.Table = LoadTable(connection, tableId);
            }

            // ----------------------------------------------------------
            // 5. Load Configurations from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingTable_Configuration", "DrawingTableID", drawingTableId, "ConfigurationID",
                id =>
                {
                    var config = LoadConfiguration(connection, id);
                    if (config != null)
                    {
                        table.Configurations.Add(config);
                        if (id == curConfigId) table.CurrentConfiguration = config;
                    }
                });

            if (curConfigId != null && table.CurrentConfiguration == null)
            {
                table.CurrentConfiguration = LoadConfiguration(connection, curConfigId);
            }

            // ----------------------------------------------------------
            // 6. Load inherited MyConstructionGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingTable_ConstructionGeometry", "DrawingTableID", drawingTableId, "ConstructionGeometryID",
                id =>
                {
                    var cg = LoadConstructionGeometry(connection, id);
                    if (cg != null)
                    {
                        table.MyConstructionGeometry.Add(cg);
                        if (id == curCgId) table.CurrentConstructionGeometry = cg;
                    }
                });

            if (curCgId != null && table.CurrentConstructionGeometry == null)
            {
                table.CurrentConstructionGeometry = LoadConstructionGeometry(connection, curCgId);
            }

            return table;
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

        private static SE_TableColumn? LoadTableColumn(SQLiteConnection connection, string columnId)
        {
            const string query =
                "SELECT TableColumnID, ColumnName, ID, Description " +
                "FROM SE_TableColumn WHERE TableColumnID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", columnId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new SE_TableColumn
            {
                ColumnName = reader["ColumnName"] as string,
                ID = reader["ID"] as string,
                Description = reader["Description"] as string
            };
        }

        private static SE_Table? LoadTable(SQLiteConnection connection, string tableId)
        {
            const string query =
                "SELECT TableID, Name, Description " +
                "FROM SE_Table WHERE TableID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", tableId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new SE_Table(reader["Name"] as string ?? "");
        }

        private static CAD_Configuration? LoadConfiguration(SQLiteConnection connection, string configId)
        {
            const string query =
                "SELECT ConfigurationID, Name, Description, Revision " +
                "FROM CAD_Configuration WHERE ConfigurationID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", configId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Configuration
            {
                ID = reader["ConfigurationID"] as string,
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
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
