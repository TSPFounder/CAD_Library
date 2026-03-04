
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using static CAD.CAD_DrawingElement;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Drawing Bill-of-Materials (BoM) table element.
    /// Wraps a generic drawing table with BoM-specific columns and rows.
    /// </summary>
    public class CAD_DrawingBoM_Table : CAD_DrawingElement
    {
        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_DrawingBoM_Table(CAD_Drawing drawing, string name)
        {
            //MyType = DrawingElementType.Table;
            MyDrawing = drawing ?? throw new ArgumentNullException(nameof(drawing));
            MyTable = new SE_Table(name ?? throw new ArgumentNullException(nameof(name)));
            _configurations = new List<CAD_Configuration>();
            _bomRows = new List<SE_TableRow>();
        }

        // -----------------------------
        // Ownership
        // -----------------------------
        /// <summary>The drawing that owns this BoM table.</summary>
        public CAD_Drawing MyDrawing { get; set; }

        // -----------------------------
        // Configurations
        // -----------------------------
        private readonly List<CAD_Configuration> _configurations;
        public CAD_Configuration? CurrentConfiguration { get; set; }
        public IReadOnlyList<CAD_Configuration> MyConfigurations => _configurations;

        // -----------------------------
        // Underlying data table
        // -----------------------------
        /// <summary>Backed data table for the BoM.</summary>
        public SE_Table MyTable { get; set; }

        // -----------------------------
        // Columns (optional references to typed columns)
        // -----------------------------
        public SE_TableColumn? ItemNumberColumn { get; set; }
        public SE_TableColumn? PartNumberColumn { get; set; }
        public SE_TableColumn? DrawingNumberColumn { get; set; }
        public SE_TableColumn? RevisionColumn { get; set; }
        public SE_TableColumn? QuantityColumn { get; set; }
        public SE_TableColumn? DescriptionColumn { get; set; }
        public SE_TableColumn? MaterialColumn { get; set; }
        public SE_TableColumn? SpecificationColumn { get; set; }

        // -----------------------------
        // Rows
        // -----------------------------
        public SE_TableRow? HeaderRow { get; set; }
        public SE_TableRow? PartRow { get; set; } // convenience handle for last/active row

        private readonly List<SE_TableRow> _bomRows;
        public IReadOnlyList<SE_TableRow> MyBoMRows => _bomRows;

        // -----------------------------
        // Metadata
        // -----------------------------
        public string? ChangeOrderID { get; set; }

        // -----------------------------
        // Placement on sheet (optional)
        // -----------------------------
        public Point? MyLocation { get; set; }

        // -----------------------------
        // Helpers
        // -----------------------------
        /// <summary>Add a configuration reference to this BoM (no duplicates).</summary>
        public bool AddConfiguration(CAD_Configuration cfg)
        {
            if (cfg is null) throw new ArgumentNullException(nameof(cfg));
            if (_configurations.Contains(cfg)) return false;
            _configurations.Add(cfg);
            return true;
        }

        /// <summary>Create and append a new row to the BoM and return it.</summary>
        public SE_TableRow AddRow()
        {
            var row = new SE_TableRow(MyTable);
            _bomRows.Add(row);
            PartRow = row;
            return row;
        }

        /// <summary>Remove a row from the BoM.</summary>
        public bool RemoveRow(SE_TableRow row)
            => row is not null && _bomRows.Remove(row);

        /// <summary>Clear all rows from the BoM (columns remain unchanged).</summary>
        public void ClearRows() => _bomRows.Clear();

        /// <summary>
        /// Ensure a column reference exists by name; if not present in the table, create it.
        /// Returns the column reference.
        /// </summary>
        public SE_TableColumn EnsureColumn(ref SE_TableColumn? slot, string name, Type systemType)
        {
            /*
            if (slot is not null) return slot;

            var existing = MyTable.FindColumn(name);
            if (existing is not null)
            {
                slot = existing;
                return existing;
            }
             */
            var col = new SE_TableColumn
            {
                ColumnName = name,
               // ColumnTypeEnum = systemType
            };
            MyTable.AddColumn(col);

            slot = col;
            return col;
        }

        // JSON Serialization
        public new string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static new CAD_DrawingBoM_Table? FromJson(string json) => JsonConvert.DeserializeObject<CAD_DrawingBoM_Table>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingBoM_Table"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingBoM_Table_Schema.sql</c>.
        /// </summary>
        public static new CAD_DrawingBoM_Table? FromSql(SQLiteConnection connection, string bomTableId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(bomTableId)) throw new ArgumentException("BoM table ID must not be empty.", nameof(bomTableId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_DrawingBoM_Table row
            // ----------------------------------------------------------
            const string query =
                "SELECT DrawingBoMTableID, Name, MyType, MyDrawingID, CurrentConstructionGeometryID, " +
                "       MyTableID, CurrentConfigurationID, " +
                "       ItemNumberColumnID, PartNumberColumnID, DrawingNumberColumnID, " +
                "       RevisionColumnID, QuantityColumnID, DescriptionColumnID, " +
                "       MaterialColumnID, SpecificationColumnID, " +
                "       HeaderRowID, PartRowID, ChangeOrderID, MyLocationPointID " +
                "FROM CAD_DrawingBoM_Table WHERE DrawingBoMTableID = @id;";

            string? name = null;
            string? drawingId = null;
            string? curCgId = null;
            string? myTableId = null;
            string? curConfigId = null;
            string? itemNumColId = null;
            string? partNumColId = null;
            string? drawingNumColId = null;
            string? revisionColId = null;
            string? quantityColId = null;
            string? descriptionColId = null;
            string? materialColId = null;
            string? specificationColId = null;
            string? headerRowId = null;
            string? partRowId = null;
            string? changeOrderId = null;
            string? locationPtId = null;
            int myType = 0;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", bomTableId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                name = reader["Name"] as string;
                myType = Convert.ToInt32(reader["MyType"]);
                drawingId = reader["MyDrawingID"] as string;
                curCgId = reader["CurrentConstructionGeometryID"] as string;
                myTableId = reader["MyTableID"] as string;
                curConfigId = reader["CurrentConfigurationID"] as string;
                itemNumColId = reader["ItemNumberColumnID"] as string;
                partNumColId = reader["PartNumberColumnID"] as string;
                drawingNumColId = reader["DrawingNumberColumnID"] as string;
                revisionColId = reader["RevisionColumnID"] as string;
                quantityColId = reader["QuantityColumnID"] as string;
                descriptionColId = reader["DescriptionColumnID"] as string;
                materialColId = reader["MaterialColumnID"] as string;
                specificationColId = reader["SpecificationColumnID"] as string;
                headerRowId = reader["HeaderRowID"] as string;
                partRowId = reader["PartRowID"] as string;
                changeOrderId = reader["ChangeOrderID"] as string;
                locationPtId = reader["MyLocationPointID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyDrawing (required for constructor)
            // ----------------------------------------------------------
            CAD_Drawing drawing = drawingId != null
                ? LoadDrawing(connection, drawingId) ?? new CAD_Drawing()
                : new CAD_Drawing();

            // ----------------------------------------------------------
            // 3. Construct the BoM table (constructor requires drawing + name)
            // ----------------------------------------------------------
            var bomTable = new CAD_DrawingBoM_Table(drawing, name ?? "")
            {
                MyType = (DrawingElementType)myType,
                ChangeOrderID = changeOrderId
            };

            // Override MyTable if a different backing table is specified
            if (myTableId != null)
            {
                var loadedTable = LoadTable(connection, myTableId);
                if (loadedTable != null) bomTable.MyTable = loadedTable;
            }

            // ----------------------------------------------------------
            // 4. Load 8 SE_TableColumn references
            // ----------------------------------------------------------
            if (itemNumColId != null) bomTable.ItemNumberColumn = LoadTableColumn(connection, itemNumColId);
            if (partNumColId != null) bomTable.PartNumberColumn = LoadTableColumn(connection, partNumColId);
            if (drawingNumColId != null) bomTable.DrawingNumberColumn = LoadTableColumn(connection, drawingNumColId);
            if (revisionColId != null) bomTable.RevisionColumn = LoadTableColumn(connection, revisionColId);
            if (quantityColId != null) bomTable.QuantityColumn = LoadTableColumn(connection, quantityColId);
            if (descriptionColId != null) bomTable.DescriptionColumn = LoadTableColumn(connection, descriptionColId);
            if (materialColId != null) bomTable.MaterialColumn = LoadTableColumn(connection, materialColId);
            if (specificationColId != null) bomTable.SpecificationColumn = LoadTableColumn(connection, specificationColId);

            // ----------------------------------------------------------
            // 5. Load HeaderRow and PartRow
            // ----------------------------------------------------------
            if (headerRowId != null)
            {
                bomTable.HeaderRow = LoadTableRow(connection, headerRowId, bomTable.MyTable);
            }

            if (partRowId != null)
            {
                bomTable.PartRow = LoadTableRow(connection, partRowId, bomTable.MyTable);
            }

            // ----------------------------------------------------------
            // 6. Load MyLocation point
            // ----------------------------------------------------------
            if (locationPtId != null)
            {
                bomTable.MyLocation = LoadPoint(connection, locationPtId);
            }

            // ----------------------------------------------------------
            // 7. Load MyConfigurations from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingBoMTable_Configuration", "DrawingBoMTableID", bomTableId, "ConfigurationID",
                id =>
                {
                    var config = LoadConfiguration(connection, id);
                    if (config != null)
                    {
                        bomTable.AddConfiguration(config);
                        if (id == curConfigId) bomTable.CurrentConfiguration = config;
                    }
                });

            if (curConfigId != null && bomTable.CurrentConfiguration == null)
            {
                bomTable.CurrentConfiguration = LoadConfiguration(connection, curConfigId);
            }

            // ----------------------------------------------------------
            // 8. Load MyBoMRows from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingBoMTable_Row", "DrawingBoMTableID", bomTableId, "TableRowID",
                id =>
                {
                    // AddRow() creates a new SE_TableRow backed by MyTable and appends it
                    bomTable.AddRow();
                });

            // ----------------------------------------------------------
            // 9. Load inherited MyConstructionGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingBoMTable_ConstructionGeometry", "DrawingBoMTableID", bomTableId, "ConstructionGeometryID",
                id =>
                {
                    var cg = LoadConstructionGeometry(connection, id);
                    if (cg != null)
                    {
                        bomTable.MyConstructionGeometry.Add(cg);
                        if (id == curCgId) bomTable.CurrentConstructionGeometry = cg;
                    }
                });

            if (curCgId != null && bomTable.CurrentConstructionGeometry == null)
            {
                bomTable.CurrentConstructionGeometry = LoadConstructionGeometry(connection, curCgId);
            }

            return bomTable;
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

        private static SE_TableRow? LoadTableRow(SQLiteConnection connection, string rowId, SE_Table backingTable)
        {
            const string query =
                "SELECT TableRowID, TableID " +
                "FROM SE_TableRow WHERE TableRowID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", rowId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new SE_TableRow(backingTable);
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

        private static Point? LoadPoint(SQLiteConnection connection, string pointId)
        {
            const string query =
                "SELECT PointID, X_Value, Y_Value, Z_Value_Cartesian " +
                "FROM Point WHERE PointID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", pointId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Point
            {
                X_Value = Convert.ToDouble(reader["X_Value"]),
                Y_Value = Convert.ToDouble(reader["Y_Value"]),
                Z_Value_Cartesian = Convert.ToDouble(reader["Z_Value_Cartesian"])
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

