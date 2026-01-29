
using System;

namespace CAD
{
    /// <summary>Concrete factory for Fusion 360 style commands.</summary>
    public sealed class Fusion360CommandFactory : ICADCommandFactory
    {
        public static Fusion360CommandFactory Instance { get; } = new();

        private Fusion360CommandFactory() { }

        public ICreateSketchCommand CreateSketchCommand()
            => new Fusion360CreateSketchCommand();

        public IExtrudeCommand CreateExtrudeCommand()
            => new Fusion360ExtrudeCommand();

        private sealed class Fusion360CreateSketchCommand : ICreateSketchCommand
        {
            public string OperationName => "Fusion360.CreateSketch";

            public CAD_Sketch CreateSketch(string? sketchId, CAD_Model model, CAD_Part? owningPart = null)
            {
                if (model is null) throw new ArgumentNullException(nameof(model));

                var sketch = new CAD_Sketch(sketchId ?? $"Sketch_{model.MySketches.Count + 1}")
                {
                    Version = "Fusion360"
                };

                model.AddSketch(sketch);
                sketch.MyModel = model;

                if (owningPart is not null)
                {
                    owningPart.AddSketch(sketch);
                    owningPart.CurrentSketch = sketch;
                }

                return sketch;
            }
        }

        private sealed class Fusion360ExtrudeCommand : BaseExtrudeCommand
        {
            public override string OperationName => "Fusion360.Extrude";

            protected override void ApplyVendorSpecificSettings(CAD_Feature feature)
            {
                feature.Version = "Fusion360";
            }
        }
    }

    /// <summary>Concrete factory for SolidWorks style commands.</summary>
    public sealed class SolidWorksCommandFactory : ICADCommandFactory
    {
        public static SolidWorksCommandFactory Instance { get; } = new();

        private SolidWorksCommandFactory() { }

        public ICreateSketchCommand CreateSketchCommand()
            => new SolidWorksCreateSketchCommand();

        public IExtrudeCommand CreateExtrudeCommand()
            => new SolidWorksExtrudeCommand();

        private sealed class SolidWorksCreateSketchCommand : ICreateSketchCommand
        {
            public string OperationName => "SolidWorks.CreateSketch";

            public CAD_Sketch CreateSketch(string? sketchId, CAD_Model model, CAD_Part? owningPart = null)
            {
                if (model is null) throw new ArgumentNullException(nameof(model));

                var sketch = new CAD_Sketch(sketchId ?? $"SW_Sketch_{model.MySketches.Count + 1}")
                {
                    Version = "SolidWorks"
                };

                model.AddSketch(sketch);
                sketch.MyModel = model;

                if (owningPart is not null)
                {
                    owningPart.AddSketch(sketch);
                    owningPart.CurrentSketch = sketch;
                }

                return sketch;
            }
        }

        private sealed class SolidWorksExtrudeCommand : BaseExtrudeCommand
        {
            public override string OperationName => "SolidWorks.Extrude";

            protected override void ApplyVendorSpecificSettings(CAD_Feature feature)
            {
                feature.Version = "SolidWorks";
            }
        }
    }

    /// <summary>
    /// Template Method base class that handles shared extrude orchestration.
    /// </summary>
    internal abstract class BaseExtrudeCommand : IExtrudeCommand
    {
        public abstract string OperationName { get; }

        public CAD_Feature Extrude(CAD_Sketch sketch, double distance, CAD_Part owningPart)
        {
            if (sketch is null) throw new ArgumentNullException(nameof(sketch));
            if (owningPart is null) throw new ArgumentNullException(nameof(owningPart));
            if (distance <= 0) throw new ArgumentOutOfRangeException(nameof(distance), "Extrude distance must be positive.");

            var feature = CreateFeatureSkeleton(sketch, owningPart);
            ApplyVendorSpecificSettings(feature);
            owningPart.CurrentFeature = feature;
            return feature;
        }

        protected virtual CAD_Feature CreateFeatureSkeleton(CAD_Sketch sketch, CAD_Part owningPart)
        {
            var feature = new CAD_Feature
            {
                Name = $"{owningPart.Name ?? "Part"}_Extrude",
                GeometricFeatureType = CAD_Feature.GeometricFeatureTypeEnum.Boss
            };

            feature.ThreeDimOperations.Add(CAD_Feature.Feature3DOperationEnum.Extrude);
            feature.AddSketch(sketch);

            if (!owningPart.MySketches.Contains(sketch))
            {
                owningPart.AddSketch(sketch);
            }

            owningPart.AddFeature(feature);
            owningPart.CurrentSketch = sketch;

            return feature;
        }

        protected abstract void ApplyVendorSpecificSettings(CAD_Feature feature);
    }
}