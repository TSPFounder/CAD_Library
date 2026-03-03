

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    public class CAD_Assembly // : CAD_Part
    {
        // -----------------------------
        // Constructor
        // -----------------------------
        public CAD_Assembly()
        {
            MyCoordinateSystems = new List<CoordinateSystem>();

            MyComponents = new List<CAD_Component>();
            MyConfigurations = new List<CAD_Configuration>();
            MissionRequirements = new List<MissionRequirement>();
            SystemRequirements = new List<SystemRequirement>();
            MyInterfaces = new List<CAD_Interface>();

            AxialStations = new List<CAD_Station>();
            RadialStations = new List<CAD_Station>();
            AngularStations = new List<CAD_Station>();
            WingStations = new List<CAD_Station>();
        }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? Version { get; set; }
        public string? Description { get; set; }

        // -----------------------------
        // Flags
        // -----------------------------
        public bool IsSubAssembly { get; set; }
        public bool IsConfigurationItem { get; set; }

        // -----------------------------
        // Pose (position & orientation)
        // -----------------------------
        public Point? MyPosition { get; set; }
        public Vector? MyOrientation { get; set; }

        // -----------------------------
        // Coordinate systems
        // -----------------------------
        public CoordinateSystem? CurrentCS { get; set; }
        public List<CoordinateSystem> MyCoordinateSystems { get; set; }

        // -----------------------------
        // Ownership / associations
        // -----------------------------
        public CAD_Assembly? MyParentAssembly { get; set; }

        // -----------------------------
        // Components
        // -----------------------------
        public CAD_Component? CurrentComponent { get; set; }
        public CAD_Component? PreviousComponent { get; set; }
        public CAD_Component? NextComponent { get; set; }
        public List<CAD_Component> MyComponents { get; set; }

        // -----------------------------
        // Model
        // -----------------------------
        public CAD_Model? MyModel { get; set; }

        // -----------------------------
        // Configurations
        // -----------------------------
        public CAD_Configuration? CurrentConfiguration { get; set; }
        public List<CAD_Configuration> MyConfigurations { get; set; }

        // -----------------------------
        // Requirements
        // -----------------------------
        public List<MissionRequirement> MissionRequirements { get; set; }
        public List<SystemRequirement> SystemRequirements { get; set; }

        // -----------------------------
        // Part (optional)
        // -----------------------------
        public CAD_Part? MyPart { get; set; }

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
        // Helpers (optional)
        // -----------------------------
        public void AddComponent(CAD_Component component)
        {
            if (component is null) throw new ArgumentNullException(nameof(component));
            PreviousComponent = CurrentComponent;
            MyComponents.Add(component);
            CurrentComponent = component;
        }

        public void AddConfiguration(CAD_Configuration config)
        {
            if (config is null) throw new ArgumentNullException(nameof(config));
            MyConfigurations.Add(config);
            CurrentConfiguration ??= config;
        }

        public void AddInterface(CAD_Interface iface)
        {
            if (iface is null) throw new ArgumentNullException(nameof(iface));
            MyInterfaces.Add(iface);
            CurrentInterface ??= iface;
        }

        public void AddCoordinateSystem(CoordinateSystem cs)
        {
            if (cs is null) throw new ArgumentNullException(nameof(cs));
            MyCoordinateSystems.Add(cs);
            CurrentCS ??= cs;
        }

        public override string ToString()
            => $"CAD_Assembly(Name={Name ?? "<null>"}, SubAsm={IsSubAssembly}, Components={MyComponents.Count}, Configs={MyConfigurations.Count})";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Assembly? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Assembly>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Assembly"/> from a SQLite database whose schema matches
        /// <c>CAD_Assembly_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="assemblyId">The <c>AssemblyID</c> value of the assembly row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Assembly"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Assembly? FromSql(SQLiteConnection connection, string assemblyId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(assemblyId)) throw new ArgumentException("Assembly ID must not be empty.", nameof(assemblyId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Assembly row
            // ----------------------------------------------------------
            const string assemblyQuery =
                "SELECT AssemblyID, Name, Version, Description, " +
                "       IsSubAssembly, IsConfigurationItem, " +
                "       MyPositionPointID, MyOrientationVectorID, " +
                "       CurrentCSID, CurrentComponentID, PreviousComponentID, NextComponentID, " +
                "       MyModelID, CurrentConfigurationID, MyPartID, CurrentInterfaceID " +
                "FROM CAD_Assembly WHERE AssemblyID = @id;";

            CAD_Assembly? assembly = null;
            string? positionPtId = null;
            string? orientationVecId = null;
            string? currentCsId = null;
            string? currentCompId = null;
            string? previousCompId = null;
            string? nextCompId = null;
            string? modelId = null;
            string? currentConfigId = null;
            string? partId = null;
            string? currentInterfaceId = null;

            using (var cmd = new SQLiteCommand(assemblyQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", assemblyId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                assembly = new CAD_Assembly
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    Description = reader["Description"] as string,
                    IsSubAssembly = Convert.ToInt32(reader["IsSubAssembly"]) != 0,
                    IsConfigurationItem = Convert.ToInt32(reader["IsConfigurationItem"]) != 0
                };

                positionPtId = reader["MyPositionPointID"] as string;
                orientationVecId = reader["MyOrientationVectorID"] as string;
                currentCsId = reader["CurrentCSID"] as string;
                currentCompId = reader["CurrentComponentID"] as string;
                previousCompId = reader["PreviousComponentID"] as string;
                nextCompId = reader["NextComponentID"] as string;
                modelId = reader["MyModelID"] as string;
                currentConfigId = reader["CurrentConfigurationID"] as string;
                partId = reader["MyPartID"] as string;
                currentInterfaceId = reader["CurrentInterfaceID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load pose (Position point & Orientation vector)
            // ----------------------------------------------------------
            if (positionPtId != null)
            {
                assembly.MyPosition = LoadPoint(connection, positionPtId);
            }

            if (orientationVecId != null)
            {
                assembly.MyOrientation = LoadVector(connection, orientationVecId);
            }

            // ----------------------------------------------------------
            // 3. Load CurrentCS
            // ----------------------------------------------------------
            if (currentCsId != null)
            {
                assembly.CurrentCS = LoadCoordinateSystem(connection, currentCsId);
            }

            // ----------------------------------------------------------
            // 4. Load component cursors
            // ----------------------------------------------------------
            if (currentCompId != null)
                assembly.CurrentComponent = LoadComponent(connection, currentCompId);
            if (previousCompId != null)
                assembly.PreviousComponent = LoadComponent(connection, previousCompId);
            if (nextCompId != null)
                assembly.NextComponent = LoadComponent(connection, nextCompId);

            // ----------------------------------------------------------
            // 5. Load Model
            // ----------------------------------------------------------
            if (modelId != null)
            {
                assembly.MyModel = LoadModel(connection, modelId);
            }

            // ----------------------------------------------------------
            // 6. Load CurrentConfiguration cursor
            // ----------------------------------------------------------
            if (currentConfigId != null)
            {
                assembly.CurrentConfiguration = LoadConfiguration(connection, currentConfigId);
            }

            // ----------------------------------------------------------
            // 7. Load Part
            // ----------------------------------------------------------
            if (partId != null)
            {
                assembly.MyPart = LoadPart(connection, partId);
            }

            // ----------------------------------------------------------
            // 8. Load CurrentInterface cursor
            // ----------------------------------------------------------
            if (currentInterfaceId != null)
            {
                assembly.CurrentInterface = LoadInterface(connection, currentInterfaceId);
            }

            // ----------------------------------------------------------
            // 9. Load MyCoordinateSystems from junction table
            // ----------------------------------------------------------
            const string csysQuery =
                "SELECT CoordinateSystemID FROM CAD_Assembly_CoordinateSystem " +
                "WHERE AssemblyID = @id ORDER BY SortOrder;";

            using (var cmd = new SQLiteCommand(csysQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", assemblyId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string csId = reader["CoordinateSystemID"] as string ?? "";
                    var cs = LoadCoordinateSystem(connection, csId);
                    if (cs != null) assembly.MyCoordinateSystems.Add(cs);
                }
            }

            // ----------------------------------------------------------
            // 10. Load MyComponents from junction table
            // ----------------------------------------------------------
            const string componentsQuery =
                "SELECT ComponentID FROM CAD_Assembly_Component " +
                "WHERE AssemblyID = @id ORDER BY SortOrder;";

            using (var cmd = new SQLiteCommand(componentsQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", assemblyId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string compId = reader["ComponentID"] as string ?? "";
                    var comp = LoadComponent(connection, compId);
                    if (comp != null) assembly.MyComponents.Add(comp);
                }
            }

            // ----------------------------------------------------------
            // 11. Load MyConfigurations from junction table
            // ----------------------------------------------------------
            const string configsQuery =
                "SELECT ConfigurationID FROM CAD_Assembly_Configuration " +
                "WHERE AssemblyID = @id ORDER BY SortOrder;";

            using (var cmd = new SQLiteCommand(configsQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", assemblyId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string cfgId = reader["ConfigurationID"] as string ?? "";
                    var cfg = LoadConfiguration(connection, cfgId);
                    if (cfg != null) assembly.MyConfigurations.Add(cfg);
                }
            }

            // ----------------------------------------------------------
            // 12. Load MissionRequirements from junction table
            // ----------------------------------------------------------
            const string missionReqQuery =
                "SELECT mr.MissionRequirementID, mr.Name " +
                "FROM CAD_Assembly_MissionRequirement amr " +
                "JOIN MissionRequirement mr ON amr.MissionRequirementID = mr.MissionRequirementID " +
                "WHERE amr.AssemblyID = @id ORDER BY amr.SortOrder;";

            using (var cmd = new SQLiteCommand(missionReqQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", assemblyId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    var req = new MissionRequirement(
                        reader["MissionRequirementID"] as string,
                        reader["Name"] as string
                    );
                    assembly.MissionRequirements.Add(req);
                }
            }

            // ----------------------------------------------------------
            // 13. Load SystemRequirements from junction table
            // ----------------------------------------------------------
            const string systemReqQuery =
                "SELECT sr.SystemRequirementID, sr.Name " +
                "FROM CAD_Assembly_SystemRequirement asr " +
                "JOIN SystemRequirement sr ON asr.SystemRequirementID = sr.SystemRequirementID " +
                "WHERE asr.AssemblyID = @id ORDER BY asr.SortOrder;";

            using (var cmd = new SQLiteCommand(systemReqQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", assemblyId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    var req = new SystemRequirement(
                        reader["SystemRequirementID"] as string,
                        reader["Name"] as string
                    );
                    assembly.SystemRequirements.Add(req);
                }
            }

            // ----------------------------------------------------------
            // 14. Load MyInterfaces from junction table
            // ----------------------------------------------------------
            const string interfacesQuery =
                "SELECT InterfaceID FROM CAD_Assembly_Interface " +
                "WHERE AssemblyID = @id ORDER BY SortOrder;";

            using (var cmd = new SQLiteCommand(interfacesQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", assemblyId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string ifaceId = reader["InterfaceID"] as string ?? "";
                    var iface = LoadInterface(connection, ifaceId);
                    if (iface != null) assembly.MyInterfaces.Add(iface);
                }
            }

            // ----------------------------------------------------------
            // 15. Load Stations from junction table (categorized)
            // ----------------------------------------------------------
            const string stationsQuery =
                "SELECT StationID, StationCategory FROM CAD_Assembly_Station " +
                "WHERE AssemblyID = @id ORDER BY StationCategory, SortOrder;";

            using (var cmd = new SQLiteCommand(stationsQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", assemblyId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string stationId = reader["StationID"] as string ?? "";
                    string category = reader["StationCategory"] as string ?? "";
                    var station = LoadStation(connection, stationId);
                    if (station == null) continue;

                    switch (category)
                    {
                        case "Axial": assembly.AxialStations.Add(station); break;
                        case "Radial": assembly.RadialStations.Add(station); break;
                        case "Angular": assembly.AngularStations.Add(station); break;
                        case "Wing": assembly.WingStations.Add(station); break;
                    }
                }
            }

            return assembly;
        }

        // -----------------------------
        // Private SQL helper methods
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

            var startPt = startPtId != null ? LoadPoint(connection, startPtId) : new Mathematics.Point();
            var endPt = endPtId != null ? LoadPoint(connection, endPtId) : new Mathematics.Point();

            var vec = new Mathematics.Vector(startPt!, endPt!)
            {
                X_Value = Convert.ToDouble(reader["X_Value"]),
                Y_Value = Convert.ToDouble(reader["Y_Value"]),
                Z_Value = Convert.ToDouble(reader["Z_Value"])
            };

            return vec;
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
            if (origin != null)
            {
                csys.OriginLocation = origin;
            }

            return csys;
        }

        private static CAD_Component? LoadComponent(SQLiteConnection connection, string componentId)
        {
            const string query =
                "SELECT ComponentID, Name, Version, Path, IsAssembly, IsConfigurationItem, WBS_Level " +
                "FROM CAD_Component WHERE ComponentID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", componentId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Component
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                Path = reader["Path"] as string,
                IsAssembly = Convert.ToInt32(reader["IsAssembly"]) != 0,
                IsConfigurationItem = Convert.ToInt32(reader["IsConfigurationItem"]) != 0,
                WBS_Level = Convert.ToInt32(reader["WBS_Level"])
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

        private static CAD_Configuration? LoadConfiguration(SQLiteConnection connection, string configId)
        {
            const string query =
                "SELECT ConfigurationID, Name, Description, ID, Revision " +
                "FROM CAD_Configuration WHERE ConfigurationID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", configId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Configuration
            {
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                ID = reader["ID"] as string,
                Revision = reader["Revision"] as string
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


