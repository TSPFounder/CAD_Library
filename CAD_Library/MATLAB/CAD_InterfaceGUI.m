%% CAD_InterfaceGUI.m
% MATLAB GUI for creating and editing CAD_Interface objects
%
% Usage:
%   CAD_InterfaceGUI()              - Opens the GUI
%   iface = CAD_InterfaceGUI()      - Opens GUI and returns created interface
%
% CAD_Interface represents interface definitions between CAD components,
% including contact points, contact surfaces, and component associations.

function varargout = CAD_InterfaceGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Interface Creator', ...
                   'Position', [100 100 550 650], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.interface = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [18, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 14), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Interface Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Name
    uilabel(gl, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Interface name');

    % Row 3: ID
    uilabel(gl, 'Text', 'ID:', 'HorizontalAlignment', 'right');
    idEdit = uieditfield(gl, 'text', 'Value', '', ...
                         'Placeholder', 'e.g., IF-001');

    % Row 4: Version
    uilabel(gl, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(gl, 'text', 'Value', '1.0', ...
                              'Placeholder', 'e.g., 1.0');

    % Row 5: Interface Type
    uilabel(gl, 'Text', 'Interface Type:', 'HorizontalAlignment', 'right');
    typeDropdown = uidropdown(gl, ...
                              'Items', {'Joint', 'ElectricalConnector', 'Other'}, ...
                              'Value', 'Joint');

    % Row 6: Contact Geometry header
    contactHeader = uilabel(gl, 'Text', '── Contact Geometry ──', ...
                            'HorizontalAlignment', 'center', ...
                            'FontWeight', 'bold', ...
                            'FontColor', [0.3 0.3 0.6]);
    contactHeader.Layout.Column = [1 2];

    % Row 7: Contact Points count
    uilabel(gl, 'Text', 'Contact Points:', 'HorizontalAlignment', 'right');
    pointsLabel = uilabel(gl, 'Text', '0 points', ...
                          'FontColor', [0.4 0.4 0.4]);

    % Row 8: Contact Surfaces count
    uilabel(gl, 'Text', 'Contact Surfaces:', 'HorizontalAlignment', 'right');
    surfacesLabel = uilabel(gl, 'Text', '0 surfaces', ...
                            'FontColor', [0.4 0.4 0.4]);

    % Row 9: Associations header
    assocHeader = uilabel(gl, 'Text', '── Component Associations ──', ...
                          'HorizontalAlignment', 'center', ...
                          'FontWeight', 'bold', ...
                          'FontColor', [0.3 0.3 0.6]);
    assocHeader.Layout.Column = [1 2];

    % Row 10: Base Component
    uilabel(gl, 'Text', 'Base Component:', 'HorizontalAlignment', 'right');
    baseCompEdit = uieditfield(gl, 'text', 'Value', '', ...
                               'Placeholder', 'Component name or ID');

    % Row 11: Mating Component
    uilabel(gl, 'Text', 'Mating Component:', 'HorizontalAlignment', 'right');
    matingCompEdit = uieditfield(gl, 'text', 'Value', '', ...
                                 'Placeholder', 'Component name or ID');

    % Row 12: Joint Reference
    uilabel(gl, 'Text', 'Joint Reference:', 'HorizontalAlignment', 'right');
    jointRefEdit = uieditfield(gl, 'text', 'Value', '', ...
                               'Placeholder', 'Joint name or ID');

    % Row 13: Current Contact header
    currHeader = uilabel(gl, 'Text', '── Current Contact Point ──', ...
                         'HorizontalAlignment', 'center', ...
                         'FontWeight', 'bold', ...
                         'FontColor', [0.3 0.3 0.6]);
    currHeader.Layout.Column = [1 2];

    % Row 14: X coordinate
    uilabel(gl, 'Text', 'X:', 'HorizontalAlignment', 'right');
    xPanel = uigridlayout(gl, [1, 2]);
    xPanel.ColumnWidth = {'1x', 60};
    xPanel.Padding = [0 0 0 0];
    xEdit = uieditfield(xPanel, 'numeric', 'Value', 0);
    uilabel(xPanel, 'Text', 'mm');

    % Row 15: Y coordinate
    uilabel(gl, 'Text', 'Y:', 'HorizontalAlignment', 'right');
    yPanel = uigridlayout(gl, [1, 2]);
    yPanel.ColumnWidth = {'1x', 60};
    yPanel.Padding = [0 0 0 0];
    yEdit = uieditfield(yPanel, 'numeric', 'Value', 0);
    uilabel(yPanel, 'Text', 'mm');

    % Row 16: Buttons
    buttonPanel = uigridlayout(gl, [1, 4]);
    buttonPanel.Layout.Row = 16;
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

    % Row 17: Status label
    statusLabel = uilabel(gl, 'Text', 'Ready', ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.2 0.2 0.8]);
    statusLabel.Layout.Column = [1 2];

    % Row 18: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 18;
    jsonArea.Layout.Column = [1 2];

    % Row 19: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 19;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.nameEdit = nameEdit;
    ui.idEdit = idEdit;
    ui.versionEdit = versionEdit;
    ui.typeDropdown = typeDropdown;
    ui.pointsLabel = pointsLabel;
    ui.surfacesLabel = surfacesLabel;
    ui.baseCompEdit = baseCompEdit;
    ui.matingCompEdit = matingCompEdit;
    ui.jointRefEdit = jointRefEdit;
    ui.xEdit = xEdit;
    ui.yEdit = yEdit;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createInterface(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.interface;
            close(fig);
        else
            varargout{1} = [];
        end
    end
end

%% Create Interface callback
function createInterface(ui)
    try
        % Build the interface struct
        iface = struct();

        % Identification
        iface.Name = ui.nameEdit.Value;
        iface.ID = ui.idEdit.Value;
        iface.Version = ui.versionEdit.Value;

        % Interface type
        typeMap = containers.Map(...
            {'Joint', 'ElectricalConnector', 'Other'}, ...
            {0, 1, 2});
        iface.InterfaceKind = typeMap(ui.typeDropdown.Value);

        % Contact geometry - initialize as empty collections
        iface.MyContactPoints = {};
        iface.MyContactSurfaces = {};

        % Add current contact point if coordinates are not zero
        if ui.xEdit.Value ~= 0 || ui.yEdit.Value ~= 0
            pt = struct();
            pt.X = ui.xEdit.Value;
            pt.Y = ui.yEdit.Value;
            pt.Z = 0;
            iface.CurrentContactPoint = pt;
            iface.MyContactPoints = {pt};
            ui.pointsLabel.Text = '1 point';
        else
            iface.CurrentContactPoint = [];
        end

        % Component associations
        if ~isempty(ui.baseCompEdit.Value)
            iface.BaseComponent = struct('Name', ui.baseCompEdit.Value);
        end
        if ~isempty(ui.matingCompEdit.Value)
            iface.MatingComponent = struct('Name', ui.matingCompEdit.Value);
        end
        if ~isempty(ui.jointRefEdit.Value)
            iface.MyJoint = struct('Name', ui.jointRefEdit.Value);
        end

        % Store in figure UserData
        ui.fig.UserData.interface = iface;

        % Generate JSON preview
        jsonStr = jsonencode(iface, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Interface created successfully!';
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
    ui.typeDropdown.Value = 'Joint';
    ui.pointsLabel.Text = '0 points';
    ui.surfacesLabel.Text = '0 surfaces';
    ui.baseCompEdit.Value = '';
    ui.matingCompEdit.Value = '';
    ui.jointRefEdit.Value = '';
    ui.xEdit.Value = 0;
    ui.yEdit.Value = 0;
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.interface = [];
end

%% Export JSON callback
function exportJSON(ui)
    iface = ui.fig.UserData.interface;
    if isempty(iface)
        ui.statusLabel.Text = 'No interface created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(iface, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    iface = ui.fig.UserData.interface;
    if isempty(iface)
        ui.statusLabel.Text = 'No interface created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Interface.json';
    if isfield(iface, 'ID') && ~isempty(iface.ID)
        defaultName = [iface.ID '.json'];
    elseif isfield(iface, 'Name') && ~isempty(iface.Name)
        defaultName = [iface.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Interface JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(iface, 'PrettyPrint', true);

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
