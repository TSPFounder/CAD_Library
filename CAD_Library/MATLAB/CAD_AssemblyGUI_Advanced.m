%% CAD_AssemblyGUI_Advanced.m
% Advanced MATLAB GUI for managing CAD_Assembly objects with components
%
% Usage:
%   CAD_AssemblyGUI_Advanced()              - Opens the GUI
%   assemblies = CAD_AssemblyGUI_Advanced() - Opens GUI and returns assembly list
%
% Features:
%   - Create and manage multiple assemblies
%   - Add/remove components to assemblies
%   - Manage configurations and interfaces
%   - Import/Export assembly collections
%   - Hierarchical assembly view

function varargout = CAD_AssemblyGUI_Advanced()
    % Create the main figure
    fig = uifigure('Name', 'CAD Assembly Manager (Advanced)', ...
                   'Position', [50 50 1000 800], ...
                   'Resize', 'on');

    % Store data in figure's UserData
    data = struct();
    data.assemblies = {};
    data.selectedAssemblyIndex = 0;
    fig.UserData = data;

    % Create main grid layout
    mainGL = uigridlayout(fig, [1, 2]);
    mainGL.ColumnWidth = {'0.30x', '0.70x'};
    mainGL.Padding = [10 10 10 10];

    % Left panel - Assembly list
    leftPanel = uipanel(mainGL, 'Title', 'Assemblies');
    leftGL = uigridlayout(leftPanel, [5, 1]);
    leftGL.RowHeight = {'1x', 35, 35, 35, 35};
    leftGL.Padding = [5 5 5 5];

    % Assembly tree/listbox
    assemblyListBox = uilistbox(leftGL, 'Items', {});

    % Quick-add button row
    quickBtnPanel = uigridlayout(leftGL, [1, 3]);
    quickBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    quickBtnPanel.Padding = [0 0 0 0];

    newAssemblyBtn = uibutton(quickBtnPanel, 'Text', 'New Assembly', ...
                              'BackgroundColor', [0.3 0.6 0.3]);
    newSubAsmBtn = uibutton(quickBtnPanel, 'Text', 'New Sub-Asm', ...
                            'BackgroundColor', [0.4 0.6 0.4]);
    deleteBtn = uibutton(quickBtnPanel, 'Text', 'Delete', ...
                         'BackgroundColor', [0.7 0.3 0.3]);

    % Component management
    compBtnPanel = uigridlayout(leftGL, [1, 2]);
    compBtnPanel.ColumnWidth = {'1x', '1x'};
    compBtnPanel.Padding = [0 0 0 0];

    addCompBtn = uibutton(compBtnPanel, 'Text', 'Add Component', ...
                          'BackgroundColor', [0.5 0.6 0.8]);
    addPartBtn = uibutton(compBtnPanel, 'Text', 'Add Part', ...
                          'BackgroundColor', [0.5 0.6 0.8]);

    % Import/Export buttons
    ioBtnPanel = uigridlayout(leftGL, [1, 2]);
    ioBtnPanel.ColumnWidth = {'1x', '1x'};
    ioBtnPanel.Padding = [0 0 0 0];

    importBtn = uibutton(ioBtnPanel, 'Text', 'Import JSON', ...
                         'BackgroundColor', [0.4 0.6 0.8]);
    exportBtn = uibutton(ioBtnPanel, 'Text', 'Export All', ...
                         'BackgroundColor', [0.6 0.4 0.8]);

    % BOM button
    bomBtn = uibutton(leftGL, 'Text', 'Generate Bill of Materials', ...
                      'BackgroundColor', [0.8 0.6 0.4]);

    % Right panel - Assembly editor with tabs
    rightPanel = uipanel(mainGL, 'Title', 'Assembly Editor');
    rightGL = uigridlayout(rightPanel, [2, 1]);
    rightGL.RowHeight = {35, '1x'};
    rightGL.Padding = [5 5 5 5];

    % Status/action bar
    actionPanel = uigridlayout(rightGL, [1, 4]);
    actionPanel.ColumnWidth = {'1x', '1x', '1x', '2x'};
    actionPanel.Padding = [0 0 0 0];

    updateBtn = uibutton(actionPanel, 'Text', 'Update Assembly', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    saveFileBtn = uibutton(actionPanel, 'Text', 'Save to File', ...
                           'BackgroundColor', [0.5 0.3 0.7]);
    copyJsonBtn = uibutton(actionPanel, 'Text', 'Copy JSON', ...
                           'BackgroundColor', [0.3 0.5 0.7]);
    statusLabel = uilabel(actionPanel, 'Text', 'Ready', ...
                          'FontColor', [0.2 0.2 0.8]);

    % Tab group for different assembly aspects
    tabGroup = uitabgroup(rightGL);

    % Tab 1: Basic Info
    basicTab = uitab(tabGroup, 'Title', 'Basic Info');
    basicGL = uigridlayout(basicTab, [10, 2]);
    basicGL.RowHeight = repmat({30}, 1, 10);
    basicGL.ColumnWidth = {'0.35x', '0.65x'};
    basicGL.Padding = [10 10 10 10];

    uilabel(basicGL, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(basicGL, 'text', 'Value', '', 'Placeholder', 'Assembly name');

    uilabel(basicGL, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(basicGL, 'text', 'Value', '1.0');

    uilabel(basicGL, 'Text', 'Description:', 'HorizontalAlignment', 'right');
    descEdit = uieditfield(basicGL, 'text', 'Value', '', 'Placeholder', 'Assembly description');

    uilabel(basicGL, 'Text', 'Is Sub-Assembly:', 'HorizontalAlignment', 'right');
    isSubAsmCheck = uicheckbox(basicGL, 'Text', '', 'Value', false);

    uilabel(basicGL, 'Text', 'Is Config Item:', 'HorizontalAlignment', 'right');
    isConfigItemCheck = uicheckbox(basicGL, 'Text', '', 'Value', false);

    uilabel(basicGL, 'Text', 'Position:', 'HorizontalAlignment', 'right');
    positionEdit = uieditfield(basicGL, 'text', 'Value', '0, 0, 0', 'Placeholder', 'X, Y, Z');

    uilabel(basicGL, 'Text', 'Orientation:', 'HorizontalAlignment', 'right');
    orientationEdit = uieditfield(basicGL, 'text', 'Value', '0, 0, 0', 'Placeholder', 'Roll, Pitch, Yaw');

    % Summary labels
    uilabel(basicGL, 'Text', 'Components:', 'HorizontalAlignment', 'right');
    componentCountLabel = uilabel(basicGL, 'Text', '0 components');

    uilabel(basicGL, 'Text', 'Configurations:', 'HorizontalAlignment', 'right');
    configCountLabel = uilabel(basicGL, 'Text', '0 configurations');

    uilabel(basicGL, 'Text', 'Interfaces:', 'HorizontalAlignment', 'right');
    interfaceCountLabel = uilabel(basicGL, 'Text', '0 interfaces');

    % Tab 2: Components
    componentsTab = uitab(tabGroup, 'Title', 'Components');
    componentsGL = uigridlayout(componentsTab, [3, 1]);
    componentsGL.RowHeight = {'1x', 35, 35};
    componentsGL.Padding = [10 10 10 10];

    componentListBox = uilistbox(componentsGL, 'Items', {});

    compBtnPanel2 = uigridlayout(componentsGL, [1, 4]);
    compBtnPanel2.ColumnWidth = {'1x', '1x', '1x', '1x'};
    compBtnPanel2.Padding = [0 0 0 0];

    addCompBtn2 = uibutton(compBtnPanel2, 'Text', 'Add Component', ...
                           'BackgroundColor', [0.3 0.6 0.3]);
    editCompBtn = uibutton(compBtnPanel2, 'Text', 'Edit', ...
                           'BackgroundColor', [0.5 0.5 0.7]);
    removeCompBtn = uibutton(compBtnPanel2, 'Text', 'Remove', ...
                             'BackgroundColor', [0.7 0.3 0.3]);
    compGuiBtn = uibutton(compBtnPanel2, 'Text', 'Open Component GUI', ...
                          'BackgroundColor', [0.4 0.6 0.8]);

    compSummaryLabel = uilabel(componentsGL, 'Text', 'Select a component to view details', ...
                               'HorizontalAlignment', 'center');

    % Tab 3: Configurations
    configTab = uitab(tabGroup, 'Title', 'Configurations');
    configGL = uigridlayout(configTab, [3, 1]);
    configGL.RowHeight = {'1x', 35, 35};
    configGL.Padding = [10 10 10 10];

    configListBox = uilistbox(configGL, 'Items', {});

    configBtnPanel = uigridlayout(configGL, [1, 3]);
    configBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    configBtnPanel.Padding = [0 0 0 0];

    addConfigBtn = uibutton(configBtnPanel, 'Text', 'Add Configuration', ...
                            'BackgroundColor', [0.3 0.6 0.3]);
    editConfigBtn = uibutton(configBtnPanel, 'Text', 'Edit', ...
                             'BackgroundColor', [0.5 0.5 0.7]);
    removeConfigBtn = uibutton(configBtnPanel, 'Text', 'Remove', ...
                               'BackgroundColor', [0.7 0.3 0.3]);

    activeConfigLabel = uilabel(configGL, 'Text', 'No active configuration', ...
                                'HorizontalAlignment', 'center');

    % Tab 4: Interfaces
    interfacesTab = uitab(tabGroup, 'Title', 'Interfaces');
    interfacesGL = uigridlayout(interfacesTab, [3, 1]);
    interfacesGL.RowHeight = {'1x', 35, 35};
    interfacesGL.Padding = [10 10 10 10];

    interfaceListBox = uilistbox(interfacesGL, 'Items', {});

    intfBtnPanel = uigridlayout(interfacesGL, [1, 3]);
    intfBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    intfBtnPanel.Padding = [0 0 0 0];

    addInterfaceBtn = uibutton(intfBtnPanel, 'Text', 'Add Interface', ...
                               'BackgroundColor', [0.3 0.6 0.3]);
    editInterfaceBtn = uibutton(intfBtnPanel, 'Text', 'Edit', ...
                                'BackgroundColor', [0.5 0.5 0.7]);
    removeInterfaceBtn = uibutton(intfBtnPanel, 'Text', 'Remove', ...
                                  'BackgroundColor', [0.7 0.3 0.3]);

    interfaceSummaryLabel = uilabel(interfacesGL, 'Text', 'Define component interfaces', ...
                                    'HorizontalAlignment', 'center');

    % Tab 5: Stations
    stationsTab = uitab(tabGroup, 'Title', 'Stations');
    stationsGL = uigridlayout(stationsTab, [5, 2]);
    stationsGL.RowHeight = [30, 30, 30, 30, '1x'];
    stationsGL.ColumnWidth = {'0.4x', '0.6x'};
    stationsGL.Padding = [10 10 10 10];

    uilabel(stationsGL, 'Text', 'Axial Stations:', 'HorizontalAlignment', 'right');
    axialEdit = uieditfield(stationsGL, 'text', 'Value', '', ...
                            'Placeholder', 'Comma-separated values');

    uilabel(stationsGL, 'Text', 'Radial Stations:', 'HorizontalAlignment', 'right');
    radialEdit = uieditfield(stationsGL, 'text', 'Value', '', ...
                             'Placeholder', 'Comma-separated values');

    uilabel(stationsGL, 'Text', 'Angular Stations:', 'HorizontalAlignment', 'right');
    angularEdit = uieditfield(stationsGL, 'text', 'Value', '', ...
                              'Placeholder', 'Comma-separated (degrees)');

    uilabel(stationsGL, 'Text', 'Wing Stations:', 'HorizontalAlignment', 'right');
    wingEdit = uieditfield(stationsGL, 'text', 'Value', '', ...
                           'Placeholder', 'Comma-separated values');

    stationPreview = uitextarea(stationsGL, 'Value', '', 'Editable', 'off', ...
                                'FontName', 'Consolas', 'FontSize', 9);
    stationPreview.Layout.Column = [1 2];

    % Tab 6: JSON Preview
    jsonTab = uitab(tabGroup, 'Title', 'JSON');
    jsonGL = uigridlayout(jsonTab, [1, 1]);
    jsonGL.Padding = [10 10 10 10];

    jsonArea = uitextarea(jsonGL, 'Value', '', 'Editable', 'off', ...
                          'FontName', 'Consolas', 'FontSize', 9);

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.assemblyListBox = assemblyListBox;
    ui.nameEdit = nameEdit;
    ui.versionEdit = versionEdit;
    ui.descEdit = descEdit;
    ui.isSubAsmCheck = isSubAsmCheck;
    ui.isConfigItemCheck = isConfigItemCheck;
    ui.positionEdit = positionEdit;
    ui.orientationEdit = orientationEdit;
    ui.componentCountLabel = componentCountLabel;
    ui.configCountLabel = configCountLabel;
    ui.interfaceCountLabel = interfaceCountLabel;
    ui.componentListBox = componentListBox;
    ui.compSummaryLabel = compSummaryLabel;
    ui.configListBox = configListBox;
    ui.activeConfigLabel = activeConfigLabel;
    ui.interfaceListBox = interfaceListBox;
    ui.interfaceSummaryLabel = interfaceSummaryLabel;
    ui.axialEdit = axialEdit;
    ui.radialEdit = radialEdit;
    ui.angularEdit = angularEdit;
    ui.wingEdit = wingEdit;
    ui.stationPreview = stationPreview;
    ui.jsonArea = jsonArea;
    ui.statusLabel = statusLabel;

    % Set up callbacks
    assemblyListBox.ValueChangedFcn = @(~,~) onAssemblySelected(ui);

    % Assembly management
    newAssemblyBtn.ButtonPushedFcn = @(~,~) addNewAssembly(ui, false);
    newSubAsmBtn.ButtonPushedFcn = @(~,~) addNewAssembly(ui, true);
    deleteBtn.ButtonPushedFcn = @(~,~) deleteAssembly(ui);

    % Component management
    addCompBtn.ButtonPushedFcn = @(~,~) addComponentToAssembly(ui);
    addPartBtn.ButtonPushedFcn = @(~,~) addPartAsComponent(ui);
    addCompBtn2.ButtonPushedFcn = @(~,~) addComponentToAssembly(ui);
    editCompBtn.ButtonPushedFcn = @(~,~) editSelectedComponent(ui);
    removeCompBtn.ButtonPushedFcn = @(~,~) removeSelectedComponent(ui);
    compGuiBtn.ButtonPushedFcn = @(~,~) openComponentGUI(ui);

    % Configuration management
    addConfigBtn.ButtonPushedFcn = @(~,~) addConfiguration(ui);
    editConfigBtn.ButtonPushedFcn = @(~,~) editConfiguration(ui);
    removeConfigBtn.ButtonPushedFcn = @(~,~) removeConfiguration(ui);

    % Interface management
    addInterfaceBtn.ButtonPushedFcn = @(~,~) addInterface(ui);
    editInterfaceBtn.ButtonPushedFcn = @(~,~) editInterface(ui);
    removeInterfaceBtn.ButtonPushedFcn = @(~,~) removeInterface(ui);

    % Import/Export
    importBtn.ButtonPushedFcn = @(~,~) importAssemblies(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportAllAssemblies(ui);
    bomBtn.ButtonPushedFcn = @(~,~) generateBOM(ui);

    % Editor actions
    updateBtn.ButtonPushedFcn = @(~,~) updateCurrentAssembly(ui);
    saveFileBtn.ButtonPushedFcn = @(~,~) saveAssemblyToFile(ui);
    copyJsonBtn.ButtonPushedFcn = @(~,~) copyAssemblyJson(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.assemblies;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Create default assembly struct
function assembly = createDefaultAssembly(isSubAssembly)
    assembly = struct();
    assembly.Name = '';
    assembly.Version = '1.0';
    assembly.Description = '';
    assembly.IsSubAssembly = isSubAssembly;
    assembly.IsConfigurationItem = false;
    assembly.MyPosition = struct('X_Value', 0, 'Y_Value', 0, 'Z_Value_Cartesian', 0);
    assembly.MyOrientation = struct('X', 0, 'Y', 0, 'Z', 0);
    assembly.MyComponents = {};
    assembly.MyConfigurations = {};
    assembly.MissionRequirements = {};
    assembly.SystemRequirements = {};
    assembly.MyInterfaces = {};
    assembly.MyCoordinateSystems = {};
    assembly.AxialStations = {};
    assembly.RadialStations = {};
    assembly.AngularStations = {};
    assembly.WingStations = {};
end

%% Add new assembly
function addNewAssembly(ui, isSubAssembly)
    assemblies = ui.fig.UserData.assemblies;

    assembly = createDefaultAssembly(isSubAssembly);
    if isSubAssembly
        assembly.Name = sprintf('SubAssembly_%d', length(assemblies) + 1);
    else
        assembly.Name = sprintf('Assembly_%d', length(assemblies) + 1);
    end

    assemblies{end+1} = assembly;
    ui.fig.UserData.assemblies = assemblies;
    ui.fig.UserData.selectedAssemblyIndex = length(assemblies);

    updateAssemblyList(ui);
    loadAssemblyToEditor(ui, assembly);

    ui.statusLabel.Text = 'New assembly added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Update assembly list display
function updateAssemblyList(ui)
    assemblies = ui.fig.UserData.assemblies;
    items = cell(1, length(assemblies));

    for i = 1:length(assemblies)
        a = assemblies{i};
        prefix = '';
        if a.IsSubAssembly
            prefix = '[SUB] ';
        end
        items{i} = sprintf('%d. %s%s (%d comp)', i, prefix, a.Name, length(a.MyComponents));
    end

    ui.assemblyListBox.Items = items;

    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx > 0 && idx <= length(items)
        ui.assemblyListBox.Value = items{idx};
    end
end

%% On assembly selected from list
function onAssemblySelected(ui)
    if isempty(ui.assemblyListBox.Value)
        return;
    end

    selStr = ui.assemblyListBox.Value;
    dotPos = strfind(selStr, '.');
    if ~isempty(dotPos)
        idx = str2double(selStr(1:dotPos(1)-1));
        ui.fig.UserData.selectedAssemblyIndex = idx;

        assemblies = ui.fig.UserData.assemblies;
        if idx > 0 && idx <= length(assemblies)
            loadAssemblyToEditor(ui, assemblies{idx});
        end
    end
end

%% Load assembly to editor
function loadAssemblyToEditor(ui, assembly)
    % Basic info
    ui.nameEdit.Value = assembly.Name;
    ui.versionEdit.Value = assembly.Version;
    ui.descEdit.Value = assembly.Description;
    ui.isSubAsmCheck.Value = assembly.IsSubAssembly;
    ui.isConfigItemCheck.Value = assembly.IsConfigurationItem;

    % Position and orientation
    if isfield(assembly, 'MyPosition')
        pos = assembly.MyPosition;
        ui.positionEdit.Value = sprintf('%.3f, %.3f, %.3f', ...
            pos.X_Value, pos.Y_Value, pos.Z_Value_Cartesian);
    end

    if isfield(assembly, 'MyOrientation')
        ori = assembly.MyOrientation;
        ui.orientationEdit.Value = sprintf('%.3f, %.3f, %.3f', ori.X, ori.Y, ori.Z);
    end

    % Update counts
    ui.componentCountLabel.Text = sprintf('%d components', length(assembly.MyComponents));
    ui.configCountLabel.Text = sprintf('%d configurations', length(assembly.MyConfigurations));
    ui.interfaceCountLabel.Text = sprintf('%d interfaces', length(assembly.MyInterfaces));

    % Component list
    compItems = {};
    for i = 1:length(assembly.MyComponents)
        c = assembly.MyComponents{i};
        if isfield(c, 'Name')
            compItems{i} = sprintf('%d. %s', i, c.Name);
        else
            compItems{i} = sprintf('%d. Component_%d', i, i);
        end
    end
    ui.componentListBox.Items = compItems;

    % Configuration list
    configItems = {};
    for i = 1:length(assembly.MyConfigurations)
        cfg = assembly.MyConfigurations{i};
        if isfield(cfg, 'Name')
            configItems{i} = sprintf('%d. %s', i, cfg.Name);
        else
            configItems{i} = sprintf('%d. Config_%d', i, i);
        end
    end
    ui.configListBox.Items = configItems;

    % Interface list
    intfItems = {};
    for i = 1:length(assembly.MyInterfaces)
        intf = assembly.MyInterfaces{i};
        if isfield(intf, 'Name')
            intfItems{i} = sprintf('%d. %s', i, intf.Name);
        else
            intfItems{i} = sprintf('%d. Interface_%d', i, i);
        end
    end
    ui.interfaceListBox.Items = intfItems;

    % Stations
    ui.axialEdit.Value = stationsToString(assembly.AxialStations);
    ui.radialEdit.Value = stationsToString(assembly.RadialStations);
    ui.angularEdit.Value = stationsToString(assembly.AngularStations);
    ui.wingEdit.Value = stationsToString(assembly.WingStations);

    % Update station preview
    updateStationPreview(ui, assembly);

    % JSON preview
    jsonStr = jsonencode(assembly, 'PrettyPrint', true);
    ui.jsonArea.Value = jsonStr;
end

%% Convert stations array to comma-separated string
function str = stationsToString(stations)
    if isempty(stations)
        str = '';
        return;
    end

    values = [];
    for i = 1:length(stations)
        if isfield(stations{i}, 'Value')
            values(end+1) = stations{i}.Value;
        end
    end

    str = strjoin(arrayfun(@num2str, values, 'UniformOutput', false), ', ');
end

%% Update station preview
function updateStationPreview(ui, assembly)
    lines = {};
    lines{end+1} = 'Station Summary:';
    lines{end+1} = sprintf('  Axial: %d stations', length(assembly.AxialStations));
    lines{end+1} = sprintf('  Radial: %d stations', length(assembly.RadialStations));
    lines{end+1} = sprintf('  Angular: %d stations', length(assembly.AngularStations));
    lines{end+1} = sprintf('  Wing: %d stations', length(assembly.WingStations));

    ui.stationPreview.Value = lines;
end

%% Parse comma-separated values to stations
function stations = parseStations(str, stationType)
    stations = {};
    if isempty(str)
        return;
    end

    parts = strsplit(str, ',');
    typeNames = {'Axial', 'Radial', 'Angular', 'Wing'};

    for i = 1:length(parts)
        val = str2double(strtrim(parts{i}));
        if ~isnan(val)
            station = struct();
            station.StationType = stationType;
            station.Value = val;
            station.Name = sprintf('%s_Station_%d', typeNames{stationType+1}, i);
            stations{end+1} = station;
        end
    end
end

%% Parse point string
function point = parsePoint(str)
    point = struct('X_Value', 0, 'Y_Value', 0, 'Z_Value_Cartesian', 0);
    if isempty(str), return; end

    parts = strsplit(str, ',');
    if length(parts) >= 1, point.X_Value = str2double(strtrim(parts{1})); end
    if length(parts) >= 2, point.Y_Value = str2double(strtrim(parts{2})); end
    if length(parts) >= 3, point.Z_Value_Cartesian = str2double(strtrim(parts{3})); end

    if isnan(point.X_Value), point.X_Value = 0; end
    if isnan(point.Y_Value), point.Y_Value = 0; end
    if isnan(point.Z_Value_Cartesian), point.Z_Value_Cartesian = 0; end
end

%% Parse vector string
function vec = parseVector(str)
    vec = struct('X', 0, 'Y', 0, 'Z', 0);
    if isempty(str), return; end

    parts = strsplit(str, ',');
    if length(parts) >= 1, vec.X = str2double(strtrim(parts{1})); end
    if length(parts) >= 2, vec.Y = str2double(strtrim(parts{2})); end
    if length(parts) >= 3, vec.Z = str2double(strtrim(parts{3})); end

    if isnan(vec.X), vec.X = 0; end
    if isnan(vec.Y), vec.Y = 0; end
    if isnan(vec.Z), vec.Z = 0; end
end

%% Update current assembly from editor
function updateCurrentAssembly(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        ui.statusLabel.Text = 'No assembly selected!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    try
        assemblies = ui.fig.UserData.assemblies;
        assembly = assemblies{idx};

        % Update basic info
        assembly.Name = ui.nameEdit.Value;
        assembly.Version = ui.versionEdit.Value;
        assembly.Description = ui.descEdit.Value;
        assembly.IsSubAssembly = ui.isSubAsmCheck.Value;
        assembly.IsConfigurationItem = ui.isConfigItemCheck.Value;

        % Position and orientation
        assembly.MyPosition = parsePoint(ui.positionEdit.Value);
        assembly.MyOrientation = parseVector(ui.orientationEdit.Value);

        % Stations
        assembly.AxialStations = parseStations(ui.axialEdit.Value, 0);
        assembly.RadialStations = parseStations(ui.radialEdit.Value, 1);
        assembly.AngularStations = parseStations(ui.angularEdit.Value, 2);
        assembly.WingStations = parseStations(ui.wingEdit.Value, 3);

        % Save back
        assemblies{idx} = assembly;
        ui.fig.UserData.assemblies = assemblies;

        updateAssemblyList(ui);
        updateStationPreview(ui, assembly);

        % Update JSON
        jsonStr = jsonencode(assembly, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        ui.statusLabel.Text = 'Assembly updated!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Delete assembly
function deleteAssembly(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select an assembly first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    assemblies = ui.fig.UserData.assemblies;
    assemblies(idx) = [];
    ui.fig.UserData.assemblies = assemblies;

    if idx > length(assemblies)
        idx = length(assemblies);
    end
    ui.fig.UserData.selectedAssemblyIndex = idx;

    updateAssemblyList(ui);

    if idx > 0
        loadAssemblyToEditor(ui, assemblies{idx});
    else
        clearEditor(ui);
    end

    ui.statusLabel.Text = 'Assembly deleted';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Clear editor
function clearEditor(ui)
    ui.nameEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.descEdit.Value = '';
    ui.isSubAsmCheck.Value = false;
    ui.isConfigItemCheck.Value = false;
    ui.positionEdit.Value = '0, 0, 0';
    ui.orientationEdit.Value = '0, 0, 0';
    ui.componentListBox.Items = {};
    ui.configListBox.Items = {};
    ui.interfaceListBox.Items = {};
    ui.axialEdit.Value = '';
    ui.radialEdit.Value = '';
    ui.angularEdit.Value = '';
    ui.wingEdit.Value = '';
    ui.jsonArea.Value = '';
end

%% Add component to assembly
function addComponentToAssembly(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select an assembly first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    assemblies = ui.fig.UserData.assemblies;
    assembly = assemblies{idx};

    % Create new component
    comp = struct();
    comp.Name = sprintf('Component_%d', length(assembly.MyComponents) + 1);
    comp.Version = '1.0';
    comp.IsAssembly = false;
    comp.IsConfigurationItem = false;
    comp.WBS_Level = 1;
    comp.MySketches = {};
    comp.MyJoints = {};
    comp.MomentsOfInertia = {};
    comp.PrincipleDirections = {};

    assembly.MyComponents{end+1} = comp;
    assemblies{idx} = assembly;
    ui.fig.UserData.assemblies = assemblies;

    loadAssemblyToEditor(ui, assembly);

    ui.statusLabel.Text = 'Component added to assembly';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Add part as component
function addPartAsComponent(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select an assembly first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Try to import a part file
    [filename, pathname] = uigetfile({'*.json', 'JSON Files'}, 'Select Part JSON');
    if filename == 0
        return;
    end

    try
        jsonStr = fileread(fullfile(pathname, filename));
        part = jsondecode(jsonStr);

        assemblies = ui.fig.UserData.assemblies;
        assembly = assemblies{idx};

        % Create component from part
        comp = struct();
        if isfield(part, 'Name')
            comp.Name = part.Name;
        else
            comp.Name = sprintf('Component_%d', length(assembly.MyComponents) + 1);
        end
        comp.Version = '1.0';
        comp.IsAssembly = false;
        comp.MyPart = part;
        comp.MySketches = {};
        comp.MyJoints = {};

        assembly.MyComponents{end+1} = comp;
        assemblies{idx} = assembly;
        ui.fig.UserData.assemblies = assemblies;

        loadAssemblyToEditor(ui, assembly);

        ui.statusLabel.Text = 'Part added as component';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error loading part: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Edit selected component (placeholder)
function editSelectedComponent(ui)
    ui.statusLabel.Text = 'Use Component GUI to edit components';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove selected component
function removeSelectedComponent(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        return;
    end

    compSel = ui.componentListBox.Value;
    if isempty(compSel)
        ui.statusLabel.Text = 'Select a component first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(compSel, '.');
    if isempty(dotPos), return; end
    compIdx = str2double(compSel(1:dotPos(1)-1));

    assemblies = ui.fig.UserData.assemblies;
    assembly = assemblies{idx};
    assembly.MyComponents(compIdx) = [];
    assemblies{idx} = assembly;
    ui.fig.UserData.assemblies = assemblies;

    loadAssemblyToEditor(ui, assembly);

    ui.statusLabel.Text = 'Component removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Open Component GUI
function openComponentGUI(ui)
    try
        CAD_ComponentGUI_Advanced();
        ui.statusLabel.Text = 'Component GUI opened';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];
    catch
        ui.statusLabel.Text = 'Could not open Component GUI';
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Add configuration
function addConfiguration(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select an assembly first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    assemblies = ui.fig.UserData.assemblies;
    assembly = assemblies{idx};

    config = struct();
    config.Name = sprintf('Configuration_%d', length(assembly.MyConfigurations) + 1);
    config.Description = '';
    config.IsActive = false;

    assembly.MyConfigurations{end+1} = config;
    assemblies{idx} = assembly;
    ui.fig.UserData.assemblies = assemblies;

    loadAssemblyToEditor(ui, assembly);

    ui.statusLabel.Text = 'Configuration added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit configuration (placeholder)
function editConfiguration(ui)
    ui.statusLabel.Text = 'Configuration editing not yet implemented';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove configuration
function removeConfiguration(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1, return; end

    configSel = ui.configListBox.Value;
    if isempty(configSel)
        ui.statusLabel.Text = 'Select a configuration first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(configSel, '.');
    if isempty(dotPos), return; end
    configIdx = str2double(configSel(1:dotPos(1)-1));

    assemblies = ui.fig.UserData.assemblies;
    assembly = assemblies{idx};
    assembly.MyConfigurations(configIdx) = [];
    assemblies{idx} = assembly;
    ui.fig.UserData.assemblies = assemblies;

    loadAssemblyToEditor(ui, assembly);

    ui.statusLabel.Text = 'Configuration removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Add interface
function addInterface(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select an assembly first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    assemblies = ui.fig.UserData.assemblies;
    assembly = assemblies{idx};

    intf = struct();
    intf.Name = sprintf('Interface_%d', length(assembly.MyInterfaces) + 1);
    intf.InterfaceType = 0; % Joint
    intf.Description = '';

    assembly.MyInterfaces{end+1} = intf;
    assemblies{idx} = assembly;
    ui.fig.UserData.assemblies = assemblies;

    loadAssemblyToEditor(ui, assembly);

    ui.statusLabel.Text = 'Interface added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit interface (placeholder)
function editInterface(ui)
    ui.statusLabel.Text = 'Interface editing not yet implemented';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove interface
function removeInterface(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1, return; end

    intfSel = ui.interfaceListBox.Value;
    if isempty(intfSel)
        ui.statusLabel.Text = 'Select an interface first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(intfSel, '.');
    if isempty(dotPos), return; end
    intfIdx = str2double(intfSel(1:dotPos(1)-1));

    assemblies = ui.fig.UserData.assemblies;
    assembly = assemblies{idx};
    assembly.MyInterfaces(intfIdx) = [];
    assemblies{idx} = assembly;
    ui.fig.UserData.assemblies = assemblies;

    loadAssemblyToEditor(ui, assembly);

    ui.statusLabel.Text = 'Interface removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Import assemblies from JSON
function importAssemblies(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files'}, 'Import Assemblies');
    if filename == 0, return; end

    try
        jsonStr = fileread(fullfile(pathname, filename));
        imported = jsondecode(jsonStr);

        if isfield(imported, 'Assemblies')
            for i = 1:length(imported.Assemblies)
                assemblies = ui.fig.UserData.assemblies;
                assemblies{end+1} = imported.Assemblies(i);
                ui.fig.UserData.assemblies = assemblies;
            end
        else
            assemblies = ui.fig.UserData.assemblies;
            assemblies{end+1} = imported;
            ui.fig.UserData.assemblies = assemblies;
        end

        updateAssemblyList(ui);
        ui.statusLabel.Text = 'Assemblies imported!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Import error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Export all assemblies
function exportAllAssemblies(ui)
    assemblies = ui.fig.UserData.assemblies;
    if isempty(assemblies)
        ui.statusLabel.Text = 'No assemblies to export!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Export All Assemblies', 'CAD_Assemblies.json');
    if filename == 0, return; end

    try
        collection = struct();
        collection.ExportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        collection.AssemblyCount = length(assemblies);
        collection.Assemblies = assemblies;

        jsonStr = jsonencode(collection, 'PrettyPrint', true);

        fid = fopen(fullfile(pathname, filename), 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = sprintf('Exported %d assemblies!', length(assemblies));
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Export error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Save single assembly to file
function saveAssemblyToFile(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select an assembly first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    assemblies = ui.fig.UserData.assemblies;
    assembly = assemblies{idx};

    defaultName = 'CAD_Assembly.json';
    if ~isempty(assembly.Name)
        defaultName = [assembly.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Save Assembly', defaultName);
    if filename == 0, return; end

    try
        jsonStr = jsonencode(assembly, 'PrettyPrint', true);
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

%% Copy assembly JSON to clipboard
function copyAssemblyJson(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select an assembly first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    assemblies = ui.fig.UserData.assemblies;
    assembly = assemblies{idx};

    jsonStr = jsonencode(assembly, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Generate Bill of Materials
function generateBOM(ui)
    idx = ui.fig.UserData.selectedAssemblyIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select an assembly first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    assemblies = ui.fig.UserData.assemblies;
    assembly = assemblies{idx};

    if isempty(assembly.MyComponents)
        ui.statusLabel.Text = 'Assembly has no components!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.csv', 'CSV Files'; '*.json', 'JSON Files'}, ...
                                      'Save Bill of Materials', 'BOM.csv');
    if filename == 0, return; end

    try
        filePath = fullfile(pathname, filename);

        if endsWith(filename, '.json')
            % JSON BOM
            bom = struct();
            bom.AssemblyName = assembly.Name;
            bom.GeneratedDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
            bom.Items = {};

            for i = 1:length(assembly.MyComponents)
                comp = assembly.MyComponents{i};
                item = struct();
                item.ItemNumber = i;
                item.Name = comp.Name;
                if isfield(comp, 'PartNumber')
                    item.PartNumber = comp.PartNumber;
                else
                    item.PartNumber = '';
                end
                item.Quantity = 1;
                bom.Items{i} = item;
            end

            jsonStr = jsonencode(bom, 'PrettyPrint', true);
            fid = fopen(filePath, 'w');
            fprintf(fid, '%s', jsonStr);
            fclose(fid);
        else
            % CSV BOM
            fid = fopen(filePath, 'w');
            fprintf(fid, 'Item,Name,Part Number,Quantity\n');

            for i = 1:length(assembly.MyComponents)
                comp = assembly.MyComponents{i};
                pn = '';
                if isfield(comp, 'PartNumber')
                    pn = comp.PartNumber;
                end
                fprintf(fid, '%d,%s,%s,1\n', i, comp.Name, pn);
            end

            fclose(fid);
        end

        ui.statusLabel.Text = ['BOM saved: ' filename];
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['BOM error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end
