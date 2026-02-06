%% CAD_DimensionGUI.m
% MATLAB GUI for creating and editing CAD_Dimension objects
%
% Usage:
%   CAD_DimensionGUI()              - Opens the GUI
%   dim = CAD_DimensionGUI()        - Opens GUI and returns created dimension
%
% The GUI allows you to:
%   - Enter all CAD_Dimension properties
%   - Create the dimension object
%   - Export to JSON
%   - Save JSON to file

function varargout = CAD_DimensionGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Dimension Creator', ...
                   'Position', [100 100 550 750], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.dimension = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [22, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 18), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Dimension Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Dimension ID
    uilabel(gl, 'Text', 'Dimension ID:', 'HorizontalAlignment', 'right');
    dimIdEdit = uieditfield(gl, 'text', 'Value', '', ...
                            'Placeholder', 'e.g., DIM_001');

    % Row 3: Name
    uilabel(gl, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Dimension name');

    % Row 4: Description
    uilabel(gl, 'Text', 'Description:', 'HorizontalAlignment', 'right');
    descEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Dimension description');

    % Row 5: Dimension Type
    uilabel(gl, 'Text', 'Dimension Type:', 'HorizontalAlignment', 'right');
    typeDropdown = uidropdown(gl, ...
                              'Items', {'Length', 'Diameter', 'Radius', 'Angle', 'Distance', 'Ordinal', 'Other'}, ...
                              'Value', 'Length');

    % Row 6: Is Ordinate
    uilabel(gl, 'Text', 'Is Ordinate:', 'HorizontalAlignment', 'right');
    isOrdinateCheckbox = uicheckbox(gl, 'Text', '', 'Value', false);

    % Row 7: Nominal Value
    uilabel(gl, 'Text', 'Nominal Value:', 'HorizontalAlignment', 'right');
    nominalPanel = uigridlayout(gl, [1, 2]);
    nominalPanel.ColumnWidth = {'1x', 80};
    nominalPanel.Padding = [0 0 0 0];
    nominalEdit = uieditfield(nominalPanel, 'numeric', 'Value', 0);
    unitsDropdown = uidropdown(nominalPanel, ...
                               'Items', {'mm', 'cm', 'm', 'in', 'ft', 'deg', 'rad'}, ...
                               'Value', 'mm');

    % Row 8: Upper Limit
    uilabel(gl, 'Text', 'Upper Limit:', 'HorizontalAlignment', 'right');
    upperLimitEdit = uieditfield(gl, 'numeric', 'Value', 0);

    % Row 9: Lower Limit
    uilabel(gl, 'Text', 'Lower Limit:', 'HorizontalAlignment', 'right');
    lowerLimitEdit = uieditfield(gl, 'numeric', 'Value', 0);

    % Row 10: Tolerance display
    uilabel(gl, 'Text', 'Tolerance:', 'HorizontalAlignment', 'right');
    toleranceLabel = uilabel(gl, 'Text', '± 0.000', ...
                             'FontColor', [0.2 0.5 0.7]);

    % Row 11: Section header - Points
    pointsHeader = uilabel(gl, 'Text', '── Points ──', ...
                           'HorizontalAlignment', 'center', ...
                           'FontWeight', 'bold', ...
                           'FontColor', [0.3 0.3 0.6]);
    pointsHeader.Layout.Column = [1 2];

    % Row 12: Center Point
    uilabel(gl, 'Text', 'Center Point:', 'HorizontalAlignment', 'right');
    centerPointEdit = uieditfield(gl, 'text', 'Value', '0, 0, 0', ...
                                  'Placeholder', 'X, Y, Z');

    % Row 13: Dimension Point
    uilabel(gl, 'Text', 'Dimension Point:', 'HorizontalAlignment', 'right');
    dimPointEdit = uieditfield(gl, 'text', 'Value', '0, 0, 0', ...
                               'Placeholder', 'X, Y, Z');

    % Row 14: Reference Point
    uilabel(gl, 'Text', 'Reference Point:', 'HorizontalAlignment', 'right');
    refPointEdit = uieditfield(gl, 'text', 'Value', '0, 0, 0', ...
                               'Placeholder', 'X, Y, Z');

    % Row 15: Leader Line End Point
    uilabel(gl, 'Text', 'Leader End Point:', 'HorizontalAlignment', 'right');
    leaderEndEdit = uieditfield(gl, 'text', 'Value', '', ...
                                'Placeholder', 'X, Y, Z (optional)');

    % Row 16: Leader Line Bend Point
    uilabel(gl, 'Text', 'Leader Bend Point:', 'HorizontalAlignment', 'right');
    leaderBendEdit = uieditfield(gl, 'text', 'Value', '', ...
                                 'Placeholder', 'X, Y, Z (optional)');

    % Row 17: Separator
    sep1 = uilabel(gl, 'Text', '');
    sep1.Layout.Column = [1 2];

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

    % Row 20: Separator
    sep2 = uilabel(gl, 'Text', '');
    sep2.Layout.Column = [1 2];

    % Row 21: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 21;
    jsonArea.Layout.Column = [1 2];

    % Row 22: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 22;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.dimIdEdit = dimIdEdit;
    ui.nameEdit = nameEdit;
    ui.descEdit = descEdit;
    ui.typeDropdown = typeDropdown;
    ui.isOrdinateCheckbox = isOrdinateCheckbox;
    ui.nominalEdit = nominalEdit;
    ui.unitsDropdown = unitsDropdown;
    ui.upperLimitEdit = upperLimitEdit;
    ui.lowerLimitEdit = lowerLimitEdit;
    ui.toleranceLabel = toleranceLabel;
    ui.centerPointEdit = centerPointEdit;
    ui.dimPointEdit = dimPointEdit;
    ui.refPointEdit = refPointEdit;
    ui.leaderEndEdit = leaderEndEdit;
    ui.leaderBendEdit = leaderBendEdit;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createDimension(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Update tolerance display when values change
    nominalEdit.ValueChangedFcn = @(~,~) updateToleranceDisplay(ui);
    upperLimitEdit.ValueChangedFcn = @(~,~) updateToleranceDisplay(ui);
    lowerLimitEdit.ValueChangedFcn = @(~,~) updateToleranceDisplay(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.dimension;
            close(fig);
        else
            varargout{1} = [];
        end
    end
end

%% Update tolerance display
function updateToleranceDisplay(ui)
    nominal = ui.nominalEdit.Value;
    upper = ui.upperLimitEdit.Value;
    lower = ui.lowerLimitEdit.Value;

    plusTol = upper - nominal;
    minusTol = nominal - lower;

    if abs(plusTol - minusTol) < 1e-10
        % Symmetric tolerance
        ui.toleranceLabel.Text = sprintf('± %.4g', plusTol);
    else
        % Asymmetric tolerance
        ui.toleranceLabel.Text = sprintf('+%.4g / -%.4g', plusTol, minusTol);
    end
end

%% Parse point string to struct
function point = parsePoint(str)
    point = struct();
    point.X_Value = 0;
    point.Y_Value = 0;
    point.Z_Value_Cartesian = 0;

    if isempty(str)
        return;
    end

    parts = strsplit(str, ',');
    if length(parts) >= 1
        point.X_Value = str2double(strtrim(parts{1}));
    end
    if length(parts) >= 2
        point.Y_Value = str2double(strtrim(parts{2}));
    end
    if length(parts) >= 3
        point.Z_Value_Cartesian = str2double(strtrim(parts{3}));
    end

    % Handle NaN
    if isnan(point.X_Value), point.X_Value = 0; end
    if isnan(point.Y_Value), point.Y_Value = 0; end
    if isnan(point.Z_Value_Cartesian), point.Z_Value_Cartesian = 0; end
end

%% Create Dimension callback
function createDimension(ui)
    try
        % Build the dimension struct
        dim = struct();

        % Identification
        if ~isempty(ui.dimIdEdit.Value)
            dim.DimensionID = ui.dimIdEdit.Value;
        else
            dim.DimensionID = ['DIM_' datestr(now, 'yyyymmddHHMMSS')];
        end

        dim.Name = ui.nameEdit.Value;
        dim.Description = ui.descEdit.Value;

        % Dimension type
        typeMap = containers.Map(...
            {'Length', 'Diameter', 'Radius', 'Angle', 'Distance', 'Ordinal', 'Other'}, ...
            {0, 1, 2, 3, 4, 5, 6});
        dim.MyDimensionType = typeMap(ui.typeDropdown.Value);

        % Drawing element type (Dimension = 1)
        dim.MyType = 1;

        % Ordinate flag
        dim.IsOrdinate = ui.isOrdinateCheckbox.Value;

        % Values
        dim.DimensionNominalValue = ui.nominalEdit.Value;
        dim.DimensionUpperLimitValue = ui.upperLimitEdit.Value;
        dim.DimensionLowerLimitValue = ui.lowerLimitEdit.Value;

        % Units
        dim.EngineeringUnit = struct('UnitName', ui.unitsDropdown.Value);

        % Points
        dim.CenterPoint = parsePoint(ui.centerPointEdit.Value);
        dim.DimensionPoint = parsePoint(ui.dimPointEdit.Value);
        dim.ReferencePoint = parsePoint(ui.refPointEdit.Value);

        if ~isempty(ui.leaderEndEdit.Value)
            dim.LeaderLineEndPoint = parsePoint(ui.leaderEndEdit.Value);
        end

        if ~isempty(ui.leaderBendEdit.Value)
            dim.LeaderLineBendPoint = parsePoint(ui.leaderBendEdit.Value);
        end

        % Initialize empty collections
        dim.MyParameters = {};
        dim.MyConstructionGeometry = {};

        % Store in figure UserData
        ui.fig.UserData.dimension = dim;

        % Generate JSON preview
        jsonStr = jsonencode(dim, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Dimension created successfully!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Clear Form callback
function clearForm(ui)
    ui.dimIdEdit.Value = '';
    ui.nameEdit.Value = '';
    ui.descEdit.Value = '';
    ui.typeDropdown.Value = 'Length';
    ui.isOrdinateCheckbox.Value = false;
    ui.nominalEdit.Value = 0;
    ui.unitsDropdown.Value = 'mm';
    ui.upperLimitEdit.Value = 0;
    ui.lowerLimitEdit.Value = 0;
    ui.toleranceLabel.Text = '± 0.000';
    ui.centerPointEdit.Value = '0, 0, 0';
    ui.dimPointEdit.Value = '0, 0, 0';
    ui.refPointEdit.Value = '0, 0, 0';
    ui.leaderEndEdit.Value = '';
    ui.leaderBendEdit.Value = '';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.dimension = [];
end

%% Export JSON callback
function exportJSON(ui)
    dim = ui.fig.UserData.dimension;
    if isempty(dim)
        ui.statusLabel.Text = 'No dimension created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(dim, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    dim = ui.fig.UserData.dimension;
    if isempty(dim)
        ui.statusLabel.Text = 'No dimension created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Dimension.json';
    if isfield(dim, 'DimensionID') && ~isempty(dim.DimensionID)
        defaultName = [dim.DimensionID '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Dimension JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(dim, 'PrettyPrint', true);

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
