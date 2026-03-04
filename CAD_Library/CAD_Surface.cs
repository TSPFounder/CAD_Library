#nullable enable
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Lightweight wrapper for a geometric surface within a CAD body.
    /// Holds scalar properties (area/perimeter/length) and one-or-more triangulated meshes.
    /// </summary>
    public class CAD_Surface : Surface
    {
        // -----------------------------
        // Enums (unchanged)
        // -----------------------------
        public enum SurfaceTypeEnum
        {
            Plane = 0,
            Circle,
            Ellipse,
            Trainangle,
            Square,
            Rectangle,
            Quadrilateral,
            Polygon,
            Cylinder,
            Cone,
            Sphere,
            Torus,
            NURBS,
            TwoDMesh,
            ThreeDMesh,
            Other
        }

        // -----------------------------
        // State
        // -----------------------------
        private readonly List<Mesh> _meshes = new();

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_Surface() { }

        public CAD_Surface(string? id, string? name = null, string? version = null) : this()
        {
            ID = id;
            Name = name;
            Version = version;
        }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? ID { get; set; }
        public string? Version { get; set; }
        public string? Description { get; set; }
        public SurfaceTypeEnum SurfaceType { get; set; } 

        // -----------------------------
        // Scalar data
        // -----------------------------
        /// <summary>Total developed length (for curve-like surfaces), optional.</summary>
        public double? Length { get; set; }

        /// <summary>Surface area.</summary>
        public double? Area { get; set; }

        /// <summary>Boundary perimeter length (sum of edge loop lengths).</summary>
        public double? Perimeter { get; set; }

        // -----------------------------
        // Ownership / relationships
        // -----------------------------
        /// <summary>
        /// Optional reference to the underlying analytic/parametric surface
        /// this object was derived from (distinct from this derived type which
        /// already inherits <see cref="Surface"/> for convenience).
        /// </summary>
        public Surface? SourceSurface { get; set; }

        /// <summary>Owning CAD body, if any.</summary>
        public CAD_Body? MyBody { get; set; }

        // -----------------------------
        // Meshes
        // -----------------------------
        /// <summary>The most recently added or explicitly selected mesh.</summary>
        public Mesh? CurrentMesh { get; private set; }

        /// <summary>All meshes associated with this surface (read-only view).</summary>
        public IReadOnlyList<Mesh> Meshes => _meshes;

        /// <summary>Adds a mesh and makes it the <see cref="CurrentMesh"/>.</summary>
        public void AddMesh(Mesh mesh)
        {
            if (mesh is null) throw new ArgumentNullException(nameof(mesh));
            _meshes.Add(mesh);
            CurrentMesh = mesh;
        }

        /// <summary>Removes a mesh; updates <see cref="CurrentMesh"/> if needed.</summary>
        public bool RemoveMesh(Mesh mesh)
        {
            if (mesh is null) return false;
            var removed = _meshes.Remove(mesh);
            if (removed && ReferenceEquals(CurrentMesh, mesh))
                CurrentMesh = _meshes.Count > 0 ? _meshes[^1] : null;
            return removed;
        }

        /// <summary>Clears all meshes and resets <see cref="CurrentMesh"/>.</summary>
        public void ClearMeshes()
        {
            _meshes.Clear();
            CurrentMesh = null;
        }

        /// <summary>Explicitly sets which mesh is considered current.</summary>
        public void SetCurrentMesh(Mesh mesh)
        {
            if (mesh is null) throw new ArgumentNullException(nameof(mesh));
            if (!_meshes.Contains(mesh))
                _meshes.Add(mesh);
            CurrentMesh = mesh;
        }

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Surface? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Surface>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Surface"/> from a SQLite database whose schema matches
        /// <c>CAD_Surface_Schema.sql</c>.
        /// </summary>
        public static CAD_Surface? FromSql(SQLiteConnection connection, string surfaceId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(surfaceId)) throw new ArgumentException("Surface ID must not be empty.", nameof(surfaceId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Surface row
            // ----------------------------------------------------------
            const string query =
                "SELECT SurfaceID, Name, Version, Description, SurfaceType, " +
                "       Length, Area, Perimeter, " +
                "       MyBodyID, CurrentMeshID " +
                "FROM CAD_Surface WHERE SurfaceID = @id;";

            CAD_Surface? surface = null;
            string? bodyId = null;
            string? curMeshId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", surfaceId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                surface = new CAD_Surface
                {
                    ID = reader["SurfaceID"] as string,
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    Description = reader["Description"] as string,
                    SurfaceType = (SurfaceTypeEnum)Convert.ToInt32(reader["SurfaceType"])
                };

                if (reader["Length"] is not DBNull)
                    surface.Length = Convert.ToDouble(reader["Length"]);

                if (reader["Area"] is not DBNull)
                    surface.Area = Convert.ToDouble(reader["Area"]);

                if (reader["Perimeter"] is not DBNull)
                    surface.Perimeter = Convert.ToDouble(reader["Perimeter"]);

                bodyId = reader["MyBodyID"] as string;
                curMeshId = reader["CurrentMeshID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyBody
            // ----------------------------------------------------------
            if (bodyId != null)
            {
                surface.MyBody = LoadBody(connection, bodyId);
            }

            // ----------------------------------------------------------
            // 3. Load Meshes from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Surface_Mesh", "SurfaceID", surfaceId, "MeshID",
                id =>
                {
                    var mesh = LoadMesh(connection, id);
                    if (mesh != null)
                    {
                        if (id == curMeshId)
                            surface.SetCurrentMesh(mesh);
                        else
                            surface.AddMesh(mesh);
                    }
                });

            // If CurrentMesh wasn't in the junction table, load directly
            if (curMeshId != null && surface.CurrentMesh == null)
            {
                var mesh = LoadMesh(connection, curMeshId);
                if (mesh != null) surface.SetCurrentMesh(mesh);
            }

            // ----------------------------------------------------------
            // 4. Load inherited Points from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Surface_Point", "SurfaceID", surfaceId, "PointID",
                id =>
                {
                    var pt = LoadPoint(connection, id);
                    if (pt != null) surface.Points.Add(pt);
                });

            // ----------------------------------------------------------
            // 5. Load inherited Segments from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Surface_Segment", "SurfaceID", surfaceId, "SegmentID",
                id =>
                {
                    var seg = LoadSegment(connection, id);
                    if (seg != null) surface.Segments.Add(seg);
                });

            // ----------------------------------------------------------
            // 6. Load inherited Perimeter segments from junction table
            //    (Perimeter segments are stored in the inherited Surface.Segments list
            //     alongside other segments; loaded here for completeness)
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Surface_Perimeter", "SurfaceID", surfaceId, "SegmentID",
                id =>
                {
                    var seg = LoadSegment(connection, id);
                    if (seg != null) surface.Segments.Add(seg);
                });

            return surface;
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

        private static CAD_Body? LoadBody(SQLiteConnection connection, string bodyId)
        {
            const string query =
                "SELECT BodyID, Name, Version, PartNumber " +
                "FROM CAD_Body WHERE BodyID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", bodyId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Body
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string
            };
        }

        private static Mesh? LoadMesh(SQLiteConnection connection, string meshId)
        {
            const string query =
                "SELECT MeshID, Name, ID, Version " +
                "FROM Mesh WHERE MeshID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", meshId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Mesh
            {
                Name = reader["Name"] as string,
                ID = reader["ID"] as string,
                Version = reader["Version"] as string
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

        private static Segment? LoadSegment(SQLiteConnection connection, string segmentId)
        {
            const string query =
                "SELECT SegmentID, StartPointID, EndPointID, MidPointID " +
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
    }
}
