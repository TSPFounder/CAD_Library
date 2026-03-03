
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using Documents;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Represents a CAD drawing document (title block, sheets, views, dims, params, elements).
    /// </summary>
    public class CAD_Drawing //: DWM_Document
    {
        // -----------------------------
        // Enums
        // -----------------------------
        public enum DrawingStandardEnum { ANSI = 0 }
        public enum DocFormatEnum { CAD_File = 0, DWG, PDF, PNG, JPG, Other }
        public enum CAD_AppName { SolidWorks = 0, Fusion360, MechanicalDesktop, AutoCAD, Other }
        public enum DrawingSize { E = 0, D, C, B, A, A1, A2, A3 }

        // -----------------------------
        // Backing state
        // -----------------------------
        private readonly List<CAD_DrawingSheet> _sheets = new();
        private readonly List<CAD_DrawingElement> _elements = new();
        private readonly List<CAD_Sketch> _sketches = new();
        private readonly List<CAD_DrawingView> _views = new();
        private readonly List<CAD_Part> _parts = new();
        private readonly List<Parameter> _parameters = new();
        private readonly List<Dimension> _dimensions = new();
        private readonly List<CAD_ConstructionGeometery> _constructionGeometry = new();

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Title { get; set; }
        public string? DrawingNumber { get; set; }
        public string? Revision { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        public DrawingStandardEnum DrawingStandard { get; set; } = DrawingStandardEnum.ANSI;
        public DocFormatEnum MyFormat { get; set; } = DocFormatEnum.CAD_File;
        public DrawingSize MyDrawingSize { get; set; } = DrawingSize.A;

        // -----------------------------
        // Owned & Owning Objects
        // -----------------------------
        public CAD_DrawingSheet? CurrentCAD_DrawingSheet { get; private set; }
        public IReadOnlyList<CAD_DrawingSheet> MyDrawingSheets => _sheets;

        public CAD_DrawingElement? RevisionTable { get; private set; }
        public CAD_DrawingElement? CurrentElement { get; private set; }
        public IReadOnlyList<CAD_DrawingElement> DrawingElements => _elements;

        public CAD_Sketch? CurrentSketch { get; private set; }
        public IReadOnlyList<CAD_Sketch> MyCAD_Sketches => _sketches;

        public CAD_DrawingView? CurrentView { get; private set; }
        public IReadOnlyList<CAD_DrawingView> MyViews => _views;

        public CAD_Part? CurrentPart { get; private set; }
        public IReadOnlyList<CAD_Part> MyParts => _parts;

        public CAD_Assembly? MyAssembly { get; set; }
        public CAD_Model? MyModel { get; set; }
        //public CAD_Manager? TheCAD_Manager { get; set; }

        // Parameters
        public Parameter? CurrentParameter { get; private set; }
        public IReadOnlyList<Parameter> MyParameters => _parameters;

        // Dimensions
        public Dimension? CurrentDimension { get; private set; }
        public IReadOnlyList<Dimension> MyDimensions => _dimensions;

        // Construction geometry
        public CAD_ConstructionGeometery? CurrentConstructionGeometry { get; private set; }
        public IReadOnlyList<CAD_ConstructionGeometery> MyConstructionGeometry => _constructionGeometry;

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_Drawing() { }

        // -----------------------------
        // Mutators / helpers
        // -----------------------------
        public void AddSheet(CAD_DrawingSheet sheet, bool setCurrent = true)
        {
            if (sheet is null) throw new ArgumentNullException(nameof(sheet));
            _sheets.Add(sheet);
            if (setCurrent) CurrentCAD_DrawingSheet = sheet;
        }

        public void AddElement(CAD_DrawingElement element, bool setCurrent = true)
        {
            if (element is null) throw new ArgumentNullException(nameof(element));
            _elements.Add(element);
            if (setCurrent) CurrentElement = element;
        }

        public void AddSketch(CAD_Sketch sketch, bool setCurrent = true)
        {
            if (sketch is null) throw new ArgumentNullException(nameof(sketch));
            _sketches.Add(sketch);
            if (setCurrent) CurrentSketch = sketch;
        }

        public void AddView(CAD_DrawingView view, bool setCurrent = true)
        {
            if (view is null) throw new ArgumentNullException(nameof(view));
            _views.Add(view);
            if (setCurrent) CurrentView = view;
        }

        public void AddPart(CAD_Part part, bool setCurrent = true)
        {
            if (part is null) throw new ArgumentNullException(nameof(part));
            _parts.Add(part);
            if (setCurrent) CurrentPart = part;
        }

        public void AddParameter(Parameter parameter, bool setCurrent = true)
        {
            if (parameter is null) throw new ArgumentNullException(nameof(parameter));
            _parameters.Add(parameter);
            if (setCurrent) CurrentParameter = parameter;
        }

        public void AddDimension(Dimension dimension, bool setCurrent = true)
        {
            if (dimension is null) throw new ArgumentNullException(nameof(dimension));
            _dimensions.Add(dimension);
            if (setCurrent) CurrentDimension = dimension;
        }

        public void AddConstructionGeometry(CAD_ConstructionGeometery geom, bool setCurrent = true)
        {
            if (geom is null) throw new ArgumentNullException(nameof(geom));
            _constructionGeometry.Add(geom);
            if (setCurrent) CurrentConstructionGeometry = geom;
        }

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Drawing? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Drawing>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Drawing"/> from a SQLite database whose schema matches
        /// <c>CAD_Drawing_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="drawingId">The <c>DrawingID</c> value of the drawing row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Drawing"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Drawing? FromSql(SQLiteConnection connection, string drawingId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(drawingId)) throw new ArgumentException("Drawing ID must not be empty.", nameof(drawingId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Drawing row
            // ----------------------------------------------------------
            const string drawingQuery =
                "SELECT DrawingID, Title, DrawingNumber, Revision, " +
                "       DrawingStandard, MyFormat, MyDrawingSize, " +
                "       CurrentCAD_DrawingSheetID, CurrentElementID, RevisionTableID, " +
                "       CurrentSketchID, CurrentViewID, CurrentPartID, " +
                "       CurrentParameterID, CurrentDimensionID, CurrentConstructionGeometryID, " +
                "       MyAssemblyID, MyModelID " +
                "FROM CAD_Drawing WHERE DrawingID = @id;";

            CAD_Drawing? drawing = null;
            string? curSheetId = null;
            string? curElementId = null;
            string? revTableId = null;
            string? curSketchId = null;
            string? curViewId = null;
            string? curPartId = null;
            string? curParamId = null;
            string? curDimId = null;
            string? curCgId = null;
            string? assemblyId = null;
            string? modelId = null;

            using (var cmd = new SQLiteCommand(drawingQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", drawingId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                drawing = new CAD_Drawing
                {
                    Title = reader["Title"] as string,
                    DrawingNumber = reader["DrawingNumber"] as string,
                    Revision = reader["Revision"] as string,
                    DrawingStandard = (DrawingStandardEnum)Convert.ToInt32(reader["DrawingStandard"]),
                    MyFormat = (DocFormatEnum)Convert.ToInt32(reader["MyFormat"]),
                    MyDrawingSize = (DrawingSize)Convert.ToInt32(reader["MyDrawingSize"])
                };

                curSheetId = reader["CurrentCAD_DrawingSheetID"] as string;
                curElementId = reader["CurrentElementID"] as string;
                revTableId = reader["RevisionTableID"] as string;
                curSketchId = reader["CurrentSketchID"] as string;
                curViewId = reader["CurrentViewID"] as string;
                curPartId = reader["CurrentPartID"] as string;
                curParamId = reader["CurrentParameterID"] as string;
                curDimId = reader["CurrentDimensionID"] as string;
                curCgId = reader["CurrentConstructionGeometryID"] as string;
                assemblyId = reader["MyAssemblyID"] as string;
                modelId = reader["MyModelID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load MyAssembly
            // ----------------------------------------------------------
            if (assemblyId != null)
            {
                drawing.MyAssembly = LoadAssembly(connection, assemblyId);
            }

            // ----------------------------------------------------------
            // 3. Load MyModel
            // ----------------------------------------------------------
            if (modelId != null)
            {
                drawing.MyModel = LoadModel(connection, modelId);
            }

            // ----------------------------------------------------------
            // 4. Load RevisionTable (a CAD_DrawingElement)
            // ----------------------------------------------------------
            if (revTableId != null)
            {
                drawing.RevisionTable = LoadDrawingElement(connection, revTableId);
            }

            // ----------------------------------------------------------
            // 5. Load MyDrawingSheets from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Drawing_Sheet", "DrawingID", drawingId, "SheetID",
                id =>
                {
                    var sheet = LoadDrawingSheet(connection, id);
                    if (sheet != null)
                    {
                        drawing.AddSheet(sheet, setCurrent: id == curSheetId);
                    }
                });

            // ----------------------------------------------------------
            // 6. Load DrawingElements from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Drawing_Element", "DrawingID", drawingId, "DrawingElementID",
                id =>
                {
                    var elem = LoadDrawingElement(connection, id);
                    if (elem != null)
                    {
                        drawing.AddElement(elem, setCurrent: id == curElementId);
                    }
                });

            // ----------------------------------------------------------
            // 7. Load MyCAD_Sketches from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Drawing_Sketch", "DrawingID", drawingId, "SketchID",
                id =>
                {
                    var sketch = LoadSketch(connection, id);
                    if (sketch != null)
                    {
                        drawing.AddSketch(sketch, setCurrent: id == curSketchId);
                    }
                });

            // ----------------------------------------------------------
            // 8. Load MyViews from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Drawing_View", "DrawingID", drawingId, "DrawingViewID",
                id =>
                {
                    var view = LoadDrawingView(connection, id);
                    if (view != null)
                    {
                        drawing.AddView(view, setCurrent: id == curViewId);
                    }
                });

            // ----------------------------------------------------------
            // 9. Load MyParts from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Drawing_Part", "DrawingID", drawingId, "PartID",
                id =>
                {
                    var part = LoadPart(connection, id);
                    if (part != null)
                    {
                        drawing.AddPart(part, setCurrent: id == curPartId);
                    }
                });

            // ----------------------------------------------------------
            // 10. Load MyParameters from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Drawing_Parameter", "DrawingID", drawingId, "MathParameterID",
                id =>
                {
                    var param = LoadParameter(connection, id);
                    if (param != null)
                    {
                        drawing.AddParameter(param, setCurrent: id == curParamId);
                    }
                });

            // ----------------------------------------------------------
            // 11. Load MyDimensions from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Drawing_Dimension", "DrawingID", drawingId, "DimensionID",
                id =>
                {
                    var dim = LoadDimension(connection, id);
                    if (dim != null)
                    {
                        drawing.AddDimension(dim, setCurrent: id == curDimId);
                    }
                });

            // ----------------------------------------------------------
            // 12. Load MyConstructionGeometry from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Drawing_ConstructionGeometry", "DrawingID", drawingId, "ConstructionGeometryID",
                id =>
                {
                    var cg = LoadConstructionGeometry(connection, id);
                    if (cg != null)
                    {
                        drawing.AddConstructionGeometry(cg, setCurrent: id == curCgId);
                    }
                });

            return drawing;
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

        private static CAD_DrawingSheet? LoadDrawingSheet(SQLiteConnection connection, string sheetId)
        {
            const string query =
                "SELECT SheetID, SheetNumber, Size, SheetOrientation " +
                "FROM CAD_DrawingSheet WHERE SheetID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", sheetId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_DrawingSheet
            {
                SheetID = sheetId,
                SheetNumber = Convert.ToInt32(reader["SheetNumber"]),
                Size = (DrawingSize)Convert.ToInt32(reader["Size"]),
                SheetOrientation = (CAD_DrawingSheet.Orientation)Convert.ToInt32(reader["SheetOrientation"])
            };
        }

        private static CAD_DrawingElement? LoadDrawingElement(SQLiteConnection connection, string elementId)
        {
            const string query =
                "SELECT DrawingElementID, Name, MyType " +
                "FROM CAD_DrawingElement WHERE DrawingElementID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", elementId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_DrawingElement
            {
                Name = reader["Name"] as string,
                MyType = (CAD_DrawingElement.DrawingElementType)Convert.ToInt32(reader["MyType"])
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

        private static CAD_DrawingView? LoadDrawingView(SQLiteConnection connection, string viewId)
        {
            const string query =
                "SELECT DrawingViewID, Name, ID, Title, Description, ViewType, " +
                "       CenterPointID, ViewRectangleID " +
                "FROM CAD_DrawingView WHERE DrawingViewID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", viewId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            string? centerPtId = reader["CenterPointID"] as string;

            var view = new CAD_DrawingView
            {
                Name = reader["Name"] as string,
                ID = reader["ID"] as string,
                Title = reader["Title"] as string,
                Description = reader["Description"] as string,
                Type = (CAD_DrawingView.ViewType)Convert.ToInt32(reader["ViewType"])
            };

            if (centerPtId != null)
            {
                view.CenterPoint = LoadPoint(connection, centerPtId);
            }

            return view;
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

        private static Parameter? LoadParameter(SQLiteConnection connection, string parameterId)
        {
            const string query =
                "SELECT MathParameterID, Name, Description, MyParameterType " +
                "FROM MathParameter WHERE MathParameterID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", parameterId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Parameter
            {
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                MyParameterType = (Parameter.ParameterType)Convert.ToInt32(reader["MyParameterType"])
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

        private static CAD_ConstructionGeometery? LoadConstructionGeometry(SQLiteConnection connection, string cgId)
        {
            const string query =
                "SELECT ConstructionGeometryID, Name, Version, GeometryType, MyCAD_ModelID " +
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
    }
}
