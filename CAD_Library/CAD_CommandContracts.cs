

namespace CAD
{
    /// <summary>
    /// Abstract factory for generating CAD application specific command objects.
    /// </summary>
    public interface ICADCommandFactory
    {
        ICreateSketchCommand CreateSketchCommand();

        IExtrudeCommand CreateExtrudeCommand();
    }

    /// <summary>
    /// Shared metadata for CAD operations (Command pattern).
    /// </summary>
    public interface ICADOperationCommand
    {
        string OperationName { get; }
    }

    /// <summary>
    /// Contract for commands that create sketches in a CAD model or part.
    /// </summary>
    public interface ICreateSketchCommand : ICADOperationCommand
    {
        CAD_Sketch CreateSketch(string? sketchId, CAD_Model model, CAD_Part? owningPart = null);
    }

    /// <summary>
    /// Contract for commands that perform extrude operations.
    /// </summary>
    public interface IExtrudeCommand : ICADOperationCommand
    {
        CAD_Feature Extrude(CAD_Sketch sketch, double distance, CAD_Part owningPart);
    }
}