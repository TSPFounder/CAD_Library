%% CAD_PartGUI.m
% MATLAB GUI for creating and editing CAD_Part objects
%
% Usage:
%   CAD_PartGUI()              - Opens the GUI
%   part = CAD_PartGUI()       - Opens GUI and returns created part
%
% The GUI allows you to:
%   - Enter all CAD_Part properties
%   - Create the part object
%   - Export to JSON
%   - Save JSON to file

function varargout = CAD_PartGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Part Creator', ...
                   'Position', [100 100 550 750], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.part = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [20, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 16), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Part Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Name
    uilabel(gl, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Part name');

    % Row 3: Part Number
    uilabel(gl, 'Text', 'Part Number:', 'HorizontalAlignment', 'right');
    partNumEdit = uieditfield(gl, 'text', 'Value', '', ...
                              'Placeholder', 'e.g., PN-001');

    % Row 4: Version
    uilabel(gl, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(gl, 'text', 'Value', '1.0', ...
                              'Placeholder', 'e.g., 1.0');

    % Row 5: Description
    uilabel(gl, 'Text', 'Description:', 'HorizontalAlignment', 'right');
    descEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Part description');

    % Row 6: Section header - Mass Properties
    massHeader = uilabel(gl, 'Text', '── Mass Properties ──', ...
                         'HorizontalAlignment', 'center', ...
                         'FontWeight', 'bold', ...
                         'FontColor', [0.3 0.3 0.6]);
    massHeader.Layout.Column = [1 2];

    % Row 7: Mass
    uilabel(gl, 'Text', 'Mass:', 'HorizontalAlignment', 'right');
    massPanel = uigridlayout(gl, [1, 2]);
    massPanel.ColumnWidth = {'1x', 80};
    massPanel.Padding = [0 0 0 0];
    massEdit = uieditfield(massPanel, 'numeric', 'Value', 0);
    massUnits = uidropdown(massPanel, ...
                           'Items', {'kg', 'g', 'lb', 'oz'}, ...
                           'Value', 'kg');

    % Row 8: Center of Mass
    uilabel(gl, 'Text', 'Center of Mass:', 'HorizontalAlignment', 'right');
    comEdit = uieditfield(gl, 'text', 'Value', '0, 0, 0', ...
                          'Placeholder', 'X, Y, Z');

    % Row 9: Section header - Geometry Counts
    geomHeader = uilabel(gl, 'Text', '── Geometry Summary ──', ...
                         'HorizontalAlignment', 'center', ...
                         'FontWeight', 'bold', ...
                         'FontColor', [0.3 0.3 0.6]);
    geomHeader.Layout.Column = [1 2];

    % Row 10: Feature count
    uilabel(gl, 'Text', 'Features:', 'HorizontalAlignment', 'right');
    featureCountLabel = uilabel(gl, 'Text', '0 features', ...
                                'FontColor', [0.4 0.4 0.4]);

    % Row 11: Sketch count
    uilabel(gl, 'Text', 'Sketches:', 'HorizontalAlignment', 'right');
    sketchCountLabel = uilabel(gl, 'Text', '0 sketches', ...
                               'FontColor', [0.4 0.4 0.4]);

    % Row 12: Body count
    uilabel(gl, 'Text', 'Bodies:', 'HorizontalAlignment', 'right');
    bodyCountLabel = uilabel(gl, 'Text', '0 bodies', ...
                             'FontColor', [0.4 0.4 0.4]);

    % Row 13: Section header - Stations
    stationHeader = uilabel(gl, 'Text', '── Reference Stations ──', ...
                            'HorizontalAlignment', 'center', ...
                            'FontWeight', 'bold', ...
                            'FontColor', [0.3 0.3 0.6]);
    stationHeader.Layout.Column = [1 2];

    % Row 14: Axial Station
    uilabel(gl, 'Text', 'Axial Station:', 'HorizontalAlignment', 'right');
    axialStationEdit = uieditfield(gl, 'numeric', 'Value', 0, ...
                                   'Tooltip', 'Primary axial reference');

    % Row 15: Radial Station
    uilabel(gl, 'Text', 'Radial Station:', 'HorizontalAlignment', 'right');
    radialStationEdit = uieditfield(gl, 'numeric', 'Value', 0, ...
                                    'Tooltip', 'Radial reference from centerline');

    % Row 16: Angular Station
    uilabel(gl, 'Text', 'Angular Station:', 'HorizontalAlignment', 'right');
    angularPanel = uigridlayout(gl, [1, 2]);
    angularPanel.ColumnWidth = {'1x', 60};
    angularPanel.Padding = [0 0 0 0];
    angularStationEdit = uieditfield(angularPanel, 'numeric', 'Value', 0);
    uilabel(angularPanel, 'Text', 'deg');

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

    % Row 19: Separator
    sep2 = uilabel(gl, 'Text', '');
    sep2.Layout.Column = [1 2];

    % Row 20: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 19;
    jsonArea.Layout.Column = [1 2];

    % Row 21: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 20;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.nameEdit = nameEdit;
    ui.partNumEdit = partNumEdit;
    ui.versionEdit = versionEdit;
    ui.descEdit = descEdit;
    ui.massEdit = massEdit;
    ui.massUnits = massUnits;
    ui.comEdit = comEdit;
    ui.featureCountLabel = featureCountLabel;
    ui.sketchCountLabel = sketchCountLabel;
    ui.bodyCountLabel = bodyCountLabel;
    ui.axialStationEdit = axialStationEdit;
    ui.radialStationEdit = radialStationEdit;
    ui.angularStationEdit = angularStationEdit;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createPart(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.part;
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

%% Create Part callback
function createPart(ui)
    try
        % Build the part struct
        part = struct();

        % Identification
        part.Name = ui.nameEdit.Value;
        part.PartNumber = ui.partNumEdit.Value;
        part.Version = ui.versionEdit.Value;
        part.Description = ui.descEdit.Value;

        % Mass properties
        part.MyMassProperties = struct();
        part.MyMassProperties.Mass = ui.massEdit.Value;
        part.MyMassProperties.MassUnit = ui.massUnits.Value;

        % Center of mass
        part.CenterOfMass = parsePoint(ui.comEdit.Value);

        % Initialize empty collections
        part.MySketches = {};
        part.MyFeatures = {};
        part.MyBodies = {};
        part.MyDrawings = {};
        part.MyDimensions = {};
        part.MyParameters = {};
        part.MyModels = {};
        part.MyCoordinateSystems = {};
        part.MyInterfaces = {};
        part.MyMassPropertiesList = {};

        % Stations
        if ui.axialStationEdit.Value ~= 0
            station = struct();
            station.StationType = 0; % Axial
            station.Value = ui.axialStationEdit.Value;
            station.Name = 'Axial_Station_1';
            part.AxialStations = {station};
        else
            part.AxialStations = {};
        end

        if ui.radialStationEdit.Value ~= 0
            station = struct();
            station.StationType = 1; % Radial
            station.Value = ui.radialStationEdit.Value;
            station.Name = 'Radial_Station_1';
            part.RadialStations = {station};
        else
            part.RadialStations = {};
        end

        if ui.angularStationEdit.Value ~= 0
            station = struct();
            station.StationType = 2; % Angular
            station.Value = ui.angularStationEdit.Value;
            station.Name = 'Angular_Station_1';
            part.AngularStations = {station};
        else
            part.AngularStations = {};
        end

        part.WingStations = {};

        % Store in figure UserData
        ui.fig.UserData.part = part;

        % Generate JSON preview
        jsonStr = jsonencode(part, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Part created successfully!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Clear Form callback
function clearForm(ui)
    ui.nameEdit.Value = '';
    ui.partNumEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.descEdit.Value = '';
    ui.massEdit.Value = 0;
    ui.massUnits.Value = 'kg';
    ui.comEdit.Value = '0, 0, 0';
    ui.axialStationEdit.Value = 0;
    ui.radialStationEdit.Value = 0;
    ui.angularStationEdit.Value = 0;
    ui.featureCountLabel.Text = '0 features';
    ui.sketchCountLabel.Text = '0 sketches';
    ui.bodyCountLabel.Text = '0 bodies';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.part = [];
end

%% Export JSON callback
function exportJSON(ui)
    part = ui.fig.UserData.part;
    if isempty(part)
        ui.statusLabel.Text = 'No part created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(part, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    part = ui.fig.UserData.part;
    if isempty(part)
        ui.statusLabel.Text = 'No part created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Part.json';
    if isfield(part, 'PartNumber') && ~isempty(part.PartNumber)
        defaultName = [part.PartNumber '.json'];
    elseif isfield(part, 'Name') && ~isempty(part.Name)
        defaultName = [part.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Part JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(part, 'PrettyPrint', true);

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
