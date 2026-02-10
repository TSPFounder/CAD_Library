%% CAD_FeatureGUI.m
% MATLAB GUI for creating and editing CAD_Feature objects
%
% Usage:
%   CAD_FeatureGUI()              - Opens the GUI
%   feature = CAD_FeatureGUI()    - Opens GUI and returns created feature
%
% The GUI allows you to:
%   - Enter all CAD_Feature properties
%   - Create the feature object
%   - Export to JSON
%   - Save JSON to file

function varargout = CAD_FeatureGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Feature Creator', ...
                   'Position', [100 100 550 700], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.feature = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [18, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 14), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Feature Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Name
    uilabel(gl, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Feature name');

    % Row 3: Version
    uilabel(gl, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(gl, 'text', 'Value', '', ...
                              'Placeholder', 'e.g., 1.0');

    % Row 4: Feature Type
    uilabel(gl, 'Text', 'Feature Type:', 'HorizontalAlignment', 'right');
    featureTypes = {'Hole', 'Joint', 'Thread', 'Chamfer', 'Fillet', ...
                    'CounterBore', 'CounterSink', 'Bead', 'Boss', 'Keyway', ...
                    'Leg', 'Arm', 'Mirror', 'Embossment', 'Rib', ...
                    'RoundedSlot', 'Gusset', 'Taper', 'SquareSlot', 'Shell', ...
                    'Web', 'Tab', 'Coil', 'Helicoil', 'RectangularPattern', ...
                    'CircularPattern', 'OtherPattern', 'Other'};
    typeDropdown = uidropdown(gl, 'Items', featureTypes, 'Value', 'Hole');

    % Row 5: Section header - 3D Operations
    opsHeader = uilabel(gl, 'Text', '── 3D Operations ──', ...
                        'HorizontalAlignment', 'center', ...
                        'FontWeight', 'bold', ...
                        'FontColor', [0.3 0.3 0.6]);
    opsHeader.Layout.Column = [1 2];

    % Row 6: 3D Operation checkboxes
    uilabel(gl, 'Text', 'Operations:', 'HorizontalAlignment', 'right');
    opsPanel = uigridlayout(gl, [1, 4]);
    opsPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    opsPanel.Padding = [0 0 0 0];
    extrudeCheck = uicheckbox(opsPanel, 'Text', 'Extrude', 'Value', false);
    revolveCheck = uicheckbox(opsPanel, 'Text', 'Revolve', 'Value', false);
    sweepCheck = uicheckbox(opsPanel, 'Text', 'Sweep', 'Value', false);
    loftCheck = uicheckbox(opsPanel, 'Text', 'Loft', 'Value', false);

    % Row 7: Section header - Dimensions
    dimHeader = uilabel(gl, 'Text', '── Feature Dimensions ──', ...
                        'HorizontalAlignment', 'center', ...
                        'FontWeight', 'bold', ...
                        'FontColor', [0.3 0.3 0.6]);
    dimHeader.Layout.Column = [1 2];

    % Row 8: Primary Dimension
    uilabel(gl, 'Text', 'Primary Dim:', 'HorizontalAlignment', 'right');
    primaryDimPanel = uigridlayout(gl, [1, 3]);
    primaryDimPanel.ColumnWidth = {'1x', 80, 80};
    primaryDimPanel.Padding = [0 0 0 0];
    primaryDimEdit = uieditfield(primaryDimPanel, 'numeric', 'Value', 0);
    primaryDimUnits = uidropdown(primaryDimPanel, ...
                                 'Items', {'mm', 'cm', 'm', 'in', 'ft'}, ...
                                 'Value', 'mm');
    primaryDimLabel = uieditfield(primaryDimPanel, 'text', 'Value', '', ...
                                  'Placeholder', 'Label');

    % Row 9: Secondary Dimension
    uilabel(gl, 'Text', 'Secondary Dim:', 'HorizontalAlignment', 'right');
    secondaryDimPanel = uigridlayout(gl, [1, 3]);
    secondaryDimPanel.ColumnWidth = {'1x', 80, 80};
    secondaryDimPanel.Padding = [0 0 0 0];
    secondaryDimEdit = uieditfield(secondaryDimPanel, 'numeric', 'Value', 0);
    secondaryDimUnits = uidropdown(secondaryDimPanel, ...
                                   'Items', {'mm', 'cm', 'm', 'in', 'ft'}, ...
                                   'Value', 'mm');
    secondaryDimLabel = uieditfield(secondaryDimPanel, 'text', 'Value', '', ...
                                    'Placeholder', 'Label');

    % Row 10: Depth/Height
    uilabel(gl, 'Text', 'Depth/Height:', 'HorizontalAlignment', 'right');
    depthPanel = uigridlayout(gl, [1, 2]);
    depthPanel.ColumnWidth = {'1x', 80};
    depthPanel.Padding = [0 0 0 0];
    depthEdit = uieditfield(depthPanel, 'numeric', 'Value', 0);
    depthUnits = uidropdown(depthPanel, ...
                            'Items', {'mm', 'cm', 'm', 'in', 'ft'}, ...
                            'Value', 'mm');

    % Row 11: Angle (for chamfer, taper, etc.)
    uilabel(gl, 'Text', 'Angle:', 'HorizontalAlignment', 'right');
    anglePanel = uigridlayout(gl, [1, 2]);
    anglePanel.ColumnWidth = {'1x', 80};
    anglePanel.Padding = [0 0 0 0];
    angleEdit = uieditfield(anglePanel, 'numeric', 'Value', 0);
    angleUnits = uidropdown(anglePanel, ...
                            'Items', {'deg', 'rad'}, ...
                            'Value', 'deg');

    % Row 12: Radius (for fillet, rounds)
    uilabel(gl, 'Text', 'Radius:', 'HorizontalAlignment', 'right');
    radiusPanel = uigridlayout(gl, [1, 2]);
    radiusPanel.ColumnWidth = {'1x', 80};
    radiusPanel.Padding = [0 0 0 0];
    radiusEdit = uieditfield(radiusPanel, 'numeric', 'Value', 0);
    radiusUnits = uidropdown(radiusPanel, ...
                             'Items', {'mm', 'cm', 'm', 'in', 'ft'}, ...
                             'Value', 'mm');

    % Row 13: Separator
    sep1 = uilabel(gl, 'Text', '');
    sep1.Layout.Column = [1 2];

    % Row 14: Buttons
    buttonPanel = uigridlayout(gl, [1, 4]);
    buttonPanel.Layout.Row = 14;
    buttonPanel.Layout.Column = [1 2];
    buttonPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    buttonPanel.Padding = [0 0 0 0];

    createBtn = uibutton(buttonPanel, 'Text', 'Create', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    clearBtn = uibutton(buttonPanel, 'Text', 'Clear', ...
                        'BackgroundColor', [0.8 0.8 0.2]);
    exportBtn = uibutton(buttonPanel, 'Text', 'Copy JSON', ...
                         'BackgroundColor', [0.3 0.5 0.7]);
    saveBtn = uibutton(buttonPanel, 'Text', 'Save File', ...
                       'BackgroundColor', [0.5 0.3 0.7]);

    % Row 15: Status label
    statusLabel = uilabel(gl, 'Text', 'Ready', ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.2 0.2 0.8]);
    statusLabel.Layout.Column = [1 2];

    % Row 16: Separator
    sep2 = uilabel(gl, 'Text', '');
    sep2.Layout.Column = [1 2];

    % Row 17: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 17;
    jsonArea.Layout.Column = [1 2];

    % Row 18: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 18;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.nameEdit = nameEdit;
    ui.versionEdit = versionEdit;
    ui.typeDropdown = typeDropdown;
    ui.extrudeCheck = extrudeCheck;
    ui.revolveCheck = revolveCheck;
    ui.sweepCheck = sweepCheck;
    ui.loftCheck = loftCheck;
    ui.primaryDimEdit = primaryDimEdit;
    ui.primaryDimUnits = primaryDimUnits;
    ui.primaryDimLabel = primaryDimLabel;
    ui.secondaryDimEdit = secondaryDimEdit;
    ui.secondaryDimUnits = secondaryDimUnits;
    ui.secondaryDimLabel = secondaryDimLabel;
    ui.depthEdit = depthEdit;
    ui.depthUnits = depthUnits;
    ui.angleEdit = angleEdit;
    ui.angleUnits = angleUnits;
    ui.radiusEdit = radiusEdit;
    ui.radiusUnits = radiusUnits;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createFeature(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.feature;
            close(fig);
        else
            varargout{1} = [];
        end
    end
end

%% Create Feature callback
function createFeature(ui)
    try
        % Build a CAD_Feature struct matching the C# CAD_Feature class

        feature = struct();

        % ── Identification ──
        feature.Name = ui.nameEdit.Value;
        feature.Version = ui.versionEdit.Value;

        % ── GeometricFeatureType (GeometricFeatureTypeEnum) ──
        typeMap = containers.Map(...
            {'Hole', 'Joint', 'Thread', 'Chamfer', 'Fillet', ...
             'CounterBore', 'CounterSink', 'Bead', 'Boss', 'Keyway', ...
             'Leg', 'Arm', 'Mirror', 'Embossment', 'Rib', ...
             'RoundedSlot', 'Gusset', 'Taper', 'SquareSlot', 'Shell', ...
             'Web', 'Tab', 'Coil', 'Helicoil', 'RectangularPattern', ...
             'CircularPattern', 'OtherPattern', 'Other'}, ...
            {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, ...
             15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27});
        feature.GeometricFeatureType = typeMap(ui.typeDropdown.Value);

        % ── ThreeDimOperations (List<Feature3DOperationEnum>) ──
        ops = [];
        if ui.extrudeCheck.Value, ops(end+1) = 0; end  % Extrude
        if ui.revolveCheck.Value, ops(end+1) = 1; end   % Revolve
        if ui.sweepCheck.Value,   ops(end+1) = 2; end   % Sweep
        if ui.loftCheck.Value,    ops(end+1) = 3; end    % Loft
        feature.ThreeDimOperations = ops;

        % ── MyDimensions (List<Dimension>) ──
        feature.MyDimensions = {};

        % Primary dimension
        if ui.primaryDimEdit.Value ~= 0 || ~isempty(ui.primaryDimLabel.Value)
            label = ui.primaryDimLabel.Value;
            if isempty(label), label = 'Primary'; end
            feature.MyDimensions{end+1} = createDimensionStruct( ...
                'DIM_PRIMARY', label, ui.primaryDimEdit.Value, ...
                ui.primaryDimUnits.Value, 0);  % Length
        end

        % Secondary dimension
        if ui.secondaryDimEdit.Value ~= 0 || ~isempty(ui.secondaryDimLabel.Value)
            label = ui.secondaryDimLabel.Value;
            if isempty(label), label = 'Secondary'; end
            feature.MyDimensions{end+1} = createDimensionStruct( ...
                'DIM_SECONDARY', label, ui.secondaryDimEdit.Value, ...
                ui.secondaryDimUnits.Value, 0);  % Length
        end

        % Depth dimension
        if ui.depthEdit.Value ~= 0
            feature.MyDimensions{end+1} = createDimensionStruct( ...
                'DIM_DEPTH', 'Depth', ui.depthEdit.Value, ...
                ui.depthUnits.Value, 4);  % Distance
        end

        % Angle dimension
        if ui.angleEdit.Value ~= 0
            feature.MyDimensions{end+1} = createDimensionStruct( ...
                'DIM_ANGLE', 'Angle', ui.angleEdit.Value, ...
                ui.angleUnits.Value, 3);  % Angle
        end

        % Radius dimension
        if ui.radiusEdit.Value ~= 0
            feature.MyDimensions{end+1} = createDimensionStruct( ...
                'DIM_RADIUS', 'Radius', ui.radiusEdit.Value, ...
                ui.radiusUnits.Value, 2);  % Radius
        end

        % CurrentDimension (first dimension or empty)
        if ~isempty(feature.MyDimensions)
            feature.CurrentDimension = feature.MyDimensions{1};
        else
            feature.CurrentDimension = [];
        end

        % ── Owned & Owning objects ──
        feature.CurrentFeature = [];
        feature.MyFeatures = {};

        % ── Sketches ──
        feature.CurrentCAD_Sketch = [];
        feature.Sketches = {};

        % ── Stations ──
        feature.CurrentCAD_Station = [];
        feature.Stations = {};

        % ── Model & Coordinate System ──
        feature.MyModel = [];
        feature.Origin = [];

        % ── Libraries ──
        feature.CurrentLibrary = [];
        feature.MyLibraries = {};

        % Store in figure UserData
        ui.fig.UserData.feature = feature;

        % Generate JSON preview
        jsonStr = jsonencode(feature, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Feature created successfully!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Clear Form callback
function clearForm(ui)
    ui.nameEdit.Value = '';
    ui.versionEdit.Value = '';
    ui.typeDropdown.Value = 'Hole';
    ui.extrudeCheck.Value = false;
    ui.revolveCheck.Value = false;
    ui.sweepCheck.Value = false;
    ui.loftCheck.Value = false;
    ui.primaryDimEdit.Value = 0;
    ui.primaryDimUnits.Value = 'mm';
    ui.primaryDimLabel.Value = '';
    ui.secondaryDimEdit.Value = 0;
    ui.secondaryDimUnits.Value = 'mm';
    ui.secondaryDimLabel.Value = '';
    ui.depthEdit.Value = 0;
    ui.depthUnits.Value = 'mm';
    ui.angleEdit.Value = 0;
    ui.angleUnits.Value = 'deg';
    ui.radiusEdit.Value = 0;
    ui.radiusUnits.Value = 'mm';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.feature = [];
end

%% Export JSON callback
function exportJSON(ui)
    feature = ui.fig.UserData.feature;
    if isempty(feature)
        ui.statusLabel.Text = 'No feature created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(feature, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    feature = ui.fig.UserData.feature;
    if isempty(feature)
        ui.statusLabel.Text = 'No feature created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Feature.json';
    if isfield(feature, 'Name') && ~isempty(feature.Name)
        defaultName = [feature.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Feature JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(feature, 'PrettyPrint', true);

    fid = fopen(filePath, 'w');
    if fid == -1
        ui.statusLabel.Text = 'Error: Could not write file!';
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
        return;
    end

    fprintf(fid, '%s', jsonStr);
    fclose(fid);

    ui.statusLabel.Text = ['Saved to: ' filename];
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Create a Dimension struct matching the C# Dimension class
function dim = createDimensionStruct(dimID, description, nominalValue, unitName, dimType)
    dim = struct();

    % Identification
    dim.DimensionID = dimID;
    dim.Description = description;
    dim.IsOrdinate = false;

    % Geometry / Locating Points (Mathematics.Point)
    dim.CenterPoint = createPoint(0, 0, 0);
    dim.LeaderLineEndPoint = [];
    dim.LeaderLineBendPoint = [];
    dim.DimensionPoint = [];
    dim.ReferencePoint = [];

    % Associations
    dim.MySegment = [];
    dim.MyModel = [];

    % Dimension values
    dim.DimensionNominalValue = nominalValue;
    dim.DimensionUpperLimitValue = nominalValue;
    dim.DimensionLowerLimitValue = nominalValue;
    dim.MyDimensionType = dimType;

    % Engineering unit (SE_Library.UnitOfMeasure)
    dim.EngineeringUnit = createUnitOfMeasure(unitName);

    % Parameters
    dim.CurrentParameter = [];
    dim.MyParameters = {};
end

%% Create a UnitOfMeasure struct matching the C# SE_Library.UnitOfMeasure class
function uom = createUnitOfMeasure(unitName)
    uom = struct();
    uom.Name = unitName;
    uom.Description = '';
    uom.SymbolName = unitName;
    uom.UnitValue = 1.0;
    uom.IsBaseUnit = false;

    % Determine SystemOfUnits (0=SI, 1=Imperial)
    imperialUnits = {'in', 'ft', 'yd', 'mi', 'oz', 'lb'};
    if any(strcmpi(unitName, imperialUnits))
        uom.SystemOfUnits = 1;  % Imperial
    else
        uom.SystemOfUnits = 0;  % SI
    end
end

%% Create a Mathematics.Point struct (Cartesian)
function pt = createPoint(x, y, z)
    pt = struct();
    pt.PointID = '';
    pt.IsWeightPoint = false;
    pt.MyType = 0;  % Cartesian
    pt.Is2D = false;
    pt.X_Value = x;
    pt.Y_Value = y;
    pt.Z_Value_Cartesian = z;
    pt.R_Value_Cylindrical = 0;
    pt.Theta_Value_Cylindrical = 0;
    pt.Z_Value_Cylindrical = 0;
    pt.R_Value_Spherical = 0;
    pt.Theta_Value_Spherical = 0;
    pt.Phi_Value = 0;
    pt.Longitude = 0;
    pt.Latitude = 0;
    pt.Altitude = 0;
    pt.Real_Value = 0;
    pt.Complex_Value = 0;
    pt.CurrentCoordinateSystem = [];
    pt.MyCoordinateSystems = {};
    pt.CurrentConnectedPoint = [];
    pt.MyConnectedPoints = {};
end
