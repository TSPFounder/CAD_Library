%% CAD_JointGUI.m
% MATLAB GUI for creating and editing CAD_Joint objects
%
% Usage:
%   CAD_JointGUI()              - Opens the GUI
%   joint = CAD_JointGUI()      - Opens GUI and returns created joint
%
% CAD_Joint represents kinematic joints between CAD components,
% with joint type, degrees of freedom, coordinate system, and component associations.

function varargout = CAD_JointGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Joint Creator', ...
                   'Position', [100 100 550 700], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.joint = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [20, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 16), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Joint Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Name
    uilabel(gl, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Joint name');

    % Row 3: ID
    uilabel(gl, 'Text', 'ID:', 'HorizontalAlignment', 'right');
    idEdit = uieditfield(gl, 'text', 'Value', '', ...
                         'Placeholder', 'e.g., JT-001');

    % Row 4: Version
    uilabel(gl, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(gl, 'text', 'Value', '1.0', ...
                              'Placeholder', 'e.g., 1.0');

    % Row 5: Joint Type
    uilabel(gl, 'Text', 'Joint Type:', 'HorizontalAlignment', 'right');
    jointTypeDropdown = uidropdown(gl, ...
        'Items', {'Rigid', 'Revolute', 'Slider', 'Cylindrical', 'PinSlot', ...
                  'Planar', 'InPlane', 'Ball', 'LeadScrew', 'Other'}, ...
        'Value', 'Rigid');

    % Row 6: DOF display
    uilabel(gl, 'Text', 'Degrees of Freedom:', 'HorizontalAlignment', 'right');
    dofLabel = uilabel(gl, 'Text', '0 DOF', ...
                       'FontWeight', 'bold', 'FontColor', [0.2 0.5 0.2]);

    % Row 7: Model Type
    uilabel(gl, 'Text', 'Model Type:', 'HorizontalAlignment', 'right');
    modelTypeDropdown = uidropdown(gl, ...
        'Items', {'SolidWorks', 'Fusion360', 'MechanicalDesktop', 'Simscape', ...
                  'STEP', 'STL', 'FBX'}, ...
        'Value', 'Fusion360');

    % Row 8: Coordinate System header
    csysHeader = uilabel(gl, 'Text', '── Coordinate System ──', ...
                         'HorizontalAlignment', 'center', ...
                         'FontWeight', 'bold', ...
                         'FontColor', [0.3 0.3 0.6]);
    csysHeader.Layout.Column = [1 2];

    % Row 9: Origin X
    uilabel(gl, 'Text', 'Origin X:', 'HorizontalAlignment', 'right');
    originXPanel = uigridlayout(gl, [1, 2]);
    originXPanel.ColumnWidth = {'1x', 60};
    originXPanel.Padding = [0 0 0 0];
    originXEdit = uieditfield(originXPanel, 'numeric', 'Value', 0);
    uilabel(originXPanel, 'Text', 'mm');

    % Row 10: Origin Y
    uilabel(gl, 'Text', 'Origin Y:', 'HorizontalAlignment', 'right');
    originYPanel = uigridlayout(gl, [1, 2]);
    originYPanel.ColumnWidth = {'1x', 60};
    originYPanel.Padding = [0 0 0 0];
    originYEdit = uieditfield(originYPanel, 'numeric', 'Value', 0);
    uilabel(originYPanel, 'Text', 'mm');

    % Row 11: Origin Z
    uilabel(gl, 'Text', 'Origin Z:', 'HorizontalAlignment', 'right');
    originZPanel = uigridlayout(gl, [1, 2]);
    originZPanel.ColumnWidth = {'1x', 60};
    originZPanel.Padding = [0 0 0 0];
    originZEdit = uieditfield(originZPanel, 'numeric', 'Value', 0);
    uilabel(originZPanel, 'Text', 'mm');

    % Row 12: Components header
    compHeader = uilabel(gl, 'Text', '── Included Components ──', ...
                         'HorizontalAlignment', 'center', ...
                         'FontWeight', 'bold', ...
                         'FontColor', [0.3 0.3 0.6]);
    compHeader.Layout.Column = [1 2];

    % Row 13: Component count
    uilabel(gl, 'Text', 'Components:', 'HorizontalAlignment', 'right');
    componentsLabel = uilabel(gl, 'Text', '0 components', ...
                              'FontColor', [0.4 0.4 0.4]);

    % Row 14: Validation header
    validHeader = uilabel(gl, 'Text', '── Validation ──', ...
                          'HorizontalAlignment', 'center', ...
                          'FontWeight', 'bold', ...
                          'FontColor', [0.3 0.3 0.6]);
    validHeader.Layout.Column = [1 2];

    % Row 15: Is Valid
    uilabel(gl, 'Text', 'Is Valid:', 'HorizontalAlignment', 'right');
    validLabel = uilabel(gl, 'Text', 'Unknown', ...
                         'FontColor', [0.4 0.4 0.4]);

    % Row 16: Validation message
    uilabel(gl, 'Text', 'Reason:', 'HorizontalAlignment', 'right');
    reasonLabel = uilabel(gl, 'Text', '', ...
                          'FontColor', [0.6 0.4 0.4]);

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
    jsonArea.Layout.Row = 19;
    jsonArea.Layout.Column = [1 2];

    % Row 20: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 20;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.nameEdit = nameEdit;
    ui.idEdit = idEdit;
    ui.versionEdit = versionEdit;
    ui.jointTypeDropdown = jointTypeDropdown;
    ui.dofLabel = dofLabel;
    ui.modelTypeDropdown = modelTypeDropdown;
    ui.originXEdit = originXEdit;
    ui.originYEdit = originYEdit;
    ui.originZEdit = originZEdit;
    ui.componentsLabel = componentsLabel;
    ui.validLabel = validLabel;
    ui.reasonLabel = reasonLabel;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createJoint(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);
    jointTypeDropdown.ValueChangedFcn = @(~,~) updateDOF(ui);

    % Initialize DOF display
    updateDOF(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.joint;
            close(fig);
        else
            varargout{1} = [];
        end
    end
end

%% Update DOF display based on joint type
function updateDOF(ui)
    jointType = ui.jointTypeDropdown.Value;

    % Map joint type to DOF
    dofMap = containers.Map(...
        {'Rigid', 'Revolute', 'Slider', 'Cylindrical', 'PinSlot', ...
         'Planar', 'InPlane', 'Ball', 'LeadScrew', 'Other'}, ...
        {0, 1, 1, 2, 2, 3, 3, 3, 1, 0});

    dof = dofMap(jointType);
    ui.dofLabel.Text = sprintf('%d DOF', dof);

    % Color code based on DOF
    if dof == 0
        ui.dofLabel.FontColor = [0.5 0.5 0.5];
    elseif dof == 1
        ui.dofLabel.FontColor = [0.2 0.6 0.2];
    elseif dof == 2
        ui.dofLabel.FontColor = [0.2 0.4 0.8];
    else
        ui.dofLabel.FontColor = [0.7 0.4 0.2];
    end
end

%% Create Joint callback
function createJoint(ui)
    try
        % Build the joint struct
        joint = struct();

        % Identification
        joint.Name = ui.nameEdit.Value;
        joint.ID = ui.idEdit.Value;
        joint.Version = ui.versionEdit.Value;

        % Joint type
        jointTypeMap = containers.Map(...
            {'Rigid', 'Revolute', 'Slider', 'Cylindrical', 'PinSlot', ...
             'Planar', 'InPlane', 'Ball', 'LeadScrew', 'Other'}, ...
            {0, 1, 2, 3, 4, 5, 6, 7, 8, 9});
        joint.JointType = jointTypeMap(ui.jointTypeDropdown.Value);

        % Model type
        modelTypeMap = containers.Map(...
            {'SolidWorks', 'Fusion360', 'MechanicalDesktop', 'Simscape', ...
             'STEP', 'STL', 'FBX'}, ...
            {0, 1, 2, 3, 4, 5, 6});
        joint.ModelType = modelTypeMap(ui.modelTypeDropdown.Value);

        % DOF (computed)
        dofMap = containers.Map(...
            {'Rigid', 'Revolute', 'Slider', 'Cylindrical', 'PinSlot', ...
             'Planar', 'InPlane', 'Ball', 'LeadScrew', 'Other'}, ...
            {0, 1, 1, 2, 2, 3, 3, 3, 1, 0});
        joint.DegreesOfFreedom = dofMap(ui.jointTypeDropdown.Value);

        % Coordinate system
        joint.MyCoordinateSystem = struct();
        joint.MyCoordinateSystem.Origin = struct();
        joint.MyCoordinateSystem.Origin.X = ui.originXEdit.Value;
        joint.MyCoordinateSystem.Origin.Y = ui.originYEdit.Value;
        joint.MyCoordinateSystem.Origin.Z = ui.originZEdit.Value;

        % Empty collections
        joint.IncludedComponents = {};

        % Validate
        [isValid, reason] = validateJoint(joint);
        if isValid
            ui.validLabel.Text = 'Valid';
            ui.validLabel.FontColor = [0.2 0.7 0.2];
            ui.reasonLabel.Text = '';
        else
            ui.validLabel.Text = 'Invalid';
            ui.validLabel.FontColor = [0.8 0.3 0.3];
            ui.reasonLabel.Text = reason;
        end

        % Store in figure UserData
        ui.fig.UserData.joint = joint;

        % Generate JSON preview
        jsonStr = jsonencode(joint, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Joint created successfully!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Validate joint
function [isValid, reason] = validateJoint(joint)
    % Check coordinate system
    if ~isfield(joint, 'MyCoordinateSystem') || isempty(joint.MyCoordinateSystem)
        isValid = false;
        reason = 'Missing coordinate system';
        return;
    end

    % Check included components (warning only for simple GUI)
    if ~isfield(joint, 'IncludedComponents') || isempty(joint.IncludedComponents)
        isValid = true;
        reason = 'No components (add in advanced mode)';
        return;
    end

    isValid = true;
    reason = '';
end

%% Clear Form callback
function clearForm(ui)
    ui.nameEdit.Value = '';
    ui.idEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.jointTypeDropdown.Value = 'Rigid';
    ui.modelTypeDropdown.Value = 'Fusion360';
    ui.originXEdit.Value = 0;
    ui.originYEdit.Value = 0;
    ui.originZEdit.Value = 0;
    ui.componentsLabel.Text = '0 components';
    ui.validLabel.Text = 'Unknown';
    ui.validLabel.FontColor = [0.4 0.4 0.4];
    ui.reasonLabel.Text = '';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.joint = [];
    updateDOF(ui);
end

%% Export JSON callback
function exportJSON(ui)
    joint = ui.fig.UserData.joint;
    if isempty(joint)
        ui.statusLabel.Text = 'No joint created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(joint, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    joint = ui.fig.UserData.joint;
    if isempty(joint)
        ui.statusLabel.Text = 'No joint created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Joint.json';
    if isfield(joint, 'ID') && ~isempty(joint.ID)
        defaultName = [joint.ID '.json'];
    elseif isfield(joint, 'Name') && ~isempty(joint.Name)
        defaultName = [joint.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Joint JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(joint, 'PrettyPrint', true);

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
