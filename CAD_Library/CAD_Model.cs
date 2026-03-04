#nullable enable
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using SE_Library;
using Documents;
using System.IO.Compression;
using Newtonsoft.Json;

namespace CAD
{
    public class CAD_Model 
    {
        // -----------------------------
        // Enums (unchanged)
        // -----------------------------
        public enum CAD_ModelTypeEnum
        {
            Component = 0,
            Assembly,
            Drawing,
            Mesh,
            Body,
            Other
        }

        public enum CAD_AppEnum
        {
            Fusion360 = 0,
            Solidworks,
            Blender,
            UnReal4,
            UnReal5,
            Unity,
            Other
        }

        public enum CAD_FileTypeEnum
        {
            f3d = 0,
            f3z,
            sldprt,
            sldasm,
            slddrw,
            step,
            stl,
            sat,
            dxf,
            iges,
            fbx,
            obj,
            dae,
            x3d,
            wrl,
            other
        }

        // -----------------------------
        // Constructor
        // -----------------------------
        public CAD_Model()
        {
            // Base / system wiring retained
            //MySystem = mySystem;
            //MySystemModelType = ModelTypeEnum.CAD;

            // Collections
            MyStations = new List<CAD_Station>();
            MySketches = new List<CAD_Sketch>();
            MyFeatures = new List<CAD_Feature>();
            MyParts = new List<CAD_Part>();
            MyDrawings = new List<CAD_Drawing>();
            MyAssemblies = new List<CAD_Assembly>();
        }

        // -----------------------------
        // Properties (auto-properties)
        // -----------------------------
        // Identification / metadata
        public string? Name { get; set; }
        public string? Version { get; set; }
        public string? Description { get; set; }
        public string? FilePath { get; set; }

        // Enumerations
        public CAD_AppEnum CAD_AppName { get; set; }
        public CAD_ModelTypeEnum ModelType { get; set; }
        public CAD_FileTypeEnum FileType { get; set; }

        // Owned & Owning
        //public CAD_Manager? MyCAD_Manager { get; set; }

        // Stations
        public CAD_Station? CurrentStation { get; set; }
        public List<CAD_Station> MyStations { get; set; }

        // Sketches
        public CAD_Sketch? CurrentSketch { get; set; }
        public List<CAD_Sketch> MySketches { get; set; }

        // Features
        public CAD_Feature? CurrentFeature { get; set; }
        public List<CAD_Feature> MyFeatures { get; set; }

        // Parts
        public CAD_Part? CurrentPart { get; set; }
        public List<CAD_Part> MyParts { get; set; }

        // Drawings
        public CAD_Drawing? CurrentDrawing { get; set; }
        public List<CAD_Drawing> MyDrawings { get; set; }

        // Assemblies
        public CAD_Assembly? CurrentAssembly { get; set; }
        public List<CAD_Assembly> MyAssemblies { get; set; }

        //  Systems
        public SE_System? MySystem { get; set; }

        // CAD application models
        /*
        public AppFile? Fusion360Model { get; set; }
        public AppFile? SolidWorksModel { get; set; }
        public AppFile? MechanicalDesktopModel { get; set; }
        public AppFile? BlenderModel { get; set; }
        public AppFile? UnityModel { get; set; }
        public AppFile? UnrealEngine4Model { get; set; }
        public AppFile? UnrealEngine5Model { get; set; }
        public AppFile? OtherCAD_Model { get; set; }

        // Design tables
        public CAD_DesignTable? SolidWorksDesignTable { get; set; }
        public CAD_DesignTable? MechanicalDesktopDesignTable { get; set; }
        public CAD_DesignTable? Fusion360DesignTable { get; set; }
        */

        // BoM
        public CAD_BoM? MyBoM { get; set; }

        // -----------------------------
        // Methods
        // -----------------------------
        public bool CreateFusion360Model()
        {
            try
            {
                //Fusion360Model = new AppFile();
                return true;
            }
            catch
            {
                return false;
            }
        }

        // Small helpers (optional)
        public void AddStation(CAD_Station station)
        {
            if (station is null) throw new ArgumentNullException(nameof(station));
            MyStations.Add(station);
            CurrentStation ??= station;
        }

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

        public void AddPart(CAD_Part part)
        {
            if (part is null) throw new ArgumentNullException(nameof(part));
            MyParts.Add(part);
            CurrentPart ??= part;
        }

        public void AddDrawing(CAD_Drawing drawing)
        {
            if (drawing is null) throw new ArgumentNullException(nameof(drawing));
            MyDrawings.Add(drawing);
            CurrentDrawing ??= drawing;
        }

        public void AddAssembly(CAD_Assembly assembly)
        {
            if (assembly is null) throw new ArgumentNullException(nameof(assembly));
            MyAssemblies.Add(assembly);
            CurrentAssembly ??= assembly;
        }

