
using System;
using System.Collections.Generic;

namespace CAD
{
    /// <summary>
    /// Registry + factory-method façade for resolving CAD command factories per application.
    /// </summary>
    public static class CAD_CommandFactoryProvider
    {
        private static readonly Dictionary<CAD_Model.CAD_AppEnum, ICADCommandFactory> _factories = new()
        {
            { CAD_Model.CAD_AppEnum.Fusion360, Fusion360CommandFactory.Instance },
            { CAD_Model.CAD_AppEnum.Solidworks, SolidWorksCommandFactory.Instance }
        };

        public static void RegisterFactory(CAD_Model.CAD_AppEnum application, ICADCommandFactory factory)
        {
            if (factory is null) throw new ArgumentNullException(nameof(factory));
            _factories[application] = factory;
        }

        public static bool HasFactory(CAD_Model.CAD_AppEnum application)
            => _factories.ContainsKey(application);

        public static ICADCommandFactory GetFactory(CAD_Model.CAD_AppEnum application)
            => _factories.TryGetValue(application, out var factory)
                ? factory
                : NullCadCommandFactory.Instance;
    }

    /// <summary>
    /// Null Object fallback that surfaces consistent exceptions when no factory is registered.
    /// </summary>
    internal sealed class NullCadCommandFactory : ICADCommandFactory
    {
        public static NullCadCommandFactory Instance { get; } = new();

        private NullCadCommandFactory() { }

        public ICreateSketchCommand CreateSketchCommand()
            => NullCreateSketchCommand.Instance;

        public IExtrudeCommand CreateExtrudeCommand()
            => NullExtrudeCommand.Instance;

        private sealed class NullCreateSketchCommand : ICreateSketchCommand
        {
            public static NullCreateSketchCommand Instance { get; } = new();
            public string OperationName => "Null.CreateSketch";

            public CAD_Sketch CreateSketch(string? sketchId, CAD_Model model, CAD_Part? owningPart = null)
                => throw new NotSupportedException(
                    $"No CAD command factory is registered for application {model?.CAD_AppName ?? CAD_Model.CAD_AppEnum.Other}.");
        }

        private sealed class NullExtrudeCommand : IExtrudeCommand
        {
            public static NullExtrudeCommand Instance { get; } = new();
            public string OperationName => "Null.Extrude";

            public CAD_Feature Extrude(CAD_Sketch sketch, double distance, CAD_Part owningPart)
                => throw new NotSupportedException("No CAD command factory is registered for extrusion commands.");
        }
    }
}