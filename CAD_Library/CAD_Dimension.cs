using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    public class CAD_Dimension : CAD_DrawingElement
    {
        public enum DimensionType
        {
            Length = 0,
            Diameter,
            Radius,
            Angle,
            Distance,
            Ordinal,
            Other
        }

        public CAD_Dimension()
        {
            MyType = DrawingElementType.Dimension;
            CenterPoint = new Point();
        }

        // Identification
        public string DimensionID { get; set; }
        public string Description { get; set; }
        public bool IsOrdinate { get; set; }

        // Geometry / Locating Points
        public Point CenterPoint { get; set; }
        public Point LeaderLineEndPoint { get; set; }
        public Point LeaderLineBendPoint { get; set; }
        public Point DimensionPoint { get; set; }
        public Point ReferencePoint { get; set; }

        // Associations
        public CAD_Model MyModel { get; set; }
        public Segment MySegment { get; set; }

        // Dimension Values
        public double DimensionNominalValue { get; set; }
        public double DimensionUpperLimitValue { get; set; }
        public double DimensionLowerLimitValue { get; set; }
        public DimensionType MyDimensionType { get; set; }
        public UnitOfMeasure EngineeringUnit { get; set; }

        // Parameters
        public CAD_Parameter CurrentParameter { get; set; }
        public List<CAD_Parameter> MyParameters { get; set; }

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Dimension FromJson(string json) => JsonConvert.DeserializeObject<CAD_Dimension>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Dimension"/> from a SQLite database whose schema matches
        /// <c>CAD_Dimension_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="dimensionId">The <c>DimensionID</c> value of the dimension row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Dimension"/>, or <c>null</c> if the ID was not found.</returns>
        public static new CAD_Dimension? FromSql(SQLiteConnection connection, string dimensionId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(dimensionId)) throw new ArgumentException("Dimension ID must not be empty.", nameof(dimensionId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Dimension row
            // ----------------------------------------------------------
            const string dimQuery =
                "SELECT DimensionID, Name, MyType, Description, IsOrdinate, " +
                "       CenterPointID, LeaderLineEndPointID, LeaderLineBendPointID, " +
                "       DimensionPointID, ReferencePointID, " +
                "       MyModelID, MySegmentID, " +
                "       DimensionNominalValue, DimensionUpperLimitValue, DimensionLowerLimitValue, " +
                "       MyDimensionType, EngineeringUnitID, CurrentParameterID " +
                "FROM CAD_Dimension WHERE DimensionID = @id;";

            CAD_Dimension? dim = null;
            string? centerPtId = null;
            string? leaderEndPtId = null;
            string? leaderBendPtId = null;
            string? dimPtId = null;
            string? refPtId = null;
            string? modelId = null;
            string? segmentId = null;
            string? unitId = null;
            string? curParamId = null;

            using (var cmd = new SQLiteCommand(dimQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", dimensionId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                dim = new CAD_Dimension
                {
                    DimensionID = reader["DimensionID"] as string ?? "",
                    Name = reader["Name"] as string ?? "",
                    MyType = (DrawingElementType)Convert.ToInt32(reader["MyType"]),
                    Description = reader["Description"] as string ?? "",
                    IsOrdinate = Convert.ToInt32(reader["IsOrdinate"]) != 0,
                    DimensionNominalValue = Convert.ToDouble(reader["DimensionNominalValue"]),
                    DimensionUpperLimitValue = Convert.ToDouble(reader["DimensionUpperLimitValue"]),
                    DimensionLowerLimitValue = Convert.ToDouble(reader["DimensionLowerLimitValue"]),
                    MyDimensionType = (DimensionType)Convert.ToInt32(reader["MyDimensionType"]),
                    MyParameters = new List<CAD_Parameter>()
                };

                centerPtId = reader["CenterPointID"] as string;
                leaderEndPtId = reader["LeaderLineEndPointID"] as string;
                leaderBendPtId = reader["LeaderLineBendPointID"] as string;
                dimPtId = reader["DimensionPointID"] as string;
                refPtId = reader["ReferencePointID"] as string;
                modelId = reader["MyModelID"] as string;
                segmentId = reader["MySegmentID"] as string;
                unitId = reader["EngineeringUnitID"] as string;
                curParamId = reader["CurrentParameterID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load geometry points
            // ----------------------------------------------------------
            if (centerPtId != null)
                dim.CenterPoint = LoadPoint(connection, centerPtId) ?? new Point();

            if (leaderEndPtId != null)
                dim.LeaderLineEndPoint = LoadPoint(connection, leaderEndPtId)!;

            if (leaderBendPtId != null)
                dim.LeaderLineBendPoint = LoadPoint(connection, leaderBendPtId)!;

            if (dimPtId != null)
                dim.DimensionPoint = LoadPoint(connection, dimPtId)!;

            if (refPtId != null)
                dim.ReferencePoint = LoadPoint(connection, refPtId)!;

            // ----------------------------------------------------------
            // 3. Load MyModel
            // ----------------------------------------------------------
            if (modelId != null)
            {
                dim.MyModel = LoadModel(connection, modelId)!;
            }

            // ----------------------------------------------------------
            // 4. Load MySegment
            // ----------------------------------------------------------
            if (segmentId != null)
            {
                dim.MySegment = LoadSegment(connection, segmentId)!;
            }

            // ----------------------------------------------------------
            // 5. Load EngineeringUnit
            // ----------------------------------------------------------
            if (unitId != null)
            {
                dim.EngineeringUnit = LoadUnitOfMeasure(connection, unitId)!;
            }

            // ----------------------------------------------------------
            // 6. Load MyParameters from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Dimension_Parameter", "DimensionID", dimensionId, "ParameterID",
                id =>
                {
                    var p = LoadCAD_Parameter(connection, id);
                    if (p != null)
                    {
                        dim.MyParameters.Add(p);
                        if (id == curParamId) dim.CurrentParameter = p;
                    }
                });

            // If CurrentParameter wasn't in the junction table, load it directly
            if (curParamId != null && dim.CurrentParameter == null)
            {
                dim.CurrentParameter = LoadCAD_Parameter(connection, curParamId)!;
            }

            // ----------------------------------------------------------
            // 7. Load inherited MyConstructionGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Dimension_ConstructionGeometry", "DimensionID", dimensionId, "ConstructionGeometryID",
                id =>
                {
                    var cg = LoadConstructionGeometry(connection, id);
                    if (cg != null) dim.MyConstructionGeometry.Add(cg);
                });

            return dim;
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

        private static CAD_Model? LoadModel(SQLiteConnection connection, string modelId)
        {
            const string query =
                "SELECT ModelID, Name, Version, Description, FilePath, " +
                "       CAD_AppName, ModelType, FileType " +
                "FROM CAD_Model WHERE ModelID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", modelId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Model
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                Description = reader["Description"] as string,
                FilePath = reader["FilePath"] as string,
                CAD_AppName = (CAD_Model.CAD_AppEnum)Convert.ToInt32(reader["CAD_AppName"]),
                ModelType = (CAD_Model.CAD_ModelTypeEnum)Convert.ToInt32(reader["ModelType"]),
                FileType = (CAD_Model.CAD_FileTypeEnum)Convert.ToInt32(reader["FileType"])
            };
        }

        private static Segment? LoadSegment(SQLiteConnection connection, string segmentId)
        {
            const string query =
                "SELECT SegmentID, SegmentType, IsEdge, Length, StartPointID, EndPointID, MidPointID " +
                "FROM Segment WHERE SegmentID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", segmentId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            var seg = new Segment
            {
                SegmentID = reader["SegmentID"] as string
            };

            string? startPtId = reader["StartPointID"] as string;
            string? endPtId = reader["EndPointID"] as string;
            string? midPtId = reader["MidPointID"] as string;

            if (startPtId != null) seg.StartPoint = LoadPoint(connection, startPtId);
            if (endPtId != null) seg.EndPoint = LoadPoint(connection, endPtId);
            if (midPtId != null) seg.MidPoint = LoadPoint(connection, midPtId);

            return seg;
        }

        private static UnitOfMeasure? LoadUnitOfMeasure(SQLiteConnection connection, string unitId)
        {
            const string query =
                "SELECT UnitOfMeasureID, Name, Description, SymbolName, UnitValue, SystemOfUnits, IsBaseUnit " +
                "FROM UnitOfMeasure WHERE UnitOfMeasureID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", unitId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new UnitOfMeasure
            {
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                SymbolName = reader["SymbolName"] as string
            };
        }

        private static CAD_Parameter? LoadCAD_Parameter(SQLiteConnection connection, string paramId)
        {
            const string query =
                "SELECT Id, Name, Description, Comments, MyParameterType, " +
                "       SolidWorksParameterName, Fusion360ParameterName " +
                "FROM CAD_Parameter WHERE Id = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", paramId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Parameter
            {
                Id = reader["Id"] as string,
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                Comments = reader["Comments"] as string,
                MyParameterType = (CAD_Parameter.ParameterType)Convert.ToInt32(reader["MyParameterType"]),
                SolidWorksParameterName = reader["SolidWorksParameterName"] as string,
                Fusion360ParameterName = reader["Fusion360ParameterName"] as string
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