        public override string ToString()
            => $"CAD_Model(Name={Name ?? "<null>"}, App={CAD_AppName}, Type={ModelType}, FileType={FileType}, Parts={MyParts.Count}, Features={MyFeatures.Count})";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Model? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Model>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Model"/> from a SQLite database whose schema matches
        /// <c>CAD_Model_Schema.sql</c>.
        /// </summary>
        public static CAD_Model? FromSql(SQLiteConnection connection, string modelId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(modelId)) throw new ArgumentException("Model ID must not be empty.", nameof(modelId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Model row
            // ----------------------------------------------------------
            const string query =
                "SELECT ModelID, Name, Version, Description, FilePath, " +
                "       CAD_AppName, ModelType, FileType, " +
                "       CurrentStationID, CurrentSketchID, CurrentFeatureID, " +
                "       CurrentPartID, CurrentDrawingID, CurrentAssemblyID, " +
                "       MySystemID, MyBoMID " +
                "FROM CAD_Model WHERE ModelID = @id;";

            CAD_Model? model = null;
            string? curStationId = null;
            string? curSketchId = null;
            string? curFeatureId = null;
            string? curPartId = null;
            string? curDrawingId = null;
            string? curAssemblyId = null;
            string? systemId = null;
            string? bomId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", modelId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                model = new CAD_Model
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    Description = reader["Description"] as string,
                    FilePath = reader["FilePath"] as string,
                    CAD_AppName = (CAD_AppEnum)Convert.ToInt32(reader["CAD_AppName"]),
                    ModelType = (CAD_ModelTypeEnum)Convert.ToInt32(reader["ModelType"]),
                    FileType = (CAD_FileTypeEnum)Convert.ToInt32(reader["FileType"])
                };

                curStationId = reader["CurrentStationID"] as string;
                curSketchId = reader["CurrentSketchID"] as string;
                curFeatureId = reader["CurrentFeatureID"] as string;
                curPartId = reader["CurrentPartID"] as string;
                curDrawingId = reader["CurrentDrawingID"] as string;
                curAssemblyId = reader["CurrentAssemblyID"] as string;
                systemId = reader["MySystemID"] as string;
                bomId = reader["MyBoMID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MySystem
            // ----------------------------------------------------------
            if (systemId != null)
            {
                model.MySystem = LoadSystem(connection, systemId);
            }

            // ----------------------------------------------------------
            // 3. Load MyBoM
            // ----------------------------------------------------------
            if (bomId != null)
            {
                model.MyBoM = LoadBoM(connection, bomId);
            }

            // ----------------------------------------------------------
            // 4. Load MyStations from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Model_Station", "ModelID", modelId, "StationID",
                id =>
                {
                    var station = LoadStation(connection, id);
                    if (station != null)
                    {
                        model.MyStations.Add(station);
                        if (id == curStationId) model.CurrentStation = station;
                    }
                });

            // ----------------------------------------------------------
            // 5. Load MySketches from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Model_Sketch", "ModelID", modelId, "SketchID",
                id =>
                {
                    var sketch = LoadSketch(connection, id);
                    if (sketch != null)
                    {
                        model.MySketches.Add(sketch);
                        if (id == curSketchId) model.CurrentSketch = sketch;
                    }
                });

            // ----------------------------------------------------------
            // 6. Load MyFeatures from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Model_Feature", "ModelID", modelId, "FeatureID",
                id =>
                {
                    var feature = LoadFeature(connection, id);
                    if (feature != null)
                    {
                        model.MyFeatures.Add(feature);
                        if (id == curFeatureId) model.CurrentFeature = feature;
                    }
                });

            // ----------------------------------------------------------
            // 7. Load MyParts from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Model_Part", "ModelID", modelId, "PartID",
                id =>
                {
                    var part = LoadPart(connection, id);
                    if (part != null)
                    {
                        model.MyParts.Add(part);
                        if (id == curPartId) model.CurrentPart = part;
                    }
                });

            // ----------------------------------------------------------
            // 8. Load MyDrawings from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Model_Drawing", "ModelID", modelId, "DrawingID",
                id =>
                {
                    var drawing = LoadDrawing(connection, id);
                    if (drawing != null)
                    {
                        model.MyDrawings.Add(drawing);
                        if (id == curDrawingId) model.CurrentDrawing = drawing;
                    }
                });

            // ----------------------------------------------------------
            // 9. Load MyAssemblies from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Model_Assembly", "ModelID", modelId, "AssemblyID",
                id =>
                {
                    var assembly = LoadAssembly(connection, id);
                    if (assembly != null)
                    {
                        model.MyAssemblies.Add(assembly);
                        if (id == curAssemblyId) model.CurrentAssembly = assembly;
                    }
                });

            return model;
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

        private static SE_System? LoadSystem(SQLiteConnection connection, string systemId)
        {
            const string query =
                "SELECT SE_SystemID, Name, Version, Description " +
                "FROM SE_System WHERE SE_SystemID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", systemId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new SE_System
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                Description = reader["Description"] as string
            };
        }

        private static CAD_BoM? LoadBoM(SQLiteConnection connection, string bomId)
        {
            const string query =
                "SELECT BoMID, BoMType " +
                "FROM CAD_BoM WHERE BoMID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", bomId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            var bom = new CAD_BoM();
            if (reader["BoMType"] is not DBNull)
            {
                bom.BoMType = (CAD_BoM.BoM_TypeEnum)Convert.ToInt32(reader["BoMType"]);
            }
            return bom;
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

            return new CAD_Station(
                reader["ID"] as string,
                stationType,
                locationValue)
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

        private static CAD_Part? LoadPart(SQLiteConnection connection, string partId)
        {
            const string query =
                "SELECT PartID, Name, Version, PartNumber, Description " +
                "FROM CAD_Part WHERE PartID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", partId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Part
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                PartNumber = reader["PartNumber"] as string,
                Description = reader["Description"] as string
            };
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

        private static CAD_Assembly? LoadAssembly(SQLiteConnection connection, string assemblyId)
        {
            const string query =
                "SELECT AssemblyID, Name, Version, Description, " +
                "       IsSubAssembly, IsConfigurationItem " +
                "FROM CAD_Assembly WHERE AssemblyID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", assemblyId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Assembly
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                Description = reader["Description"] as string,
                IsSubAssembly = Convert.ToInt32(reader["IsSubAssembly"]) != 0,
                IsConfigurationItem = Convert.ToInt32(reader["IsConfigurationItem"]) != 0
            };
        }
    }
}
