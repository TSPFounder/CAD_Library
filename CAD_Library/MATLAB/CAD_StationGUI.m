%% CAD_StationGUI.m
% MATLAB GUI for creating and editing CAD_Station objects
%
% Usage:
%   CAD_StationGUI()              - Opens the GUI
%   station = CAD_StationGUI()    - Opens GUI and returns created station
%
% CAD_Station represents design stations (axial, radial, angular, wing)
% used for placing sketch planes and reference locations in CAD models.

function varargout = CAD_StationGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Station Creator', ...
                   'Position', [100 100 500 600], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.station = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [17, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 13), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Station Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Name
    uilabel(gl, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Station name');

    % Row 3: ID
    uilabel(gl, 'Text', 'ID:', 'HorizontalAlignment', 'right');
    idEdit = uieditfield(gl, 'text', 'Value', '', ...
                         'Placeholder', 'e.g., STA-100');

    % Row 4: Version
    uilabel(gl, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(gl, 'text', 'Value', '1.0', ...
                              'Placeholder', 'e.g., 1.0');

    % Row 5: Station Type
    uilabel(gl, 'Text', 'Station Type:', 'HorizontalAlignment', 'right');
    typeDropdown = uidropdown(gl, ...
                              'Items', {'Axial', 'Radial', 'Angular', 'Wing', 'Other'}, ...
                              'Value', 'Axial');

    % Row 6: Locations header
    locHeader = uilabel(gl, 'Text', '── Station Locations ──', ...
                        'HorizontalAlignment', 'center', ...
                        'FontWeight', 'bold', ...
                        'FontColor', [0.3 0.3 0.6]);
    locHeader.Layout.Column = [1 2];

    % Row 7: Axial Location
    uilabel(gl, 'Text', 'Axial Location:', 'HorizontalAlignment', 'right');
    axialPanel = uigridlayout(gl, [1, 2]);
    axialPanel.ColumnWidth = {'1x', 60};
    axialPanel.Padding = [0 0 0 0];
    axialEdit = uieditfield(axialPanel, 'numeric', 'Value', 0);
    uilabel(axialPanel, 'Text', 'mm');

    % Row 8: Radial Location
    uilabel(gl, 'Text', 'Radial Location:', 'HorizontalAlignment', 'right');
    radialPanel = uigridlayout(gl, [1, 2]);
    radialPanel.ColumnWidth = {'1x', 60};
    radialPanel.Padding = [0 0 0 0];
    radialEdit = uieditfield(radialPanel, 'numeric', 'Value', 0);
    uilabel(radialPanel, 'Text', 'mm');

    % Row 9: Angular Location
    uilabel(gl, 'Text', 'Angular Location:', 'HorizontalAlignment', 'right');
    angularPanel = uigridlayout(gl, [1, 2]);
    angularPanel.ColumnWidth = {'1x', 60};
    angularPanel.Padding = [0 0 0 0];
    angularEdit = uieditfield(angularPanel, 'numeric', 'Value', 0);
    uilabel(angularPanel, 'Text', 'deg');

    % Row 10: Wing Location
    uilabel(gl, 'Text', 'Wing Location:', 'HorizontalAlignment', 'right');
    wingPanel = uigridlayout(gl, [1, 2]);
    wingPanel.ColumnWidth = {'1x', 60};
    wingPanel.Padding = [0 0 0 0];
    wingEdit = uieditfield(wingPanel, 'numeric', 'Value', 0);
    uilabel(wingPanel, 'Text', 'mm');

    % Row 11: Floor Location
    uilabel(gl, 'Text', 'Floor Location:', 'HorizontalAlignment', 'right');
    floorPanel = uigridlayout(gl, [1, 2]);
    floorPanel.ColumnWidth = {'1x', 60};
    floorPanel.Padding = [0 0 0 0];
    floorEdit = uieditfield(floorPanel, 'numeric', 'Value', 0);
    uilabel(floorPanel, 'Text', 'mm');

    % Row 12: Sketch Planes header
    planesHeader = uilabel(gl, 'Text', '── Sketch Planes ──', ...
                           'HorizontalAlignment', 'center', ...
                           'FontWeight', 'bold', ...
                           'FontColor', [0.3 0.3 0.6]);
    planesHeader.Layout.Column = [1 2];

    % Row 13: Sketch plane count
    uilabel(gl, 'Text', 'Sketch Planes:', 'HorizontalAlignment', 'right');
    planeCountLabel = uilabel(gl, 'Text', '0 planes defined', ...
                              'FontColor', [0.4 0.4 0.4]);

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

    % Row 16: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 16;
    jsonArea.Layout.Column = [1 2];

    % Row 17: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 17;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.nameEdit = nameEdit;
    ui.idEdit = idEdit;
    ui.versionEdit = versionEdit;
    ui.typeDropdown = typeDropdown;
    ui.axialEdit = axialEdit;
    ui.radialEdit = radialEdit;
    ui.angularEdit = angularEdit;
    ui.wingEdit = wingEdit;
    ui.floorEdit = floorEdit;
    ui.planeCountLabel = planeCountLabel;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createStation(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Auto-update primary location based on type
    typeDropdown.ValueChangedFcn = @(~,~) onTypeChanged(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.station;
            close(fig);
        else
            varargout{1} = [];
        end
    end
end

%% On type changed - highlight the relevant location field
function onTypeChanged(ui)
    % Reset all field backgrounds
    ui.axialEdit.BackgroundColor = [1 1 1];
    ui.radialEdit.BackgroundColor = [1 1 1];
    ui.angularEdit.BackgroundColor = [1 1 1];
    ui.wingEdit.BackgroundColor = [1 1 1];

    % Highlight the primary field
    switch ui.typeDropdown.Value
        case 'Axial'
            ui.axialEdit.BackgroundColor = [0.9 1 0.9];
        case 'Radial'
            ui.radialEdit.BackgroundColor = [0.9 1 0.9];
        case 'Angular'
            ui.angularEdit.BackgroundColor = [0.9 1 0.9];
        case 'Wing'
            ui.wingEdit.BackgroundColor = [0.9 1 0.9];
    end
end

%% Create Station callback
function createStation(ui)
    try
        % Build the station struct
        station = struct();

        % Identification
        station.Name = ui.nameEdit.Value;
        station.ID = ui.idEdit.Value;
        station.Version = ui.versionEdit.Value;

        % Station type
        typeMap = containers.Map(...
            {'Axial', 'Radial', 'Angular', 'Wing', 'Other'}, ...
            {0, 1, 2, 3, 4});
        station.MyType = typeMap(ui.typeDropdown.Value);

        % Locations
        station.AxialLocation = ui.axialEdit.Value;
        station.RadialLocation = ui.radialEdit.Value;
        station.AngularLocation = ui.angularEdit.Value;
        station.WingLocation = ui.wingEdit.Value;
        station.FloorLocation = ui.floorEdit.Value;

        % Empty collections
        station.MySketchPlanes = {};

        % Store in figure UserData
        ui.fig.UserData.station = station;

        % Generate JSON preview
        jsonStr = jsonencode(station, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Station created successfully!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Clear Form callback
function clearForm(ui)
    ui.nameEdit.Value = '';
    ui.idEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.typeDropdown.Value = 'Axial';
    ui.axialEdit.Value = 0;
    ui.radialEdit.Value = 0;
    ui.angularEdit.Value = 0;
    ui.wingEdit.Value = 0;
    ui.floorEdit.Value = 0;
    ui.planeCountLabel.Text = '0 planes defined';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.station = [];
    onTypeChanged(ui);
end

%% Export JSON callback
function exportJSON(ui)
    station = ui.fig.UserData.station;
    if isempty(station)
        ui.statusLabel.Text = 'No station created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(station, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    station = ui.fig.UserData.station;
    if isempty(station)
        ui.statusLabel.Text = 'No station created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Station.json';
    if isfield(station, 'ID') && ~isempty(station.ID)
        defaultName = [station.ID '.json'];
    elseif isfield(station, 'Name') && ~isempty(station.Name)
        defaultName = [station.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Station JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(station, 'PrettyPrint', true);

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
