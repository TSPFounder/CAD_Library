
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// A solid (or surface) body composed of sketches and features.
    /// Inherits 3D operation capabilities from <see cref="CAD_Feature"/>.
    /// </summary>
    public class CAD_Body : CAD_Feature
    {
        // -----------------------------
        // Backing fields
        // -----------------------------
        private readonly List<CAD_Sketch> _sketches = new();
        private readonly List<CAD_Feature> _features = new();

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? Version { get; set; }
        public string? PartNumber { get; set; }

        // -----------------------------
        // Owned & Owning Objects
        // -----------------------------
        /// <summary>The active sketch used for the most recent/next feature.</summary>
        public CAD_Sketch? CurrentSketch { get; private set; }

        /// <summary>The active feature being edited or most recently created.</summary>
        public CAD_Feature? CurrentFeature { get; private set; }

        /// <summary>All sketches referenced by this body.</summary>
        public IReadOnlyList<CAD_Sketch> Sketches => _sketches;

        /// <summary>All features that compose this body.</summary>
        public IReadOnlyList<CAD_Feature> Features => _features;

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_Body()
        {
            // NOTE:
            // 3D operation list is inherited from CAD_Feature via ThreeDimOperations.
            // It is initialized in CAD_Feature's constructor.
        }

        // -----------------------------
        // Mutators / helpers
        // -----------------------------
        public void AddSketch(CAD_Sketch sketch, bool setCurrent = true)
        {
            if (sketch is null) throw new ArgumentNullException(nameof(sketch));
            _sketches.Add(sketch);
            if (setCurrent) CurrentSketch = sketch;
        }

        public void SetCurrentSketch(CAD_Sketch? sketch) => CurrentSketch = sketch;

        public void AddFeature(CAD_Feature feature, bool setCurrent = true)
        {
            if (feature is null) throw new ArgumentNullException(nameof(feature));
            _features.Add(feature);
            if (setCurrent) CurrentFeature = feature;
        }

        public void SetCurrentFeature(CAD_Feature? feature) => CurrentFeature = feature;

        /// <summary>
        /// Convenience helper to declare the next 3D operation this body intends to perform.
        /// Uses the inherited <see cref="CAD_Feature.Feature3DOperationEnum"/>.
        /// </summary>
        public void QueueOperation(Feature3DOperationEnum op) => ThreeDimOperations.Add(op);

        /// <summary>Clears all sketches and features (does not alter identification fields).</summary>
        public void Clear()
        {
            _sketches.Clear();
            _features.Clear();
            CurrentSketch = null;
            CurrentFeature = null;
            ThreeDimOperations.Clear();
        }

        // JSON Serialization
        public new string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static new CAD_Body? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Body>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Body"/> from a SQLite database whose schema matches
        /// <c>CAD_Body_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="bodyId">The <c>BodyID</c> value of the body row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Body"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Body? FromSql(SQLiteConnection connection, string bodyId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(bodyId)) throw new ArgumentException("Body ID must not be empty.", nameof(bodyId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Body row
            // ----------------------------------------------------------
            const string bodyQuery =
                "SELECT BodyID, Name, Version, PartNumber, GeometricFeatureType, " +
                "       MyModelID, OriginCSysID, CurrentSketchID, CurrentFeatureID, " +
                "       Base_CurrentDimensionID, Base_CurrentFeatureID, " +
                "       Base_CurrentCAD_SketchID, Base_CurrentCAD_StationID, Base_CurrentLibraryID " +
                "FROM CAD_Body WHERE BodyID = @id;";

            CAD_Body? body = null;
            string? modelId = null;
            string? originCsId = null;
            string? currentSketchId = null;
            string? currentFeatureId = null;
            string? baseCurDimId = null;
            string? baseCurFeatureId = null;
            string? baseCurSketchId = null;
            string? baseCurStationId = null;
            string? baseCurLibId = null;

            using (var cmd = new SQLiteCommand(bodyQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", bodyId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                body = new CAD_Body
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    PartNumber = reader["PartNumber"] as string,
                    GeometricFeatureType = (GeometricFeatureTypeEnum)Convert.ToInt32(reader["GeometricFeatureType"])
                };

                modelId = reader["MyModelID"] as string;
                originCsId = reader["OriginCSysID"] as string;
                currentSketchId = reader["CurrentSketchID"] as string;
                currentFeatureId = reader["CurrentFeatureID"] as string;
                baseCurDimId = reader["Base_CurrentDimensionID"] as string;
                baseCurFeatureId = reader["Base_CurrentFeatureID"] as string;
                baseCurSketchId = reader["Base_CurrentCAD_SketchID"] as string;
                baseCurStationId = reader["Base_CurrentCAD_StationID"] as string;
                baseCurLibId = reader["Base_CurrentLibraryID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyModel (inherited from CAD_Feature)
            // ----------------------------------------------------------
            if (modelId != null)
            {
                body.MyModel = LoadModel(connection, modelId);
            }

            // ----------------------------------------------------------
            // 3. Load Origin coordinate system (inherited from CAD_Feature)
            // ----------------------------------------------------------
            if (originCsId != null)
            {
                body.Origin = LoadCoordinateSystem(connection, originCsId);
            }

            // ----------------------------------------------------------
            // 4. Load Body's own Sketches from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Body_Sketch", "BodyID", bodyId, "SketchID",
                id =>
                {
                    var s = LoadSketch(connection, id);
                    if (s != null)
                    {
                        bool isCurrent = id == currentSketchId;
                        body.AddSketch(s, setCurrent: isCurrent);
                    }
                });
            // If CurrentSketch wasn't set via junction, load it explicitly
            if (currentSketchId != null && body.CurrentSketch == null)
            {
                var cs = LoadSketch(connection, currentSketchId);
                if (cs != null) body.SetCurrentSketch(cs);
            }

            // ----------------------------------------------------------
            // 5. Load Body's own Features from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Body_Feature", "BodyID", bodyId, "FeatureID",
                id =>
                {
                    var f = LoadFeature(connection, id);
                    if (f != null)
                    {
                        bool isCurrent = id == currentFeatureId;
                        body.AddFeature(f, setCurrent: isCurrent);
                    }
                });
            if (currentFeatureId != null && body.CurrentFeature == null)
            {
                var cf = LoadFeature(connection, currentFeatureId);
                if (cf != null) body.SetCurrentFeature(cf);
            }

            // ----------------------------------------------------------
            // 6. Load inherited ThreeDimOperations from junction table
            // ----------------------------------------------------------
            {
                const string opsQuery =
                    "SELECT Operation FROM CAD_Body_3DOperation " +
                    "WHERE BodyID = @id ORDER BY SortOrder;";
                using var cmd = new SQLiteCommand(opsQuery, connection);
                cmd.Parameters.AddWithValue("@id", bodyId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    body.ThreeDimOperations.Add(
                        (Feature3DOperationEnum)Convert.ToInt32(reader["Operation"]));
                }
            }

            // ----------------------------------------------------------
            // 7. Load inherited MyDimensions from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Body_Dimension", "BodyID", bodyId, "DimensionID",
                id =>
                {
                    var d = LoadDimension(connection, id);
                    if (d != null)
                    {
                        body.MyDimensions.Add(d);
                        if (id == baseCurDimId) body.CurrentDimension = d;
                    }
                });

            // ----------------------------------------------------------
            // 8. Load inherited base Sketches from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Body_BaseSketch", "BodyID", bodyId, "SketchID",
                id =>
                {
                    var s = LoadSketch(connection, id);
                    if (s != null)
                    {
                        ((CAD_Feature)body).Sketches.Add(s);
                        if (id == baseCurSketchId) body.CurrentCAD_Sketch = s;
                    }
                });

            // ----------------------------------------------------------
            // 9. Load inherited Stations from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Body_Station", "BodyID", bodyId, "StationID",
                id =>
                {
                    var st = LoadStation(connection, id);
                    if (st != null)
                    {
                        body.Stations.Add(st);
                        if (id == baseCurStationId) body.CurrentCAD_Station = st;
                    }
                });

            // ----------------------------------------------------------
            // 10. Load inherited base MyFeatures (sub-features) from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Body_BaseSubFeature", "BodyID", bodyId, "ChildFeatureID",
                id =>
                {
                    var f = LoadFeature(connection, id);
                    if (f != null)
                    {
                        body.MyFeatures.Add(f);
                        if (id == baseCurFeatureId) body.CurrentFeature = f;
                    }
                });

            // ----------------------------------------------------------
            // 11. Load inherited MyLibraries from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Body_Library", "BodyID", bodyId, "LibraryID",
                id =>
                {
                    var lib = LoadLibrary(connection, id);
                    if (lib != null)
                    {
                        body.MyLibraries.Add(lib);
                        if (id == baseCurLibId) body.CurrentLibrary = lib;
                    }
                });

            return body;
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

        private static CoordinateSystem? LoadCoordinateSystem(SQLiteConnection connection, string csId)
        {
            const string query =
                "SELECT CoordinateSystemID, Name, OriginLocationPointID " +
                "FROM CoordinateSystem WHERE CoordinateSystemID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", csId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            string? originId = reader["OriginLocationPointID"] as string;
            Point? origin = originId != null ? LoadPoint(connection, originId) : null;

            var csys = new CoordinateSystem();
            if (origin != null) csys.OriginLocation = origin;

            return csys;
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

        private static Mathematics.Vector? LoadVector(SQLiteConnection connection, string vectorId)
        {
            const string query =
                "SELECT VectorID, Name, X_Value, Y_Value, Z_Value, StartPointID, EndPointID " +
                "FROM Vector WHERE VectorID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", vectorId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            string? startPtId = reader["StartPointID"] as string;
            string? endPtId = reader["EndPointID"] as string;

            var startPt = startPtId != null ? LoadPoint(connection, startPtId) : new Point();
            var endPt = endPtId != null ? LoadPoint(connection, endPtId) : new Point();

            return new Mathematics.Vector(startPt!, endPt!)
            {
                X_Value = Convert.ToDouble(reader["X_Value"]),
                Y_Value = Convert.ToDouble(reader["Y_Value"]),
                Z_Value = Convert.ToDouble(reader["Z_Value"])
            };
        }

        private static CAD_Sketch? LoadSketch(SQLiteConnection connection, string sketchId)
        {
            const string query =
                "SELECT SketchID, Version, IsTwoD " +
                "FROM CAD_Sketch WHERE SketchID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", sketchId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Sketch
            {
                SketchID = sketchId,
                Version = reader["Version"] as string,
                IsTwoD = Convert.ToInt32(reader["IsTwoD"]) != 0
            };
        }

        private static CAD_Feature? LoadFeature(SQLiteConnection connection, string featureId)
        {
            const string query =
                "SELECT FeatureID, Name, Version, GeometricFeatureType " +
                "FROM CAD_Feature WHERE FeatureID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", featureId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Feature
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                GeometricFeatureType = (GeometricFeatureTypeEnum)Convert.ToInt32(reader["GeometricFeatureType"])
            };
        }

        private static Dimension? LoadDimension(SQLiteConnection connection, string dimensionId)
        {
            const string query =
                "SELECT DimensionID, Name, Description, IsOrdinate, " +
                "       DimensionNominalValue, DimensionUpperLimitValue, DimensionLowerLimitValue, " +
                "       MyDimensionType " +
                "FROM CAD_Dimension WHERE DimensionID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", dimensionId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Dimension
            {
                DimensionID = reader["DimensionID"] as string ?? "",
                Name = reader["Name"] as string ?? "",
                Description = reader["Description"] as string ?? "",
                IsOrdinate = Convert.ToInt32(reader["IsOrdinate"]) != 0,
                DimensionNominalValue = Convert.ToDouble(reader["DimensionNominalValue"]),
                DimensionUpperLimitValue = Convert.ToDouble(reader["DimensionUpperLimitValue"]),
                DimensionLowerLimitValue = Convert.ToDouble(reader["DimensionLowerLimitValue"]),
                MyDimensionType = (Dimension.DimensionType)Convert.ToInt32(reader["MyDimensionType"])
            };
        }

        private static CAD_Station? LoadStation(SQLiteConnection connection, string stationId)
        {
            const string query =
                "SELECT StationID, Name, ID, Version, MyType, " +
                "       AxialLocation, RadialLocation, AngularLocation, WingLocation, FloorLocation " +
                "FROM CAD_Station WHERE StationID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", stationId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            var stationType = (CAD_Station.StationTypeEnum)Convert.ToInt32(reader["MyType"]);
            double locationValue = stationType switch
            {
                CAD_Station.StationTypeEnum.Axial => Convert.ToDouble(reader["AxialLocation"]),
                CAD_Station.StationTypeEnum.Radial => Convert.ToDouble(reader["RadialLocation"]),
                CAD_Station.StationTypeEnum.Angular => Convert.ToDouble(reader["AngularLocation"]),
                CAD_Station.StationTypeEnum.Wing => Convert.ToDouble(reader["WingLocation"]),
                _ => 0.0
            };

            return new CAD_Station(reader["ID"] as string ?? "", stationType, locationValue)
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string
            };
        }

        private static CAD_Library? LoadLibrary(SQLiteConnection connection, string libraryId)
        {
            const string query =
                "SELECT LibraryID, Name, Description, LocalPath, Url " +
                "FROM CAD_Library WHERE LibraryID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", libraryId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            string? urlStr = reader["Url"] as string;
            return new CAD_Library
            {
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                LocalPath = reader["LocalPath"] as string,
                Url = urlStr != null ? new Uri(urlStr) : null
            };
        }
    }
}

