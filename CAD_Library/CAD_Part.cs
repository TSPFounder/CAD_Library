#nullable enable
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using System.Drawing;
using Mathematics;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    public class CAD_Part
    {
        // -----------------------------
        // Constructor
        // -----------------------------
        public CAD_Part()
        {
            // Collections
            MySketches = new List<CAD_Sketch>();
            MyFeatures = new List<CAD_Feature>();
            MyBodies = new List<CAD_Body>();
            MyDrawings = new List<CAD_Drawing>();
            MyDimensions = new List<Dimension>();
            MyParameters = new List<Parameter>();
            MyModels = new List<CAD_Model>();
            MyCoordinateSystems = new List<CoordinateSystem>();
            //MyLibraries = new List<CAD_Library>();
            MyInterfaces = new List<CAD_Interface>();
            //MyMaterials = new List<Material>();
            AxialStations = new List<CAD_Station>();
            RadialStations = new List<CAD_Station>();
            AngularStations = new List<CAD_Station>();
            WingStations = new List<CAD_Station>();
            MyMassPropertiesList = new List<MassProperties>();

            // Mass properties object commonly kept around
            MyMassProperties = new MassProperties();
            try
            {
                // Preserve original intent if this back-reference exists
                MyMassProperties.MyCAD_Part = this;
            }
            catch
            {
                // Ignore if not supported by your MassProperties type
            }
        }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? Version { get; set; }
        public string? PartNumber { get; set; }
        public string? Description { get; set; }

        // -----------------------------
        // Mass properties & center of mass
        // -----------------------------
        public MassProperties? CurrentMassProperties { get; set; }
        public List<MassProperties> MyMassPropertiesList { get; set; }
        public Mathematics.Point? CenterOfMass { get; set; }
        public MassProperties MyMassProperties { get; set; }

        // -----------------------------
        // Models
        // -----------------------------
        public CAD_Model? CurrentModel { get; set; }
        public List<CAD_Model> MyModels { get; set; }

        // -----------------------------
        // Coordinate systems
        // -----------------------------
        public CoordinateSystem? CurrentCoordinateSystem { get; set; }
        public List<CoordinateSystem> MyCoordinateSystems { get; set; }

        // -----------------------------
        // Sketches
        // -----------------------------
        public CAD_Sketch? CurrentSketch { get; set; }
        public List<CAD_Sketch> MySketches { get; set; }

        // -----------------------------
        // Features
        // -----------------------------
        public CAD_Feature? CurrentFeature { get; set; }
        public List<CAD_Feature> MyFeatures { get; set; }

        // -----------------------------
        // Bodies
        // -----------------------------
        public CAD_Body? CurrentBody { get; set; }
        public List<CAD_Body> MyBodies { get; set; }

        // -----------------------------
        // Drawings
        // -----------------------------
        public CAD_Drawing? CurrentDrawing { get; set; }
        public List<CAD_Drawing> MyDrawings { get; set; }

        // -----------------------------
        // Dimensions
        // -----------------------------
        public Dimension? CurrentDimension { get; set; }
        public List<Dimension> MyDimensions { get; set; }

        // -----------------------------
        // Parameters
        // -----------------------------
        public Parameter? CurrentParameter { get; set; }
        public List<Parameter> MyParameters { get; set; }

        // -----------------------------
        // Assembly
        // -----------------------------
        public CAD_Assembly? MyAssembly { get; set; }

        // -----------------------------
        // Materials
        // -----------------------------
        //public List<Material> MyMaterials { get; set; }

        // -----------------------------
        // CAD application
        // -----------------------------
       // public CAD_App? CAD_Application { get; set; }

        // -----------------------------
        // Libraries
        // -----------------------------
        public CAD_Library? CurrentLibrary { get; set; }
        public List<CAD_Library> MyLibraries { get; set; }

        // -----------------------------
        // Interfaces
        // -----------------------------
        public CAD_Interface? CurrentInterface { get; set; }
        public List<CAD_Interface> MyInterfaces { get; set; }

        // -----------------------------
        // Stations
        // -----------------------------
        public List<CAD_Station> AxialStations { get; set; }
        public List<CAD_Station> RadialStations { get; set; }
        public List<CAD_Station> AngularStations { get; set; }
        public List<CAD_Station> WingStations { get; set; }

        // -----------------------------
        // Methods
        // -----------------------------
        /// <summary>
        /// Extrudes the current sketch (placeholder). Returns true on success.
        /// </summary>
        public bool ExtrudeSketch()
        {
            try
            {
                // Implementation placeholder
                return true;
            }
            catch
            {
                // Avoid UI here; let caller decide how to report errors
                return false;
            }
        }

        // -----------------------------
        // Tiny helpers (optional)
        // -----------------------------
        public void AddSketch(CAD_Sketch sketch)
        {
            if (sketch is null) throw new ArgumentNullException(nameof(sketch));
            MySketches.Add(sketch);
            CurrentSketch ??= sketch;
        }

        public void AddFeature(CAD_Feature feature)
        {
            if (feature is null) throw new ArgumentNullException(nameof(feature));
            MyFeatures.Add(feature);
            CurrentFeature ??= feature;
        }

        public void AddBody(CAD_Body body)
        {
            if (body is null) throw new ArgumentNullException(nameof(body));
            MyBodies.Add(body);
            CurrentBody ??= body;
        }

        public void AddDimension(Dimension dim)
        {
            if (dim is null) throw new ArgumentNullException(nameof(dim));
            MyDimensions.Add(dim);
            CurrentDimension ??= dim;
        }

        public void AddParameter(Parameter param)
        {
            if (param is null) throw new ArgumentNullException(nameof(param));
            MyParameters.Add(param);
            CurrentParameter ??= param;
        }

        public override string ToString()
            => $"CAD_Part(Name={Name ?? "<null>"}, PN={PartNumber ?? "<null>"}, Features={MyFeatures.Count}, Bodies={MyBodies.Count})";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Part? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Part>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Part"/> from a SQLite database whose schema matches
        /// <c>CAD_Part_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="partId">The <c>PartID</c> value of the part row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Part"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Part? FromSql(SQLiteConnection connection, string partId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(partId)) throw new ArgumentException("Part ID must not be empty.", nameof(partId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Part row
            // ----------------------------------------------------------
            const string partQuery =
                "SELECT PartID, Name, Version, PartNumber, Description, " +
                "       CurrentMassPropertiesID, MyMassPropertiesID, CenterOfMassPointID, " +
                "       CurrentModelID, CurrentCoordinateSystemID, " +
                "       CurrentSketchID, CurrentFeatureID, CurrentBodyID, " +
                "       CurrentDrawingID, CurrentDimensionID, CurrentParameterID, " +
                "       MyAssemblyID, CurrentLibraryID, CurrentInterfaceID " +
                "FROM CAD_Part WHERE PartID = @id;";

            CAD_Part? part = null;
            string? currentMassPropId = null;
            string? myMassPropId = null;
            string? centerOfMassId = null;
            string? currentModelId = null;
            string? currentCsysId = null;
            string? currentSketchId = null;
            string? currentFeatureId = null;
            string? currentBodyId = null;
            string? currentDrawingId = null;
            string? currentDimensionId = null;
            string? currentParameterId = null;
            string? myAssemblyId = null;
            string? currentLibraryId = null;
            string? currentInterfaceId = null;

            using (var cmd = new SQLiteCommand(partQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", partId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                part = new CAD_Part
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    PartNumber = reader["PartNumber"] as string,
                    Description = reader["Description"] as string
                };

                currentMassPropId = reader["CurrentMassPropertiesID"] as string;
                myMassPropId = reader["MyMassPropertiesID"] as string;
                centerOfMassId = reader["CenterOfMassPointID"] as string;
                currentModelId = reader["CurrentModelID"] as string;
                currentCsysId = reader["CurrentCoordinateSystemID"] as string;
                currentSketchId = reader["CurrentSketchID"] as string;
                currentFeatureId = reader["CurrentFeatureID"] as string;
                currentBodyId = reader["CurrentBodyID"] as string;
                currentDrawingId = reader["CurrentDrawingID"] as string;
                currentDimensionId = reader["CurrentDimensionID"] as string;
                currentParameterId = reader["CurrentParameterID"] as string;
                myAssemblyId = reader["MyAssemblyID"] as string;
                currentLibraryId = reader["CurrentLibraryID"] as string;
                currentInterfaceId = reader["CurrentInterfaceID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load scalar references (mass properties, center of mass)
            // ----------------------------------------------------------
            if (myMassPropId != null)
            {
                var mp = LoadMassProperties(connection, myMassPropId);
                if (mp != null) part.MyMassProperties = mp;
            }

            if (currentMassPropId != null)
            {
                part.CurrentMassProperties = LoadMassProperties(connection, currentMassPropId);
            }

            if (centerOfMassId != null)
            {
                part.CenterOfMass = LoadPoint(connection, centerOfMassId);
            }

            // ----------------------------------------------------------
            // 3. Load cursor references
            // ----------------------------------------------------------
            if (currentModelId != null)
                part.CurrentModel = LoadModel(connection, currentModelId);

            if (currentCsysId != null)
                part.CurrentCoordinateSystem = LoadCoordinateSystem(connection, currentCsysId);

            if (currentSketchId != null)
                part.CurrentSketch = LoadSketch(connection, currentSketchId);

            if (currentFeatureId != null)
                part.CurrentFeature = LoadFeature(connection, currentFeatureId);

            if (currentBodyId != null)
                part.CurrentBody = LoadBody(connection, currentBodyId);

            if (currentDrawingId != null)
                part.CurrentDrawing = LoadDrawing(connection, currentDrawingId);

            if (currentDimensionId != null)
                part.CurrentDimension = LoadDimension(connection, currentDimensionId);

            if (currentParameterId != null)
                part.CurrentParameter = LoadParameter(connection, currentParameterId);

            if (currentLibraryId != null)
                part.CurrentLibrary = LoadLibrary(connection, currentLibraryId);

            if (currentInterfaceId != null)
                part.CurrentInterface = LoadInterface(connection, currentInterfaceId);

            // ----------------------------------------------------------
            // 4. Load MySketches from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_Sketch", "PartID", partId, "SketchID",
                id => { var s = LoadSketch(connection, id); if (s != null) part.MySketches.Add(s); });

            // ----------------------------------------------------------
            // 5. Load MyFeatures from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_Feature", "PartID", partId, "FeatureID",
                id => { var f = LoadFeature(connection, id); if (f != null) part.MyFeatures.Add(f); });

            // ----------------------------------------------------------
            // 6. Load MyBodies from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_Body", "PartID", partId, "BodyID",
                id => { var b = LoadBody(connection, id); if (b != null) part.MyBodies.Add(b); });

            // ----------------------------------------------------------
            // 7. Load MyDrawings from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_Drawing", "PartID", partId, "DrawingID",
                id => { var d = LoadDrawing(connection, id); if (d != null) part.MyDrawings.Add(d); });

            // ----------------------------------------------------------
            // 8. Load MyDimensions from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_Dimension", "PartID", partId, "DimensionID",
                id => { var d = LoadDimension(connection, id); if (d != null) part.MyDimensions.Add(d); });

            // ----------------------------------------------------------
            // 9. Load MyParameters from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_Parameter", "PartID", partId, "MathParameterID",
                id => { var p = LoadParameter(connection, id); if (p != null) part.MyParameters.Add(p); });

            // ----------------------------------------------------------
            // 10. Load MyModels from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_Model", "PartID", partId, "ModelID",
                id => { var m = LoadModel(connection, id); if (m != null) part.MyModels.Add(m); });

            // ----------------------------------------------------------
            // 11. Load MyCoordinateSystems from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_CoordinateSystem", "PartID", partId, "CoordinateSystemID",
                id => { var cs = LoadCoordinateSystem(connection, id); if (cs != null) part.MyCoordinateSystems.Add(cs); });

            // ----------------------------------------------------------
            // 12. Load MyInterfaces from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_Interface", "PartID", partId, "InterfaceID",
                id => { var i = LoadInterface(connection, id); if (i != null) part.MyInterfaces.Add(i); });

            // ----------------------------------------------------------
            // 13. Load MyLibraries from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_Library", "PartID", partId, "LibraryID",
                id => { var l = LoadLibrary(connection, id); if (l != null) part.MyLibraries.Add(l); });

            // ----------------------------------------------------------
            // 14. Load MyMassPropertiesList from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Part_MassProperties", "PartID", partId, "MassPropertiesID",
                id => { var mp = LoadMassProperties(connection, id); if (mp != null) part.MyMassPropertiesList.Add(mp); });

            // ----------------------------------------------------------
            // 15. Load Stations from junction table (categorized)
            // ----------------------------------------------------------
            const string stationsQuery =
                "SELECT StationID, StationCategory FROM CAD_Part_Station " +
                "WHERE PartID = @id ORDER BY StationCategory, SortOrder;";

            using (var cmd = new SQLiteCommand(stationsQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", partId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string stationId = reader["StationID"] as string ?? "";
                    string category = reader["StationCategory"] as string ?? "";
                    var station = LoadStation(connection, stationId);
                    if (station == null) continue;

                    switch (category)
                    {
                        case "Axial": part.AxialStations.Add(station); break;
                        case "Radial": part.RadialStations.Add(station); break;
                        case "Angular": part.AngularStations.Add(station); break;
                        case "Wing": part.WingStations.Add(station); break;
                    }
                }
            }

            return part;
        }

        // -----------------------------
        // Private SQL helper: junction table loader
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

        // -----------------------------
        // Private SQL helper: entity loaders
        // -----------------------------

        private static Mathematics.Point? LoadPoint(SQLiteConnection connection, string pointId)
        {
            const string query =
                "SELECT PointID, X_Value, Y_Value, Z_Value_Cartesian " +
                "FROM Point WHERE PointID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", pointId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Mathematics.Point
            {
                X_Value = Convert.ToDouble(reader["X_Value"]),
                Y_Value = Convert.ToDouble(reader["Y_Value"]),
                Z_Value_Cartesian = Convert.ToDouble(reader["Z_Value_Cartesian"])
            };
        }

        private static CoordinateSystem? LoadCoordinateSystem(SQLiteConnection connection, string csysId)
        {
            const string query =
                "SELECT CoordinateSystemID, Name, OriginLocationPointID " +
                "FROM CoordinateSystem WHERE CoordinateSystemID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", csysId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            string? originId = reader["OriginLocationPointID"] as string;
            Mathematics.Point? origin = originId != null ? LoadPoint(connection, originId) : null;

            var csys = new CoordinateSystem();
            if (origin != null) csys.OriginLocation = origin;

            return csys;
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
                GeometricFeatureType = (CAD_Feature.GeometricFeatureTypeEnum)Convert.ToInt32(reader["GeometricFeatureType"])
            };
        }

        private static CAD_Body? LoadBody(SQLiteConnection connection, string bodyId)
        {
            const string query =
                "SELECT BodyID, Name, Version, PartNumber, GeometricFeatureType " +
                "FROM CAD_Body WHERE BodyID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", bodyId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Body
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                PartNumber = reader["PartNumber"] as string,
                GeometricFeatureType = (CAD_Feature.GeometricFeatureTypeEnum)Convert.ToInt32(reader["GeometricFeatureType"])
            };
        }

        private static CAD_Drawing? LoadDrawing(SQLiteConnection connection, string drawingId)
        {
            const string query =
                "SELECT DrawingID, Title, DrawingNumber, Revision, " +
                "       DrawingStandard, MyFormat, MyDrawingSize " +
                "FROM CAD_Drawing WHERE DrawingID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", drawingId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Drawing
            {
                Title = reader["Title"] as string,
                DrawingNumber = reader["DrawingNumber"] as string,
                Revision = reader["Revision"] as string,
                DrawingStandard = (CAD_Drawing.DrawingStandardEnum)Convert.ToInt32(reader["DrawingStandard"]),
                MyFormat = (CAD_Drawing.DocFormatEnum)Convert.ToInt32(reader["MyFormat"]),
                MyDrawingSize = (CAD_Drawing.DrawingSize)Convert.ToInt32(reader["MyDrawingSize"])
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
                DimensionID = reader["DimensionID"] as string,
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                IsOrdinate = Convert.ToInt32(reader["IsOrdinate"]) != 0,
                DimensionNominalValue = Convert.ToDouble(reader["DimensionNominalValue"]),
                DimensionUpperLimitValue = Convert.ToDouble(reader["DimensionUpperLimitValue"]),
                DimensionLowerLimitValue = Convert.ToDouble(reader["DimensionLowerLimitValue"]),
                MyDimensionType = (Dimension.DimensionType)Convert.ToInt32(reader["MyDimensionType"])
            };
        }

        private static Parameter? LoadParameter(SQLiteConnection connection, string parameterId)
        {
            const string query =
                "SELECT MathParameterID, Name, PartNumber, Description, Comments, MyParameterType, " +
                "       SolidWorksParameterName, Fusion360ParameterName " +
                "FROM MathParameter WHERE MathParameterID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", parameterId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Parameter
            {
                Name = reader["Name"] as string,
                PartNumber = reader["PartNumber"] as string,
                Description = reader["Description"] as string,
                Comments = reader["Comments"] as string,
                MyParameterType = (Parameter.ParameterType)Convert.ToInt32(reader["MyParameterType"]),
                SolidWorksParameterName = reader["SolidWorksParameterName"] as string,
                Fusion360ParameterName = reader["Fusion360ParameterName"] as string
            };
        }

        private static CAD_Interface? LoadInterface(SQLiteConnection connection, string interfaceId)
        {
            const string query =
                "SELECT InterfaceID, Name, ID, Version, InterfaceKind " +
                "FROM CAD_Interface WHERE InterfaceID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", interfaceId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Interface
            {
                Name = reader["Name"] as string,
                ID = reader["ID"] as string,
                Version = reader["Version"] as string,
                InterfaceKind = reader["InterfaceKind"] is DBNull
                    ? null
                    : (CAD_Interface.InterfaceType)Convert.ToInt32(reader["InterfaceKind"])
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

            string? urlString = reader["Url"] as string;
            Uri? url = null;
            if (!string.IsNullOrEmpty(urlString))
                Uri.TryCreate(urlString, UriKind.Absolute, out url);

            return new CAD_Library
            {
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                LocalPath = reader["LocalPath"] as string,
                Url = url
            };
        }

        private static MassProperties? LoadMassProperties(SQLiteConnection connection, string massPropId)
        {
            const string query =
                "SELECT MassPropertiesID, Mass, CenterOfGravityPointID " +
                "FROM MassProperties WHERE MassPropertiesID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", massPropId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            var mp = new MassProperties
            {
                Mass = Convert.ToDouble(reader["Mass"])
            };

            string? cogId = reader["CenterOfGravityPointID"] as string;
            if (cogId != null)
            {
                var cog = LoadPoint(connection, cogId);
                if (cog != null) mp.CenterOfGravity = cog;
            }

            return mp;
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

            var station = new CAD_Station(reader["ID"] as string ?? "", stationType, locationValue)
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string
            };

            return station;
        }
    }
}

