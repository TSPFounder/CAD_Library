
using System;
using System.Collections.Generic;
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

        public CAD_Joint(string name, JointTypeEnum jointType, CoordinateSystem? csys = null)
        {
            Name = name;
            JointType = jointType;
            MyCoordinateSystem = csys;
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
        public JointTypeEnum JointType { get; set; } = JointTypeEnum.Rigid;
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
    }
}
