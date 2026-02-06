%% CAD_StationGUI_Advanced.m
% Advanced MATLAB GUI for managing CAD_Station objects
%
% Usage:
%   CAD_StationGUI_Advanced()              - Opens the GUI
%   stations = CAD_StationGUI_Advanced()   - Opens GUI and returns station list
%
% Features:
%   - Create and manage multiple stations
%   - Quick-add station series (e.g., fuselage stations)
%   - Sketch plane management
%   - Import/Export station collections

function varargout = CAD_StationGUI_Advanced()
    % Create the main figure
    fig = uifigure('Name', 'CAD Station Manager (Advanced)', ...
                   'Position', [50 50 950 750], ...
                   'Resize', 'on');

    % Store data in figure's UserData
    data = struct();
    data.stations = {};
    data.selectedIndex = 0;
    fig.UserData = data;

    % Create main grid layout
    mainGL = uigridlayout(fig, [1, 2]);
    mainGL.ColumnWidth = {'0.35x', '0.65x'};
    mainGL.Padding = [10 10 10 10];

    % Left panel - Station list
    leftPanel = uipanel(mainGL, 'Title', 'Stations');
    leftGL = uigridlayout(leftPanel, [6, 1]);
    leftGL.RowHeight = {'1x', 35, 35, 35, 35, 35};
    leftGL.Padding = [5 5 5 5];

    % Station listbox
    stationListBox = uilistbox(leftGL, 'Items', {});

    % Quick-add buttons by type
    typeBtnPanel = uigridlayout(leftGL, [1, 4]);
    typeBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    typeBtnPanel.Padding = [0 0 0 0];

    axialBtn = uibutton(typeBtnPanel, 'Text', 'Axial', ...
                        'BackgroundColor', [0.6 0.8 0.6]);
    radialBtn = uibutton(typeBtnPanel, 'Text', 'Radial', ...
                         'BackgroundColor', [0.6 0.8 0.8]);
    angularBtn = uibutton(typeBtnPanel, 'Text', 'Angular', ...
                          'BackgroundColor', [0.8 0.8 0.6]);
    wingBtn = uibutton(typeBtnPanel, 'Text', 'Wing', ...
                       'BackgroundColor', [0.8 0.6 0.8]);

    % Management buttons
    mgmtBtnPanel = uigridlayout(leftGL, [1, 3]);
    mgmtBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    mgmtBtnPanel.Padding = [0 0 0 0];

    newBtn = uibutton(mgmtBtnPanel, 'Text', 'New Station', ...
                      'BackgroundColor', [0.3 0.6 0.3]);
    duplicateBtn = uibutton(mgmtBtnPanel, 'Text', 'Duplicate', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    deleteBtn = uibutton(mgmtBtnPanel, 'Text', 'Delete', ...
                         'BackgroundColor', [0.7 0.3 0.3]);

    % Series generator
    seriesPanel = uigridlayout(leftGL, [1, 3]);
    seriesPanel.ColumnWidth = {'1x', '1x', '1x'};
    seriesPanel.Padding = [0 0 0 0];

    seriesStartEdit = uieditfield(seriesPanel, 'numeric', 'Value', 0, ...
                                  'Tooltip', 'Start value');
    seriesEndEdit = uieditfield(seriesPanel, 'numeric', 'Value', 1000, ...
                                'Tooltip', 'End value');
    seriesStepEdit = uieditfield(seriesPanel, 'numeric', 'Value', 100, ...
                                 'Tooltip', 'Step increment');

    % Generate series button
    generateSeriesBtn = uibutton(leftGL, 'Text', 'Generate Station Series', ...
                                 'BackgroundColor', [0.4 0.6 0.8]);

    % Import/Export
    ioBtnPanel = uigridlayout(leftGL, [1, 2]);
    ioBtnPanel.ColumnWidth = {'1x', '1x'};
    ioBtnPanel.Padding = [0 0 0 0];

    importBtn = uibutton(ioBtnPanel, 'Text', 'Import JSON', ...
                         'BackgroundColor', [0.4 0.6 0.8]);
    exportBtn = uibutton(ioBtnPanel, 'Text', 'Export All', ...
                         'BackgroundColor', [0.6 0.4 0.8]);

    % Right panel - Station editor with tabs
    rightPanel = uipanel(mainGL, 'Title', 'Station Editor');
    rightGL = uigridlayout(rightPanel, [2, 1]);
    rightGL.RowHeight = {35, '1x'};
    rightGL.Padding = [5 5 5 5];

    % Status/action bar
    actionPanel = uigridlayout(rightGL, [1, 4]);
    actionPanel.ColumnWidth = {'1x', '1x', '1x', '2x'};
    actionPanel.Padding = [0 0 0 0];

    updateBtn = uibutton(actionPanel, 'Text', 'Update Station', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    saveFileBtn = uibutton(actionPanel, 'Text', 'Save to File', ...
                           'BackgroundColor', [0.5 0.3 0.7]);
    copyJsonBtn = uibutton(actionPanel, 'Text', 'Copy JSON', ...
                           'BackgroundColor', [0.3 0.5 0.7]);
    statusLabel = uilabel(actionPanel, 'Text', 'Ready', ...
                          'FontColor', [0.2 0.2 0.8]);

    % Tab group
    tabGroup = uitabgroup(rightGL);

    % Tab 1: Basic Info
    basicTab = uitab(tabGroup, 'Title', 'Basic Info');
    basicGL = uigridlayout(basicTab, [12, 2]);
    basicGL.RowHeight = repmat({30}, 1, 12);
    basicGL.ColumnWidth = {'0.4x', '0.6x'};
    basicGL.Padding = [10 10 10 10];

    uilabel(basicGL, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(basicGL, 'text', 'Value', '');

    uilabel(basicGL, 'Text', 'ID:', 'HorizontalAlignment', 'right');
    idEdit = uieditfield(basicGL, 'text', 'Value', '');

    uilabel(basicGL, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(basicGL, 'text', 'Value', '1.0');

    uilabel(basicGL, 'Text', 'Station Type:', 'HorizontalAlignment', 'right');
    typeDropdown = uidropdown(basicGL, ...
        'Items', {'Axial', 'Radial', 'Angular', 'Wing', 'Other'}, 'Value', 'Axial');

    % Separator
    locHeader = uilabel(basicGL, 'Text', '── Locations ──', ...
                        'HorizontalAlignment', 'center', ...
                        'FontWeight', 'bold', ...
                        'FontColor', [0.3 0.3 0.6]);
    locHeader.Layout.Column = [1 2];

    uilabel(basicGL, 'Text', 'Axial (X):', 'HorizontalAlignment', 'right');
    axialEdit = uieditfield(basicGL, 'numeric', 'Value', 0);

    uilabel(basicGL, 'Text', 'Radial (R):', 'HorizontalAlignment', 'right');
    radialEdit = uieditfield(basicGL, 'numeric', 'Value', 0);

    uilabel(basicGL, 'Text', 'Angular (Theta):', 'HorizontalAlignment', 'right');
    angularEdit = uieditfield(basicGL, 'numeric', 'Value', 0);

    uilabel(basicGL, 'Text', 'Wing (Y):', 'HorizontalAlignment', 'right');
    wingEdit = uieditfield(basicGL, 'numeric', 'Value', 0);

    uilabel(basicGL, 'Text', 'Floor (Z):', 'HorizontalAlignment', 'right');
    floorEdit = uieditfield(basicGL, 'numeric', 'Value', 0);

    % Summary
    uilabel(basicGL, 'Text', 'Sketch Planes:', 'HorizontalAlignment', 'right');
    planeCountLabel = uilabel(basicGL, 'Text', '0 planes');

    % Tab 2: Sketch Planes
    planesTab = uitab(tabGroup, 'Title', 'Sketch Planes');
    planesGL = uigridlayout(planesTab, [3, 1]);
    planesGL.RowHeight = {'1x', 35, 35};
    planesGL.Padding = [10 10 10 10];

    planeListBox = uilistbox(planesGL, 'Items', {});

    planeBtnPanel = uigridlayout(planesGL, [1, 4]);
    planeBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    planeBtnPanel.Padding = [0 0 0 0];

    addPlaneBtn = uibutton(planeBtnPanel, 'Text', 'Add Plane', ...
                           'BackgroundColor', [0.3 0.6 0.3]);
    editPlaneBtn = uibutton(planeBtnPanel, 'Text', 'Edit', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    removePlaneBtn = uibutton(planeBtnPanel, 'Text', 'Remove', ...
                              'BackgroundColor', [0.7 0.3 0.3]);
    setCurrentBtn = uibutton(planeBtnPanel, 'Text', 'Set Current', ...
                             'BackgroundColor', [0.4 0.6 0.8]);

    currentPlaneLabel = uilabel(planesGL, 'Text', 'No current plane set', ...
                                'HorizontalAlignment', 'center');

    % Tab 3: Visualization
    vizTab = uitab(tabGroup, 'Title', 'Visualization');
    vizGL = uigridlayout(vizTab, [2, 1]);
    vizGL.RowHeight = {'1x', 35};
    vizGL.Padding = [10 10 10 10];

    % Station diagram (placeholder text area)
    vizArea = uitextarea(vizGL, 'Value', '', 'Editable', 'off', ...
                         'FontName', 'Consolas', 'FontSize', 10);

    vizBtnPanel = uigridlayout(vizGL, [1, 2]);
    vizBtnPanel.ColumnWidth = {'1x', '1x'};
    vizBtnPanel.Padding = [0 0 0 0];

    refreshVizBtn = uibutton(vizBtnPanel, 'Text', 'Refresh Diagram', ...
                             'BackgroundColor', [0.4 0.6 0.8]);
    exportVizBtn = uibutton(vizBtnPanel, 'Text', 'Export Diagram', ...
                            'BackgroundColor', [0.6 0.4 0.8]);

    % Tab 4: JSON Preview
    jsonTab = uitab(tabGroup, 'Title', 'JSON');
    jsonGL = uigridlayout(jsonTab, [1, 1]);
    jsonGL.Padding = [10 10 10 10];

    jsonArea = uitextarea(jsonGL, 'Value', '', 'Editable', 'off', ...
                          'FontName', 'Consolas', 'FontSize', 9);

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.stationListBox = stationListBox;
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
    ui.planeListBox = planeListBox;
    ui.currentPlaneLabel = currentPlaneLabel;
    ui.vizArea = vizArea;
    ui.jsonArea = jsonArea;
    ui.statusLabel = statusLabel;
    ui.seriesStartEdit = seriesStartEdit;
    ui.seriesEndEdit = seriesEndEdit;
    ui.seriesStepEdit = seriesStepEdit;

    % Set up callbacks
    stationListBox.ValueChangedFcn = @(~,~) onStationSelected(ui);

    % Type quick-add
    axialBtn.ButtonPushedFcn = @(~,~) quickAddStation(ui, 'Axial');
    radialBtn.ButtonPushedFcn = @(~,~) quickAddStation(ui, 'Radial');
    angularBtn.ButtonPushedFcn = @(~,~) quickAddStation(ui, 'Angular');
    wingBtn.ButtonPushedFcn = @(~,~) quickAddStation(ui, 'Wing');

    % Management
    newBtn.ButtonPushedFcn = @(~,~) addNewStation(ui);
    duplicateBtn.ButtonPushedFcn = @(~,~) duplicateStation(ui);
    deleteBtn.ButtonPushedFcn = @(~,~) deleteStation(ui);

    % Series
    generateSeriesBtn.ButtonPushedFcn = @(~,~) generateStationSeries(ui);

    % Import/Export
    importBtn.ButtonPushedFcn = @(~,~) importStations(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportAllStations(ui);

    % Editor actions
    updateBtn.ButtonPushedFcn = @(~,~) updateCurrentStation(ui);
    saveFileBtn.ButtonPushedFcn = @(~,~) saveStationToFile(ui);
    copyJsonBtn.ButtonPushedFcn = @(~,~) copyStationJson(ui);

    % Sketch planes
    addPlaneBtn.ButtonPushedFcn = @(~,~) addSketchPlane(ui);
    editPlaneBtn.ButtonPushedFcn = @(~,~) editSketchPlane(ui);
    removePlaneBtn.ButtonPushedFcn = @(~,~) removeSketchPlane(ui);
    setCurrentBtn.ButtonPushedFcn = @(~,~) setCurrentPlane(ui);

    % Visualization
    refreshVizBtn.ButtonPushedFcn = @(~,~) refreshVisualization(ui);
    exportVizBtn.ButtonPushedFcn = @(~,~) exportVisualization(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.stations;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Create default station struct
function station = createDefaultStation(stationType)
    station = struct();
    station.Name = '';
    station.ID = '';
    station.Version = '1.0';

    typeMap = containers.Map(...
        {'Axial', 'Radial', 'Angular', 'Wing', 'Other'}, ...
        {0, 1, 2, 3, 4});
    station.MyType = typeMap(stationType);

    station.AxialLocation = 0;
    station.RadialLocation = 0;
    station.AngularLocation = 0;
    station.WingLocation = 0;
    station.FloorLocation = 0;
    station.MySketchPlanes = {};
end

%% Get station type name
function name = getStationTypeName(val)
    types = {'Axial', 'Radial', 'Angular', 'Wing', 'Other'};
    if val >= 0 && val < length(types)
        name = types{val + 1};
    else
        name = 'Other';
    end
end

%% Quick-add station
function quickAddStation(ui, stationType)
    stations = ui.fig.UserData.stations;

    station = createDefaultStation(stationType);
    station.Name = sprintf('%s_Station_%d', stationType, length(stations) + 1);
    station.ID = sprintf('STA-%s-%03d', upper(stationType(1)), length(stations) + 1);

    % Set a default value based on type
    switch stationType
        case 'Axial'
            station.AxialLocation = length(stations) * 100;
        case 'Radial'
            station.RadialLocation = 50 + length(stations) * 10;
        case 'Angular'
            station.AngularLocation = length(stations) * 45;
        case 'Wing'
            station.WingLocation = length(stations) * 500;
    end

    stations{end+1} = station;
    ui.fig.UserData.stations = stations;
    ui.fig.UserData.selectedIndex = length(stations);

    updateStationList(ui);
    loadStationToEditor(ui, station);

    ui.statusLabel.Text = sprintf('%s station added', stationType);
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Add new station
function addNewStation(ui)
    stations = ui.fig.UserData.stations;

    station = createDefaultStation('Axial');
    station.Name = sprintf('Station_%d', length(stations) + 1);
    station.ID = sprintf('STA-%03d', length(stations) + 1);

    stations{end+1} = station;
    ui.fig.UserData.stations = stations;
    ui.fig.UserData.selectedIndex = length(stations);

    updateStationList(ui);
    loadStationToEditor(ui, station);

    ui.statusLabel.Text = 'New station added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Generate station series
function generateStationSeries(ui)
    startVal = ui.seriesStartEdit.Value;
    endVal = ui.seriesEndEdit.Value;
    stepVal = ui.seriesStepEdit.Value;

    if stepVal <= 0
        ui.statusLabel.Text = 'Step must be positive!';
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
        return;
    end

    stationType = ui.typeDropdown.Value;
    stations = ui.fig.UserData.stations;
    count = 0;

    for val = startVal:stepVal:endVal
        station = createDefaultStation(stationType);
        station.Name = sprintf('%s_%.0f', stationType, val);
        station.ID = sprintf('STA-%.0f', val);

        switch stationType
            case 'Axial'
                station.AxialLocation = val;
            case 'Radial'
                station.RadialLocation = val;
            case 'Angular'
                station.AngularLocation = val;
            case 'Wing'
                station.WingLocation = val;
        end

        stations{end+1} = station;
        count = count + 1;
    end

    ui.fig.UserData.stations = stations;
    ui.fig.UserData.selectedIndex = length(stations);

    updateStationList(ui);

    if ~isempty(stations)
        loadStationToEditor(ui, stations{end});
    end

    ui.statusLabel.Text = sprintf('Generated %d stations', count);
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Update station list display
function updateStationList(ui)
    stations = ui.fig.UserData.stations;
    items = cell(1, length(stations));

    for i = 1:length(stations)
        s = stations{i};
        typeName = getStationTypeName(s.MyType);

        % Get primary value
        switch typeName
            case 'Axial'
                val = s.AxialLocation;
            case 'Radial'
                val = s.RadialLocation;
            case 'Angular'
                val = s.AngularLocation;
            case 'Wing'
                val = s.WingLocation;
            otherwise
                val = 0;
        end

        items{i} = sprintf('%d. %s [%s: %.1f]', i, s.ID, typeName(1:3), val);
    end

    ui.stationListBox.Items = items;

    idx = ui.fig.UserData.selectedIndex;
    if idx > 0 && idx <= length(items)
        ui.stationListBox.Value = items{idx};
    end
end

%% On station selected
function onStationSelected(ui)
    if isempty(ui.stationListBox.Value)
        return;
    end

    selStr = ui.stationListBox.Value;
    dotPos = strfind(selStr, '.');
    if ~isempty(dotPos)
        idx = str2double(selStr(1:dotPos(1)-1));
        ui.fig.UserData.selectedIndex = idx;

        stations = ui.fig.UserData.stations;
        if idx > 0 && idx <= length(stations)
            loadStationToEditor(ui, stations{idx});
        end
    end
end

%% Load station to editor
function loadStationToEditor(ui, station)
    ui.nameEdit.Value = station.Name;
    ui.idEdit.Value = station.ID;
    ui.versionEdit.Value = station.Version;
    ui.typeDropdown.Value = getStationTypeName(station.MyType);

    ui.axialEdit.Value = station.AxialLocation;
    ui.radialEdit.Value = station.RadialLocation;
    ui.angularEdit.Value = station.AngularLocation;
    ui.wingEdit.Value = station.WingLocation;
    ui.floorEdit.Value = station.FloorLocation;

    % Plane list
    planeItems = {};
    for i = 1:length(station.MySketchPlanes)
        p = station.MySketchPlanes{i};
        if isfield(p, 'Name')
            planeItems{i} = sprintf('%d. %s', i, p.Name);
        else
            planeItems{i} = sprintf('%d. Plane_%d', i, i);
        end
    end
    ui.planeListBox.Items = planeItems;
    ui.planeCountLabel.Text = sprintf('%d planes', length(planeItems));

    % Refresh visualization
    refreshVisualization(ui);

    % JSON preview
    jsonStr = jsonencode(station, 'PrettyPrint', true);
    ui.jsonArea.Value = jsonStr;
end

%% Update current station
function updateCurrentStation(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'No station selected!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    try
        stations = ui.fig.UserData.stations;
        station = stations{idx};

        station.Name = ui.nameEdit.Value;
        station.ID = ui.idEdit.Value;
        station.Version = ui.versionEdit.Value;

        typeMap = containers.Map(...
            {'Axial', 'Radial', 'Angular', 'Wing', 'Other'}, ...
            {0, 1, 2, 3, 4});
        station.MyType = typeMap(ui.typeDropdown.Value);

        station.AxialLocation = ui.axialEdit.Value;
        station.RadialLocation = ui.radialEdit.Value;
        station.AngularLocation = ui.angularEdit.Value;
        station.WingLocation = ui.wingEdit.Value;
        station.FloorLocation = ui.floorEdit.Value;

        stations{idx} = station;
        ui.fig.UserData.stations = stations;

        updateStationList(ui);
        refreshVisualization(ui);

        jsonStr = jsonencode(station, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        ui.statusLabel.Text = 'Station updated!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Duplicate station
function duplicateStation(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a station first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    stations = ui.fig.UserData.stations;
    newStation = stations{idx};
    newStation.ID = [newStation.ID '-COPY'];
    newStation.Name = [newStation.Name '_copy'];

    stations{end+1} = newStation;
    ui.fig.UserData.stations = stations;
    ui.fig.UserData.selectedIndex = length(stations);

    updateStationList(ui);
    loadStationToEditor(ui, newStation);

    ui.statusLabel.Text = 'Station duplicated';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Delete station
function deleteStation(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a station first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    stations = ui.fig.UserData.stations;
    stations(idx) = [];
    ui.fig.UserData.stations = stations;

    if idx > length(stations)
        idx = length(stations);
    end
    ui.fig.UserData.selectedIndex = idx;

    updateStationList(ui);

    if idx > 0
        loadStationToEditor(ui, stations{idx});
    else
        clearEditor(ui);
    end

    ui.statusLabel.Text = 'Station deleted';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Clear editor
function clearEditor(ui)
    ui.nameEdit.Value = '';
    ui.idEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.typeDropdown.Value = 'Axial';
    ui.axialEdit.Value = 0;
    ui.radialEdit.Value = 0;
    ui.angularEdit.Value = 0;
    ui.wingEdit.Value = 0;
    ui.floorEdit.Value = 0;
    ui.planeListBox.Items = {};
    ui.vizArea.Value = '';
    ui.jsonArea.Value = '';
end

%% Add sketch plane
function addSketchPlane(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a station first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    stations = ui.fig.UserData.stations;
    station = stations{idx};

    plane = struct();
    plane.Name = sprintf('Plane_%d', length(station.MySketchPlanes) + 1);
    plane.GeometryType = 0; % Cartesian

    station.MySketchPlanes{end+1} = plane;
    stations{idx} = station;
    ui.fig.UserData.stations = stations;

    loadStationToEditor(ui, station);

    ui.statusLabel.Text = 'Sketch plane added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit sketch plane (placeholder)
function editSketchPlane(ui)
    ui.statusLabel.Text = 'Plane editing: add plane first, then modify';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove sketch plane
function removeSketchPlane(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    planeSel = ui.planeListBox.Value;
    if isempty(planeSel)
        ui.statusLabel.Text = 'Select a plane first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(planeSel, '.');
    if isempty(dotPos), return; end
    planeIdx = str2double(planeSel(1:dotPos(1)-1));

    stations = ui.fig.UserData.stations;
    station = stations{idx};
    station.MySketchPlanes(planeIdx) = [];
    stations{idx} = station;
    ui.fig.UserData.stations = stations;

    loadStationToEditor(ui, station);

    ui.statusLabel.Text = 'Plane removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Set current plane
function setCurrentPlane(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    planeSel = ui.planeListBox.Value;
    if isempty(planeSel)
        ui.statusLabel.Text = 'Select a plane first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(planeSel, '.');
    if isempty(dotPos), return; end
    planeIdx = str2double(planeSel(1:dotPos(1)-1));

    stations = ui.fig.UserData.stations;
    station = stations{idx};

    if planeIdx > 0 && planeIdx <= length(station.MySketchPlanes)
        plane = station.MySketchPlanes{planeIdx};
        ui.currentPlaneLabel.Text = sprintf('Current: %s', plane.Name);
        ui.statusLabel.Text = 'Current plane set';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];
    end
end

%% Refresh visualization
function refreshVisualization(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.vizArea.Value = '';
        return;
    end

    stations = ui.fig.UserData.stations;
    station = stations{idx};

    lines = {};
    lines{end+1} = '=== Station Visualization ===';
    lines{end+1} = '';
    lines{end+1} = sprintf('ID: %s', station.ID);
    lines{end+1} = sprintf('Name: %s', station.Name);
    lines{end+1} = sprintf('Type: %s', getStationTypeName(station.MyType));
    lines{end+1} = '';
    lines{end+1} = '--- Location Values ---';
    lines{end+1} = sprintf('  Axial (X):    %.3f mm', station.AxialLocation);
    lines{end+1} = sprintf('  Radial (R):   %.3f mm', station.RadialLocation);
    lines{end+1} = sprintf('  Angular:      %.3f deg', station.AngularLocation);
    lines{end+1} = sprintf('  Wing (Y):     %.3f mm', station.WingLocation);
    lines{end+1} = sprintf('  Floor (Z):    %.3f mm', station.FloorLocation);
    lines{end+1} = '';
    lines{end+1} = sprintf('Sketch Planes: %d', length(station.MySketchPlanes));

    ui.vizArea.Value = lines;
end

%% Export visualization
function exportVisualization(ui)
    ui.statusLabel.Text = 'Visualization export not yet implemented';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Import stations
function importStations(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files'}, 'Import Stations');
    if filename == 0, return; end

    try
        jsonStr = fileread(fullfile(pathname, filename));
        imported = jsondecode(jsonStr);

        if isfield(imported, 'Stations')
            for i = 1:length(imported.Stations)
                stations = ui.fig.UserData.stations;
                stations{end+1} = imported.Stations(i);
                ui.fig.UserData.stations = stations;
            end
        else
            stations = ui.fig.UserData.stations;
            stations{end+1} = imported;
            ui.fig.UserData.stations = stations;
        end

        updateStationList(ui);
        ui.statusLabel.Text = 'Stations imported!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Import error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Export all stations
function exportAllStations(ui)
    stations = ui.fig.UserData.stations;
    if isempty(stations)
        ui.statusLabel.Text = 'No stations to export!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Export All Stations', 'CAD_Stations.json');
    if filename == 0, return; end

    try
        collection = struct();
        collection.ExportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        collection.StationCount = length(stations);
        collection.Stations = stations;

        jsonStr = jsonencode(collection, 'PrettyPrint', true);
        fid = fopen(fullfile(pathname, filename), 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = sprintf('Exported %d stations!', length(stations));
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Export error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Save station to file
function saveStationToFile(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a station first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    stations = ui.fig.UserData.stations;
    station = stations{idx};

    defaultName = [station.ID '.json'];

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Save Station', defaultName);
    if filename == 0, return; end

    try
        jsonStr = jsonencode(station, 'PrettyPrint', true);
        fid = fopen(fullfile(pathname, filename), 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = ['Saved: ' filename];
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Save error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Copy station JSON
function copyStationJson(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a station first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    stations = ui.fig.UserData.stations;
    station = stations{idx};

    jsonStr = jsonencode(station, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end
