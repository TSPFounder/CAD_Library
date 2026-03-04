
using System;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// A placed drawing view (orthographic, isometric, section, etc.) on a drawing sheet.
    /// </summary>
    public class CAD_DrawingView : CAD_DrawingElement
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum ViewType
        {
            OrthoTop,
            OrthoFront,
            OrthoRightSide,
            OrthoBottom,
            OrthoBack,
            OrthoLeftSide,
            Isometric,
            CrossSection,
            Detail,
            Other
        }

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_DrawingView()
        {
            MyType = DrawingElementType.DrawingView;
        }

        public CAD_DrawingView(
            string? id,
            string? title,
            ViewType viewType,
            Point? centerPoint = null,
            Quadrilateral? viewRectangle = null,
            string? description = null) : this()
        {
            ID = id;
            Title = title;
            Type = viewType;
            CenterPoint = centerPoint;
            ViewRectangle = viewRectangle;
            Description = description;
        }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? ID { get; set; }
        public string? Title { get; set; }
        public string? Description { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        /// <summary>The canonical type/kind of this view (orthographic, isometric, section, etc.).</summary>
        public ViewType Type { get; set; } = ViewType.Other;

        /// <summary>Optional center point of the view on the sheet (drawing coordinates).</summary>
        public Point? CenterPoint { get; set; }

        /// <summary>Optional view bounding rectangle on the sheet (drawing coordinates).</summary>
        public Quadrilateral? ViewRectangle { get; set; }

        // -----------------------------
        // Overrides
        // -----------------------------
        public override string ToString()
            => $"{Title ?? Type.ToString()} ({Type})#{ID}";

        // JSON Serialization
        public new string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static new CAD_DrawingView? FromJson(string json) => JsonConvert.DeserializeObject<CAD_DrawingView>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingView"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingView_Schema.sql</c>.
        /// </summary>
        public static new CAD_DrawingView? FromSql(SQLiteConnection connection, string drawingViewId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(drawingViewId)) throw new ArgumentException("Drawing view ID must not be empty.", nameof(drawingViewId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_DrawingView row
            // ----------------------------------------------------------
            const string query =
                "SELECT DrawingViewID, Name, MyType, MyDrawingID, CurrentConstructionGeometryID, " +
                "       Title, Description, ViewType, CenterPointID, ViewRectangleID " +
                "FROM CAD_DrawingView WHERE DrawingViewID = @id;";

            CAD_DrawingView? view = null;
            string? drawingId = null;
            string? curCgId = null;
            string? centerPtId = null;
            string? viewRectId = null;

            using (var cmd = new SQLiteCommand(query, connection))
            {
                cmd.Parameters.AddWithValue("@id", drawingViewId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                view = new CAD_DrawingView
                {
                    ID = reader["DrawingViewID"] as string,
                    Name = reader["Name"] as string,
                    MyType = (DrawingElementType)Convert.ToInt32(reader["MyType"]),
                    Title = reader["Title"] as string,
                    Description = reader["Description"] as string,
                    Type = (ViewType)Convert.ToInt32(reader["ViewType"])
                };

                drawingId = reader["MyDrawingID"] as string;
                curCgId = reader["CurrentConstructionGeometryID"] as string;
                centerPtId = reader["CenterPointID"] as string;
                viewRectId = reader["ViewRectangleID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyDrawing
            // ----------------------------------------------------------
            if (drawingId != null)
            {
                view.MyDrawing = LoadDrawing(connection, drawingId);
            }

            // ----------------------------------------------------------
            // 3. Load CenterPoint
            // ----------------------------------------------------------
            if (centerPtId != null)
            {
                view.CenterPoint = LoadPoint(connection, centerPtId);
            }

            // ----------------------------------------------------------
            // 4. Load ViewRectangle
            // ----------------------------------------------------------
            if (viewRectId != null)
            {
                view.ViewRectangle = LoadQuadrilateral(connection, viewRectId);
            }

            // ----------------------------------------------------------
            // 5. Load MyConstructionGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_DrawingView_ConstructionGeometry", "DrawingViewID", drawingViewId, "ConstructionGeometryID",
                id =>
                {
                    var cg = LoadConstructionGeometry(connection, id);
                    if (cg != null)
                    {
                        view.MyConstructionGeometry.Add(cg);
                        if (id == curCgId) view.CurrentConstructionGeometry = cg;
                    }
                });

            if (curCgId != null && view.CurrentConstructionGeometry == null)
            {
                view.CurrentConstructionGeometry = LoadConstructionGeometry(connection, curCgId);
            }

            return view;
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

        private static Quadrilateral? LoadQuadrilateral(SQLiteConnection connection, string quadId)
        {
            const string query =
                "SELECT QuadrilateralID, Vertex1ID, Vertex2ID, Vertex3ID, Vertex4ID " +
                "FROM Quadrilateral WHERE QuadrilateralID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", quadId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            var quad = new Quadrilateral();

            string? v1 = reader["Vertex1ID"] as string;
            string? v2 = reader["Vertex2ID"] as string;
            string? v3 = reader["Vertex3ID"] as string;
            string? v4 = reader["Vertex4ID"] as string;

            if (v1 != null) quad.Vertex1 = LoadPoint(connection, v1);
            if (v2 != null) quad.Vertex2 = LoadPoint(connection, v2);
            if (v3 != null) quad.Vertex3 = LoadPoint(connection, v3);
            if (v4 != null) quad.Vertex4 = LoadPoint(connection, v4);

            return quad;
        }

        private static CAD_ConstructionGeometery? LoadConstructionGeometry(SQLiteConnection connection, string cgId)
        {
            const string query =
                "SELECT ConstructionGeometryID, Name, Version, GeometryType " +
                "FROM CAD_ConstructionGeometry WHERE ConstructionGeometryID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", cgId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_ConstructionGeometery
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string ?? "1.0",
                GeometryType = (CAD_ConstructionGeometry.ConstructionGeometryTypeEnum)Convert.ToInt32(reader["GeometryType"])
            };
        }
    }
}
