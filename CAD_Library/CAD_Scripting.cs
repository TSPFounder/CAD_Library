// CAD_Scripting.cs
// Script/add-in generation abstractions and the CAD operation IR.
// Lives in CAD_Library (the abstraction layer). Tool-specific emitters and
// runners (e.g. FusionPythonGenerator) live in the implementation libraries.
//
// Design rule: the IR stays at DWM-semantic level (set parameter, create part,
// export) — it is NOT a mirror of any CAD tool's full API surface. Emitters
// grow new operation types only when the pipeline demands them.

using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CAD.Scripting
{
    // ---------------------------------------------------------------------
    // Enums
    // ---------------------------------------------------------------------

    public enum ScriptLanguage
    {
        Python,      // Desktop, in-process, live execution via DWM add-in
        TypeScript,  // Cloud (Automation API for Fusion); desktop via helper add-in
        Cpp          // Desktop, compiled binary; export-only (no live execution)
    }

    public enum ScriptKind
    {
        Script,      // Run-once, disposed after execution
        AddIn        // Persistent, loads with the CAD application
    }

    public enum ExportFormat
    {
        Step,
        F3d,    // Fusion Archive — replaces Fbx
        Obj,
        Iges,
        Threemf,
        Stl
    }

    // ---------------------------------------------------------------------
    // Operation IR
    // ---------------------------------------------------------------------

    /// <summary>
    /// Base class for all operations in the IR. Each operation is a small,
    /// serializable, tool-agnostic description of one CAD action.
    /// </summary>
    [JsonConverter(typeof(CadOperationConverter))]
    public abstract class CadOperation
    {
        /// <summary>Discriminator used for JSON round-tripping and emitter dispatch.</summary>
        public abstract string Kind { get; }

        /// <summary>Optional human-readable note carried into generated code as a comment.</summary>
        public string? Comment { get; set; }
    }

    public sealed class CreateDocumentOp : CadOperation
    {
        public override string Kind => "createDocument";
        public string? Name { get; set; }
    }

    public sealed class OpenDocumentOp : CadOperation
    {
        public override string Kind => "openDocument";
        public string Path { get; set; } = string.Empty;
    }

    public sealed class SaveDocumentOp : CadOperation
    {
        public override string Kind => "saveDocument";
        public string? Description { get; set; }
    }

    public sealed class SetParameterOp : CadOperation
    {
        public override string Kind => "setParameter";
        public string ParameterName { get; set; } = string.Empty;

        /// <summary>
        /// Expression string, e.g. "120 mm" or "width * 2". Expressions, not raw
        /// doubles, so units survive the trip (see roadmap watch item on units).
        /// </summary>
        public string Expression { get; set; } = string.Empty;

        /// <summary>Create the user parameter if it does not already exist.</summary>
        public bool CreateIfMissing { get; set; } = false;

        /// <summary>Unit string used only when creating, e.g. "mm", "kg".</summary>
        public string? Unit { get; set; }
    }

    public sealed class CreateSketchOp : CadOperation
    {
        public override string Kind => "createSketch";
        public string SketchId { get; set; } = string.Empty;

        /// <summary>"XY" | "XZ" | "YZ" — base construction plane.</summary>
        public string Plane { get; set; } = "XY";
    }

    /// <summary>Adds a centered rectangle to a sketch. Deliberately minimal —
    /// the tracer bullet needs a box, not a sketch language.</summary>
    public sealed class SketchRectangleOp : CadOperation
    {
        public override string Kind => "sketchRectangle";
        public string SketchId { get; set; } = string.Empty;
        public double WidthCm { get; set; }
        public double HeightCm { get; set; }
    }

    public sealed class ExtrudeOp : CadOperation
    {
        public override string Kind => "extrude";
        public string SketchId { get; set; } = string.Empty;
        public double DistanceCm { get; set; }
        public bool Symmetric { get; set; } = false;
    }

    public sealed class ExportOp : CadOperation
    {
        public override string Kind => "export";
        public ExportFormat Format { get; set; } = ExportFormat.Step;

        /// <summary>Output path on the machine running the CAD tool. For the
        /// cloud track this is a working-directory-relative name.</summary>
        public string OutputPath { get; set; } = string.Empty;
    }

    /// <summary>
    /// Escape hatch: verbatim source in the TARGET language, spliced into the
    /// generated program. Use sparingly; anything used twice should become a
    /// real operation type.
    /// </summary>
    public sealed class RawCodeOp : CadOperation
    {
        public override string Kind => "rawCode";
        public ScriptLanguage Language { get; set; }
        public string Source { get; set; } = string.Empty;
    }

    /// <summary>
    /// An ordered, serializable sequence of operations. This is the single IR
    /// that all language emitters consume.
    /// </summary>
    public sealed class CadOperationSequence
    {
        public string SchemaVersion { get; set; } = "1.0";
        public List<CadOperation> Operations { get; } = new();

        public CadOperationSequence Add(CadOperation op)
        {
            Operations.Add(op);
            return this; // fluent
        }

        public string ToJson() =>
            JsonConvert.SerializeObject(this, Formatting.Indented);

        public static CadOperationSequence FromJson(string json) =>
            JsonConvert.DeserializeObject<CadOperationSequence>(json)
            ?? throw new JsonException("Failed to deserialize CadOperationSequence.");
    }

    // ---------------------------------------------------------------------
    // Generation output
    // ---------------------------------------------------------------------

    public sealed class ScriptMetadata
    {
        public string Name { get; set; } = "DWM_Generated";
        public string Description { get; set; } = "Generated by Dream World Maker";
        public string Author { get; set; } = "DWM";
        public string Version { get; set; } = "1.0.0";
    }

    /// <summary>
    /// The rendered result: one or more files (relative path → content) plus
    /// the entry-point file name. WriteTo() materializes it on disk.
    /// </summary>
    public sealed class GeneratedPackage
    {
        public ScriptLanguage Language { get; init; }
        public ScriptKind Kind { get; init; }
        public ScriptMetadata Metadata { get; init; } = new();
        public string EntryFile { get; init; } = string.Empty;
        public IReadOnlyDictionary<string, string> Files { get; init; }
            = new Dictionary<string, string>();

        public string EntrySource => Files[EntryFile];

        public void WriteTo(string rootDirectory)
        {
            foreach (var (relPath, content) in Files)
            {
                var full = System.IO.Path.Combine(rootDirectory, relPath);
                var dir = System.IO.Path.GetDirectoryName(full);
                if (!string.IsNullOrEmpty(dir))
                    System.IO.Directory.CreateDirectory(dir);
                System.IO.File.WriteAllText(full, content);
            }
        }
    }

    public sealed class ScriptResult
    {
        public bool Success { get; init; }
        public string? Output { get; init; }
        public string? Error { get; init; }
        public TimeSpan Elapsed { get; init; }
    }

    // ---------------------------------------------------------------------
    // Abstractions implemented per CAD tool / per language track
    // ---------------------------------------------------------------------

    /// <summary>Renders an operation sequence into source files for one language.</summary>
    public interface ICADScriptGenerator
    {
        ScriptLanguage Language { get; }
        GeneratedPackage Generate(CadOperationSequence ops, ScriptKind kind, ScriptMetadata meta);
    }

    /// <summary>Executes a generated package on its execution surface
    /// (local HTTP add-in, cloud automation, or build+deploy).</summary>
    public interface ICADScriptRunner
    {
        ScriptLanguage Language { get; }
        Task<ScriptResult> ExecuteAsync(GeneratedPackage package, CancellationToken ct = default);
    }

    // ---------------------------------------------------------------------
    // JSON polymorphism (no TypeNameHandling — explicit kind map only)
    // ---------------------------------------------------------------------

    public sealed class CadOperationConverter : JsonConverter
    {
        private static readonly Dictionary<string, Type> KindMap = new()
        {
            ["createDocument"]  = typeof(CreateDocumentOp),
            ["openDocument"]    = typeof(OpenDocumentOp),
            ["saveDocument"]    = typeof(SaveDocumentOp),
            ["setParameter"]    = typeof(SetParameterOp),
            ["createSketch"]    = typeof(CreateSketchOp),
            ["sketchRectangle"] = typeof(SketchRectangleOp),
            ["extrude"]         = typeof(ExtrudeOp),
            ["export"]          = typeof(ExportOp),
            ["rawCode"]         = typeof(RawCodeOp),
        };

        public override bool CanConvert(Type objectType) =>
            typeof(CadOperation).IsAssignableFrom(objectType);

        public override bool CanWrite => false; // default serialization writes Kind

        public override object? ReadJson(JsonReader reader, Type objectType,
            object? existingValue, JsonSerializer serializer)
        {
            var jo = JObject.Load(reader);
            var kind = jo["kind"]?.Value<string>() ?? jo["Kind"]?.Value<string>()
                ?? throw new JsonException("CadOperation is missing 'kind' discriminator.");

            if (!KindMap.TryGetValue(kind, out var type))
                throw new JsonException($"Unknown CadOperation kind '{kind}'.");

            var op = (CadOperation)Activator.CreateInstance(type)!;
            serializer.Populate(jo.CreateReader(), op);
            return op;
        }

        public override void WriteJson(JsonWriter writer, object? value, JsonSerializer serializer)
            => throw new NotSupportedException();
    }
}
