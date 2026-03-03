#nullable enable
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using SE_Library;
using Documents;
using System.Linq.Expressions;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// A named CAD parameter with a value, units, optional expression, and links to
    /// dimensions, math parameters, and CAD models.
    /// </summary>
    public sealed class CAD_Parameter
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum ParameterType
        {
            Double = 0,
            Integer,
            String,
            Vector,
            Other
        }

        // -----------------------------
        // Identity / description
        // -----------------------------
        public string? Name { get; set; }
        public string? Id { get; set; }                    // was PartNumber
        public string? Description { get; set; }
        public string? Comments { get; set; }

        // -----------------------------
        // Core data
        // -----------------------------
        public ParameterType MyParameterType { get; set; }
        public CAD_ParameterValue? Value { get; set; }
        public UnitOfMeasure? MyUnits { get; set; }
        public Expression? MyExpression { get; set; }

        // -----------------------------
        // CAD app bindings
        // -----------------------------
        public string? SolidWorksParameterName { get; set; }
        public string? Fusion360ParameterName { get; set; }

        // -----------------------------
        // Associations
        // -----------------------------
        public CAD_Dimension? CurrentDimension { get; set; }
        public CAD_Model? CurrentModel { get; set; }
        public Parameter? CurrentMathParameter { get; set; }

        public SE_Table? DesignTable { get; set; }

        // Backing collections
        private readonly List<CAD_Dimension> _dimensions = new();
        private readonly List<Parameter> _mathParameters = new();
        private readonly List<CAD_Model> _models = new();
        private readonly List<CAD_Parameter> _dependencies = new();
        private readonly List<CAD_Parameter> _dependents = new();

        public IReadOnlyList<CAD_Dimension> MyDimensions => _dimensions;
        public IReadOnlyList<Parameter> MyMathParameters => _mathParameters;
        public IReadOnlyList<CAD_Model> MyModels => _models;
        public IReadOnlyList<CAD_Parameter> DependencyParameters => _dependencies;
        public IReadOnlyList<CAD_Parameter> DependentParameters => _dependents;

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_Parameter() { }

        public CAD_Parameter(string? name, ParameterType type, CAD_ParameterValue? value = null,UnitOfMeasure? units = null)
        {
            Name = name;
            MyParameterType = type;
            Value = value;
            MyUnits = units;
        }

        // -----------------------------
        // Mutators / helpers
        // -----------------------------
        public void LinkDimension(CAD_Dimension dimension, bool setAsCurrent = true)
        {
            if (dimension is null) throw new ArgumentNullException(nameof(dimension));
            if (!_dimensions.Contains(dimension)) _dimensions.Add(dimension);
            if (setAsCurrent) CurrentDimension = dimension;
        }

        public void AttachToModel(CAD_Model model, bool setAsCurrent = true)
        {
            if (model is null) throw new ArgumentNullException(nameof(model));
            if (!_models.Contains(model)) _models.Add(model);
            if (setAsCurrent) CurrentModel = model;
        }

        public void AddMathParameter(Parameter mathParameter, bool setAsCurrent = false)
        {
            if (mathParameter is null) throw new ArgumentNullException(nameof(mathParameter));
            if (!_mathParameters.Contains(mathParameter)) _mathParameters.Add(mathParameter);
            if (setAsCurrent) CurrentMathParameter = mathParameter;
        }

        public void AddDependency(CAD_Parameter prerequisite)
        {
            if (prerequisite is null) throw new ArgumentNullException(nameof(prerequisite));
            if (ReferenceEquals(prerequisite, this)) return;
            if (!_dependencies.Contains(prerequisite)) _dependencies.Add(prerequisite);
            if (!prerequisite._dependents.Contains(this)) prerequisite._dependents.Add(this);
        }

        public bool RemoveDependency(CAD_Parameter prerequisite)
        {
            if (prerequisite is null) return false;
            var removed = _dependencies.Remove(prerequisite);
            if (removed) prerequisite._dependents.Remove(this);
            return removed;
        }

        public void SetExpression(Expression expression) => MyExpression = expression;

        /// <summary>Try to extract a double value if this parameter represents a scalar.</summary>
        public bool TryGetDouble(out double value)
        {
            value = 0;
            if (Value is null) return false;

            // Extend this as your CAD_ParameterValue API requires.
            if (Value.TryGetDouble(out var v))
            {
                value = v;
                return true;
            }
            return false;
        }

        public override string ToString()
        {
            var idPart = string.IsNullOrWhiteSpace(Id) ? "" : $"[{Id}] ";
            var val = Value?.ToString() ?? "<null>";
            var unit = MyUnits?.ToString();
            return $"{idPart}{Name}: {val}{(unit is null ? "" : " " + unit)}";
        }

        public static CAD_Parameter CreateIntegerParameter(string name, int initialValue = 0)
        {
            var parameter = new CAD_Parameter(name, CAD_Parameter.ParameterType.Integer);
            parameter.Value = new CAD_ParameterValue(initialValue, parameter);
            return parameter;
        }

        public static CAD_Parameter CreateDoubleParameter(string name, double initialValue = 0d)
        {
            var parameter = new CAD_Parameter(name, CAD_Parameter.ParameterType.Double);
            parameter.Value = new CAD_ParameterValue(initialValue, parameter);
            return parameter;
        }

        public static CAD_Parameter CreateBooleanParameter(string name, bool initialValue)
        {
            var parameter = new CAD_Parameter(name, CAD_Parameter.ParameterType.Other);
            parameter.Value = new CAD_ParameterValue(initialValue, parameter);
            return parameter;
        }

        public static CAD_Parameter CreateEnumParameter(string name, int initialValue) => CAD_Parameter.CreateIntegerParameter(name, initialValue);

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Parameter? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Parameter>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Parameter"/> from a SQLite database whose schema matches
        /// <c>CAD_Parameter_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="parameterId">The <c>Id</c> value of the parameter row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Parameter"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Parameter? FromSql(SQLiteConnection connection, string parameterId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(parameterId)) throw new ArgumentException("Parameter ID must not be empty.", nameof(parameterId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Parameter row
            // ----------------------------------------------------------
            const string paramQuery =
                "SELECT Id, Name, Description, Comments, MyParameterType, " +
                "       ValueID, MyUnitsID, ExpressionText, " +
                "       SolidWorksParameterName, Fusion360ParameterName, " +
                "       CurrentDimensionID, CurrentModelID, CurrentMathParameterID, DesignTableID " +
                "FROM CAD_Parameter WHERE Id = @id;";

            CAD_Parameter? param = null;
            string? valueId = null;
            string? unitsId = null;
            string? curDimId = null;
            string? curModelId = null;
            string? curMathParamId = null;
            string? designTableId = null;

            using (var cmd = new SQLiteCommand(paramQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", parameterId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                param = new CAD_Parameter
                {
                    Id = reader["Id"] as string,
                    Name = reader["Name"] as string,
                    Description = reader["Description"] as string,
                    Comments = reader["Comments"] as string,
                    MyParameterType = (ParameterType)Convert.ToInt32(reader["MyParameterType"]),
                    SolidWorksParameterName = reader["SolidWorksParameterName"] as string,
                    Fusion360ParameterName = reader["Fusion360ParameterName"] as string
                };

                valueId = reader["ValueID"] as string;
                unitsId = reader["MyUnitsID"] as string;
                curDimId = reader["CurrentDimensionID"] as string;
                curModelId = reader["CurrentModelID"] as string;
                curMathParamId = reader["CurrentMathParameterID"] as string;
                designTableId = reader["DesignTableID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load Value (CAD_ParameterValue)
            // ----------------------------------------------------------
            if (valueId != null)
            {
                param.Value = LoadParameterValue(connection, valueId, param);
            }

            // ----------------------------------------------------------
            // 3. Load MyUnits (UnitOfMeasure)
            // ----------------------------------------------------------
            if (unitsId != null)
            {
                param.MyUnits = LoadUnitOfMeasure(connection, unitsId);
            }

            // ----------------------------------------------------------
            // 4. Load CurrentDimension
            // ----------------------------------------------------------
            if (curDimId != null)
            {
                param.CurrentDimension = LoadCAD_Dimension(connection, curDimId);
            }

            // ----------------------------------------------------------
            // 5. Load CurrentModel
            // ----------------------------------------------------------
            if (curModelId != null)
            {
                param.CurrentModel = LoadModel(connection, curModelId);
            }

            // ----------------------------------------------------------
            // 6. Load CurrentMathParameter
            // ----------------------------------------------------------
            if (curMathParamId != null)
            {
                param.CurrentMathParameter = LoadMathParameter(connection, curMathParamId);
            }

            // ----------------------------------------------------------
            // 7. Load DesignTable
            // ----------------------------------------------------------
            if (designTableId != null)
            {
                param.DesignTable = LoadTable(connection, designTableId);
            }

            // ----------------------------------------------------------
            // 8. Load MyDimensions from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Parameter_Dimension", "ParameterID", parameterId, "DimensionID",
                id =>
                {
                    var d = LoadCAD_Dimension(connection, id);
                    if (d != null) param.LinkDimension(d, setAsCurrent: false);
                });

            // ----------------------------------------------------------
            // 9. Load MyMathParameters from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Parameter_MathParameter", "ParameterID", parameterId, "MathParameterID",
                id =>
                {
                    var mp = LoadMathParameter(connection, id);
                    if (mp != null) param.AddMathParameter(mp, setAsCurrent: false);
                });

            // ----------------------------------------------------------
            // 10. Load MyModels from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Parameter_Model", "ParameterID", parameterId, "ModelID",
                id =>
                {
                    var m = LoadModel(connection, id);
                    if (m != null) param.AttachToModel(m, setAsCurrent: false);
                });

            // ----------------------------------------------------------
            // 11. Load DependencyParameters from junction table
            //     (self-referential — shallow load to avoid infinite recursion)
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Parameter_Dependency", "ParameterID", parameterId, "DependsOnParameterID",
                id =>
                {
                    var dep = LoadCAD_ParameterShallow(connection, id);
                    if (dep != null) param._dependencies.Add(dep);
                });

            // ----------------------------------------------------------
            // 12. Load DependentParameters from junction table
            //     (self-referential — shallow load to avoid infinite recursion)
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Parameter_Dependent", "ParameterID", parameterId, "DependentParameterID",
                id =>
                {
                    var dep = LoadCAD_ParameterShallow(connection, id);
                    if (dep != null) param._dependents.Add(dep);
                });

            return param;
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

        private static CAD_ParameterValue? LoadParameterValue(SQLiteConnection connection, string valueId, CAD_Parameter? owner)
        {
            const string query =
                "SELECT ParameterValueID, ValueType, " +
                "       DoubleValue, SingleValue, Int16Value, Int32Value, Int64Value, " +
                "       BooleanValue, StringValue, ObjectValue " +
                "FROM CAD_ParameterValue WHERE ParameterValueID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", valueId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            var valueType = (CAD_ParameterValue.ParameterValueTypeEnum)Convert.ToInt32(reader["ValueType"]);

            return valueType switch
            {
                CAD_ParameterValue.ParameterValueTypeEnum.Double =>
                    new CAD_ParameterValue(reader["DoubleValue"] is DBNull ? 0.0 : Convert.ToDouble(reader["DoubleValue"]), owner),
                CAD_ParameterValue.ParameterValueTypeEnum.Single =>
                    new CAD_ParameterValue((float)(reader["SingleValue"] is DBNull ? 0f : Convert.ToSingle(reader["SingleValue"])), owner),
                CAD_ParameterValue.ParameterValueTypeEnum.Int16 =>
                    new CAD_ParameterValue((short)(reader["Int16Value"] is DBNull ? (short)0 : Convert.ToInt16(reader["Int16Value"])), owner),
                CAD_ParameterValue.ParameterValueTypeEnum.Int32 =>
                    new CAD_ParameterValue(reader["Int32Value"] is DBNull ? 0 : Convert.ToInt32(reader["Int32Value"]), owner),
                CAD_ParameterValue.ParameterValueTypeEnum.Int64 =>
                    new CAD_ParameterValue(reader["Int64Value"] is DBNull ? 0L : Convert.ToInt64(reader["Int64Value"]), owner),
                CAD_ParameterValue.ParameterValueTypeEnum.Boolean =>
                    new CAD_ParameterValue(reader["BooleanValue"] is not DBNull && Convert.ToInt32(reader["BooleanValue"]) != 0, owner),
                CAD_ParameterValue.ParameterValueTypeEnum.String =>
                    new CAD_ParameterValue(reader["StringValue"] as string ?? "", owner),
                _ =>
                    new CAD_ParameterValue(valueType, owner)
            };
        }

        private static UnitOfMeasure? LoadUnitOfMeasure(SQLiteConnection connection, string unitId)
        {
            const string query =
                "SELECT UnitOfMeasureID, Name, Description, SymbolName, UnitValue, SystemOfUnits, IsBaseUnit " +
                "FROM UnitOfMeasure WHERE UnitOfMeasureID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", unitId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new UnitOfMeasure
            {
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                SymbolName = reader["SymbolName"] as string
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

        private static Parameter? LoadMathParameter(SQLiteConnection connection, string mathParamId)
        {
            const string query =
                "SELECT MathParameterID, Name, Description, MyParameterType " +
                "FROM MathParameter WHERE MathParameterID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", mathParamId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Parameter
            {
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                MyParameterType = (Parameter.ParameterType)Convert.ToInt32(reader["MyParameterType"])
            };
        }

        private static SE_Table? LoadTable(SQLiteConnection connection, string tableId)
        {
            const string query =
                "SELECT SE_TableID, Name " +
                "FROM SE_Table WHERE SE_TableID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", tableId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new SE_Table(reader["Name"] as string ?? "");
        }

        /// <summary>
        /// Shallow load of a CAD_Parameter (identity + type only, no collections)
        /// to avoid infinite recursion on self-referential dependency/dependent tables.
        /// </summary>
        private static CAD_Parameter? LoadCAD_ParameterShallow(SQLiteConnection connection, string paramId)
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
                MyParameterType = (ParameterType)Convert.ToInt32(reader["MyParameterType"]),
                SolidWorksParameterName = reader["SolidWorksParameterName"] as string,
                Fusion360ParameterName = reader["Fusion360ParameterName"] as string
            };
        }
    }
}

