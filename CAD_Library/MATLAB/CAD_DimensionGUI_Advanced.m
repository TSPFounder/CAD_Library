%% CAD_DimensionGUI_Advanced.m
% Advanced MATLAB GUI for creating and editing CAD_Dimension objects
% Includes load/save, batch creation, and dimension list management
%
% Usage:
%   CAD_DimensionGUI_Advanced()                    - Opens the GUI
%   dims = CAD_DimensionGUI_Advanced()             - Returns all created dimensions
%   CAD_DimensionGUI_Advanced(existingDims)        - Opens with existing dimensions

function varargout = CAD_DimensionGUI_Advanced(existingDims)
    if nargin < 1
        existingDims = {};
    end

    % Create the main figure
    fig = uifigure('Name', 'CAD Dimension Manager', ...
                   'Position', [50 50 1000 750], ...
                   'Resize', 'on');

    % Store data in figure's UserData
    data = struct();
    data.dimensions = existingDims;
    data.selectedIndex = 0;
    fig.UserData = data;

    % Create main grid layout
    mainGrid = uigridlayout(fig, [1, 2]);
    mainGrid.ColumnWidth = {'0.35x', '1x'};
    mainGrid.Padding = [10 10 10 10];

    %% Left Panel - Dimension List
    leftPanel = uipanel(mainGrid, 'Title', 'Dimensions');
    leftGrid = uigridlayout(leftPanel, [5, 1]);
    leftGrid.RowHeight = {'1x', 30, 30, 30, 25};

    % Dimension list box
    dimList = uilistbox(leftGrid, 'Items', {}, 'Value', {});

    % List control buttons
    listBtnPanel = uigridlayout(leftGrid, [1, 3]);
    listBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    listBtnPanel.Padding = [0 0 0 0];

    addBtn = uibutton(listBtnPanel, 'Text', '+ Add', ...
                      'BackgroundColor', [0.3 0.6 0.3]);
    duplicateBtn = uibutton(listBtnPanel, 'Text', 'Duplicate', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    deleteBtn = uibutton(listBtnPanel, 'Text', '- Delete', ...
                         'BackgroundColor', [0.7 0.3 0.3]);

    % Import/Export buttons
    ioBtnPanel = uigridlayout(leftGrid, [1, 2]);
    ioBtnPanel.ColumnWidth = {'1x', '1x'};
    ioBtnPanel.Padding = [0 0 0 0];

    importBtn = uibutton(ioBtnPanel, 'Text', 'Import JSON', ...
                         'BackgroundColor', [0.4 0.6 0.8]);
    exportAllBtn = uibutton(ioBtnPanel, 'Text', 'Export All', ...
                            'BackgroundColor', [0.6 0.4 0.8]);

    % Quick add panel
    quickPanel = uigridlayout(leftGrid, [1, 2]);
    quickPanel.ColumnWidth = {'1x', 80};
    quickPanel.Padding = [0 0 0 0];
    quickValueEdit = uieditfield(quickPanel, 'numeric', 'Value', 0, ...
                                 'Placeholder', 'Quick value');
    quickAddBtn = uibutton(quickPanel, 'Text', 'Quick+', ...
                           'BackgroundColor', [0.4 0.7 0.4]);

    % Count label
    countLabel = uilabel(leftGrid, 'Text', 'Total: 0 dimensions', ...
                         'HorizontalAlignment', 'center');

    %% Right Panel - Dimension Editor
    rightPanel = uipanel(mainGrid, 'Title', 'Dimension Editor');
    rightGrid = uigridlayout(rightPanel, [2, 1]);
    rightGrid.RowHeight = {'1x', '0.4x'};

    % Top section - form fields
    formGrid = uigridlayout(rightGrid, [12, 4]);
    formGrid.RowHeight = repmat({28}, 1, 12);
    formGrid.ColumnWidth = {'0.3x', '1x', '0.3x', '1x'};
    formGrid.Padding = [10 10 10 10];

    % Row 1: Dimension ID & Name
    uilabel(formGrid, 'Text', 'Dimension ID:', 'HorizontalAlignment', 'right');
    dimIdEdit = uieditfield(formGrid, 'text', 'Value', '', ...
                            'Placeholder', 'Auto-generated if empty');
    uilabel(formGrid, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(formGrid, 'text', 'Value', '', ...
                           'Placeholder', 'Dimension name');

    % Row 2: Description & Type
    uilabel(formGrid, 'Text', 'Description:', 'HorizontalAlignment', 'right');
    descEdit = uieditfield(formGrid, 'text', 'Value', '', ...
                           'Placeholder', 'Description');
    uilabel(formGrid, 'Text', 'Type:', 'HorizontalAlignment', 'right');
    typeDropdown = uidropdown(formGrid, ...
                              'Items', {'Length', 'Diameter', 'Radius', 'Angle', 'Distance', 'Ordinal', 'Other'}, ...
                              'Value', 'Length');

    % Row 3: Nominal Value & Units
    uilabel(formGrid, 'Text', 'Nominal Value:', 'HorizontalAlignment', 'right');
    nominalEdit = uieditfield(formGrid, 'numeric', 'Value', 0);
    uilabel(formGrid, 'Text', 'Units:', 'HorizontalAlignment', 'right');
    unitsDropdown = uidropdown(formGrid, ...
                               'Items', {'mm', 'cm', 'm', 'in', 'ft', 'deg', 'rad', 'μm', 'mil'}, ...
                               'Value', 'mm');

    % Row 4: Upper & Lower Limits
    uilabel(formGrid, 'Text', 'Upper Limit:', 'HorizontalAlignment', 'right');
    upperLimitEdit = uieditfield(formGrid, 'numeric', 'Value', 0);
    uilabel(formGrid, 'Text', 'Lower Limit:', 'HorizontalAlignment', 'right');
    lowerLimitEdit = uieditfield(formGrid, 'numeric', 'Value', 0);

    % Row 5: Tolerance display & Ordinate
    uilabel(formGrid, 'Text', 'Tolerance:', 'HorizontalAlignment', 'right');
    toleranceLabel = uilabel(formGrid, 'Text', '± 0.000', ...
                             'FontWeight', 'bold', 'FontColor', [0.2 0.5 0.7]);
    uilabel(formGrid, 'Text', 'Is Ordinate:', 'HorizontalAlignment', 'right');
    isOrdinateCheckbox = uicheckbox(formGrid, 'Text', '', 'Value', false);

    % Row 6: Section header - Points
    pointsHeader = uilabel(formGrid, 'Text', '── Geometry Points ──', ...
                           'FontWeight', 'bold', 'FontColor', [0.3 0.3 0.6]);
    pointsHeader.Layout.Column = [1 4];

    % Row 7: Center Point & Dimension Point
    uilabel(formGrid, 'Text', 'Center Point:', 'HorizontalAlignment', 'right');
    centerPointEdit = uieditfield(formGrid, 'text', 'Value', '0, 0, 0', ...
                                  'Placeholder', 'X, Y, Z');
    uilabel(formGrid, 'Text', 'Dimension Pt:', 'HorizontalAlignment', 'right');
    dimPointEdit = uieditfield(formGrid, 'text', 'Value', '0, 0, 0', ...
                               'Placeholder', 'X, Y, Z');

    % Row 8: Reference Point & Leader End
    uilabel(formGrid, 'Text', 'Reference Pt:', 'HorizontalAlignment', 'right');
    refPointEdit = uieditfield(formGrid, 'text', 'Value', '0, 0, 0', ...
                               'Placeholder', 'X, Y, Z');
    uilabel(formGrid, 'Text', 'Leader End:', 'HorizontalAlignment', 'right');
    leaderEndEdit = uieditfield(formGrid, 'text', 'Value', '', ...
                                'Placeholder', 'X, Y, Z (optional)');

    % Row 9: Leader Bend Point
    uilabel(formGrid, 'Text', 'Leader Bend:', 'HorizontalAlignment', 'right');
    leaderBendEdit = uieditfield(formGrid, 'text', 'Value', '', ...
                                 'Placeholder', 'X, Y, Z (optional)');
    % Empty cells for alignment
    uilabel(formGrid, 'Text', '');
    uilabel(formGrid, 'Text', '');

    % Row 10: Separator
    sep1 = uilabel(formGrid, 'Text', '');
    sep1.Layout.Column = [1 4];

    % Row 11: Action Buttons
    actionPanel = uigridlayout(formGrid, [1, 4]);
    actionPanel.Layout.Column = [1 4];
    actionPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    actionPanel.Padding = [0 0 0 0];

    saveBtn = uibutton(actionPanel, 'Text', 'Save Dimension', ...
                       'BackgroundColor', [0.2 0.6 0.2]);
    clearBtn = uibutton(actionPanel, 'Text', 'Clear Form', ...
                        'BackgroundColor', [0.8 0.7 0.2]);
    previewBtn = uibutton(actionPanel, 'Text', 'Preview JSON', ...
                          'BackgroundColor', [0.3 0.5 0.7]);
    calcBtn = uibutton(actionPanel, 'Text', 'Calc Tolerance', ...
                       'BackgroundColor', [0.5 0.5 0.8]);

    % Row 12: Status
    statusLabel = uilabel(formGrid, 'Text', 'Ready', ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.2 0.5 0.8]);
    statusLabel.Layout.Column = [1 4];

    % Bottom section - JSON Preview
    jsonPanel = uipanel(rightGrid, 'Title', 'JSON Preview');
    jsonGrid = uigridlayout(jsonPanel, [1, 1]);
    jsonArea = uitextarea(jsonGrid, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 10);

    %% Store UI components
    ui = struct();
    ui.fig = fig;
    ui.dimList = dimList;
    ui.countLabel = countLabel;
    ui.quickValueEdit = quickValueEdit;
    ui.dimIdEdit = dimIdEdit;
    ui.nameEdit = nameEdit;
    ui.descEdit = descEdit;
    ui.typeDropdown = typeDropdown;
    ui.nominalEdit = nominalEdit;
    ui.unitsDropdown = unitsDropdown;
    ui.upperLimitEdit = upperLimitEdit;
    ui.lowerLimitEdit = lowerLimitEdit;
    ui.toleranceLabel = toleranceLabel;
    ui.isOrdinateCheckbox = isOrdinateCheckbox;
    ui.centerPointEdit = centerPointEdit;
    ui.dimPointEdit = dimPointEdit;
    ui.refPointEdit = refPointEdit;
    ui.leaderEndEdit = leaderEndEdit;
    ui.leaderBendEdit = leaderBendEdit;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    %% Set up callbacks
    addBtn.ButtonPushedFcn = @(~,~) addNewDimension(ui);
    duplicateBtn.ButtonPushedFcn = @(~,~) duplicateDimension(ui);
    deleteBtn.ButtonPushedFcn = @(~,~) deleteDimension(ui);
    importBtn.ButtonPushedFcn = @(~,~) importDimensions(ui);
    exportAllBtn.ButtonPushedFcn = @(~,~) exportAllDimensions(ui);
    quickAddBtn.ButtonPushedFcn = @(~,~) quickAddDimension(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveCurrentDimension(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    previewBtn.ButtonPushedFcn = @(~,~) previewJSON(ui);
    calcBtn.ButtonPushedFcn = @(~,~) calculateTolerance(ui);
    dimList.ValueChangedFcn = @(~,~) loadSelectedDimension(ui);

    % Auto-update tolerance on value changes
    nominalEdit.ValueChangedFcn = @(~,~) updateToleranceDisplay(ui);
    upperLimitEdit.ValueChangedFcn = @(~,~) updateToleranceDisplay(ui);
    lowerLimitEdit.ValueChangedFcn = @(~,~) updateToleranceDisplay(ui);

    % Initialize with existing dimensions
    if ~isempty(existingDims)
        updateDimensionList(ui);
    end

    %% Wait for output if requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.dimensions;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Update dimension list display
function updateDimensionList(ui)
    dims = ui.fig.UserData.dimensions;
    if isempty(dims)
        ui.dimList.Items = {};
        ui.countLabel.Text = 'Total: 0 dimensions';
        return;
    end

    % Build display names
    names = cell(1, length(dims));
    for i = 1:length(dims)
        d = dims{i};

        % Get name or ID
        if isfield(d, 'Name') && ~isempty(d.Name)
            displayName = d.Name;
        elseif isfield(d, 'DimensionID') && ~isempty(d.DimensionID)
            displayName = d.DimensionID;
        else
            displayName = '(unnamed)';
        end

        % Get value
        if isfield(d, 'DimensionNominalValue')
            valStr = sprintf('%.4g', d.DimensionNominalValue);
        else
            valStr = '?';
        end

        % Get type indicator
        typeIndicators = {'L', 'Ø', 'R', '∠', 'D', 'O', '?'};
        if isfield(d, 'MyDimensionType') && d.MyDimensionType >= 0 && d.MyDimensionType <= 6
            typeStr = typeIndicators{d.MyDimensionType + 1};
        else
            typeStr = '?';
        end

        names{i} = sprintf('%d. [%s] %s = %s', i, typeStr, displayName, valStr);
    end

    ui.dimList.Items = names;
    ui.countLabel.Text = sprintf('Total: %d dimensions', length(dims));
end

%% Add new dimension
function addNewDimension(ui)
    clearForm(ui);
    ui.fig.UserData.selectedIndex = 0;
    ui.statusLabel.Text = 'Creating new dimension...';
    ui.statusLabel.FontColor = [0.2 0.5 0.8];
end

%% Quick add dimension
function quickAddDimension(ui)
    try
        dim = struct();
        dim.DimensionID = ['DIM_' datestr(now, 'yyyymmddHHMMSSFFF')];
        dim.Name = sprintf('Dim_%.4g', ui.quickValueEdit.Value);
        dim.MyDimensionType = 0; % Length
        dim.MyType = 1; % Dimension
        dim.DimensionNominalValue = ui.quickValueEdit.Value;
        dim.DimensionUpperLimitValue = ui.quickValueEdit.Value;
        dim.DimensionLowerLimitValue = ui.quickValueEdit.Value;
        dim.IsOrdinate = false;
        dim.CenterPoint = struct('X_Value', 0, 'Y_Value', 0, 'Z_Value_Cartesian', 0);
        dim.DimensionPoint = struct('X_Value', 0, 'Y_Value', 0, 'Z_Value_Cartesian', 0);
        dim.ReferencePoint = struct('X_Value', 0, 'Y_Value', 0, 'Z_Value_Cartesian', 0);
        dim.EngineeringUnit = struct('UnitName', ui.unitsDropdown.Value);
        dim.MyParameters = {};
        dim.MyConstructionGeometry = {};

        dims = ui.fig.UserData.dimensions;
        dims{end+1} = dim;
        ui.fig.UserData.dimensions = dims;
        updateDimensionList(ui);

        ui.statusLabel.Text = sprintf('Quick added: %.4g', ui.quickValueEdit.Value);
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Duplicate selected dimension
function duplicateDimension(ui)
    idx = getSelectedIndex(ui);
    if idx == 0
        ui.statusLabel.Text = 'Select a dimension to duplicate';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dims = ui.fig.UserData.dimensions;
    newDim = dims{idx};

    if isfield(newDim, 'Name') && ~isempty(newDim.Name)
        newDim.Name = [newDim.Name '_copy'];
    end
    if isfield(newDim, 'DimensionID') && ~isempty(newDim.DimensionID)
        newDim.DimensionID = [newDim.DimensionID '_copy'];
    end

    dims{end+1} = newDim;
    ui.fig.UserData.dimensions = dims;
    updateDimensionList(ui);

    ui.statusLabel.Text = 'Dimension duplicated';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Delete selected dimension
function deleteDimension(ui)
    idx = getSelectedIndex(ui);
    if idx == 0
        ui.statusLabel.Text = 'Select a dimension to delete';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dims = ui.fig.UserData.dimensions;
    dims(idx) = [];
    ui.fig.UserData.dimensions = dims;
    ui.fig.UserData.selectedIndex = 0;
    updateDimensionList(ui);
    clearForm(ui);

    ui.statusLabel.Text = 'Dimension deleted';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Get selected index
function idx = getSelectedIndex(ui)
    if isempty(ui.dimList.Value)
        idx = 0;
        return;
    end

    selected = ui.dimList.Value;
    if iscell(selected)
        selected = selected{1};
    end

    parts = strsplit(selected, '.');
    idx = str2double(parts{1});
    if isnan(idx)
        idx = 0;
    end
end

%% Load selected dimension into form
function loadSelectedDimension(ui)
    idx = getSelectedIndex(ui);
    if idx == 0 || idx > length(ui.fig.UserData.dimensions)
        return;
    end

    ui.fig.UserData.selectedIndex = idx;
    dim = ui.fig.UserData.dimensions{idx};

    % Populate form fields
    ui.dimIdEdit.Value = getFieldStr(dim, 'DimensionID');
    ui.nameEdit.Value = getFieldStr(dim, 'Name');
    ui.descEdit.Value = getFieldStr(dim, 'Description');

    % Type
    types = {'Length', 'Diameter', 'Radius', 'Angle', 'Distance', 'Ordinal', 'Other'};
    if isfield(dim, 'MyDimensionType') && dim.MyDimensionType >= 0 && dim.MyDimensionType <= 6
        ui.typeDropdown.Value = types{dim.MyDimensionType + 1};
    end

    % Values
    ui.nominalEdit.Value = getFieldNum(dim, 'DimensionNominalValue', 0);
    ui.upperLimitEdit.Value = getFieldNum(dim, 'DimensionUpperLimitValue', 0);
    ui.lowerLimitEdit.Value = getFieldNum(dim, 'DimensionLowerLimitValue', 0);

    % Units
    if isfield(dim, 'EngineeringUnit') && isfield(dim.EngineeringUnit, 'UnitName')
        ui.unitsDropdown.Value = dim.EngineeringUnit.UnitName;
    end

    % Ordinate
    ui.isOrdinateCheckbox.Value = getFieldNum(dim, 'IsOrdinate', 0) == 1;

    % Points
    ui.centerPointEdit.Value = pointToStr(dim, 'CenterPoint');
    ui.dimPointEdit.Value = pointToStr(dim, 'DimensionPoint');
    ui.refPointEdit.Value = pointToStr(dim, 'ReferencePoint');
    ui.leaderEndEdit.Value = pointToStr(dim, 'LeaderLineEndPoint');
    ui.leaderBendEdit.Value = pointToStr(dim, 'LeaderLineBendPoint');

    updateToleranceDisplay(ui);
    previewJSON(ui);

    ui.statusLabel.Text = sprintf('Loaded: %s', getFieldStr(dim, 'DimensionID'));
    ui.statusLabel.FontColor = [0.2 0.5 0.8];
end

%% Helper functions
function str = getFieldStr(s, field)
    if isfield(s, field) && ~isempty(s.(field))
        str = s.(field);
    else
        str = '';
    end
end

function val = getFieldNum(s, field, default)
    if isfield(s, field) && ~isempty(s.(field))
        val = s.(field);
    else
        val = default;
    end
end

function str = pointToStr(s, field)
    if isfield(s, field) && ~isempty(s.(field))
        pt = s.(field);
        x = getFieldNum(pt, 'X_Value', 0);
        y = getFieldNum(pt, 'Y_Value', 0);
        z = getFieldNum(pt, 'Z_Value_Cartesian', 0);
        str = sprintf('%g, %g, %g', x, y, z);
    else
        str = '';
    end
end

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

%% Update tolerance display
function updateToleranceDisplay(ui)
    nominal = ui.nominalEdit.Value;
    upper = ui.upperLimitEdit.Value;
    lower = ui.lowerLimitEdit.Value;

    plusTol = upper - nominal;
    minusTol = nominal - lower;

    if abs(plusTol - minusTol) < 1e-10
        ui.toleranceLabel.Text = sprintf('± %.4g', plusTol);
    else
        ui.toleranceLabel.Text = sprintf('+%.4g / -%.4g', plusTol, minusTol);
    end
end

%% Calculate tolerance from nominal
function calculateTolerance(ui)
    nominal = ui.nominalEdit.Value;

    % Simple tolerance calculation based on ISO 2768-m (medium)
    if nominal <= 3
        tol = 0.1;
    elseif nominal <= 6
        tol = 0.1;
    elseif nominal <= 30
        tol = 0.2;
    elseif nominal <= 120
        tol = 0.3;
    elseif nominal <= 400
        tol = 0.5;
    elseif nominal <= 1000
        tol = 0.8;
    else
        tol = 1.2;
    end

    ui.upperLimitEdit.Value = nominal + tol;
    ui.lowerLimitEdit.Value = nominal - tol;
    updateToleranceDisplay(ui);

    ui.statusLabel.Text = sprintf('Calculated ISO 2768-m tolerance: ± %.3g', tol);
    ui.statusLabel.FontColor = [0.2 0.6 0.6];
end

%% Save current dimension
function saveCurrentDimension(ui)
    try
        dim = buildDimensionFromForm(ui);

        dims = ui.fig.UserData.dimensions;
        idx = ui.fig.UserData.selectedIndex;

        if idx > 0 && idx <= length(dims)
            dims{idx} = dim;
            ui.statusLabel.Text = sprintf('Updated: %s', dim.DimensionID);
        else
            dims{end+1} = dim;
            ui.fig.UserData.selectedIndex = length(dims);
            ui.statusLabel.Text = sprintf('Created: %s', dim.DimensionID);
        end

        ui.fig.UserData.dimensions = dims;
        updateDimensionList(ui);
        previewJSON(ui);

        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Build dimension struct from form
function dim = buildDimensionFromForm(ui)
    dim = struct();

    % ID
    if ~isempty(ui.dimIdEdit.Value)
        dim.DimensionID = ui.dimIdEdit.Value;
    else
        dim.DimensionID = ['DIM_' datestr(now, 'yyyymmddHHMMSSFFF')];
    end

    dim.Name = ui.nameEdit.Value;
    dim.Description = ui.descEdit.Value;

    % Type
    typeMap = containers.Map(...
        {'Length', 'Diameter', 'Radius', 'Angle', 'Distance', 'Ordinal', 'Other'}, ...
        {0, 1, 2, 3, 4, 5, 6});
    dim.MyDimensionType = typeMap(ui.typeDropdown.Value);
    dim.MyType = 1; % DrawingElementType.Dimension

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

    % Collections
    dim.MyParameters = {};
    dim.MyConstructionGeometry = {};
end

%% Clear form
function clearForm(ui)
    ui.dimIdEdit.Value = '';
    ui.nameEdit.Value = '';
    ui.descEdit.Value = '';
    ui.typeDropdown.Value = 'Length';
    ui.nominalEdit.Value = 0;
    ui.unitsDropdown.Value = 'mm';
    ui.upperLimitEdit.Value = 0;
    ui.lowerLimitEdit.Value = 0;
    ui.toleranceLabel.Text = '± 0.000';
    ui.isOrdinateCheckbox.Value = false;
    ui.centerPointEdit.Value = '0, 0, 0';
    ui.dimPointEdit.Value = '0, 0, 0';
    ui.refPointEdit.Value = '0, 0, 0';
    ui.leaderEndEdit.Value = '';
    ui.leaderBendEdit.Value = '';
    ui.jsonArea.Value = '';
    ui.fig.UserData.selectedIndex = 0;
end

%% Preview JSON
function previewJSON(ui)
    try
        dim = buildDimensionFromForm(ui);
        jsonStr = jsonencode(dim, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;
    catch
        ui.jsonArea.Value = '(Enter valid data to preview JSON)';
    end
end

%% Import dimensions from JSON file
function importDimensions(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Import Dimensions JSON');
    if filename == 0, return; end

    try
        filePath = fullfile(pathname, filename);
        fid = fopen(filePath, 'r');
        jsonStr = fread(fid, '*char')';
        fclose(fid);

        imported = jsondecode(jsonStr);

        % Handle various formats
        if isstruct(imported) && isfield(imported, 'Dimensions')
            toAdd = imported.Dimensions;
        elseif isstruct(imported) && ~isfield(imported, 'Dimensions')
            toAdd = {imported};
        elseif iscell(imported)
            toAdd = imported;
        else
            toAdd = {imported};
        end

        dims = ui.fig.UserData.dimensions;
        for i = 1:length(toAdd)
            if iscell(toAdd)
                dims{end+1} = toAdd{i};
            else
                dims{end+1} = toAdd(i);
            end
        end
        ui.fig.UserData.dimensions = dims;

        updateDimensionList(ui);
        ui.statusLabel.Text = sprintf('Imported from: %s', filename);
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Import error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Export all dimensions
function exportAllDimensions(ui)
    dims = ui.fig.UserData.dimensions;
    if isempty(dims)
        ui.statusLabel.Text = 'No dimensions to export!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Export All Dimensions', 'CAD_Dimensions.json');
    if filename == 0, return; end

    try
        filePath = fullfile(pathname, filename);

        exportData = struct();
        exportData.ExportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        exportData.DimensionCount = length(dims);
        exportData.Dimensions = dims;

        jsonStr = jsonencode(exportData, 'PrettyPrint', true);

        fid = fopen(filePath, 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = sprintf('Exported %d dimensions to: %s', length(dims), filename);
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Export error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end
