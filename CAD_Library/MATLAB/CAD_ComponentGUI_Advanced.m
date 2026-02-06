%% CAD_ComponentGUI_Advanced.m
% Advanced MATLAB GUI for managing CAD_Component objects
%
% Usage:
%   CAD_ComponentGUI_Advanced()              - Opens the GUI
%   components = CAD_ComponentGUI_Advanced() - Opens GUI and returns component list
%
% Features:
%   - Create and manage multiple components
%   - Joint management
%   - Mass property calculations
%   - WBS hierarchy visualization

function varargout = CAD_ComponentGUI_Advanced()
    % Create the main figure
    fig = uifigure('Name', 'CAD Component Manager (Advanced)', ...
                   'Position', [50 50 1000 800], ...
                   'Resize', 'on');

    % Store data in figure's UserData
    data = struct();
    data.components = {};
    data.selectedIndex = 0;
    fig.UserData = data;

    % Create main grid layout
    mainGL = uigridlayout(fig, [1, 2]);
    mainGL.ColumnWidth = {'0.30x', '0.70x'};
    mainGL.Padding = [10 10 10 10];

    % Left panel - Component list
    leftPanel = uipanel(mainGL, 'Title', 'Components');
    leftGL = uigridlayout(leftPanel, [5, 1]);
    leftGL.RowHeight = {'1x', 35, 35, 35, 35};
    leftGL.Padding = [5 5 5 5];

    % Component listbox
    componentListBox = uilistbox(leftGL, 'Items', {});

    % Quick-add buttons
    quickBtnPanel = uigridlayout(leftGL, [1, 3]);
    quickBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    quickBtnPanel.Padding = [0 0 0 0];

    newCompBtn = uibutton(quickBtnPanel, 'Text', 'New Component', ...
                          'BackgroundColor', [0.3 0.6 0.3]);
    duplicateBtn = uibutton(quickBtnPanel, 'Text', 'Duplicate', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    deleteBtn = uibutton(quickBtnPanel, 'Text', 'Delete', ...
                         'BackgroundColor', [0.7 0.3 0.3]);

    % Template buttons
    templatePanel = uigridlayout(leftGL, [1, 3]);
    templatePanel.ColumnWidth = {'1x', '1x', '1x'};
    templatePanel.Padding = [0 0 0 0];

    structuralBtn = uibutton(templatePanel, 'Text', 'Structural', ...
                             'BackgroundColor', [0.6 0.8 0.6]);
    mechanicalBtn = uibutton(templatePanel, 'Text', 'Mechanical', ...
                             'BackgroundColor', [0.6 0.8 0.6]);
    electricalBtn = uibutton(templatePanel, 'Text', 'Electrical', ...
                             'BackgroundColor', [0.6 0.8 0.6]);

    % Import/Export
    ioBtnPanel = uigridlayout(leftGL, [1, 2]);
    ioBtnPanel.ColumnWidth = {'1x', '1x'};
    ioBtnPanel.Padding = [0 0 0 0];

    importBtn = uibutton(ioBtnPanel, 'Text', 'Import JSON', ...
                         'BackgroundColor', [0.4 0.6 0.8]);
    exportBtn = uibutton(ioBtnPanel, 'Text', 'Export All', ...
                         'BackgroundColor', [0.6 0.4 0.8]);

    % Load part button
    loadPartBtn = uibutton(leftGL, 'Text', 'Load Part as Component', ...
                           'BackgroundColor', [0.8 0.6 0.4]);

    % Right panel - Component editor with tabs
    rightPanel = uipanel(mainGL, 'Title', 'Component Editor');
    rightGL = uigridlayout(rightPanel, [2, 1]);
    rightGL.RowHeight = {35, '1x'};
    rightGL.Padding = [5 5 5 5];

    % Status/action bar
    actionPanel = uigridlayout(rightGL, [1, 4]);
    actionPanel.ColumnWidth = {'1x', '1x', '1x', '2x'};
    actionPanel.Padding = [0 0 0 0];

    updateBtn = uibutton(actionPanel, 'Text', 'Update Component', ...
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
    basicGL = uigridlayout(basicTab, [10, 2]);
    basicGL.RowHeight = repmat({30}, 1, 10);
    basicGL.ColumnWidth = {'0.35x', '0.65x'};
    basicGL.Padding = [10 10 10 10];

    uilabel(basicGL, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(basicGL, 'text', 'Value', '');

    uilabel(basicGL, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(basicGL, 'text', 'Value', '1.0');

    uilabel(basicGL, 'Text', 'Path:', 'HorizontalAlignment', 'right');
    pathEdit = uieditfield(basicGL, 'text', 'Value', '');

    uilabel(basicGL, 'Text', 'Is Assembly:', 'HorizontalAlignment', 'right');
    isAssemblyCheck = uicheckbox(basicGL, 'Text', '', 'Value', false);

    uilabel(basicGL, 'Text', 'Is Config Item:', 'HorizontalAlignment', 'right');
    isConfigItemCheck = uicheckbox(basicGL, 'Text', '', 'Value', false);

    uilabel(basicGL, 'Text', 'WBS Level:', 'HorizontalAlignment', 'right');
    wbsLevelEdit = uieditfield(basicGL, 'numeric', 'Value', 1, ...
                               'Limits', [0 10], 'RoundFractionalValues', 'on');

    uilabel(basicGL, 'Text', 'Sketches:', 'HorizontalAlignment', 'right');
    sketchCountLabel = uilabel(basicGL, 'Text', '0 sketches');

    uilabel(basicGL, 'Text', 'Joints:', 'HorizontalAlignment', 'right');
    jointCountLabel = uilabel(basicGL, 'Text', '0 joints');

    uilabel(basicGL, 'Text', 'Features:', 'HorizontalAlignment', 'right');
    featureCountLabel = uilabel(basicGL, 'Text', '0 features');

    uilabel(basicGL, 'Text', 'Bodies:', 'HorizontalAlignment', 'right');
    bodyCountLabel = uilabel(basicGL, 'Text', '0 bodies');

    % Tab 2: Mass Properties
    massTab = uitab(tabGroup, 'Title', 'Mass Properties');
    massGL = uigridlayout(massTab, [10, 2]);
    massGL.RowHeight = repmat({30}, 1, 10);
    massGL.ColumnWidth = {'0.4x', '0.6x'};
    massGL.Padding = [10 10 10 10];

    uilabel(massGL, 'Text', 'Weight:', 'HorizontalAlignment', 'right');
    weightPanel = uigridlayout(massGL, [1, 2]);
    weightPanel.ColumnWidth = {'1x', 70};
    weightPanel.Padding = [0 0 0 0];
    weightEdit = uieditfield(weightPanel, 'numeric', 'Value', 0);
    weightUnits = uidropdown(weightPanel, 'Items', {'kg', 'g', 'lb', 'N'}, 'Value', 'kg');

    uilabel(massGL, 'Text', 'Ixx:', 'HorizontalAlignment', 'right');
    ixxEdit = uieditfield(massGL, 'numeric', 'Value', 0);

    uilabel(massGL, 'Text', 'Iyy:', 'HorizontalAlignment', 'right');
    iyyEdit = uieditfield(massGL, 'numeric', 'Value', 0);

    uilabel(massGL, 'Text', 'Izz:', 'HorizontalAlignment', 'right');
    izzEdit = uieditfield(massGL, 'numeric', 'Value', 0);

    uilabel(massGL, 'Text', 'Ixy:', 'HorizontalAlignment', 'right');
    ixyEdit = uieditfield(massGL, 'numeric', 'Value', 0);

    uilabel(massGL, 'Text', 'Ixz:', 'HorizontalAlignment', 'right');
    ixzEdit = uieditfield(massGL, 'numeric', 'Value', 0);

    uilabel(massGL, 'Text', 'Iyz:', 'HorizontalAlignment', 'right');
    iyzEdit = uieditfield(massGL, 'numeric', 'Value', 0);

    moiUnitsLabel = uilabel(massGL, 'Text', 'Units: kg*m^2', ...
                            'HorizontalAlignment', 'center', ...
                            'FontColor', [0.4 0.4 0.6]);
    moiUnitsLabel.Layout.Column = [1 2];

    % Principal directions
    uilabel(massGL, 'Text', 'Principal X:', 'HorizontalAlignment', 'right');
    principalXEdit = uieditfield(massGL, 'text', 'Value', '1, 0, 0');

    uilabel(massGL, 'Text', 'Principal Y:', 'HorizontalAlignment', 'right');
    principalYEdit = uieditfield(massGL, 'text', 'Value', '0, 1, 0');

    % Tab 3: Joints
    jointsTab = uitab(tabGroup, 'Title', 'Joints');
    jointsGL = uigridlayout(jointsTab, [3, 1]);
    jointsGL.RowHeight = {'1x', 35, 35};
    jointsGL.Padding = [10 10 10 10];

    jointListBox = uilistbox(jointsGL, 'Items', {});

    jointBtnPanel = uigridlayout(jointsGL, [1, 4]);
    jointBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    jointBtnPanel.Padding = [0 0 0 0];

    addJointBtn = uibutton(jointBtnPanel, 'Text', 'Add Joint', ...
                           'BackgroundColor', [0.3 0.6 0.3]);
    editJointBtn = uibutton(jointBtnPanel, 'Text', 'Edit', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    removeJointBtn = uibutton(jointBtnPanel, 'Text', 'Remove', ...
                              'BackgroundColor', [0.7 0.3 0.3]);
    jointTypeDropdown = uidropdown(jointBtnPanel, ...
        'Items', {'Rigid', 'Revolute', 'Slider', 'Cylindrical', 'PinSlot', ...
                  'Planar', 'InPlane', 'Ball', 'LeadScrew', 'Other'}, ...
        'Value', 'Rigid');

    jointSummaryLabel = uilabel(jointsGL, 'Text', 'Add joints to define component connections', ...
                                'HorizontalAlignment', 'center');

    % Tab 4: Sketches
    sketchesTab = uitab(tabGroup, 'Title', 'Sketches');
    sketchesGL = uigridlayout(sketchesTab, [3, 1]);
    sketchesGL.RowHeight = {'1x', 35, 35};
    sketchesGL.Padding = [10 10 10 10];

    sketchListBox = uilistbox(sketchesGL, 'Items', {});

    sketchBtnPanel = uigridlayout(sketchesGL, [1, 3]);
    sketchBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    sketchBtnPanel.Padding = [0 0 0 0];

    addSketchBtn = uibutton(sketchBtnPanel, 'Text', 'Add Sketch', ...
                            'BackgroundColor', [0.3 0.6 0.3]);
    editSketchBtn = uibutton(sketchBtnPanel, 'Text', 'Edit', ...
                             'BackgroundColor', [0.5 0.5 0.7]);
    removeSketchBtn = uibutton(sketchBtnPanel, 'Text', 'Remove', ...
                               'BackgroundColor', [0.7 0.3 0.3]);

    sketchSummaryLabel = uilabel(sketchesGL, 'Text', 'Add sketches for component geometry', ...
                                 'HorizontalAlignment', 'center');

    % Tab 5: JSON Preview
    jsonTab = uitab(tabGroup, 'Title', 'JSON');
    jsonGL = uigridlayout(jsonTab, [1, 1]);
    jsonGL.Padding = [10 10 10 10];

    jsonArea = uitextarea(jsonGL, 'Value', '', 'Editable', 'off', ...
                          'FontName', 'Consolas', 'FontSize', 9);

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.componentListBox = componentListBox;
    ui.nameEdit = nameEdit;
    ui.versionEdit = versionEdit;
    ui.pathEdit = pathEdit;
    ui.isAssemblyCheck = isAssemblyCheck;
    ui.isConfigItemCheck = isConfigItemCheck;
    ui.wbsLevelEdit = wbsLevelEdit;
    ui.sketchCountLabel = sketchCountLabel;
    ui.jointCountLabel = jointCountLabel;
    ui.featureCountLabel = featureCountLabel;
    ui.bodyCountLabel = bodyCountLabel;
    ui.weightEdit = weightEdit;
    ui.weightUnits = weightUnits;
    ui.ixxEdit = ixxEdit;
    ui.iyyEdit = iyyEdit;
    ui.izzEdit = izzEdit;
    ui.ixyEdit = ixyEdit;
    ui.ixzEdit = ixzEdit;
    ui.iyzEdit = iyzEdit;
    ui.principalXEdit = principalXEdit;
    ui.principalYEdit = principalYEdit;
    ui.jointListBox = jointListBox;
    ui.jointTypeDropdown = jointTypeDropdown;
    ui.jointSummaryLabel = jointSummaryLabel;
    ui.sketchListBox = sketchListBox;
    ui.sketchSummaryLabel = sketchSummaryLabel;
    ui.jsonArea = jsonArea;
    ui.statusLabel = statusLabel;

    % Set up callbacks
    componentListBox.ValueChangedFcn = @(~,~) onComponentSelected(ui);

    newCompBtn.ButtonPushedFcn = @(~,~) addNewComponent(ui);
    duplicateBtn.ButtonPushedFcn = @(~,~) duplicateComponent(ui);
    deleteBtn.ButtonPushedFcn = @(~,~) deleteComponent(ui);

    structuralBtn.ButtonPushedFcn = @(~,~) createTemplateComponent(ui, 'Structural');
    mechanicalBtn.ButtonPushedFcn = @(~,~) createTemplateComponent(ui, 'Mechanical');
    electricalBtn.ButtonPushedFcn = @(~,~) createTemplateComponent(ui, 'Electrical');

    importBtn.ButtonPushedFcn = @(~,~) importComponents(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportAllComponents(ui);
    loadPartBtn.ButtonPushedFcn = @(~,~) loadPartAsComponent(ui);

    updateBtn.ButtonPushedFcn = @(~,~) updateCurrentComponent(ui);
    saveFileBtn.ButtonPushedFcn = @(~,~) saveComponentToFile(ui);
    copyJsonBtn.ButtonPushedFcn = @(~,~) copyComponentJson(ui);

    addJointBtn.ButtonPushedFcn = @(~,~) addJoint(ui);
    editJointBtn.ButtonPushedFcn = @(~,~) editJoint(ui);
    removeJointBtn.ButtonPushedFcn = @(~,~) removeJoint(ui);

    addSketchBtn.ButtonPushedFcn = @(~,~) addSketch(ui);
    editSketchBtn.ButtonPushedFcn = @(~,~) editSketch(ui);
    removeSketchBtn.ButtonPushedFcn = @(~,~) removeSketch(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.components;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Create default component struct
function comp = createDefaultComponent()
    comp = struct();
    comp.Name = '';
    comp.Version = '1.0';
    comp.Path = '';
    comp.IsAssembly = false;
    comp.IsConfigurationItem = false;
    comp.WBS_Level = 1;

    comp.Weight = struct();
    comp.Weight.Name = 'Weight';
    comp.Weight.Value = struct('DoubleValue', 0, 'ValueType', 0);
    comp.Weight.MyUnits = struct('UnitName', 'kg');

    comp.MomentsOfInertia = {};
    comp.PrincipleDirections = {};

    comp.MySketches = {};
    comp.MyJoints = {};
    comp.MyFeatures = {};
    comp.MyBodies = {};
    comp.MyDrawings = {};
    comp.MyDimensions = {};
    comp.MyParameters = {};
end

%% Add new component
function addNewComponent(ui)
    components = ui.fig.UserData.components;

    comp = createDefaultComponent();
    comp.Name = sprintf('Component_%d', length(components) + 1);

    components{end+1} = comp;
    ui.fig.UserData.components = components;
    ui.fig.UserData.selectedIndex = length(components);

    updateComponentList(ui);
    loadComponentToEditor(ui, comp);

    ui.statusLabel.Text = 'New component added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Create template component
function createTemplateComponent(ui, templateType)
    components = ui.fig.UserData.components;

    comp = createDefaultComponent();
    comp.Name = sprintf('%s_%d', templateType, length(components) + 1);

    switch templateType
        case 'Structural'
            comp.WBS_Level = 2;
            comp.Weight.Value.DoubleValue = 5.0;
            % Add a rigid joint
            joint = struct();
            joint.Name = 'Mount_Joint';
            joint.JointType = 0; % Rigid
            comp.MyJoints{1} = joint;

        case 'Mechanical'
            comp.WBS_Level = 3;
            comp.Weight.Value.DoubleValue = 2.5;
            % Add a revolute joint
            joint = struct();
            joint.Name = 'Pivot_Joint';
            joint.JointType = 1; % Revolute
            comp.MyJoints{1} = joint;

        case 'Electrical'
            comp.WBS_Level = 4;
            comp.Weight.Value.DoubleValue = 0.5;
            comp.IsConfigurationItem = true;
    end

    components{end+1} = comp;
    ui.fig.UserData.components = components;
    ui.fig.UserData.selectedIndex = length(components);

    updateComponentList(ui);
    loadComponentToEditor(ui, comp);

    ui.statusLabel.Text = sprintf('%s component created', templateType);
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Update component list display
function updateComponentList(ui)
    components = ui.fig.UserData.components;
    items = cell(1, length(components));

    for i = 1:length(components)
        c = components{i};
        wbs = '';
        if isfield(c, 'WBS_Level')
            wbs = sprintf(' [WBS:%d]', c.WBS_Level);
        end
        items{i} = sprintf('%d. %s%s', i, c.Name, wbs);
    end

    ui.componentListBox.Items = items;

    idx = ui.fig.UserData.selectedIndex;
    if idx > 0 && idx <= length(items)
        ui.componentListBox.Value = items{idx};
    end
end

%% On component selected
function onComponentSelected(ui)
    if isempty(ui.componentListBox.Value)
        return;
    end

    selStr = ui.componentListBox.Value;
    dotPos = strfind(selStr, '.');
    if ~isempty(dotPos)
        idx = str2double(selStr(1:dotPos(1)-1));
        ui.fig.UserData.selectedIndex = idx;

        components = ui.fig.UserData.components;
        if idx > 0 && idx <= length(components)
            loadComponentToEditor(ui, components{idx});
        end
    end
end

%% Load component to editor
function loadComponentToEditor(ui, comp)
    % Basic info
    ui.nameEdit.Value = comp.Name;
    ui.versionEdit.Value = comp.Version;
    ui.pathEdit.Value = comp.Path;
    ui.isAssemblyCheck.Value = comp.IsAssembly;
    ui.isConfigItemCheck.Value = comp.IsConfigurationItem;
    ui.wbsLevelEdit.Value = comp.WBS_Level;

    % Counts
    ui.sketchCountLabel.Text = sprintf('%d sketches', length(comp.MySketches));
    ui.jointCountLabel.Text = sprintf('%d joints', length(comp.MyJoints));
    ui.featureCountLabel.Text = sprintf('%d features', length(comp.MyFeatures));
    ui.bodyCountLabel.Text = sprintf('%d bodies', length(comp.MyBodies));

    % Weight
    if isfield(comp, 'Weight') && isfield(comp.Weight, 'Value')
        ui.weightEdit.Value = comp.Weight.Value.DoubleValue;
        if isfield(comp.Weight, 'MyUnits')
            ui.weightUnits.Value = comp.Weight.MyUnits.UnitName;
        end
    end

    % MOI - initialize to 0
    ui.ixxEdit.Value = 0;
    ui.iyyEdit.Value = 0;
    ui.izzEdit.Value = 0;
    ui.ixyEdit.Value = 0;
    ui.ixzEdit.Value = 0;
    ui.iyzEdit.Value = 0;

    if isfield(comp, 'MomentsOfInertia')
        for i = 1:length(comp.MomentsOfInertia)
            moi = comp.MomentsOfInertia{i};
            if isfield(moi, 'Name') && isfield(moi, 'Value')
                val = moi.Value.DoubleValue;
                switch moi.Name
                    case 'Ixx', ui.ixxEdit.Value = val;
                    case 'Iyy', ui.iyyEdit.Value = val;
                    case 'Izz', ui.izzEdit.Value = val;
                    case 'Ixy', ui.ixyEdit.Value = val;
                    case 'Ixz', ui.ixzEdit.Value = val;
                    case 'Iyz', ui.iyzEdit.Value = val;
                end
            end
        end
    end

    % Principal directions
    if isfield(comp, 'PrincipleDirections') && length(comp.PrincipleDirections) >= 2
        pd1 = comp.PrincipleDirections{1};
        pd2 = comp.PrincipleDirections{2};
        ui.principalXEdit.Value = sprintf('%.4g, %.4g, %.4g', pd1.X, pd1.Y, pd1.Z);
        ui.principalYEdit.Value = sprintf('%.4g, %.4g, %.4g', pd2.X, pd2.Y, pd2.Z);
    end

    % Joint list
    jointItems = {};
    for i = 1:length(comp.MyJoints)
        j = comp.MyJoints{i};
        jtype = getJointTypeName(j.JointType);
        jointItems{i} = sprintf('%d. %s (%s)', i, j.Name, jtype);
    end
    ui.jointListBox.Items = jointItems;

    % Sketch list
    sketchItems = {};
    for i = 1:length(comp.MySketches)
        s = comp.MySketches{i};
        if isfield(s, 'Name')
            sketchItems{i} = sprintf('%d. %s', i, s.Name);
        else
            sketchItems{i} = sprintf('%d. Sketch_%d', i, i);
        end
    end
    ui.sketchListBox.Items = sketchItems;

    % JSON preview
    jsonStr = jsonencode(comp, 'PrettyPrint', true);
    ui.jsonArea.Value = jsonStr;
end

%% Get joint type name
function name = getJointTypeName(typeVal)
    types = {'Rigid', 'Revolute', 'Slider', 'Cylindrical', 'PinSlot', ...
             'Planar', 'InPlane', 'Ball', 'LeadScrew', 'Other'};
    if typeVal >= 0 && typeVal < length(types)
        name = types{typeVal + 1};
    else
        name = 'Other';
    end
end

%% Get joint type value
function val = getJointTypeValue(name)
    types = containers.Map(...
        {'Rigid', 'Revolute', 'Slider', 'Cylindrical', 'PinSlot', ...
         'Planar', 'InPlane', 'Ball', 'LeadScrew', 'Other'}, ...
        {0, 1, 2, 3, 4, 5, 6, 7, 8, 9});
    val = types(name);
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

%% Update current component
function updateCurrentComponent(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'No component selected!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    try
        components = ui.fig.UserData.components;
        comp = components{idx};

        % Basic info
        comp.Name = ui.nameEdit.Value;
        comp.Version = ui.versionEdit.Value;
        comp.Path = ui.pathEdit.Value;
        comp.IsAssembly = ui.isAssemblyCheck.Value;
        comp.IsConfigurationItem = ui.isConfigItemCheck.Value;
        comp.WBS_Level = ui.wbsLevelEdit.Value;

        % Weight
        comp.Weight.Value.DoubleValue = ui.weightEdit.Value;
        comp.Weight.MyUnits.UnitName = ui.weightUnits.Value;

        % MOI
        comp.MomentsOfInertia = {};
        moiNames = {'Ixx', 'Iyy', 'Izz', 'Ixy', 'Ixz', 'Iyz'};
        moiEdits = {ui.ixxEdit, ui.iyyEdit, ui.izzEdit, ui.ixyEdit, ui.ixzEdit, ui.iyzEdit};
        for i = 1:6
            if moiEdits{i}.Value ~= 0
                moi = struct();
                moi.Name = moiNames{i};
                moi.Value = struct('DoubleValue', moiEdits{i}.Value, 'ValueType', 0);
                moi.MyUnits = struct('UnitName', 'kg*m^2');
                comp.MomentsOfInertia{end+1} = moi;
            end
        end

        % Principal directions
        comp.PrincipleDirections = {};
        comp.PrincipleDirections{1} = parseVector(ui.principalXEdit.Value);
        comp.PrincipleDirections{2} = parseVector(ui.principalYEdit.Value);
        comp.PrincipleDirections{3} = struct('X', 0, 'Y', 0, 'Z', 1);

        % Save back
        components{idx} = comp;
        ui.fig.UserData.components = components;

        updateComponentList(ui);

        jsonStr = jsonencode(comp, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        ui.statusLabel.Text = 'Component updated!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Duplicate component
function duplicateComponent(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a component first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    components = ui.fig.UserData.components;
    newComp = components{idx};
    newComp.Name = [newComp.Name '_copy'];

    components{end+1} = newComp;
    ui.fig.UserData.components = components;
    ui.fig.UserData.selectedIndex = length(components);

    updateComponentList(ui);
    loadComponentToEditor(ui, newComp);

    ui.statusLabel.Text = 'Component duplicated';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Delete component
function deleteComponent(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a component first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    components = ui.fig.UserData.components;
    components(idx) = [];
    ui.fig.UserData.components = components;

    if idx > length(components)
        idx = length(components);
    end
    ui.fig.UserData.selectedIndex = idx;

    updateComponentList(ui);

    if idx > 0
        loadComponentToEditor(ui, components{idx});
    else
        clearEditor(ui);
    end

    ui.statusLabel.Text = 'Component deleted';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Clear editor
function clearEditor(ui)
    ui.nameEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.pathEdit.Value = '';
    ui.isAssemblyCheck.Value = false;
    ui.isConfigItemCheck.Value = false;
    ui.wbsLevelEdit.Value = 1;
    ui.weightEdit.Value = 0;
    ui.ixxEdit.Value = 0;
    ui.iyyEdit.Value = 0;
    ui.izzEdit.Value = 0;
    ui.jointListBox.Items = {};
    ui.sketchListBox.Items = {};
    ui.jsonArea.Value = '';
end

%% Add joint
function addJoint(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a component first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    components = ui.fig.UserData.components;
    comp = components{idx};

    joint = struct();
    joint.Name = sprintf('Joint_%d', length(comp.MyJoints) + 1);
    joint.JointType = getJointTypeValue(ui.jointTypeDropdown.Value);

    comp.MyJoints{end+1} = joint;
    components{idx} = comp;
    ui.fig.UserData.components = components;

    loadComponentToEditor(ui, comp);

    ui.statusLabel.Text = 'Joint added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit joint (placeholder)
function editJoint(ui)
    ui.statusLabel.Text = 'Joint editing: select type from dropdown before adding';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove joint
function removeJoint(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    jointSel = ui.jointListBox.Value;
    if isempty(jointSel)
        ui.statusLabel.Text = 'Select a joint first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(jointSel, '.');
    if isempty(dotPos), return; end
    jointIdx = str2double(jointSel(1:dotPos(1)-1));

    components = ui.fig.UserData.components;
    comp = components{idx};
    comp.MyJoints(jointIdx) = [];
    components{idx} = comp;
    ui.fig.UserData.components = components;

    loadComponentToEditor(ui, comp);

    ui.statusLabel.Text = 'Joint removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Add sketch
function addSketch(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a component first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    components = ui.fig.UserData.components;
    comp = components{idx};

    sketch = struct();
    sketch.Name = sprintf('Sketch_%d', length(comp.MySketches) + 1);
    sketch.Elements = {};

    comp.MySketches{end+1} = sketch;
    components{idx} = comp;
    ui.fig.UserData.components = components;

    loadComponentToEditor(ui, comp);

    ui.statusLabel.Text = 'Sketch added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit sketch (placeholder)
function editSketch(ui)
    ui.statusLabel.Text = 'Sketch editing not yet implemented';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove sketch
function removeSketch(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    sketchSel = ui.sketchListBox.Value;
    if isempty(sketchSel)
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(sketchSel, '.');
    if isempty(dotPos), return; end
    sketchIdx = str2double(sketchSel(1:dotPos(1)-1));

    components = ui.fig.UserData.components;
    comp = components{idx};
    comp.MySketches(sketchIdx) = [];
    components{idx} = comp;
    ui.fig.UserData.components = components;

    loadComponentToEditor(ui, comp);

    ui.statusLabel.Text = 'Sketch removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Load part as component
function loadPartAsComponent(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files'}, 'Select Part JSON');
    if filename == 0, return; end

    try
        jsonStr = fileread(fullfile(pathname, filename));
        part = jsondecode(jsonStr);

        comp = createDefaultComponent();
        if isfield(part, 'Name')
            comp.Name = part.Name;
        end
        if isfield(part, 'Version')
            comp.Version = part.Version;
        end
        comp.MyPart = part;

        components = ui.fig.UserData.components;
        components{end+1} = comp;
        ui.fig.UserData.components = components;
        ui.fig.UserData.selectedIndex = length(components);

        updateComponentList(ui);
        loadComponentToEditor(ui, comp);

        ui.statusLabel.Text = 'Part loaded as component';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Import components
function importComponents(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files'}, 'Import Components');
    if filename == 0, return; end

    try
        jsonStr = fileread(fullfile(pathname, filename));
        imported = jsondecode(jsonStr);

        if isfield(imported, 'Components')
            for i = 1:length(imported.Components)
                components = ui.fig.UserData.components;
                components{end+1} = imported.Components(i);
                ui.fig.UserData.components = components;
            end
        else
            components = ui.fig.UserData.components;
            components{end+1} = imported;
            ui.fig.UserData.components = components;
        end

        updateComponentList(ui);
        ui.statusLabel.Text = 'Components imported!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Import error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Export all components
function exportAllComponents(ui)
    components = ui.fig.UserData.components;
    if isempty(components)
        ui.statusLabel.Text = 'No components to export!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Export All Components', 'CAD_Components.json');
    if filename == 0, return; end

    try
        collection = struct();
        collection.ExportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        collection.ComponentCount = length(components);
        collection.Components = components;

        jsonStr = jsonencode(collection, 'PrettyPrint', true);
        fid = fopen(fullfile(pathname, filename), 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = sprintf('Exported %d components!', length(components));
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Export error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Save component to file
function saveComponentToFile(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a component first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    components = ui.fig.UserData.components;
    comp = components{idx};

    defaultName = [comp.Name '.json'];

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Save Component', defaultName);
    if filename == 0, return; end

    try
        jsonStr = jsonencode(comp, 'PrettyPrint', true);
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

%% Copy component JSON
function copyComponentJson(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a component first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    components = ui.fig.UserData.components;
    comp = components{idx};

    jsonStr = jsonencode(comp, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end
