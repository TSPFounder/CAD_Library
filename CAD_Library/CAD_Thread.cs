#nullable enable
using System;
using Newtonsoft.Json;

namespace CAD
{
    /// <summary>
    /// Represents a screw thread definition (formerly named <c>Thread</c>, renamed to avoid
    /// conflict with <see cref="System.Threading.Thread"/>).
    /// Extends <see cref="CAD_Feature"/> — schema: <c>CAD_Hole_Schema.sql</c> table <c>CAD_Thread</c>.
    /// </summary>
    public class CAD_Thread
    {
        // -----------------------------
        // Enums
        // -----------------------------
        public enum ThreadStandardEnum
        {
            UN  = 0,   // Unified National
            UNR = 1,   // UN Rounded
            M   = 2,   // Metric
            MR  = 3,   // Metric Rounded
            Other = 4
        }

        // -----------------------------
        // Identification / metadata
        // -----------------------------
        public string? Name    { get; set; }
        public string? Version { get; set; } = "1.0";

        // -----------------------------
        // Thread descriptors
        // -----------------------------
        public string? Designation           { get; set; }
        public string? ThreadClass           { get; set; }
        public string? MaterialSpecification { get; set; }
        public string? SurfaceFinish         { get; set; }

        // -----------------------------
        // Flags
        // -----------------------------
        public bool IsInternal        { get; set; }
        public bool IsFine            { get; set; }
        public bool IsMultithreaded   { get; set; }
        public bool IsReverseThreaded { get; set; }
        public bool IsMetric          { get; set; }
        public bool IsSquare          { get; set; }

        // -----------------------------
        // Numeric properties
        // -----------------------------
        public int             Starts          { get; set; } = 1;
        public ThreadStandardEnum ThreadStandard { get; set; }
        public double?         CoatingThickness { get; set; }

        // -----------------------------
        // Overrides
        // -----------------------------
        public override string ToString() =>
            $"{Designation ?? Name ?? "(unnamed)"} [{ThreadStandard}]{(IsInternal ? " Internal" : " External")}";

        // -----------------------------
        // JSON serialization
        // -----------------------------
        public string ToJson() => JsonConvert.SerializeObject(this, Formatting.Indented,
            new JsonSerializerSettings { ReferenceLoopHandling = ReferenceLoopHandling.Ignore });

        public static CAD_Thread? FromJson(string json) =>
            JsonConvert.DeserializeObject<CAD_Thread>(json);
    }
}
