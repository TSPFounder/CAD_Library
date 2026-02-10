%% CAD_JointGUI.m
% MATLAB GUI for creating and editing CAD_Joint objects
%
% Usage:
%   CAD_JointGUI()              - Opens the GUI
%   joint = CAD_JointGUI()      - Opens GUI and returns created joint
%
% CAD_Joint represents kinematic joints between CAD components,
% with joint type, degrees of freedom, coordinate system,
% a base component (stationary reference), and a joining/mating component.

function varargout = CAD_JointGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Joint Creator', ...
                   'Position', [100 100 650 900], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.joint = [];
    data.dbPath = '';
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [24, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 20), 10, 100, 35];
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

    % Row 12: Base Component header
    baseHeader = uilabel(gl, 'Text', '── Base Component ──', ...
                         'HorizontalAlignment', 'center', ...
                         'FontWeight', 'bold', ...
                         'FontColor', [0.3 0.3 0.6]);
    baseHeader.Layout.Column = [1 2];

    % Row 13: Base Component Name
    uilabel(gl, 'Text', 'Base Name:', 'HorizontalAlignment', 'right');
    baseNameEdit = uieditfield(gl, 'text', 'Value', '', ...
                               'Placeholder', 'Base component name');

    % Row 14: Base Component ID
    uilabel(gl, 'Text', 'Base ID:', 'HorizontalAlignment', 'right');
    baseIDEdit = uieditfield(gl, 'text', 'Value', '', ...
                             'Placeholder', 'e.g., COMP-001');

    % Row 15: Joining Component header
    joiningHeader = uilabel(gl, 'Text', '── Joining Component ──', ...
                            'HorizontalAlignment', 'center', ...
                            'FontWeight', 'bold', ...
                            'FontColor', [0.3 0.3 0.6]);
    joiningHeader.Layout.Column = [1 2];

    % Row 16: Joining Component Name
    uilabel(gl, 'Text', 'Joining Name:', 'HorizontalAlignment', 'right');
    joiningNameEdit = uieditfield(gl, 'text', 'Value', '', ...
                                  'Placeholder', 'Joining component name');

    % Row 17: Joining Component ID
    uilabel(gl, 'Text', 'Joining ID:', 'HorizontalAlignment', 'right');
    joiningIDEdit = uieditfield(gl, 'text', 'Value', '', ...
                                'Placeholder', 'e.g., COMP-002');

    % Row 18: Validation header
    validHeader = uilabel(gl, 'Text', '── Validation ──', ...
                          'HorizontalAlignment', 'center', ...
                          'FontWeight', 'bold', ...
                          'FontColor', [0.3 0.3 0.6]);
    validHeader.Layout.Column = [1 2];

    % Row 19: Is Valid
    uilabel(gl, 'Text', 'Is Valid:', 'HorizontalAlignment', 'right');
    validLabel = uilabel(gl, 'Text', 'Unknown', ...
                         'FontColor', [0.4 0.4 0.4]);

    % Row 20: Validation message
    uilabel(gl, 'Text', 'Reason:', 'HorizontalAlignment', 'right');
    reasonLabel = uilabel(gl, 'Text', '', ...
                          'FontColor', [0.6 0.4 0.4]);

    % Row 21: Buttons
    buttonPanel = uigridlayout(gl, [1, 5]);
    buttonPanel.Layout.Row = 21;
    buttonPanel.Layout.Column = [1 2];
    buttonPanel.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
    buttonPanel.Padding = [0 0 0 0];

    createBtn = uibutton(buttonPanel, 'Text', 'Create', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    clearBtn = uibutton(buttonPanel, 'Text', 'Clear', ...
                        'BackgroundColor', [0.8 0.8 0.2]);
    exportBtn = uibutton(buttonPanel, 'Text', 'Copy JSON', ...
                         'BackgroundColor', [0.3 0.5 0.7]);
    saveBtn = uibutton(buttonPanel, 'Text', 'Save File', ...
                       'BackgroundColor', [0.5 0.3 0.7]);
    saveDbBtn = uibutton(buttonPanel, 'Text', 'Save DB', ...
                         'BackgroundColor', [0.2 0.5 0.6]);

    % Row 22: Status label
    statusLabel = uilabel(gl, 'Text', 'Ready', ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.2 0.2 0.8]);
    statusLabel.Layout.Column = [1 2];

    % Row 23: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 23;
    jsonArea.Layout.Column = [1 2];

    % Row 24: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 24;
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
    ui.baseNameEdit = baseNameEdit;
    ui.baseIDEdit = baseIDEdit;
    ui.joiningNameEdit = joiningNameEdit;
    ui.joiningIDEdit = joiningIDEdit;
    ui.validLabel = validLabel;
    ui.reasonLabel = reasonLabel;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createJoint(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    saveDbBtn.ButtonPushedFcn = @(~,~) saveToDatabase(ui);
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
        % Build a CAD_Joint struct matching the C# CAD_Joint : CAD_Interface hierarchy

        joint = struct();

        % ── CAD_Interface inherited properties ──

        % Identification (inherited from CAD_Interface, overridden in CAD_Joint)
        joint.Name = ui.nameEdit.Value;
        joint.ID = ui.idEdit.Value;
        joint.Version = ui.versionEdit.Value;

        % InterfaceKind (CAD_Interface.InterfaceType: Joint=0)
        joint.InterfaceKind = 0;

        % Contact geometry (inherited from CAD_Interface)
        joint.CurrentContactPoint = [];
        joint.MyContactPoints = {};
        joint.CurrentContactSurface = [];
        joint.MyContactSurfaces = {};

        % BaseComponent (inherited from CAD_Interface)
        if ~isempty(ui.baseNameEdit.Value) || ~isempty(ui.baseIDEdit.Value)
            joint.BaseComponent = createComponentStub(...
                ui.baseNameEdit.Value, ui.baseIDEdit.Value);
        else
            joint.BaseComponent = [];
        end

        % MatingComponent (inherited from CAD_Interface)
        if ~isempty(ui.joiningNameEdit.Value) || ~isempty(ui.joiningIDEdit.Value)
            joint.MatingComponent = createComponentStub(...
                ui.joiningNameEdit.Value, ui.joiningIDEdit.Value);
        else
            joint.MatingComponent = [];
        end

        % ── CAD_Joint own properties ──

        % JointType (CAD_Joint.JointTypeEnum)
        jointTypeMap = containers.Map(...
            {'Rigid', 'Revolute', 'Slider', 'Cylindrical', 'PinSlot', ...
             'Planar', 'InPlane', 'Ball', 'LeadScrew', 'Other'}, ...
            {0, 1, 2, 3, 4, 5, 6, 7, 8, 9});
        joint.JointType = jointTypeMap(ui.jointTypeDropdown.Value);

        % ModelType (CAD_Joint.CAD_ModelTypeEnum)
        modelTypeMap = containers.Map(...
            {'SolidWorks', 'Fusion360', 'MechanicalDesktop', 'Simscape', ...
             'STEP', 'STL', 'FBX'}, ...
            {0, 1, 2, 3, 4, 5, 6});
        joint.ModelType = modelTypeMap(ui.modelTypeDropdown.Value);

        % DegreesOfFreedom (computed, matches C# switch expression)
        dofMap = containers.Map(...
            {'Rigid', 'Revolute', 'Slider', 'Cylindrical', 'PinSlot', ...
             'Planar', 'InPlane', 'Ball', 'LeadScrew', 'Other'}, ...
            {0, 1, 1, 2, 2, 3, 3, 3, 1, 0});
        joint.DegreesOfFreedom = dofMap(ui.jointTypeDropdown.Value);

        % MyCoordinateSystem (Mathematics.CoordinateSystem)
        joint.MyCoordinateSystem = createCoordinateSystem(...
            ui.originXEdit.Value, ui.originYEdit.Value, ui.originZEdit.Value);

        % IncludedComponents (List<CAD_Component>)
        joint.IncludedComponents = {};
        if ~isempty(joint.BaseComponent)
            joint.IncludedComponents{end+1} = joint.BaseComponent;
        end
        if ~isempty(joint.MatingComponent)
            joint.IncludedComponents{end+1} = joint.MatingComponent;
        end

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

    % Check base component
    if ~isfield(joint, 'BaseComponent') || isempty(joint.BaseComponent)
        isValid = false;
        reason = 'Missing base component';
        return;
    end

    % Check joining/mating component
    if ~isfield(joint, 'MatingComponent') || isempty(joint.MatingComponent)
        isValid = false;
        reason = 'Missing joining component';
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
    ui.baseNameEdit.Value = '';
    ui.baseIDEdit.Value = '';
    ui.joiningNameEdit.Value = '';
    ui.joiningIDEdit.Value = '';
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

%% Save to SQLite Database callback
function saveToDatabase(ui)
    joint = ui.fig.UserData.joint;
    if isempty(joint)
        ui.statusLabel.Text = 'No joint created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    try
        % Determine database path
        dbPath = ui.fig.UserData.dbPath;
        if isempty(dbPath)
            % Prompt user to select or create a .db file
            defaultName = 'CAD_Library.db';
            [filename, pathname] = uiputfile( ...
                {'*.db', 'SQLite Database (*.db)'}, ...
                'Select SQLite Database', defaultName);
            if filename == 0
                return;
            end
            dbPath = fullfile(pathname, filename);
            ui.fig.UserData.dbPath = dbPath;
        end

        % Open connection and ensure table exists
        conn = openDatabase(dbPath);
        cleanup = onCleanup(@() close(conn));

        % Build a flat MATLAB table row from the joint struct
        row = jointToTableRow(joint);

        % Delete existing row with same ID to allow upsert
        jointID = string(joint.ID);
        if strlength(jointID) > 0
            safeId = strrep(char(jointID), '''', '''''');
            execute(conn, ...
                ['DELETE FROM CAD_Joint WHERE ID = ''' safeId '''']);
        end

        % Insert the row
        sqlwrite(conn, 'CAD_Joint', row);

        ui.statusLabel.Text = ['Saved to DB: ' dbPath];
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['DB Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Open a SQLite database connection and ensure the CAD_Joint table exists
function conn = openDatabase(dbPath)
    % Connect (create file if it does not exist)
    if exist(dbPath, 'file')
        conn = sqlite(dbPath);
    else
        conn = sqlite(dbPath, 'create');
    end

    % Create the CAD_Joint table if it does not already exist
    createSQL = [ ...
        'CREATE TABLE IF NOT EXISTS CAD_Joint (' ...
        '  RowID               INTEGER PRIMARY KEY AUTOINCREMENT,' ...
        '  Name                TEXT,' ...
        '  ID                  TEXT UNIQUE,' ...
        '  Version             TEXT,' ...
        '  InterfaceKind       INTEGER DEFAULT 0,' ...
        '  JointType           INTEGER,' ...
        '  JointTypeName       TEXT,' ...
        '  ModelType           INTEGER,' ...
        '  ModelTypeName       TEXT,' ...
        '  DegreesOfFreedom    INTEGER,' ...
        '  OriginX             REAL,' ...
        '  OriginY             REAL,' ...
        '  OriginZ             REAL,' ...
        '  BaseComponentName   TEXT,' ...
        '  BaseComponentID     TEXT,' ...
        '  MatingComponentName TEXT,' ...
        '  MatingComponentID   TEXT,' ...
        '  JsonData            TEXT,' ...
        '  CreatedAt           TEXT' ...
        ')'];
    execute(conn, createSQL);
end

%% Convert a CAD_Joint struct into a single-row MATLAB table for sqlwrite
function row = jointToTableRow(joint)
    % Scalar identification
    Name                = string(joint.Name);
    ID                  = string(joint.ID);
    Version             = string(joint.Version);
    InterfaceKind       = int32(joint.InterfaceKind);

    % Joint data
    JointType           = int32(joint.JointType);
    JointTypeName       = jointTypeToString(joint.JointType);
    ModelType           = int32(joint.ModelType);
    ModelTypeName       = modelTypeToString(joint.ModelType);
    DegreesOfFreedom    = int32(joint.DegreesOfFreedom);

    % Coordinate system origin
    csys = joint.MyCoordinateSystem;
    if ~isempty(csys) && isfield(csys, 'OriginLocation') && ~isempty(csys.OriginLocation)
        OriginX = csys.OriginLocation.X_Value;
        OriginY = csys.OriginLocation.Y_Value;
        OriginZ = csys.OriginLocation.Z_Value_Cartesian;
    else
        OriginX = 0;
        OriginY = 0;
        OriginZ = 0;
    end

    % Base component
    if isstruct(joint.BaseComponent)
        BaseComponentName = string(joint.BaseComponent.Name);
        BaseComponentID   = string(joint.BaseComponent.PartNumber);
    else
        BaseComponentName = "";
        BaseComponentID   = "";
    end

    % Mating component
    if isstruct(joint.MatingComponent)
        MatingComponentName = string(joint.MatingComponent.Name);
        MatingComponentID   = string(joint.MatingComponent.PartNumber);
    else
        MatingComponentName = "";
        MatingComponentID   = "";
    end

    % Full JSON for round-trip fidelity
    JsonData = string(jsonencode(joint));

    % Timestamp
    CreatedAt = string(datestr(now, 'yyyy-mm-ddTHH:MM:SS')); %#ok<TNOW1,DATST>

    % Assemble into a MATLAB table
    row = table( ...
        Name, ID, Version, InterfaceKind, ...
        JointType, JointTypeName, ModelType, ModelTypeName, ...
        DegreesOfFreedom, ...
        OriginX, OriginY, OriginZ, ...
        BaseComponentName, BaseComponentID, ...
        MatingComponentName, MatingComponentID, ...
        JsonData, CreatedAt);
end

%% Map JointType enum integer to display string
function s = jointTypeToString(val)
    names = {'Rigid','Revolute','Slider','Cylindrical','PinSlot', ...
             'Planar','InPlane','Ball','LeadScrew','Other'};
    idx = val + 1;  % 0-based enum to 1-based index
    if idx >= 1 && idx <= numel(names)
        s = string(names{idx});
    else
        s = "Unknown";
    end
end

%% Map ModelType enum integer to display string
function s = modelTypeToString(val)
    names = {'SolidWorks','Fusion360','MechanicalDesktop','Simscape', ...
             'STEP','STL','FBX'};
    idx = val + 1;
    if idx >= 1 && idx <= numel(names)
        s = string(names{idx});
    else
        s = "Unknown";
    end
end

%% Create a Mathematics.Point struct (Cartesian)
function pt = createPoint(x, y, z)
    pt = struct();
    pt.PointID = '';
    pt.IsWeightPoint = false;
    pt.MyType = 0;  % Cartesian
    pt.Is2D = false;
    pt.X_Value = x;
    pt.Y_Value = y;
    pt.Z_Value_Cartesian = z;
    pt.R_Value_Cylindrical = 0;
    pt.Theta_Value_Cylindrical = 0;
    pt.Z_Value_Cylindrical = 0;
    pt.R_Value_Spherical = 0;
    pt.Theta_Value_Spherical = 0;
    pt.Phi_Value = 0;
    pt.Longitude = 0;
    pt.Latitude = 0;
    pt.Altitude = 0;
    pt.Real_Value = 0;
    pt.Complex_Value = 0;
    pt.CurrentCoordinateSystem = [];
    pt.MyCoordinateSystems = {};
    pt.CurrentConnectedPoint = [];
    pt.MyConnectedPoints = {};
end

%% Create a Mathematics.CoordinateSystem struct
function csys = createCoordinateSystem(originX, originY, originZ)
    csys = struct();
    csys.CoordinateSystemID = '';
    csys.Name = '';
    csys.MyType = 0;  % Cartesian
    csys.IsWCS = false;
    csys.Is2D = false;
    csys.OriginLocation = createPoint(originX, originY, originZ);
    csys.BaseVector = [];
    csys.Vectors = {};
    csys.My2DGeometry = {};
    csys.My3DGeometry = {};
end

%% Create a CAD_Component stub struct
function comp = createComponentStub(name, id)
    comp = struct();

    % Identification
    comp.Name = name;
    comp.Version = '';
    comp.Path = '';

    % Mass properties
    comp.Weight = [];
    comp.MomentsOfInertia = {};
    comp.PrincipleDirections = {};

    % Flags
    comp.IsAssembly = false;
    comp.IsConfigurationItem = false;

    % Associations
    comp.MyPart = [];
    comp.MySketches = {};
    comp.MyJoints = {};

    % Component data
    comp.WBS_Level = 0;

    % Inherited from CAD_Part
    comp.PartNumber = id;
    comp.Description = '';
    comp.CenterOfMass = [];
    comp.MyFeatures = {};
    comp.MyBodies = {};
    comp.MyDrawings = {};
    comp.MyDimensions = {};
    comp.MyParameters = {};
    comp.MyCoordinateSystems = {};
    comp.MyInterfaces = {};
    comp.AxialStations = {};
    comp.RadialStations = {};
    comp.AngularStations = {};
    comp.WingStations = {};
end
