
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    public class CAD_Feature
    {
        // -----------------------------
        // Enums (unchanged)
        // -----------------------------
        public enum GeometricFeatureTypeEnum
        {
            Hole = 0,
            Joint,
            Thread,
            Chamfer,
            Fillet,
            CounterBore,
            CounterSink,
            Bead,
            Boss,
            Keyway,
            Leg,
            Arm,
            Mirror,
            Embossment,
            Rib,
            RoundedSlot,
            Gusset,
            Taper,
            SquareSlot,
            Shell,
            Web,
            Tab,
            Coil,
            Helicoil,
            RectangularPattern,
            CircularPattern,
            OtherPattern,
            Other
        }

        public enum Feature3DOperationEnum
        {
            Extrude = 0,
            Revolve,
            Sweep,
            Loft
        }

        // -----------------------------
        // Constructor
        // -----------------------------
        public CAD_Feature()
        {
            ThreeDimOperations = new List<Feature3DOperationEnum>();
            MyDimensions = new List<Dimension>();
            Sketches = new List<CAD_Sketch>();
            Stations = new List<CAD_Station>();
            MyFeatures = new List<CAD_Feature>();
            MyLibraries = new List<CAD_Library>();
        }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? Version { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        public GeometricFeatureTypeEnum GeometricFeatureType { get; set; }

        // -----------------------------
        // Dimensions
        // -----------------------------
        public Dimension? CurrentDimension { get; set; }
        public List<Dimension> MyDimensions { get; set; }

        // -----------------------------
        // Owned & Owning Objects
        // -----------------------------
        public CAD_Feature? CurrentFeature { get; set; }
        public List<CAD_Feature> MyFeatures { get; set; }

        // -----------------------------
        // Sketches
        // -----------------------------
        public CAD_Sketch? CurrentCAD_Sketch { get; set; }
        public List<CAD_Sketch> Sketches { get; set; }

        // -----------------------------
        // Stations
        // -----------------------------
        public CAD_Station? CurrentCAD_Station { get; set; }
        public List<CAD_Station> Stations { get; set; }

        // -----------------------------
        // Model & CSYS
        // -----------------------------
        public CAD_Model? MyModel { get; set; }
        public CoordinateSystem? Origin { get; set; }

        // -----------------------------
        // 3-D Operations
        // -----------------------------
        public List<Feature3DOperationEnum> ThreeDimOperations { get; set; }

        // -----------------------------
        // Libraries
        // -----------------------------
        public CAD_Library? CurrentLibrary { get; set; }
        public List<CAD_Library> MyLibraries { get; set; }

        // -----------------------------
        // Methods (kept, with minor polish)
        // -----------------------------
        public bool CreateHole()
        {
            try
            {
                // placeholder for implementation
                return true;
            }
            catch
            {
                return false;
            }
        }

        // -----------------------------
        // Helpers (optional)
        // -----------------------------
        public void AddDimension(Dimension dim)
        {
            if (dim is null) throw new ArgumentNullException(nameof(dim));
            MyDimensions.Add(dim);
            CurrentDimension ??= dim;
        }

        public void AddSketch(CAD_Sketch sketch)
        {
            if (sketch is null) throw new ArgumentNullException(nameof(sketch));
            Sketches.Add(sketch);
            CurrentCAD_Sketch ??= sketch;
        }

        public void AddStation(CAD_Station station)
        {
            if (station is null) throw new ArgumentNullException(nameof(station));
            Stations.Add(station);
            CurrentCAD_Station ??= station;
        }

        public void AddFeature(CAD_Feature feature)
        {
            if (feature is null) throw new ArgumentNullException(nameof(feature));
            MyFeatures.Add(feature);
            CurrentFeature ??= feature;
        }

        public void AddLibrary(CAD_Library lib)
        {
            if (lib is null) throw new ArgumentNullException(nameof(lib));
            MyLibraries.Add(lib);
            CurrentLibrary ??= lib;
        }

        public override string ToString()
            => $"CAD_Feature(Name={Name ?? "<null>"}, Type={GeometricFeatureType}, Dims={MyDimensions.Count}, Sketches={Sketches.Count})";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Feature? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Feature>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Feature"/> from a SQLite database whose schema matches
        /// <c>CAD_Feature_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="featureId">The <c>FeatureID</c> value of the feature row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Feature"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Feature? FromSql(SQLiteConnection connection, string featureId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(featureId)) throw new ArgumentException("Feature ID must not be empty.", nameof(featureId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Feature row
            // ----------------------------------------------------------
            const string featureQuery =
                "SELECT FeatureID, Name, Version, GeometricFeatureType, " +
                "       MyModelID, OriginCSysID, " +
                "       CurrentDimensionID, CurrentFeatureID, " +
                "       CurrentCAD_SketchID, CurrentCAD_StationID, CurrentLibraryID " +
                "FROM CAD_Feature WHERE FeatureID = @id;";

            CAD_Feature? feature = null;
            string? modelId = null;
            string? originCsId = null;
            string? curDimId = null;
            string? curFeatureId = null;
            string? curSketchId = null;
            string? curStationId = null;
            string? curLibId = null;

            using (var cmd = new SQLiteCommand(featureQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", featureId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                feature = new CAD_Feature
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    GeometricFeatureType = (GeometricFeatureTypeEnum)Convert.ToInt32(reader["GeometricFeatureType"])
                };

                modelId = reader["MyModelID"] as string;
                originCsId = reader["OriginCSysID"] as string;
                curDimId = reader["CurrentDimensionID"] as string;
                curFeatureId = reader["CurrentFeatureID"] as string;
                curSketchId = reader["CurrentCAD_SketchID"] as string;
                curStationId = reader["CurrentCAD_StationID"] as string;
                curLibId = reader["CurrentLibraryID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyModel
            // ----------------------------------------------------------
            if (modelId != null)
            {
                feature.MyModel = LoadModel(connection, modelId);
            }

            // ----------------------------------------------------------
            // 3. Load Origin coordinate system
            // ----------------------------------------------------------
            if (originCsId != null)
            {
                feature.Origin = LoadCoordinateSystem(connection, originCsId);
            }

            // ----------------------------------------------------------
            // 4. Load ThreeDimOperations from junction table
            // ----------------------------------------------------------
            {
                const string opsQuery =
                    "SELECT Operation FROM CAD_Feature_3DOperation " +
                    "WHERE FeatureID = @id ORDER BY SortOrder;";
                using var cmd = new SQLiteCommand(opsQuery, connection);
                cmd.Parameters.AddWithValue("@id", featureId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    feature.ThreeDimOperations.Add(
                        (Feature3DOperationEnum)Convert.ToInt32(reader["Operation"]));
                }
            }

            // ----------------------------------------------------------
            // 5. Load MyDimensions from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Feature_Dimension", "FeatureID", featureId, "DimensionID",
                id =>
                {
                    var d = LoadDimension(connection, id);
                    if (d != null)
                    {
                        feature.MyDimensions.Add(d);
                        if (id == curDimId) feature.CurrentDimension = d;
                    }
                });

            // ----------------------------------------------------------
            // 6. Load Sketches from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Feature_Sketch", "FeatureID", featureId, "SketchID",
                id =>
                {
                    var s = LoadSketch(connection, id);
                    if (s != null)
                    {
                        feature.Sketches.Add(s);
                        if (id == curSketchId) feature.CurrentCAD_Sketch = s;
                    }
                });

            // ----------------------------------------------------------
            // 7. Load Stations from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Feature_Station", "FeatureID", featureId, "StationID",
                id =>
                {
                    var st = LoadStation(connection, id);
                    if (st != null)
                    {
                        feature.Stations.Add(st);
                        if (id == curStationId) feature.CurrentCAD_Station = st;
                    }
                });

            // ----------------------------------------------------------
            // 8. Load MyFeatures (sub-features) from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Feature_SubFeature", "ParentFeatureID", featureId, "ChildFeatureID",
                id =>
                {
                    var f = LoadFeatureShallow(connection, id);
                    if (f != null)
                    {
                        feature.MyFeatures.Add(f);
                        if (id == curFeatureId) feature.CurrentFeature = f;
                    }
                });

            // ----------------------------------------------------------
            // 9. Load MyLibraries from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Feature_Library", "FeatureID", featureId, "LibraryID",
                id =>
                {
                    var lib = LoadLibrary(connection, id);
                    if (lib != null)
                    {
                        feature.MyLibraries.Add(lib);
                        if (id == curLibId) feature.CurrentLibrary = lib;
                    }
                });

            return feature;
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

        /// <summary>
        /// Shallow load of a CAD_Feature (identity + type only, no collections)
        /// to avoid infinite recursion on self-referential sub-feature tables.
        /// </summary>
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

        // -----------------------------
        // Virtual Feature Creation Methods
        // (Override in CAD-specific implementations)
        // -----------------------------

        /// <summary>
        /// Creates an extrusion (boss) feature.
        /// </summary>
        public virtual object? CreateExtrusion(bool singleDirection, bool flipDirection,
            int endCondition1, double depth1,
            int endCondition2, double depth2,
            bool draftWhileExtruding1, double draftAngle1,
            bool draftWhileExtruding2, double draftAngle2,
            bool merge, bool useFeatScope, bool useAutoSelect)
        {
            throw new NotImplementedException("CreateExtrusion must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a cut extrusion feature.
        /// </summary>
        public virtual object? CreateCutExtrusion(bool singleDirection, bool flipDirection,
            int endCondition1, double depth1,
            int endCondition2, double depth2,
            bool draftWhileExtruding1, double draftAngle1,
            bool draftWhileExtruding2, double draftAngle2,
            bool normalCut, bool useFeatScope, bool useAutoSelect)
        {
            throw new NotImplementedException("CreateCutExtrusion must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a revolve feature.
        /// </summary>
        public virtual object? CreateRevolve(bool singleDirection, bool isSolid,
            bool isCut, bool reverseDirection,
            int endCondition1, double angle1,
            int endCondition2, double angle2,
            bool merge, bool useFeatScope, bool useAutoSelect)
        {
            throw new NotImplementedException("CreateRevolve must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a hole using the Hole Wizard.
        /// </summary>
        public virtual object? CreateHoleWizard(int holeType, int standard,
            int fastenerType, string size, short endCondition,
            double diameter, double depth,
            double headClearance, double headDiameter,
            double headDepth, double threadDepth,
            double threadDiameter)
        {
            throw new NotImplementedException("CreateHoleWizard must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a threaded hole.
        /// </summary>
        public virtual object? CreateThreadedHole(string size, double depth,
            double threadDepth, int standard, int fastenerType)
        {
            throw new NotImplementedException("CreateThreadedHole must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a counterbore hole.
        /// </summary>
        public virtual object? CreateCounterboreHole(string size, double depth,
            double cboreDiameter, double cboreDepth,
            int standard, int fastenerType)
        {
            throw new NotImplementedException("CreateCounterboreHole must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a countersink hole.
        /// </summary>
        public virtual object? CreateCountersinkHole(string size, double depth,
            double csinkDiameter, double csinkAngle,
            int standard, int fastenerType)
        {
            throw new NotImplementedException("CreateCountersinkHole must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a chamfer on selected edges.
        /// </summary>
        public virtual void CreateChamfer(double width, double angle, bool flipDirection)
        {
            throw new NotImplementedException("CreateChamfer must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a fillet on selected edges.
        /// </summary>
        public virtual bool CreateFillet(double radius, int filletType,
            int overflowType, int radiusType,
            bool propagateToTangentFaces)
        {
            throw new NotImplementedException("CreateFillet must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a constant radius fillet on selected edges.
        /// </summary>
        public virtual bool CreateConstantRadiusFillet(double radius,
            bool propagateToTangentFaces)
        {
            throw new NotImplementedException("CreateConstantRadiusFillet must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a shell feature on selected faces.
        /// </summary>
        public virtual void CreateShell(double thickness, bool shellOutward)
        {
            throw new NotImplementedException("CreateShell must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a draft feature on selected faces.
        /// </summary>
        public virtual object? CreateDraft(double angle, bool reverseDirection, int draftType)
        {
            throw new NotImplementedException("CreateDraft must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a linear pattern of selected features.
        /// </summary>
        public virtual object? CreateLinearPattern(int numDir1, double spacingDir1,
            int numDir2, double spacingDir2,
            bool reverseDir1, bool reverseDir2,
            bool geometryPattern, bool varySketch,
            string skipInstances1, string skipInstances2)
        {
            throw new NotImplementedException("CreateLinearPattern must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a circular pattern of selected features.
        /// </summary>
        public virtual object? CreateCircularPattern(int totalInstances, double angularSpacing,
            bool reverseDirection, bool geometryPattern,
            bool equalSpacing, bool varySketch,
            string skipInstances)
        {
            throw new NotImplementedException("CreateCircularPattern must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a mirror feature of selected features.
        /// </summary>
        public virtual object? CreateMirrorFeature(bool geometryPattern, bool propagateVisualProps)
        {
            throw new NotImplementedException("CreateMirrorFeature must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a rib feature from a sketch.
        /// </summary>
        public virtual void CreateRib(double thickness, int ribType, bool flipMaterial,
            bool reverseThickness, bool naturalDraft, double draftAngle)
        {
            throw new NotImplementedException("CreateRib must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a slot cut feature.
        /// </summary>
        public virtual object? CreateSlotCut(double depth,
            bool singleDirection, bool flipDirection)
        {
            throw new NotImplementedException("CreateSlotCut must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a joint feature for connecting components.
        /// </summary>
        public virtual object? CreateJoint(int jointType, double clearance,
            bool flipDirection)
        {
            throw new NotImplementedException("CreateJoint must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a bead feature along selected edges or faces.
        /// </summary>
        public virtual object? CreateBead(double beadWidth, double beadHeight,
            int beadType, bool flipDirection)
        {
            throw new NotImplementedException("CreateBead must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a keyway feature for shaft/hub connections.
        /// </summary>
        public virtual object? CreateKeyway(double width, double depth,
            double length, int keywayType, bool flipDirection)
        {
            throw new NotImplementedException("CreateKeyway must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a leg feature.
        /// </summary>
        public virtual object? CreateLeg(double height, double width,
            double thickness, int legType)
        {
            throw new NotImplementedException("CreateLeg must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates an arm feature.
        /// </summary>
        public virtual object? CreateArm(double length, double width,
            double thickness, int armType)
        {
            throw new NotImplementedException("CreateArm must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates an embossment feature on a surface.
        /// </summary>
        public virtual object? CreateEmbossment(double depth, double taperAngle,
            bool flipDirection, int embossType)
        {
            throw new NotImplementedException("CreateEmbossment must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a gusset feature for structural reinforcement.
        /// </summary>
        public virtual object? CreateGusset(double thickness, double height,
            double width, int gussetType, bool flipDirection)
        {
            throw new NotImplementedException("CreateGusset must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a web feature for structural support.
        /// </summary>
        public virtual object? CreateWeb(double thickness, double height,
            int webType, bool flipDirection)
        {
            throw new NotImplementedException("CreateWeb must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a tab feature.
        /// </summary>
        public virtual object? CreateTab(double length, double width,
            double thickness, int tabType, bool flipDirection)
        {
            throw new NotImplementedException("CreateTab must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a coil/spring feature.
        /// </summary>
        public virtual object? CreateCoil(double pitch, double diameter,
            double height, int numCoils, bool clockwise,
            int coilType, double wirediameter)
        {
            throw new NotImplementedException("CreateCoil must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a helicoil/helical thread insert feature.
        /// </summary>
        public virtual object? CreateHelicoil(double pitch, double diameter,
            double depth, int numTurns, bool clockwise,
            int threadType)
        {
            throw new NotImplementedException("CreateHelicoil must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a sweep feature along a path.
        /// </summary>
        public virtual object? CreateSweep(bool isSolid, bool isCut,
            bool isThinFeature, double thinWallThickness,
            bool merge, bool useFeatScope, bool useAutoSelect,
            int startTangentType, int endTangentType,
            bool alignWithEndFaces, bool maintainTangency)
        {
            throw new NotImplementedException("CreateSweep must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a loft feature between profiles.
        /// </summary>
        public virtual object? CreateLoft(bool isSolid, bool isCut,
            bool isThinFeature, double thinWallThickness,
            bool merge, bool useFeatScope, bool useAutoSelect,
            int startTangentType, int endTangentType,
            bool closeProfile, bool maintainTangency)
        {
            throw new NotImplementedException("CreateLoft must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates an other/custom pattern feature.
        /// </summary>
        public virtual object? CreateOtherPattern(int patternType,
            object patternParameters, bool geometryPattern)
        {
            throw new NotImplementedException("CreateOtherPattern must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a rounded slot feature.
        /// </summary>
        public virtual object? CreateRoundedSlot(double length, double width,
            double depth, bool singleDirection, bool flipDirection)
        {
            throw new NotImplementedException("CreateRoundedSlot must be implemented in a derived class.");
        }

        /// <summary>
        /// Creates a square slot feature.
        /// </summary>
        public virtual object? CreateSquareSlot(double length, double width,
            double depth, bool singleDirection, bool flipDirection)
        {
            throw new NotImplementedException("CreateSquareSlot must be implemented in a derived class.");
        }


    }
}
