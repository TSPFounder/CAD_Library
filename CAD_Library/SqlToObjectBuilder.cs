#nullable enable
using System;
using System.Data.SQLite;

namespace CAD
{
    /// <summary>
    /// Central factory for building CAD domain objects from SQLite query results.
    /// Each method delegates to the corresponding class's own <c>FromSql</c> implementation.
    /// </summary>
    public static class SqlToObjectBuilder
    {
        // ----------------------------------------------------------------
        // Validation helper
        // ----------------------------------------------------------------

        private static void Validate(SQLiteConnection connection, string id, string paramName)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(id))
                throw new ArgumentException($"{paramName} must not be empty.", paramName);
        }

        // ----------------------------------------------------------------
        // CAD_Assembly
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Assembly"/> from a SQLite database whose schema matches
        /// <c>CAD_Assembly_Schema.sql</c>.
        /// </summary>
        public static CAD_Assembly? BuildAssembly(SQLiteConnection connection, string assemblyId)
        {
            Validate(connection, assemblyId, nameof(assemblyId));
            return CAD_Assembly.FromSql(connection, assemblyId);
        }

        // ----------------------------------------------------------------
        // CAD_Part
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Part"/> from a SQLite database whose schema matches
        /// <c>CAD_Part_Schema.sql</c>.
        /// </summary>
        public static CAD_Part? BuildPart(SQLiteConnection connection, string partId)
        {
            Validate(connection, partId, nameof(partId));
            return CAD_Part.FromSql(connection, partId);
        }

        // ----------------------------------------------------------------
        // CAD_Joint
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Joint"/> from a SQLite database whose schema matches
        /// <c>CAD_Joint_Schema.sql</c>.
        /// </summary>
        public static CAD_Joint? BuildJoint(SQLiteConnection connection, string jointId)
        {
            Validate(connection, jointId, nameof(jointId));
            return CAD_Joint.FromSql(connection, jointId);
        }

        // ----------------------------------------------------------------
        // CAD_Sketch
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Sketch"/> from a SQLite database whose schema matches
        /// <c>CAD_Sketch_Schema.sql</c>.
        /// </summary>
        public static CAD_Sketch? BuildSketch(SQLiteConnection connection, string sketchId)
        {
            Validate(connection, sketchId, nameof(sketchId));
            return CAD_Sketch.FromSql(connection, sketchId);
        }

        // ----------------------------------------------------------------
        // CAD_SketchPlane
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_SketchPlane"/> from a SQLite database whose schema matches
        /// <c>CAD_SketchPlane_Schema.sql</c>.
        /// </summary>
        public static CAD_SketchPlane? BuildSketchPlane(SQLiteConnection connection, string sketchPlaneId)
        {
            Validate(connection, sketchPlaneId, nameof(sketchPlaneId));
            return CAD_SketchPlane.FromSql(connection, sketchPlaneId);
        }

        // ----------------------------------------------------------------
        // CAD_SketchElement
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_SketchElement"/> from a SQLite database whose schema matches
        /// <c>CAD_SketchElement_Schema.sql</c>.
        /// </summary>
        public static CAD_SketchElement? BuildSketchElement(SQLiteConnection connection, string sketchElementId)
        {
            Validate(connection, sketchElementId, nameof(sketchElementId));
            return CAD_SketchElement.FromSql(connection, sketchElementId);
        }

        // ----------------------------------------------------------------
        // CAD_Station
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Station"/> from a SQLite database whose schema matches
        /// <c>CAD_Station_Schema.sql</c>.
        /// </summary>
        public static CAD_Station? BuildStation(SQLiteConnection connection, string stationId)
        {
            Validate(connection, stationId, nameof(stationId));
            return CAD_Station.FromSql(connection, stationId);
        }

        // ----------------------------------------------------------------
        // CAD_Model
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Model"/> from a SQLite database whose schema matches
        /// <c>CAD_Model_Schema.sql</c>.
        /// </summary>
        public static CAD_Model? BuildModel(SQLiteConnection connection, string modelId)
        {
            Validate(connection, modelId, nameof(modelId));
            return CAD_Model.FromSql(connection, modelId);
        }

        // ----------------------------------------------------------------
        // CAD_Body
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Body"/> from a SQLite database whose schema matches
        /// <c>CAD_Body_Schema.sql</c>.
        /// </summary>
        public static CAD_Body? BuildBody(SQLiteConnection connection, string bodyId)
        {
            Validate(connection, bodyId, nameof(bodyId));
            return CAD_Body.FromSql(connection, bodyId);
        }

        // ----------------------------------------------------------------
        // CAD_Surface
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Surface"/> from a SQLite database whose schema matches
        /// <c>CAD_Surface_Schema.sql</c>.
        /// </summary>
        public static CAD_Surface? BuildSurface(SQLiteConnection connection, string surfaceId)
        {
            Validate(connection, surfaceId, nameof(surfaceId));
            return CAD_Surface.FromSql(connection, surfaceId);
        }

        // ----------------------------------------------------------------
        // CAD_Hole
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Hole"/> from a SQLite database whose schema matches
        /// <c>CAD_Hole_Schema.sql</c>.
        /// </summary>
        public static CAD_Hole? BuildHole(SQLiteConnection connection, string holeId)
        {
            Validate(connection, holeId, nameof(holeId));
            return CAD_Hole.FromSql(connection, holeId);
        }

        // ----------------------------------------------------------------
        // CAD_Feature
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Feature"/> from a SQLite database whose schema matches
        /// <c>CAD_Feature_Schema.sql</c>.
        /// </summary>
        public static CAD_Feature? BuildFeature(SQLiteConnection connection, string featureId)
        {
            Validate(connection, featureId, nameof(featureId));
            return CAD_Feature.FromSql(connection, featureId);
        }

        // ----------------------------------------------------------------
        // CAD_Component
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Component"/> from a SQLite database whose schema matches
        /// <c>CAD_Component_Schema.sql</c>.
        /// </summary>
        public static CAD_Component? BuildComponent(SQLiteConnection connection, string componentId)
        {
            Validate(connection, componentId, nameof(componentId));
            return CAD_Component.FromSql(connection, componentId);
        }

        // ----------------------------------------------------------------
        // CAD_Configuration
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Configuration"/> from a SQLite database whose schema matches
        /// <c>CAD_Configuration_Schema.sql</c>.
        /// </summary>
        public static CAD_Configuration? BuildConfiguration(SQLiteConnection connection, string configurationId)
        {
            Validate(connection, configurationId, nameof(configurationId));
            return CAD_Configuration.FromSql(connection, configurationId);
        }

        // ----------------------------------------------------------------
        // CAD_Constraint
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Constraint"/> from a SQLite database whose schema matches
        /// <c>CAD_Constraint_Schema.sql</c>.
        /// </summary>
        public static CAD_Constraint? BuildConstraint(SQLiteConnection connection, string constraintId)
        {
            Validate(connection, constraintId, nameof(constraintId));
            return CAD_Constraint.FromSql(connection, constraintId);
        }

        // ----------------------------------------------------------------
        // CAD_Parameter
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Parameter"/> from a SQLite database whose schema matches
        /// <c>CAD_Parameter_Schema.sql</c>.
        /// </summary>
        public static CAD_Parameter? BuildParameter(SQLiteConnection connection, string parameterId)
        {
            Validate(connection, parameterId, nameof(parameterId));
            return CAD_Parameter.FromSql(connection, parameterId);
        }

        // ----------------------------------------------------------------
        // CAD_ParameterValue
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_ParameterValue"/> from a SQLite database whose schema matches
        /// the <c>CAD_ParameterValue</c> table in <c>CAD_Parameter_Schema.sql</c>.
        /// </summary>
        public static CAD_ParameterValue? BuildParameterValue(SQLiteConnection connection, string parameterValueId)
        {
            Validate(connection, parameterValueId, nameof(parameterValueId));
            return CAD_ParameterValue.FromSql(connection, parameterValueId);
        }

        // ----------------------------------------------------------------
        // CAD_Dimension
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Dimension"/> from a SQLite database whose schema matches
        /// <c>CAD_Dimension_Schema.sql</c>.
        /// </summary>
        public static CAD_Dimension? BuildDimension(SQLiteConnection connection, string dimensionId)
        {
            Validate(connection, dimensionId, nameof(dimensionId));
            return CAD_Dimension.FromSql(connection, dimensionId);
        }

        // ----------------------------------------------------------------
        // CAD_BoM
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_BoM"/> from a SQLite database whose schema matches
        /// <c>CAD_BoM_Schema.sql</c>.
        /// </summary>
        public static CAD_BoM? BuildBoM(SQLiteConnection connection, string bomId)
        {
            Validate(connection, bomId, nameof(bomId));
            return CAD_BoM.FromSql(connection, bomId);
        }

        // ----------------------------------------------------------------
        // CAD_Drawing
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Drawing"/> from a SQLite database whose schema matches
        /// <c>CAD_Drawing_Schema.sql</c>.
        /// </summary>
        public static CAD_Drawing? BuildDrawing(SQLiteConnection connection, string drawingId)
        {
            Validate(connection, drawingId, nameof(drawingId));
            return CAD_Drawing.FromSql(connection, drawingId);
        }

        // ----------------------------------------------------------------
        // CAD_DrawingSheet
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingSheet"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingSheet_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingSheet? BuildDrawingSheet(SQLiteConnection connection, string sheetId)
        {
            Validate(connection, sheetId, nameof(sheetId));
            return CAD_DrawingSheet.FromSql(connection, sheetId);
        }

        // ----------------------------------------------------------------
        // CAD_DrawingView
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingView"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingView_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingView? BuildDrawingView(SQLiteConnection connection, string drawingViewId)
        {
            Validate(connection, drawingViewId, nameof(drawingViewId));
            return CAD_DrawingView.FromSql(connection, drawingViewId);
        }

        // ----------------------------------------------------------------
        // CAD_DrawingElement
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingElement"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingElement_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingElement? BuildDrawingElement(SQLiteConnection connection, string drawingElementId)
        {
            Validate(connection, drawingElementId, nameof(drawingElementId));
            return CAD_DrawingElement.FromSql(connection, drawingElementId);
        }

        // ----------------------------------------------------------------
        // CAD_DrawingNote
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingNote"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingNote_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingNote? BuildDrawingNote(SQLiteConnection connection, string drawingNoteId)
        {
            Validate(connection, drawingNoteId, nameof(drawingNoteId));
            return CAD_DrawingNote.FromSql(connection, drawingNoteId);
        }

        // ----------------------------------------------------------------
        // CAD_DrawingPMI
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingPMI"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingPMI_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingPMI? BuildDrawingPMI(SQLiteConnection connection, string pmiId)
        {
            Validate(connection, pmiId, nameof(pmiId));
            return CAD_DrawingPMI.FromSql(connection, pmiId);
        }

        // ----------------------------------------------------------------
        // CAD_DrawingTable
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingTable"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingTable_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingTable? BuildDrawingTable(SQLiteConnection connection, string drawingTableId)
        {
            Validate(connection, drawingTableId, nameof(drawingTableId));
            return CAD_DrawingTable.FromSql(connection, drawingTableId);
        }

        // ----------------------------------------------------------------
        // CAD_DrawingBoM_Table
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_DrawingBoM_Table"/> from a SQLite database whose schema matches
        /// <c>CAD_DrawingBoM_Table_Schema.sql</c>.
        /// </summary>
        public static CAD_DrawingBoM_Table? BuildDrawingBoMTable(SQLiteConnection connection, string bomTableId)
        {
            Validate(connection, bomTableId, nameof(bomTableId));
            return CAD_DrawingBoM_Table.FromSql(connection, bomTableId);
        }

        // ----------------------------------------------------------------
        // CAD_Library
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Library"/> from a SQLite database whose schema matches
        /// <c>CAD_LibraryClass_Schema.sql</c>.
        /// </summary>
        public static CAD_Library? BuildLibrary(SQLiteConnection connection, string libraryId)
        {
            Validate(connection, libraryId, nameof(libraryId));
            return CAD_Library.FromSql(connection, libraryId);
        }

        // ----------------------------------------------------------------
        // CAD_File
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_File"/> from a SQLite database whose schema matches
        /// <c>CAD_File_Schema.sql</c>.
        /// </summary>
        public static CAD_File? BuildFile(SQLiteConnection connection, string fileId)
        {
            Validate(connection, fileId, nameof(fileId));
            return CAD_File.FromSql(connection, fileId);
        }

        // ----------------------------------------------------------------
        // CAD_ConstructionGeometry
        // (no FromSql on the class itself — logic lives here)
        // ----------------------------------------------------------------

        /// <summary>
        /// Creates a <see cref="CAD_ConstructionGeometry"/> from a SQLite database whose schema matches
        /// <c>CAD_ConstructionGeometry_Schema.sql</c>.
        /// </summary>
        public static CAD_ConstructionGeometry? BuildConstructionGeometry(
            SQLiteConnection connection,
            string constructionGeometryId)
        {
            Validate(connection, constructionGeometryId, nameof(constructionGeometryId));

            const string query = @"
                SELECT cg.ConstructionGeometryID,
                       cg.Name,
                       cg.Version,
                       cg.GeometryType,
                       cg.MyCAD_ModelID
                FROM   CAD_ConstructionGeometry cg
                WHERE  cg.ConstructionGeometryID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", constructionGeometryId);
            using var reader = cmd.ExecuteReader();

            if (!reader.Read()) return null;

            var geometry = new CAD_ConstructionGeometry
            {
                Name         = reader["Name"] as string,
                Version      = reader["Version"] as string ?? "1.0",
                GeometryType = (CAD_ConstructionGeometry.ConstructionGeometryTypeEnum)
                                   Convert.ToInt32(reader["GeometryType"])
            };

            var modelId = reader["MyCAD_ModelID"] as string;
            if (!string.IsNullOrWhiteSpace(modelId))
            {
                geometry.MyCAD_Model = CAD_Model.FromSql(connection, modelId);
            }

            return geometry;
        }
    }
}
