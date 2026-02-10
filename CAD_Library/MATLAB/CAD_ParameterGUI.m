%% CAD_ParameterGUI.m
% MATLAB GUI for creating and editing CAD_Parameter objects
%
% Usage:
%   CAD_ParameterGUI()              - Opens the GUI
%   param = CAD_ParameterGUI()      - Opens GUI and returns created parameter
%
% The GUI allows you to:
%   - Enter all CAD_Parameter properties
%   - Create the parameter object
%   - Export to JSON
%   - Save JSON to file

function varargout = CAD_ParameterGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Parameter Creator', ...
                   'Position', [100 100 500 650], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.parameter = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [17, 2]);
    gl.RowHeight = repmat({30}, 1, 17);
    gl.RowHeight{15} = 100; % JSON preview area
    gl.ColumnWidth = {'1x', '2x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 5;

    % Title
    titleLabel = uilabel(gl, 'Text', 'CAD Parameter Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Name
    uilabel(gl, 'Text', 'Name:', 'HorizontalAlignment', 'right');
    nameEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Parameter name');

    % Row 3: ID
    uilabel(gl, 'Text', 'ID:', 'HorizontalAlignment', 'right');
    idEdit = uieditfield(gl, 'text', 'Value', '', ...
                         'Placeholder', 'Unique identifier');

    % Row 4: Description
    uilabel(gl, 'Text', 'Description:', 'HorizontalAlignment', 'right');
    descEdit = uieditfield(gl, 'text', 'Value', '', ...
                           'Placeholder', 'Parameter description');

    % Row 5: Comments
    uilabel(gl, 'Text', 'Comments:', 'HorizontalAlignment', 'right');
    commentsEdit = uieditfield(gl, 'text', 'Value', '', ...
                               'Placeholder', 'Additional comments');

    % Row 6: Parameter Type
    uilabel(gl, 'Text', 'Parameter Type:', 'HorizontalAlignment', 'right');
    typeDropdown = uidropdown(gl, ...
                              'Items', {'Double', 'Integer', 'String', 'Vector', 'Other'}, ...
                              'Value', 'Double');

    % Row 7: Value
    uilabel(gl, 'Text', 'Value:', 'HorizontalAlignment', 'right');
    valueEdit = uieditfield(gl, 'text', 'Value', '0', ...
                            'Placeholder', 'Parameter value');

    % Row 8: Units
    uilabel(gl, 'Text', 'Units:', 'HorizontalAlignment', 'right');
    unitsDropdown = uidropdown(gl, ...
                               'Items', {'None', 'mm', 'cm', 'm', 'in', 'ft', ...
                                        'deg', 'rad', 'kg', 'lb', 'N', 'lbf'}, ...
                               'Value', 'None');

    % Row 9: SolidWorks Parameter Name
    uilabel(gl, 'Text', 'SolidWorks Name:', 'HorizontalAlignment', 'right');
    swNameEdit = uieditfield(gl, 'text', 'Value', '', ...
                             'Placeholder', 'e.g., D1@Sketch1');

    % Row 10: Fusion 360 Parameter Name
    uilabel(gl, 'Text', 'Fusion 360 Name:', 'HorizontalAlignment', 'right');
    f360NameEdit = uieditfield(gl, 'text', 'Value', '', ...
                               'Placeholder', 'e.g., Length');

    % Row 11: Separator
    separator1 = uilabel(gl, 'Text', '─────────────────────────────────────────');
    separator1.Layout.Column = [1 2];

    % Row 12: Buttons
    buttonPanel = uigridlayout(gl, [1, 4]);
    buttonPanel.Layout.Row = 12;
    buttonPanel.Layout.Column = [1 2];
    buttonPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    buttonPanel.Padding = [0 0 0 0];

    createBtn = uibutton(buttonPanel, 'Text', 'Create', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    clearBtn = uibutton(buttonPanel, 'Text', 'Clear', ...
                        'BackgroundColor', [0.8 0.8 0.2]);
    exportBtn = uibutton(buttonPanel, 'Text', 'Export JSON', ...
                         'BackgroundColor', [0.3 0.5 0.7]);
    saveBtn = uibutton(buttonPanel, 'Text', 'Save to File', ...
                       'BackgroundColor', [0.5 0.3 0.7]);

    % Row 13: Status label
    uilabel(gl, 'Text', 'Status:', 'HorizontalAlignment', 'right');
    statusLabel = uilabel(gl, 'Text', 'Ready', ...
                          'FontColor', [0.2 0.2 0.8]);

    % Row 14: JSON Preview Label
    jsonLabel = uilabel(gl, 'Text', 'JSON Preview:', ...
                        'HorizontalAlignment', 'left', ...
                        'VerticalAlignment', 'top');
    jsonLabel.Layout.Column = [1 2];

    % Row 15: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas');
    jsonArea.Layout.Row = 15;
    jsonArea.Layout.Column = [1 2];

    % Row 16: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 16;
    closeBtn.Layout.Column = [1 2];

    % Store UI components in struct for callbacks
    ui = struct();
    ui.nameEdit = nameEdit;
    ui.idEdit = idEdit;
    ui.descEdit = descEdit;
    ui.commentsEdit = commentsEdit;
    ui.typeDropdown = typeDropdown;
    ui.valueEdit = valueEdit;
    ui.unitsDropdown = unitsDropdown;
    ui.swNameEdit = swNameEdit;
    ui.f360NameEdit = f360NameEdit;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;
    ui.fig = fig;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createParameter(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.parameter;
            close(fig);
        else
            varargout{1} = [];
        end
    end
end

%% Create Parameter callback
function createParameter(ui)
    try
        % Build the CAD_Parameter struct matching C# CAD_Parameter class
        param = struct();

        % ----- Identity / description -----
        % (C# CAD_Parameter: Name, Id, Description, Comments)
        param.Name = ui.nameEdit.Value;
        param.Id = ui.idEdit.Value;
        param.Description = ui.descEdit.Value;
        param.Comments = ui.commentsEdit.Value;

        % ----- Core data -----
        % (C# CAD_Parameter.ParameterType enum: Double=0, Integer=1,
        %  String=2, Vector=3, Other=4)
        typeMap = containers.Map(...
            {'Double', 'Integer', 'String', 'Vector', 'Other'}, ...
            {0, 1, 2, 3, 4});
        param.MyParameterType = typeMap(ui.typeDropdown.Value);

        % (C# CAD_Parameter.Value : CAD_ParameterValue)
        param.Value = createCADParameterValue(ui);

        % (C# CAD_Parameter.MyUnits : UnitOfMeasure)
        if ~strcmp(ui.unitsDropdown.Value, 'None')
            param.MyUnits = createUnitOfMeasure(ui.unitsDropdown.Value);
        else
            param.MyUnits = [];
        end

        % (C# CAD_Parameter.MyExpression : Expression)
        param.MyExpression = [];

        % ----- CAD app bindings -----
        param.SolidWorksParameterName = ui.swNameEdit.Value;
        param.Fusion360ParameterName = ui.f360NameEdit.Value;

        % ----- Associations -----
        % (C# CAD_Parameter: CurrentDimension, CurrentModel,
        %  CurrentMathParameter, DesignTable)
        param.CurrentDimension = [];
        param.CurrentModel = [];
        param.CurrentMathParameter = [];
        param.DesignTable = [];

        % ----- Backing collections -----
        % (C# CAD_Parameter: MyDimensions, MyMathParameters, MyModels,
        %  DependencyParameters, DependentParameters)
        param.MyDimensions = {};
        param.MyMathParameters = {};
        param.MyModels = {};
        param.DependencyParameters = {};
        param.DependentParameters = {};

        % Store in figure UserData
        ui.fig.UserData.parameter = param;

        % Generate JSON preview
        jsonStr = jsonencode(param, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Parameter created successfully!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Create CAD_ParameterValue struct
%  Matches C# CAD_ParameterValue class.
%  ParameterValueTypeEnum: Double=0, Single=1, Int16=2, Int32=3,
%                          Int64=4, Boolean=5, String=6, Object=7
function value = createCADParameterValue(ui)
    value = struct();

    typeStr = ui.typeDropdown.Value;

    switch typeStr
        case 'Double'
            value.ValueType = 0;  % Double
            dval = str2double(ui.valueEdit.Value);
            if isnan(dval), dval = 0; end
            value.DoubleValue = dval;
            value.SingleValue = [];
            value.Int16Value = [];
            value.Int32Value = [];
            value.Int64Value = [];
            value.BooleanValue = [];
            value.StringValue = [];

        case 'Integer'
            value.ValueType = 3;  % Int32
            ival = round(str2double(ui.valueEdit.Value));
            if isnan(ival), ival = 0; end
            value.DoubleValue = [];
            value.SingleValue = [];
            value.Int16Value = [];
            value.Int32Value = ival;
            value.Int64Value = [];
            value.BooleanValue = [];
            value.StringValue = [];

        case 'String'
            value.ValueType = 6;  % String
            value.DoubleValue = [];
            value.SingleValue = [];
            value.Int16Value = [];
            value.Int32Value = [];
            value.Int64Value = [];
            value.BooleanValue = [];
            value.StringValue = ui.valueEdit.Value;

        case 'Vector'
            value.ValueType = 7;  % Object
            parts = strsplit(ui.valueEdit.Value, ',');
            if length(parts) >= 3
                vx = str2double(strtrim(parts{1}));
                vy = str2double(strtrim(parts{2}));
                vz = str2double(strtrim(parts{3}));
                if isnan(vx), vx = 0; end
                if isnan(vy), vy = 0; end
                if isnan(vz), vz = 0; end
                value.VectorValue = struct( ...
                    'X_Value', vx, 'Y_Value', vy, 'Z_Value', vz);
            else
                value.VectorValue = struct( ...
                    'X_Value', 0, 'Y_Value', 0, 'Z_Value', 0);
            end
            value.DoubleValue = [];
            value.SingleValue = [];
            value.Int16Value = [];
            value.Int32Value = [];
            value.Int64Value = [];
            value.BooleanValue = [];
            value.StringValue = [];

        otherwise
            value.ValueType = 7;  % Object
            value.DoubleValue = [];
            value.SingleValue = [];
            value.Int16Value = [];
            value.Int32Value = [];
            value.Int64Value = [];
            value.BooleanValue = [];
            value.StringValue = [];
            value.ObjectValue = ui.valueEdit.Value;
    end
end

%% Create UnitOfMeasure struct
%  Matches C# SE_Library.UnitOfMeasure class.
%  SystemOfUnitsEnum: SI=0, CGS=1, US=2, GU=3, EMU=4, Other=5
function uom = createUnitOfMeasure(unitName)
    uom = struct();
    uom.Name = unitName;
    uom.Description = '';
    uom.SymbolName = unitName;
    uom.UnitValue = 1.0;
    uom.IsBaseUnit = false;

    % Auto-detect system of units
    usUnits = {'in', 'ft', 'yd', 'mi', 'oz', 'lb', 'lbf', 'psi'};
    if any(strcmpi(unitName, usUnits))
        uom.SystemOfUnits = 2;  % US
    else
        uom.SystemOfUnits = 0;  % SI
    end
end

%% Clear Form callback
function clearForm(ui)
    ui.nameEdit.Value = '';
    ui.idEdit.Value = '';
    ui.descEdit.Value = '';
    ui.commentsEdit.Value = '';
    ui.typeDropdown.Value = 'Double';
    ui.valueEdit.Value = '0';
    ui.unitsDropdown.Value = 'None';
    ui.swNameEdit.Value = '';
    ui.f360NameEdit.Value = '';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.parameter = [];
end

%% Export JSON callback
function exportJSON(ui)
    param = ui.fig.UserData.parameter;
    if isempty(param)
        ui.statusLabel.Text = 'No parameter created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(param, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    param = ui.fig.UserData.parameter;
    if isempty(param)
        ui.statusLabel.Text = 'No parameter created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Parameter.json';
    if ~isempty(param.Name)
        defaultName = [param.Name '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Parameter JSON', defaultName);

    if filename == 0
        return; % User cancelled
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(param, 'PrettyPrint', true);

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
