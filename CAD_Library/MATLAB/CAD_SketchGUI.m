%% CAD_SketchGUI.m
% MATLAB GUI for creating and editing CAD_Sketch objects
%
% Usage:
%   CAD_SketchGUI()              - Opens the GUI
%   sketch = CAD_SketchGUI()     - Opens GUI and returns created sketch
%
% CAD_Sketch represents 2D/3D sketch geometry containing points, segments,
% dimensions, constraints, and sketch elements.

function varargout = CAD_SketchGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Sketch Creator', ...
                   'Position', [100 100 550 700], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.sketch = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [19, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 15), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Sketch Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Sketch ID
    uilabel(gl, 'Text', 'Sketch ID:', 'HorizontalAlignment', 'right');
    sketchIdEdit = uieditfield(gl, 'text', 'Value', '', ...
                               'Placeholder', 'e.g., SK-001');

    % Row 3: Version
    uilabel(gl, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(gl, 'text', 'Value', '1.0', ...
                              'Placeholder', 'e.g., 1.0');

    % Row 4: Is 2D
    uilabel(gl, 'Text', 'Is 2D Sketch:', 'HorizontalAlignment', 'right');
    is2DCheck = uicheckbox(gl, 'Text', '', 'Value', true);

    % Row 5: Properties header
    propsHeader = uilabel(gl, 'Text', '── Sketch Properties ──', ...
                          'HorizontalAlignment', 'center', ...
                          'FontWeight', 'bold', ...
                          'FontColor', [0.3 0.3 0.6]);
    propsHeader.Layout.Column = [1 2];

    % Row 6: Area
    uilabel(gl, 'Text', 'Area:', 'HorizontalAlignment', 'right');
    areaPanel = uigridlayout(gl, [1, 2]);
    areaPanel.ColumnWidth = {'1x', 60};
    areaPanel.Padding = [0 0 0 0];
    areaEdit = uieditfield(areaPanel, 'numeric', 'Value', 0);
    uilabel(areaPanel, 'Text', 'mm^2');

    % Row 7: Perimeter
    uilabel(gl, 'Text', 'Perimeter:', 'HorizontalAlignment', 'right');
    perimeterPanel = uigridlayout(gl, [1, 2]);
    perimeterPanel.ColumnWidth = {'1x', 60};
    perimeterPanel.Padding = [0 0 0 0];
    perimeterEdit = uieditfield(perimeterPanel, 'numeric', 'Value', 0);
    uilabel(perimeterPanel, 'Text', 'mm');

    % Row 8: Contents header
    contentsHeader = uilabel(gl, 'Text', '── Sketch Contents ──', ...
                             'HorizontalAlignment', 'center', ...
                             'FontWeight', 'bold', ...
                             'FontColor', [0.3 0.3 0.6]);
    contentsHeader.Layout.Column = [1 2];

    % Row 9: Points
    uilabel(gl, 'Text', 'Points:', 'HorizontalAlignment', 'right');
    pointsLabel = uilabel(gl, 'Text', '0 points', ...
                          'FontColor', [0.4 0.4 0.4]);

    % Row 10: Segments
    uilabel(gl, 'Text', 'Segments:', 'HorizontalAlignment', 'right');
    segmentsLabel = uilabel(gl, 'Text', '0 segments', ...
                            'FontColor', [0.4 0.4 0.4]);

    % Row 11: Dimensions
    uilabel(gl, 'Text', 'Dimensions:', 'HorizontalAlignment', 'right');
    dimensionsLabel = uilabel(gl, 'Text', '0 dimensions', ...
                              'FontColor', [0.4 0.4 0.4]);

    % Row 12: Constraints
    uilabel(gl, 'Text', 'Constraints:', 'HorizontalAlignment', 'right');
    constraintsLabel = uilabel(gl, 'Text', '0 constraints', ...
                               'FontColor', [0.4 0.4 0.4]);

    % Row 13: Sketch Elements
    uilabel(gl, 'Text', 'Sketch Elements:', 'HorizontalAlignment', 'right');
    elementsLabel = uilabel(gl, 'Text', '0 elements', ...
                            'FontColor', [0.4 0.4 0.4]);

    % Row 14: Status header
    statusHeader = uilabel(gl, 'Text', '── Sketch Status ──', ...
                           'HorizontalAlignment', 'center', ...
                           'FontWeight', 'bold', ...
                           'FontColor', [0.3 0.3 0.6]);
    statusHeader.Layout.Column = [1 2];

    % Row 15: Closed loop indicator
    uilabel(gl, 'Text', 'Closed Loop:', 'HorizontalAlignment', 'right');
    closedLoopLabel = uilabel(gl, 'Text', 'Unknown', ...
                              'FontColor', [0.4 0.4 0.4]);

    % Row 16: Buttons
    buttonPanel = uigridlayout(gl, [1, 4]);
    buttonPanel.Layout.Row = 16;
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

    % Row 17: Status label
    statusLabel = uilabel(gl, 'Text', 'Ready', ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.2 0.2 0.8]);
    statusLabel.Layout.Column = [1 2];

    % Row 18: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 18;
    jsonArea.Layout.Column = [1 2];

    % Row 19: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 19;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.sketchIdEdit = sketchIdEdit;
    ui.versionEdit = versionEdit;
    ui.is2DCheck = is2DCheck;
    ui.areaEdit = areaEdit;
    ui.perimeterEdit = perimeterEdit;
    ui.pointsLabel = pointsLabel;
    ui.segmentsLabel = segmentsLabel;
    ui.dimensionsLabel = dimensionsLabel;
    ui.constraintsLabel = constraintsLabel;
    ui.elementsLabel = elementsLabel;
    ui.closedLoopLabel = closedLoopLabel;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createSketch(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.sketch;
            close(fig);
        else
            varargout{1} = [];
        end
    end
end

%% Create Sketch callback
function createSketch(ui)
    try
        % Build the sketch struct
        sketch = struct();

        % Identification
        sketch.SketchID = ui.sketchIdEdit.Value;
        sketch.Version = ui.versionEdit.Value;
        sketch.IsTwoD = ui.is2DCheck.Value;

        % Properties
        if ui.areaEdit.Value > 0
            sketch.Area = struct();
            sketch.Area.Name = 'Area';
            sketch.Area.Value = struct('DoubleValue', ui.areaEdit.Value, 'ValueType', 0);
            sketch.Area.MyUnits = struct('UnitName', 'mm^2');
        end

        if ui.perimeterEdit.Value > 0
            sketch.PerimeterLength = struct();
            sketch.PerimeterLength.Name = 'PerimeterLength';
            sketch.PerimeterLength.Value = struct('DoubleValue', ui.perimeterEdit.Value, 'ValueType', 0);
            sketch.PerimeterLength.MyUnits = struct('UnitName', 'mm');
        end

        % Initialize empty collections
        sketch.MyPoints = {};
        sketch.MySegments = {};
        sketch.MyProfile = {};
        sketch.My2DGeometry = {};
        sketch.MyCoordinateSystems = {};
        sketch.MySketchElements = {};
        sketch.MyParameters = {};
        sketch.MyDimensions = {};
        sketch.MyConstraints = {};

        % Store in figure UserData
        ui.fig.UserData.sketch = sketch;

        % Generate JSON preview
        jsonStr = jsonencode(sketch, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Sketch created successfully!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Clear Form callback
function clearForm(ui)
    ui.sketchIdEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.is2DCheck.Value = true;
    ui.areaEdit.Value = 0;
    ui.perimeterEdit.Value = 0;
    ui.pointsLabel.Text = '0 points';
    ui.segmentsLabel.Text = '0 segments';
    ui.dimensionsLabel.Text = '0 dimensions';
    ui.constraintsLabel.Text = '0 constraints';
    ui.elementsLabel.Text = '0 elements';
    ui.closedLoopLabel.Text = 'Unknown';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.sketch = [];
end

%% Export JSON callback
function exportJSON(ui)
    sketch = ui.fig.UserData.sketch;
    if isempty(sketch)
        ui.statusLabel.Text = 'No sketch created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(sketch, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    sketch = ui.fig.UserData.sketch;
    if isempty(sketch)
        ui.statusLabel.Text = 'No sketch created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Sketch.json';
    if isfield(sketch, 'SketchID') && ~isempty(sketch.SketchID)
        defaultName = [sketch.SketchID '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Sketch JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(sketch, 'PrettyPrint', true);

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
