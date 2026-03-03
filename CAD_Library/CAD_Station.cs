#nullable enable
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// A design “station” (axial, radial, angular, or wing) used to place sketch planes and
    /// reference locations in a CAD model (e.g., fuselage stations, wing stations, frames).
    /// </summary>
    public sealed class CAD_Station
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum StationTypeEnum
        {
            Axial = 0,
            Radial,
            Angular,
            Wing,
            Other
        }

        // -----------------------------
        // Backing storage
        // -----------------------------
        private readonly List<CAD_SketchPlane> _sketchPlanes = new();

        // -----------------------------
        // Construction
        // -----------------------------
        /*
        public CAD_Station(CAD_SketchPlane myPlane) {
            _sketchPlanes.Add(myPlane);
        }
        */

        public CAD_Station(CAD_SketchPlane myPlane,string id, StationTypeEnum type)
        {
            _sketchPlanes.Add(myPlane);
            ID = id;
            MyType = type;
        }


        
        public CAD_Station(string id, StationTypeEnum type, double value) //: this(id, type)
        {
            SetLocation(type, value);
        }
        


        // -----------------------------
        // Identity
        // -----------------------------
        /// <summary>Display name (optional).</summary>
        public string? Name { get; set; }

        /// <summary>Unique identifier (optional but recommended).</summary>
        public string? ID { get; set; }

        public string? Version { get; set; }

        // -----------------------------
        // Station data
        // -----------------------------
        public StationTypeEnum MyType { get; set; } = StationTypeEnum.Axial;

        /// <summary>Axial location (e.g., along fuselage X), in model units.</summary>
        public double AxialLocation { get; private set; }

        /// <summary>Radial location (e.g., radius from axis), in model units.</summary>
        public double RadialLocation { get; private set; }

        /// <summary>Angular location (e.g., degrees about axis unless your model uses radians).</summary>
        public double AngularLocation { get; private set; }

        /// <summary>Wing station location (e.g., spanwise), in model units.</summary>
        public double WingLocation { get; private set; }

        /// <summary>Floor location (e.g., vertical height), in model units.</summary>
        public double FloorLocation { get; private set; }

        // -----------------------------
        // Ownership
        // -----------------------------
        /// <summary>Owning CAD model (if any).</summary>
        public CAD_Model? MyModel { get; set; }

        /// <summary>The currently active sketch plane at this station, if one is selected.</summary>
        public CAD_SketchPlane? CurrentSketchPlane { get; private set; }

        /// <summary>All sketch planes associated with this station.</summary>
        public IReadOnlyList<CAD_SketchPlane> MySketchPlanes => _sketchPlanes;

        // -----------------------------
        // Mutators / helpers
        // -----------------------------
        /// <summary>
        /// Sets the primary location value according to <paramref name="type"/>.
        /// Other location fields are left unchanged.
        /// </summary>
        public CAD_Station SetLocation(StationTypeEnum type, double value)
        {
            MyType = type;
            switch (type)
            {
                case StationTypeEnum.Axial: AxialLocation = value; break;
                case StationTypeEnum.Radial: RadialLocation = value; break;
                case StationTypeEnum.Angular: AngularLocation = value; break;
                case StationTypeEnum.Wing: WingLocation = value; break;
                case StationTypeEnum.Other:   /* no-op */              break;
                default: throw new ArgumentOutOfRangeException(nameof(type));
            }
            return this;
        }

        /// <summary>Adds a sketch plane and optionally makes it the current plane.</summary>
        public CAD_Station AddSketchPlane(CAD_SketchPlane plane, bool makeCurrent = true)
        {
            if (plane is null) throw new ArgumentNullException(nameof(plane));
            _sketchPlanes.Add(plane);
            if (makeCurrent) CurrentSketchPlane = plane;
            return this;
        }

        /// <summary>Sets the <see cref="CurrentSketchPlane"/> if it is already associated with this station.</summary>
        public bool TrySetCurrentSketchPlane(CAD_SketchPlane plane)
        {
            if (plane is null) return false;
            if (_sketchPlanes.Contains(plane))
            {
                CurrentSketchPlane = plane;
                return true;
            }
            return false;
        }

        /// <summary>Simple string for debugging/diagnostics.</summary>
        public override string ToString()
            => $"{MyType} Station (ID: {ID ?? "—"}, Axial={AxialLocation}, Radial={RadialLocation}, Angular={AngularLocation}, Wing={WingLocation})";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Station? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Station>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Station"/> from a SQLite database whose schema matches
        /// <c>CAD_Station_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="stationId">The <c>StationID</c> value of the station row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Station"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Station? FromSql(SQLiteConnection connection, string stationId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(stationId)) throw new ArgumentException("Station ID must not be empty.", nameof(stationId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Station row
            // ----------------------------------------------------------
            const string stationQuery =
                "SELECT StationID, Name, ID, Version, MyType, " +
                "       AxialLocation, RadialLocation, AngularLocation, WingLocation, FloorLocation, " +
                "       MyModelID, CurrentSketchPlaneID " +
                "FROM CAD_Station WHERE StationID = @id;";

            CAD_Station? station = null;
            string? modelId = null;
            string? currentPlaneId = null;

            using (var cmd = new SQLiteCommand(stationQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", stationId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                var stationType = (StationTypeEnum)Convert.ToInt32(reader["MyType"]);
                double locationValue = stationType switch
                {
                    StationTypeEnum.Axial => Convert.ToDouble(reader["AxialLocation"]),
                    StationTypeEnum.Radial => Convert.ToDouble(reader["RadialLocation"]),
                    StationTypeEnum.Angular => Convert.ToDouble(reader["AngularLocation"]),
                    StationTypeEnum.Wing => Convert.ToDouble(reader["WingLocation"]),
                    _ => 0.0
                };

                station = new CAD_Station(reader["ID"] as string ?? "", stationType, locationValue)
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string
                };

                modelId = reader["MyModelID"] as string;
                currentPlaneId = reader["CurrentSketchPlaneID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyModel
            // ----------------------------------------------------------
            if (modelId != null)
            {
                station.MyModel = LoadModel(connection, modelId);
            }

            // ----------------------------------------------------------
            // 3. Load CurrentSketchPlane
            // ----------------------------------------------------------
            if (currentPlaneId != null)
            {
                var plane = LoadSketchPlane(connection, currentPlaneId);
                if (plane != null) station.AddSketchPlane(plane, makeCurrent: true);
            }

            // ----------------------------------------------------------
            // 4. Load MySketchPlanes from junction table
            // ----------------------------------------------------------
            const string planesQuery =
                "SELECT SketchPlaneID FROM CAD_Station_SketchPlane " +
                "WHERE StationID = @id ORDER BY SortOrder;";

            using (var cmd = new SQLiteCommand(planesQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", stationId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string planeId = reader["SketchPlaneID"] as string ?? "";
                    // Skip if already added as the current sketch plane
                    if (planeId == currentPlaneId) continue;

                    var plane = LoadSketchPlane(connection, planeId);
                    if (plane != null) station.AddSketchPlane(plane, makeCurrent: false);
                }
            }

            return station;
        }

        // -----------------------------
        // Private SQL helpers
        // -----------------------------

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

        private static CAD_SketchPlane? LoadSketchPlane(SQLiteConnection connection, string planeId)
        {
            const string query =
                "SELECT SketchPlaneID, Name, Version, Path, IsWorkplane, GeometryType, FunctionalType " +
                "FROM CAD_SketchPlane WHERE SketchPlaneID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", planeId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_SketchPlane
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                Path = reader["Path"] as string,
                IsWorkplane = Convert.ToInt32(reader["IsWorkplane"]) != 0,
                GeometryType = (CAD_SketchPlane.GeometryTypeEnum)Convert.ToInt32(reader["GeometryType"]),
                FunctionalType = (CAD_SketchPlane.FunctionalTypeEnum)Convert.ToInt32(reader["FunctionalType"])
            };
        }
    }
}
