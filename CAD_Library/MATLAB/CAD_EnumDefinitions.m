%% CAD_EnumDefinitions.m
% Enum value definitions matching the C# CAD_Library enums
% Use these constants when creating CAD objects in MATLAB

classdef CAD_EnumDefinitions
    properties (Constant)
        %% CAD_Dimension.DimensionType
        DimensionType_Length = 0
        DimensionType_Diameter = 1
        DimensionType_Radius = 2
        DimensionType_Angle = 3
        DimensionType_Distance = 4
        DimensionType_Ordinal = 5
        DimensionType_Other = 6

        %% CAD_Parameter.ParameterType
        ParameterType_Double = 0
        ParameterType_Integer = 1
        ParameterType_String = 2
        ParameterType_Vector = 3
        ParameterType_Other = 4

        %% CAD_ParameterValue.ParameterValueTypeEnum
        ParameterValueType_Double = 0
        ParameterValueType_Single = 1
        ParameterValueType_Int16 = 2
        ParameterValueType_Int32 = 3
        ParameterValueType_Int64 = 4
        ParameterValueType_Boolean = 5
        ParameterValueType_String = 6
        ParameterValueType_Object = 7

        %% CAD_Model.CAD_ModelTypeEnum
        ModelType_Component = 0
        ModelType_Assembly = 1
        ModelType_Drawing = 2
        ModelType_Mesh = 3
        ModelType_Body = 4
        ModelType_Other = 5

        %% CAD_Model.CAD_AppEnum
        CAD_App_Fusion360 = 0
        CAD_App_Solidworks = 1
        CAD_App_Blender = 2
        CAD_App_UnReal4 = 3
        CAD_App_UnReal5 = 4
        CAD_App_Unity = 5
        CAD_App_Other = 6

        %% CAD_Model.CAD_FileTypeEnum
        FileType_f3d = 0
        FileType_f3z = 1
        FileType_sldprt = 2
        FileType_sldasm = 3
        FileType_slddrw = 4
        FileType_step = 5
        FileType_stl = 6
        FileType_sat = 7
        FileType_dxf = 8
        FileType_iges = 9
        FileType_fbx = 10
        FileType_obj = 11
        FileType_dae = 12
        FileType_x3d = 13
        FileType_wrl = 14
        FileType_other = 15

        %% CAD_Feature.GeometricFeatureTypeEnum
        FeatureType_Hole = 0
        FeatureType_Joint = 1
        FeatureType_Thread = 2
        FeatureType_Chamfer = 3
        FeatureType_Fillet = 4
        FeatureType_CounterBore = 5
        FeatureType_CounterSink = 6
        FeatureType_Bead = 7
        FeatureType_Boss = 8
        FeatureType_Keyway = 9
        FeatureType_Leg = 10
        FeatureType_Arm = 11
        FeatureType_Mirror = 12
        FeatureType_Embossment = 13
        FeatureType_Rib = 14
        FeatureType_RoundedSlot = 15
        FeatureType_Gusset = 16
        FeatureType_Taper = 17
        FeatureType_SquareSlot = 18
        FeatureType_Shell = 19
        FeatureType_Web = 20
        FeatureType_Tab = 21
        FeatureType_Coil = 22
        FeatureType_Helicoil = 23
        FeatureType_RectangularPattern = 24
        FeatureType_CircularPattern = 25
        FeatureType_OtherPattern = 26
        FeatureType_Other = 27

        %% CAD_Feature.Feature3DOperationEnum
        Operation_Extrude = 0
        Operation_Revolve = 1
        Operation_Sweep = 2
        Operation_Loft = 3

        %% CAD_Station.StationTypeEnum
        StationType_Axial = 0
        StationType_Radial = 1
        StationType_Angular = 2
        StationType_Wing = 3
        StationType_Other = 4

        %% CAD_Constraint.ConstraintType
        ConstraintType_Horizontal = 0
        ConstraintType_Vertical = 1
        ConstraintType_Distance = 2
        ConstraintType_Coincident = 3
        ConstraintType_Tangent = 4
        ConstraintType_Angle = 5
        ConstraintType_Equal = 6
        ConstraintType_Parallel = 7
        ConstraintType_Perpendicular = 8
        ConstraintType_Fixed = 9
        ConstraintType_Midpoint = 10
        ConstraintType_Midplane = 11
        ConstraintType_Concentric = 12
        ConstraintType_Collinear = 13
        ConstraintType_Symmetry = 14
        ConstraintType_Curvature = 15
        ConstraintType_Other = 16

        %% CAD_Joint.JointTypeEnum
        JointType_Rigid = 0
        JointType_Revolute = 1
        JointType_Slider = 2
        JointType_Cylindrical = 3
        JointType_PinSlot = 4
        JointType_Planar = 5
        JointType_InPlane = 6
        JointType_Ball = 7
        JointType_LeadScrew = 8
        JointType_Other = 9

        %% CAD_SketchPlane.GeometryTypeEnum
        PlaneGeometry_Cartesian = 0
        PlaneGeometry_Spherical = 1
        PlaneGeometry_Cylindrical = 2

        %% CAD_SketchPlane.FunctionalTypeEnum
        PlaneFunctional_Interface = 0
        PlaneFunctional_Section = 1
        PlaneFunctional_GeometricBoundary = 2
        PlaneFunctional_Feature = 3
        PlaneFunctional_CoordinateSystemOrigin = 4
        PlaneFunctional_Incremental = 5

        %% CAD_SketchElement.SketchElemTypeEnum
        SketchElem_StartPoint = 0
        SketchElem_EndPoint = 1
        SketchElem_MidPoint = 2
        SketchElem_ControlPoint = 3
        SketchElem_Line = 4
        SketchElem_Rectangle = 5
        SketchElem_Circle = 6
        SketchElem_Parabola = 7
        SketchElem_Ellipse = 8
        SketchElem_Contour = 9
        SketchElem_Arc = 10
        SketchElem_Spline = 11
        SketchElem_Slot = 12
        SketchElem_BreakLine = 13
        SketchElem_Centerline = 14
        SketchElem_Centerpoint = 15
        SketchElem_WorkPoint = 16
        SketchElem_WorkLine = 17

        %% CAD_Surface.SurfaceTypeEnum
        SurfaceType_Plane = 0
        SurfaceType_Circle = 1
        SurfaceType_Ellipse = 2
        SurfaceType_Triangle = 3
        SurfaceType_Square = 4
        SurfaceType_Rectangle = 5
        SurfaceType_Quadrilateral = 6
        SurfaceType_Polygon = 7
        SurfaceType_Cylinder = 8
        SurfaceType_Cone = 9
        SurfaceType_Sphere = 10
        SurfaceType_Torus = 11
        SurfaceType_NURBS = 12
        SurfaceType_TwoDMesh = 13
        SurfaceType_ThreeDMesh = 14
        SurfaceType_Other = 15

        %% CAD_Hole.HoleGeometryTypeEnum
        HoleType_Straight = 0
        HoleType_CounterSink = 1
        HoleType_CounterBore = 2
        HoleType_Other = 3

        %% CAD_DrawingElement.DrawingElementType
        DrawingElementType_DrawingView = 0
        DrawingElementType_Dimension = 1
        DrawingElementType_Table = 2
        DrawingElementType_BoM = 3
        DrawingElementType_PMI = 4
        DrawingElementType_ConstructionGeometry = 5
        DrawingElementType_Note = 6
        DrawingElementType_Other = 7

        %% CAD_DrawingView.ViewType
        ViewType_OrthoTop = 0
        ViewType_OrthoFront = 1
        ViewType_OrthoRightSide = 2
        ViewType_OrthoBottom = 3
        ViewType_OrthoBack = 4
        ViewType_OrthoLeftSide = 5
        ViewType_Isometric = 6
        ViewType_CrossSection = 7
        ViewType_Detail = 8
        ViewType_Other = 9

        %% CAD_DrawingSheet.Orientation
        SheetOrientation_Landscape = 0
        SheetOrientation_Portrait = 1

        %% CAD_Drawing.DrawingSize
        DrawingSize_E = 0
        DrawingSize_D = 1
        DrawingSize_C = 2
        DrawingSize_B = 3
        DrawingSize_A = 4
        DrawingSize_A1 = 5
        DrawingSize_A2 = 6
        DrawingSize_A3 = 7

        %% CAD_DrawingNote.NoteType
        NoteType_General = 0
        NoteType_Safety = 1
        NoteType_Process = 2
        NoteType_Material = 3
        NoteType_Finish = 4
        NoteType_Reference = 5
        NoteType_Tolerance = 6
        NoteType_Other = 7

        %% CAD_DrawingPMI.PmiType
        PmiType_Gdt = 0
        PmiType_Welding = 1
        PmiType_Hole = 2
        PmiType_SurfaceFinish = 3
        PmiType_Other = 4

        %% CAD_BoM.BoM_TypeEnum
        BoMType_Design = 0
        BoMType_Manufacturing = 1
        BoMType_Estimating = 2
        BoMType_Other = 3

        %% CAD_ConstructionGeometry.ConstructionGeometryTypeEnum
        ConstructionGeomType_Point = 0
        ConstructionGeomType_Line = 1
        ConstructionGeomType_Plane = 2
        ConstructionGeomType_Circle = 3

        %% CAD_File.FileLocationState
        FileLocation_Unknown = 0
        FileLocation_LocalOnly = 1
        FileLocation_RemoteOnly = 2
        FileLocation_Synchronized = 3

        %% CAD_Interface.InterfaceType
        InterfaceType_Joint = 0
        InterfaceType_ElectricalConnector = 1
        InterfaceType_Other = 2
    end
end
