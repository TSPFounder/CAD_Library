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
    /// A geometric element within a sketch (points, lines, arcs, etc.).
    /// </summary>
    public sealed class CAD_SketchElement
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum SketchElemTypeEnum
        {
            StartPoint = 0,
            EndPoint,
            MidPoint,
            ControlPoint,
            Line,
            Rectangle,
            Circle,
            Parabola,
            Ellipse,
            Contour,
            Arc,
            Spline,
            Slot,
            BreakLine,
            Centerline,
            Centerpoint,
            WorkPoint,
            WorkLine
        }

        // -----------------------------
        // Backing fields
        // -----------------------------
        private readonly List<Point> _points = new();
        private readonly List<Primitive> _primitives = new();

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_SketchElement() { }

        public CAD_SketchElement(
            SketchElemTypeEnum elementType,
            string? name = null,
            string? version = null,
            string? path = null)
        {
            ElementType = elementType;
            Name = name;
            Version = version;
            Path = path;
        }

        // -----------------------------
        // Identity
        // -----------------------------
        public string? Name { get; set; }
        public string? Version { get; set; }
        public string? Path { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        public SketchElemTypeEnum ElementType { get; set; }

        /// <summary>Marks this element as a work/reference element.</summary>
        public bool IsWorkElement { get; set; }

        // -----------------------------
        // Geometry (owned)
        // -----------------------------
        public Point? CurrentPoint { get; private set; }
        public Point? StartPoint { get; set; }
        public Point? EndPoint { get; set; }
        public Point? MidPoint { get; set; }
        public Point? ControlPoint { get; set; }

        public Primitive? CurrentPrimitive { get; private set; }

        /// <summary>All points associated with this sketch element.</summary>
        public IReadOnlyList<Point> Points => _points;

        /// <summary>All geometric primitives (lines, arcs, splines) for this element.</summary>
        public IReadOnlyList<Primitive> Primitives => _primitives;

        // -----------------------------
        // Operations
        // -----------------------------
        /// <summary>
        /// Adds a point to this element. Optionally sets it as the current point and/or marks the element as a work element.
        /// </summary>
        public Point AddPoint(Point? point = null, bool makeCurrent = true, bool isWorkPoint = false)
        {
            var p = point ?? new Point();
            _points.Add(p);

            if (makeCurrent)
                CurrentPoint = p;

            // Corrected: compare, don't assign.
            if (isWorkPoint)
                IsWorkElement = true;

            return p;
        }

        /// <summary>
        /// Adds a primitive to this element and sets it as current.
        /// </summary>
        public Primitive AddPrimitive(Primitive primitive)
        {
            if (primitive is null) throw new ArgumentNullException(nameof(primitive));
            _primitives.Add(primitive);
            CurrentPrimitive = primitive;
            return primitive;
        }

        /// <summary>
        /// Clears all geometry (points and primitives) and resets current references.
        /// </summary>
        public void ClearGeometry()
        {
            _points.Clear();
            _primitives.Clear();
            CurrentPoint = null;
            CurrentPrimitive = null;
        }

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_SketchElement? FromJson(string json) => JsonConvert.DeserializeObject<CAD_SketchElement>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_SketchElement"/> from a SQLite database whose schema matches
        /// <c>CAD_SketchElement_Schema.sql</c>.
        /// </summary>
        public static CAD_SketchElement? FromSql(SQLiteConnection connection, string sketchElementId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(sketchElementId)) throw new ArgumentException("Sketch element ID must not be empty.", nameof(sketchElementId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_SketchElement row
            // ----------------------------------------------------------
            const string query =
                "SELECT SketchElementID, Name, Version, Path, ElementType, IsWorkElement, " +
                "       CurrentPointID, StartPointID, EndPointID, MidPointID, ControlPointID, " +
                "       CurrentPrimitiveID " +
                "FROM CAD_SketchElement WHERE SketchElementID = @id;";

            CAD_SketchElement? elem = null;
            string? curPointId = null;
            string? startPtId = null;
            string? endPtId = null;
            string? midPtId = null;
            string? controlPtId = null;
            string? curPrimitiveId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", sketchElementId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                elem = new CAD_SketchElement
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    Path = reader["Path"] as string,
                    ElementType = (SketchElemTypeEnum)Convert.ToInt32(reader["ElementType"]),
                    IsWorkElement = Convert.ToInt32(reader["IsWorkElement"]) != 0
                };

                curPointId = reader["CurrentPointID"] as string;
                startPtId = reader["StartPointID"] as string;
                endPtId = reader["EndPointID"] as string;
                midPtId = reader["MidPointID"] as string;
                controlPtId = reader["ControlPointID"] as string;
                curPrimitiveId = reader["CurrentPrimitiveID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load named point references
            // ----------------------------------------------------------
            if (startPtId != null)
                elem.StartPoint = LoadPoint(connection, startPtId);

            if (endPtId != null)
                elem.EndPoint = LoadPoint(connection, endPtId);

            if (midPtId != null)
                elem.MidPoint = LoadPoint(connection, midPtId);

            if (controlPtId != null)
                elem.ControlPoint = LoadPoint(connection, controlPtId);

            // ----------------------------------------------------------
            // 3. Load Points collection from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_SketchElement_Point", "SketchElementID", sketchElementId, "PointID",
                id =>
                {
                    var pt = LoadPoint(connection, id);
                    if (pt != null)
                    {
                        bool makeCurrent = (id == curPointId);
                        elem.AddPoint(pt, makeCurrent);
                    }
                });

            // If CurrentPoint wasn't in the junction table, load and add it directly
            if (curPointId != null && elem.CurrentPoint == null)
            {
                var curPt = LoadPoint(connection, curPointId);
                if (curPt != null) elem.AddPoint(curPt, makeCurrent: true);
            }

            // ----------------------------------------------------------
            // 4. Load Primitives collection from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_SketchElement_Primitive", "SketchElementID", sketchElementId, "PrimitiveID",
                id =>
                {
                    var prim = LoadPrimitive(connection, id);
                    if (prim != null) elem.AddPrimitive(prim);
                });

            return elem;
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

        private static Primitive? LoadPrimitive(SQLiteConnection connection, string primitiveId)
        {
            const string query =
                "SELECT PrimitiveID, TwoDType, ThreeDType " +
                "FROM Primitive WHERE PrimitiveID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", primitiveId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Primitive();
        }
    }
}
