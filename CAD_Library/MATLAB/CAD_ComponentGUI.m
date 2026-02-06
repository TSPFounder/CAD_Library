%% CAD_ComponentGUI.m
% MATLAB GUI for creating and editing CAD_Component objects
%
% Usage:
%   CAD_ComponentGUI()              - Opens the GUI
%   component = CAD_ComponentGUI()  - Opens GUI and returns created component
%
% CAD_Component extends CAD_Part with additional properties:
%   - Weight, Moments of Inertia, Principal Directions
%   - Joints, WBS Level, IsAssembly flag

function varargout = CAD_ComponentGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Component Creator', ...
                   'Position', [100 100 550 750], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.component = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [21, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 17), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Component Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Name
    uilabel(gl, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Component name');

    % Row 3: Version
    uilabel(gl, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(gl, 'text', 'Value', '1.0', ...
                              'Placeholder', 'e.g., 1.0');

    % Row 4: Path
    uilabel(gl, 'Text', 'Path:', 'HorizontalAlignment', 'right');
    pathEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'File path (optional)');

    % Row 5: Flags header
    flagsHeader = uilabel(gl, 'Text', '── Component Flags ──', ...
                          'HorizontalAlignment', 'center', ...
                          'FontWeight', 'bold', ...
                          'FontColor', [0.3 0.3 0.6]);
    flagsHeader.Layout.Column = [1 2];

    % Row 6: Is Assembly
    uilabel(gl, 'Text', 'Is Assembly:', 'HorizontalAlignment', 'right');
    isAssemblyCheck = uicheckbox(gl, 'Text', '', 'Value', false);

    % Row 7: Is Configuration Item
    uilabel(gl, 'Text', 'Is Config Item:', 'HorizontalAlignment', 'right');
    isConfigItemCheck = uicheckbox(gl, 'Text', '', 'Value', false);

    % Row 8: WBS Level
    uilabel(gl, 'Text', 'WBS Level:', 'HorizontalAlignment', 'right');
    wbsLevelEdit = uieditfield(gl, 'numeric', 'Value', 1, ...
                               'Limits', [0 10], 'RoundFractionalValues', 'on');

    % Row 9: Mass properties header
    massHeader = uilabel(gl, 'Text', '── Mass Properties ──', ...
                         'HorizontalAlignment', 'center', ...
                         'FontWeight', 'bold', ...
                         'FontColor', [0.3 0.3 0.6]);
    massHeader.Layout.Column = [1 2];

    % Row 10: Weight
    uilabel(gl, 'Text', 'Weight:', 'HorizontalAlignment', 'right');
    weightPanel = uigridlayout(gl, [1, 2]);
    weightPanel.ColumnWidth = {'1x', 80};
    weightPanel.Padding = [0 0 0 0];
    weightEdit = uieditfield(weightPanel, 'numeric', 'Value', 0);
    weightUnits = uidropdown(weightPanel, ...
                             'Items', {'kg', 'g', 'lb', 'oz', 'N'}, ...
                             'Value', 'kg');

    % Row 11: Moments of Inertia
    uilabel(gl, 'Text', 'Moments of Inertia:', 'HorizontalAlignment', 'right');
    moiEdit = uieditfield(gl, 'text', 'Value', '', ...
                          'Placeholder', 'Ixx, Iyy, Izz (kg*m^2)');

    % Row 12: Principal Directions
    uilabel(gl, 'Text', 'Principal Dir X:', 'HorizontalAlignment', 'right');
    principalXEdit = uieditfield(gl, 'text', 'Value', '1, 0, 0', ...
                                 'Placeholder', 'X, Y, Z');

    % Row 13: Principal Y
    uilabel(gl, 'Text', 'Principal Dir Y:', 'HorizontalAlignment', 'right');
    principalYEdit = uieditfield(gl, 'text', 'Value', '0, 1, 0', ...
                                 'Placeholder', 'X, Y, Z');

    % Row 14: Principal Z
    uilabel(gl, 'Text', 'Principal Dir Z:', 'HorizontalAlignment', 'right');
    principalZEdit = uieditfield(gl, 'text', 'Value', '0, 0, 1', ...
                                 'Placeholder', 'X, Y, Z');

    % Row 15: Joints header
    jointsHeader = uilabel(gl, 'Text', '── Joints ──', ...
                           'HorizontalAlignment', 'center', ...
                           'FontWeight', 'bold', ...
                           'FontColor', [0.3 0.3 0.6]);
    jointsHeader.Layout.Column = [1 2];

    % Row 16: Joint count
    uilabel(gl, 'Text', 'Joints:', 'HorizontalAlignment', 'right');
    jointCountLabel = uilabel(gl, 'Text', '0 joints defined', ...
                              'FontColor', [0.4 0.4 0.4]);

    % Row 17: Sketches count
    uilabel(gl, 'Text', 'Sketches:', 'HorizontalAlignment', 'right');
    sketchCountLabel = uilabel(gl, 'Text', '0 sketches', ...
                               'FontColor', [0.4 0.4 0.4]);

    % Row 18: Buttons
    buttonPanel = uigridlayout(gl, [1, 4]);
    buttonPanel.Layout.Row = 18;
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

    % Row 19: Status label
    statusLabel = uilabel(gl, 'Text', 'Ready', ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.2 0.2 0.8]);
    statusLabel.Layout.Column = [1 2];

    % Row 20: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 20;
    jsonArea.Layout.Column = [1 2];

    % Row 21: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 21;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.nameEdit = nameEdit;
    ui.versionEdit = versionEdit;
    ui.pathEdit = pathEdit;
    ui.isAssemblyCheck = isAssemblyCheck;
    ui.isConfigItemCheck = isConfigItemCheck;
    ui.wbsLevelEdit = wbsLevelEdit;
    ui.weightEdit = weightEdit;
    ui.weightUnits = weightUnits;
    ui.moiEdit = moiEdit;
    ui.principalXEdit = principalXEdit;
    ui.principalYEdit = principalYEdit;
    ui.principalZEdit = principalZEdit;
    ui.jointCountLabel = jointCountLabel;
    ui.sketchCountLabel = sketchCountLabel;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createComponent(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.component;
            close(fig);
        else
            varargout{1} = [];
        end
    end
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

%% Parse MOI string to parameter list
function moi = parseMOI(str)
    moi = {};
    if isempty(str)
        return;
    end

    parts = strsplit(str, ',');
    names = {'Ixx', 'Iyy', 'Izz'};

    for i = 1:min(length(parts), 3)
        val = str2double(strtrim(parts{i}));
        if ~isnan(val)
            param = struct();
            param.Name = names{i};
            param.Value = struct('DoubleValue', val, 'ValueType', 0);
            param.MyUnits = struct('UnitName', 'kg*m^2');
            moi{end+1} = param;
        end
    end
end

%% Create Component callback
function createComponent(ui)
    try
        % Build the component struct
        comp = struct();

        % Identification
        comp.Name = ui.nameEdit.Value;
        comp.Version = ui.versionEdit.Value;
        comp.Path = ui.pathEdit.Value;

        % Flags
        comp.IsAssembly = ui.isAssemblyCheck.Value;
        comp.IsConfigurationItem = ui.isConfigItemCheck.Value;
        comp.WBS_Level = ui.wbsLevelEdit.Value;

        % Weight
        comp.Weight = struct();
        comp.Weight.Name = 'Weight';
        comp.Weight.Value = struct('DoubleValue', ui.weightEdit.Value, 'ValueType', 0);
        comp.Weight.MyUnits = struct('UnitName', ui.weightUnits.Value);

        % Moments of Inertia
        comp.MomentsOfInertia = parseMOI(ui.moiEdit.Value);

        % Principal Directions
        comp.PrincipleDirections = {};
        comp.PrincipleDirections{1} = parseVector(ui.principalXEdit.Value);
        comp.PrincipleDirections{2} = parseVector(ui.principalYEdit.Value);
        comp.PrincipleDirections{3} = parseVector(ui.principalZEdit.Value);

        % Initialize empty collections
        comp.MySketches = {};
        comp.MyJoints = {};

        % Inherited from CAD_Part
        comp.MyFeatures = {};
        comp.MyBodies = {};
        comp.MyDrawings = {};
        comp.MyDimensions = {};
        comp.MyParameters = {};

        % Store in figure UserData
        ui.fig.UserData.component = comp;

        % Generate JSON preview
        jsonStr = jsonencode(comp, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Component created successfully!';
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
    ui.pathEdit.Value = '';
    ui.isAssemblyCheck.Value = false;
    ui.isConfigItemCheck.Value = false;
    ui.wbsLevelEdit.Value = 1;
    ui.weightEdit.Value = 0;
    ui.weightUnits.Value = 'kg';
    ui.moiEdit.Value = '';
    ui.principalXEdit.Value = '1, 0, 0';
    ui.principalYEdit.Value = '0, 1, 0';
    ui.principalZEdit.Value = '0, 0, 1';
    ui.jointCountLabel.Text = '0 joints defined';
    ui.sketchCountLabel.Text = '0 sketches';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.component = [];
end

%% Export JSON callback
function exportJSON(ui)
    comp = ui.fig.UserData.component;
    if isempty(comp)
        ui.statusLabel.Text = 'No component created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(comp, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    comp = ui.fig.UserData.component;
    if isempty(comp)
        ui.statusLabel.Text = 'No component created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Component.json';
    if isfield(comp, 'Name') && ~isempty(comp.Name)
        defaultName = [comp.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Component JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(comp, 'PrettyPrint', true);

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
