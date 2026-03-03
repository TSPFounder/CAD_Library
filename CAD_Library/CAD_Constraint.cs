
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using SE_Library;
using Documents;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Represents a sketch/feature constraint within a CAD model.
    /// </summary>
    public sealed class CAD_Constraint
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum ConstraintType
        {
            Horizontal = 0,
            Vertical,
            Distance,
            Coincident,
            Tangent,
            Angle,
            Equal,
            Parallel,
            Perpendicular,
            Fixed,
            Midpoint,
            Midplane,
            Concentric,
            Collinear,
            Symmetry,
            Curvature,
            Other
        }

        // -----------------------------
        // Backing fields (mutable privately; exposed read-only)
        // -----------------------------
        private readonly List<CAD_Feature> _features = new();
        private readonly List<CAD_Model> _models = new();

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_Constraint() { }

        public CAD_Constraint(string? id, string? name = null, ConstraintType type = ConstraintType.Other)
        {
            ID = id;
            Name = name;
            Type = type;
        }

        // -----------------------------
        // Identity / Meta
        // -----------------------------
        public string? Name { get; set; }
        public string? ID { get; set; }               // (Was "PartNumber" in original; clarified to ID)
        public string? Description { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        public ConstraintType Type { get; set; }      // (Was "MyConstraintType")

        // -----------------------------
        // Owned & Owning Objects
        // -----------------------------
        public CAD_Feature? CurrentFeature { get; set; }
        public CAD_Feature? PreviousFeature { get; set; }

        public CAD_Model? CurrentModel { get; set; }

        /// <summary>All features referenced by this constraint (read-only view).</summary>
        public IReadOnlyList<CAD_Feature> Features => _features;

        /// <summary>All models this constraint participates in (read-only view).</summary>
        public IReadOnlyList<CAD_Model> Models => _models;

        // -----------------------------
        // Helpers (idempotent adds/removes)
        // -----------------------------
        public void AddFeature(CAD_Feature feature)
        {
            if (feature is null) throw new ArgumentNullException(nameof(feature));
            if (!_features.Contains(feature)) _features.Add(feature);
        }

        public bool RemoveFeature(CAD_Feature feature) =>
            feature is not null && _features.Remove(feature);

        public void AddModel(CAD_Model model)
        {
            if (model is null) throw new ArgumentNullException(nameof(model));
            if (!_models.Contains(model)) _models.Add(model);
        }

        public bool RemoveModel(CAD_Model model) =>
            model is not null && _models.Remove(model);

        // -----------------------------
        // Validation
        // -----------------------------
        /// <summary>Basic sanity check (must have ID or Name).</summary>
        public bool IsValid(out string? reason)
        {
            if (string.IsNullOrWhiteSpace(ID) && string.IsNullOrWhiteSpace(Name))
            {
                reason = "Constraint must have an ID or Name.";
                return false;
            }

            reason = null;
            return true;
        }

        // JSON Serialization
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static CAD_Constraint? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Constraint>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Constraint"/> from a SQLite database whose schema matches
        /// <c>CAD_Constraint_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="constraintId">The <c>ConstraintID</c> value of the constraint row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Constraint"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Constraint? FromSql(SQLiteConnection connection, string constraintId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(constraintId)) throw new ArgumentException("Constraint ID must not be empty.", nameof(constraintId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Constraint row
            // ----------------------------------------------------------
            const string constraintQuery =
                "SELECT ConstraintID, Name, Description, Type, " +
                "       CurrentFeatureID, PreviousFeatureID, CurrentModelID " +
                "FROM CAD_Constraint WHERE ConstraintID = @id;";

            CAD_Constraint? constraint = null;
            string? curFeatureId = null;
            string? prevFeatureId = null;
            string? curModelId = null;

            using (var cmd = new SQLiteCommand(constraintQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", constraintId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                constraint = new CAD_Constraint
                {
                    ID = reader["ConstraintID"] as string,
                    Name = reader["Name"] as string,
                    Description = reader["Description"] as string,
                    Type = (ConstraintType)Convert.ToInt32(reader["Type"])
                };

                curFeatureId = reader["CurrentFeatureID"] as string;
                prevFeatureId = reader["PreviousFeatureID"] as string;
                curModelId = reader["CurrentModelID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load CurrentFeature
            // ----------------------------------------------------------
            if (curFeatureId != null)
            {
                constraint.CurrentFeature = LoadFeature(connection, curFeatureId);
            }

            // ----------------------------------------------------------
            // 3. Load PreviousFeature
            // ----------------------------------------------------------
            if (prevFeatureId != null)
            {
                constraint.PreviousFeature = LoadFeature(connection, prevFeatureId);
            }

            // ----------------------------------------------------------
            // 4. Load CurrentModel
            // ----------------------------------------------------------
            if (curModelId != null)
            {
                constraint.CurrentModel = LoadModel(connection, curModelId);
            }

            // ----------------------------------------------------------
            // 5. Load Features from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Constraint_Feature", "ConstraintID", constraintId, "FeatureID",
                id =>
                {
                    var f = LoadFeature(connection, id);
                    if (f != null) constraint.AddFeature(f);
                });

            // ----------------------------------------------------------
            // 6. Load Models from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Constraint_Model", "ConstraintID", constraintId, "ModelID",
                id =>
                {
                    var m = LoadModel(connection, id);
                    if (m != null) constraint.AddModel(m);
                });

            return constraint;
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

        private static CAD_Feature? LoadFeature(SQLiteConnection connection, string featureId)
        {
            const string query =
                "SELECT FeatureID, Name, Version, GeometricFeatureType " +
                "FROM CAD_Feature WHERE FeatureID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", featureId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Feature
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                GeometricFeatureType = (CAD_Feature.GeometricFeatureTypeEnum)Convert.ToInt32(reader["GeometricFeatureType"])
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
    }
}

