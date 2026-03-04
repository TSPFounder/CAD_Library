
using CAD_Library;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using static CAD.CAD_DrawingElement;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Bill of Materials (BoM) drawing element.
    /// Specializes <see cref="CAD_DrawingTable"/> and tracks configurations and a BoM-specific table reference.
    /// </summary>
    public class CAD_BoM : CAD_DrawingElement
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum BoM_TypeEnum
        {
            Design = 0,
            Manufacturing,
            Estimating,
            Other
        }

        // -----------------------------
        // State
        // -----------------------------
        private readonly List<CAD_Configuration> _configurations = new();

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_BoM()
        {
            MyType = DrawingElementType.BoM;
        }

        // -----------------------------
        // Properties
        // -----------------------------
        /// <summary>Optional classification for this BoM.</summary>
        public BoM_TypeEnum? BoMType { get; set; }

        /// <summary>The configuration currently used to generate this BoM (if any).</summary>
        public CAD_Configuration? CurrentConfiguration { get; set; }

        /// <summary>All configurations associated with this BoM.</summary>
        public IReadOnlyList<CAD_Configuration> Configurations => _configurations;

        /// <summary>Optional pointer to a BoM-dedicated drawing table definition.</summary>
        public CAD_DrawingBoM_Table? DrawingBoMTable { get; set; }

        // -----------------------------
        // Helpers
        // -----------------------------
        /// <summary>Add a configuration if it's not already present.</summary>
        public bool AddConfiguration(CAD_Configuration configuration)
        {
            if (configuration is null) throw new ArgumentNullException(nameof(configuration));
            if (_configurations.Contains(configuration)) return false;
            _configurations.Add(configuration);
            return true;
        }

        /// <summary>Remove a configuration.</summary>
        public bool RemoveConfiguration(CAD_Configuration configuration)
            => configuration is not null && _configurations.Remove(configuration);

        /// <summary>Clear all configurations.</summary>
        public void ClearConfigurations() => _configurations.Clear();

        // JSON Serialization
        public new string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static new CAD_BoM? FromJson(string json) => JsonConvert.DeserializeObject<CAD_BoM>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_BoM"/> from a SQLite database whose schema matches
        /// <c>CAD_BoM_Schema.sql</c>.
        /// </summary>
        public static new CAD_BoM? FromSql(SQLiteConnection connection, string bomId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(bomId)) throw new ArgumentException("BoM ID must not be empty.", nameof(bomId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_BoM row
            // ----------------------------------------------------------
            const string query =
                "SELECT BoMID, Name, MyType, MyDrawingID, CurrentConstructionGeometryID, " +
                "       BoMType, CurrentConfigurationID, DrawingBoMTableID " +
                "FROM CAD_BoM WHERE BoMID = @id;";

            CAD_BoM? bom = null;
            string? drawingId = null;
            string? curCgId = null;
            string? curConfigId = null;
            string? bomTableId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", bomId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                bom = new CAD_BoM
                {
                    Name = reader["Name"] as string,
                    MyType = (DrawingElementType)Convert.ToInt32(reader["MyType"])
                };

                if (reader["BoMType"] is not DBNull)
                    bom.BoMType = (BoM_TypeEnum)Convert.ToInt32(reader["BoMType"]);

                drawingId = reader["MyDrawingID"] as string;
                curCgId = reader["CurrentConstructionGeometryID"] as string;
                curConfigId = reader["CurrentConfigurationID"] as string;
                bomTableId = reader["DrawingBoMTableID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load inherited MyDrawing
            // ----------------------------------------------------------
            if (drawingId != null)
            {
                bom.MyDrawing = LoadDrawing(connection, drawingId);
            }

            // ----------------------------------------------------------
            // 3. Load CurrentConfiguration
            // ----------------------------------------------------------
            if (curConfigId != null)
            {
                bom.CurrentConfiguration = LoadConfiguration(connection, curConfigId);
            }

            // ----------------------------------------------------------
            // 4. Load DrawingBoMTable
            // ----------------------------------------------------------
            if (bomTableId != null)
            {
                bom.DrawingBoMTable = LoadDrawingBoMTable(connection, bomTableId);
            }

            // ----------------------------------------------------------
            // 5. Load Configurations from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_BoM_Configuration", "BoMID", bomId, "ConfigurationID",
                id =>
                {
                    var config = LoadConfiguration(connection, id);
                    if (config != null) bom.AddConfiguration(config);
                });

            // ----------------------------------------------------------
            // 6. Load inherited MyConstructionGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_BoM_ConstructionGeometry", "BoMID", bomId, "ConstructionGeometryID",
                id =>
                {
                    var cg = LoadConstructionGeometry(connection, id);
                    if (cg != null)
                    {
                        bom.MyConstructionGeometry.Add(cg);
                        if (id == curCgId) bom.CurrentConstructionGeometry = cg;
                    }
                });

            // If CurrentConstructionGeometry wasn't in the junction table, load directly
            if (curCgId != null && bom.CurrentConstructionGeometry == null)
            {
                bom.CurrentConstructionGeometry = LoadConstructionGeometry(connection, curCgId);
            }

            return bom;
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
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                Revision = reader["Revision"] as string
            };
        }

        private static CAD_DrawingBoM_Table? LoadDrawingBoMTable(SQLiteConnection connection, string bomTableId)
        {
            const string query =
                "SELECT DrawingBoMTableID, Name, MyDrawingID " +
                "FROM CAD_DrawingBoM_Table WHERE DrawingBoMTableID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", bomTableId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            string? drawingId = reader["MyDrawingID"] as string;
            CAD_Drawing? drawing = drawingId != null ? LoadDrawing(connection, drawingId) : null;

            return new CAD_DrawingBoM_Table(
                drawing ?? new CAD_Drawing(),
                reader["Name"] as string ?? "");
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
