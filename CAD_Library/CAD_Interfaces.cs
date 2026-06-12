// CAD_Interfaces.cs
// Tool-agnostic CAD abstraction interfaces for the DWM pipeline.
// Lives in CAD_Library. Implemented by FusionLibrary (FusionApplication,
// FusionDocument, etc.) — mirrors the IMatlabBackend / MatlabDesktopBackend
// pattern from MatlabLibrary.

using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using CAD.Scripting;

namespace CAD
{
    /// <summary>Entry point: represents a running CAD application instance.</summary>
        public interface ICADApplication
        {
            string Version { get; }
            string ActiveDocumentName { get; }
            Task<ICADDocument> CreateDocumentAsync(string name, CancellationToken ct = default);
            Task<ICADDocument> OpenDocumentAsync(string path, CancellationToken ct = default);
            Task<ICADDocument> GetActiveDocumentAsync(CancellationToken ct = default);
            Task<bool> PingAsync(CancellationToken ct = default);
        }

        /// <summary>Represents a single open CAD design document.</summary>
        public interface ICADDocument
        {
            string Name { get; }
            string Id { get; }
            ICADParameterCollection Parameters { get; }
            Task SaveAsync(string? description = null, CancellationToken ct = default);
            Task<string> ExportAsync(ExportFormat format, string outputPath, CancellationToken ct = default);
            Task ExecuteScriptAsync(GeneratedPackage script, CancellationToken ct = default);
        }

        /// <summary>The collection of user parameters on a document.</summary>
        public interface ICADParameterCollection : IEnumerable<ICADParameter>
        {
            ICADParameter? FindByName(string name);
            Task<ICADParameter> SetAsync(string name, string expression, CancellationToken ct = default);
            Task<ICADParameter> AddAsync(string name, string expression, string unit,
                string comment = "", CancellationToken ct = default);
        }

        /// <summary>A single user parameter.</summary>
        public interface ICADParameter
        {
            string Name { get; }
            /// <summary>Unit-carrying expression, e.g. "120 mm".</summary>
            string Expression { get; }
            /// <summary>Value in internal units (cm / radians for Fusion).</summary>
            double Value { get; }
            string Unit { get; }
            string Comment { get; }
        }

        /// <summary>Produces GeneratedPackages (script/add-in bundles) from
        /// a CadOperationSequence. Tool-specific factories live in FusionLibrary.</summary>
        public interface ICADScriptFactory
        {
            ScriptLanguage Language { get; }
            GeneratedPackage CreateScript(CadOperationSequence ops, ScriptMetadata meta);
            GeneratedPackage CreateAddIn(CadOperationSequence ops, ScriptMetadata meta);
        }
    }

