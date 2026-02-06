%% CAD_PartGUI_Advanced.m
% Advanced MATLAB GUI for managing CAD_Part objects with full sub-object management
%
% Usage:
%   CAD_PartGUI_Advanced()              - Opens the GUI
%   parts = CAD_PartGUI_Advanced()      - Opens GUI and returns part list
%
% Features:
%   - Create and manage multiple parts
%   - Add features, sketches, bodies to parts
%   - Manage stations and coordinate systems
%   - Import/Export part collections
%   - Mass properties calculation

function varargout = CAD_PartGUI_Advanced()
    % Create the main figure
    fig = uifigure('Name', 'CAD Part Manager (Advanced)', ...
                   'Position', [50 50 1000 800], ...
                   'Resize', 'on');

    % Store data in figure's UserData
    data = struct();
    data.parts = {};
    data.selectedPartIndex = 0;
    fig.UserData = data;

    % Create main grid layout
    mainGL = uigridlayout(fig, [1, 2]);
    mainGL.ColumnWidth = {'0.30x', '0.70x'};
    mainGL.Padding = [10 10 10 10];

    % Left panel - Part list
    leftPanel = uipanel(mainGL, 'Title', 'Parts');
    leftGL = uigridlayout(leftPanel, [5, 1]);
    leftGL.RowHeight = {'1x', 35, 35, 35, 35};
    leftGL.Padding = [5 5 5 5];

    % Part listbox
    partListBox = uilistbox(leftGL, 'Items', {});

    % Quick-add button row
    quickBtnPanel = uigridlayout(leftGL, [1, 3]);
    quickBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    quickBtnPanel.Padding = [0 0 0 0];

    newPartBtn = uibutton(quickBtnPanel, 'Text', 'New Part', ...
                          'BackgroundColor', [0.3 0.6 0.3]);
    duplicateBtn = uibutton(quickBtnPanel, 'Text', 'Duplicate', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    deleteBtn = uibutton(quickBtnPanel, 'Text', 'Delete', ...
                         'BackgroundColor', [0.7 0.3 0.3]);

    % Template buttons
    templatePanel = uigridlayout(leftGL, [1, 3]);
    templatePanel.ColumnWidth = {'1x', '1x', '1x'};
    templatePanel.Padding = [0 0 0 0];

    plateBtn = uibutton(templatePanel, 'Text', 'Plate', ...
                        'BackgroundColor', [0.6 0.8 0.6], ...
                        'Tooltip', 'Create rectangular plate part');
    cylinderBtn = uibutton(templatePanel, 'Text', 'Cylinder', ...
                           'BackgroundColor', [0.6 0.8 0.6], ...
                           'Tooltip', 'Create cylindrical part');
    bracketBtn = uibutton(templatePanel, 'Text', 'Bracket', ...
                          'BackgroundColor', [0.6 0.8 0.6], ...
                          'Tooltip', 'Create L-bracket part');

    % Import/Export buttons
    ioBtnPanel = uigridlayout(leftGL, [1, 2]);
    ioBtnPanel.ColumnWidth = {'1x', '1x'};
    ioBtnPanel.Padding = [0 0 0 0];

    importBtn = uibutton(ioBtnPanel, 'Text', 'Import JSON', ...
                         'BackgroundColor', [0.4 0.6 0.8]);
    exportBtn = uibutton(ioBtnPanel, 'Text', 'Export All', ...
                         'BackgroundColor', [0.6 0.4 0.8]);

    % Assembly button
    assemblyBtn = uibutton(leftGL, 'Text', 'Create Assembly from Parts', ...
                           'BackgroundColor', [0.8 0.6 0.4]);

    % Right panel - Part editor with tabs
    rightPanel = uipanel(mainGL, 'Title', 'Part Editor');
    rightGL = uigridlayout(rightPanel, [2, 1]);
    rightGL.RowHeight = {35, '1x'};
    rightGL.Padding = [5 5 5 5];

    % Status/action bar
    actionPanel = uigridlayout(rightGL, [1, 4]);
    actionPanel.ColumnWidth = {'1x', '1x', '1x', '2x'};
    actionPanel.Padding = [0 0 0 0];

    updateBtn = uibutton(actionPanel, 'Text', 'Update Part', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    saveFileBtn = uibutton(actionPanel, 'Text', 'Save to File', ...
                           'BackgroundColor', [0.5 0.3 0.7]);
    copyJsonBtn = uibutton(actionPanel, 'Text', 'Copy JSON', ...
                           'BackgroundColor', [0.3 0.5 0.7]);
    statusLabel = uilabel(actionPanel, 'Text', 'Ready', ...
                          'FontColor', [0.2 0.2 0.8]);

    % Tab group for different part aspects
    tabGroup = uitabgroup(rightGL);

    % Tab 1: Basic Info
    basicTab = uitab(tabGroup, 'Title', 'Basic Info');
    basicGL = uigridlayout(basicTab, [10, 2]);
    basicGL.RowHeight = repmat({30}, 1, 10);
    basicGL.ColumnWidth = {'0.35x', '0.65x'};
    basicGL.Padding = [10 10 10 10];

    uilabel(basicGL, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(basicGL, 'text', 'Value', '', 'Placeholder', 'Part name');

    uilabel(basicGL, 'Text', 'Part Number:', 'HorizontalAlignment', 'right');
    partNumEdit = uieditfield(basicGL, 'text', 'Value', '', 'Placeholder', 'e.g., PN-001');

    uilabel(basicGL, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(basicGL, 'text', 'Value', '1.0');

    uilabel(basicGL, 'Text', 'Description:', 'HorizontalAlignment', 'right');
    descEdit = uieditfield(basicGL, 'text', 'Value', '', 'Placeholder', 'Part description');

    uilabel(basicGL, 'Text', 'Mass:', 'HorizontalAlignment', 'right');
    massPanel = uigridlayout(basicGL, [1, 2]);
    massPanel.ColumnWidth = {'1x', 70};
    massPanel.Padding = [0 0 0 0];
    massEdit = uieditfield(massPanel, 'numeric', 'Value', 0);
    massUnits = uidropdown(massPanel, 'Items', {'kg', 'g', 'lb', 'oz'}, 'Value', 'kg');

    uilabel(basicGL, 'Text', 'Center of Mass:', 'HorizontalAlignment', 'right');
    comEdit = uieditfield(basicGL, 'text', 'Value', '0, 0, 0', 'Placeholder', 'X, Y, Z');

    uilabel(basicGL, 'Text', 'Volume:', 'HorizontalAlignment', 'right');
    volumePanel = uigridlayout(basicGL, [1, 2]);
    volumePanel.ColumnWidth = {'1x', 70};
    volumePanel.Padding = [0 0 0 0];
    volumeEdit = uieditfield(volumePanel, 'numeric', 'Value', 0);
    uilabel(volumePanel, 'Text', 'mm^3');

    uilabel(basicGL, 'Text', 'Surface Area:', 'HorizontalAlignment', 'right');
    areaPanel = uigridlayout(basicGL, [1, 2]);
    areaPanel.ColumnWidth = {'1x', 70};
    areaPanel.Padding = [0 0 0 0];
    areaEdit = uieditfield(areaPanel, 'numeric', 'Value', 0);
    uilabel(areaPanel, 'Text', 'mm^2');

    uilabel(basicGL, 'Text', 'Material:', 'HorizontalAlignment', 'right');
    materialDropdown = uidropdown(basicGL, ...
        'Items', {'Aluminum 6061', 'Steel 1018', 'Stainless 304', 'Titanium Ti-6Al-4V', ...
                  'ABS Plastic', 'Nylon', 'PEEK', 'Custom'}, ...
        'Value', 'Aluminum 6061');

    % Calculate mass button
    calcMassBtn = uibutton(basicGL, 'Text', 'Calculate Mass from Volume', ...
                           'BackgroundColor', [0.6 0.7 0.9]);
    calcMassBtn.Layout.Column = [1 2];

    % Tab 2: Features
    featuresTab = uitab(tabGroup, 'Title', 'Features');
    featuresGL = uigridlayout(featuresTab, [3, 1]);
    featuresGL.RowHeight = {'1x', 35, 35};
    featuresGL.Padding = [10 10 10 10];

    featureListBox = uilistbox(featuresGL, 'Items', {});

    featureBtnPanel = uigridlayout(featuresGL, [1, 4]);
    featureBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    featureBtnPanel.Padding = [0 0 0 0];

    addFeatureBtn = uibutton(featureBtnPanel, 'Text', 'Add Feature', ...
                             'BackgroundColor', [0.3 0.6 0.3]);
    editFeatureBtn = uibutton(featureBtnPanel, 'Text', 'Edit', ...
                              'BackgroundColor', [0.5 0.5 0.7]);
    removeFeatureBtn = uibutton(featureBtnPanel, 'Text', 'Remove', ...
                                'BackgroundColor', [0.7 0.3 0.3]);
    featureGuiBtn = uibutton(featureBtnPanel, 'Text', 'Open Feature GUI', ...
                             'BackgroundColor', [0.4 0.6 0.8]);

    featureCountLabel = uilabel(featuresGL, 'Text', '0 features in part', ...
                                'HorizontalAlignment', 'center');

    % Tab 3: Sketches & Bodies
    geomTab = uitab(tabGroup, 'Title', 'Geometry');
    geomGL = uigridlayout(geomTab, [2, 2]);
    geomGL.RowHeight = {'1x', 35};
    geomGL.ColumnWidth = {'1x', '1x'};
    geomGL.Padding = [10 10 10 10];

    % Sketches panel
    sketchPanel = uipanel(geomGL, 'Title', 'Sketches');
    sketchPanelGL = uigridlayout(sketchPanel, [2, 1]);
    sketchPanelGL.RowHeight = {'1x', 30};
    sketchListBox = uilistbox(sketchPanelGL, 'Items', {});
    addSketchBtn = uibutton(sketchPanelGL, 'Text', 'Add Sketch', ...
                            'BackgroundColor', [0.3 0.6 0.3]);

    % Bodies panel
    bodyPanel = uipanel(geomGL, 'Title', 'Bodies');
    bodyPanelGL = uigridlayout(bodyPanel, [2, 1]);
    bodyPanelGL.RowHeight = {'1x', 30};
    bodyListBox = uilistbox(bodyPanelGL, 'Items', {});
    addBodyBtn = uibutton(bodyPanelGL, 'Text', 'Add Body', ...
                          'BackgroundColor', [0.3 0.6 0.3]);

    sketchCountLabel = uilabel(geomGL, 'Text', '0 sketches');
    bodyCountLabel = uilabel(geomGL, 'Text', '0 bodies');

    % Tab 4: Stations
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

    % Tab 5: JSON Preview
    jsonTab = uitab(tabGroup, 'Title', 'JSON');
    jsonGL = uigridlayout(jsonTab, [1, 1]);
    jsonGL.Padding = [10 10 10 10];

    jsonArea = uitextarea(jsonGL, 'Value', '', 'Editable', 'off', ...
                          'FontName', 'Consolas', 'FontSize', 9);

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.partListBox = partListBox;
    ui.nameEdit = nameEdit;
    ui.partNumEdit = partNumEdit;
    ui.versionEdit = versionEdit;
    ui.descEdit = descEdit;
    ui.massEdit = massEdit;
    ui.massUnits = massUnits;
    ui.comEdit = comEdit;
    ui.volumeEdit = volumeEdit;
    ui.areaEdit = areaEdit;
    ui.materialDropdown = materialDropdown;
    ui.featureListBox = featureListBox;
    ui.featureCountLabel = featureCountLabel;
    ui.sketchListBox = sketchListBox;
    ui.bodyListBox = bodyListBox;
    ui.sketchCountLabel = sketchCountLabel;
    ui.bodyCountLabel = bodyCountLabel;
    ui.axialEdit = axialEdit;
    ui.radialEdit = radialEdit;
    ui.angularEdit = angularEdit;
    ui.wingEdit = wingEdit;
    ui.stationPreview = stationPreview;
    ui.jsonArea = jsonArea;
    ui.statusLabel = statusLabel;

    % Set up callbacks
    partListBox.ValueChangedFcn = @(~,~) onPartSelected(ui);

    % Part management
    newPartBtn.ButtonPushedFcn = @(~,~) addNewPart(ui);
    duplicateBtn.ButtonPushedFcn = @(~,~) duplicatePart(ui);
    deleteBtn.ButtonPushedFcn = @(~,~) deletePart(ui);

    % Templates
    plateBtn.ButtonPushedFcn = @(~,~) createTemplatePart(ui, 'Plate');
    cylinderBtn.ButtonPushedFcn = @(~,~) createTemplatePart(ui, 'Cylinder');
    bracketBtn.ButtonPushedFcn = @(~,~) createTemplatePart(ui, 'Bracket');

    % Import/Export
    importBtn.ButtonPushedFcn = @(~,~) importParts(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportAllParts(ui);
    assemblyBtn.ButtonPushedFcn = @(~,~) createAssembly(ui);

    % Editor actions
    updateBtn.ButtonPushedFcn = @(~,~) updateCurrentPart(ui);
    saveFileBtn.ButtonPushedFcn = @(~,~) savePartToFile(ui);
    copyJsonBtn.ButtonPushedFcn = @(~,~) copyPartJson(ui);

    % Mass calculation
    calcMassBtn.ButtonPushedFcn = @(~,~) calculateMass(ui);

    % Feature management
    addFeatureBtn.ButtonPushedFcn = @(~,~) addFeatureToPart(ui);
    editFeatureBtn.ButtonPushedFcn = @(~,~) editSelectedFeature(ui);
    removeFeatureBtn.ButtonPushedFcn = @(~,~) removeSelectedFeature(ui);
    featureGuiBtn.ButtonPushedFcn = @(~,~) openFeatureGUI(ui);

    % Geometry management
    addSketchBtn.ButtonPushedFcn = @(~,~) addSketchToPart(ui);
    addBodyBtn.ButtonPushedFcn = @(~,~) addBodyToPart(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.parts;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Create default part struct
function part = createDefaultPart()
    part = struct();
    part.Name = '';
    part.PartNumber = '';
    part.Version = '1.0';
    part.Description = '';

    % Mass properties
    part.MyMassProperties = struct();
    part.MyMassProperties.Mass = 0;
    part.MyMassProperties.MassUnit = 'kg';
    part.MyMassProperties.Volume = 0;
    part.MyMassProperties.SurfaceArea = 0;

    part.CenterOfMass = struct('X_Value', 0, 'Y_Value', 0, 'Z_Value_Cartesian', 0);

    % Empty collections
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
    part.AxialStations = {};
    part.RadialStations = {};
    part.AngularStations = {};
    part.WingStations = {};
end

%% Add new blank part
function addNewPart(ui)
    parts = ui.fig.UserData.parts;

    part = createDefaultPart();
    part.Name = sprintf('Part_%d', length(parts) + 1);
    part.PartNumber = sprintf('PN-%03d', length(parts) + 1);

    parts{end+1} = part;
    ui.fig.UserData.parts = parts;
    ui.fig.UserData.selectedPartIndex = length(parts);

    updatePartList(ui);
    loadPartToEditor(ui, part);

    ui.statusLabel.Text = 'New part added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Create template part
function createTemplatePart(ui, templateType)
    parts = ui.fig.UserData.parts;

    part = createDefaultPart();
    part.Name = sprintf('%s_%d', templateType, length(parts) + 1);
    part.PartNumber = sprintf('PN-%s-%03d', upper(templateType(1:3)), length(parts) + 1);

    switch templateType
        case 'Plate'
            part.Description = 'Rectangular plate';
            % Add plate feature
            feature = struct();
            feature.Name = 'Plate_Extrusion';
            feature.GeometricFeatureType = 8; % Boss
            feature.ThreeDimOperations = [0]; % Extrude
            feature.MyDimensions = {};
            feature.MyDimensions{1} = createDimension('Length', 100, 'mm', 0);
            feature.MyDimensions{2} = createDimension('Width', 50, 'mm', 0);
            feature.MyDimensions{3} = createDimension('Thickness', 5, 'mm', 0);
            part.MyFeatures{1} = feature;

            % Calculate approximate mass (aluminum)
            volume = 100 * 50 * 5; % mm^3
            part.MyMassProperties.Volume = volume;
            part.MyMassProperties.Mass = volume * 2.7e-6; % kg (aluminum density)

        case 'Cylinder'
            part.Description = 'Cylindrical part';
            feature = struct();
            feature.Name = 'Cylinder_Revolve';
            feature.GeometricFeatureType = 8; % Boss
            feature.ThreeDimOperations = [1]; % Revolve
            feature.MyDimensions = {};
            feature.MyDimensions{1} = createDimension('Diameter', 50, 'mm', 1);
            feature.MyDimensions{2} = createDimension('Height', 100, 'mm', 0);
            part.MyFeatures{1} = feature;

            % Calculate approximate mass
            volume = pi * (25^2) * 100; % mm^3
            part.MyMassProperties.Volume = volume;
            part.MyMassProperties.Mass = volume * 2.7e-6; % kg

        case 'Bracket'
            part.Description = 'L-shaped bracket';
            % Vertical leg
            feature1 = struct();
            feature1.Name = 'Vertical_Leg';
            feature1.GeometricFeatureType = 10; % Leg
            feature1.ThreeDimOperations = [0];
            feature1.MyDimensions = {};
            feature1.MyDimensions{1} = createDimension('Height', 80, 'mm', 0);
            feature1.MyDimensions{2} = createDimension('Width', 40, 'mm', 0);
            feature1.MyDimensions{3} = createDimension('Thickness', 5, 'mm', 0);
            part.MyFeatures{1} = feature1;

            % Horizontal leg
            feature2 = struct();
            feature2.Name = 'Horizontal_Leg';
            feature2.GeometricFeatureType = 10; % Leg
            feature2.ThreeDimOperations = [0];
            feature2.MyDimensions = {};
            feature2.MyDimensions{1} = createDimension('Length', 60, 'mm', 0);
            feature2.MyDimensions{2} = createDimension('Width', 40, 'mm', 0);
            feature2.MyDimensions{3} = createDimension('Thickness', 5, 'mm', 0);
            part.MyFeatures{2} = feature2;

            volume = (80*40*5) + (60*40*5) - (5*40*5); % Approximate
            part.MyMassProperties.Volume = volume;
            part.MyMassProperties.Mass = volume * 2.7e-6;
    end

    parts{end+1} = part;
    ui.fig.UserData.parts = parts;
    ui.fig.UserData.selectedPartIndex = length(parts);

    updatePartList(ui);
    loadPartToEditor(ui, part);

    ui.statusLabel.Text = sprintf('%s template created!', templateType);
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Create dimension helper
function dim = createDimension(name, value, units, dimType)
    dim = struct();
    dim.DimensionID = ['DIM_' upper(name)];
    dim.Name = name;
    dim.DimensionNominalValue = value;
    dim.EngineeringUnit = struct('UnitName', units);
    dim.MyDimensionType = dimType;
end

%% Update part list display
function updatePartList(ui)
    parts = ui.fig.UserData.parts;
    items = cell(1, length(parts));

    for i = 1:length(parts)
        p = parts{i};
        pn = '';
        if isfield(p, 'PartNumber') && ~isempty(p.PartNumber)
            pn = [' (' p.PartNumber ')'];
        end
        items{i} = sprintf('%d. %s%s', i, p.Name, pn);
    end

    ui.partListBox.Items = items;

    idx = ui.fig.UserData.selectedPartIndex;
    if idx > 0 && idx <= length(items)
        ui.partListBox.Value = items{idx};
    end
end

%% On part selected from list
function onPartSelected(ui)
    if isempty(ui.partListBox.Value)
        return;
    end

    selStr = ui.partListBox.Value;
    dotPos = strfind(selStr, '.');
    if ~isempty(dotPos)
        idx = str2double(selStr(1:dotPos(1)-1));
        ui.fig.UserData.selectedPartIndex = idx;

        parts = ui.fig.UserData.parts;
        if idx > 0 && idx <= length(parts)
            loadPartToEditor(ui, parts{idx});
        end
    end
end

%% Load part to editor
function loadPartToEditor(ui, part)
    % Basic info
    ui.nameEdit.Value = part.Name;
    ui.partNumEdit.Value = part.PartNumber;
    ui.versionEdit.Value = part.Version;
    ui.descEdit.Value = part.Description;

    % Mass properties
    if isfield(part, 'MyMassProperties')
        mp = part.MyMassProperties;
        if isfield(mp, 'Mass'), ui.massEdit.Value = mp.Mass; end
        if isfield(mp, 'MassUnit'), ui.massUnits.Value = mp.MassUnit; end
        if isfield(mp, 'Volume'), ui.volumeEdit.Value = mp.Volume; end
        if isfield(mp, 'SurfaceArea'), ui.areaEdit.Value = mp.SurfaceArea; end
    end

    % Center of mass
    if isfield(part, 'CenterOfMass')
        com = part.CenterOfMass;
        ui.comEdit.Value = sprintf('%.3f, %.3f, %.3f', ...
            com.X_Value, com.Y_Value, com.Z_Value_Cartesian);
    end

    % Feature list
    featureItems = {};
    if isfield(part, 'MyFeatures')
        for i = 1:length(part.MyFeatures)
            f = part.MyFeatures{i};
            featureItems{i} = sprintf('%d. %s', i, f.Name);
        end
    end
    ui.featureListBox.Items = featureItems;
    ui.featureCountLabel.Text = sprintf('%d features in part', length(featureItems));

    % Sketch list
    sketchItems = {};
    if isfield(part, 'MySketches')
        for i = 1:length(part.MySketches)
            s = part.MySketches{i};
            if isfield(s, 'Name')
                sketchItems{i} = sprintf('%d. %s', i, s.Name);
            else
                sketchItems{i} = sprintf('%d. Sketch_%d', i, i);
            end
        end
    end
    ui.sketchListBox.Items = sketchItems;
    ui.sketchCountLabel.Text = sprintf('%d sketches', length(sketchItems));

    % Body list
    bodyItems = {};
    if isfield(part, 'MyBodies')
        for i = 1:length(part.MyBodies)
            b = part.MyBodies{i};
            if isfield(b, 'Name')
                bodyItems{i} = sprintf('%d. %s', i, b.Name);
            else
                bodyItems{i} = sprintf('%d. Body_%d', i, i);
            end
        end
    end
    ui.bodyListBox.Items = bodyItems;
    ui.bodyCountLabel.Text = sprintf('%d bodies', length(bodyItems));

    % Stations
    ui.axialEdit.Value = stationsToString(part.AxialStations);
    ui.radialEdit.Value = stationsToString(part.RadialStations);
    ui.angularEdit.Value = stationsToString(part.AngularStations);
    ui.wingEdit.Value = stationsToString(part.WingStations);

    % Update station preview
    updateStationPreview(ui, part);

    % JSON preview
    jsonStr = jsonencode(part, 'PrettyPrint', true);
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
function updateStationPreview(ui, part)
    lines = {};
    lines{end+1} = 'Station Summary:';
    lines{end+1} = sprintf('  Axial: %d stations', length(part.AxialStations));
    lines{end+1} = sprintf('  Radial: %d stations', length(part.RadialStations));
    lines{end+1} = sprintf('  Angular: %d stations', length(part.AngularStations));
    lines{end+1} = sprintf('  Wing: %d stations', length(part.WingStations));

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

%% Update current part from editor
function updateCurrentPart(ui)
    idx = ui.fig.UserData.selectedPartIndex;
    if idx < 1
        ui.statusLabel.Text = 'No part selected!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    try
        parts = ui.fig.UserData.parts;
        part = parts{idx};

        % Update basic info
        part.Name = ui.nameEdit.Value;
        part.PartNumber = ui.partNumEdit.Value;
        part.Version = ui.versionEdit.Value;
        part.Description = ui.descEdit.Value;

        % Mass properties
        part.MyMassProperties.Mass = ui.massEdit.Value;
        part.MyMassProperties.MassUnit = ui.massUnits.Value;
        part.MyMassProperties.Volume = ui.volumeEdit.Value;
        part.MyMassProperties.SurfaceArea = ui.areaEdit.Value;

        % Center of mass
        part.CenterOfMass = parsePoint(ui.comEdit.Value);

        % Stations
        part.AxialStations = parseStations(ui.axialEdit.Value, 0);
        part.RadialStations = parseStations(ui.radialEdit.Value, 1);
        part.AngularStations = parseStations(ui.angularEdit.Value, 2);
        part.WingStations = parseStations(ui.wingEdit.Value, 3);

        % Save back
        parts{idx} = part;
        ui.fig.UserData.parts = parts;

        updatePartList(ui);
        updateStationPreview(ui, part);

        % Update JSON
        jsonStr = jsonencode(part, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        ui.statusLabel.Text = 'Part updated!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
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

%% Calculate mass from volume
function calculateMass(ui)
    volume = ui.volumeEdit.Value; % mm^3

    % Material densities (kg/mm^3)
    densities = containers.Map(...
        {'Aluminum 6061', 'Steel 1018', 'Stainless 304', 'Titanium Ti-6Al-4V', ...
         'ABS Plastic', 'Nylon', 'PEEK', 'Custom'}, ...
        {2.7e-6, 7.87e-6, 8.0e-6, 4.43e-6, 1.05e-6, 1.15e-6, 1.32e-6, 1.0e-6});

    material = ui.materialDropdown.Value;
    density = densities(material);

    mass = volume * density; % kg
    ui.massEdit.Value = mass;
    ui.massUnits.Value = 'kg';

    ui.statusLabel.Text = sprintf('Mass calculated: %.4f kg', mass);
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Duplicate selected part
function duplicatePart(ui)
    idx = ui.fig.UserData.selectedPartIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a part first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    parts = ui.fig.UserData.parts;
    newPart = parts{idx};
    newPart.Name = [newPart.Name '_copy'];
    newPart.PartNumber = [newPart.PartNumber '-COPY'];

    parts{end+1} = newPart;
    ui.fig.UserData.parts = parts;
    ui.fig.UserData.selectedPartIndex = length(parts);

    updatePartList(ui);
    loadPartToEditor(ui, newPart);

    ui.statusLabel.Text = 'Part duplicated';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Delete selected part
function deletePart(ui)
    idx = ui.fig.UserData.selectedPartIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a part first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    parts = ui.fig.UserData.parts;
    parts(idx) = [];
    ui.fig.UserData.parts = parts;

    if idx > length(parts)
        idx = length(parts);
    end
    ui.fig.UserData.selectedPartIndex = idx;

    updatePartList(ui);

    if idx > 0
        loadPartToEditor(ui, parts{idx});
    else
        clearEditor(ui);
    end

    ui.statusLabel.Text = 'Part deleted';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Clear editor
function clearEditor(ui)
    ui.nameEdit.Value = '';
    ui.partNumEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.descEdit.Value = '';
    ui.massEdit.Value = 0;
    ui.volumeEdit.Value = 0;
    ui.areaEdit.Value = 0;
    ui.comEdit.Value = '0, 0, 0';
    ui.featureListBox.Items = {};
    ui.sketchListBox.Items = {};
    ui.bodyListBox.Items = {};
    ui.axialEdit.Value = '';
    ui.radialEdit.Value = '';
    ui.angularEdit.Value = '';
    ui.wingEdit.Value = '';
    ui.jsonArea.Value = '';
end

%% Add feature to part
function addFeatureToPart(ui)
    idx = ui.fig.UserData.selectedPartIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a part first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    parts = ui.fig.UserData.parts;
    part = parts{idx};

    % Create new feature
    feature = struct();
    feature.Name = sprintf('Feature_%d', length(part.MyFeatures) + 1);
    feature.GeometricFeatureType = 0; % Hole
    feature.ThreeDimOperations = [0]; % Extrude
    feature.MyDimensions = {};

    part.MyFeatures{end+1} = feature;
    parts{idx} = part;
    ui.fig.UserData.parts = parts;

    loadPartToEditor(ui, part);

    ui.statusLabel.Text = 'Feature added to part';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit selected feature (placeholder)
function editSelectedFeature(ui)
    ui.statusLabel.Text = 'Use Feature GUI to edit features';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove selected feature
function removeSelectedFeature(ui)
    idx = ui.fig.UserData.selectedPartIndex;
    if idx < 1
        return;
    end

    featureSel = ui.featureListBox.Value;
    if isempty(featureSel)
        ui.statusLabel.Text = 'Select a feature first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Parse feature index
    dotPos = strfind(featureSel, '.');
    if isempty(dotPos), return; end
    featureIdx = str2double(featureSel(1:dotPos(1)-1));

    parts = ui.fig.UserData.parts;
    part = parts{idx};
    part.MyFeatures(featureIdx) = [];
    parts{idx} = part;
    ui.fig.UserData.parts = parts;

    loadPartToEditor(ui, part);

    ui.statusLabel.Text = 'Feature removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Open Feature GUI
function openFeatureGUI(ui)
    try
        CAD_FeatureGUI_Advanced();
        ui.statusLabel.Text = 'Feature GUI opened';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];
    catch
        ui.statusLabel.Text = 'Could not open Feature GUI';
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Add sketch to part
function addSketchToPart(ui)
    idx = ui.fig.UserData.selectedPartIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a part first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    parts = ui.fig.UserData.parts;
    part = parts{idx};

    sketch = struct();
    sketch.Name = sprintf('Sketch_%d', length(part.MySketches) + 1);
    sketch.Elements = {};

    part.MySketches{end+1} = sketch;
    parts{idx} = part;
    ui.fig.UserData.parts = parts;

    loadPartToEditor(ui, part);

    ui.statusLabel.Text = 'Sketch added to part';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Add body to part
function addBodyToPart(ui)
    idx = ui.fig.UserData.selectedPartIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a part first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    parts = ui.fig.UserData.parts;
    part = parts{idx};

    body = struct();
    body.Name = sprintf('Body_%d', length(part.MyBodies) + 1);
    body.Surfaces = {};

    part.MyBodies{end+1} = body;
    parts{idx} = part;
    ui.fig.UserData.parts = parts;

    loadPartToEditor(ui, part);

    ui.statusLabel.Text = 'Body added to part';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Import parts from JSON
function importParts(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files'}, 'Import Parts');
    if filename == 0, return; end

    try
        jsonStr = fileread(fullfile(pathname, filename));
        imported = jsondecode(jsonStr);

        if isfield(imported, 'Parts')
            for i = 1:length(imported.Parts)
                parts = ui.fig.UserData.parts;
                parts{end+1} = imported.Parts(i);
                ui.fig.UserData.parts = parts;
            end
        else
            parts = ui.fig.UserData.parts;
            parts{end+1} = imported;
            ui.fig.UserData.parts = parts;
        end

        updatePartList(ui);
        ui.statusLabel.Text = 'Parts imported!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Import error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Export all parts
function exportAllParts(ui)
    parts = ui.fig.UserData.parts;
    if isempty(parts)
        ui.statusLabel.Text = 'No parts to export!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Export All Parts', 'CAD_Parts.json');
    if filename == 0, return; end

    try
        collection = struct();
        collection.ExportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        collection.PartCount = length(parts);
        collection.Parts = parts;

        jsonStr = jsonencode(collection, 'PrettyPrint', true);

        fid = fopen(fullfile(pathname, filename), 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = sprintf('Exported %d parts!', length(parts));
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Export error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Save single part to file
function savePartToFile(ui)
    idx = ui.fig.UserData.selectedPartIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a part first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    parts = ui.fig.UserData.parts;
    part = parts{idx};

    defaultName = 'CAD_Part.json';
    if ~isempty(part.PartNumber)
        defaultName = [part.PartNumber '.json'];
    elseif ~isempty(part.Name)
        defaultName = [part.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Save Part', defaultName);
    if filename == 0, return; end

    try
        jsonStr = jsonencode(part, 'PrettyPrint', true);
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

%% Copy part JSON to clipboard
function copyPartJson(ui)
    idx = ui.fig.UserData.selectedPartIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a part first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    parts = ui.fig.UserData.parts;
    part = parts{idx};

    jsonStr = jsonencode(part, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Create assembly from parts
function createAssembly(ui)
    parts = ui.fig.UserData.parts;
    if isempty(parts)
        ui.statusLabel.Text = 'No parts to create assembly!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Save Assembly', 'CAD_Assembly.json');
    if filename == 0, return; end

    try
        assembly = struct();
        assembly.Name = 'Assembly_1';
        assembly.Version = '1.0';
        assembly.Description = sprintf('Assembly with %d parts', length(parts));
        assembly.MyParts = parts;
        assembly.MyJoints = {};
        assembly.MyConstraints = {};

        jsonStr = jsonencode(assembly, 'PrettyPrint', true);
        fid = fopen(fullfile(pathname, filename), 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = 'Assembly created!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Assembly error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end
