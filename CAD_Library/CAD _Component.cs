
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using System.Numerics;
using Mathematics;
using SE_Library;
using Newtonsoft.Json;

namespace CAD
{
    public class CAD_Component : CAD_Part
    {
        // -----------------------------
        // Constructor
        // -----------------------------
        public CAD_Component()
        {
            MySketches = new List<CAD_Sketch>();
            MyJoints = new List<CAD_Joint>();
            MomentsOfInertia = new List<Parameter>();
            PrincipleDirections = new List<Mathematics.Vector>();
        }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? Version { get; set; }
        public string? Path { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        public Parameter? Weight { get; set; }
        public List<Parameter> MomentsOfInertia { get; set; }
        /// <remarks>
        /// Kept the original property name <c>PrincipleDirections</c> to preserve API compatibility.
        /// If this was a typo for “PrincipalDirections”, we can add a second read-only alias.
        /// </remarks>
        public List<Mathematics.Vector> PrincipleDirections { get; set; }

        // Optional alias (uncomment if you want a clearer name without breaking the original):
        // public List<Vector> PrincipalDirections => PrincipleDirections;

        // -----------------------------
        // Flags
        // -----------------------------
        public bool IsAssembly { get; set; }
        public bool IsConfigurationItem { get; set; }

        // -----------------------------
        // Ownership / Associations
        // -----------------------------
        public CAD_Part? MyPart { get; set; }
        public List<CAD_Sketch> MySketches { get; set; }
        public List<CAD_Joint> MyJoints { get; set; }

        // -----------------------------
        // Component data
        // -----------------------------
        public int WBS_Level { get; set; }

        // -----------------------------
        // Methods (placeholders retained)
        // -----------------------------
        /// <summary>Extrudes a CAD profile (implementation-specific; retained as placeholder).</summary>
        public void ExtrudeCAD_Profile()
        {
            // Implementation goes here
        }

        // -----------------------------
        // Helpers (optional)
        // -----------------------------
        public void AddSketch(CAD_Sketch sketch)
        {
            if (sketch is null) throw new ArgumentNullException(nameof(sketch));
            MySketches.Add(sketch);
        }

        public void AddJoint(CAD_Joint joint)
        {
            if (joint is null) throw new ArgumentNullException(nameof(joint));
            MyJoints.Add(joint);
        }

        public override string ToString()
            => $"CAD_Component(Name={Name ?? "<null>"}, Version={Version ?? "<null>"}, WBS={WBS_Level}, IsAsm={IsAssembly})";

        // JSON Serialization
        public new string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static new CAD_Component? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Component>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Component"/> from a SQLite database whose schema matches
        /// <c>CAD_Component_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="componentId">The <c>ComponentID</c> value of the component row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Component"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Component? FromSql(SQLiteConnection connection, string componentId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(componentId)) throw new ArgumentException("Component ID must not be empty.", nameof(componentId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Component row
            // ----------------------------------------------------------
            const string componentQuery =
                "SELECT ComponentID, Name, Version, Path, " +
                "       WeightParameterID, IsAssembly, IsConfigurationItem, " +
                "       WBS_Level, MyPartID " +
                "FROM CAD_Component WHERE ComponentID = @id;";

            CAD_Component? component = null;
            string? weightParamId = null;
            string? myPartId = null;

            using (var cmd = new SQLiteCommand(componentQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", componentId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                component = new CAD_Component
                {
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    Path = reader["Path"] as string,
                    IsAssembly = Convert.ToInt32(reader["IsAssembly"]) != 0,
                    IsConfigurationItem = Convert.ToInt32(reader["IsConfigurationItem"]) != 0,
                    WBS_Level = Convert.ToInt32(reader["WBS_Level"])
                };

                weightParamId = reader["WeightParameterID"] as string;
                myPartId = reader["MyPartID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load Weight parameter
            // ----------------------------------------------------------
            if (weightParamId != null)
            {
                component.Weight = LoadParameter(connection, weightParamId);
            }

            // ----------------------------------------------------------
            // 3. Load MyPart (underlying CAD_Part)
            // ----------------------------------------------------------
            if (myPartId != null)
            {
                component.MyPart = LoadPart(connection, myPartId);
            }

            // ----------------------------------------------------------
            // 4. Load MomentsOfInertia from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Component_MomentOfInertia", "ComponentID", componentId, "ParameterID",
                id => { var p = LoadParameter(connection, id); if (p != null) component.MomentsOfInertia.Add(p); });

            // ----------------------------------------------------------
            // 5. Load PrincipleDirections from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Component_PrincipleDirection", "ComponentID", componentId, "VectorID",
                id => { var v = LoadVector(connection, id); if (v != null) component.PrincipleDirections.Add(v); });

            // ----------------------------------------------------------
            // 6. Load MySketches from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Component_Sketch", "ComponentID", componentId, "SketchID",
                id => { var s = LoadSketch(connection, id); if (s != null) component.MySketches.Add(s); });

            // ----------------------------------------------------------
            // 7. Load MyJoints from junction table
            // ----------------------------------------------------------
            LoadJunction(connection, "CAD_Component_Joint", "ComponentID", componentId, "JointID",
                id => { var j = LoadJoint(connection, id); if (j != null) component.MyJoints.Add(j); });

            return component;
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

        private static Mathematics.Point? LoadPoint(SQLiteConnection connection, string pointId)
        {
            const string query =
                "SELECT PointID, X_Value, Y_Value, Z_Value_Cartesian " +
                "FROM Point WHERE PointID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", pointId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Mathematics.Point
            {
                X_Value = Convert.ToDouble(reader["X_Value"]),
                Y_Value = Convert.ToDouble(reader["Y_Value"]),
                Z_Value_Cartesian = Convert.ToDouble(reader["Z_Value_Cartesian"])
            };
        }

        private static Mathematics.Vector? LoadVector(SQLiteConnection connection, string vectorId)
        {
            const string query =
                "SELECT VectorID, Name, X_Value, Y_Value, Z_Value, StartPointID, EndPointID " +
                "FROM Vector WHERE VectorID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", vectorId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            string? startPtId = reader["StartPointID"] as string;
            string? endPtId = reader["EndPointID"] as string;

            var startPt = startPtId != null ? LoadPoint(connection, startPtId) : new Mathematics.Point();
            var endPt = endPtId != null ? LoadPoint(connection, endPtId) : new Mathematics.Point();

            var vec = new Mathematics.Vector(startPt!, endPt!)
            {
                X_Value = Convert.ToDouble(reader["X_Value"]),
                Y_Value = Convert.ToDouble(reader["Y_Value"]),
                Z_Value = Convert.ToDouble(reader["Z_Value"])
            };

            return vec;
        }

        private static Parameter? LoadParameter(SQLiteConnection connection, string parameterId)
        {
            const string query =
                "SELECT ParameterID, Name, Description, ParameterType " +
                "FROM MathParameter WHERE ParameterID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", parameterId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new Parameter
            {
                Name = reader["Name"] as string,
                Description = reader["Description"] as string,
                MyParameterType = (Parameter.ParameterType)Convert.ToInt32(reader["ParameterType"])
            };
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

        private static CAD_Joint? LoadJoint(SQLiteConnection connection, string jointId)
        {
            const string query =
                "SELECT JointID, Name, JointType, ModelType " +
                "FROM CAD_Joint WHERE JointID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", jointId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Joint
            {
                Name = reader["Name"] as string,
                JointType = (CAD_Joint.JointTypeEnum)Convert.ToInt32(reader["JointType"]),
                ModelType = (CAD_Joint.CAD_ModelTypeEnum)Convert.ToInt32(reader["ModelType"])
            };
        }
    }
}

