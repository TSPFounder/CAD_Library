%% CAD_FeatureGUI_Advanced.m
% Advanced MATLAB GUI for managing multiple CAD_Feature objects
%
% Usage:
%   CAD_FeatureGUI_Advanced()              - Opens the GUI
%   features = CAD_FeatureGUI_Advanced()   - Opens GUI and returns feature list
%
% Features:
%   - Create and manage multiple features
%   - Feature list with selection
%   - Quick-add common feature types
%   - Import/Export feature collections
%   - Feature-specific parameter panels

function varargout = CAD_FeatureGUI_Advanced()
    % Create the main figure
    fig = uifigure('Name', 'CAD Feature Manager (Advanced)', ...
                   'Position', [50 50 900 750], ...
                   'Resize', 'on');

    % Store data in figure's UserData
    data = struct();
    data.features = {};
    data.selectedIndex = 0;
    fig.UserData = data;

    % Create main grid layout
    mainGL = uigridlayout(fig, [1, 2]);
    mainGL.ColumnWidth = {'0.35x', '0.65x'};
    mainGL.Padding = [10 10 10 10];

    % Left panel - Feature list
    leftPanel = uipanel(mainGL, 'Title', 'Feature List');
    leftGL = uigridlayout(leftPanel, [5, 1]);
    leftGL.RowHeight = {'1x', 35, 35, 35, 35};
    leftGL.Padding = [5 5 5 5];

    % Feature listbox
    featureListBox = uilistbox(leftGL, 'Items', {}, ...
                                'ValueChangedFcn', @(src,~) onFeatureSelected(src));

    % Quick-add buttons row 1
    quickBtnPanel1 = uigridlayout(leftGL, [1, 4]);
    quickBtnPanel1.ColumnWidth = {'1x', '1x', '1x', '1x'};
    quickBtnPanel1.Padding = [0 0 0 0];

    holeBtn = uibutton(quickBtnPanel1, 'Text', 'Hole', ...
                       'BackgroundColor', [0.6 0.8 0.6]);
    filletBtn = uibutton(quickBtnPanel1, 'Text', 'Fillet', ...
                         'BackgroundColor', [0.6 0.8 0.6]);
    chamferBtn = uibutton(quickBtnPanel1, 'Text', 'Chamfer', ...
                          'BackgroundColor', [0.6 0.8 0.6]);
    threadBtn = uibutton(quickBtnPanel1, 'Text', 'Thread', ...
                         'BackgroundColor', [0.6 0.8 0.6]);

    % Quick-add buttons row 2
    quickBtnPanel2 = uigridlayout(leftGL, [1, 4]);
    quickBtnPanel2.ColumnWidth = {'1x', '1x', '1x', '1x'};
    quickBtnPanel2.Padding = [0 0 0 0];

    bossBtn = uibutton(quickBtnPanel2, 'Text', 'Boss', ...
                       'BackgroundColor', [0.6 0.7 0.9]);
    ribBtn = uibutton(quickBtnPanel2, 'Text', 'Rib', ...
                      'BackgroundColor', [0.6 0.7 0.9]);
    shellBtn = uibutton(quickBtnPanel2, 'Text', 'Shell', ...
                        'BackgroundColor', [0.6 0.7 0.9]);
    slotBtn = uibutton(quickBtnPanel2, 'Text', 'Slot', ...
                       'BackgroundColor', [0.6 0.7 0.9]);

    % List management buttons
    listBtnPanel = uigridlayout(leftGL, [1, 3]);
    listBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    listBtnPanel.Padding = [0 0 0 0];

    addBtn = uibutton(listBtnPanel, 'Text', 'Add New', ...
                      'BackgroundColor', [0.3 0.6 0.3]);
    duplicateBtn = uibutton(listBtnPanel, 'Text', 'Duplicate', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    deleteBtn = uibutton(listBtnPanel, 'Text', 'Delete', ...
                         'BackgroundColor', [0.7 0.3 0.3]);

    % Import/Export buttons
    ioBtnPanel = uigridlayout(leftGL, [1, 2]);
    ioBtnPanel.ColumnWidth = {'1x', '1x'};
    ioBtnPanel.Padding = [0 0 0 0];

    importBtn = uibutton(ioBtnPanel, 'Text', 'Import JSON', ...
                         'BackgroundColor', [0.4 0.6 0.8]);
    exportBtn = uibutton(ioBtnPanel, 'Text', 'Export All', ...
                         'BackgroundColor', [0.6 0.4 0.8]);

    % Right panel - Feature editor
    rightPanel = uipanel(mainGL, 'Title', 'Feature Editor');
    rightGL = uigridlayout(rightPanel, [14, 2]);
    rightGL.RowHeight = [30, 30, 30, 35, 30, 30, 30, 30, 30, 30, 30, 10, 35, '1x'];
    rightGL.ColumnWidth = {'0.35x', '0.65x'};
    rightGL.Padding = [10 10 10 10];
    rightGL.RowSpacing = 4;

    % Row 1: Name
    uilabel(rightGL, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(rightGL, 'text', 'Value', '', ...
                           'Placeholder', 'Feature name');

    % Row 2: Version
    uilabel(rightGL, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(rightGL, 'text', 'Value', '1.0', ...
                              'Placeholder', 'e.g., 1.0');

    % Row 3: Feature Type
    uilabel(rightGL, 'Text', 'Feature Type:', 'HorizontalAlignment', 'right');
    featureTypes = {'Hole', 'Joint', 'Thread', 'Chamfer', 'Fillet', ...
                    'CounterBore', 'CounterSink', 'Bead', 'Boss', 'Keyway', ...
                    'Leg', 'Arm', 'Mirror', 'Embossment', 'Rib', ...
                    'RoundedSlot', 'Gusset', 'Taper', 'SquareSlot', 'Shell', ...
                    'Web', 'Tab', 'Coil', 'Helicoil', 'RectangularPattern', ...
                    'CircularPattern', 'OtherPattern', 'Other'};
    typeDropdown = uidropdown(rightGL, 'Items', featureTypes, 'Value', 'Hole');

    % Row 4: 3D Operations
    uilabel(rightGL, 'Text', '3D Operations:', 'HorizontalAlignment', 'right');
    opsPanel = uigridlayout(rightGL, [1, 4]);
    opsPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    opsPanel.Padding = [0 0 0 0];
    extrudeCheck = uicheckbox(opsPanel, 'Text', 'Extrude', 'Value', true);
    revolveCheck = uicheckbox(opsPanel, 'Text', 'Revolve', 'Value', false);
    sweepCheck = uicheckbox(opsPanel, 'Text', 'Sweep', 'Value', false);
    loftCheck = uicheckbox(opsPanel, 'Text', 'Loft', 'Value', false);

    % Row 5: Primary Dimension header
    dimHeader = uilabel(rightGL, 'Text', '── Dimensions ──', ...
                        'HorizontalAlignment', 'center', ...
                        'FontWeight', 'bold', ...
                        'FontColor', [0.3 0.3 0.6]);
    dimHeader.Layout.Column = [1 2];

    % Row 6: Width/Diameter
    uilabel(rightGL, 'Text', 'Width/Diameter:', 'HorizontalAlignment', 'right');
    widthPanel = uigridlayout(rightGL, [1, 2]);
    widthPanel.ColumnWidth = {'1x', 70};
    widthPanel.Padding = [0 0 0 0];
    widthEdit = uieditfield(widthPanel, 'numeric', 'Value', 0);
    widthUnits = uidropdown(widthPanel, 'Items', {'mm', 'cm', 'm', 'in'}, 'Value', 'mm');

    % Row 7: Height/Length
    uilabel(rightGL, 'Text', 'Height/Length:', 'HorizontalAlignment', 'right');
    heightPanel = uigridlayout(rightGL, [1, 2]);
    heightPanel.ColumnWidth = {'1x', 70};
    heightPanel.Padding = [0 0 0 0];
    heightEdit = uieditfield(heightPanel, 'numeric', 'Value', 0);
    heightUnits = uidropdown(heightPanel, 'Items', {'mm', 'cm', 'm', 'in'}, 'Value', 'mm');

    % Row 8: Depth
    uilabel(rightGL, 'Text', 'Depth:', 'HorizontalAlignment', 'right');
    depthPanel = uigridlayout(rightGL, [1, 2]);
    depthPanel.ColumnWidth = {'1x', 70};
    depthPanel.Padding = [0 0 0 0];
    depthEdit = uieditfield(depthPanel, 'numeric', 'Value', 0);
    depthUnits = uidropdown(depthPanel, 'Items', {'mm', 'cm', 'm', 'in'}, 'Value', 'mm');

    % Row 9: Radius
    uilabel(rightGL, 'Text', 'Radius:', 'HorizontalAlignment', 'right');
    radiusPanel = uigridlayout(rightGL, [1, 2]);
    radiusPanel.ColumnWidth = {'1x', 70};
    radiusPanel.Padding = [0 0 0 0];
    radiusEdit = uieditfield(radiusPanel, 'numeric', 'Value', 0);
    radiusUnits = uidropdown(radiusPanel, 'Items', {'mm', 'cm', 'm', 'in'}, 'Value', 'mm');

    % Row 10: Angle
    uilabel(rightGL, 'Text', 'Angle:', 'HorizontalAlignment', 'right');
    anglePanel = uigridlayout(rightGL, [1, 2]);
    anglePanel.ColumnWidth = {'1x', 70};
    anglePanel.Padding = [0 0 0 0];
    angleEdit = uieditfield(anglePanel, 'numeric', 'Value', 0);
    angleUnits = uidropdown(anglePanel, 'Items', {'deg', 'rad'}, 'Value', 'deg');

    % Row 11: Pattern Count (for patterns)
    uilabel(rightGL, 'Text', 'Pattern Count:', 'HorizontalAlignment', 'right');
    patternPanel = uigridlayout(rightGL, [1, 3]);
    patternPanel.ColumnWidth = {'1x', '1x', 70};
    patternPanel.Padding = [0 0 0 0];
    patternCount1 = uieditfield(patternPanel, 'numeric', 'Value', 1);
    patternCount2 = uieditfield(patternPanel, 'numeric', 'Value', 1);
    patternSpacing = uieditfield(patternPanel, 'numeric', 'Value', 10, ...
                                 'Tooltip', 'Spacing (mm)');

    % Row 12: Separator
    sep1 = uilabel(rightGL, 'Text', '');
    sep1.Layout.Column = [1 2];

    % Row 13: Update/Status row
    actionPanel = uigridlayout(rightGL, [1, 3]);
    actionPanel.Layout.Column = [1 2];
    actionPanel.ColumnWidth = {'1x', '1x', '2x'};
    actionPanel.Padding = [0 0 0 0];

    updateBtn = uibutton(actionPanel, 'Text', 'Update Feature', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    saveFileBtn = uibutton(actionPanel, 'Text', 'Save to File', ...
                           'BackgroundColor', [0.5 0.3 0.7]);
    statusLabel = uilabel(actionPanel, 'Text', 'Ready', ...
                          'FontColor', [0.2 0.2 0.8]);

    % Row 14: JSON Preview
    jsonArea = uitextarea(rightGL, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 14;
    jsonArea.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.featureListBox = featureListBox;
    ui.nameEdit = nameEdit;
    ui.versionEdit = versionEdit;
    ui.typeDropdown = typeDropdown;
    ui.extrudeCheck = extrudeCheck;
    ui.revolveCheck = revolveCheck;
    ui.sweepCheck = sweepCheck;
    ui.loftCheck = loftCheck;
    ui.widthEdit = widthEdit;
    ui.widthUnits = widthUnits;
    ui.heightEdit = heightEdit;
    ui.heightUnits = heightUnits;
    ui.depthEdit = depthEdit;
    ui.depthUnits = depthUnits;
    ui.radiusEdit = radiusEdit;
    ui.radiusUnits = radiusUnits;
    ui.angleEdit = angleEdit;
    ui.angleUnits = angleUnits;
    ui.patternCount1 = patternCount1;
    ui.patternCount2 = patternCount2;
    ui.patternSpacing = patternSpacing;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    featureListBox.ValueChangedFcn = @(src,~) onFeatureSelected(ui);

    % Quick-add buttons
    holeBtn.ButtonPushedFcn = @(~,~) quickAddFeature(ui, 'Hole');
    filletBtn.ButtonPushedFcn = @(~,~) quickAddFeature(ui, 'Fillet');
    chamferBtn.ButtonPushedFcn = @(~,~) quickAddFeature(ui, 'Chamfer');
    threadBtn.ButtonPushedFcn = @(~,~) quickAddFeature(ui, 'Thread');
    bossBtn.ButtonPushedFcn = @(~,~) quickAddFeature(ui, 'Boss');
    ribBtn.ButtonPushedFcn = @(~,~) quickAddFeature(ui, 'Rib');
    shellBtn.ButtonPushedFcn = @(~,~) quickAddFeature(ui, 'Shell');
    slotBtn.ButtonPushedFcn = @(~,~) quickAddFeature(ui, 'RoundedSlot');

    % List management
    addBtn.ButtonPushedFcn = @(~,~) addNewFeature(ui);
    duplicateBtn.ButtonPushedFcn = @(~,~) duplicateFeature(ui);
    deleteBtn.ButtonPushedFcn = @(~,~) deleteFeature(ui);

    % Import/Export
    importBtn.ButtonPushedFcn = @(~,~) importFeatures(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportAllFeatures(ui);

    % Editor buttons
    updateBtn.ButtonPushedFcn = @(~,~) updateCurrentFeature(ui);
    saveFileBtn.ButtonPushedFcn = @(~,~) saveFeatureToFile(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.features;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Quick-add feature with preset type
function quickAddFeature(ui, featureType)
    features = ui.fig.UserData.features;

    % Create new feature with type
    feature = createDefaultFeature();
    feature.GeometricFeatureType = getFeatureTypeEnum(featureType);
    feature.Name = sprintf('%s_%d', featureType, length(features) + 1);

    % Set defaults based on type
    switch featureType
        case 'Hole'
            feature.MyDimensions{1} = createDimension('Diameter', 10, 'mm', 1);
            feature.MyDimensions{2} = createDimension('Depth', 20, 'mm', 4);
        case 'Fillet'
            feature.MyDimensions{1} = createDimension('Radius', 5, 'mm', 2);
        case 'Chamfer'
            feature.MyDimensions{1} = createDimension('Width', 2, 'mm', 0);
            feature.MyDimensions{2} = createDimension('Angle', 45, 'deg', 3);
        case 'Thread'
            feature.MyDimensions{1} = createDimension('Diameter', 10, 'mm', 1);
            feature.MyDimensions{2} = createDimension('Pitch', 1.5, 'mm', 0);
        case 'Boss'
            feature.MyDimensions{1} = createDimension('Diameter', 20, 'mm', 1);
            feature.MyDimensions{2} = createDimension('Height', 10, 'mm', 0);
            feature.ThreeDimOperations = [0]; % Extrude
        case 'Rib'
            feature.MyDimensions{1} = createDimension('Thickness', 3, 'mm', 0);
            feature.MyDimensions{2} = createDimension('Height', 15, 'mm', 0);
        case 'Shell'
            feature.MyDimensions{1} = createDimension('Thickness', 2, 'mm', 0);
        case 'RoundedSlot'
            feature.MyDimensions{1} = createDimension('Length', 30, 'mm', 0);
            feature.MyDimensions{2} = createDimension('Width', 10, 'mm', 0);
            feature.MyDimensions{3} = createDimension('Depth', 5, 'mm', 4);
    end

    features{end+1} = feature;
    ui.fig.UserData.features = features;
    ui.fig.UserData.selectedIndex = length(features);

    updateFeatureList(ui);
    loadFeatureToEditor(ui, feature);

    ui.statusLabel.Text = sprintf('%s feature added!', featureType);
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Create default feature struct
function feature = createDefaultFeature()
    feature = struct();
    feature.Name = '';
    feature.Version = '1.0';
    feature.GeometricFeatureType = 0;
    feature.ThreeDimOperations = [];
    feature.MyDimensions = {};
    feature.Sketches = {};
    feature.Stations = {};
    feature.MyFeatures = {};
    feature.MyLibraries = {};
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

%% Get feature type enum value
function enumVal = getFeatureTypeEnum(typeName)
    typeMap = containers.Map(...
        {'Hole', 'Joint', 'Thread', 'Chamfer', 'Fillet', ...
         'CounterBore', 'CounterSink', 'Bead', 'Boss', 'Keyway', ...
         'Leg', 'Arm', 'Mirror', 'Embossment', 'Rib', ...
         'RoundedSlot', 'Gusset', 'Taper', 'SquareSlot', 'Shell', ...
         'Web', 'Tab', 'Coil', 'Helicoil', 'RectangularPattern', ...
         'CircularPattern', 'OtherPattern', 'Other'}, ...
        {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, ...
         15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27});
    enumVal = typeMap(typeName);
end

%% Get feature type name from enum
function typeName = getFeatureTypeName(enumVal)
    types = {'Hole', 'Joint', 'Thread', 'Chamfer', 'Fillet', ...
             'CounterBore', 'CounterSink', 'Bead', 'Boss', 'Keyway', ...
             'Leg', 'Arm', 'Mirror', 'Embossment', 'Rib', ...
             'RoundedSlot', 'Gusset', 'Taper', 'SquareSlot', 'Shell', ...
             'Web', 'Tab', 'Coil', 'Helicoil', 'RectangularPattern', ...
             'CircularPattern', 'OtherPattern', 'Other'};
    if enumVal >= 0 && enumVal < length(types)
        typeName = types{enumVal + 1};
    else
        typeName = 'Other';
    end
end

%% Add new blank feature
function addNewFeature(ui)
    features = ui.fig.UserData.features;

    feature = createDefaultFeature();
    feature.Name = sprintf('Feature_%d', length(features) + 1);

    features{end+1} = feature;
    ui.fig.UserData.features = features;
    ui.fig.UserData.selectedIndex = length(features);

    updateFeatureList(ui);
    loadFeatureToEditor(ui, feature);

    ui.statusLabel.Text = 'New feature added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Duplicate selected feature
function duplicateFeature(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a feature first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    features = ui.fig.UserData.features;
    original = features{idx};

    % Deep copy
    newFeature = original;
    newFeature.Name = [original.Name '_copy'];

    features{end+1} = newFeature;
    ui.fig.UserData.features = features;
    ui.fig.UserData.selectedIndex = length(features);

    updateFeatureList(ui);
    loadFeatureToEditor(ui, newFeature);

    ui.statusLabel.Text = 'Feature duplicated';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Delete selected feature
function deleteFeature(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a feature first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    features = ui.fig.UserData.features;
    features(idx) = [];
    ui.fig.UserData.features = features;

    if idx > length(features)
        idx = length(features);
    end
    ui.fig.UserData.selectedIndex = idx;

    updateFeatureList(ui);

    if idx > 0
        loadFeatureToEditor(ui, features{idx});
    else
        clearEditor(ui);
    end

    ui.statusLabel.Text = 'Feature deleted';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Update feature list display
function updateFeatureList(ui)
    features = ui.fig.UserData.features;
    items = cell(1, length(features));

    for i = 1:length(features)
        f = features{i};
        typeName = getFeatureTypeName(f.GeometricFeatureType);
        items{i} = sprintf('%d. %s (%s)', i, f.Name, typeName);
    end

    ui.featureListBox.Items = items;

    idx = ui.fig.UserData.selectedIndex;
    if idx > 0 && idx <= length(items)
        ui.featureListBox.Value = items{idx};
    end
end

%% On feature selected from list
function onFeatureSelected(ui)
    if isempty(ui.featureListBox.Value)
        return;
    end

    % Parse index from selection
    selStr = ui.featureListBox.Value;
    dotPos = strfind(selStr, '.');
    if ~isempty(dotPos)
        idx = str2double(selStr(1:dotPos(1)-1));
        ui.fig.UserData.selectedIndex = idx;

        features = ui.fig.UserData.features;
        if idx > 0 && idx <= length(features)
            loadFeatureToEditor(ui, features{idx});
        end
    end
end

%% Load feature to editor
function loadFeatureToEditor(ui, feature)
    ui.nameEdit.Value = feature.Name;
    ui.versionEdit.Value = feature.Version;
    ui.typeDropdown.Value = getFeatureTypeName(feature.GeometricFeatureType);

    % 3D Operations
    ui.extrudeCheck.Value = any(feature.ThreeDimOperations == 0);
    ui.revolveCheck.Value = any(feature.ThreeDimOperations == 1);
    ui.sweepCheck.Value = any(feature.ThreeDimOperations == 2);
    ui.loftCheck.Value = any(feature.ThreeDimOperations == 3);

    % Reset dimensions
    ui.widthEdit.Value = 0;
    ui.heightEdit.Value = 0;
    ui.depthEdit.Value = 0;
    ui.radiusEdit.Value = 0;
    ui.angleEdit.Value = 0;

    % Load dimensions
    for i = 1:length(feature.MyDimensions)
        dim = feature.MyDimensions{i};
        if isfield(dim, 'Name') && isfield(dim, 'DimensionNominalValue')
            name = lower(dim.Name);
            val = dim.DimensionNominalValue;

            if contains(name, 'width') || contains(name, 'diameter')
                ui.widthEdit.Value = val;
            elseif contains(name, 'height') || contains(name, 'length')
                ui.heightEdit.Value = val;
            elseif contains(name, 'depth')
                ui.depthEdit.Value = val;
            elseif contains(name, 'radius')
                ui.radiusEdit.Value = val;
            elseif contains(name, 'angle')
                ui.angleEdit.Value = val;
            end
        end
    end

    % Update JSON preview
    jsonStr = jsonencode(feature, 'PrettyPrint', true);
    ui.jsonArea.Value = jsonStr;
end

%% Clear editor fields
function clearEditor(ui)
    ui.nameEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.typeDropdown.Value = 'Hole';
    ui.extrudeCheck.Value = false;
    ui.revolveCheck.Value = false;
    ui.sweepCheck.Value = false;
    ui.loftCheck.Value = false;
    ui.widthEdit.Value = 0;
    ui.heightEdit.Value = 0;
    ui.depthEdit.Value = 0;
    ui.radiusEdit.Value = 0;
    ui.angleEdit.Value = 0;
    ui.jsonArea.Value = '';
end

%% Update current feature from editor
function updateCurrentFeature(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'No feature selected!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    try
        feature = struct();
        feature.Name = ui.nameEdit.Value;
        feature.Version = ui.versionEdit.Value;
        feature.GeometricFeatureType = getFeatureTypeEnum(ui.typeDropdown.Value);

        % 3D Operations
        ops = [];
        if ui.extrudeCheck.Value, ops(end+1) = 0; end
        if ui.revolveCheck.Value, ops(end+1) = 1; end
        if ui.sweepCheck.Value, ops(end+1) = 2; end
        if ui.loftCheck.Value, ops(end+1) = 3; end
        feature.ThreeDimOperations = ops;

        % Build dimensions
        feature.MyDimensions = {};
        if ui.widthEdit.Value ~= 0
            feature.MyDimensions{end+1} = createDimension('Width', ui.widthEdit.Value, ui.widthUnits.Value, 0);
        end
        if ui.heightEdit.Value ~= 0
            feature.MyDimensions{end+1} = createDimension('Height', ui.heightEdit.Value, ui.heightUnits.Value, 0);
        end
        if ui.depthEdit.Value ~= 0
            feature.MyDimensions{end+1} = createDimension('Depth', ui.depthEdit.Value, ui.depthUnits.Value, 4);
        end
        if ui.radiusEdit.Value ~= 0
            feature.MyDimensions{end+1} = createDimension('Radius', ui.radiusEdit.Value, ui.radiusUnits.Value, 2);
        end
        if ui.angleEdit.Value ~= 0
            feature.MyDimensions{end+1} = createDimension('Angle', ui.angleEdit.Value, ui.angleUnits.Value, 3);
        end

        % Empty collections
        feature.Sketches = {};
        feature.Stations = {};
        feature.MyFeatures = {};
        feature.MyLibraries = {};

        % Update storage
        features = ui.fig.UserData.features;
        features{idx} = feature;
        ui.fig.UserData.features = features;

        updateFeatureList(ui);

        % Update JSON preview
        jsonStr = jsonencode(feature, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        ui.statusLabel.Text = 'Feature updated!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Import features from JSON
function importFeatures(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Import Features');
    if filename == 0
        return;
    end

    try
        filePath = fullfile(pathname, filename);
        jsonStr = fileread(filePath);
        imported = jsondecode(jsonStr);

        % Handle single feature or array
        if isstruct(imported) && ~isfield(imported, 'Features')
            % Single feature
            features = ui.fig.UserData.features;
            features{end+1} = imported;
            ui.fig.UserData.features = features;
        elseif isfield(imported, 'Features')
            % Feature collection
            for i = 1:length(imported.Features)
                features = ui.fig.UserData.features;
                features{end+1} = imported.Features(i);
                ui.fig.UserData.features = features;
            end
        end

        updateFeatureList(ui);

        ui.statusLabel.Text = 'Features imported!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Import error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Export all features to JSON
function exportAllFeatures(ui)
    features = ui.fig.UserData.features;
    if isempty(features)
        ui.statusLabel.Text = 'No features to export!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Export All Features', 'CAD_Features.json');
    if filename == 0
        return;
    end

    try
        % Create collection struct
        collection = struct();
        collection.ExportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        collection.FeatureCount = length(features);
        collection.Features = features;

        jsonStr = jsonencode(collection, 'PrettyPrint', true);

        filePath = fullfile(pathname, filename);
        fid = fopen(filePath, 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = sprintf('Exported %d features!', length(features));
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Export error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Save single feature to file
function saveFeatureToFile(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a feature first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    features = ui.fig.UserData.features;
    feature = features{idx};

    defaultName = 'CAD_Feature.json';
    if ~isempty(feature.Name)
        defaultName = [feature.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Feature', defaultName);
    if filename == 0
        return;
    end

    try
        jsonStr = jsonencode(feature, 'PrettyPrint', true);

        filePath = fullfile(pathname, filename);
        fid = fopen(filePath, 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = ['Saved: ' filename];
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Save error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end
