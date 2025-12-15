#nullable enable
using System;
using System.Collections.Generic;
using System.Drawing;
using Mathematics;
using SE_Library;

namespace CAD
{
    /// <summary>
    /// Refactored version of CAD_Dimension (now named <see cref="Dimension"/>).
    /// Represents a drawing/model dimension with value, limits, type, unit, and locating geometry.
    /// </summary>
    public class Dimension : CAD_DrawingElement
    {
        // -----------------------------
        // Types
        // -----------------------------
        public enum DimensionType
        {
            Length = 0,
            Diameter,
            Radius,
            Angle,
            Distance,
            Ordinal,
            Other
        }

        // -----------------------------
        // Constructors
        // -----------------------------
        public Dimension()
        {
            // Preserve original behavior
            MyType = DrawingElementType.Dimension;

            // Initialize key references/collections as in original constructor
            CenterPoint = new Mathematics.Point();
            MyParameters = new List<Parameter>();
        }

        // -----------------------------
        // Identification
        // -----------------------------
        /// <summary>Unique id for the dimension.</summary>
        public string? DimensionID { get; set; }

        /// <summary>Human-readable description.</summary>
        public string? Description { get; set; }

        /// <summary>True if this is an ordinate dimension.</summary>
        public bool IsOrdinate { get; set; }

        // -----------------------------
        // Geometry / locating elements
        // -----------------------------
        /// <summary>Center point of the dimension annotation.</summary>
        public Mathematics.Point? CenterPoint { get; set; }

        /// <summary>Leader line end point.</summary>
        public Mathematics.Point? LeaderLineEndPoint { get; set; }

        /// <summary>Leader line bend point.</summary>
        public Mathematics.Point? LeaderLineBendPoint { get; set; }

        /// <summary>Primary point defining the dimension measurement.</summary>
        public Mathematics.Point? DimensionPoint { get; set; }

        /// <summary>Reference point used by the dimension.</summary>
        public Mathematics.Point? ReferencePoint { get; set; }

        /// <summary>Associated segment (if any).</summary>
        public Segment? MySegment { get; set; }

        // -----------------------------
        // Ownership / associations
        // -----------------------------
        /// <summary>Owning CAD model.</summary>
        public CAD_Model? MyModel { get; set; }

        // -----------------------------
        // Dimension data
        // -----------------------------
        /// <summary>Nominal dimension value.</summary>
        public double DimensionNominalValue { get; set; }

        /// <summary>Upper limit (positive tolerance endpoint).</summary>
        public double DimensionUpperLimitValue { get; set; }

        /// <summary>Lower limit (negative tolerance endpoint).</summary>
        public double DimensionLowerLimitValue { get; set; }

        /// <summary>Dimension classification (length, angle, etc.).</summary>
        public DimensionType MyDimensionType { get; set; }

        /// <summary>Engineering unit of measure.</summary>
        public UnitOfMeasure? EngineeringUnit { get; set; }

        // -----------------------------
        // Parameters
        // -----------------------------
        /// <summary>Current (active) parameter associated with this dimension.</summary>
        public Parameter? CurrentParameter { get; set; }

        /// <summary>All parameters associated with this dimension.</summary>
        public List<Parameter> MyParameters { get; set; }

        // -----------------------------
        // Helpers (optional)
        // -----------------------------

        /// <summary>
        /// Returns the bilateral tolerance as (upper - nominal, nominal - lower).
        /// Useful when interpreting limits as ± tolerances around the nominal.
        /// </summary>
        public (double Plus, double Minus) GetBilateralTolerance()
            => (DimensionUpperLimitValue - DimensionNominalValue,
                DimensionNominalValue - DimensionLowerLimitValue);

        /// <summary>
        /// Updates the upper/lower limits from a nominal and ± tolerances.
        /// </summary>
        public void SetFromNominalAndTolerance(double nominal, double plus, double minus)
        {
            DimensionNominalValue = nominal;
            DimensionUpperLimitValue = nominal + plus;
            DimensionLowerLimitValue = nominal - minus;
        }

        public override string ToString()
            => $"Dimension(ID={DimensionID ?? "<null>"}, Type={MyDimensionType}, Nom={DimensionNominalValue}, +Tol={DimensionUpperLimitValue - DimensionNominalValue}, -Tol={DimensionNominalValue - DimensionLowerLimitValue})";
    }
}
