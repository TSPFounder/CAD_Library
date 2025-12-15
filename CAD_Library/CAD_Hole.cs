using System;
using System.Collections.Generic;
using Mathematics;
using SE_Library;
using Documents;
//using MissionsNamespace;
using System.IO.Compression;

namespace CAD
{
    public class CAD_Hole : CAD_Feature
    {
        //  *****************************************************************************************
        //  DECLARATIONS
        //
        //  ************************************************************
        #region
        //
        //  Identification

        //
        //  Data
        //
        //  General
        //
        //  Nominal Diameter
        private CAD_Dimension _NominalDiameter;
        //
        //  Nominal Depth
        private CAD_Dimension _NominalDepth;
        //
        //  Nominal Taper Angle
        private CAD_Dimension _NominalTaperAngle;
        //
        //  Center Point
        private Point _CenterPoint;
        //
        //  CounterSink
        private CAD_Dimension _CounterSinkAngle;
        private CAD_Dimension _CounterSinkDepth;
        //
        //  CounterBore
        private CAD_Dimension _CounterBoreOuterDiameter;
        private CAD_Dimension _CounterBoreDepth;
        //
        //  Keyway
        private Boolean _HasKeyway;
        private CAD_Feature _MyKeyway;
        //
        //  Owned & Owning Objects
        //
        //  Features
        //
        //  Threads
        private Boolean _HasThreads;
        private Thread _CurrentThread;
        private List<Thread> _MyThreads;
        //
        //  My Feature
        private CAD_Feature _MyFeature;
        //
        //  Sketch
        private CAD_Sketch _MySketch;
#endregion
        //  *****************************************************************************************


        //  ****************************************************************************************
        //  INITIALIZATIONS
        //
        //  ************************************************************

        //  *****************************************************************************************


        //  *****************************************************************************************
        //  ENUMERATIONS
        //
        //  ************************************************************
        public enum HoleGeometryTypeEnum
        {
            Straight = 0,
            CounterSink,
            CounterBore,
            Other
        }
        //  *****************************************************************************************


        //  *****************************************************************************************
        //  CAD_HOLE CONSTRUCTOR
        //
        //  ************************************************************
        public CAD_Hole()
        #region
        {
            //  Dimensions
            //
            //  Nominal Diameter
            this.NominalDiameter = new CAD_Dimension();
            this.NominalDiameter.MyDimensionType = CAD_Dimension.DimensionType.Diameter;
            //
            //  Nominal Depth
            this.NominalDepth = new CAD_Dimension();
            this.NominalDepth.MyDimensionType = CAD_Dimension.DimensionType.Length;
            //
            //  Nominal Taper Angle
            this.NominalTaperAngle = new CAD_Dimension();
            this.NominalTaperAngle.MyDimensionType = CAD_Dimension.DimensionType.Angle;
            //
            //  Add Dimensions to the List
            /*
            this.MyDimensions.Add(this.NominalDiameter);
            this.MyDimensions.Add(this.NominalDepth);
            this.MyDimensions.Add(this.NominalTaperAngle);
            */

            //
            //  Lists
            //
            //  Threads
            this.MyThreads = new List<Thread>();
            //
            //  Locating Objects
            //
            //  Center Point
            this.CenterPoint = new Point();
        }
        #endregion
        //  *****************************************************************************************


        //  *****************************************************************************************
        //  PROPERTIES
        //
        //  ************************************************************
        //
        //  Data
        //
        //  General
        //
        //  Nominal Depth
        public CAD_Dimension NominalDepth
        {
            set => _NominalDepth = value;
            get { return _NominalDepth; }
        }
        //
        //  Nominal Diameter
        public CAD_Dimension NominalDiameter
        {
            set => _NominalDiameter = value;
            get { return _NominalDiameter; }
        }
        //
        //  NominalTaper Angle
        public CAD_Dimension NominalTaperAngle
        {
            set => _NominalTaperAngle = value;
            get { return _NominalTaperAngle; }
        }
        //
        //  Center Point
        public Point CenterPoint
        {
            set => _CenterPoint = value;
            get { return _CenterPoint; }
        }
        //
        //  CounterSink
        public CAD_Dimension CounterSinkAngle
        {
            set => _CounterSinkAngle = value;
            get { return _CounterSinkAngle; }
        }
        public CAD_Dimension CounterSinkDepth
        {
            set => _CounterSinkDepth = value;
            get { return _CounterSinkDepth; }
        }
        //
        //  CounterBore
        public CAD_Dimension CounterBoreOuterDiameter
        {
            set => _CounterBoreOuterDiameter = value;
            get { return _CounterBoreOuterDiameter; }
        }
        public CAD_Dimension CounterBoreDepth
        {
            set => _CounterBoreDepth = value;
            get { return _CounterBoreDepth; }
        }
        //
        //  Keyway
        public Boolean HasKeyway
        {
            set => _HasKeyway = value;
            get { return _HasKeyway; }
        }
        public CAD_Feature MyKeyway
        {
            set => _MyKeyway = value;
            get { return _MyKeyway; }
        }
        //
        //  Owned & Owning Objects
        //
        //  Features
        //
        //  Threads
        public Boolean HasThreads
        {
            set => _HasThreads = value;
            get { return _HasThreads; }
        }
        public Thread CurrentThread
        {
            set => _CurrentThread = value;
            get { return _CurrentThread; }
        }
        public List<Thread> MyThreads
        {
            set => _MyThreads = value;
            get { return _MyThreads; }
        }
        //
        //  Fastener Feature
        public CAD_Feature MyFeature
        {
            set => _MyFeature = value;
            get { return _MyFeature; }
        }
        //
        //  Sketch
        public CAD_Sketch MySketch
        {
            set => _MySketch = value;
            get { return _MySketch; }
        }
        //  *****************************************************************************************


        //  *****************************************************************************************
        //  METHODS
        //
        //  ************************************************************

        //  *****************************************************************************************


        //  *****************************************************************************************
        //  EVENTS
        //
        //  ************************************************************

        //  *****************************************************************************************
    }
}
