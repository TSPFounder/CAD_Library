%% CAD_InterfaceGUI_Advanced.m
% Advanced MATLAB GUI for managing multiple CAD_Interface objects
%
% Usage:
%   CAD_InterfaceGUI_Advanced()           - Opens the GUI
%   interfaces = CAD_InterfaceGUI_Advanced() - Opens GUI and returns interfaces
%
% Features:
%   - Create and manage multiple interfaces
%   - Templates for common interface types
%   - Contact point and surface management
%   - Component association tracking
%   - Import/Export JSON collections

function varargout = CAD_InterfaceGUI_Advanced()
    % Create the main figure
    fig = uifigure('Name', 'CAD Interface Manager - Advanced', ...
                   'Position', [50 50 900 700], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.interfaces = {};
    data.currentIndex = 0;
    data.contactPoints = {};
    data.contactSurfaces = {};
    fig.UserData = data;

    % Create main grid layout
    mainGrid = uigridlayout(fig, [1, 2]);
    mainGrid.ColumnWidth = {'0.35x', '0.65x'};
    mainGrid.Padding = [10 10 10 10];

    % Left panel - Interface list
    leftPanel = uigridlayout(mainGrid, [6, 1]);
    leftPanel.RowHeight = {30, '1x', 30, 30, 30, 30};
    leftPanel.Padding = [5 5 5 5];

    uilabel(leftPanel, 'Text', 'Interfaces', ...
            'FontSize', 14, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');

    interfaceList = uilistbox(leftPanel, 'Items', {}, ...
                              'FontName', 'Consolas');

    % Template buttons
    templatePanel = uigridlayout(leftPanel, [1, 3]);
    templatePanel.ColumnWidth = {'1x', '1x', '1x'};
    templatePanel.Padding = [0 0 0 0];
    jointBtn = uibutton(templatePanel, 'Text', 'Joint', ...
                        'BackgroundColor', [0.6 0.8 0.6]);
    elecBtn = uibutton(templatePanel, 'Text', 'Electrical', ...
                       'BackgroundColor', [0.6 0.7 0.9]);
    otherBtn = uibutton(templatePanel, 'Text', 'Other', ...
                        'BackgroundColor', [0.9 0.8 0.6]);

    % List management buttons
    listBtnPanel = uigridlayout(leftPanel, [1, 3]);
    listBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    listBtnPanel.Padding = [0 0 0 0];
    addBtn = uibutton(listBtnPanel, 'Text', 'Add New', ...
                      'BackgroundColor', [0.3 0.6 0.3]);
    dupBtn = uibutton(listBtnPanel, 'Text', 'Duplicate', ...
                      'BackgroundColor', [0.5 0.5 0.7]);
    delBtn = uibutton(listBtnPanel, 'Text', 'Delete', ...
                      'BackgroundColor', [0.7 0.3 0.3]);

    % Import/Export buttons
    ioBtnPanel = uigridlayout(leftPanel, [1, 2]);
    ioBtnPanel.ColumnWidth = {'1x', '1x'};
    ioBtnPanel.Padding = [0 0 0 0];
    importBtn = uibutton(ioBtnPanel, 'Text', 'Import JSON', ...
                         'BackgroundColor', [0.4 0.6 0.8]);
    exportBtn = uibutton(ioBtnPanel, 'Text', 'Export All', ...
                         'BackgroundColor', [0.6 0.4 0.8]);

    % Status
    listStatusLabel = uilabel(leftPanel, 'Text', '0 interfaces', ...
                              'HorizontalAlignment', 'center', ...
                              'FontColor', [0.4 0.4 0.4]);

    % Right panel - Tabbed interface details
    rightPanel = uigridlayout(mainGrid, [3, 1]);
    rightPanel.RowHeight = {30, '1x', 35};
    rightPanel.Padding = [5 5 5 5];

    uilabel(rightPanel, 'Text', 'Interface Details', ...
            'FontSize', 14, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');

    % Create tab group
    tabGroup = uitabgroup(rightPanel);

    % Tab 1: Basic Info
    basicTab = uitab(tabGroup, 'Title', 'Basic Info');
    basicGrid = uigridlayout(basicTab, [9, 2]);
    basicGrid.RowHeight = [28, 28, 28, 28, 28, 28, 28, 28, '1x'];
    basicGrid.ColumnWidth = {'0.35x', '0.65x'};
    basicGrid.Padding = [10 10 10 10];

    uilabel(basicGrid, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(basicGrid, 'text', 'Value', '', ...
                           'Placeholder', 'Interface name');

    uilabel(basicGrid, 'Text', 'ID:', 'HorizontalAlignment', 'right');
    idEdit = uieditfield(basicGrid, 'text', 'Value', '', ...
                         'Placeholder', 'e.g., IF-001');

    uilabel(basicGrid, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(basicGrid, 'text', 'Value', '1.0');

    uilabel(basicGrid, 'Text', 'Interface Type:', 'HorizontalAlignment', 'right');
    typeDropdown = uidropdown(basicGrid, ...
                              'Items', {'Joint', 'ElectricalConnector', 'Other'}, ...
                              'Value', 'Joint');

    % Separator
    sepLabel = uilabel(basicGrid, 'Text', '── Component Associations ──', ...
                       'HorizontalAlignment', 'center', ...
                       'FontWeight', 'bold', 'FontColor', [0.3 0.3 0.6]);
    sepLabel.Layout.Column = [1 2];

    uilabel(basicGrid, 'Text', 'Base Component:', 'HorizontalAlignment', 'right');
    baseCompEdit = uieditfield(basicGrid, 'text', 'Value', '', ...
                               'Placeholder', 'Component name or ID');

    uilabel(basicGrid, 'Text', 'Mating Component:', 'HorizontalAlignment', 'right');
    matingCompEdit = uieditfield(basicGrid, 'text', 'Value', '', ...
                                 'Placeholder', 'Component name or ID');

    uilabel(basicGrid, 'Text', 'Joint Reference:', 'HorizontalAlignment', 'right');
    jointRefEdit = uieditfield(basicGrid, 'text', 'Value', '', ...
                               'Placeholder', 'Joint name or ID');

    % Tab 2: Contact Points
    pointsTab = uitab(tabGroup, 'Title', 'Contact Points');
    pointsGrid = uigridlayout(pointsTab, [5, 1]);
    pointsGrid.RowHeight = {30, '1x', 30, 80, 30};
    pointsGrid.Padding = [10 10 10 10];

    uilabel(pointsGrid, 'Text', 'Contact Points List', ...
            'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    pointsList = uilistbox(pointsGrid, 'Items', {}, ...
                           'FontName', 'Consolas');

    % Point input panel
    pointInputPanel = uigridlayout(pointsGrid, [1, 7]);
    pointInputPanel.ColumnWidth = {40, '1x', 40, '1x', 40, '1x', 80};
    pointInputPanel.Padding = [0 0 0 0];
    uilabel(pointInputPanel, 'Text', 'X:', 'HorizontalAlignment', 'right');
    ptXEdit = uieditfield(pointInputPanel, 'numeric', 'Value', 0);
    uilabel(pointInputPanel, 'Text', 'Y:', 'HorizontalAlignment', 'right');
    ptYEdit = uieditfield(pointInputPanel, 'numeric', 'Value', 0);
    uilabel(pointInputPanel, 'Text', 'Z:', 'HorizontalAlignment', 'right');
    ptZEdit = uieditfield(pointInputPanel, 'numeric', 'Value', 0);
    addPtBtn = uibutton(pointInputPanel, 'Text', 'Add Point', ...
                        'BackgroundColor', [0.3 0.6 0.3]);

    % Current contact point info
    currPtPanel = uigridlayout(pointsGrid, [2, 2]);
    currPtPanel.RowHeight = {25, 25};
    currPtPanel.ColumnWidth = {'0.4x', '0.6x'};
    currPtPanel.Padding = [5 5 5 5];
    uilabel(currPtPanel, 'Text', 'Current Contact Point:', ...
            'FontWeight', 'bold');
    currPtLabel = uilabel(currPtPanel, 'Text', 'Not set', ...
                          'FontColor', [0.4 0.4 0.4]);
    setCurrentPtBtn = uibutton(currPtPanel, 'Text', 'Set Selected as Current', ...
                               'BackgroundColor', [0.5 0.7 0.5]);
    delPtBtn = uibutton(currPtPanel, 'Text', 'Delete Selected', ...
                        'BackgroundColor', [0.7 0.4 0.4]);

    % Point count
    pointCountLabel = uilabel(pointsGrid, 'Text', '0 contact points', ...
                              'HorizontalAlignment', 'center', ...
                              'FontColor', [0.4 0.4 0.4]);

    % Tab 3: Contact Surfaces
    surfacesTab = uitab(tabGroup, 'Title', 'Contact Surfaces');
    surfacesGrid = uigridlayout(surfacesTab, [5, 1]);
    surfacesGrid.RowHeight = {30, '1x', 30, 60, 30};
    surfacesGrid.Padding = [10 10 10 10];

    uilabel(surfacesGrid, 'Text', 'Contact Surfaces List', ...
            'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    surfacesList = uilistbox(surfacesGrid, 'Items', {}, ...
                             'FontName', 'Consolas');

    % Surface input panel
    surfInputPanel = uigridlayout(surfacesGrid, [1, 4]);
    surfInputPanel.ColumnWidth = {80, '1x', 80, 80};
    surfInputPanel.Padding = [0 0 0 0];
    uilabel(surfInputPanel, 'Text', 'Surface Name:', 'HorizontalAlignment', 'right');
    surfNameEdit = uieditfield(surfInputPanel, 'text', 'Value', '', ...
                               'Placeholder', 'e.g., Face1');
    surfTypeDropdown = uidropdown(surfInputPanel, ...
                                  'Items', {'Planar', 'Cylindrical', 'Spherical', 'Conical', 'Freeform'}, ...
                                  'Value', 'Planar');
    addSurfBtn = uibutton(surfInputPanel, 'Text', 'Add Surface', ...
                          'BackgroundColor', [0.3 0.6 0.3]);

    % Current surface info
    currSurfPanel = uigridlayout(surfacesGrid, [1, 3]);
    currSurfPanel.ColumnWidth = {'0.5x', '0.25x', '0.25x'};
    currSurfPanel.Padding = [5 5 5 5];
    currSurfLabel = uilabel(currSurfPanel, 'Text', 'Current Surface: Not set', ...
                            'FontColor', [0.4 0.4 0.4]);
    setCurrentSurfBtn = uibutton(currSurfPanel, 'Text', 'Set Current', ...
                                 'BackgroundColor', [0.5 0.7 0.5]);
    delSurfBtn = uibutton(currSurfPanel, 'Text', 'Delete', ...
                          'BackgroundColor', [0.7 0.4 0.4]);

    % Surface count
    surfaceCountLabel = uilabel(surfacesGrid, 'Text', '0 contact surfaces', ...
                                'HorizontalAlignment', 'center', ...
                                'FontColor', [0.4 0.4 0.4]);

    % Tab 4: JSON Preview
    jsonTab = uitab(tabGroup, 'Title', 'JSON Preview');
    jsonGrid = uigridlayout(jsonTab, [2, 1]);
    jsonGrid.RowHeight = {30, '1x'};
    jsonGrid.Padding = [10 10 10 10];

    jsonBtnPanel = uigridlayout(jsonGrid, [1, 2]);
    jsonBtnPanel.ColumnWidth = {'1x', '1x'};
    jsonBtnPanel.Padding = [0 0 0 0];
    refreshJsonBtn = uibutton(jsonBtnPanel, 'Text', 'Refresh Preview', ...
                              'BackgroundColor', [0.5 0.7 0.5]);
    copyJsonBtn = uibutton(jsonBtnPanel, 'Text', 'Copy to Clipboard', ...
                           'BackgroundColor', [0.3 0.5 0.7]);

    jsonArea = uitextarea(jsonGrid, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);

    % Bottom buttons
    bottomPanel = uigridlayout(rightPanel, [1, 3]);
    bottomPanel.ColumnWidth = {'1x', '1x', '1x'};
    bottomPanel.Padding = [0 0 0 0];
    applyBtn = uibutton(bottomPanel, 'Text', 'Apply Changes', ...
                        'BackgroundColor', [0.3 0.6 0.3]);
    revertBtn = uibutton(bottomPanel, 'Text', 'Revert', ...
                         'BackgroundColor', [0.8 0.6 0.2]);
    closeBtn = uibutton(bottomPanel, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.interfaceList = interfaceList;
    ui.listStatusLabel = listStatusLabel;
    ui.nameEdit = nameEdit;
    ui.idEdit = idEdit;
    ui.versionEdit = versionEdit;
    ui.typeDropdown = typeDropdown;
    ui.baseCompEdit = baseCompEdit;
    ui.matingCompEdit = matingCompEdit;
    ui.jointRefEdit = jointRefEdit;
    ui.pointsList = pointsList;
    ui.ptXEdit = ptXEdit;
    ui.ptYEdit = ptYEdit;
    ui.ptZEdit = ptZEdit;
    ui.currPtLabel = currPtLabel;
    ui.pointCountLabel = pointCountLabel;
    ui.surfacesList = surfacesList;
    ui.surfNameEdit = surfNameEdit;
    ui.surfTypeDropdown = surfTypeDropdown;
    ui.currSurfLabel = currSurfLabel;
    ui.surfaceCountLabel = surfaceCountLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    interfaceList.ValueChangedFcn = @(~,~) onInterfaceSelected(ui);
    jointBtn.ButtonPushedFcn = @(~,~) addTemplateInterface(ui, 'Joint');
    elecBtn.ButtonPushedFcn = @(~,~) addTemplateInterface(ui, 'Electrical');
    otherBtn.ButtonPushedFcn = @(~,~) addTemplateInterface(ui, 'Other');
    addBtn.ButtonPushedFcn = @(~,~) addNewInterface(ui);
    dupBtn.ButtonPushedFcn = @(~,~) duplicateInterface(ui);
    delBtn.ButtonPushedFcn = @(~,~) deleteInterface(ui);
    importBtn.ButtonPushedFcn = @(~,~) importInterfaces(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportInterfaces(ui);
    addPtBtn.ButtonPushedFcn = @(~,~) addContactPoint(ui);
    setCurrentPtBtn.ButtonPushedFcn = @(~,~) setCurrentPoint(ui);
    delPtBtn.ButtonPushedFcn = @(~,~) deletePoint(ui);
    addSurfBtn.ButtonPushedFcn = @(~,~) addContactSurface(ui);
    setCurrentSurfBtn.ButtonPushedFcn = @(~,~) setCurrentSurface(ui);
    delSurfBtn.ButtonPushedFcn = @(~,~) deleteSurface(ui);
    refreshJsonBtn.ButtonPushedFcn = @(~,~) refreshJsonPreview(ui);
    copyJsonBtn.ButtonPushedFcn = @(~,~) copyJsonToClipboard(ui);
    applyBtn.ButtonPushedFcn = @(~,~) applyChanges(ui);
    revertBtn.ButtonPushedFcn = @(~,~) revertChanges(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.interfaces;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Template interface creation
function addTemplateInterface(ui, templateType)
    data = ui.fig.UserData;
    newIdx = length(data.interfaces) + 1;

    iface = struct();
    switch templateType
        case 'Joint'
            iface.Name = sprintf('Joint Interface %d', newIdx);
            iface.ID = sprintf('IF-J%03d', newIdx);
            iface.InterfaceKind = 0; % Joint
            iface.MyContactPoints = {};
            iface.MyContactSurfaces = {};
        case 'Electrical'
            iface.Name = sprintf('Electrical Connector %d', newIdx);
            iface.ID = sprintf('IF-E%03d', newIdx);
            iface.InterfaceKind = 1; % ElectricalConnector
            iface.MyContactPoints = {};
            iface.MyContactSurfaces = {};
        case 'Other'
            iface.Name = sprintf('Interface %d', newIdx);
            iface.ID = sprintf('IF-%03d', newIdx);
            iface.InterfaceKind = 2; % Other
            iface.MyContactPoints = {};
            iface.MyContactSurfaces = {};
    end
    iface.Version = '1.0';

    data.interfaces{end+1} = iface;
    data.currentIndex = length(data.interfaces);
    ui.fig.UserData = data;

    updateInterfaceList(ui);
    loadInterfaceToForm(ui, data.currentIndex);
end

%% Add new blank interface
function addNewInterface(ui)
    data = ui.fig.UserData;
    newIdx = length(data.interfaces) + 1;

    iface = struct();
    iface.Name = sprintf('Interface %d', newIdx);
    iface.ID = sprintf('IF-%03d', newIdx);
    iface.Version = '1.0';
    iface.InterfaceKind = 0;
    iface.MyContactPoints = {};
    iface.MyContactSurfaces = {};

    data.interfaces{end+1} = iface;
    data.currentIndex = length(data.interfaces);
    ui.fig.UserData = data;

    updateInterfaceList(ui);
    loadInterfaceToForm(ui, data.currentIndex);
end

%% Duplicate selected interface
function duplicateInterface(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0 || isempty(data.interfaces)
        return;
    end

    original = data.interfaces{data.currentIndex};
    newIface = original;
    newIface.Name = [original.Name ' (Copy)'];
    newIface.ID = [original.ID '-COPY'];

    data.interfaces{end+1} = newIface;
    data.currentIndex = length(data.interfaces);
    ui.fig.UserData = data;

    updateInterfaceList(ui);
    loadInterfaceToForm(ui, data.currentIndex);
end

%% Delete selected interface
function deleteInterface(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0 || isempty(data.interfaces)
        return;
    end

    data.interfaces(data.currentIndex) = [];
    if data.currentIndex > length(data.interfaces)
        data.currentIndex = length(data.interfaces);
    end
    ui.fig.UserData = data;

    updateInterfaceList(ui);
    if data.currentIndex > 0
        loadInterfaceToForm(ui, data.currentIndex);
    else
        clearForm(ui);
    end
end

%% Update interface list display
function updateInterfaceList(ui)
    data = ui.fig.UserData;
    items = {};
    for i = 1:length(data.interfaces)
        iface = data.interfaces{i};
        typeName = getTypeName(iface.InterfaceKind);
        items{end+1} = sprintf('%s (%s)', iface.Name, typeName);
    end
    ui.interfaceList.Items = items;
    if data.currentIndex > 0 && data.currentIndex <= length(items)
        ui.interfaceList.Value = items{data.currentIndex};
    end
    ui.listStatusLabel.Text = sprintf('%d interfaces', length(data.interfaces));
end

%% Get type name from enum value
function name = getTypeName(typeVal)
    if isempty(typeVal)
        name = 'Unknown';
        return;
    end
    types = {'Joint', 'ElectricalConnector', 'Other'};
    if typeVal >= 0 && typeVal < length(types)
        name = types{typeVal + 1};
    else
        name = 'Unknown';
    end
end

%% On interface selection changed
function onInterfaceSelected(ui)
    data = ui.fig.UserData;
    selectedValue = ui.interfaceList.Value;
    if isempty(selectedValue)
        return;
    end

    % Find index
    items = ui.interfaceList.Items;
    idx = find(strcmp(items, selectedValue), 1);
    if ~isempty(idx)
        data.currentIndex = idx;
        ui.fig.UserData = data;
        loadInterfaceToForm(ui, idx);
    end
end

%% Load interface data to form
function loadInterfaceToForm(ui, idx)
    data = ui.fig.UserData;
    if idx < 1 || idx > length(data.interfaces)
        return;
    end

    iface = data.interfaces{idx};

    % Basic info
    ui.nameEdit.Value = getFieldOrDefault(iface, 'Name', '');
    ui.idEdit.Value = getFieldOrDefault(iface, 'ID', '');
    ui.versionEdit.Value = getFieldOrDefault(iface, 'Version', '1.0');

    % Type
    typeVal = getFieldOrDefault(iface, 'InterfaceKind', 0);
    types = {'Joint', 'ElectricalConnector', 'Other'};
    if typeVal >= 0 && typeVal < length(types)
        ui.typeDropdown.Value = types{typeVal + 1};
    end

    % Component associations
    if isfield(iface, 'BaseComponent') && ~isempty(iface.BaseComponent)
        ui.baseCompEdit.Value = getFieldOrDefault(iface.BaseComponent, 'Name', '');
    else
        ui.baseCompEdit.Value = '';
    end
    if isfield(iface, 'MatingComponent') && ~isempty(iface.MatingComponent)
        ui.matingCompEdit.Value = getFieldOrDefault(iface.MatingComponent, 'Name', '');
    else
        ui.matingCompEdit.Value = '';
    end
    if isfield(iface, 'MyJoint') && ~isempty(iface.MyJoint)
        ui.jointRefEdit.Value = getFieldOrDefault(iface.MyJoint, 'Name', '');
    else
        ui.jointRefEdit.Value = '';
    end

    % Contact points
    updatePointsList(ui, iface);

    % Contact surfaces
    updateSurfacesList(ui, iface);

    % JSON preview
    refreshJsonPreview(ui);
end

%% Update points list
function updatePointsList(ui, iface)
    items = {};
    if isfield(iface, 'MyContactPoints') && ~isempty(iface.MyContactPoints)
        for i = 1:length(iface.MyContactPoints)
            pt = iface.MyContactPoints{i};
            items{end+1} = sprintf('Point %d: (%.2f, %.2f, %.2f)', i, ...
                getFieldOrDefault(pt, 'X', 0), ...
                getFieldOrDefault(pt, 'Y', 0), ...
                getFieldOrDefault(pt, 'Z', 0));
        end
    end
    ui.pointsList.Items = items;
    ui.pointCountLabel.Text = sprintf('%d contact points', length(items));

    % Current point
    if isfield(iface, 'CurrentContactPoint') && ~isempty(iface.CurrentContactPoint)
        pt = iface.CurrentContactPoint;
        ui.currPtLabel.Text = sprintf('(%.2f, %.2f, %.2f)', ...
            getFieldOrDefault(pt, 'X', 0), ...
            getFieldOrDefault(pt, 'Y', 0), ...
            getFieldOrDefault(pt, 'Z', 0));
    else
        ui.currPtLabel.Text = 'Not set';
    end
end

%% Update surfaces list
function updateSurfacesList(ui, iface)
    items = {};
    if isfield(iface, 'MyContactSurfaces') && ~isempty(iface.MyContactSurfaces)
        for i = 1:length(iface.MyContactSurfaces)
            surf = iface.MyContactSurfaces{i};
            items{end+1} = sprintf('%s (%s)', ...
                getFieldOrDefault(surf, 'Name', 'Unnamed'), ...
                getFieldOrDefault(surf, 'SurfaceType', 'Unknown'));
        end
    end
    ui.surfacesList.Items = items;
    ui.surfaceCountLabel.Text = sprintf('%d contact surfaces', length(items));

    % Current surface
    if isfield(iface, 'CurrentContactSurface') && ~isempty(iface.CurrentContactSurface)
        surf = iface.CurrentContactSurface;
        ui.currSurfLabel.Text = sprintf('Current: %s', ...
            getFieldOrDefault(surf, 'Name', 'Unnamed'));
    else
        ui.currSurfLabel.Text = 'Current Surface: Not set';
    end
end

%% Add contact point
function addContactPoint(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0
        return;
    end

    pt = struct();
    pt.X = ui.ptXEdit.Value;
    pt.Y = ui.ptYEdit.Value;
    pt.Z = ui.ptZEdit.Value;

    iface = data.interfaces{data.currentIndex};
    if ~isfield(iface, 'MyContactPoints') || isempty(iface.MyContactPoints)
        iface.MyContactPoints = {};
    end
    iface.MyContactPoints{end+1} = pt;

    % Set as current if first point
    if length(iface.MyContactPoints) == 1
        iface.CurrentContactPoint = pt;
    end

    data.interfaces{data.currentIndex} = iface;
    ui.fig.UserData = data;

    updatePointsList(ui, iface);
    refreshJsonPreview(ui);
end

%% Set current contact point
function setCurrentPoint(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0
        return;
    end

    selectedValue = ui.pointsList.Value;
    if isempty(selectedValue)
        return;
    end

    items = ui.pointsList.Items;
    idx = find(strcmp(items, selectedValue), 1);

    iface = data.interfaces{data.currentIndex};
    if idx <= length(iface.MyContactPoints)
        iface.CurrentContactPoint = iface.MyContactPoints{idx};
        data.interfaces{data.currentIndex} = iface;
        ui.fig.UserData = data;
        updatePointsList(ui, iface);
        refreshJsonPreview(ui);
    end
end

%% Delete contact point
function deletePoint(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0
        return;
    end

    selectedValue = ui.pointsList.Value;
    if isempty(selectedValue)
        return;
    end

    items = ui.pointsList.Items;
    idx = find(strcmp(items, selectedValue), 1);

    iface = data.interfaces{data.currentIndex};
    if idx <= length(iface.MyContactPoints)
        iface.MyContactPoints(idx) = [];
        data.interfaces{data.currentIndex} = iface;
        ui.fig.UserData = data;
        updatePointsList(ui, iface);
        refreshJsonPreview(ui);
    end
end

%% Add contact surface
function addContactSurface(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0
        return;
    end

    surf = struct();
    surf.Name = ui.surfNameEdit.Value;
    if isempty(surf.Name)
        surf.Name = sprintf('Surface%d', length(data.interfaces{data.currentIndex}.MyContactSurfaces) + 1);
    end
    surf.SurfaceType = ui.surfTypeDropdown.Value;

    iface = data.interfaces{data.currentIndex};
    if ~isfield(iface, 'MyContactSurfaces') || isempty(iface.MyContactSurfaces)
        iface.MyContactSurfaces = {};
    end
    iface.MyContactSurfaces{end+1} = surf;

    % Set as current if first surface
    if length(iface.MyContactSurfaces) == 1
        iface.CurrentContactSurface = surf;
    end

    data.interfaces{data.currentIndex} = iface;
    ui.fig.UserData = data;

    updateSurfacesList(ui, iface);
    refreshJsonPreview(ui);
end

%% Set current surface
function setCurrentSurface(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0
        return;
    end

    selectedValue = ui.surfacesList.Value;
    if isempty(selectedValue)
        return;
    end

    items = ui.surfacesList.Items;
    idx = find(strcmp(items, selectedValue), 1);

    iface = data.interfaces{data.currentIndex};
    if idx <= length(iface.MyContactSurfaces)
        iface.CurrentContactSurface = iface.MyContactSurfaces{idx};
        data.interfaces{data.currentIndex} = iface;
        ui.fig.UserData = data;
        updateSurfacesList(ui, iface);
        refreshJsonPreview(ui);
    end
end

%% Delete surface
function deleteSurface(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0
        return;
    end

    selectedValue = ui.surfacesList.Value;
    if isempty(selectedValue)
        return;
    end

    items = ui.surfacesList.Items;
    idx = find(strcmp(items, selectedValue), 1);

    iface = data.interfaces{data.currentIndex};
    if idx <= length(iface.MyContactSurfaces)
        iface.MyContactSurfaces(idx) = [];
        data.interfaces{data.currentIndex} = iface;
        ui.fig.UserData = data;
        updateSurfacesList(ui, iface);
        refreshJsonPreview(ui);
    end
end

%% Refresh JSON preview
function refreshJsonPreview(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0 || isempty(data.interfaces)
        ui.jsonArea.Value = '';
        return;
    end

    iface = data.interfaces{data.currentIndex};
    jsonStr = jsonencode(iface, 'PrettyPrint', true);
    ui.jsonArea.Value = jsonStr;
end

%% Copy JSON to clipboard
function copyJsonToClipboard(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0 || isempty(data.interfaces)
        return;
    end

    iface = data.interfaces{data.currentIndex};
    jsonStr = jsonencode(iface, 'PrettyPrint', true);
    clipboard('copy', jsonStr);
end

%% Apply changes from form to data
function applyChanges(ui)
    data = ui.fig.UserData;
    if data.currentIndex == 0
        return;
    end

    iface = data.interfaces{data.currentIndex};

    % Basic info
    iface.Name = ui.nameEdit.Value;
    iface.ID = ui.idEdit.Value;
    iface.Version = ui.versionEdit.Value;

    % Type
    typeMap = containers.Map(...
        {'Joint', 'ElectricalConnector', 'Other'}, ...
        {0, 1, 2});
    iface.InterfaceKind = typeMap(ui.typeDropdown.Value);

    % Component associations
    if ~isempty(ui.baseCompEdit.Value)
        iface.BaseComponent = struct('Name', ui.baseCompEdit.Value);
    else
        iface.BaseComponent = [];
    end
    if ~isempty(ui.matingCompEdit.Value)
        iface.MatingComponent = struct('Name', ui.matingCompEdit.Value);
    else
        iface.MatingComponent = [];
    end
    if ~isempty(ui.jointRefEdit.Value)
        iface.MyJoint = struct('Name', ui.jointRefEdit.Value);
    else
        iface.MyJoint = [];
    end

    data.interfaces{data.currentIndex} = iface;
    ui.fig.UserData = data;

    updateInterfaceList(ui);
    refreshJsonPreview(ui);
end

%% Revert changes
function revertChanges(ui)
    data = ui.fig.UserData;
    if data.currentIndex > 0 && data.currentIndex <= length(data.interfaces)
        loadInterfaceToForm(ui, data.currentIndex);
    end
end

%% Clear form
function clearForm(ui)
    ui.nameEdit.Value = '';
    ui.idEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.typeDropdown.Value = 'Joint';
    ui.baseCompEdit.Value = '';
    ui.matingCompEdit.Value = '';
    ui.jointRefEdit.Value = '';
    ui.pointsList.Items = {};
    ui.currPtLabel.Text = 'Not set';
    ui.pointCountLabel.Text = '0 contact points';
    ui.surfacesList.Items = {};
    ui.currSurfLabel.Text = 'Current Surface: Not set';
    ui.surfaceCountLabel.Text = '0 contact surfaces';
    ui.jsonArea.Value = '';
end

%% Import interfaces from JSON
function importInterfaces(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Import Interfaces');
    if filename == 0
        return;
    end

    filePath = fullfile(pathname, filename);
    fid = fopen(filePath, 'r');
    if fid == -1
        return;
    end

    jsonStr = fread(fid, '*char')';
    fclose(fid);

    try
        imported = jsondecode(jsonStr);
        data = ui.fig.UserData;

        if iscell(imported)
            for i = 1:length(imported)
                data.interfaces{end+1} = imported{i};
            end
        elseif isstruct(imported)
            if isfield(imported, 'interfaces')
                for i = 1:length(imported.interfaces)
                    data.interfaces{end+1} = imported.interfaces(i);
                end
            else
                data.interfaces{end+1} = imported;
            end
        end

        if ~isempty(data.interfaces)
            data.currentIndex = length(data.interfaces);
        end
        ui.fig.UserData = data;

        updateInterfaceList(ui);
        if data.currentIndex > 0
            loadInterfaceToForm(ui, data.currentIndex);
        end
    catch
        % Import failed
    end
end

%% Export all interfaces to JSON
function exportInterfaces(ui)
    data = ui.fig.UserData;
    if isempty(data.interfaces)
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Export Interfaces', 'CAD_Interfaces.json');
    if filename == 0
        return;
    end

    filePath = fullfile(pathname, filename);
    exportData = struct();
    exportData.interfaces = data.interfaces;
    exportData.exportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    exportData.count = length(data.interfaces);

    jsonStr = jsonencode(exportData, 'PrettyPrint', true);

    fid = fopen(filePath, 'w');
    if fid ~= -1
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
    end
end

%% Helper function to get field or default value
function val = getFieldOrDefault(s, fieldName, defaultVal)
    if isfield(s, fieldName) && ~isempty(s.(fieldName))
        val = s.(fieldName);
    else
        val = defaultVal;
    end
end
