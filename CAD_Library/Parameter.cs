#nullable enable
using System;
using System.Collections.Generic;
using SE_Library;
using MathematicsLibrary;
using Documents;
using System.Linq.Expressions;

namespace CAD
{
    /// <summary>
    /// Refactored version of CAD_Parameter (now named <see cref="Parameter"/>).
    /// Represents a parametric value, its CAD and mathematical associations, and metadata.
    /// </summary>
    public class Parameter
    {
        // -----------------------------
        // Enumerations
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
        // Constructors
        // -----------------------------
        public Parameter()
        {
            MyDimensions = new List<Dimension>();
            MyModels = new List<CAD_Model>();
            DependencyParameters = new List<Parameter>();
            DependentParameters = new List<Parameter>();
        }

        // -----------------------------
        // Identification
        // -----------------------------
        /// <summary>Parameter name (human-readable).</summary>
        public string? Name { get; set; }

        /// <summary>Unique identifier or part number.</summary>
        public string? PartNumber { get; set; }

        /// <summary>Optional description of the parameter.</summary>
        public string? Description { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        /// <summary>Parameter category/type (double, integer, etc.).</summary>
        public ParameterType MyParameterType { get; set; }

        /// <summary>Freeform comments or notes.</summary>
        public string? Comments { get; set; }

        /// <summary>Encapsulated parameter value definition.</summary>
        public ParameterValue? Value { get; set; }

        // -----------------------------
        // Owned & Owning Objects
        // -----------------------------
        /// <summary>Associated (current) dimension object.</summary>
        public Dimension? CurrentDimension { get; set; }

        /// <summary>All dimensions referencing this parameter.</summary>
        public List<Dimension> MyDimensions { get; set; }

        /// <summary>SolidWorks parameter mapping.</summary>
        public string? SolidWorksParameterName { get; set; }

        /// <summary>Fusion 360 parameter mapping.</summary>
        public string? Fusion360ParameterName { get; set; }

        // -----------------------------
        // Dependency relationships
        // -----------------------------
        /// <summary>Parameters this parameter depends on (inputs).</summary>
        public List<Parameter> DependencyParameters { get; set; }

        /// <summary>Parameters that depend on this parameter (outputs).</summary>
        public List<Parameter> DependentParameters { get; set; }

         // -----------------------------
        // Model relationships
        // -----------------------------
        /// <summary>The current CAD model context.</summary>
        public CAD_Model? CurrentModel { get; set; }

        /// <summary>All CAD models referencing this parameter.</summary>
        public List<CAD_Model> MyModels { get; set; }

        // -----------------------------
        // Expression and units
        // -----------------------------
        /// <summary>Linked mathematical expression, if parameter is formula-driven.</summary>
        public Expression? MyExpression { get; set; }

        /// <summary>Engineering unit of the parameter.</summary>
        public UnitOfMeasure? MyUnits { get; set; }

        // -----------------------------
        // Design table link
        // -----------------------------
        /// <summary>Reference to a design table entry associated with this parameter.</summary>
        public SE_Table? DesignTable { get; set; }

        // -----------------------------
        // Methods
        // -----------------------------
        public override string ToString()
        {
            return $"Parameter(Name={Name ?? "<null>"}, Type={MyParameterType}, Value={Value?.ToString() ?? "null"}, Units={MyUnits?.ToString() ?? "null"})";
        }
    }
}
