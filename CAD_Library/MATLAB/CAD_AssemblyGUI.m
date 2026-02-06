%% CAD_AssemblyGUI.m
% MATLAB GUI for creating and editing CAD_Assembly objects
%
% Usage:
%   CAD_AssemblyGUI()              - Opens the GUI
%   assembly = CAD_AssemblyGUI()   - Opens GUI and returns created assembly
%
% The GUI allows you to:
%   - Enter all CAD_Assembly properties
%   - Create the assembly object
%   - Export to JSON
%   - Save JSON to file

function varargout = CAD_AssemblyGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Assembly Creator', ...
                   'Position', [100 100 550 700], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.assembly = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [19, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 15), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Assembly Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Name
    uilabel(gl, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Assembly name');

    % Row 3: Version
    uilabel(gl, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(gl, 'text', 'Value', '1.0', ...
                              'Placeholder', 'e.g., 1.0');

    % Row 4: Description
    uilabel(gl, 'Text', 'Description:', 'HorizontalAlignment', 'right');
    descEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Assembly description');

    % Row 5: Flags header
    flagsHeader = uilabel(gl, 'Text', '── Assembly Flags ──', ...
                          'HorizontalAlignment', 'center', ...
                          'FontWeight', 'bold', ...
                          'FontColor', [0.3 0.3 0.6]);
    flagsHeader.Layout.Column = [1 2];

    % Row 6: Is Sub-Assembly
    uilabel(gl, 'Text', 'Is Sub-Assembly:', 'HorizontalAlignment', 'right');
    isSubAssemblyCheck = uicheckbox(gl, 'Text', '', 'Value', false);

    % Row 7: Is Configuration Item
    uilabel(gl, 'Text', 'Is Config Item:', 'HorizontalAlignment', 'right');
    isConfigItemCheck = uicheckbox(gl, 'Text', '', 'Value', false);

    % Row 8: Position header
    posHeader = uilabel(gl, 'Text', '── Position & Orientation ──', ...
                        'HorizontalAlignment', 'center', ...
                        'FontWeight', 'bold', ...
                        'FontColor', [0.3 0.3 0.6]);
    posHeader.Layout.Column = [1 2];

    % Row 9: Position
    uilabel(gl, 'Text', 'Position:', 'HorizontalAlignment', 'right');
    positionEdit = uieditfield(gl, 'text', 'Value', '0, 0, 0', ...
                               'Placeholder', 'X, Y, Z');

    % Row 10: Orientation
    uilabel(gl, 'Text', 'Orientation:', 'HorizontalAlignment', 'right');
    orientationEdit = uieditfield(gl, 'text', 'Value', '0, 0, 0', ...
                                  'Placeholder', 'Roll, Pitch, Yaw (deg)');

    % Row 11: Stations header
    stationHeader = uilabel(gl, 'Text', '── Reference Stations ──', ...
                            'HorizontalAlignment', 'center', ...
                            'FontWeight', 'bold', ...
                            'FontColor', [0.3 0.3 0.6]);
    stationHeader.Layout.Column = [1 2];

    % Row 12: Axial Station
    uilabel(gl, 'Text', 'Axial Station:', 'HorizontalAlignment', 'right');
    axialStationEdit = uieditfield(gl, 'numeric', 'Value', 0);

    % Row 13: Radial Station
    uilabel(gl, 'Text', 'Radial Station:', 'HorizontalAlignment', 'right');
    radialStationEdit = uieditfield(gl, 'numeric', 'Value', 0);

    % Row 14: Angular Station
    uilabel(gl, 'Text', 'Angular Station:', 'HorizontalAlignment', 'right');
    angularStationEdit = uieditfield(gl, 'numeric', 'Value', 0);

    % Row 15: Summary
    summaryHeader = uilabel(gl, 'Text', '── Summary ──', ...
                            'HorizontalAlignment', 'center', ...
                            'FontWeight', 'bold', ...
                            'FontColor', [0.3 0.3 0.6]);
    summaryHeader.Layout.Column = [1 2];

    % Row 16: Component count display
    uilabel(gl, 'Text', 'Components:', 'HorizontalAlignment', 'right');
    componentCountLabel = uilabel(gl, 'Text', '0 components', ...
                                  'FontColor', [0.4 0.4 0.4]);

    % Row 17: Buttons
    buttonPanel = uigridlayout(gl, [1, 4]);
    buttonPanel.Layout.Row = 17;
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

    % Row 18: Status label
    statusLabel = uilabel(gl, 'Text', 'Ready', ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.2 0.2 0.8]);
    statusLabel.Layout.Column = [1 2];

    % Row 19: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 18;
    jsonArea.Layout.Column = [1 2];

    % Row 20: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 19;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.nameEdit = nameEdit;
    ui.versionEdit = versionEdit;
    ui.descEdit = descEdit;
    ui.isSubAssemblyCheck = isSubAssemblyCheck;
    ui.isConfigItemCheck = isConfigItemCheck;
    ui.positionEdit = positionEdit;
    ui.orientationEdit = orientationEdit;
    ui.axialStationEdit = axialStationEdit;
    ui.radialStationEdit = radialStationEdit;
    ui.angularStationEdit = angularStationEdit;
    ui.componentCountLabel = componentCountLabel;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createAssembly(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.assembly;
            close(fig);
        else
            varargout{1} = [];
        end
    end
end

%% Parse point string to struct
function point = parsePoint(str)
    point = struct();
    point.X_Value = 0;
    point.Y_Value = 0;
    point.Z_Value_Cartesian = 0;

    if isempty(str)
        return;
    end

    parts = strsplit(str, ',');
    if length(parts) >= 1
        point.X_Value = str2double(strtrim(parts{1}));
    end
    if length(parts) >= 2
        point.Y_Value = str2double(strtrim(parts{2}));
    end
    if length(parts) >= 3
        point.Z_Value_Cartesian = str2double(strtrim(parts{3}));
    end

    % Handle NaN
    if isnan(point.X_Value), point.X_Value = 0; end
    if isnan(point.Y_Value), point.Y_Value = 0; end
    if isnan(point.Z_Value_Cartesian), point.Z_Value_Cartesian = 0; end
end

%% Parse vector string to struct
function vec = parseVector(str)
    vec = struct();
    vec.X = 0;
    vec.Y = 0;
    vec.Z = 0;

    if isempty(str)
        return;
    end

    parts = strsplit(str, ',');
    if length(parts) >= 1
        vec.X = str2double(strtrim(parts{1}));
    end
    if length(parts) >= 2
        vec.Y = str2double(strtrim(parts{2}));
    end
    if length(parts) >= 3
        vec.Z = str2double(strtrim(parts{3}));
    end

    % Handle NaN
    if isnan(vec.X), vec.X = 0; end
    if isnan(vec.Y), vec.Y = 0; end
    if isnan(vec.Z), vec.Z = 0; end
end

%% Create Assembly callback
function createAssembly(ui)
    try
        % Build the assembly struct
        assembly = struct();

        % Identification
        assembly.Name = ui.nameEdit.Value;
        assembly.Version = ui.versionEdit.Value;
        assembly.Description = ui.descEdit.Value;

        % Flags
        assembly.IsSubAssembly = ui.isSubAssemblyCheck.Value;
        assembly.IsConfigurationItem = ui.isConfigItemCheck.Value;

        % Position and orientation
        assembly.MyPosition = parsePoint(ui.positionEdit.Value);
        assembly.MyOrientation = parseVector(ui.orientationEdit.Value);

        % Initialize empty collections
        assembly.MyComponents = {};
        assembly.MyConfigurations = {};
        assembly.MissionRequirements = {};
        assembly.SystemRequirements = {};
        assembly.MyInterfaces = {};
        assembly.MyCoordinateSystems = {};

        % Stations
        if ui.axialStationEdit.Value ~= 0
            station = struct();
            station.StationType = 0; % Axial
            station.Value = ui.axialStationEdit.Value;
            station.Name = 'Axial_Station_1';
            assembly.AxialStations = {station};
        else
            assembly.AxialStations = {};
        end

        if ui.radialStationEdit.Value ~= 0
            station = struct();
            station.StationType = 1; % Radial
            station.Value = ui.radialStationEdit.Value;
            station.Name = 'Radial_Station_1';
            assembly.RadialStations = {station};
        else
            assembly.RadialStations = {};
        end

        if ui.angularStationEdit.Value ~= 0
            station = struct();
            station.StationType = 2; % Angular
            station.Value = ui.angularStationEdit.Value;
            station.Name = 'Angular_Station_1';
            assembly.AngularStations = {station};
        else
            assembly.AngularStations = {};
        end

        assembly.WingStations = {};

        % Store in figure UserData
        ui.fig.UserData.assembly = assembly;

        % Generate JSON preview
        jsonStr = jsonencode(assembly, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Assembly created successfully!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Clear Form callback
function clearForm(ui)
    ui.nameEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.descEdit.Value = '';
    ui.isSubAssemblyCheck.Value = false;
    ui.isConfigItemCheck.Value = false;
    ui.positionEdit.Value = '0, 0, 0';
    ui.orientationEdit.Value = '0, 0, 0';
    ui.axialStationEdit.Value = 0;
    ui.radialStationEdit.Value = 0;
    ui.angularStationEdit.Value = 0;
    ui.componentCountLabel.Text = '0 components';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.assembly = [];
end

%% Export JSON callback
function exportJSON(ui)
    assembly = ui.fig.UserData.assembly;
    if isempty(assembly)
        ui.statusLabel.Text = 'No assembly created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(assembly, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    assembly = ui.fig.UserData.assembly;
    if isempty(assembly)
        ui.statusLabel.Text = 'No assembly created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Assembly.json';
    if isfield(assembly, 'Name') && ~isempty(assembly.Name)
        defaultName = [assembly.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Assembly JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(assembly, 'PrettyPrint', true);

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
