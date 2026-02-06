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
        % Build the feature struct
        feature = struct();

        % Identification
        feature.Name = ui.nameEdit.Value;
        feature.Version = ui.versionEdit.Value;

        % Feature type enum mapping
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

        % 3D Operations
        ops = [];
        if ui.extrudeCheck.Value
            ops(end+1) = 0; % Extrude
        end
        if ui.revolveCheck.Value
            ops(end+1) = 1; % Revolve
        end
        if ui.sweepCheck.Value
            ops(end+1) = 2; % Sweep
        end
        if ui.loftCheck.Value
            ops(end+1) = 3; % Loft
        end
        feature.ThreeDimOperations = ops;

        % Create dimensions
        feature.MyDimensions = {};

        % Primary dimension
        if ui.primaryDimEdit.Value ~= 0 || ~isempty(ui.primaryDimLabel.Value)
            dim1 = struct();
            dim1.DimensionID = 'DIM_PRIMARY';
            dim1.Name = ui.primaryDimLabel.Value;
            dim1.DimensionNominalValue = ui.primaryDimEdit.Value;
            dim1.EngineeringUnit = struct('UnitName', ui.primaryDimUnits.Value);
            dim1.MyDimensionType = 0; % Length
            feature.MyDimensions{end+1} = dim1;
        end

        % Secondary dimension
        if ui.secondaryDimEdit.Value ~= 0 || ~isempty(ui.secondaryDimLabel.Value)
            dim2 = struct();
            dim2.DimensionID = 'DIM_SECONDARY';
            dim2.Name = ui.secondaryDimLabel.Value;
            dim2.DimensionNominalValue = ui.secondaryDimEdit.Value;
            dim2.EngineeringUnit = struct('UnitName', ui.secondaryDimUnits.Value);
            dim2.MyDimensionType = 0; % Length
            feature.MyDimensions{end+1} = dim2;
        end

        % Depth dimension
        if ui.depthEdit.Value ~= 0
            dimDepth = struct();
            dimDepth.DimensionID = 'DIM_DEPTH';
            dimDepth.Name = 'Depth';
            dimDepth.DimensionNominalValue = ui.depthEdit.Value;
            dimDepth.EngineeringUnit = struct('UnitName', ui.depthUnits.Value);
            dimDepth.MyDimensionType = 4; % Distance
            feature.MyDimensions{end+1} = dimDepth;
        end

        % Angle dimension
        if ui.angleEdit.Value ~= 0
            dimAngle = struct();
            dimAngle.DimensionID = 'DIM_ANGLE';
            dimAngle.Name = 'Angle';
            dimAngle.DimensionNominalValue = ui.angleEdit.Value;
            dimAngle.EngineeringUnit = struct('UnitName', ui.angleUnits.Value);
            dimAngle.MyDimensionType = 3; % Angle
            feature.MyDimensions{end+1} = dimAngle;
        end

        % Radius dimension
        if ui.radiusEdit.Value ~= 0
            dimRadius = struct();
            dimRadius.DimensionID = 'DIM_RADIUS';
            dimRadius.Name = 'Radius';
            dimRadius.DimensionNominalValue = ui.radiusEdit.Value;
            dimRadius.EngineeringUnit = struct('UnitName', ui.radiusUnits.Value);
            dimRadius.MyDimensionType = 2; % Radius
            feature.MyDimensions{end+1} = dimRadius;
        end

        % Initialize empty collections
        feature.Sketches = {};
        feature.Stations = {};
        feature.MyFeatures = {};
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
