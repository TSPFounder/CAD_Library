using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using Newtonsoft.Json;

namespace CAD
{
    public class CAD_Hole : CAD_Feature
    {
        public enum HoleGeometryTypeEnum
        {
            Straight = 0,
            CounterSink,
            CounterBore,
            Other
        }

        public CAD_Hole()
        {
            NominalDiameter = new CAD_Dimension { MyDimensionType = CAD_Dimension.DimensionType.Diameter };
            NominalDepth = new CAD_Dimension { MyDimensionType = CAD_Dimension.DimensionType.Length };
            NominalTaperAngle = new CAD_Dimension { MyDimensionType = CAD_Dimension.DimensionType.Angle };
            MyThreads = new List<Thread>();
            CenterPoint = new Point();
        }

        // General Dimensions
        public CAD_Dimension NominalDiameter { get; set; }
        public CAD_Dimension NominalDepth { get; set; }
        public CAD_Dimension NominalTaperAngle { get; set; }
        public Point CenterPoint { get; set; }

        // CounterSink
        public CAD_Dimension CounterSinkAngle { get; set; }
        public CAD_Dimension CounterSinkDepth { get; set; }

        // CounterBore
        public CAD_Dimension CounterBoreOuterDiameter { get; set; }
        public CAD_Dimension CounterBoreDepth { get; set; }

        // Keyway
        public bool HasKeyway { get; set; }
        public CAD_Feature MyKeyway { get; set; }

        // Threads
        public bool HasThreads { get; set; }
        public Thread CurrentThread { get; set; }
        public List<Thread> MyThreads { get; set; }

        // Associations
        public CAD_Feature MyFeature { get; set; }
        public CAD_Sketch MySketch { get; set; }

        // JSON Serialization
        public new string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static new CAD_Hole FromJson(string json) => JsonConvert.DeserializeObject<CAD_Hole>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Hole"/> from a SQLite database whose schema matches
        /// <c>CAD_Hole_Schema.sql</c>.
        /// </summary>
        public static new CAD_Hole? FromSql(SQLiteConnection connection, string holeId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(holeId)) throw new ArgumentException("Hole ID must not be empty.", nameof(holeId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Hole row
            // ----------------------------------------------------------
            const string query =
                "SELECT HoleID, Name, Version, GeometricFeatureType, MyModelID, OriginPointID, " +
                "       NominalDiameterID, NominalDepthID, NominalTaperAngleID, CenterPointID, " +
                "       CounterSinkAngleID, CounterSinkDepthID, " +
                "       CounterBoreOuterDiameterID, CounterBoreDepthID, " +
                "       HasKeyway, MyKeywayFeatureID, " +
                "       HasThreads, CurrentThreadID, " +
                "       MyFeatureID, MySketchID " +
                "FROM CAD_Hole WHERE HoleID = @id;";

            CAD_Hole? hole = null;
            string? modelId = null;
            string? originPtId = null;
            string? nomDiaId = null;
            string? nomDepthId = null;
            string? nomTaperId = null;
            string? centerPtId = null;
            string? csAngleId = null;
            string? csDepthId = null;
            string? cbOuterDiaId = null;
            string? cbDepthId = null;
            string? keywayFeatureId = null;
            string? curThreadId = null;
            string? myFeatureId = null;
            string? mySketchId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", holeId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                hole = new CAD_Hole
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    GeometricFeatureType = (GeometricFeatureTypeEnum)Convert.ToInt32(reader["GeometricFeatureType"]),
                    HasKeyway = Convert.ToInt32(reader["HasKeyway"]) != 0,
                    HasThreads = Convert.ToInt32(reader["HasThreads"]) != 0
                };

                modelId = reader["MyModelID"] as string;
                originPtId = reader["OriginPointID"] as string;
                nomDiaId = reader["NominalDiameterID"] as string;
                nomDepthId = reader["NominalDepthID"] as string;
                nomTaperId = reader["NominalTaperAngleID"] as string;
                centerPtId = reader["CenterPointID"] as string;
                csAngleId = reader["CounterSinkAngleID"] as string;
                csDepthId = reader["CounterSinkDepthID"] as string;
                cbOuterDiaId = reader["CounterBoreOuterDiameterID"] as string;
                cbDepthId = reader["CounterBoreDepthID"] as string;
                keywayFeatureId = reader["MyKeywayFeatureID"] as string;
                curThreadId = reader["CurrentThreadID"] as string;
                myFeatureId = reader["MyFeatureID"] as string;
                mySketchId = reader["MySketchID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load inherited CAD_Feature references
            // ----------------------------------------------------------
            if (modelId != null)
                hole.MyModel = LoadModel(connection, modelId);

            if (originPtId != null)
            {
                var originPt = LoadPoint(connection, originPtId);
                if (originPt != null)
                {
                    var csys = new CoordinateSystem();
                    csys.OriginLocation = originPt;
                    hole.Origin = csys;
                }
            }

            // ----------------------------------------------------------
            // 3. Load dimension references
            // ----------------------------------------------------------
            if (nomDiaId != null)
                hole.NominalDiameter = LoadDimension(connection, nomDiaId) ?? hole.NominalDiameter;

            if (nomDepthId != null)
                hole.NominalDepth = LoadDimension(connection, nomDepthId) ?? hole.NominalDepth;

            if (nomTaperId != null)
                hole.NominalTaperAngle = LoadDimension(connection, nomTaperId) ?? hole.NominalTaperAngle;

            if (centerPtId != null)
                hole.CenterPoint = LoadPoint(connection, centerPtId) ?? hole.CenterPoint;

            // CounterSink
            if (csAngleId != null)
                hole.CounterSinkAngle = LoadDimension(connection, csAngleId);

            if (csDepthId != null)
                hole.CounterSinkDepth = LoadDimension(connection, csDepthId);

            // CounterBore
            if (cbOuterDiaId != null)
                hole.CounterBoreOuterDiameter = LoadDimension(connection, cbOuterDiaId);

            if (cbDepthId != null)
                hole.CounterBoreDepth = LoadDimension(connection, cbDepthId);

            // ----------------------------------------------------------
            // 4. Load Keyway feature
            // ----------------------------------------------------------
            if (keywayFeatureId != null)
                hole.MyKeyway = LoadFeatureShallow(connection, keywayFeatureId);

            // ----------------------------------------------------------
            // 5. Load Threads from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Hole_Thread", "HoleID", holeId, "ThreadID",
                id =>
                {
                    var thread = LoadThread(connection, id);
                    if (thread != null)
                    {
                        hole.MyThreads.Add(thread);
                        if (id == curThreadId) hole.CurrentThread = thread;
                    }
                });

            // If CurrentThread wasn't in the junction table, load directly
            if (curThreadId != null && hole.CurrentThread == null)
            {
                var thread = LoadThread(connection, curThreadId);
                if (thread != null)
                {
                    hole.MyThreads.Add(thread);
                    hole.CurrentThread = thread;
                }
            }

            // ----------------------------------------------------------
            // 6. Load Feature / Sketch associations
            // ----------------------------------------------------------
            if (myFeatureId != null)
                hole.MyFeature = LoadFeatureShallow(connection, myFeatureId);

            if (mySketchId != null)
                hole.MySketch = LoadSketch(connection, mySketchId);

            // ----------------------------------------------------------
            // 7. Load inherited CAD_Feature junction tables
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Hole_Dimension", "HoleID", holeId, "DimensionID",
                id =>
                {
                    var d = LoadDimensionAsBase(connection, id);
                    if (d != null) hole.MyDimensions.Add(d);
                });

