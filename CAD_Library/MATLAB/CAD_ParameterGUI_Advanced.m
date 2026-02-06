%% CAD_ParameterGUI_Advanced.m
% Advanced MATLAB GUI for creating and editing CAD_Parameter objects
% Includes load/save, batch creation, and parameter list management
%
% Usage:
%   CAD_ParameterGUI_Advanced()                    - Opens the GUI
%   params = CAD_ParameterGUI_Advanced()           - Returns all created parameters
%   CAD_ParameterGUI_Advanced(existingParams)      - Opens with existing parameters

function varargout = CAD_ParameterGUI_Advanced(existingParams)
    if nargin < 1
        existingParams = {};
    end

    % Create the main figure
    fig = uifigure('Name', 'CAD Parameter Manager', ...
                   'Position', [50 50 900 700], ...
                   'Resize', 'on');

    % Store data in figure's UserData
    data = struct();
    data.parameters = existingParams;
    data.selectedIndex = 0;
    fig.UserData = data;

    % Create main grid layout
    mainGrid = uigridlayout(fig, [1, 2]);
    mainGrid.ColumnWidth = {'1x', '1.5x'};
    mainGrid.Padding = [10 10 10 10];

    %% Left Panel - Parameter List
    leftPanel = uipanel(mainGrid, 'Title', 'Parameters');
    leftGrid = uigridlayout(leftPanel, [4, 1]);
    leftGrid.RowHeight = {'1x', 30, 30, 30};

    % Parameter list box
    paramList = uilistbox(leftGrid, 'Items', {}, 'Value', {});

    % List control buttons
    listBtnPanel = uigridlayout(leftGrid, [1, 3]);
    listBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    listBtnPanel.Padding = [0 0 0 0];

    addBtn = uibutton(listBtnPanel, 'Text', '+ Add New', ...
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

    % Count label
    countLabel = uilabel(leftGrid, 'Text', 'Total: 0 parameters', ...
                         'HorizontalAlignment', 'center');

    %% Right Panel - Parameter Editor
    rightPanel = uipanel(mainGrid, 'Title', 'Parameter Editor');
    rightGrid = uigridlayout(rightPanel, [14, 2]);
    rightGrid.RowHeight = [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 10, '1x', 40];
    rightGrid.ColumnWidth = {'0.4x', '1x'};
    rightGrid.Padding = [10 10 10 10];

    % Row 1: Name
    uilabel(rightGrid, 'Text', 'Name *:', 'HorizontalAlignment', 'right', ...
            'FontWeight', 'bold');
    nameEdit = uieditfield(rightGrid, 'text', 'Value', '', ...
                           'Placeholder', 'Required: Parameter name');

    % Row 2: ID
    uilabel(rightGrid, 'Text', 'ID:', 'HorizontalAlignment', 'right');
    idEdit = uieditfield(rightGrid, 'text', 'Value', '', ...
                         'Placeholder', 'Unique identifier (auto-generated if empty)');

    % Row 3: Description
    uilabel(rightGrid, 'Text', 'Description:', 'HorizontalAlignment', 'right');
    descEdit = uieditfield(rightGrid, 'text', 'Value', '', ...
                           'Placeholder', 'Parameter description');

    % Row 4: Comments
    uilabel(rightGrid, 'Text', 'Comments:', 'HorizontalAlignment', 'right');
    commentsEdit = uieditfield(rightGrid, 'text', 'Value', '', ...
                               'Placeholder', 'Additional notes');

    % Row 5: Parameter Type
    uilabel(rightGrid, 'Text', 'Type:', 'HorizontalAlignment', 'right');
    typeDropdown = uidropdown(rightGrid, ...
                              'Items', {'Double', 'Integer', 'String', 'Vector', 'Other'}, ...
                              'Value', 'Double');

    % Row 6: Value
    uilabel(rightGrid, 'Text', 'Value:', 'HorizontalAlignment', 'right');
    valuePanel = uigridlayout(rightGrid, [1, 2]);
    valuePanel.ColumnWidth = {'1x', 80};
    valuePanel.Padding = [0 0 0 0];
    valueEdit = uieditfield(valuePanel, 'text', 'Value', '0', ...
                            'Placeholder', 'Value');
    unitsDropdown = uidropdown(valuePanel, ...
                               'Items', {'(none)', 'mm', 'cm', 'm', 'in', 'ft', ...
                                        'deg', 'rad', 'kg', 'lb', 'N', 'lbf', 'Pa', 'psi'}, ...
                               'Value', '(none)');

    % Row 7: Min/Max limits
    uilabel(rightGrid, 'Text', 'Limits:', 'HorizontalAlignment', 'right');
    limitsPanel = uigridlayout(rightGrid, [1, 4]);
    limitsPanel.ColumnWidth = {40, '1x', 40, '1x'};
    limitsPanel.Padding = [0 0 0 0];
    uilabel(limitsPanel, 'Text', 'Min:', 'HorizontalAlignment', 'right');
    minEdit = uieditfield(limitsPanel, 'text', 'Value', '', 'Placeholder', '-∞');
    uilabel(limitsPanel, 'Text', 'Max:', 'HorizontalAlignment', 'right');
    maxEdit = uieditfield(limitsPanel, 'text', 'Value', '', 'Placeholder', '+∞');

    % Row 8: SolidWorks binding
    uilabel(rightGrid, 'Text', 'SolidWorks:', 'HorizontalAlignment', 'right');
    swNameEdit = uieditfield(rightGrid, 'text', 'Value', '', ...
                             'Placeholder', 'e.g., D1@Sketch1');

    % Row 9: Fusion 360 binding
    uilabel(rightGrid, 'Text', 'Fusion 360:', 'HorizontalAlignment', 'right');
    f360NameEdit = uieditfield(rightGrid, 'text', 'Value', '', ...
                               'Placeholder', 'e.g., Length');

    % Row 10: Expression
    uilabel(rightGrid, 'Text', 'Expression:', 'HorizontalAlignment', 'right');
    exprEdit = uieditfield(rightGrid, 'text', 'Value', '', ...
                           'Placeholder', 'e.g., Width * 2 + 10');

    % Row 11: Tags
    uilabel(rightGrid, 'Text', 'Tags:', 'HorizontalAlignment', 'right');
    tagsEdit = uieditfield(rightGrid, 'text', 'Value', '', ...
                           'Placeholder', 'Comma-separated tags');

    % Row 12: Separator
    sep = uilabel(rightGrid, 'Text', '');
    sep.Layout.Column = [1 2];

    % Row 13: JSON Preview
    jsonLabel = uilabel(rightGrid, 'Text', 'JSON:', ...
                        'HorizontalAlignment', 'right', ...
                        'VerticalAlignment', 'top');
    jsonArea = uitextarea(rightGrid, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 10);

    % Row 14: Action buttons
    statusLabel = uilabel(rightGrid, 'Text', 'Ready', ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.2 0.5 0.8]);
    actionPanel = uigridlayout(rightGrid, [1, 3]);
    actionPanel.ColumnWidth = {'1x', '1x', '1x'};
    actionPanel.Padding = [0 0 0 0];

    saveParamBtn = uibutton(actionPanel, 'Text', 'Save Parameter', ...
                            'BackgroundColor', [0.2 0.6 0.2]);
    clearBtn = uibutton(actionPanel, 'Text', 'Clear Form', ...
                        'BackgroundColor', [0.8 0.7 0.2]);
    previewBtn = uibutton(actionPanel, 'Text', 'Preview JSON', ...
                          'BackgroundColor', [0.3 0.5 0.7]);

    %% Store UI components
    ui = struct();
    ui.fig = fig;
    ui.paramList = paramList;
    ui.countLabel = countLabel;
    ui.nameEdit = nameEdit;
    ui.idEdit = idEdit;
    ui.descEdit = descEdit;
    ui.commentsEdit = commentsEdit;
    ui.typeDropdown = typeDropdown;
    ui.valueEdit = valueEdit;
    ui.unitsDropdown = unitsDropdown;
    ui.minEdit = minEdit;
    ui.maxEdit = maxEdit;
    ui.swNameEdit = swNameEdit;
    ui.f360NameEdit = f360NameEdit;
    ui.exprEdit = exprEdit;
    ui.tagsEdit = tagsEdit;
    ui.jsonArea = jsonArea;
    ui.statusLabel = statusLabel;

    %% Set up callbacks
    addBtn.ButtonPushedFcn = @(~,~) addNewParameter(ui);
    duplicateBtn.ButtonPushedFcn = @(~,~) duplicateParameter(ui);
    deleteBtn.ButtonPushedFcn = @(~,~) deleteParameter(ui);
    importBtn.ButtonPushedFcn = @(~,~) importParameters(ui);
    exportAllBtn.ButtonPushedFcn = @(~,~) exportAllParameters(ui);
    saveParamBtn.ButtonPushedFcn = @(~,~) saveCurrentParameter(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    previewBtn.ButtonPushedFcn = @(~,~) previewJSON(ui);
    paramList.ValueChangedFcn = @(~,~) loadSelectedParameter(ui);
    typeDropdown.ValueChangedFcn = @(~,~) updateValuePlaceholder(ui);

    % Initialize with existing parameters
    if ~isempty(existingParams)
        updateParameterList(ui);
    end

    % Initialize value placeholder
    updateValuePlaceholder(ui);

    %% Wait for output if requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.parameters;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Update parameter list display
function updateParameterList(ui)
    params = ui.fig.UserData.parameters;
    if isempty(params)
        ui.paramList.Items = {};
        ui.countLabel.Text = 'Total: 0 parameters';
        return;
    end

    % Build display names
    names = cell(1, length(params));
    for i = 1:length(params)
        p = params{i};
        if isfield(p, 'Name') && ~isempty(p.Name)
            names{i} = sprintf('%d. %s', i, p.Name);
        else
            names{i} = sprintf('%d. (unnamed)', i);
        end

        % Add type indicator
        if isfield(p, 'MyParameterType')
            types = {'[D]', '[I]', '[S]', '[V]', '[?]'};
            if p.MyParameterType >= 0 && p.MyParameterType <= 4
                names{i} = [names{i} ' ' types{p.MyParameterType + 1}];
            end
        end
    end

    ui.paramList.Items = names;
    ui.countLabel.Text = sprintf('Total: %d parameters', length(params));
end

%% Add new parameter
function addNewParameter(ui)
    clearForm(ui);
    ui.fig.UserData.selectedIndex = 0;
    ui.statusLabel.Text = 'Creating new parameter...';
    ui.statusLabel.FontColor = [0.2 0.5 0.8];
end

%% Duplicate selected parameter
function duplicateParameter(ui)
    idx = getSelectedIndex(ui);
    if idx == 0
        ui.statusLabel.Text = 'Select a parameter to duplicate';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    params = ui.fig.UserData.parameters;
    newParam = params{idx};
    newParam.Name = [newParam.Name '_copy'];
    if isfield(newParam, 'Id') && ~isempty(newParam.Id)
        newParam.Id = [newParam.Id '_copy'];
    end

    params{end+1} = newParam;
    ui.fig.UserData.parameters = params;
    updateParameterList(ui);

    ui.statusLabel.Text = 'Parameter duplicated';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Delete selected parameter
function deleteParameter(ui)
    idx = getSelectedIndex(ui);
    if idx == 0
        ui.statusLabel.Text = 'Select a parameter to delete';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    params = ui.fig.UserData.parameters;
    params(idx) = [];
    ui.fig.UserData.parameters = params;
    ui.fig.UserData.selectedIndex = 0;
    updateParameterList(ui);
    clearForm(ui);

    ui.statusLabel.Text = 'Parameter deleted';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Get selected index from list
function idx = getSelectedIndex(ui)
    if isempty(ui.paramList.Value)
        idx = 0;
        return;
    end

    selected = ui.paramList.Value;
    if iscell(selected)
        selected = selected{1};
    end

    % Extract index from "N. Name" format
    parts = strsplit(selected, '.');
    idx = str2double(parts{1});
    if isnan(idx)
        idx = 0;
    end
end

%% Load selected parameter into form
function loadSelectedParameter(ui)
    idx = getSelectedIndex(ui);
    if idx == 0 || idx > length(ui.fig.UserData.parameters)
        return;
    end

    ui.fig.UserData.selectedIndex = idx;
    param = ui.fig.UserData.parameters{idx};

    % Populate form fields
    ui.nameEdit.Value = getFieldOrDefault(param, 'Name', '');
    ui.idEdit.Value = getFieldOrDefault(param, 'Id', '');
    ui.descEdit.Value = getFieldOrDefault(param, 'Description', '');
    ui.commentsEdit.Value = getFieldOrDefault(param, 'Comments', '');

    % Parameter type
    types = {'Double', 'Integer', 'String', 'Vector', 'Other'};
    typeIdx = getFieldOrDefault(param, 'MyParameterType', 0) + 1;
    if typeIdx >= 1 && typeIdx <= 5
        ui.typeDropdown.Value = types{typeIdx};
    end

    % Value
    if isfield(param, 'Value') && ~isempty(param.Value)
        val = param.Value;
        if isfield(val, 'DoubleValue')
            ui.valueEdit.Value = num2str(val.DoubleValue);
        elseif isfield(val, 'Int32Value')
            ui.valueEdit.Value = num2str(val.Int32Value);
        elseif isfield(val, 'StringValue')
            ui.valueEdit.Value = val.StringValue;
        elseif isfield(val, 'VectorValue')
            v = val.VectorValue;
            ui.valueEdit.Value = sprintf('%g, %g, %g', v.X_Value, v.Y_Value, v.Z_Value);
        end
    else
        ui.valueEdit.Value = '0';
    end

    % Units
    if isfield(param, 'MyUnits') && isfield(param.MyUnits, 'UnitName')
        ui.unitsDropdown.Value = param.MyUnits.UnitName;
    else
        ui.unitsDropdown.Value = '(none)';
    end

    % Limits
    ui.minEdit.Value = getFieldOrDefault(param, 'MinValue', '');
    ui.maxEdit.Value = getFieldOrDefault(param, 'MaxValue', '');

    % CAD bindings
    ui.swNameEdit.Value = getFieldOrDefault(param, 'SolidWorksParameterName', '');
    ui.f360NameEdit.Value = getFieldOrDefault(param, 'Fusion360ParameterName', '');

    % Expression
    ui.exprEdit.Value = getFieldOrDefault(param, 'Expression', '');

    % Tags
    if isfield(param, 'Tags') && iscell(param.Tags)
        ui.tagsEdit.Value = strjoin(param.Tags, ', ');
    else
        ui.tagsEdit.Value = '';
    end

    % Update JSON preview
    previewJSON(ui);

    ui.statusLabel.Text = sprintf('Loaded: %s', param.Name);
    ui.statusLabel.FontColor = [0.2 0.5 0.8];
end

%% Helper to get field with default
function val = getFieldOrDefault(s, field, default)
    if isfield(s, field) && ~isempty(s.(field))
        val = s.(field);
        if isnumeric(val)
            val = num2str(val);
        end
    else
        val = default;
    end
end

%% Save current parameter
function saveCurrentParameter(ui)
    % Validate required fields
    if isempty(ui.nameEdit.Value)
        ui.statusLabel.Text = 'Error: Name is required!';
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
        return;
    end

    try
        param = buildParameterFromForm(ui);

        params = ui.fig.UserData.parameters;
        idx = ui.fig.UserData.selectedIndex;

        if idx > 0 && idx <= length(params)
            % Update existing
            params{idx} = param;
            ui.statusLabel.Text = sprintf('Updated: %s', param.Name);
        else
            % Add new
            params{end+1} = param;
            ui.fig.UserData.selectedIndex = length(params);
            ui.statusLabel.Text = sprintf('Created: %s', param.Name);
        end

        ui.fig.UserData.parameters = params;
        updateParameterList(ui);
        previewJSON(ui);

        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Build parameter struct from form
function param = buildParameterFromForm(ui)
    param = struct();

    % Basic fields
    param.Name = ui.nameEdit.Value;

    if ~isempty(ui.idEdit.Value)
        param.Id = ui.idEdit.Value;
    else
        param.Id = ['PARAM_' datestr(now, 'yyyymmddHHMMSSFFF')];
    end

    if ~isempty(ui.descEdit.Value)
        param.Description = ui.descEdit.Value;
    end

    if ~isempty(ui.commentsEdit.Value)
        param.Comments = ui.commentsEdit.Value;
    end

    % Parameter type
    typeMap = containers.Map(...
        {'Double', 'Integer', 'String', 'Vector', 'Other'}, ...
        {0, 1, 2, 3, 4});
    param.MyParameterType = typeMap(ui.typeDropdown.Value);

    % Value
    param.Value = buildValueFromForm(ui);

    % Units
    if ~strcmp(ui.unitsDropdown.Value, '(none)')
        param.MyUnits = struct('UnitName', ui.unitsDropdown.Value);
    end

    % Limits
    if ~isempty(ui.minEdit.Value)
        param.MinValue = str2double(ui.minEdit.Value);
    end
    if ~isempty(ui.maxEdit.Value)
        param.MaxValue = str2double(ui.maxEdit.Value);
    end

    % CAD bindings
    if ~isempty(ui.swNameEdit.Value)
        param.SolidWorksParameterName = ui.swNameEdit.Value;
    end
    if ~isempty(ui.f360NameEdit.Value)
        param.Fusion360ParameterName = ui.f360NameEdit.Value;
    end

    % Expression
    if ~isempty(ui.exprEdit.Value)
        param.Expression = ui.exprEdit.Value;
    end

    % Tags
    if ~isempty(ui.tagsEdit.Value)
        tags = strsplit(ui.tagsEdit.Value, ',');
        param.Tags = strtrim(tags);
    end

    % Initialize collections
    param.MyDimensions = {};
    param.MyMathParameters = {};
    param.MyModels = {};
    param.DependencyParameters = {};
    param.DependentParameters = {};
end

%% Build value struct from form
function value = buildValueFromForm(ui)
    value = struct();
    typeStr = ui.typeDropdown.Value;

    switch typeStr
        case 'Double'
            value.ValueType = 0;
            value.DoubleValue = str2double(ui.valueEdit.Value);
            if isnan(value.DoubleValue)
                value.DoubleValue = 0;
            end

        case 'Integer'
            value.ValueType = 3;
            value.Int32Value = round(str2double(ui.valueEdit.Value));
            if isnan(value.Int32Value)
                value.Int32Value = 0;
            end

        case 'String'
            value.ValueType = 6;
            value.StringValue = ui.valueEdit.Value;

        case 'Vector'
            value.ValueType = 7;
            parts = strsplit(ui.valueEdit.Value, ',');
            if length(parts) >= 3
                value.VectorValue = struct(...
                    'X_Value', str2double(strtrim(parts{1})), ...
                    'Y_Value', str2double(strtrim(parts{2})), ...
                    'Z_Value', str2double(strtrim(parts{3})));
            else
                value.VectorValue = struct('X_Value', 0, 'Y_Value', 0, 'Z_Value', 0);
            end

        otherwise
            value.ValueType = 7;
            value.ObjectValue = ui.valueEdit.Value;
    end
end

%% Clear form
function clearForm(ui)
    ui.nameEdit.Value = '';
    ui.idEdit.Value = '';
    ui.descEdit.Value = '';
    ui.commentsEdit.Value = '';
    ui.typeDropdown.Value = 'Double';
    ui.valueEdit.Value = '0';
    ui.unitsDropdown.Value = '(none)';
    ui.minEdit.Value = '';
    ui.maxEdit.Value = '';
    ui.swNameEdit.Value = '';
    ui.f360NameEdit.Value = '';
    ui.exprEdit.Value = '';
    ui.tagsEdit.Value = '';
    ui.jsonArea.Value = '';
    ui.fig.UserData.selectedIndex = 0;
    updateValuePlaceholder(ui);
end

%% Update value placeholder based on type
function updateValuePlaceholder(ui)
    typeStr = ui.typeDropdown.Value;
    switch typeStr
        case 'Double'
            ui.valueEdit.Placeholder = 'e.g., 3.14159';
        case 'Integer'
            ui.valueEdit.Placeholder = 'e.g., 42';
        case 'String'
            ui.valueEdit.Placeholder = 'e.g., Hello World';
        case 'Vector'
            ui.valueEdit.Placeholder = 'e.g., 1.0, 2.0, 3.0';
        otherwise
            ui.valueEdit.Placeholder = 'Value';
    end
end

%% Preview JSON
function previewJSON(ui)
    try
        param = buildParameterFromForm(ui);
        jsonStr = jsonencode(param, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;
    catch
        ui.jsonArea.Value = '(Enter valid data to preview JSON)';
    end
end

%% Import parameters from JSON file
function importParameters(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Import Parameters JSON');
    if filename == 0
        return;
    end

    try
        filePath = fullfile(pathname, filename);
        fid = fopen(filePath, 'r');
        jsonStr = fread(fid, '*char')';
        fclose(fid);

        imported = jsondecode(jsonStr);

        % Handle single parameter or array
        if isstruct(imported) && ~isfield(imported, 'Parameters')
            % Single parameter
            params = ui.fig.UserData.parameters;
            params{end+1} = imported;
            ui.fig.UserData.parameters = params;
        elseif isstruct(imported) && isfield(imported, 'Parameters')
            % Array wrapped in object
            for i = 1:length(imported.Parameters)
                params = ui.fig.UserData.parameters;
                params{end+1} = imported.Parameters(i);
                ui.fig.UserData.parameters = params;
            end
        elseif iscell(imported)
            % Array of parameters
            for i = 1:length(imported)
                params = ui.fig.UserData.parameters;
                params{end+1} = imported{i};
                ui.fig.UserData.parameters = params;
            end
        end

        updateParameterList(ui);
        ui.statusLabel.Text = sprintf('Imported from: %s', filename);
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Import error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Export all parameters
function exportAllParameters(ui)
    params = ui.fig.UserData.parameters;
    if isempty(params)
        ui.statusLabel.Text = 'No parameters to export!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Export All Parameters', 'CAD_Parameters.json');
    if filename == 0
        return;
    end

    try
        filePath = fullfile(pathname, filename);

        % Create export structure
        exportData = struct();
        exportData.ExportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        exportData.ParameterCount = length(params);
        exportData.Parameters = params;

        jsonStr = jsonencode(exportData, 'PrettyPrint', true);

        fid = fopen(filePath, 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = sprintf('Exported %d parameters to: %s', length(params), filename);
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Export error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end
