#nullable enable
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Represents a sketch plane (workplane) with a coordinate system, a normal, and owned sketches.
    /// </summary>
    public sealed class CAD_SketchPlane
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum GeometryTypeEnum
        {
            Cartesian = 0,
            Spherical,
            Cylindrical // fixed spelling
        }

        public enum FunctionalTypeEnum
        {
            Interface = 0,
            Section,
            GeometricBoundary,
            Feature,
            CoordinateSystemOrigin,
            Incremental
        }

        // -----------------------------
        // Backing storage
        // -----------------------------
        private readonly List<CAD_Sketch> _sketches = new();

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_SketchPlane() { }

        public CAD_SketchPlane(string name,
                               FunctionalTypeEnum functionalType = FunctionalTypeEnum.Feature,
                               GeometryTypeEnum geometryType = GeometryTypeEnum.Cartesian)
        {
            Name = name;
            FunctionalType = functionalType;
            GeometryType = geometryType;
        }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? Version { get; set; }
        public string? Path { get; set; }

        // -----------------------------
        // Data / flags
        // -----------------------------
        public bool IsWorkplane { get; set; } = true;
        public GeometryTypeEnum GeometryType { get; set; } = GeometryTypeEnum.Cartesian;
        public FunctionalTypeEnum FunctionalType { get; set; } = FunctionalTypeEnum.Feature;

        // -----------------------------
        // Ownership
        // -----------------------------
        /// <summary>Owning model, if any.</summary>
        public CAD_Model? MyModel { get; set; }

        /// <summary>Coordinate system used by this plane (origin + axes).</summary>
        public CoordinateSystem? MyCoordinateSystem { get; set; }

        /// <summary>Unit normal vector (model units) describing plane orientation.</summary>
        public Vector? NormalVector { get; private set; }

        /// <summary>Currently active/selected sketch on this plane.</summary>
        public CAD_Sketch? CurrentSketch { get; private set; }

        /// <summary>All sketches associated with this plane.</summary>
        public IReadOnlyList<CAD_Sketch> Sketches => _sketches;

        // -----------------------------
        // Mutators / helpers
        // -----------------------------
        public CAD_SketchPlane AddSketch(CAD_Sketch sketch, bool makeCurrent = true)
        {
            if (sketch is null) throw new ArgumentNullException(nameof(sketch));
            _sketches.Add(sketch);
            if (makeCurrent) CurrentSketch = sketch;
            return this;
        }

        public bool TrySetCurrentSketch(CAD_Sketch sketch)
        {
            if (sketch is null) return false;
            if (_sketches.Contains(sketch))
            {
                CurrentSketch = sketch;
                return true;
            }
            return false;
        }

        /// <summary>
        /// Sets the plane normal from raw components. Normalized if <paramref name="normalize"/> is true.
        /// </summary>
        public CAD_SketchPlane SetNormal(double nx, double ny, double nz, bool normalize = true)
        {
            // Build a minimal Vector instance from (0,0,0) -> (nx,ny,nz)
            var start = new Mathematics.Point { X_Value = 0, Y_Value = 0, Z_Value_Cartesian = 0 };
            var end = new Mathematics.Point { X_Value = nx, Y_Value = ny, Z_Value_Cartesian = nz };
            var v = new Vector(start, end) { VectorType = Vector.VectorTypeEnum.Cartesian };

            if (normalize)
            {
                var len = Math.Sqrt(nx * nx + ny * ny + nz * nz);
                if (len > 0)
                {
                    v.X_Value = nx / len;
                    v.Y_Value = ny / len;
                    v.Z_Value = nz / len;
                }
            }
            else
            {
                v.X_Value = nx; v.Y_Value = ny; v.Z_Value = nz;
            }

            NormalVector = v;
            return this;
        }

        public override string ToString()
            => $"{Name ?? "SketchPlane"} [{FunctionalType}, {GeometryType}]  IsWorkplane={IsWorkplane}";

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_SketchPlane? FromJson(string json) => JsonConvert.DeserializeObject<CAD_SketchPlane>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_SketchPlane"/> from a SQLite database whose schema matches
        /// <c>CAD_SketchPlane_Schema.sql</c>.
        /// </summary>
        public static CAD_SketchPlane? FromSql(SQLiteConnection connection, string sketchPlaneId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(sketchPlaneId)) throw new ArgumentException("Sketch plane ID must not be empty.", nameof(sketchPlaneId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_SketchPlane row
            // ----------------------------------------------------------
            const string query =
                "SELECT SketchPlaneID, Name, Version, Path, IsWorkplane, " +
                "       GeometryType, FunctionalType, " +
                "       MyModelID, MyCoordinateSystemID, NormalVectorID, CurrentSketchID " +
                "FROM CAD_SketchPlane WHERE SketchPlaneID = @id;";

            CAD_SketchPlane? plane = null;
            string? modelId = null;
            string? csysId = null;
            string? normalVectorId = null;
            string? curSketchId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", sketchPlaneId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                plane = new CAD_SketchPlane
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    Path = reader["Path"] as string,
                    IsWorkplane = Convert.ToInt32(reader["IsWorkplane"]) != 0,
                    GeometryType = (GeometryTypeEnum)Convert.ToInt32(reader["GeometryType"]),
                    FunctionalType = (FunctionalTypeEnum)Convert.ToInt32(reader["FunctionalType"])
                };

                modelId = reader["MyModelID"] as string;
                csysId = reader["MyCoordinateSystemID"] as string;
                normalVectorId = reader["NormalVectorID"] as string;
                curSketchId = reader["CurrentSketchID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyModel
            // ----------------------------------------------------------
            if (modelId != null)
            {
                plane.MyModel = LoadModel(connection, modelId);
            }

            // ----------------------------------------------------------
            // 3. Load MyCoordinateSystem
            // ----------------------------------------------------------
            if (csysId != null)
            {
                plane.MyCoordinateSystem = LoadCoordinateSystem(connection, csysId);
            }

            // ----------------------------------------------------------
            // 4. Load NormalVector (via SetNormal)
            // ----------------------------------------------------------
            if (normalVectorId != null)
            {
                var (nx, ny, nz) = LoadVectorComponents(connection, normalVectorId);
                plane.SetNormal(nx, ny, nz, normalize: false);
            }

            // ----------------------------------------------------------
            // 5. Load Sketches from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_SketchPlane_Sketch", "SketchPlaneID", sketchPlaneId, "SketchID",
                id =>
                {
                    var sketch = LoadSketch(connection, id);
                    if (sketch != null)
                    {
                        bool makeCurrent = (id == curSketchId);
                        plane.AddSketch(sketch, makeCurrent);
                    }
                });

            return plane;
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

        private static CoordinateSystem? LoadCoordinateSystem(SQLiteConnection connection, string csysId)
        {
            const string query =
                "SELECT CoordinateSystemID, Name, OriginLocationPointID " +
                "FROM CoordinateSystem WHERE CoordinateSystemID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", csysId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            var cs = new CoordinateSystem();

            string? originPtId = reader["OriginLocationPointID"] as string;
            if (originPtId != null)
            {
                cs.OriginLocation = LoadPoint(connection, originPtId);
            }

            return cs;
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

        private static (double nx, double ny, double nz) LoadVectorComponents(SQLiteConnection connection, string vectorId)
        {
            const string query =
                "SELECT VectorID, X_Value, Y_Value, Z_Value " +
                "FROM Vector WHERE VectorID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", vectorId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return (0, 0, 0);

            return (
                Convert.ToDouble(reader["X_Value"]),
                Convert.ToDouble(reader["Y_Value"]),
                Convert.ToDouble(reader["Z_Value"])
            );
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
    }
}
