
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using Mathematics;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Represents a kinematic joint between CAD components, with a locating coordinate system.
    /// </summary>
    public class CAD_Joint : CAD_Interface
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum JointTypeEnum
        {
            Rigid = 0,
            Revolute,
            Slider,
            Cylindrical,
            PinSlot,
            Planar,
            InPlane,
            Ball,
            LeadScrew,
            Other
        }

        public enum CAD_ModelTypeEnum
        {
            SolidWorks = 0,
            Fusion360,
            MechanicalDesktop,
            Simscape,
            STEP,
            STL,
            FBX
        }

        // -----------------------------
        // State
        // -----------------------------
        private readonly List<CAD_Component> _includedComponents = new();

        // -----------------------------
        // Construction
        // -----------------------------
        public CAD_Joint() { }

        public CAD_Joint(string name, JointTypeEnum jointType, CoordinateSystem? csys = null, 
            CAD_Component? baseComponent = null, CAD_Component? matingComponent = null)
        {
            Name = name;
            JointType = jointType;
            MyCoordinateSystem = csys;
            BaseComponent = baseComponent;
            MatingComponent = matingComponent;
            
            // Add components to the included components list
            if (baseComponent != null)
            {
                AddComponent(baseComponent);
            }
            if (matingComponent != null)
            {
                AddComponent(matingComponent);
            }
        }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? ID { get; set; }
        public string? Version { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        /// <summary>Type for this joint.</summary>
        public JointTypeEnum JointType { get; set; } = JointTypeEnum.Rigid;
        /// <summary>Model type for this joint.</summary>
        public CAD_ModelTypeEnum ModelType { get; set; } = CAD_ModelTypeEnum.Fusion360;

        /// <summary>
        /// Nominal degrees of freedom implied by <see cref="JointType"/>.
        /// For leadscrew and other coupled joints this returns the number of independent DOFs.
        /// </summary>
        public int DegreesOfFreedom => JointType switch
        {
            JointTypeEnum.Rigid => 0,
            JointTypeEnum.Revolute => 1, // 1 rotation
            JointTypeEnum.Slider => 1, // 1 translation
            JointTypeEnum.Cylindrical => 2, // 1 rotation + 1 translation
            JointTypeEnum.PinSlot => 2, // typical simplification
            JointTypeEnum.Planar => 3, // Tx, Ty, Rz
            JointTypeEnum.InPlane => 3, // alias of planar
            JointTypeEnum.Ball => 3, // Rx, Ry, Rz (no translations)
            JointTypeEnum.LeadScrew => 1, // 1 independent DOF (coupled)
            _ => 0
        };

        // -----------------------------
        // Ownership
        // -----------------------------
        /// <summary>Components constrained/connected by this joint.</summary>
        public IReadOnlyList<CAD_Component> IncludedComponents => _includedComponents;

        /// <summary>Locating coordinate system for the joint.</summary>
        public CoordinateSystem? MyCoordinateSystem { get; set; }

        // -----------------------------
        // Helpers
        // -----------------------------
        public void AddComponent(CAD_Component component)
        {
            if (component is null) throw new ArgumentNullException(nameof(component));
            if (!_includedComponents.Contains(component)) _includedComponents.Add(component);
        }

        public bool RemoveComponent(CAD_Component component)
        {
            if (component is null) return false;
            return _includedComponents.Remove(component);
        }

        /// <summary>
        /// Validates that the joint has a coordinate system and at least one component.
        /// </summary>
        public bool IsValid(out string? reason)
        {
            if (MyCoordinateSystem is null)
            {
                reason = "Missing locating coordinate system.";
                return false;
            }

            if (_includedComponents.Count == 0)
            {
                reason = "No included components.";
                return false;
            }

            reason = null;
            return true;
        }

        // JSON Serialization
        public new string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });
        public static new CAD_Joint? FromJson(string json) => JsonConvert.DeserializeObject<CAD_Joint>(json);

        // -----------------------------
        // SQL Deserialization
        // -----------------------------

        /// <summary>
        /// Creates a <see cref="CAD_Joint"/> from a SQLite database whose schema matches
        /// <c>CAD_Joint_Schema.sql</c>.
        /// </summary>
        /// <param name="connection">An open <see cref="SQLiteConnection"/>.</param>
        /// <param name="jointId">The <c>ID</c> value of the joint row to load.</param>
        /// <returns>A fully-hydrated <see cref="CAD_Joint"/>, or <c>null</c> if the ID was not found.</returns>
        public static CAD_Joint? FromSql(SQLiteConnection connection, string jointId)
        {
            if (connection is null) throw new ArgumentNullException(nameof(connection));
            if (string.IsNullOrWhiteSpace(jointId)) throw new ArgumentException("Joint ID must not be empty.", nameof(jointId));

            // ----------------------------------------------------------
            // 1. Load the main CAD_Joint row
            // ----------------------------------------------------------
            const string jointQuery =
                "SELECT ID, Name, Version, JointType, ModelType, DegreesOfFreedom, " +
                "       MyCoordinateSystemID, InterfaceKind, " +
                "       BaseComponentID, MatingComponentID " +
                "FROM CAD_Joint WHERE ID = @id;";

            CAD_Joint? joint = null;
            string? csysId = null;
            string? baseCompId = null;
            string? matingCompId = null;

            using (var cmd = new SQLiteCommand(jointQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", jointId);
                using var reader = cmd.ExecuteReader();
                if (!reader.Read()) return null;

                joint = new CAD_Joint
                {
                    ID = reader["ID"] as string,
                    Name = reader["Name"] as string,
                    Version = reader["Version"] as string,
                    JointType = (JointTypeEnum)Convert.ToInt32(reader["JointType"]),
                    ModelType = (CAD_ModelTypeEnum)Convert.ToInt32(reader["ModelType"]),
                    InterfaceKind = reader["InterfaceKind"] is DBNull
                        ? null
                        : (InterfaceType)Convert.ToInt32(reader["InterfaceKind"])
                };

                csysId = reader["MyCoordinateSystemID"] as string;
                baseCompId = reader["BaseComponentID"] as string;
                matingCompId = reader["MatingComponentID"] as string;
            }

            // ----------------------------------------------------------
            // 2. Load the locating CoordinateSystem (with origin Point)
            // ----------------------------------------------------------
            if (csysId != null)
            {
                joint.MyCoordinateSystem = LoadCoordinateSystem(connection, csysId);
            }

            // ----------------------------------------------------------
            // 3. Load Base and Mating components
            // ----------------------------------------------------------
            if (baseCompId != null)
            {
                joint.BaseComponent = LoadComponent(connection, baseCompId);
                if (joint.BaseComponent != null) joint.AddComponent(joint.BaseComponent);
            }

            if (matingCompId != null)
            {
                joint.MatingComponent = LoadComponent(connection, matingCompId);
                if (joint.MatingComponent != null) joint.AddComponent(joint.MatingComponent);
            }

            // ----------------------------------------------------------
            // 4. Load IncludedComponents from the junction table
            // ----------------------------------------------------------
            const string includedQuery =
                "SELECT ComponentID FROM CAD_Joint_IncludedComponent " +
                "WHERE JointID = @id ORDER BY SortOrder;";

            using (var cmd = new SQLiteCommand(includedQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", jointId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string compId = reader["ComponentID"] as string ?? "";
                    // Avoid duplicating base/mating components already added
                    if (compId == baseCompId || compId == matingCompId) continue;

                    var comp = LoadComponent(connection, compId);
                    if (comp != null) joint.AddComponent(comp);
                }
            }

            // ----------------------------------------------------------
            // 5. Load ContactPoints from the junction table
            // ----------------------------------------------------------
            const string contactPointsQuery =
                "SELECT PointID FROM CAD_Joint_ContactPoint " +
                "WHERE JointID = @id ORDER BY SortOrder;";

            using (var cmd = new SQLiteCommand(contactPointsQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", jointId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string ptId = reader["PointID"] as string ?? "";
                    var pt = LoadPoint(connection, ptId);
                    if (pt != null) joint.AddContactPoint(pt);
                }
            }

            // ----------------------------------------------------------
            // 6. Load ContactSurfaces from the junction table
            // ----------------------------------------------------------
            const string contactSurfacesQuery =
                "SELECT SurfaceID FROM CAD_Joint_ContactSurface " +
                "WHERE JointID = @id ORDER BY SortOrder;";

            using (var cmd = new SQLiteCommand(contactSurfacesQuery, connection))
            {
                cmd.Parameters.AddWithValue("@id", jointId);
                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string surfId = reader["SurfaceID"] as string ?? "";
                    var surf = LoadSurface(connection, surfId);
                    if (surf != null) joint.AddContactSurface(surf);
                }
            }

            return joint;
        }

        // -----------------------------
        // Private SQL helper methods
        // -----------------------------

        private static CAD_Component? LoadComponent(SQLiteConnection connection, string componentId)
        {
            const string query =
                "SELECT ComponentID, Name, Version, Path, IsAssembly, IsConfigurationItem, WBS_Level " +
                "FROM CAD_Component WHERE ComponentID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", componentId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Component
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string,
                Path = reader["Path"] as string,
                IsAssembly = Convert.ToInt32(reader["IsAssembly"]) != 0,
                IsConfigurationItem = Convert.ToInt32(reader["IsConfigurationItem"]) != 0,
                WBS_Level = Convert.ToInt32(reader["WBS_Level"])
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

            string? originId = reader["OriginLocationPointID"] as string;
            Mathematics.Point? origin = originId != null ? LoadPoint(connection, originId) : null;

            var csys = new CoordinateSystem();
            if (origin != null)
            {
                csys.OriginLocation = origin;
            }

            return csys;
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

        private static CAD_Surface? LoadSurface(SQLiteConnection connection, string surfaceId)
        {
            const string query =
                "SELECT ID, Name, Version " +
                "FROM CAD_Surface WHERE ID = @id;";

            using var cmd = new SQLiteCommand(query, connection);
            cmd.Parameters.AddWithValue("@id", surfaceId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read()) return null;

            return new CAD_Surface
            {
                Name = reader["Name"] as string,
                Version = reader["Version"] as string
            };
        }
    }
}
