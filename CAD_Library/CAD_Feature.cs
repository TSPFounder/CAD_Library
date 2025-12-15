#nullable enable
using System;
using System.Collections.Generic;
using Mathematics;
using SE_Library;

namespace CAD
{
    public class CAD_Feature
    {
        // -----------------------------
        // Enums (unchanged)
        // -----------------------------
        public enum GeometricFeatureTypeEnum
        {
            Hole = 0,
            Joint,
            Thread,
            Chamfer,
            Fillet,
            CounterBore,
            CounterSink,
            Bead,
            Boss,
            Keyway,
            Leg,
            Arm,
            Mirror,
            Embossment,
            Rib,
            RoundedSlot,
            Gusset,
            Taper,
            SquareSlot,
            Shell,
            Web,
            Tab,
            Coil,
            Helicoil,
            RectangularPattern,
            CircularPattern,
            OtherPattern
        }

        public enum Feature3DOperationEnum
        {
            Extrude = 0,
            Revolve,
            Sweep,
            Loft
        }

        // -----------------------------
        // Constructor
        // -----------------------------
        public CAD_Feature()
        {
            ThreeDimOperations = new List<Feature3DOperationEnum>();
            MyDimensions = new List<Dimension>();
            Sketches = new List<CAD_Sketch>();
            Stations = new List<CAD_Station>();
            MyFeatures = new List<CAD_Feature>();
            MyLibraries = new List<CAD_Library>();
        }

        // -----------------------------
        // Identification
        // -----------------------------
        public string? Name { get; set; }
        public string? Version { get; set; }

        // -----------------------------
        // Data
        // -----------------------------
        public GeometricFeatureTypeEnum GeometricFeatureType { get; set; }

        // -----------------------------
        // Dimensions
        // -----------------------------
        public Dimension? CurrentDimension { get; set; }
        public List<Dimension> MyDimensions { get; set; }

        // -----------------------------
        // Owned & Owning Objects
        // -----------------------------
        public CAD_Feature? CurrentFeature { get; set; }
        public List<CAD_Feature> MyFeatures { get; set; }

        // -----------------------------
        // Sketches
        // -----------------------------
        public CAD_Sketch? CurrentCAD_Sketch { get; set; }
        public List<CAD_Sketch> Sketches { get; set; }

        // -----------------------------
        // Stations
        // -----------------------------
        public CAD_Station? CurrentCAD_Station { get; set; }
        public List<CAD_Station> Stations { get; set; }

        // -----------------------------
        // Model & CSYS
        // -----------------------------
        public CAD_Model? MyModel { get; set; }
        public CoordinateSystem? Origin { get; set; }

        // -----------------------------
        // 3-D Operations
        // -----------------------------
        public List<Feature3DOperationEnum> ThreeDimOperations { get; set; }

        // -----------------------------
        // Libraries
        // -----------------------------
        public CAD_Library? CurrentLibrary { get; set; }
        public List<CAD_Library> MyLibraries { get; set; }

        // -----------------------------
        // Methods (kept, with minor polish)
        // -----------------------------
        public bool CreateHole()
        {
            try
            {
                // placeholder for implementation
                return true;
            }
            catch
            {
                return false;
            }
        }

        // -----------------------------
        // Helpers (optional)
        // -----------------------------
        public void AddDimension(Dimension dim)
        {
            if (dim is null) throw new ArgumentNullException(nameof(dim));
            MyDimensions.Add(dim);
            CurrentDimension ??= dim;
        }

        public void AddSketch(CAD_Sketch sketch)
        {
            if (sketch is null) throw new ArgumentNullException(nameof(sketch));
            Sketches.Add(sketch);
            CurrentCAD_Sketch ??= sketch;
        }

        public void AddStation(CAD_Station station)
        {
            if (station is null) throw new ArgumentNullException(nameof(station));
            Stations.Add(station);
            CurrentCAD_Station ??= station;
        }

        public void AddFeature(CAD_Feature feature)
        {
            if (feature is null) throw new ArgumentNullException(nameof(feature));
            MyFeatures.Add(feature);
            CurrentFeature ??= feature;
        }

        public void AddLibrary(CAD_Library lib)
        {
            if (lib is null) throw new ArgumentNullException(nameof(lib));
            MyLibraries.Add(lib);
            CurrentLibrary ??= lib;
        }

        public override string ToString()
            => $"CAD_Feature(Name={Name ?? "<null>"}, Type={GeometricFeatureType}, Dims={MyDimensions.Count}, Sketches={Sketches.Count})";
    }
}
