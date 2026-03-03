#nullable enable
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using System.Linq;
using Mathematics;
using System.Xml;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Lightweight, modernized refactor of the original CAD_Sketch class.
    /// - Uses readonly backing collections and read-only exposures (IReadOnlyList).
    /// - Adds small helper mutators (AddPoint / AddSegment) and validation helpers.
    /// - Improves the original WriteSketchToJSON to validate contiguity and produce JSON.
    /// - Keeps type references (Point, Segment, CAD_Parameter, etc.) from the original model.
    /// </summary>
    public class CAD_Sketch
    {
        // -----------------------
        // Backing fields
        // -----------------------
        private readonly List<Point> _points = new();
        private readonly List<Segment> _segments = new();
        private readonly List<CAD_Dimension> _dimensions = new();
        private readonly List<CAD_Parameter> _parameters = new();
        private readonly List<CAD_Constraint> _constraints = new();
        private readonly List<Segment> _profile = new();
        private readonly List<TwoDGeometry> _twoDGeometry = new();
        private readonly List<CoordinateSystem> _coordinateSystems = new();
        private readonly List<CAD_SketchElement> _sketchElements = new();

        // -----------------------
        // Construction
        // -----------------------
        public CAD_Sketch() { }

        public CAD_Sketch(string sketchId) => SketchID = sketchId;

        // -----------------------
        // Identification / metadata
        // -----------------------
        public string? SketchID { get; set; }
        public string? Version { get; set; }

        // -----------------------
        // Geometry summary parameters
        // -----------------------
        public CAD_Parameter? Area { get; set; }
        public CAD_Parameter? PerimeterLength { get; set; }

        // -----------------------
        // Ownership
        // -----------------------
        public CAD_Model? MyModel { get; set; }
        public CAD_SketchPlane? MySketchPlane { get; set; }

        // -----------------------
        // Flags / mode
        // -----------------------
        /// <summary>True when sketch is strictly 2D.</summary>
        public bool IsTwoD { get; set; }

        // -----------------------
        // Current cursors (optional helpers for editing workflows)
        // -----------------------
        public Point? CurrentPoint { get; private set; }
        public Segment? CurrentSegment { get; private set; }
        public Segment? PreviousSegment { get; private set; }
        public CAD_SketchElement? CurrentSketchElem { get; set; }
        public CAD_Parameter? CurrentParameter { get; set; }
        public CAD_Dimension? CurrentDimension { get; set; }
        public CAD_Constraint? CurrentConstraint { get; set; }
        public CoordinateSystem? CurrentCoordinateSystem { get; set; }
        public CoordinateSystem? BaseCoordinateSystem { get; set; }

        // -----------------------
        // Collections (read-only exposure)
        // -----------------------
        public IReadOnlyList<Point> MyPoints => _points;
        public IReadOnlyList<Segment> MySegments => _segments;
        public IReadOnlyList<Segment> MyProfile => _profile;
        public IReadOnlyList<TwoDGeometry> My2DGeometry => _twoDGeometry;
        public IReadOnlyList<CoordinateSystem> MyCoordinateSystems => _coordinateSystems;
        public IReadOnlyList<CAD_SketchElement> MySketchElements => _sketchElements;
        public IReadOnlyList<CAD_Parameter> MyParameters => _parameters;
        public IReadOnlyList<CAD_Dimension> MyDimensions => _dimensions;
        public IReadOnlyList<CAD_Constraint> MyConstraints => _constraints;

        // -----------------------
        // Mutators / helpers
        // -----------------------

        /// <summary>Add a point to the sketch and move the CurrentPoint cursor to it.</summary>
        public void AddPoint(Point point)
        {
            if (point is null) throw new ArgumentNullException(nameof(point));
            _points.Add(point);
            PreviousSegment = null;
            CurrentPoint = point;
        }

        /// <summary>Add a segment to the sketch and update segment cursors (CurrentSegment / PreviousSegment).</summary>
        public void AddSegment(Segment segment)
        {
            if (segment is null) throw new ArgumentNullException(nameof(segment));
            _segments.Add(segment);
            PreviousSegment = _segments.Count >= 2 ? _segments[^2] : null;
            CurrentSegment = segment;
        }

        public void AddDimension(CAD_Dimension dim)
        {
            if (dim is null) throw new ArgumentNullException(nameof(dim));
            _dimensions.Add(dim);
            CurrentDimension = dim;
        }

        public void AddParameter(CAD_Parameter parameter)
        {
            if (parameter is null) throw new ArgumentNullException(nameof(parameter));
            _parameters.Add(parameter);
            CurrentParameter = parameter;
        }

        public void AddConstraint(CAD_Constraint constraint)
        {
            if (constraint is null) throw new ArgumentNullException(nameof(constraint));
            _constraints.Add(constraint);
            CurrentConstraint = constraint;
        }

        public void AddSketchElement(CAD_SketchElement elem)
        {
            if (elem is null) throw new ArgumentNullException(nameof(elem));
            _sketchElements.Add(elem);
            CurrentSketchElem = elem;
        }

        public void AddCoordinateSystem(CoordinateSystem cs)
        {
            if (cs is null) throw new ArgumentNullException(nameof(cs));
            _coordinateSystems.Add(cs);
            CurrentCoordinateSystem = cs;
        }

        public void AddProfileSegment(Segment seg)
        {
            if (seg is null) throw new ArgumentNullException(nameof(seg));
            _profile.Add(seg);
        }

        public void AddTwoDGeometry(TwoDGeometry geo)
        {
            if (geo is null) throw new ArgumentNullException(nameof(geo));
            _twoDGeometry.Add(geo);
        }

        public void Clear()
        {
            _points.Clear();
            _segments.Clear();
            _dimensions.Clear();
            _parameters.Clear();
            _constraints.Clear();
            _profile.Clear();
            _twoDGeometry.Clear();
            _sketchElements.Clear();
            CurrentPoint = null;
            CurrentSegment = null;
            PreviousSegment = null;
        }

        // -----------------------
        // Validation helpers
        // -----------------------

        /// <summary>
        /// Validates that the provided segments form a contiguous chain where each segment's start equals the previous segment's end.
        /// </summary>
        /// <param name="segments">Segments to validate (if null uses sketch segments).</param>
        /// <param name="tolerance">Coordinate matching tolerance</param>
        /// <returns>True if contiguous (and non-empty), otherwise false.</returns>
        public bool ValidateContiguous(IReadOnlyList<Segment>? segments = null, double tolerance = 1e-9)
        {
            var list = segments ?? MySegments;
            if (list == null || list.Count == 0) return false;
            // Each segment must have a non-null StartPoint and EndPoint
            for (int i = 0; i < list.Count; ++i)
            {
                var seg = list[i];
                if (seg?.StartPoint is null || seg.EndPoint is null) return false;
                if (i > 0)
                {
                    var prev = list[i - 1];
                    if (prev?.EndPoint is null) return false;
                    if (!PointsMatch(prev.EndPoint, seg.StartPoint, tolerance)) return false;
                }
            }
            return true;
        }

        private static bool PointsMatch(Point a, Point b, double tol)
        {
            if (a is null || b is null) return false;
            var dx = a.X_Value - b.X_Value;
            var dy = a.Y_Value - b.Y_Value;
            var dz = a.Z_Value_Cartesian - b.Z_Value_Cartesian;
            return (dx * dx + dy * dy + dz * dz) <= tol * tol;
        }

        /// <summary>
        /// Attempts to determine whether a closed loop exists (first and last point equal within tolerance).
        /// Returns false if there are too few segments/points.
        /// </summary>
        public bool IsClosedLoop(double tolerance = 1e-9)
        {
            if (_segments.Count < 1) return false;
            var first = _segments.First().StartPoint;
            var last = _segments.Last().EndPoint;
            if (first is null || last is null) return false;
            return PointsMatch(first, last, tolerance);
        }

        // -----------------------
        // Serialization / original WriteSketchToJSON replacement
        // -----------------------

        /// <summary>
        /// Validates contiguity of segments and if valid serializes the segments into JSON.
        /// Produces a JSON string in the out parameter. Returns true when validation + serialization succeed.
        /// </summary>
        public bool WriteSketchToJSON(out string json, IReadOnlyList<Segment>? segments = null, double tolerance = 1e-9)
        {
            json = string.Empty;
            var list = segments ?? MySegments;
            if (!ValidateContiguous(list, tolerance)) return false;

            // Build a simple serializable representation to avoid attempting to serialize external types directly.
            var serializableSegments = list.Select(s => new
            {
                Start = new { X = s.StartPoint?.X_Value, Y = s.StartPoint?.Y_Value, Z = s.StartPoint?.Z_Value_Cartesian },
                End = new { X = s.EndPoint?.X_Value, Y = s.EndPoint?.Y_Value, Z = s.EndPoint?.Z_Value_Cartesian },
                SegmentID = s.SegmentID
            }).ToList();

            try
            {
                json = JsonConvert.SerializeObject(new
                {
                    SketchID,
                    Version,
                    IsTwoD,
                    Segments = serializableSegments
                }, Newtonsoft.Json.Formatting.Indented);

                return true;
            }
            catch
            {
                json = string.Empty;
                return false;
            }
        }

        /// <summary>
        /// Convenience wrapper matching the older signature: returns true/false based on success (json discarded).
        /// </summary>
        public bool WriteSketchToJSON(List<Segment> MySegments)
        {
            return WriteSketchToJSON(out _, MySegments);
        }

        // -----------------------
        // Simple sketching helper
        // -----------------------
        /// <summary>
        /// Adds a point to the sketch and updates the current point. Optionally performs CAD-app specific actions (kept for compatibility).
        /// </summary>
        public bool SketchAPoint(Point myPoint)
        {
            if (myPoint is null) return false;
            AddPoint(myPoint);

            // Placeholder: app-specific behavior can be added here if necessary.
            // For now we only update internal state and return success.
            return true;
        }

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Newtonsoft.Json.Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Sketch? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Sketch>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Sketch"/> from a SQLite database whose schema matches
        /// <c>CAD_Sketch_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="sketchId">The <c>SketchID</c> value of the sketch row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Sketch"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Sketch? FromSql(SQLiteConnection connection, string sketchId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(sketchId)) throw new ArgumentException("Sketch ID must not be empty.", nameof(sketchId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Sketch row
            // ----------------------------------------------------------
            const string sketchQuery =
                "SELECT SketchID, Version, IsTwoD, " +
                "       AreaParameterID, PerimeterLengthParameterID, " +
                "       MyModelID, MySketchPlaneID, " +
                "       CurrentPointID, CurrentSegmentID, PreviousSegmentID, " +
                "       CurrentSketchElemID, CurrentParameterID, CurrentDimensionID, " +
                "       CurrentConstraintID, CurrentCoordinateSystemID, BaseCoordinateSystemID " +
                "FROM CAD_Sketch WHERE SketchID = @id;";

            CAD_Sketch? sketch = null;
            string? areaParamId = null;
            string? perimParamId = null;
            string? modelId = null;
            string? sketchPlaneId = null;
            string? currentPointId = null;
            string? currentSegId = null;
            string? prevSegId = null;
            string? currentElemId = null;
            string? currentParamId = null;
            string? currentDimId = null;
            string? currentConstrId = null;
            string? currentCsysId = null;
            string? baseCsysId = null;

            using (var cmd = new SQLiteCommand(sketchQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", sketchId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                sketch = new CAD_Sketch
                {
                    SketchID = reader["SketchID"] as string,
                    Version = reader["Version"] as string,
                    IsTwoD = Convert.ToInt32(reader["IsTwoD"]) != 0
                };

                areaParamId = reader["AreaParameterID"] as string;
                perimParamId = reader["PerimeterLengthParameterID"] as string;
                modelId = reader["MyModelID"] as string;
                sketchPlaneId = reader["MySketchPlaneID"] as string;
                currentPointId = reader["CurrentPointID"] as string;
                currentSegId = reader["CurrentSegmentID"] as string;
                prevSegId = reader["PreviousSegmentID"] as string;
                currentElemId = reader["CurrentSketchElemID"] as string;
                currentParamId = reader["CurrentParameterID"] as string;
                currentDimId = reader["CurrentDimensionID"] as string;
                currentConstrId = reader["CurrentConstraintID"] as string;
                currentCsysId = reader["CurrentCoordinateSystemID"] as string;
                baseCsysId = reader["BaseCoordinateSystemID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load scalar references
            // ----------------------------------------------------------
            if (areaParamId != null)
                sketch.Area = LoadCAD_Parameter(connection, areaParamId);

            if (perimParamId != null)
                sketch.PerimeterLength = LoadCAD_Parameter(connection, perimParamId);

            if (modelId != null)
                sketch.MyModel = LoadModel(connection, modelId);

            if (sketchPlaneId != null)
                sketch.MySketchPlane = LoadSketchPlane(connection, sketchPlaneId);

            if (currentCsysId != null)
                sketch.CurrentCoordinateSystem = LoadCoordinateSystem(connection, currentCsysId);

            if (baseCsysId != null)
                sketch.BaseCoordinateSystem = LoadCoordinateSystem(connection, baseCsysId);

            if (currentElemId != null)
                sketch.CurrentSketchElem = LoadSketchElement(connection, currentElemId);

            if (currentParamId != null)
                sketch.CurrentParameter = LoadCAD_Parameter(connection, currentParamId);

            if (currentDimId != null)
                sketch.CurrentDimension = LoadCAD_Dimension(connection, currentDimId);

            if (currentConstrId != null)
                sketch.CurrentConstraint = LoadConstraint(connection, currentConstrId);

            // CurrentPoint, CurrentSegment, PreviousSegment are private set —
            // load them via the Add helpers after loading collections below.

            // ----------------------------------------------------------
            // 3. Load MyPoints from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Sketch_Point", "SketchID", sketchId, "PointID",
                id => { var pt = LoadPoint(connection, id); if (pt != null) sketch.AddPoint(pt); });

            // ----------------------------------------------------------
            // 4. Load MySegments from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Sketch_Segment", "SketchID", sketchId, "SegmentID",
                id => { var seg = LoadSegment(connection, id); if (seg != null) sketch.AddSegment(seg); });

            // ----------------------------------------------------------
            // 5. Load MyProfile from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Sketch_ProfileSegment", "SketchID", sketchId, "SegmentID",
                id => { var seg = LoadSegment(connection, id); if (seg != null) sketch.AddProfileSegment(seg); });

            // ----------------------------------------------------------
            // 6. Load My2DGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Sketch_TwoDGeometry", "SketchID", sketchId, "TwoDGeometryID",
                id => { var geo = LoadTwoDGeometry(connection, id); if (geo != null) sketch.AddTwoDGeometry(geo); });

            // ----------------------------------------------------------
            // 7. Load MyCoordinateSystems from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Sketch_CoordinateSystem", "SketchID", sketchId, "CoordinateSystemID",
                id => { var cs = LoadCoordinateSystem(connection, id); if (cs != null) sketch.AddCoordinateSystem(cs); });

            // ----------------------------------------------------------
            // 8. Load MySketchElements from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Sketch_SketchElement", "SketchID", sketchId, "SketchElementID",
                id => { var elem = LoadSketchElement(connection, id); if (elem != null) sketch.AddSketchElement(elem); });

            // ----------------------------------------------------------
            // 9. Load MyParameters from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Sketch_Parameter", "SketchID", sketchId, "ParameterID",
                id => { var p = LoadCAD_Parameter(connection, id); if (p != null) sketch.AddParameter(p); });

            // ----------------------------------------------------------
            // 10. Load MyDimensions from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Sketch_Dimension", "SketchID", sketchId, "DimensionID",
                id => { var d = LoadCAD_Dimension(connection, id); if (d != null) sketch.AddDimension(d); });

            // ----------------------------------------------------------
            // 11. Load MyConstraints from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Sketch_Constraint", "SketchID", sketchId, "ConstraintID",
                id => { var c = LoadConstraint(connection, id); if (c != null) sketch.AddConstraint(c); });

            return sketch;
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

        private static Segment? LoadSegment(SQLiteConnection connection, string segmentId)
        {
            const string query =
                "SELECT SegmentID, SegmentType, IsEdge, Length, StartPointID, EndPointID, MidPointID " +
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
            var csys = new CoordinateSystem();
            if (originId != null)
            {
                var origin = LoadPoint(connection, originId);
                if (origin != null) csys.OriginLocation = origin;
            }
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

        private static CAD_Parameter? LoadCAD_Parameter(SQLiteConnection connection, string paramId)
        {
            const string query =
                "SELECT Id, Name, Description, Comments, MyParameterType, " +
                "       SolidWorksParameterName, Fusion360ParameterName " +
                "FROM CAD_Parameter WHERE Id = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", paramId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Parameter
            {
                Id = reader["Id"] as string,
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                Comments = reader["Comments"] as string,
                MyParameterType = (CAD_Parameter.ParameterType)Convert.ToInt32(reader["MyParameterType"]),
                SolidWorksParameterName = reader["SolidWorksParameterName"] as string,
                Fusion360ParameterName = reader["Fusion360ParameterName"] as string
            };
        }

        private static CAD_Dimension? LoadCAD_Dimension(SQLiteConnection connection, string dimId)
        {
            const string query =
                "SELECT DimensionID, Name, Description, IsOrdinate, " +
                "       DimensionNominalValue, DimensionUpperLimitValue, DimensionLowerLimitValue, " +
                "       MyDimensionType " +
                "FROM CAD_Dimension WHERE DimensionID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", dimId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Dimension
            {
                DimensionID = reader["DimensionID"] as string ?? "",
                Name = reader["Name"] as string ?? "",
                Description = reader["Description"] as string ?? "",
                IsOrdinate = Convert.ToInt32(reader["IsOrdinate"]) != 0,
                DimensionNominalValue = Convert.ToDouble(reader["DimensionNominalValue"]),
                DimensionUpperLimitValue = Convert.ToDouble(reader["DimensionUpperLimitValue"]),
                DimensionLowerLimitValue = Convert.ToDouble(reader["DimensionLowerLimitValue"]),
                MyDimensionType = (CAD_Dimension.DimensionType)Convert.ToInt32(reader["MyDimensionType"])
            };
        }

        private static CAD_Constraint? LoadConstraint(SQLiteConnection connection, string constraintId)
        {
            const string query =
                "SELECT ConstraintID, Name, ID, Description, Type " +
                "FROM CAD_Constraint WHERE ConstraintID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", constraintId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Constraint
            {
                Name = reader["Name"] as string,
                ID = reader["ID"] as string,
                Description = reader["Description"] as string,
                Type = (CAD_Constraint.ConstraintType)Convert.ToInt32(reader["Type"])
            };
        }

        private static CAD_SketchElement? LoadSketchElement(SQLiteConnection connection, string elemId)
        {
            const string query =
                "SELECT SketchElementID, Name, Version, Path, ElementType, IsWorkElement " +
                "FROM CAD_SketchElement WHERE SketchElementID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", elemId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_SketchElement
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                Path = reader["Path"] as string,
                ElementType = (CAD_SketchElement.SketchElemTypeEnum)Convert.ToInt32(reader["ElementType"]),
                IsWorkElement = Convert.ToInt32(reader["IsWorkElement"]) != 0
            };
        }

        private static TwoDGeometry? LoadTwoDGeometry(SQLiteConnection connection, string geoId)
        {
            const string query =
                "SELECT TwoDGeometryID, GeometryID, GeometryType, IsClosed, IsConstructionGeometry " +
                "FROM TwoDGeometry WHERE TwoDGeometryID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", geoId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new TwoDGeometry();
        }
    }
}