            LoadJunction(connection, "CAD_Hole_SubFeature", "HoleID", holeId, "SubFeatureID",
                id =>
                {
                    var f = LoadFeatureShallow(connection, id);
                    if (f != null) hole.MyFeatures.Add(f);
                });

            LoadJunction(connection, "CAD_Hole_Sketch", "HoleID", holeId, "SketchID",
                id =>
                {
                    var s = LoadSketch(connection, id);
                    if (s != null) hole.Sketches.Add(s);
                });

            LoadJunction(connection, "CAD_Hole_Station", "HoleID", holeId, "StationID",
                id =>
                {
                    var st = LoadStation(connection, id);
                    if (st != null) hole.Stations.Add(st);
                });

            LoadJunction(connection, "CAD_Hole_Library", "HoleID", holeId, "LibraryID",
                id =>
                {
                    var lib = LoadLibrary(connection, id);
                    if (lib != null) hole.MyLibraries.Add(lib);
                });

            return hole;
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

        private static CAD_Dimension? LoadDimension(SQLiteConnection connection, string dimensionId)
        {
            const string query =
                "SELECT DimensionID, Description, MyDimensionType " +
                "FROM CAD_Dimension WHERE DimensionID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", dimensionId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Dimension
            {
                DimensionID = reader["DimensionID"] as string,
                Description = reader["Description"] as string,
                MyDimensionType = (CAD_Dimension.DimensionType)Convert.ToInt32(reader["MyDimensionType"])
            };
        }

        private static Dimension? LoadDimensionAsBase(SQLiteConnection connection, string dimensionId)
        {
            const string query =
                "SELECT DimensionID, Name, Description, MyDimensionType " +
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
                MyDimensionType = (Dimension.DimensionType)Convert.ToInt32(reader["MyDimensionType"])
            };
        }

        private static CAD_Feature? LoadFeatureShallow(SQLiteConnection connection, string featureId)
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

        private static Thread? LoadThread(SQLiteConnection connection, string threadId)
        {
            const string query =
                "SELECT ThreadID, Name, Version, Designation, ThreadClass, " +
                "       MaterialSpecification, SurfaceFinish, " +
                "       IsInternal, IsFine, IsMultithreaded, IsReverseThreaded, " +
                "       IsMetric, IsSquare, Starts, ThreadStandard, CoatingThickness " +
                "FROM Thread WHERE ThreadID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", threadId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Thread
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string
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

        private static CAD_Station? LoadStation(SQLiteConnection connection, string stationId)
        {
            const string query =
                "SELECT StationID, Name, ID, Version, MyType, " +
                "       AxialLocation, RadialLocation, AngularLocation, WingLocation " +
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
